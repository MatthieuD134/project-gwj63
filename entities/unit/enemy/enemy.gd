class_name Enemy
extends Unit

signal changed_state(enemy: Enemy, prev_state: game_state, state: game_state)
signal movement_triggered(enemy: Enemy)
var footstep : AudioStreamPlayer2D
var footR : RandomNumberGenerator
#Most interactions define where the enemy is going to move. Instead of coding a
#lot of interactions here in the enemy script, we just want to make sure the
#enemy can give necessary information to tell the gameboard where to put things.
enum game_state {PATROLLING, SUSPICIOUS, CHASING}

@export var current_state := game_state.PATROLLING : set = update_game_state
@export var trigger_movement_timer: Timer
@onready var animation : AnimationPlayer = $AnimationPlayer
var footstepTimer : Timer

var suspicious_target_cell  := Vector2(0,0)

# Called when the node enters the scene tree for the first time.
func _ready():
	super()
	footR = RandomNumberGenerator.new()
	footstepTimer = get_child(get_child_count() - 1)
	footstepTimer.start()
	self.move_range = 10
	self.add_to_group("enemies")
	self.trigger_movement_timer.set_one_shot(true)
	var player = get_tree().get_first_node_in_group("player")
	if player as Player:
		player.connect("cell_changed", _on_player_cell_changed )
		player.connect("walk_finished", _on_player_walk_finished )
	# start timer to trigger movement as well as setting game state
	self.current_state = game_state.PATROLLING
	animation.play("Walk")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	super(delta)

func update_game_state(state : game_state) -> void:
	if current_state != state:
		var prev_state = current_state
		current_state = state
		# add a delay before continuing the patrol when changing state
		if state == game_state.PATROLLING:
			trigger_movement_timer.start()
		else:
			trigger_movement_timer.stop()
		changed_state.emit(self, prev_state, state)
	else:
		trigger_movement_timer.stop()

#The variable name start_state fits a lot of cases, but can be confusing to
#reference directly, so this function makes for a more readable alternative.
func is_in_state(state : game_state) -> bool:
	return current_state == state


# function the player if he is within detection range (but not checking if within line of sight)
func get_player_in_detection_range() -> Player:
	var player = get_tree().get_first_node_in_group("player") as Player
	if $PathFollow2D/DetectionArea.overlaps_area(player.detection_shape):
		return player
	return null

# function to check if player is within sight
func is_player_in_sight() -> bool:
	var player : Player = get_tree().get_first_node_in_group("player")
	var space_state = get_world_2d().direct_space_state
	# enables the collision mask layer 1 and 3
	var cell_size = self.grid.cell_size.x
	var queries: Array[PhysicsRayQueryParameters2D] = [
#		PhysicsRayQueryParameters2D.create(self.sprite.global_position, player.global_position, int(pow(2, 1-1) + pow(2, 3-1)), [self]), # center
		PhysicsRayQueryParameters2D.create(self.sprite.global_position, player.sprite.global_position + Vector2(0, -cell_size/3), int(pow(2, 1-1) + pow(2, 3-1)), [self]), # top
		PhysicsRayQueryParameters2D.create(self.sprite.global_position, player.sprite.global_position + Vector2(cell_size/3, 0), int(pow(2, 1-1) + pow(2, 3-1)), [self]), # right
		PhysicsRayQueryParameters2D.create(self.sprite.global_position, player.sprite.global_position + Vector2(0, cell_size/3), int(pow(2, 1-1) + pow(2, 3-1)), [self]), # bottom
		PhysicsRayQueryParameters2D.create(self.sprite.global_position, player.sprite.global_position + Vector2(-cell_size/3, 0), int(pow(2, 1-1) + pow(2, 3-1)), [self]) # left
	]
	for query in queries:
		query.set_collide_with_areas(true)
		query.set_collide_with_bodies(true)
		var sight_check = space_state.intersect_ray(query)
		if sight_check:
			if sight_check["collider"] == player.detection_shape:
				return true
	return false

# function to trigger enemy to chase player
func chase_player(_player: Player) -> void:
	animation.play("Run")
	footstepTimer.start()
	self.update_game_state(game_state.CHASING)
	movement_triggered.emit(self)

