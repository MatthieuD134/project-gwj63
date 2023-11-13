extends Interactable

var break_time : float
var broken : bool = false
# Called when the node enters the scene tree for the first time.
func _ready():
	super()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if (break_time > 0):
		break_time -= delta
	else:
		broken = true


#Some permeables need to be broken before letting the cat through them.
func interact():
	if (break_time > 0):
		set_process(true)
