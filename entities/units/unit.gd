# Represents the player on the game board.
# The board manages the Player's position inside the game grid.
# The player itself is only a visual representation that moves smoothly in the game world.
@tool
extends Path2D
class_name Unit



# --------------------
# 		SIGNALS
# --------------------

signal walk_finished()
signal cell_changed(prev_cell: Vector2, new_cell: Vector2, unit: Unit)



# --------------------
# 		VARIABLES
# --------------------
# Preload the `Grid.tres` resource you created in the previous part.
@export var grid: Resource = preload("res://ressources/grid_board.tres")
# Distance to which the player can walk in cells.
# We'll use this to limit the cells the player can move to.
@export var move_range := 6
# The player's move speed in pixels, when it's moving along a path.
@export var move_speed := 160.0
# The Unit sprite
@export var sprite: Sprite2D

# Coordinates of the grid's cell the player is on.
var cell := Vector2.ZERO : set = set_cell

# Through its setter function, the `_is_walking` property toggles processing for the player.
# See `_set_is_walking()` at the bottom of this code snippet.
var _is_walking := false : set = _set_is_walking
var can_move := true

@onready var _path_follow: PathFollow2D = $PathFollow2D



# --------------------
# 	UTILITY FUNCTIONS
# --------------------

# When changing the `cell`'s value, we don't want to allow coordinates outside the grid, so we clamp
# them.
func set_cell(value: Vector2) -> void:
	emit_signal("cell_changed", cell, value, self)
	cell = grid.clamp(value)


func _set_is_walking(value: bool) -> void:
	_is_walking = value
	self.set_process(_is_walking)



# --------------------
# 	MAIN FUNCTIONS
# --------------------

func _ready():
	# Make sure the sprite is set as the export variable
	assert(sprite, "ERROR: You must explicitly specify the sprite for any node inheriting the Unit script")
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

# When active, moves the unit along its `curve` with the help of the PathFollow2D node.
func _process(delta: float) -> void:
	# Every frame, the `PathFollow2D.offset` property moves the sprites along the `curve`.
	# The great thing about this is it moves an exact number of pixels taking turns into account.
	_path_follow.progress += move_speed * delta
	
	var new_cell = grid.calculate_grid_coordinates(_path_follow.global_position)
	if cell != new_cell:
		cell = new_cell
	
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
	if path.is_empty() or not can_move:
		return
	if curve.get_point_count() > 0:
		await interupt_walk()
	curve.clear_points()
	curve.add_point(Vector2.ZERO)
	
	# This code converts the `path` to points on the `curve`. That property comes from the `Path2D`
	# class the Unit extends.
	for point in path:
		curve.add_point(grid.calculate_map_position(point) - position)
	# The `_is_walking` property triggers the move animation and turns on `_process()`. See
	# `_set_is_walking()` below.
	self._is_walking = true

func interupt_walk():
	if grid.calculate_map_position(cell) == position: return
	can_move = false
	curve.clear_points()
	# add point where the curent player is currently set
	curve.add_point(Vector2.ZERO)
	# add target point, the center of the cell the player is currently at
	curve.add_point(grid.calculate_map_position(cell) - position)
	self._is_walking = true
	await self.walk_finished
	can_move = true
