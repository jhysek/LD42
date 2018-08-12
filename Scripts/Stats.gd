extends Node

var wins  = 0
var loses = 0
var draws = 0

var matches = 0

func save_draw():
	matches += 1
	draws += 1

func save_win():
	matches += 1
	wins += 1
	
func save_defeat():
	matches += 1
	loses += 1

func get_rank():
	if matches == 0:
		return "Coward"
		
	var diff = wins - loses
	
	if diff > 5:
		return "Winner"
	elif diff > 0:
		return "Lucky Winner"
	elif diff == 0:
		return "Nonwinner"
	if diff > -2:
		return "Loser"
	else:
		return "Hopeless Loser"