extends Control

@onready var play_btn: Button        = $VBox/PlayButton
@onready var leaderboard_btn: Button = $VBox/LeaderboardButton


func _ready() -> void:
	play_btn.pressed.connect(_on_play_pressed)
	leaderboard_btn.pressed.connect(_on_leaderboard_pressed)
	NetworkManager.connect_to_server()
	NetworkManager.room_joined.connect(_on_room_joined)


func _on_play_pressed() -> void:
	play_btn.disabled = true
	play_btn.text = "Bağlanıyor..."
	NetworkManager.join_room()


func _on_room_joined(room_id: String, player_id: String) -> void:
	GameManager.local_player_id = player_id
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _on_leaderboard_pressed() -> void:
	pass  # TODO: leaderboard scene
