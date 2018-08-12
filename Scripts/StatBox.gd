extends Control


func _ready():
	load_stats()

	
func load_stats():
	$Wins.text    = "Victories:  " + str(Stats.wins)
	$Defeats.text = "Defeats:    " + str(Stats.loses)
	$Battles.text = "Battles:    " + str(Stats.matches)
	$Rank.text    = "Your Rank:  " + str(Stats.get_rank()).to_upper()