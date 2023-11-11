extends Control

@onready var pause_menu = $PauseMenuContainer
@onready var options_menu = $OptionsMenu

func _ready():
	unpause()

func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		toggle_pause()
		


func _on_continue_button_pressed():
	unpause()


func _on_options_button_pressed():
	show_and_hide(options_menu, pause_menu)


func _on_main_menu_button_pressed():
	get_tree().set_pause(false)
	get_tree().change_scene_to_file("res://menus/main_menu.tscn")


func _on_quit_button_pressed():
	get_tree().quit()


func _on_options_menu_back_button_pressed():
	show_and_hide(pause_menu, options_menu)


# -----------------
# Utility functions
# -----------------
func show_and_hide(first: Control, second: Control) -> void:
	# Hide the first UI element and show the second one
	first.show()
	second.hide()
	if first.has_method("initialize_focus"):
		first.initialize_focus()
	elif first == pause_menu:
		initialize_focus()

func initialize_focus() -> void:
	$PauseMenuContainer/VBoxContainer/ContinueButton.grab_focus()

func pause() -> void:
	self.show()
	get_tree().set_pause(true)
	initialize_focus()

func unpause() -> void:
	self.hide()
	get_tree().set_pause(false)

func toggle_pause() -> void:
	if get_tree().paused: unpause()
	else: pause()
