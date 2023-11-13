extends Interactable

var status_tags : PackedStringArray
# Called when the node enters the scene tree for the first time.
func _ready():
	super()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	super(delta)

#Fixtures have ongoing interactions. As of yet, it is unclear how to
#implement this particular interaction.
func interact():
	pass
