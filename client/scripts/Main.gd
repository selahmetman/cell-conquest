extends Node2D

const CELL_SCENE := preload("res://scenes/Cell.tscn")

@onready var _cell_container : Node2D   = $CellContainer
@onready var _input_handler  : Node     = $InputHandler
@onready var _hud_timer      : Label    = $UIManager/HUD/Timer
@onready var _hud_scores     : VBoxContainer = $UIManager/HUD/Scores
@onready var _game_over_panel: Panel    = $UIManager/GameOver
@onready var _winner_label   : Label    = $UIManager/GameOver/WinnerLabel

var _cells_ready := false


func _ready() -> void:
	_game_over_panel.visible = false
	NetworkManager.state_updated.connect(_on_state)
	NetworkManager.game_over.connect(_on_game_over)


func _process(_delta: float) -> void:
	var t := int(GameManager.time_remaining)
	_hud_timer.text = "%d:%02d" % [t / 60, t % 60]


func _on_state(state: Dictionary) -> void:
	GameManager.time_remaining = state.get("time_remaining", GameManager.time_remaining)
	GameManager.game_active    = state.get("game_active", false)
	GameManager.players        = state.get("players", {})

	var cells_data : Array = state.get("cells", [])

	if not _cells_ready and cells_data.size() > 0:
		_spawn_cells(cells_data)
		_cells_ready = true

	for cdata in cells_data:
		var id : int = int(cdata["id"])
		if GameManager.cells.has(id):
			GameManager.cells[id].apply_state(cdata)

	_refresh_scores()


func _spawn_cells(cells_data: Array) -> void:
	for cdata in cells_data:
		var cell : Cell = CELL_SCENE.instantiate()
		cell.cell_id  = int(cdata["id"])
		cell.position = Vector2(float(cdata["x"]), float(cdata["y"]))
		cell.radius   = float(cdata.get("radius", 50))
		cell.drag_start.connect(_input_handler.start_drag)
		_cell_container.add_child(cell)
		GameManager.cells[cell.cell_id] = cell
		cell.apply_state(cdata)


func _refresh_scores() -> void:
	for c in _hud_scores.get_children():
		c.queue_free()
	for pid in GameManager.players:
		var p   : Dictionary = GameManager.players[pid]
		var lbl := Label.new()
		lbl.text = "%s: %d" % [p.get("name", pid), p.get("cell_count", 0)]
		lbl.modulate = Cell._color_for(pid)
		_hud_scores.add_child(lbl)


func _on_game_over(data: Dictionary) -> void:
	var winner_id   : String = data.get("winner_id", "")
	var winner_name : String = GameManager.players.get(winner_id, {}).get("name", "???")
	_winner_label.text = "%s Kazandı!" % winner_name
	_game_over_panel.visible = true
