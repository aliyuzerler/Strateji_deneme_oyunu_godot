class_name EnemyUnit
extends CombatUnit
## Dusman AI (Faz 05): IDLE -> CHASE -> (WINDUP) -> saldiri.
## Tip davranisi UnitDefs'ten gelir:
##   melee   — zigzag takip + lunge vurus (Kum Koşucusu)
##   slam    — telegraf halkali alan vurusu (Grit Muhafız)
##   ranged  — guvenli bantta dur, strafe yap, mermi at (Fırtına Salyası)
## Ayrilma (separation) EnemyRegistry ile yumusatilir; hareket dogrudan
## konum degisimidir (kanit sahnesi fizik kullanmaz — mevcut yapıyla uyumlu).


enum State { IDLE, CHASE, WINDUP }

var def: Dictionary = {}
var player: CombatUnit = null

var _state := State.IDLE
var _wander_t := 0.0
var _wander_dir := Vector2.ZERO
var _zigzag_phase := 0.0
var _strafe_dir := 1.0
var _windup_t := 0.0
var _telegraph: Node2D = null
var _sep_acc := 0.0
var _sep_cache: Array = []
var _bounds := Rect2(-1e9, -1e9, 2e9, 2e9)


func setup_from_def(p_def: Dictionary, p_player: CombatUnit, p_registry: EnemyRegistry, p_fx: CombatFx) -> void:
        def = p_def
        player = p_player
        registry = p_registry
        fx = p_fx
        unit_team = "enemy"
        unit_id = def["id"]
        display_name = def["display"]
        max_hp = int(def["max_hp"])
        hp = max_hp
        move_speed = float(def["speed"])
        attack_damage = int(def["damage"])
        attack_cooldown = float(def["cooldown"])
        attack_range = float(def["range"])
        knockback_power = float(def.get("knockback", 120.0))
        bolt_speed = float(def.get("bolt_speed", 640.0))
        _strafe_dir = 1.0 if randf() < 0.5 else -1.0
        setup_sheets(def["cell"], def["sheets"])


func set_bounds(r: Rect2) -> void:
        _bounds = r


func ai_state() -> int:
        return _state


func _physics_process(delta: float) -> void:
        if dead:
                tick_combat(delta)
                return
        tick_combat(delta)
        var vel := Vector2.ZERO
        var dist := INF
        var to_p := Vector2.ZERO
        var target_valid := player != null and is_instance_valid(player) and not player.dead
        if target_valid:
                to_p = player.global_position - global_position
                dist = to_p.length()
        if not target_valid:
                _state = State.IDLE
        match _state:
                State.IDLE:
                        _wander_t -= delta
                        if _wander_t <= 0.0:
                                _wander_t = randf_range(1.2, 2.6)
                                _wander_dir = Vector2.from_angle(randf() * TAU) * 0.35
                        vel = _wander_dir * move_speed
                        pick_locomotion_anim(vel.length_squared() > 100.0)
                        if target_valid and dist < float(def.get("aggro", 1000.0)):
                                _state = State.CHASE
                State.CHASE:
                        if not target_valid:
                                _state = State.IDLE
                        else:
                                vel = _behavior(to_p, dist, delta)
                                if _state == State.CHASE:
                                        set_facing(to_p.angle())
                                        pick_locomotion_anim(vel.length_squared() > 900.0)
                State.WINDUP:
                        vel = Vector2.ZERO
                        _windup_t -= delta
                        if target_valid:
                                set_facing(to_p.angle())
                        if _windup_t <= 0.0:
                                _finish_slam()
        vel += _separation(delta)
        vel += apply_knockback(delta)
        if vel.length_squared() > 0.0:
                global_position += vel * delta
                global_position.x = clampf(global_position.x, _bounds.position.x, _bounds.end.x)
                global_position.y = clampf(global_position.y, _bounds.position.y, _bounds.end.y)
        if registry != null:
                registry.update_position(self)


func _behavior(to_p: Vector2, dist: float, delta: float) -> Vector2:
        var behavior: String = def.get("behavior", "melee")
        match behavior:
                "slam":
                        if dist <= attack_range and can_attack():
                                _begin_windup()
                                return Vector2.ZERO
                        if dist > attack_range * 0.8:
                                return to_p.normalized() * move_speed
                        return Vector2.ZERO
                "ranged":
                        var bmin: float = float(def.get("band_min", 340.0))
                        var bmax: float = float(def.get("band_max", 540.0))
                        var tangential := Vector2(-to_p.y, to_p.x).normalized() * move_speed * 0.6 * _strafe_dir
                        if dist > bmax:
                                return to_p.normalized() * move_speed + tangential * 0.3
                        if dist < bmin:
                                return -to_p.normalized() * move_speed + tangential * 0.5
                        if can_attack() and dist <= attack_range:
                                _fire_at_player()
                        return tangential
                _:
                        if dist <= attack_range and can_attack():
                                _melee_strike()
                                return Vector2.ZERO
                        _zigzag_phase += delta * 7.0
                        var side := Vector2(-to_p.y, to_p.x).normalized()
                        return (to_p.normalized() + side * sin(_zigzag_phase) * 0.45).normalized() * move_speed
        return Vector2.ZERO


func _melee_strike() -> void:
        _cooldown = attack_cooldown
        _force_anim("attack")
        if player != null and is_instance_valid(player) and not player.dead:
                if global_position.distance_to(player.global_position) <= attack_range + 46.0:
                        player.take_hit(attack_damage, global_position)


func _begin_windup() -> void:
        _state = State.WINDUP
        _windup_t = float(def.get("windup", 0.8))
        _cooldown = attack_cooldown
        _force_anim("attack")
        _anim_done = true   # windup boyunca kare 0'da bekler
        if fx != null:
                _telegraph = fx.spawn_telegraph(global_position, float(def.get("slam_radius", 140.0)))


func _finish_slam() -> void:
        _state = State.CHASE
        if _telegraph != null and is_instance_valid(_telegraph):
                _telegraph.queue_free()
                _telegraph = null
        _anim_done = false   # attack animasyonunun kalan kareleri oynar
        if fx != null:
                fx.spawn_slam_burst(global_position)
        if player != null and is_instance_valid(player) and not player.dead:
                var r: float = float(def.get("slam_radius", 140.0))
                if global_position.distance_to(player.global_position) <= r + 30.0:
                        player.take_hit(attack_damage, global_position)


func _fire_at_player() -> void:
        _cooldown = attack_cooldown
        _force_anim("attack")
        if bolt_parent == null or player == null or not is_instance_valid(player):
                return
        var bolt := CombatBolt.new()
        bolt.setup("enemy", attack_damage, registry, fx, player)
        bolt.position = global_position + Vector2(0.0, -70.0)
        var dir := (player.global_position + Vector2(0.0, -40.0) - bolt.position).normalized()
        if dir == Vector2.ZERO:
                dir = Vector2(0.0, -1.0)
        bolt.velocity = dir * bolt_speed
        bolt.rotation = dir.angle()
        bolt_parent.add_child(bolt)


func _separation(delta: float) -> Vector2:
        if registry == null:
                return Vector2.ZERO
        _sep_acc += delta
        if _sep_acc >= 0.08:
                _sep_acc = 0.0
                _sep_cache = registry.in_radius(global_position, 78.0, self)
        var push := Vector2.ZERO
        for u in _sep_cache:
                var cu := u as CombatUnit
                if cu == null or cu.dead or not is_instance_valid(cu):
                        continue
                var d := global_position.distance_to(cu.global_position)
                if d > 0.01 and d < 78.0:
                        push += (global_position - cu.global_position) / d
        return push * 90.0
