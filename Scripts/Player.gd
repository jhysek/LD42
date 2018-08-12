extends Node2D

var Indicator = preload("res://Components/RadiusIndicator.tscn")
var AI        = preload("res://Scripts/AI.gd")

const STATUS_ALIVE = 1
const STATUS_DEAD  = 0

const UNIT_SCOUT = 0
const UNIT_KNIGHT = 1
const UNIT_ARCHER = 2 

var units = [
	# SCOUT
	{
		name        = "Scout",
		ap          = 5,
		hp          = 20,
		attack_cost = 2,
		damage      = 2,
		speed       = 10, 
	},
	
	# KNIGHT
	{	
		name        = "Knight",
	    ap          = 3,
		hp          = 40,
		attack_cost = 3,
		damage      = 10,
		speed       = 2
	},
	
	# ARCHER
	{
		name        = "Archer",
		ap          = 3,
		hp          = 15,
		attack_cost = 2,
		damage      = 5,
		speed       = 5
	}
]

var ai
var map

var map_pos = Vector2()
var selected = false
var status    = STATUS_ALIVE
var unit_type = UNIT_SCOUT
 
var ap = 0
var hp = 0
var damage = 0
var attack_cost = 0

var max_ap = 0
var max_hp = 0
var speed = 100

var action_radius = {}
var attack_radius = {}

var target_position = Vector2()
var moving          = false


func _ready():
	set_process(true)
	
func _process(delta):
	if moving:
		if position != target_position:
			position.x = lerp(position.x, target_position.x, delta * speed)
			position.y = lerp(position.y, target_position.y, delta * speed)
			z_index = position.y
		else:
			moving = false
			
func init(game, is_ai):
	map  = game.map
	
	if is_ai:
		ai = AI.new()
		ai.initialize(self, game)
		

func set_type(type):
	if type == UNIT_SCOUT || type == UNIT_ARCHER || type == UNIT_KNIGHT:
		unit_type = type
		ap = units[unit_type].ap
		hp = units[unit_type].hp
		speed = units[unit_type].speed
		max_hp = hp
		max_ap = ap
		attack_cost = units[unit_type].attack_cost
		damage = units[unit_type].damage
		update_hp_indicator()
		update_ap_indicator()
		
		if ai:
			$Visual/Sprite.texture = load("res://Assets/unit_red_front.png")	
		else:
			$Visual/Sprite.texture = load("res://Assets/unit_blue_back.png")
			
		if unit_type == UNIT_ARCHER:
			$Visual/Sprite/Bow.show()
			$Visual/Sprite/Sword.hide()
			
		if unit_type == UNIT_KNIGHT:
			$Visual/Sprite/Bow.hide()
			$Visual/Sprite/Sword.show()
			
		if unit_type == UNIT_SCOUT:
			$Visual/Sprite/Bow.hide()
			$Visual/Sprite/Sword.hide()
		
	else:
		print("ERROR: UNKNOWN UNIT TYPE: " + str(type))

func can_shoot():
	return unit_type == UNIT_ARCHER

func attack(enemy):
	if attack_radius.has(enemy.map_pos) and ap >= attack_cost:
		
		enemy.hit(damage)
		ap = ap - attack_cost
		update_ap_indicator()
		hide_radius()
		

func unit_type_name():
	return units[unit_type].name

func reset_ap():
	ap = max_ap
	update_ap_indicator()
	hide_radius()
	
func update_hp_indicator():
	$HPIndicator.max_value = units[unit_type].hp
	$HPIndicator.value     = hp
	
func update_ap_indicator():
	$APIndicator.max_value = units[unit_type].ap
	$APIndicator.value     = ap
	
func hit(damage):
	$AnimationPlayer.play("Hit")
	$Sfx/Hit.play()
	hp = hp - damage
	if hp <= 0:
		die()
	else:
		update_hp_indicator()
		
func set_map_position(new_map_pos):
	map_pos = new_map_pos
	z_index = map_pos.y
	position = map.map_to_world(map_pos)
	
