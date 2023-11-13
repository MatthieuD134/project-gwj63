extends Unit


# Called when the node enters the scene tree for the first time.
func _ready():
	move_speed = 24
	super()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	super(delta)
