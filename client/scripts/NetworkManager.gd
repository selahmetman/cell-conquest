extends Node

# Singleton: autoload as "NetworkManager"

signal connected
signal disconnected
signal state_updated(state: Dictionary)
signal game_over(data: Dictionary)
signal room_joined(room_id: String, player_id: String)
signal error_received(message: String)

const SERVER_URL := "wss://cell-conquest-server.onrender.com"
const LOCAL_URL  := "ws://localhost:2567"

var _socket  := WebSocketPeer.new()
var _ready_state := WebSocketPeer.STATE_CLOSED


func _ready() -> void:
	set_process(false)


func connect_to_server(use_local := false) -> void:
	var url := LOCAL_URL if use_local else SERVER_URL
	var err  := _socket.connect_to_url(url)
	if err != OK:
		error_received.emit("Sunucuya bağlanılamadı (hata %d)" % err)
		return
	set_process(true)


func disconnect_from_server() -> void:
	_socket.close()
	set_process(false)


func join_room(player_name := "Oyuncu") -> void:
	_send({ "type": "join", "name": player_name })


func send_command(data: Dictionary) -> void:
	_send(data)


func _process(_delta: float) -> void:
	_socket.poll()
	var state := _socket.get_ready_state()

	if state != _ready_state:
		_ready_state = state
		match state:
			WebSocketPeer.STATE_OPEN:
				connected.emit()
			WebSocketPeer.STATE_CLOSED:
				disconnected.emit()
				set_process(false)

	if state == WebSocketPeer.STATE_OPEN:
		while _socket.get_available_packet_count() > 0:
			var raw := _socket.get_packet().get_string_from_utf8()
			_handle(raw)


func _send(data: Dictionary) -> void:
	if _socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_socket.send_text(JSON.stringify(data))


func _handle(raw: String) -> void:
	var msg: Variant = JSON.parse_string(raw)
	if not msg is Dictionary:
		return
	match msg.get("type", ""):
		"room_joined":
			room_joined.emit(msg.get("room_id", ""), msg.get("player_id", ""))
		"state":
			state_updated.emit(msg)
		"game_over":
			game_over.emit(msg)
		"error":
			error_received.emit(msg.get("message", "Bilinmeyen hata"))