func check_suspicious_cell(suspicious_cell: Vector2) -> void:
	self.suspicious_target_cell = suspicious_cell
	animation.play("Walk")
	footstepTimer.start()
	self.update_game_state(game_state.SUSPICIOUS)
	movement_triggered.emit(self)


# change the state to chasing if the player is within sight and not hidden
func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.has_method("get_player"):
		var player: Player = area.get_player()
		if not player.is_hidden():
			if self.is_player_in_sight():
				self.chase_player(player)

# change the state to patroling if user leaves sight and was being chased
func _on_area_2d_area_exited(area: Area2D) -> void:
	if area as DetectionShape and self.current_state == game_state.CHASING:
		var player : Player = area.get_player()
		# if player still in sight, chase him, otherwise go to last seen place as suspicious
		if self.is_player_in_sight():
			self.chase_player(player)
		else:
			self.check_suspicious_cell(player.cell)

# whenever enemy reach destination, either wait for a while when patrolling or continue chasing player
func _on_walk_finished(unit: Enemy, is_interuption: bool) -> void:
	# first check if player can be chased, otherwise continue the normal flow
	var player = self.get_player_in_detection_range()
	if player as Player and self.is_player_in_sight() and not player.is_hidden():
		self.chase_player(player)
	else:
		match current_state:
			game_state.PATROLLING:
				animation.play("Idle")
				footstepTimer.stop()
				unit.trigger_movement_timer.start()
			game_state.CHASING:
				# if player still in sight, chase him, otherwise go to last seen place as suspicious
				if self.is_player_in_sight():
					self.chase_player(player)
				else:
					self.check_suspicious_cell(player.cell)
			game_state.SUSPICIOUS:
				if is_interuption:
					movement_triggered.emit(self)
				else:
					animation.play("Walk")
					footstepTimer.start()
					update_game_state(game_state.PATROLLING)

# whenever player reach destination, check if he can be chased
func _on_player_walk_finished(player: Unit, _is_interuption: bool) -> void:
	if player as Player:
		match self.current_state:
			game_state.CHASING:
				# if player still in sight, chase him, otherwise go to last seen place as suspicious
				if self.is_player_in_sight():
					self.chase_player(player)
				else:
					self.check_suspicious_cell(player.cell)
			_:
				if $PathFollow2D/DetectionArea.overlaps_area(player.detection_shape):
					if self.is_player_in_sight() and not player.is_hidden():
						self.chase_player(player)


func _on_trigger_movement_timeout() -> void:
	if current_state == game_state.PATROLLING:
		animation.play("Walk")
		footstepTimer.start()
		movement_triggered.emit(self)

# called whenever the player cell changes to continue chasing them or change to patrolling
func _on_player_cell_changed(_prev_cell: Vector2, _new_cell: Vector2, unit: Unit) -> void:
	if unit as Player:
		match current_state:
			game_state.CHASING:
				# if player still in sight, chase him, otherwise go to last seen place as suspicious
				if not self.is_player_in_sight():
					self.check_suspicious_cell(grid.calculate_grid_coordinates(unit.cell))
				else:
					self.chase_player(unit)
			_:
				var player = self.get_player_in_detection_range()
				if player as Player and self.is_player_in_sight() and not player.is_hidden():
					self.chase_player(player)

func _on_footstep_timer_timeout():
	footstep = get_node("FootStep " + str(footR.randi_range(0, 6)))
	footstep.play()

# check if player is in range and in sight to start following them
func _on_cell_changed(_prev_cell, _new_cell, _unit) -> void:
	match current_state:
		game_state.CHASING:
			var player = get_tree().get_first_node_in_group("player")
			# if player still in sight, chase him, otherwise go to last seen place as suspicious
			if self.is_player_in_sight():
				self.chase_player(player)
			else:
				self.check_suspicious_cell(player.cell)
		_:
			var player = self.get_player_in_detection_range()
			if player as Player and self.is_player_in_sight() and not player.is_hidden():
				self.chase_player(player)
