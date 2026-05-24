extends Node

var _drag_from : Cell = null
var _line      : Line2D


func _ready() -> void:
	_line = Line2D.new()
	_line.default_color = Color(1, 1, 1, 0.45)
	_line.width = 4.0
	_line.visible = false
	get_parent().add_child(_line)


func start_drag(from_cell: Cell) -> void:
	if not from_cell.is_mine():
		return
	_drag_from = from_cell
	_line.clear_points()
	_line.add_point(from_cell.global_position)
	_line.add_point(from_cell.global_position)
	_line.visible = true


func _input(event: InputEvent) -> void:
	if _drag_from == null:
		return

	var pos := _event_pos(event)
	if pos == Vector2.INF:
		return

	if _is_move(event):
		if _line.get_point_count() >= 2:
			_line.set_point_position(1, pos)

	elif _is_release(event):
		_line.visible = false
		var target := _cell_at(pos)
		if target and target != _drag_from:
			GameManager.send_troops(_drag_from.cell_id, target.cell_id, 0)
		_drag_from = null


func _cell_at(pos: Vector2) -> Cell:
	for cell in GameManager.cells.values():
		if cell.global_position.distance_to(pos) <= cell.radius:
			return cell
	return null


func _event_pos(event: InputEvent) -> Vector2:
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		return event.position
	if event is InputEventScreenDrag or event is InputEventScreenTouch:
		return event.position
	return Vector2.INF


func _is_move(event: InputEvent) -> bool:
	return event is InputEventMouseMotion or event is InputEventScreenDrag


func _is_release(event: InputEvent) -> bool:
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		return true
	if event is InputEventScreenTouch and not event.pressed:
		return true
	return false
