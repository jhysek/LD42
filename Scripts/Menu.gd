extends Node2D


func _on_Start_Game_pressed():
	$Click.play()
	get_tree().change_scene("res://Scenes/Game.tscn")

func _on_Quit_pressed():
	$Click.play()
	get_tree().quit()

func _on_btn_mouse_entered():
	$Click.play()
	