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
		damage      = 2 
	},
	
	# KNIGHT
	{	
		name        = "Knight",
	    ap          = 3,
		hp          = 40,
		attack_cost = 3,
		damage      = 10
	},
	
	# ARCHER
	{
		name        = "Archer",
		ap          = 3,
		hp          = 15,
		attack_cost = 2,
		damage      = 5
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

var action_radius = {}
var attack_radius = {}


func init(game, is_ai):
	map = game.map
	
	if is_ai:
		ai = AI.new()
		ai.initialize(self, game)
		
		$Sprite.modulate = Color(1,0,0)
	else:
		$Sprite.modulate = Color(0,0,1)

func set_type(type):
	if type == UNIT_SCOUT || type == UNIT_ARCHER || type == UNIT_KNIGHT:
		unit_type = type
		ap = units[unit_type].ap
		hp = units[unit_type].hp
		max_hp = hp
		max_ap = ap
		attack_cost = units[unit_type].attack_cost
		damage = units[unit_type].damage
		update_hp_indicator()
		update_ap_indicator()
		
		if unit_type == UNIT_ARCHER:
			$Sprite.texture = load("res://Assets/player_placeholder_archer.png")
		if unit_type == UNIT_KNIGHT:
			$Sprite.texture = load("res://Assets/player_placeholder_knight.png")
		if unit_type == UNIT_SCOUT:
			$Sprite.texture = load("res://Assets/player_placeholder_scout.png")
	else:
		print("ERROR: UNKNOWN UNIT TYPE: " + str(type))

func can_shoot():
	return unit_type == UNIT_ARCHER

func attack(enemy):
	if attack_radius.has(enemy.map_pos) and ap >= attack_cost:
		print("Enemy FIRED")
		enemy.hit(damage)
		ap = ap - attack_cost
		update_ap_indicator()
		show_radius()
		

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
	hp = hp - damage
	if hp <= 0:
		die()
	else:
		update_hp_indicator()
		
func set_map_position(new_map_pos):
	map_pos = new_map_pos
	position = map.map_to_world(map_pos)
	
func jump_to(pos):
	if action_radius.has(pos):
	  var cost = map_pos - pos
	  cost = abs(cost.x) + abs(cost.y)
	  ap = ap - cost
	  update_ap_indicator()
	  set_map_position(pos)
	  show_radius()
	
func select():
	if status != STATUS_DEAD:
		selected = true
		show_radius()
		return true
	else:
		return false
		
func unselect():
	selected = false
	hide_radius()
	
func die():
	status = STATUS_DEAD
	selected = false
	hide()
	print("PLAYER HAS DIED")
	
func alive():
	return status != STATUS_DEAD
	
func count_action_radius_from(pos, iterations, positions):
	if iterations > 0 and map.get_cell(pos.x, pos.y) >= 0:
	
		var left   = pos + Vector2(1,0)
		var right  = pos + Vector2(-1,0)
		var top    = pos + Vector2(0,-1)
		var bottom = pos + Vector2(0,1)
	
		positions[pos] = true
		if map.get_cellv(left) >= 0:
			action_radius[left]   = true
		
		if map.get_cellv(right) >= 0:
			action_radius[right]  = true
		
		if map.get_cellv(top) >= 0:
			action_radius[top]    = true
		
		if map.get_cellv(bottom) >= 0:
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
		ai.calculate_next_move()
		
