class_name ArenaInput
extends Node
## Dokunma jest cozucu (ARCHITECTURE B.9): tap = hareket emri, pinch = zoom.
## emulate_touch_from_mouse acik oldugu icin fare de touch akisina duser;
## tekerlek yalnizca gelistirme kolayligidir. Duraklatma InputMap aksiyonudur.

signal move_order_issued(world_pos: Vector2)
signal zoom_delta(factor: float)
signal pause_toggle_requested

const TAP_MAX_DRAG: float = 24.0
const TAP_MAX_TIME: float = 0.5

var _press_pos := Vector2.ZERO
var _press_time := 0.0
var _touch_points: Dictionary = {}
var _last_pinch_dist: float = 0.0
var debug_touch_count := 0  # smoke test tesihisi: _unhandled_input'a ulasan touch sayisi


func _process(_delta: float) -> void:
        if Input.is_action_just_pressed("pause_toggle"):
                pause_toggle_requested.emit()


func _unhandled_input(event: InputEvent) -> void:
        if event is InputEventScreenTouch:
                debug_touch_count += 1
                if event.pressed:
                        _touch_points[event.index] = event.position
                        if event.index == 0:
                                _press_pos = event.position
                                _press_time = Time.get_ticks_msec() / 1000.0
                else:
                        _touch_points.erase(event.index)
                        _last_pinch_dist = 0.0
                        if event.index == 0 and not get_tree().paused:
                                var duration := Time.get_ticks_msec() / 1000.0 - _press_time
                                if duration <= TAP_MAX_TIME and event.position.distance_to(_press_pos) <= TAP_MAX_DRAG:
                                        move_order_issued.emit(_screen_to_world(event.position))
        elif event is InputEventScreenDrag:
                if _touch_points.size() >= 2 and _touch_points.has(event.index):
                        _touch_points[event.index] = event.position
                        if _touch_points.size() == 2:
                                var keys: Array = _touch_points.keys()
                                var dist: float = _touch_points[keys[0]].distance_to(_touch_points[keys[1]])
                                if _last_pinch_dist > 0.0 and dist > 0.0:
                                        zoom_delta.emit(dist / _last_pinch_dist)
                                _last_pinch_dist = dist
        elif event is InputEventMouseButton and event.pressed:
                if event.button_index == MOUSE_BUTTON_WHEEL_UP:
                        zoom_delta.emit(1.1)
                elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
                        zoom_delta.emit(0.9)


func _screen_to_world(screen_pos: Vector2) -> Vector2:
        var xform := get_viewport().get_canvas_transform()
        return xform.affine_inverse() * screen_pos
