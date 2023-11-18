extends Control

@export var label_text: String

# Called when the node enters the scene tree for the first time.
func _ready():
	$Label.set_text(label_text)
	$AnimationPlayer.play("fade_and_grow")
