extends TextureButton



func _on_focus_entered():
	var tween = get_tree().create_tween()
	tween.tween_property(self, "scale", Vector2(1.1,1.1), 0.2 )


func _on_focus_exited():
	var tween = get_tree().create_tween()
	tween.tween_property(self, "scale", Vector2(1,1), 0.2 )


func _on_mouse_entered():
	var tween = get_tree().create_tween()
	tween.tween_property(self, "scale", Vector2(1.1,1.1), 0.2 )



func _on_mouse_exited():
#	if not self.has_focus():
		var tween = get_tree().create_tween()
		tween.tween_property(self, "scale", Vector2(1,1), 0.2 )
