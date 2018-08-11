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
	player.count_attack_radius_from(player.map_pos, player.ap, {})
	
	var target_enemy = enemy_in_attack_radius()
	
	if target_enemy:
		player.attack(target_enemy)
	else:
		# TODO: nacist cestu k njblizsimu nepriteli (nebo ke stredu pole)
		# zjistit nejblzsi misto, kam muzu jit
		# skocit tam
		
		target_enemy = nearest_enemy()
		if target_enemy:
			player.jump
		else: # jdi ke stredu pole
			
	
func nearest_enemy():
	var length = 9999
	for enemy in enemies:
		var path = game.get_nearest_path(player.map_pos, enemy.map_pos)
		var next_position = get_furthermost_reachable_path_point(path)
		print("JUMPING ENEMY FROM: " + str(player.map_pos) + " to " + str(next_position)) 
		player.jump_to(next_position)
			
func enemy_in_attack_radius():
	for spot in player.attack_radius.keys():
		for enemy in enemies:
			if enemy.map_pos == spot:
				return enemy
			
func enemy_in_action_radius():
	for spot in player.action_radius.keys():
		for enemy in enemies:
			if enemy.map_pos == spot:
				return enemy

func get_furthermost_reachable_path_point(path):
	var result = player.map_pos
	var max_distance = 0

	print("ENEMY POS: " + str(player.map_pos))
	for point in path:
		if player.action_radius.has(Vector2(point.x, point.y)):
			var distance = Vector2(point.x, point.y) - player.map_pos
			distance = abs(distance.x) + abs(distance.y)
			print("DISTANCE: " + str(distance))
			if distance > max_distance:
				distance = max_distance
				result = Vector2(point.x, point.y)
				
	return result
		
