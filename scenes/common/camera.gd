extends Camera2D


# Preload the `Grid.tres` resource you created in the previous part.
@export var grid: Resource = preload("res://ressources/grid_board.tres")
# Explicitly specify the player so the camera can be attached to its underlying sprite in order to access tha  visual position of the player
# which is different from the value in player.position
@export var player: Player

# Called when the node enters the scene tree for the first time.
func _ready():
	assert(player, "ERROR: You must explicitly specify the player for the camera node")
	
	# set the camera limit according to the grid, that defines the levels limits
	self.set_limit(SIDE_LEFT, 0)
	self.set_limit(SIDE_TOP, 0)
	self.set_limit(SIDE_RIGHT, grid.cell_size.x * grid.size.x)
	self.set_limit(SIDE_BOTTOM, grid.cell_size.y * grid.size.y)
	
	# set the position smoothing
	self.set_position_smoothing_enabled(true)
	self.set_position_smoothing_speed(5)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	position = player.sprite.global_position
