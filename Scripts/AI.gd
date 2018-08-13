extends Node

var player
var map
var game
var enemies

func initialize(controlled_player, current_game):
	player = controlled_player
	game = current_game
	enemies = game.players["b"]	
		
func calculate_next_move():
	player.action_radius = {}
	player.count_action_radius_from(player.map_pos, player.ap, {})
	
	player.attack_radius = {}
	player.count_attack_radius_from(player.map_pos, player.ap if player.can_shoot() else 1, {})
	
	# TODO: priorita - pokud je na hranici likvidace, jit pryc!
	
	var target_enemy = enemy_in_attack_radius()
	
	if target_enemy:
		player.attack(target_enemy)
	else:
		var path = get_path_to_enemy()
		print(path)
		var next_position = get_furthermost_reachable_path_point(path)
		player.jump_to(next_position)
	
	
func get_path_to_enemy():
	var length 	= 9999
	var result_path   = null
	
	for enemy in enemies:
		if enemy.alive():
			var path = game.get_nearest_path(player.map_pos, enemy.map_pos)
			if path.size() < length:
				length = path.size()
				result_path = path
			
	if result_path == null:
		result_path = game.get_nearest_path(player.map_pos, Vector2(floor(game.map_size.x / 2), floor(game.map_size.y / 2)))
		
	return result_path
			
			
func enemy_in_attack_radius():
	for spot in player.attack_radius.keys():
		for enemy in enemies:
			if enemy.map_pos == spot and enemy.alive():
				return enemy
			
func enemy_in_action_radius():
	for spot in player.action_radius.keys():
		for enemy in enemies:
			if enemy.map_pos == spot and enemy.alive():
				return enemy

func get_furthermost_reachable_path_point(path):
	var result = player.map_pos
	var max_distance = 0

	for point in path:
		var vec2_point = Vector2(point.x, point.y)
		if player.action_radius.has(vec2_point) and tile_unoccupied(vec2_point):
			var distance = Vector2(point.x, point.y) - player.map_pos
			distance = abs(distance.x) + abs(distance.y)
			if distance > max_distance:
				distance = max_distance
				result = Vector2(point.x, point.y)
				
	return result
		
func tile_unoccupied(pos):
	var result = true
	for unit in game.players["a"]:
		if unit.map_pos.x == pos.x and unit.map_pos.y == pos.y and unit.alive():
			return false
			
	for unit in game.players["b"]:
		if unit.map_pos.x == pos.x and unit.map_pos.y == pos.y and unit.alive():
			return false
			
	return true