extends Camera2D

var SPEED = 800
var dragging = false
var start_pos = Vector2()
var start_cam_pos = Vector2()

func _ready():
	set_process_input(true)
	
		
func _input(event):
	if 	event is InputEventMouseButton:
		if event.is_pressed():
			dragging = true
		else:
			dragging = false
			
	if event is InputEventMouseMotion and dragging:
		position = position - event.relative

			
			