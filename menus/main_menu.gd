extends Control

@onready var main_menu = $MainMenuContainer
@onready var options_menu = $OptionsMenu

func _ready():
	initialize_focus()
	options_menu.hide()

func _on_start_button_pressed():
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")


func _on_options_button_pressed():
	show_and_hide(options_menu, main_menu)


func _on_quit_button_pressed():
	get_tree().quit()
	

func _on_options_menu_back_button_pressed():
	show_and_hide(main_menu, options_menu)


# -----------------
# Utility functions
# -----------------
func show_and_hide(first: Control, second: Control) -> void:
	# Hide the first UI element and show the second one
	first.show()
	second.hide()
	if first.has_method("initialize_focus"):
		first.initialize_focus()
	elif first == main_menu:
		initialize_focus()

func initialize_focus() -> void:
	$MainMenuContainer/VBoxContainer/StartButton.grab_focus()
