extends Control

@onready var badCat : String = "Cuddle Time"
@onready var badCatI : TextureRect = $CuddleTime

func _ready():
	self.hide()

func _on_main_menu_button_pressed():
	get_tree().set_pause(false)
	get_tree().change_scene_to_file("res://menus/main_menu.tscn")
	badCatI.visible = false
	badCat = "Cuddle Time"
	badCatI = $CuddleTime


func _on_quit_button_pressed():
	get_tree().quit()

func initialize_focus() -> void:
	$PauseMenuContainer/VBoxContainer2/VBoxContainer/MainMenuButton.grab_focus()

func game_over(infamy, infamyMax) -> void:
	#print(infamy)
	if (infamy >= infamyMax):
		badCat = "FINE! YOU WIN!"
		badCatI = $Win
	else:
		if ((infamy/infamyMax) > 0.10):
			badCat = "No! Bad Cat!"
			badCatI = $Spray
		if ((infamy/infamyMax) > 0.50):
			badCat = "I GOT YOU NOW! \nYOU ARE A VERY BAD CAT"
			badCatI = $Anger
	get_node("PauseMenuContainer/VBoxContainer2/Label").text = badCat
	badCatI.visible = true
	self.show()
	get_tree().set_pause(true)
	initialize_focus()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
