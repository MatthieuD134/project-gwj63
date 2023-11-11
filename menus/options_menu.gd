extends Control

signal back_button_pressed()


func _ready():
	initialize_focus()


func _on_back_button_pressed():
	back_button_pressed.emit()

# -----------------
# Utility functions
# -----------------
func initialize_focus() -> void:
	$MarginContainer/VBoxContainer/BackButton.grab_focus()
