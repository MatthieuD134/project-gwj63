class_name Player
extends Unit

@onready var _is_hidden : bool = false
# whenever an enemy starts chasing the player, they are being added to the array
@onready var chasers: Array[Enemy] = []

# Called when the node enters the scene tree for the first time.
func _ready():
	super()
	self.add_to_group("player")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	super(delta)

# the player is being chased only when it has chasers in the array
func is_being_chased() -> bool:
	return self.chasers.size() > 0

# function to be used to hide player, only hides if not being chased
func hide_self() -> void:
	if not self._is_hidden and not is_being_chased():
		self._is_hidden = true

# function to be used to unhide player
func unhide_self() -> void:
	if self.is_hidden:
		self._is_hidden = false

# getter function to avoid using the variable directly
func is_hidden():
	return self._is_hidden
