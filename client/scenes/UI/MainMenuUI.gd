extends Control

@onready var play_btn:      Button = $VBox/PlayButton
@onready var status_label:  Label  = $VBox/StatusLabel


func _ready() -> void:
	play_btn.disabled = true
	play_btn.pressed.connect(_on_play_pressed)

	NetworkManager.connected.connect(_on_connected)
	NetworkManager.room_joined.connect(_on_room_joined)
	NetworkManager.error_received.connect(_on_error)
	NetworkManager.disconnected.connect(_on_disconnected)

	_set_status("Sunucuya bağlanılıyor...")
	NetworkManager.connect_to_server(true)   # true = yerel sunucu


func _on_connected() -> void:
	print("[UI] Sunucuya bağlandı")
	_set_status("")
	play_btn.disabled = false


func _on_play_pressed() -> void:
	play_btn.disabled = true
	_set_status("Oda aranıyor...")
	NetworkManager.join_room()


func _on_room_joined(_room_id: String, player_id: String) -> void:
	print("[UI] Odaya girildi, player_id=", player_id)
	GameManager.local_player_id = player_id
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _on_error(message: String) -> void:
	_set_status("Hata: " + message)
	play_btn.disabled = false
	play_btn.text = "TEKRAR DENE"
	play_btn.pressed.disconnect(_on_play_pressed)
	play_btn.pressed.connect(_on_retry)


func _on_retry() -> void:
	play_btn.text = "OYNA"
	play_btn.disabled = true
	play_btn.pressed.disconnect(_on_retry)
	play_btn.pressed.connect(_on_play_pressed)
	_set_status("Yeniden bağlanılıyor...")
	NetworkManager.connect_to_server(true)


func _on_disconnected() -> void:
	_set_status("Bağlantı kesildi")
	play_btn.disabled = true


func _set_status(text: String) -> void:
	status_label.text = text
