extends Node

# Singleton: autoload as "GameManager"
# Sadece paylaşılan oyun durumunu tutar.

var local_player_id : String     = ""
var players         : Dictionary = {}   # pid -> {name, cell_count}
var cells           : Dictionary = {}   # cell_id -> Cell node
var game_active     : bool       = false
var time_remaining  : float      = 180.0


func send_troops(from_id: int, to_id: int, _amount: int) -> void:
	if not game_active:
		return
	NetworkManager.send_command({ "type": "send_troops", "from": from_id, "to": to_id })


func reset() -> void:
	players        = {}
	cells          = {}
	game_active    = false
	time_remaining = 180.0
