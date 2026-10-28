class_name CameraRig
extends Node2D
## ARCHITECTURE B.8: hedef takibi + pinch zoom (0.6-1.8) + arena siniri.
## 2.5D sabit aci: rotasyon yok, serbest pan yok (takip modu).

const ZOOM_MIN: float = 0.6
const ZOOM_MAX: float = 1.8
const FOLLOW_SPEED: float = 6.0

@onready var camera: Camera2D = $Camera2D

var target: Node2D
var _zoom: float = 1.0
var _bounds := Rect2(-1e9, -1e9, 2e9, 2e9)


func _ready() -> void:
	camera.make_current()
	_apply_zoom()


func _process(delta: float) -> void:
	if is_instance_valid(target):
		var weight := 1.0 - exp(-FOLLOW_SPEED * delta)
		global_position = global_position.lerp(target.global_position, weight)
	_clamp_to_bounds()


func multiply_zoom(factor: float) -> void:
	_zoom = clampf(_zoom * factor, ZOOM_MIN, ZOOM_MAX)
	_apply_zoom()


func get_zoom() -> float:
	return _zoom


func set_bounds(rect: Rect2) -> void:
	_bounds = rect
	camera.limit_left = int(rect.position.x)
	camera.limit_top = int(rect.position.y)
	camera.limit_right = int(rect.end.x)
	camera.limit_bottom = int(rect.end.y)


func _apply_zoom() -> void:
	camera.zoom = Vector2.ONE * _zoom


func _clamp_to_bounds() -> void:
	global_position.x = clampf(global_position.x, _bounds.position.x, _bounds.end.x)
	global_position.y = clampf(global_position.y, _bounds.position.y, _bounds.end.y)
