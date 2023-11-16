class_name Player
extends Unit

var boardPiece : Interactable
@onready var is_hidden : bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	super()
	self.add_to_group("player")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	super(delta)

#The player and enemy can deal with interactables in a specific way depending
#on their game state. The cat will take status tags from fixtures and apply
#them as well as it can. If something is usable, it will be used at that point.
#If the cat needs to take time breaking through the space, it will stall to
#work on said space.
func interact(activePiece):
	boardPiece = activePiece
	if (boardPiece == null):
		self.is_hidden = false
		return
	
	if (boardPiece.Status_tags.has("HIDDEN")):
		self.is_hidden = true
	else:
		self.is_hidden = false
		
	boardPiece.interact()
