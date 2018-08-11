extends Node2D

var preScript = preload("res://scripts/softnoise.gd")
var Player    = preload("res://Components/Player.tscn")
var softnoise
var map_size = Vector2(16,16)

onready var camera = $Camera2D
onready var map    = $TileMap
onready var cursor = $Cursor

var game_over = false
var current_player = null
var current_team   = "TeamB"
var current_turn   = 1
var sliced_border_width = 0
var traversing_graph 

var cell_markers = []

var selected_player = null
var players = {
	"a": [],
	"b": []
}

func _ready():
	generate_terain()
	generate_graph()
	set_process(true)
	set_process_input(true)
	generate_players()
	game_over = false

func _input(event):
	if game_over:
		if Input.is_action_just_pressed("ui_accept"):
			reset_game()
		return
		
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

		if current_player and current_player.attack_radius.has(map_pos) and enemy_placed_at(map_pos) and current_player.ap >= current_player.attack_cost:
			current_player.attack(enemy_placed_at(map_pos))
			update_selected_player_info()
		 
		elif current_player and current_player.can_move_to(map_pos) and player_placed_at(map_pos) == null:
			current_player.jump_to(map_pos)
			update_selected_player_info()
		else:
			select_player_at(map_pos)


func game_over_check():
	var active_enemies = 0
	var active_players = 0
	
	for enemy in players["a"]:
		if enemy.alive():
			active_enemies += 1
				
	for player in players["b"]:
		if player.alive():
			active_players += 1
			
	if active_enemies <= 0 and active_players <= 0:
		# Draw
		print("Draw")
		game_over = true
			
	if active_enemies <= 0 and active_players > 0:
		# You win
		$CanvasLayer/GameOver/Anim.play("Victory")
		game_over = true
		
	if active_enemies > 0 and active_players <= 0:
		# you lose		
		$CanvasLayer/GameOver/Anim.play("Defeat")
		game_over = true

func generate_terain():
	randomize()
	var tilemap = $TileMap
	softnoise = preScript.SoftNoise.new(randi())
	for x in range(map_size.x):
		for y in range(map_size.y):
			var v = softnoise.openSimplex2D(x*0.2, y*0.2)
			if v < -0.4:
				tilemap.set_cell(x, y, -1)
			elif v < 0:
				tilemap.set_cell(x, y, 2)
			elif v < 0.5:
				tilemap.set_cell(x, y, 1)
			else:
				tilemap.set_cell(x, y, 7)


func get_cell_id(x, y):
	return x + map_size.y * y
		
func generate_graph():
	if !traversing_graph:
		traversing_graph = AStar.new()
	else:
		traversing_graph.clear()
		
	var tilemap = $TileMap
	
	# Add nodes
	for x in range(0, map_size.x):
		for y in range(0, map_size.y):
			if tilemap.get_cell(x, y) >= 0:
				traversing_graph.add_point(get_cell_id(x, y), Vector3(x, y, 0))  
	
	# Add connections
	for x in range(0, map_size.x):
		for y in range(0, map_size.y):
			var cell_id = get_cell_id(x, y)
			if traversing_graph.has_point(cell_id):
				# get neighbours
				if tilemap.get_cell(x + 1, y) >= 0:
					traversing_graph.connect_points(cell_id, get_cell_id(x+1, y))
					
				if tilemap.get_cell(x, y + 1) >= 0:
					traversing_graph.connect_points(cell_id, get_cell_id(x, y + 1))
					

func get_nearest_path(from, to):
	return traversing_graph.get_point_path(get_cell_id(from.x, from.y), get_cell_id(to.x, to.y))

func generate_players():
	for team in players.keys():
		for player in players[team]:
			player.queue_free()

	players = {"a": [], "b": []}

	for i in range(3):
		var new_player = Player.instance()
		new_player.set_type(i)
		new_player.init(self, true)
		new_player.add_to_group("Opponent")
		players["a"].append(new_player)
		$Players/TeamA.add_child(new_player)
		place_player(new_player, "top")

	for i in range(3):
		var new_player = Player.instance()
		new_player.set_type(i)
		new_player.init(self, false)
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

func enemy_placed_at(map_pos):
	for enemy in players["a"]:
		if enemy.map_pos == map_pos and enemy.alive():
			return enemy
	return null

func player_placed_at(map_pos):
	for player in $Players/TeamA.get_children():
		if player.map_pos == map_pos and player.alive():
			return player

	for player in $Players/TeamB.get_children():
		if player.map_pos == map_pos and player.alive():
			return player

	return null


func place_player(player, corner):
	var map_pos = get_random_starting_pos(corner)
	while player_placed_at(map_pos) != null:
		map_pos = get_random_starting_pos(corner)
	player.set_map_position(map_pos)

func select_player_at(map_pos):
	var player = player_placed_at(map_pos)
	if player and player.is_in_group("Player"):
		for player in $Players/TeamB.get_children():
			player.unselect()
		
		if player.selected:
			current_player = null
			update_selected_player_info()
		elif player.select():
			current_player = player
			update_selected_player_info()
			
func update_selected_player_info():
	if current_player:
		$CanvasLayer/Panel/Title.text = current_player.unit_type_name()
		$CanvasLayer/Panel/HP.text = "Hitpoints: " + str(current_player.hp) + " / " + str(current_player.max_hp)
		$CanvasLayer/Panel/AP.text = "Action points: " + str(current_player.ap) + " / " + str(current_player.max_ap)
	else:
		$CanvasLayer/Panel/Title.text = ""
		$CanvasLayer/Panel/HP.text = ""
		$CanvasLayer/Panel/AP.text = ""
		

func slice_border():
	$Overlay.clear()	
	for i in range (sliced_border_width, map_size.x - sliced_border_width ):
		destroy_cell(sliced_border_width, i)
		destroy_cell(map_size.x - sliced_border_width - 1, i)
		destroy_cell(i, sliced_border_width)
		destroy_cell(i, map_size.y - sliced_border_width - 1)
		
	sliced_border_width = sliced_border_width + 1
	generate_graph()		

func mark_border():
	$Overlay.clear()
	
	for i in range (sliced_border_width, map_size.x - sliced_border_width ):
		mark_cell(sliced_border_width, i)
		mark_cell(map_size.x - sliced_border_width - 1, i)
		mark_cell(i, sliced_border_width)
		mark_cell(i, map_size.y - sliced_border_width - 1)

func destroy_cell(x, y):
	map.set_cell(x, y, -1)
			
	for player in players["a"]:
		if player.is_in_position(x, y):
			player.die()
	
	for player in players["b"]:
		if player.is_in_position(x, y):
			player.die()
			
func mark_cell(x, y):
	if $TileMap.get_cell(x, y) >= 0:
	  $Overlay.set_cell(x, y, 5)
	

func perform_ai_moves():
	print("AI MOVES DONE")
	for enemy in players["a"]:
		enemy.make_ai_move()
		
	end_turn()

func end_turn():	
	current_turn = current_turn + 1
	
	if current_turn > 2:
		if current_turn % 2 == 0:
			slice_border()
		
		if (current_turn + 1) % 2 == 0:
			mark_border()
		
	for player in players["a"]:
		player.reset_ap()
		
	for player in players["b"]:
		player.reset_ap()
		

func reset_game():
	get_tree().change_scene("res://Scenes/Game.tscn")