func jump_to(pos):
	if action_radius.has(pos):
	  var cost = map_pos - pos
	  cost = abs(cost.x) + abs(cost.y)
	  ap = ap - cost
	  update_ap_indicator()
	  # set_map_position(pos)
	  target_position = map.map_to_world(pos)
	  hide_radius()
	  moving = true
	  map_pos = pos

	
func select():
	if status != STATUS_DEAD:
		$AnimationPlayer.play("Active")
		selected = true
		show_radius()
		return true
	else:
		return false
		
func unselect():
	$AnimationPlayer.play("Idle")
	selected = false
	hide_radius()
	
func die():
	status = STATUS_DEAD
	selected = false
	hide()
	get_node("/root/Game").game_over_check()
	
func alive():
	return status != STATUS_DEAD
	
func count_action_radius_from(pos, iterations, positions):
	var game = get_node("/root/Game")
	if iterations > 0 and map.get_cell(pos.x, pos.y) >= 0:
	
		var left   = pos + Vector2(1,0)
		var right  = pos + Vector2(-1,0)
		var top    = pos + Vector2(0,-1)
		var bottom = pos + Vector2(0,1)
	
	    # TODO: scout can fly over holes
		positions[pos] = true
		if game.accessible_cell(map.get_cellv(left)):
			action_radius[left]   = true
		
		if game.accessible_cell(map.get_cellv(right)):
			action_radius[right]  = true
		
		if game.accessible_cell(map.get_cellv(top)):
			action_radius[top]    = true
		
		if game.accessible_cell(map.get_cellv(bottom)):
			action_radius[bottom] = true
			
		iterations = iterations - 1
	
		if iterations > 0:
			if !positions.has(left):
				count_action_radius_from(left, iterations, positions)
			if !positions.has(right):
				count_action_radius_from(right, iterations, positions)
			if !positions.has(top):
				count_action_radius_from(top, iterations, positions)
			if !positions.has(bottom):
				count_action_radius_from(bottom, iterations, positions)

func count_attack_radius_from(pos, iterations, positions):
	if iterations > 0:
		var left   = pos + Vector2(1,0)
		var right  = pos + Vector2(-1,0)
		var top    = pos + Vector2(0,-1)
		var bottom = pos + Vector2(0,1)	
		positions[pos] = true
		
		attack_radius[left]   = true
		attack_radius[right]   = true
		attack_radius[top]   = true
		attack_radius[bottom]   = true
		
		iterations = iterations - 1
		
		if iterations > 0:
			count_attack_radius_from(left, iterations, positions)
			count_attack_radius_from(right, iterations, positions)
			count_attack_radius_from(top, iterations, positions)
			count_attack_radius_from(bottom, iterations, positions)
			
			
func show_radius():
	hide_radius()
	
	action_radius = {}
	count_action_radius_from(map_pos, ap, {})
	
	attack_radius = {}
	count_attack_radius_from(map_pos, ap if unit_type == UNIT_ARCHER else 1, {})
	
	for pos in action_radius.keys():
		var indicator = Indicator.instance()
		$Radius.add_child(indicator)
		indicator.position = map.map_to_world(pos - map_pos + Vector2(1,1))
		
	
func hide_radius():
	for item in $Radius.get_children():
		item.queue_free()
	action_radius = {}
	
	
func can_move_to(map_position):
	if status == STATUS_ALIVE and action_radius.has(map_position):
		return true
	else:
		return false
		
func is_in_position(x,y):
	return map_pos == Vector2(x,y)
	
func make_ai_move():
	if ai and status == STATUS_ALIVE:
		$AnimationPlayer.play("Active")
		#ai.calculate_next_move()
		$ActionTimer.wait_time = 0.5
		$ActionTimer.start()
		
func ai_calculate_next_move():
	print("ACTION TIMER EXPIRED...")
	ai.calculate_next_move()
	$AnimationPlayer.play("Idle")
		
