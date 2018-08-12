extends Camera2D

var SPEED = 800
var dragging = false
var start_pos = Vector2()
var start_cam_pos = Vector2()

func _ready():
	set_process(true)
	set_process_input(true)
	
func _process(delta):
	var pos = position
	if Input.is_action_pressed("ui_up"):
		pos.y = pos.y - delta * SPEED
		
	if Input.is_action_pressed("ui_down"):
		pos.y = pos.y + delta * SPEED
	
	if Input.is_action_pressed("ui_left"):
		pos.x = pos.x - delta * SPEED
	
	if Input.is_action_pressed("ui_right"):
		pos.x = pos.x + delta * SPEED

	position = pos
	
	
func _input(event):
	if 	event is InputEventMouseButton:
		if event.is_pressed():
			dragging = true
		else:
			dragging = false
			
	if event is InputEventMouseMotion and dragging:
		position = position - event.relative

			
			