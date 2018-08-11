extends Camera2D

var SPEED = 800

func _ready():
	set_process(true)

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