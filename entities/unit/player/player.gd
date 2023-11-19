class_name Player
extends Unit

var boardPiece : Interactable
@onready var _is_hidden : bool = false
# whenever an enemy starts chasing the player, they are being added to the array
@onready var active_chasers: Array[Enemy] = []
@onready var suspicious_chasers: Array[Enemy] = []
@onready var detection_shape : DetectionShape = $PathFollow2D/PlayerDetectionShape

var mewo : AudioStreamPlayer
var ears : AudioListener2D
var mewoR : RandomNumberGenerator
@onready var feet : AnimationPlayer = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	super()
	feet.play("CatIdle")
	mewoR = RandomNumberGenerator.new()
	get_node("MewoTimer").start()
	self.add_to_group("player")
	ears = AudioListener2D.new()
	ears.make_current()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	super(delta)
	if (_is_walking):
		if (is_being_chased()):
			feet.play("catWalkChase")
		else:
			feet.play("catWalk")
	else:
		if (is_being_chased()):
			feet.play("catIdleChase")
		else:
			feet.play("catIdle")

#The player and enemy can deal with interactables in a specific way depending
#on their game state. The cat will take status tags from fixtures and apply
#them as well as it can. If something is usable, it will be used at that point.
#If the cat needs to take time breaking through the space, it will stall to
#work on said space.
func interact(activePiece):
	boardPiece = activePiece
	if (boardPiece == null):
		self.unhide_self()
		return
	
	if (boardPiece.status_tags.has("HIDDEN")):
		self.hide_self()
	else:
		self.unhide_self()

# the player is being chased only when it has active chasers in the array
func is_being_chased() -> bool:
	return self.active_chasers.size() > 0

# function to be used to hide player, only hides if not being chased
func hide_self() -> void:
	if not self._is_hidden and not is_being_chased():
		self._is_hidden = true

# function to be used to unhide player
func unhide_self() -> void:
	if self._is_hidden:
		self._is_hidden = false

# getter function to avoid using the variable directly
func is_hidden():
	return self._is_hidden


func _on_mewo_timer_timeout():
	mewo = get_node("Mewo " + str(mewoR.randi_range(1, 7)))
	mewo.play()
