extends Control

@onready var badCat : String = "Cuddle Time"

func _ready():
	self.hide()

func _on_main_menu_button_pressed():
	get_tree().set_pause(false)
	get_tree().change_scene_to_file("res://menus/main_menu.tscn")
	badCat = "Cuddle Time"


func _on_quit_button_pressed():
	get_tree().quit()

func initialize_focus() -> void:
	$PauseMenuContainer/VBoxContainer2/VBoxContainer/MainMenuButton.grab_focus()

func game_over(infamy, max) -> void:
	if (infamy == max):
		badCat = "FINE! YOU WIN!"
	else:
		if ((infamy/max) > 0.10):
			badCat = "No! Bad Cat!"
		if ((infamy/max) > 0.50):
			badCat = "I GOT YOU NOW! \nYOU ARE A VERY BAD CAT!"
	get_node("PauseMenuContainer/VBoxContainer2/Label").text = badCat
	self.show()
	get_tree().set_pause(true)
	initialize_focus()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
