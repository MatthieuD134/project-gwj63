# Represents the player on the game board.
# The board manages the Player's position inside the game grid.
# The player itself is only a visual representation that moves smoothly in the game world.
# We use the tool mode so the `skin` and `skin_offset` below update in the editor.
@tool
extends Path2D
class_name Unit



# --------------------
# 		SIGNALS
# --------------------

signal walk_finished()



# --------------------
# 		VARIABLES
# --------------------
# Preload the `Grid.tres` resource you created in the previous part.
@export var grid: Resource = preload("res://ressources/grid_board.tres")
# Distance to which the player can walk in cells.
# We'll use this to limit the cells the player can move to.
@export var move_range := 6
# The player's move speed in pixels, when it's moving along a path.
@export var move_speed := 32.0

# Coordinates of the grid's cell the player is on.
var cell := Vector2.ZERO : set = set_cell

# Through its setter function, the `_is_walking` property toggles processing for the player.
# See `_set_is_walking()` at the bottom of this code snippet.
var _is_walking := false : set = _set_is_walking

@onready var _path_follow: PathFollow2D = $PathFollow2D



# --------------------
# 	UTILITY FUNCTIONS
# --------------------

# When changing the `cell`'s value, we don't want to allow coordinates outside the grid, so we clamp
# them.
func set_cell(value: Vector2) -> void:
	cell = grid.clamp(value)


func _set_is_walking(value: bool) -> void:
	_is_walking = value
	self.set_process(_is_walking)



# --------------------
# 	MAIN FUNCTIONS
# --------------------

func _ready():
	# We'll use the `_process()` callback to move the unit along a path. Unless it has a path to
	# walk, we don't want it to update every frame. See `walk_along()` below.
	self.set_process(false)

	# The following lines initialize the `cell` property and snap the unit to the cell's center on the map.
	self.cell = grid.calculate_grid_coordinates(position)
	position = grid.calculate_map_position(cell)

	if not Engine.is_editor_hint():
		# We create the curve resource here because creating it in the editor prevents us from
		# moving the unit.
		curve = Curve2D.new()

#	var points := [
#		Vector2(1, 0),
#		Vector2(2, 0),
#		Vector2(2, 1),
#		Vector2(2, 2),
#		Vector2(1, 2),
#		Vector2(0, 2),
#		Vector2(0, 1),
#	]
#	walk_along(PackedVector2Array(points))

# When active, moves the unit along its `curve` with the help of the PathFollow2D node.
func _process(delta: float) -> void:
	# Every frame, the `PathFollow2D.offset` property moves the sprites along the `curve`.
	# The great thing about this is it moves an exact number of pixels taking turns into account.
	_path_follow.progress += move_speed * delta

	# When we increase the `progress` above, the 'progress_ratio` also updates. It represents how far you
	# are along the `curve` in percent, where a value of `1.0` means you reached the end.
	# When that is the case, the unit is done moving.
	if _path_follow.progress_ratio >= 1.0:
		# Setting `_is_walking` to `false` also turns off processing.
		self._is_walking = false
		# Below, we reset the offset to `0.0`, which snaps the sprites back to the Unit node's
		# position, we position the node to the center of the target grid cell, and we clear the
		# curve.
		# In the process loop, we only moved the sprite, and not the unit itself. The following
		# lines move the unit in a way that's transparent to the player.
		_path_follow.progress = 0.0
		position = grid.calculate_map_position(cell)
		curve.clear_points()
		# Finally, we emit a signal. We'll use this one with the game board.
		emit_signal("walk_finished")


# Starts walking along the `path`.
# `path` is an array of grid coordinates that the function converts to map coordinates.
func walk_along(path: PackedVector2Array) -> void:
	if path.is_empty():
		return

	# This code converts the `path` to points on the `curve`. That property comes from the `Path2D`
	# class the Unit extends.
	curve.add_point(Vector2.ZERO)
	for point in path:
		curve.add_point(grid.calculate_map_position(point) - position)
	# We instantly change the unit's cell to the target position. You could also do that when it
	# reaches the end of the path, using `grid.calculate_grid_coordinates()`, instead.
	# I did it here because we have the coordinates provided by the `path` argument.
	# The cell itself represents the grid coordinates the unit will stand on.
	cell = path[-1]
	# The `_is_walking` property triggers the move animation and turns on `_process()`. See
	# `_set_is_walking()` below.
	self._is_walking = true
