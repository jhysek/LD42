extends Node2D

var preScript = preload("res://scripts/softnoise.gd")
var Player    = preload("res://Components/Player.tscn")
var softnoise
#var map_size = Vector2(16,16)
var map_size = Vector2(24,24)

onready var camera = $Camera2D
onready var map    = $TileMap
onready var cursor = $Cursor

var current_player = null
var current_team   = "TeamB"
var sliced_border_width = 0

var selected_player = null
var players = {
	"a": [],
	"b": []
}

func generate_terain():
	randomize()
	var tilemap = $TileMap
	softnoise = preScript.SoftNoise.new(randi())
	for x in range(map_size.x):
		for y in range(map_size.y):
			var v = softnoise.openSimplex2D(x*0.2, y*0.2)
			if v < -0.5:
				tilemap.set_cell(x, y, -1)
			elif v < 0:
				tilemap.set_cell(x, y, 3)
			elif v < 0.5:
				tilemap.set_cell(x, y, 1)
			else:
				tilemap.set_cell(x, y, 0)

func generate_players():
	for team in players.keys():
		for player in players[team]:
			player.queue_free()

	players = {"a": [], "b": []}

	for i in range(3):
		var new_player = Player.instance()
		new_player.set_type(i)
		new_player.map = map
		new_player.add_to_group("Opponent")
		players["a"].append(new_player)
		$Players/TeamA.add_child(new_player)
		place_player(new_player, "top")

	for i in range(3):
		var new_player = Player.instance()
		new_player.set_type(i)
		new_player.map = map
		new_player.add_to_group("Player")
		players["b"].append(new_player)
		$Players/TeamB.add_child(new_player)
		place_player(new_player, "bottom")

func get_random_starting_pos(corner):
	var x = randi() % 3
	var y = randi() % 3
	var map_pos = Vector2(x, y)
	if corner == "bottom":
		map_pos = map_size - Vector2(x + 1, y + 1)
	return map_pos

func player_placed_at(map_pos):
	var res = null

	for player in $Players/TeamA.get_children():
		if player.map_pos == map_pos:
			res = player
			break

	for player in $Players/TeamB.get_children():
		if player.map_pos == map_pos:
			res = player
			break

	return res


func place_player(player, corner):
	print("Placing player to " + corner)
	var map_pos = get_random_starting_pos(corner)
	while player_placed_at(map_pos) != null:
		print("player at: " + str(map_pos))
		map_pos = get_random_starting_pos(corner)
	player.set_map_position(map_pos)

func select_player_at(map_pos):
	var player = player_placed_at(map_pos)
	if player and player.is_in_group("Player"):
		for player in $Players/TeamB.get_children():
			player.unselect()
		
		if player.select():
			current_player = player
			update_selected_player_info()
			
func update_selected_player_info():
	if current_player:
		$CanvasLayer/Panel/Title.text = current_player.unit_type_name()
		$CanvasLayer/Panel/HP.text = "Hitpoints: " + str(current_player.hp) + " / " + str(current_player.max_hp)
		$CanvasLayer/Panel/AP.text = "Action points: " + str(current_player.ap) + " / " + str(current_player.max_ap)
		
func _ready():
	generate_terain()
	set_process(true)
	set_process_input(true)
	generate_players()

func _input(event):
	var screen        = get_viewport_rect().size
	var camera_offset = Vector2(screen.x / 2, screen.y / 2)

	if event is InputEventMouseMotion:
		var world_pos = get_global_mouse_position()
		var map_pos = map.world_to_map(world_pos)
		cursor.set_offset(map.map_to_world(map_pos))
		$CanvasLayer/Label.text = str(map_pos)

	if event is InputEventMouseButton:
		var world_pos = get_global_mouse_position()
		var map_pos = map.world_to_map(world_pos)

		if current_player and current_player.can_move_to(map_pos) and player_placed_at(map_pos) == null:
			current_player.jump_to(map_pos)
		else:
			select_player_at(map_pos)


func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		generate_terain()
		generate_players()


func slice_border():
	for i in range (sliced_border_width, map_size.x - sliced_border_width ):
		destroy_cell(sliced_border_width, i)
		destroy_cell(map_size.x - sliced_border_width - 1, i)
		destroy_cell(i, sliced_border_width)
		destroy_cell(i, map_size.y - sliced_border_width - 1)

		
	sliced_border_width = sliced_border_width + 1
		

func destroy_cell(x, y):
	map.set_cell(x, y, -1)
			
	for player in players["a"]:
		if player.is_in_position(x, y):
			player.die()
	
	for player in players["b"]:
		if player.is_in_position(x, y):
			player.die()		

func end_turn():
	for player in players["a"]:
		player.reset_ap()
	for player in players["b"]:
		player.reset_ap()
