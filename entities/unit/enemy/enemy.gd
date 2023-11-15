class_name Enemy
extends Unit

#Most interactions define where the enemy is going to move. Instead of coding a
#lot of interactions here in the enemy script, we just want to make sure the
#enemy can give necessary information to tell the gameboard where to put things.
enum game_state {PATROLLING, SUSPICIOUS, CHASING}

@export var current_state := game_state.PATROLLING

# Called when the node enters the scene tree for the first time.
func _ready():
	super()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	super(delta)
	
func update_game_state(state : game_state):
	current_state = state

#The variable name start_state fits a lot of cases, but can be confusing to
#reference directly, so this function makes for a more readable alternative.
func is_in_state(state : game_state) -> bool:
	return current_state == state
