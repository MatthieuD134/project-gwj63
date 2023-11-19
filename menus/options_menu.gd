extends Control

signal back_button_pressed()

var master_bus := AudioServer.get_bus_index("Master")
var MIN := -30
var MAX := 0


func _ready():
	initialize_focus()
	$MarginContainer/VBoxContainer/Label/HSlider.set_min(MIN)
	$MarginContainer/VBoxContainer/Label/HSlider.set_max(MAX)
	

func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		back_button_pressed.emit()


func _on_back_button_pressed():
	back_button_pressed.emit()

# -----------------
# Utility functions
# -----------------
func initialize_focus() -> void:
	$MarginContainer/VBoxContainer/Label/HSlider.grab_focus()


func _on_h_slider_value_changed(value):
	AudioServer.set_bus_volume_db(master_bus, value)
	AudioServer.set_bus_mute(master_bus, value == MIN)
