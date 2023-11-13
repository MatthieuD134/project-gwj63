extends Node
class_name Interactable

#This is the parent class for our three secondary tile details. We will create
#a template here for our three types to follow.

var owners : PackedVector2Array

@export_group("Consumable")
@export var fixable : bool = false
@export var usable : bool = false
@export_group("Fixture")
@export var Status_tags : PackedStringArray
@export_group("Permeable")
@export var break_time : float = 0.0
@export var resettable : bool = false
var break_reset

# Called when the node enters the scene tree for the first time.
func _ready():
	break_reset = break_time
	var gameBoard = get_node("res://scenes/common/game_board.gd")
	gameBoard.connect("cell_changed", _on_cell_changed)
	set_process(false)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if (break_time > 0):
		break_time -= delta
	
#We are expecting the signal to reach all of our interactables, meaning
#we have to check to see if we have the correct one.
func _on_cell_changed(cell : Vector2):
	if (owners.has(cell)) :
		interact()
		
#This function is a stub here, and must be defined by each child.
func interact():
	if (break_time > 0):
		set_process(true)
		
	if usable:
		use()
		
func use():
	usable = false
