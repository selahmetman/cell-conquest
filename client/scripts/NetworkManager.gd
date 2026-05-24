extends Node

signal connected
signal disconnected
signal state_updated(state: Dictionary)
signal game_over(data: Dictionary)
signal room_joined(room_id: String, player_id: String)
signal error_received(message: String)

const SERVER_URL    := "wss://cell-conquest-server.onrender.com"
const LOCAL_URL     := "ws://127.0.0.1:2567"
const CONNECT_TIMEOUT := 5.0   # saniye

var _socket        := WebSocketPeer.new()
var _last_state    := -1
var _connect_timer := 0.0
var _connecting    := false


func _ready() -> void:
	set_process(false)


func connect_to_server(use_local := false) -> void:
	var url := LOCAL_URL if use_local else SERVER_URL
	print("[NET] Bağlanılıyor: ", url)

	var err := _socket.connect_to_url(url)
	if err != OK:
		print("[NET] connect_to_url hatası: ", err)
		error_received.emit("Bağlantı başlatılamadı (kod: %d)" % err)
		return

	_connecting = true
	_connect_timer = 0.0
	_last_state = -1
	set_process(true)


func disconnect_from_server() -> void:
	_socket.close()
	set_process(false)
	_connecting = false


func join_room(player_name := "Oyuncu") -> void:
	_send({ "type": "join", "name": player_name })


func send_command(data: Dictionary) -> void:
	_send(data)


func _process(delta: float) -> void:
	_socket.poll()
	var state := _socket.get_ready_state()

	if state != _last_state:
		print("[NET] Durum değişti: %d -> %d" % [_last_state, state])
		_last_state = state

	match state:
		WebSocketPeer.STATE_OPEN:
			_connecting = false
			_connect_timer = 0.0
			if _last_state != WebSocketPeer.STATE_OPEN:
				pass   # Zaten yukarıda yakalandı
			_drain_packets()

		WebSocketPeer.STATE_CLOSED:
			if _connecting:
				print("[NET] Bağlantı kapalı — kod: %d, sebep: %s" % [
					_socket.get_close_code(), _socket.get_close_reason()])
			_connecting = false
			disconnected.emit()
			set_process(false)

	# Bağlantı kurulunca sinyal gönder (bir kez)
	if state == WebSocketPeer.STATE_OPEN and _connect_timer == 0.0:
		_connect_timer = -1.0   # tekrar tetiklenmesin
		print("[NET] Bağlantı kuruldu!")
		connected.emit()
		return

	# Bağlanma zaman aşımı
	if _connecting and state == WebSocketPeer.STATE_CONNECTING:
		_connect_timer += delta
		if _connect_timer >= CONNECT_TIMEOUT:
			print("[NET] Zaman aşımı!")
			_socket.close()
			_connecting = false
			error_received.emit("Sunucuya bağlanılamadı (zaman aşımı)")
			set_process(false)


func _drain_packets() -> void:
	while _socket.get_available_packet_count() > 0:
		var raw := _socket.get_packet().get_string_from_utf8()
		_handle(raw)


func _send(data: Dictionary) -> void:
	if _socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_socket.send_text(JSON.stringify(data))
	else:
		print("[NET] Gönderilemiyor, bağlantı yok")


func _handle(raw: String) -> void:
	var msg: Variant = JSON.parse_string(raw)
	if not msg is Dictionary:
		return
	match msg.get("type", ""):
		"room_joined":
			print("[NET] Odaya katıldı: ", msg.get("room_id"))
			room_joined.emit(msg.get("room_id", ""), msg.get("player_id", ""))
		"state":
			state_updated.emit(msg)
		"game_over":
			game_over.emit(msg)
		"error":
			error_received.emit(msg.get("message", "Bilinmeyen hata"))
