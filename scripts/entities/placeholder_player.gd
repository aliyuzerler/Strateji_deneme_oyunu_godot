class_name PlaceholderPlayer
extends IsoEntity
## Kanit sahnesi gecici oyuncusu: dokunma hedefine duz hat hareketi.
## NOT: Grid yol bulma ARCHITECTURE B.10'daki MovementComponent gorevine aittir;
## bu sahne derinlik/kamera/girdi kaniti icin duz hat kullanir.

signal arrived(cell: Vector2i)

const MOVE_SPEED: float = 340.0  # tasarim px/sn (ARCHITECTURE B.9 dokunma olcekli)

var arena_bounds: Rect2 = Rect2(-1e9, -1e9, 2e9, 2e9)
var current_cell := Vector2i.ZERO

var _target_world := Vector2.ZERO
var _moving := false
var _bob_time := 0.0

var moving: bool:
	get:
		return _moving


func _process(delta: float) -> void:
	# Gelistirici klavye hareketi (masaustu inceleme kolayligi; mobil birincil degil)
	var key_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if key_dir.length_squared() > 0.01:
		_moving = false
		position += key_dir * MOVE_SPEED * delta
		_clamp_position()
		_update_cell()
	elif _moving:
		_step_towards(_target_world, delta)
	_animate_bob(delta)


func move_to(world_target: Vector2) -> void:
	_target_world = world_target
	_moving = true


func _step_towards(target: Vector2, delta: float) -> void:
	var to := target - position
	var step := MOVE_SPEED * delta
	if to.length() <= step:
		position = target
		_moving = false
		_update_cell()
		arrived.emit(current_cell)
	else:
		position += to.normalized() * step
		_update_cell()
		_clamp_position()


func _clamp_position() -> void:
	position.x = clampf(position.x, arena_bounds.position.x, arena_bounds.end.x)
	position.y = clampf(position.y, arena_bounds.position.y, arena_bounds.end.y)


func _update_cell() -> void:
	current_cell = IsoMath.world_to_map(position)


func _animate_bob(delta: float) -> void:
	if _moving:
		_bob_time += delta * 11.0
		body.position.y = -absf(sin(_bob_time)) * 7.0
	else:
		_bob_time = 0.0
		body.position.y = lerpf(body.position.y, 0.0, 0.35)
