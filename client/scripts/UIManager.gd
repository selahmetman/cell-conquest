extends CanvasLayer

@onready var hud_timer: Label    = $HUD/Timer
@onready var hud_scores: VBoxContainer = $HUD/Scores
@onready var game_over_panel: Panel = $GameOver
@onready var winner_label: Label = $GameOver/WinnerLabel


func _ready() -> void:
	GameManager.game_ended.connect(_on_game_ended)
	game_over_panel.visible = false


func _process(_delta: float) -> void:
	if not GameManager.game_active:
		return
	var t := int(GameManager.time_remaining)
	hud_timer.text = "%d:%02d" % [t / 60, t % 60]
	_refresh_scores()


func _refresh_scores() -> void:
	for child in hud_scores.get_children():
		child.queue_free()
	for pid in GameManager.players:
		var p: Dictionary = GameManager.players[pid]
		var lbl := Label.new()
		lbl.text = "%s: %d hücre" % [p.get("name", pid), p.get("cell_count", 0)]
		lbl.modulate = Cell.PLAYER_COLORS.get(pid, Color.WHITE)
		hud_scores.add_child(lbl)


func _on_game_ended(winner_id: String) -> void:
	var winner_name: String = GameManager.players.get(winner_id, {}).get("name", winner_id)
	winner_label.text = "%s Kazandı!" % winner_name
	game_over_panel.visible = true
