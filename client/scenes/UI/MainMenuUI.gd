extends Control

@onready var play_btn: Button        = $VBox/PlayButton
@onready var leaderboard_btn: Button = $VBox/LeaderboardButton
@onready var status_label: Label     = $VBox/StatusLabel


func _ready() -> void:
	play_btn.pressed.connect(_on_play_pressed)
	leaderboard_btn.pressed.connect(_on_leaderboard_pressed)

	NetworkManager.connected.connect(_on_server_connected)
	NetworkManager.room_joined.connect(_on_room_joined)
	NetworkManager.error_received.connect(_on_error)

	status_label.text = "Sunucuya bağlanılıyor..."
	# Yerel geliştirme için use_local=true, production'da false
	NetworkManager.connect_to_server(true)


func _on_server_connected() -> void:
	status_label.text = ""
	play_btn.disabled = false


func _on_play_pressed() -> void:
	play_btn.disabled = true
	play_btn.text = "Bağlanıyor..."
	status_label.text = "Oda aranıyor..."
	NetworkManager.join_room()


func _on_room_joined(room_id: String, player_id: String) -> void:
	GameManager.local_player_id = player_id
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _on_error(message: String) -> void:
	status_label.text = "Hata: " + message
	play_btn.disabled = false
	play_btn.text = "OYNA"


func _on_leaderboard_pressed() -> void:
	pass
