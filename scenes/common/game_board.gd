# Represents and manages the game board. Stores references to entities that are in each cell and
# tells whether cells are occupied or not.
# Units can only move around the grid one at a time.
class_name GameBoard
extends Node2D

# This constant represents the directions in which a unit can move on the board. We will reference
# the constant later in the script.
const DIRECTIONS = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]

# Once again, we use our grid resource that we explicitly define in the class.
@export var grid: Resource = preload("res://ressources/grid_board.tres")

@export var enemies: Node2D
@export var player: Player
@onready var tilemap: TileMap = $TileMap

var _pathfinder: PathFinder


# We use a dictionary to keep track of the units that are on the board. Each key-value pair in the
# dictionary represents a unit. The key is the position in grid coordinates, while the value is a
# reference to the unit.
# Mapping of coordinates of a cell to a reference to the unit it contains.
var _units := {}
var _obstacles := {}
var _walkable_for_player_only := {}


# At the start of the game, we initialize the game board. Look at the `_reinitialize()` function below.
# It populates our `_units` dictionary.
func _ready() -> void:
	_reinitialize()
	assert(enemies, "Enemies node is null")
	assert(player, "Player node is null")
	assert(tilemap, "TileMap node is null")


# Returns `true` if the cell is occupied by a unit.
func is_occupied(cell: Vector2, is_player: bool) -> bool:
	if (_units.has(cell) or _obstacles.has(cell)): return true
	if not is_player and _walkable_for_player_only.has(cell): return true
	return false


# Clears, and refills the `_units` dictionary with game objects that are on the board.
func _reinitialize() -> void:
	_units.clear()
	
	# register the player as occupying a cell
	_units[player.cell] = player
	
	var obstacles_cells = tilemap.get_used_cells(1) # the obstacles are set in the layer with index 1 in the tilemap
	
	for cell in obstacles_cells:
		_obstacles[Vector2(cell)] = tilemap.get_cell_tile_data(1, cell)

	# In this demo, we loop over the node's children and filter them to find the units. As your game
	# becomes more complex, you may want to use the node group feature instead to place your units
	# anywhere in the scene tree.
#	for enemy in enemies.get_children():
#		# We can use the "as" keyword to cast the child to a given type. If the child is not of type
#		# Unit, the variable will be null.
#		var unit := enemy as Enemy
#		if not unit:
#			continue
		# As mentioned when introducing the units variable, we use the grid coordinates for the key
		# and a reference to the unit for the value. This allows us to access a unit given its grid
		# coordinates.
#		_units[unit.cell] = unit

# Returns an array of cells a given unit can walk using the flood fill algorithm.
func get_walkable_cells(unit: Unit) -> Array:
	return _flood_fill(unit.cell, unit.move_range, unit == player)


# Returns an array with all the coordinates of walkable cells based on the `max_distance`.
func _flood_fill(cell: Vector2, max_distance: int, is_player: bool) -> Array:
	# This is the array of walkable cells the algorithm outputs.
	var array := []
	# The way we implemented the flood fill here is by using a stack. In that stack, we store every
	# cell we want to apply the flood fill algorithm to.
	var stack := [cell]
	# We loop over cells in the stack, popping one cell on every loop iteration.
	while not stack.is_empty():
		var current = stack.pop_back()

		# For each cell, we ensure that we can fill further.
		#
		# The conditions are:
		# 1. We didn't go past the grid's limits.
		# 2. We haven't already visited and filled this cell
		# 3. We are within the `max_distance`, a number of cells.
		if not grid.is_within_bounds(current):
			continue
		if current in array:
			continue

		# This is where we check for the distance between the starting `cell` and the `current` one.
		var difference: Vector2 = (current - cell).abs()
		var distance := int(difference.x + difference.y)
		if distance > max_distance:
			continue

		# If we meet all the conditions, we "fill" the `current` cell. To be more accurate, we store
		# it in our output `array` to later use them with the UnitPath and UnitOverlay classes.
		array.append(current)
		# We then look at the `current` cell's neighbors and, if they're not occupied and we haven't
		# visited them already, we add them to the stack for the next iteration.
		# This mechanism keeps the loop running until we found all cells the unit can walk.
		for direction in DIRECTIONS:
			var coordinates: Vector2 = current + direction
			# This is an "optimization". It does the same thing as our `if current in array:` above
			# but repeating it here with the neighbors skips some instructions.
			if is_occupied(coordinates, is_player):
				continue
			if coordinates in array:
				continue
			# This is where we extend the stack.
			stack.append(coordinates)
	return array


# Updates the _units dictionary with the target position for the unit and asks the _active_unit to
# walk to it.
func _move_unit(unit: Unit, new_cell: Vector2) -> void:
	var walkable_cells := get_walkable_cells(unit)
	_pathfinder = PathFinder.new(grid, walkable_cells)
	
	if is_occupied(new_cell, unit == player) or not new_cell in walkable_cells:
		return
	
	# When moving a unit, we need to update our `_units` dictionary. We instantly save it in the
	# target cell even if the unit itself will take time to walk there.
	# While it's walking, the player won't be able to issue new commands.
	_units.erase(player.cell)
	_units[new_cell] = unit
  
	# We then ask the unit to walk along the path stored in the UnitPath instance and wait until it
	# finished.
	var path := _pathfinder.calculate_point_path(unit.cell, new_cell)
	# Ensure that the path calculated is within reach
	# The calculated path includes the player position, so it should include a maximum of the player movement range + 1
	# TODO: we might want to remove that check in the future and instead use a system of wether the cell is within reach AND in the unit's sight
	if path.size() > player.move_range + 1:
		return
	player.walk_along(_pathfinder.calculate_point_path(player.cell, new_cell))
	await player.walk_finished

# player is within range of enemy if positionned on an adjacent tile
# ie: within a distance of 1 to the enemy's cell
func is_player_within_enemy_range(enemy: Enemy):
	return player.cell.distance_to(enemy.cell) <= 1

# --------------------------------
#    EXTERNAL SIGNALS HANDLING
# --------------------------------
# called when left clicking or press enter/space
func _on_cursor_accept_pressed(cell):
	_move_unit(player, cell)

# called whenever the player cell changes
func _on_player_cell_changed(prev_cell, new_cell, unit):
	_units.erase(prev_cell)
	_units[new_cell] = unit
	var enemie_nodes = enemies.get_children()
	for node in enemie_nodes:
		if node as Enemy:
			print(is_player_within_enemy_range(node))
