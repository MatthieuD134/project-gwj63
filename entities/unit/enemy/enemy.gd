class_name Enemy
extends Unit

signal changed_state(enemy: Enemy, state: game_state)
signal movement_triggered(enemy: Enemy)

#Most interactions define where the enemy is going to move. Instead of coding a
#lot of interactions here in the enemy script, we just want to make sure the
#enemy can give necessary information to tell the gameboard where to put things.
enum game_state {PATROLLING, SUSPICIOUS, CHASING}

@export var current_state := game_state.PATROLLING : set = update_game_state
@export var trigger_movement_timer: Timer

# Called when the node enters the scene tree for the first time.
func _ready():
	super()
	self.move_range = 10
	self.add_to_group("enemies")
	self.trigger_movement_timer.set_one_shot(true)
	var player = get_tree().get_first_node_in_group("player")
	if player as Player:
		player.connect("cell_changed", _on_player_cell_changed )
		player.connect("walk_finished", _on_player_walk_finished )
	# start timer to trigger movement as well as setting game state
	self.current_state = game_state.PATROLLING
	self.trigger_movement_timer.start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	super(delta)
	
func update_game_state(state : game_state) -> void:
	current_state = state
	# add a delay before continuing the patrol when changing state
	if state == game_state.PATROLLING:
		trigger_movement_timer.start()
	else:
		trigger_movement_timer.stop()
	changed_state.emit(self, state)

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
func is_player_in_sight(player:  Player) -> bool:
	var space_state = get_world_2d().direct_space_state
	# enables the collision mask layer 1 and 3
	var cell_size = self.grid.cell_size.x
	var queries: Array[PhysicsRayQueryParameters2D] = [
		PhysicsRayQueryParameters2D.create(self.sprite.global_position, player.global_position + Vector2(0, -cell_size), int(pow(2, 1-1) + pow(2, 3-1)), [self]), # top
		PhysicsRayQueryParameters2D.create(self.sprite.global_position, player.global_position + Vector2(cell_size, 0), int(pow(2, 1-1) + pow(2, 3-1)), [self]), # right
		PhysicsRayQueryParameters2D.create(self.sprite.global_position, player.global_position + Vector2(0, cell_size), int(pow(2, 1-1) + pow(2, 3-1)), [self]), # bottom
		PhysicsRayQueryParameters2D.create(self.sprite.global_position, player.global_position + Vector2(-cell_size, 0), int(pow(2, 1-1) + pow(2, 3-1)), [self]) # left
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
func chase_player(player: Player) -> void:
	# check if enemy already in the player's chaser, and add it if not already there
	if self not in player.chasers:
		player.chasers.append(self)
	self.update_game_state(game_state.CHASING)
	movement_triggered.emit(self)


# change the state to chasing if the player is within sight and not hidden
func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.has_method("get_player"):
		var player: Player = area.get_player()
		if not player.is_hidden():
			if self.is_player_in_sight(player):
				self.chase_player(player)


# change the state to patroling if user leaves sight
func _on_area_2d_area_exited(area: Area2D) -> void:
	if area as DetectionShape:
		self.update_game_state(game_state.SUSPICIOUS)

# whenever enemy reach destination, either wait for a while when patrolling or continue chasing player
func _on_walk_finished(unit: Enemy) -> void:
	# first check if player can be chased, otherwise continue the normal flow
	var player = self.get_player_in_detection_range()
	if player as Player and self.is_player_in_sight(player) and not player.is_hidden():
		self.chase_player(player)
	else:
		match current_state:
			game_state.PATROLLING:
				unit.trigger_movement_timer.start()
			game_state.CHASING:
				movement_triggered.emit(self)
			game_state.SUSPICIOUS:
				update_game_state(game_state.PATROLLING)

# whenever player reach destination, check if he can be chased
func _on_player_walk_finished(player: Unit) -> void:
	if player as Player:
		if $PathFollow2D/DetectionArea.overlaps_area(player.detection_shape):
			if self.is_player_in_sight(player) and not player.is_hidden():
				self.chase_player(player)


func _on_trigger_movement_timeout() -> void:
	if current_state == game_state.PATROLLING:
		movement_triggered.emit(self)

# called whenever the player cell changes to continue chasing them or change to patrolling
func _on_player_cell_changed(_prev_cell: Vector2, _new_cell: Vector2, unit: Unit) -> void:
	if unit as Player:
		match current_state:
			game_state.CHASING:
				if not unit.is_hidden() and self.is_player_in_sight(unit):
					chase_player(unit)
			_:
				var player = self.get_player_in_detection_range()
				if player as Player and self.is_player_in_sight(player) and not player.is_hidden():
					self.chase_player(player)

# check if player is in range and in sight to start following them
func _on_cell_changed(_prev_cell, _new_cell, _unit) -> void:
	match current_state:
		game_state.CHASING:
			pass
		_:
			var player = self.get_player_in_detection_range()
			if player as Player and self.is_player_in_sight(player) and not player.is_hidden():
				self.chase_player(player)
