extends Node2D

var Indicator = preload("res://Components/RadiusIndicator.tscn")

const STATUS_ALIVE = 1
const STATUS_DEAD  = 0

const UNIT_SCOUT = 0
const UNIT_KNIGHT = 1
const UNIT_ARCHER = 2 

var units = [
	# SCOUT
	{
		name        = "Scout",
		ap          = 4,
		hp          = 10,
		attack_cost = 2,
		damage      = 2 
	},
	
	# KNIGHT
	{	
		name        = "Knight",
	    ap          = 2,
		hp          = 20,
		attack_cost = 2,
		damage      = 10
	},
	
	# ARCHER
	{
		name        = "Archer",
		ap          = 3,
		hp          = 8,
		attack_cost = 2,
		damage      = 5
	}
]

onready var map = get_node("/root/Game/TileMap")
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



func _ready(_map):
	map = _map

func set_type(type):
	if type == UNIT_SCOUT || type == UNIT_ARCHER || type == UNIT_KNIGHT:
		print(units)
		unit_type = type
		ap = units[unit_type].ap
		hp = units[unit_type].hp
		max_hp = hp
		max_ap = ap
		attack_cost = units[unit_type].attack_cost
		damage = units[unit_type].damage
		update_hp_indicator()
		# set sprite
	else:
		print("ERROR: UNKNOWN UNIT TYPE: " + str(type))

func unit_type_name():
	return units[unit_type].name

func reset_ap():
	ap = max_ap
	
func update_hp_indicator():
	$HPIndicator.max_value = units[unit_type].hp
	$HPIndicator.value     = hp
	
func damage(damage_hp):
	hp = hp - damage_hp
	if hp <= 0:
		die()
	else:
		update_hp_indiator()
		
func set_map_position(new_map_pos):
	map_pos = new_map_pos
	position = map.map_to_world(map_pos)
	
func jump_to(pos):
	if action_radius.has(pos):
	  var cost = map_pos - pos
	  cost = abs(cost.x) + abs(cost.y)
	  ap = ap - cost
	  set_map_position(pos)
	
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
	

func count_action_radius_from(pos, iterations, positions):
	if iterations <= 0:
		return
		
	var left   = pos + Vector2(1,0)
	var right  = pos + Vector2(-1,0)
	var top    = pos + Vector2(0,-1)
	var bottom = pos + Vector2(0,1)
	
	positions[pos]        = true
	action_radius[left]   = true
	action_radius[right]  = true
	action_radius[top]    = true
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

	
func show_radius():
	hide_radius()
	count_action_radius_from(map_pos, ap, {})
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