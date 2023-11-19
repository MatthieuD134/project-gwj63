extends Node2D
class_name Interactable

#This is the parent class for our three secondary tile details. We will create
#a template here for our three types to follow.

@export var infamy : int = 1
@export var emitting_marker: Marker2D
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
var owners: PackedVector2Array
var emitting_cell: Vector2
signal infamy_transmit(infamy)

@export var grid: Resource = preload("res://ressources/grid_board.tres")

# Called when the node enters the scene tree for the first time.
func _ready():
	assert(animation, "Interactables must have a sprite representing them on the Game Board.")
	
	var player = get_tree().get_first_node_in_group("player")
	if player as Player:
		player.connect("cell_changed", _on_player_cell_changed )
	
	var ownerMarkers = $OwnersMarkers.get_children()
	for marker in ownerMarkers:
		if marker as Marker2D:
			owners.append(grid.calculate_grid_coordinates(marker.global_position))
	
	if emitting_cell:
		emitting_cell = grid.calculate_grid_coordinates(emitting_marker.global_position)
	else: 
		emitting_cell = grid.calculate_grid_coordinates(self.global_position)

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
	if (owners.has(cell) && !owners.has(old_cell)) :
		interact()
		actor.interact(self)
		if self.enable:
			self.modulate.a = 0.5
	else:
		if (owners.has(old_cell) && !owners.has(cell)):
			actor.interact(null)
			reset()
			if self.enable:
				self.modulate.a = 1
		
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
	#print(infamy)
	infamy_transmit.emit(infamy)
	animation.play(animation_title)
	usable = false

func get_enemies_attention() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy as Enemy:
			if enemy.current_state != Enemy.game_state.CHASING and (emitting_cell - enemy.cell).abs().x + (emitting_cell - enemy.cell).abs().y <= enemy.hearing_range:
				enemy.check_suspicious_cell(emitting_cell)

func _on_animation_player_animation_finished(_anim_name):
	animation.stop(true)
	
func report_owners():
	return owners
