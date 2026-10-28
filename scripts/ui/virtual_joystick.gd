class_name TouchJoystick
extends Control
## Faz 06: sol alt bolge sanal hareket cubugu (ARCHITECTURE B.9 dokunma
## kurallari): kaydirma = yon vektoru, coklu dokunma guvenli (kendi indeksini
## izler, diger parmak jestlerini bozmaz). Dokunma hedefi 320x320 tasarim px
## (>> 64 px kurali); gosterge tabani 192, topuz 96.
##
## emulate_touch_from_mouse acik -> fare ile de test edilebilir.
## Veriyi tuketmez: stick_vector_changed sinyalini yayinlar; arena oyuncuya
## baglar. Duraklatmada calisir (HUD katmani ALWAYS) ama oyuncu zaten
## duraklatildigi icin hareket etmez.

signal stick_vector_changed(vector: Vector2)

const TEX_BASE := preload("res://assets/art/ui/tex_ui_joystick_base_01.png")
const TEX_KNOB := preload("res://assets/art/ui/tex_ui_joystick_knob_01.png")

const BASE_SIZE := 192.0     # tasarim px
const KNOB_SIZE := 96.0
const RADIUS := 62.0         # topuz merkez siniri (mekanik his)
const GRAB_MARGIN := 1.25    # taban disindan yakalama toleransi

var stick := Vector2.ZERO
var is_grabbed := false

var _grab_index := -1
var _base: TextureRect
var _knob: TextureRect
var _center := Vector2.ZERO


func _ready() -> void:
        mouse_filter = MOUSE_FILTER_STOP
        custom_minimum_size = Vector2(320, 320)
        _base = TextureRect.new()
        _base.texture = TEX_BASE
        _base.custom_minimum_size = Vector2(BASE_SIZE, BASE_SIZE)
        _base.size = Vector2(BASE_SIZE, BASE_SIZE)
        _base.stretch_mode = TextureRect.STRETCH_SCALE
        _base.mouse_filter = MOUSE_FILTER_IGNORE
        add_child(_base)
        _knob = TextureRect.new()
        _knob.texture = TEX_KNOB
        _knob.custom_minimum_size = Vector2(KNOB_SIZE, KNOB_SIZE)
        _knob.size = Vector2(KNOB_SIZE, KNOB_SIZE)
        _knob.stretch_mode = TextureRect.STRETCH_SCALE
        _knob.mouse_filter = MOUSE_FILTER_IGNORE
        add_child(_knob)
        resized.connect(_layout)
        _layout()


func _layout() -> void:
        # taban kontrolun sol-alt kosesine yakin yerlesir (guvenli alan icinde)
        _center = size - Vector2(BASE_SIZE, BASE_SIZE) * 0.5 - Vector2(30, 34)
        _base.position = _center - Vector2(BASE_SIZE, BASE_SIZE) * 0.5
        _update_knob()


func _update_knob() -> void:
        _knob.position = _center + stick * RADIUS - Vector2(KNOB_SIZE, KNOB_SIZE) * 0.5


func _gui_input(event: InputEvent) -> void:
        if event is InputEventScreenTouch:
                var t := event as InputEventScreenTouch
                if t.pressed and _grab_index == -1:
                        if t.position.distance_to(_center) <= RADIUS * GRAB_MARGIN + 60.0:
                                _grab_index = t.index
                                is_grabbed = true
                                _drag_to(t.position)
                elif not t.pressed and t.index == _grab_index:
                        _release()
        elif event is InputEventScreenDrag:
                var d := event as InputEventScreenDrag
                if d.index == _grab_index:
                        _drag_to(d.position)
        elif event is InputEventMouseButton and event.pressed \
                        and event.button_index == MOUSE_BUTTON_LEFT and _grab_index == -1:
                # fare yedegi (emulate_touch_from_mouse kapali ortamlar icin)
                _grab_index = 99
                is_grabbed = true
                _drag_to((event as InputEventMouseButton).position)
        elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT \
                        and _grab_index == 99:
                _release()


func _drag_to(local_pos: Vector2) -> void:
        var raw := local_pos - _center
        stick = raw.limit_length(RADIUS) / RADIUS
        _update_knob()
        stick_vector_changed.emit(stick)


func _release() -> void:
        _grab_index = -1
        is_grabbed = false
        stick = Vector2.ZERO
        _update_knob()
        stick_vector_changed.emit(Vector2.ZERO)
