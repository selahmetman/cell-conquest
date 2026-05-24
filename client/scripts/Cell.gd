extends Node2D
class_name Cell

signal drag_started(cell: Cell)
signal drag_ended(from_cell: Cell, to_cell: Cell)

const PLAYER_COLORS := {
	"": Color(0.5, 0.5, 0.5),      # neutral
	"p1": Color(0.2, 0.6, 1.0),
	"p2": Color(1.0, 0.3, 0.3),
	"p3": Color(0.2, 0.9, 0.4),
	"p4": Color(1.0, 0.8, 0.1),
	"p5": Color(0.9, 0.3, 0.9),
	"p6": Color(0.3, 0.9, 0.9),
}

var cell_id: int = 0
var owner_id: String = ""
var strength: int = 0
var radius: float = 50.0

@onready var circle: Node2D = $Circle
@onready var label: Label = $Label
@onready var area: Area2D = $Area2D


func _ready() -> void:
	area.input_event.connect(_on_area_input)


func apply_state(data: Dictionary) -> void:
	var new_owner: String = data.get("owner", "")
	var new_strength: int = data.get("strength", 0)

	if new_owner != owner_id:
		owner_id = new_owner
		_play_capture_animation()

	strength = new_strength
	label.text = str(strength)
	circle.modulate = PLAYER_COLORS.get(owner_id, PLAYER_COLORS[""])


func is_mine() -> bool:
	return owner_id == GameManager.local_player_id


func _play_capture_animation() -> void:
	var tween := create_tween()
	tween.tween_property(circle, "scale", Vector2(1.3, 1.3), 0.15)
	tween.tween_property(circle, "scale", Vector2(1.0, 1.0), 0.15)


func _on_area_input(_viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			drag_started.emit(self)
