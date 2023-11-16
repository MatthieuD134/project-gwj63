class_name Enemy
extends Unit

signal changed_state(enemy: Enemy, state: game_state)
signal movement_triggered(enemy: Enemy)
var footstep : AudioStreamPlayer2D
var footR : RandomNumberGenerator
var theme : AudioStreamPlayer
#Most interactions define where the enemy is going to move. Instead of coding a
#lot of interactions here in the enemy script, we just want to make sure the
#enemy can give necessary information to tell the gameboard where to put things.
enum game_state {PATROLLING, SUSPICIOUS, CHASING}

@export var current_state := game_state.PATROLLING : set = update_game_state
@export var trigger_movement_timer: Timer
@onready var detection_distance := 6

# Called when the node enters the scene tree for the first time.
func _ready():
	super()
	footR = RandomNumberGenerator.new()
	self.get_child(get_child_count() - 1).start()
	self.move_range = 10
	self.add_to_group("enemies")
	self.current_state = game_state.PATROLLING
	theme = $"Patrol Theme"
	theme.play()
	self.trigger_movement_timer.set_one_shot(true)
	var player = get_tree().get_first_node_in_group("player")
	if player as Player:
		player.connect("cell_changed", _on_player_cell_changed )
	# start timer to trigger movement
	self.trigger_movement_timer.start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	super(delta)
	
func update_game_state(state : game_state) -> void:
	if current_state != state:
		current_state = state
		# add a delay before continuing the patrol when changing state
		if state == game_state.PATROLLING:
			trigger_movement_timer.start()
		
		theme.stop()
		match current_state:
			game_state.PATROLLING:
					theme = $"Patrol Theme"
					theme.play()
			game_state.CHASING:
					theme = $"Chase Theme"
					theme.play()
			game_state.SUSPICIOUS:
					theme = $"Suspicious Theme"
					theme.play()
		changed_state.emit(self, state)

#The variable name start_state fits a lot of cases, but can be confusing to
#reference directly, so this function makes for a more readable alternative.
func is_in_state(state : game_state) -> bool:
	return current_state == state


# change the state to chasing if the player is within sight and not hidden
func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.has_method("get_player"):
		var player: Player = area.get_player()
		if not player.is_hidden:
			current_state = game_state.CHASING


# change the state to patroling if user leaves sight
func _on_area_2d_area_exited(area: Area2D) -> void:
	if area as DetectionShape:
		current_state = game_state.SUSPICIOUS

# whenever enemy reach destination, either wait for a while when patrolling or continue chasing player
func _on_walk_finished(unit: Enemy) -> void:
	match current_state:
		game_state.PATROLLING:
			unit.trigger_movement_timer.start()
		game_state.CHASING:
			movement_triggered.emit(self)
		game_state.SUSPICIOUS:
			current_state = game_state.PATROLLING


func _on_trigger_movement_timeout() -> void:
	movement_triggered.emit(self)

# called whenever the player cell changes to continue chasing them or change to patrolling
func _on_player_cell_changed(_prev_cell: Vector2, _new_cell: Vector2, unit: Unit) -> void:
	if unit as Player and current_state == game_state.CHASING:
			movement_triggered.emit(self)


func _on_footstep_timer_timeout():
	footstep = get_node("FootStep " + str(footR.randi_range(0, 6)))
	#footstep = get_node("FootStep 0")
	#print(footstep.get_path())
	footstep.play()
