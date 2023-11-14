extends Unit

enum game_state {Patrolling, Suspicious, Chasing}

@export var start_state = game_state

# Called when the node enters the scene tree for the first time.
func _ready():
	super()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	super(delta)
	
func game_changed(state):
	start_state = state
