extends Node
class_name Interactable

#This is the parent class for our three secondary tile details. We will create
#a template here for our three types to follow.

@export var owners : PackedVector2Array
@export_group("Animation")
@export var animation : AnimationPlayer
@export var animation_frames : int
@export var animation_title : String
@export_group("Consumable")
@export var fixable : bool = false
@export var usable : bool = false
@export_group("Fixture")
@export var status_tags : PackedStringArray
@export_group("Permeable")
@export var enable : bool = false
@export var break_time : float = 0.0
@export var resettable : bool = false
var break_reset

# Called when the node enters the scene tree for the first time.
func _ready():
	assert(animation, "Interactables must have a sprite representing them on the Game Board.")
	
	var player = get_tree().get_first_node_in_group("player")
	if player as Player:
		player.connect("cell_changed", _on_player_cell_changed )
	#print(owners)
	if (enable):
		report_owners()
	break_reset = break_time
	animation.stop(false)
	#var gameBoard = get_node("GameBoard")
	#gameBoard.connect("cell_changed", _on_cell_changed)
	set_process(false)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if (break_time > 0):
		break_time -= delta
	else:
		reset()
	
#We are expecting the signal to reach all of our interactables, meaning
#we have to check to see if we have the correct one.
func _on_player_cell_changed(old_cell : Vector2, cell : Vector2, actor : Unit):
	#print("Signal Received")
	if (owners.has(cell) && !owners.has(old_cell)) :
		#print("You just entered an Interactable")
		interact()
		actor.interact(self)
	else:
		if (owners.has(old_cell) && !owners.has(cell)):
			#print("You just exited an Interactable")
			actor.interact(null)
			reset()
		
#This function is the starting point of our interactable code and how they behave.
func interact():
	if ((break_time > 0) && (enable)):
		print("This Interactable is a Permeable that requires some work to use")
		set_process(true)
		
	if usable:
		#print("This Interactable is Consumable")
		use()
		
func reset():
	set_process(false)
	if resettable:
		print("You will need to work to reenter this Permeable")
		break_time = break_reset
		
func use():
	animation.play(animation_title)
	usable = false

func _on_animation_player_animation_finished(anim_name):
	animation.stop(true)
	
func report_owners():
	return owners
