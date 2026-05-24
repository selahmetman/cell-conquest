extends Node

# Touch + mouse drag abstraction for cell selection

signal troops_sent(from_cell: Cell, to_cell: Cell)

var _drag_from: Cell = null
var _drag_line: Line2D = null


func _ready() -> void:
	_drag_line = Line2D.new()
	_drag_line.default_color = Color(1, 1, 1, 0.5)
	_drag_line.width = 3.0
	_drag_line.visible = false
	add_child(_drag_line)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenDrag or event is InputEventMouseMotion:
		if _drag_from:
			_update_drag_line(_get_event_position(event))

	elif _is_release_event(event):
		if _drag_from:
			_finish_drag(_get_event_position(event))


func start_drag(from_cell: Cell) -> void:
	if not from_cell.is_mine():
		return
	_drag_from = from_cell
	_drag_line.clear_points()
	_drag_line.add_point(from_cell.global_position)
	_drag_line.add_point(from_cell.global_position)
	_drag_line.visible = true


func _finish_drag(end_pos: Vector2) -> void:
	_drag_line.visible = false
	var target := _find_cell_at(end_pos)
	if target and target != _drag_from:
		troops_sent.emit(_drag_from, target)
	_drag_from = null


func _update_drag_line(pos: Vector2) -> void:
	if _drag_line.get_point_count() >= 2:
		_drag_line.set_point_position(1, pos)


func _find_cell_at(pos: Vector2) -> Cell:
	for cell in GameManager.cells.values():
		if cell.global_position.distance_to(pos) <= cell.radius:
			return cell
	return null


func _get_event_position(event: InputEvent) -> Vector2:
	if event is InputEventScreenDrag:
		return event.position
	if event is InputEventMouseMotion:
		return event.position
	if event is InputEventScreenTouch:
		return event.position
	if event is InputEventMouseButton:
		return event.position
	return Vector2.ZERO


func _is_release_event(event: InputEvent) -> bool:
	if event is InputEventScreenTouch and not event.pressed:
		return true
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		return true
	return false
