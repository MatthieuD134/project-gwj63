# Player-controlled cursor. Allows them to navigate the game grid, and lead the cat player
# Supports both keyboard and mouse (or touch) input.
# The `tool` mode allows us to preview the drawing code you'll see below in the editor.
@tool
class_name Cursor
extends Node2D



# --------------------
# 		SIGNALS
# --------------------
# We'll use signals to keep the cursor decoupled from other nodes.
# When the player moves the cursor or wants to interact with a cell, we emit a signal and let
# another node handle the interaction.

# Emitted when clicking on the currently hovered cell or when pressing "ui_accept".
signal accept_pressed(cell: Vector2)
# Emitted when the cursor moved to a new cell.
signal moved(new_cell: Vector2)



# --------------------
# 		VARIABLES
# --------------------
# Grid resource, giving the node access to the grid size, and more.
@export var grid: Resource = preload("res://ressources/grid_board.tres")
# Time before the cursor can move again in seconds.
# You can see how we use it in the unhandled input function below.
@export var ui_cooldown := 0.1

# Coordinates of the current cell the cursor is hovering.
var cell := Vector2.ZERO : set = set_cell

# We use the timer to have a cooldown on the cursor movement.
@onready var _timer: Timer = $Timer
@onready var sprite: Sprite2D = $Sprite2D
@onready var follow_mouse := true
@onready var attention : AnimationPlayer = $AnimationPlayer


# --------------------
# 	MAIN FUNCTIONS
# --------------------
# When the cursor enters the scene tree, we snap its position to the centre of the cell and we
# initialise the timer with our ui_cooldown variable.
func _ready() -> void:
	_timer.wait_time = ui_cooldown
	position = grid.calculate_map_position(cell)
	sprite.global_position = position
	
	# disable the mouse so that the sprite referenced in this script is used as replacement
	# This allows us to animate the cursor if needed
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)


func _unhandled_input(event: InputEvent) -> void:
	if not follow_mouse: return
	# If the user moves the mouse, we capture that input and update the node's cell in priority.
	if event is InputEventMouseMotion:
		var global_mouse_position := get_global_mouse_position()
		self.cell = grid.calculate_grid_coordinates(global_mouse_position)
		sprite.global_position = global_mouse_position
	# If we are already hovering the cell and click on it, or we press the enter key, the player
	# wants to interact with that cell.
	elif event.is_action_pressed("click") or event.is_action_pressed("ui_accept"):
		#  In that case, we emit a signal to let another node handle that input. The game board will
		#  have the responsibility of looking at the cell's content.
		emit_signal("accept_pressed", cell)
		draw_attention()

		get_viewport().set_input_as_handled()

	# The code below is for the cursor's movement.
	# The following lines make some preliminary checks to see whether the cursor should move or not
	# if the user presses an arrow key.
	var should_move := event.is_pressed()
	# If the player is pressing the key in this frame, we allow the cursor to move. If they keep the
	# keypress down, we only want to move after the cooldown timer stops.
	if event.is_echo():
		should_move = should_move and _timer.is_stopped()

	# And if the cursor shouldn't move, we prevent it from doing so.
	if not should_move:
		return

	# Here, we update the cursor's current cell based on the input direction. See the set_cell()
	# function below to see what changes that triggers.
	if event.is_action("ui_right"):
		self.cell += Vector2.RIGHT
		sprite.position = Vector2.ZERO
	elif event.is_action("ui_up"):
		self.cell += Vector2.UP
		sprite.position = Vector2.ZERO
	elif event.is_action("ui_left"):
		self.cell += Vector2.LEFT
		sprite.position = Vector2.ZERO
	elif event.is_action("ui_down"):
		self.cell += Vector2.DOWN
		sprite.position = Vector2.ZERO


# We use the draw callback to a rectangular outline the size of a grid cell, with a width of two
# pixels.
func _draw() -> void:
	# Rect2 is built from the position of the rectangle's top-left corner and its size. To draw the
	# square around the cell, the start position needs to be `-grid.cell_size / 2`.
	draw_rect(Rect2(-grid.cell_size / 2, grid.cell_size), Color.RED, false, 10.0)


# This function controls the cursor's current position.
func set_cell(value: Vector2) -> void:
	# We first clamp the cell coordinates and ensure that we weren't trying to move outside the
	# grid's boundaries.
	var new_cell: Vector2 = grid.clamp(value)
	if new_cell.is_equal_approx(cell):
		return

	cell = new_cell
	# If we move to a new cell, we update the cursor's position, emit a signal, and start the
	# cooldown timer that will limit the rate at which the cursor moves when we keep the direction
	# key down.
	position = grid.calculate_map_position(cell)
	emit_signal("moved", cell)
	_timer.start()

func draw_attention() -> void:
	follow_mouse = false
	attention.play("cursorSelect")
	#var tween = get_tree().create_tween()
	## animate the global position of the laser sprite to randomly go around the center of the current selected cell
	#var number_of_position := 10
	#var movement_range = (grid.cell_size / 3 as Vector2).x
	#for i in range(number_of_position):
	#	tween.tween_property(sprite, "global_position", get_random_position_around(self.global_position, movement_range, movement_range), .5/number_of_position)
	## once tween is finished, bring back posibility to move the mouse again
	#var resume_mouse_follow = func(): follow_mouse = true
	#tween.connect("finished", resume_mouse_follow)


func get_random_position_around(pos: Vector2, rangeX: float, rangeY: float) -> Vector2:
	return pos + Vector2(randf_range(-rangeX, rangeX), randf_range(-rangeY, rangeY))


func _on_animation_player_animation_finished(anim_name):
	follow_mouse = true
