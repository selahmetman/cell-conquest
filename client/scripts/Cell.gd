extends Node2D
class_name Cell

signal drag_start(cell: Cell)

var cell_id  : int    = 0
var owner_id : String = ""
var strength : int    = 0
var radius   : float  = 50.0
var _color   := Color(0.4, 0.4, 0.4)

@onready var _label : Label  = $Label
@onready var _area  : Area2D = $Area2D


func _ready() -> void:
	_area.input_event.connect(_on_input)
	_update_collision()


func apply_state(data: Dictionary) -> void:
	var new_owner : String = data.get("owner", "")
	if new_owner != owner_id:
		owner_id = new_owner
		_color = _color_for(owner_id)
		_animate_capture()
	strength = data.get("strength", 0)
	_label.text = str(strength)
	queue_redraw()


func is_mine() -> bool:
	return owner_id == GameManager.local_player_id


# ── Drawing ──────────────────────────────────────────────────────────────────

func _draw() -> void:
	draw_circle(Vector2(3, 3), radius, Color(0, 0, 0, 0.25))   # gölge
	draw_circle(Vector2.ZERO, radius, _color)
	var border := _color.lightened(0.4)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, border, 3.0)
	if is_mine():
		draw_arc(Vector2.ZERO, radius - 5, 0.0, TAU, 64, Color(1, 1, 1, 0.6), 2.0)


# ── Helpers ───────────────────────────────────────────────────────────────────

static func _color_for(pid: String) -> Color:
	if pid == "":
		return Color(0.35, 0.35, 0.4)
	var h := fmod(float(pid.hash() & 0xFFFF) / 65535.0, 1.0)
	return Color.from_hsv(h, 0.75, 0.95)


func _animate_capture() -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.25, 1.25), 0.12)
	tw.tween_property(self, "scale", Vector2(1.0,  1.0),  0.12)


func _update_collision() -> void:
	var shape := CircleShape2D.new()
	shape.radius = radius
	var col := CollisionShape2D.new()
	col.shape = shape
	_area.add_child(col)


func _on_input(_viewport: Node, event: InputEvent, _shape: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		drag_start.emit(self)
	elif event is InputEventScreenTouch and event.pressed:
		drag_start.emit(self)
