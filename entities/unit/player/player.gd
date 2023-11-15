class_name Player
extends Unit


@onready var is_hidden : bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	super()
	self.add_to_group("player")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	super(delta)
