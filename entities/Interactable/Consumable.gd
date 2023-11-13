extends Interactable

var fixable : bool = false
var usable : bool = true
# Called when the node enters the scene tree for the first time.
func _ready():
	super()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	super(delta)

#Consumables are usually used once, so we unset the flag to tell it to ignore
#any future interactions.
func interact():
	usable = false
