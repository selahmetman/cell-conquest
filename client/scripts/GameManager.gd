extends Node

# Singleton: autoload as "GameManager"

signal game_started
signal game_ended(winner_id: String)
signal cell_captured(cell_id: int, new_owner: String)

const GROWTH_TICK_INTERVAL := 1.0
const MAX_CELL_STRENGTH := 100
const GAME_DURATION := 180.0  # 3 minutes

var local_player_id := ""
var players: Dictionary = {}   # player_id -> { color, name, cell_count }
var cells: Dictionary = {}     # cell_id  -> Cell node
var game_active := false
var time_remaining := GAME_DURATION

@onready var network: Node = $"/root/NetworkManager"


func _ready() -> void:
	network.state_updated.connect(_on_state_updated)
	network.game_over.connect(_on_game_over)


func _process(delta: float) -> void:
	if not game_active:
		return
	time_remaining -= delta
	if time_remaining <= 0.0:
		time_remaining = 0.0


func send_troops(from_id: int, to_id: int, amount: int) -> void:
	if not game_active:
		return
	network.send_command({
		"type": "send_troops",
		"from": from_id,
		"to": to_id,
		"amount": amount
	})


func _on_state_updated(state: Dictionary) -> void:
	time_remaining = state.get("time_remaining", time_remaining)
	players = state.get("players", players)

	for cell_data in state.get("cells", []):
		var id: int = cell_data["id"]
		if cells.has(id):
			cells[id].apply_state(cell_data)


func _on_game_over(data: Dictionary) -> void:
	game_active = false
	game_ended.emit(data.get("winner_id", ""))
