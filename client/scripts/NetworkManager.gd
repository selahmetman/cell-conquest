extends Node

# Singleton: autoload as "NetworkManager"

signal connected
signal disconnected
signal state_updated(state: Dictionary)
signal game_over(data: Dictionary)
signal room_joined(room_id: String, player_id: String)
signal error_received(message: String)

const SERVER_URL := "wss://cell-conquest-server.onrender.com"  # production
const LOCAL_URL  := "ws://localhost:2567"

var _socket := WebSocketPeer.new()
var _is_connected := false
var _use_local := false


func _ready() -> void:
	set_process(false)


func connect_to_server(use_local := false) -> void:
	_use_local = use_local
	var url := LOCAL_URL if use_local else SERVER_URL
	var err := _socket.connect_to_url(url)
	if err != OK:
		error_received.emit("Sunucuya bağlanılamadı: %d" % err)
		return
	set_process(true)


func disconnect_from_server() -> void:
	_socket.close()
	set_process(false)
	_is_connected = false


func send_command(data: Dictionary) -> void:
	if not _is_connected:
		return
	var json := JSON.stringify(data)
	_socket.send_text(json)


func join_room(room_name := "game") -> void:
	send_command({"type": "join", "room": room_name})


func _process(_delta: float) -> void:
	_socket.poll()
	var state := _socket.get_ready_state()

	match state:
		WebSocketPeer.STATE_OPEN:
			if not _is_connected:
				_is_connected = true
				connected.emit()
			while _socket.get_available_packet_count() > 0:
				_handle_packet(_socket.get_packet().get_string_from_utf8())

		WebSocketPeer.STATE_CLOSED:
			if _is_connected:
				_is_connected = false
				disconnected.emit()
			set_process(false)


func _handle_packet(raw: String) -> void:
	var data: Variant = JSON.parse_string(raw)
	if not data is Dictionary:
		return

	match data.get("type", ""):
		"room_joined":
			room_joined.emit(data.get("room_id", ""), data.get("player_id", ""))
		"state":
			state_updated.emit(data.get("payload", {}))
		"game_over":
			game_over.emit(data.get("payload", {}))
		"error":
			error_received.emit(data.get("message", "Bilinmeyen hata"))
