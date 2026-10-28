class_name PlaceholderPlayer
extends CombatUnit
## Kanit sahnesi oyuncusu — Faz 05 ile savas yetenekli:
##   - tap hedefine duz hat hareketi + gelistirici klavye hareketi (korundu)
##   - otomatik hedefleme + turkuaz enerji mermisi (turkuaz yalnizca oyuncuda)
##   - hasar alinca flash + geri itme + hasar etiketi; olumde respawn
##
## NOT: Sinif adi mevcut sahne/smoke referanslari nedeniyle korunmustur;
## production oyuncu birimi ayri gorevde netlestirilecek (worklog).
## Grid yol bulma ARCHITECTURE B.10 MovementComponent'e aittir; bu sahne
## derinlik/savas kaniti icin duz hat kullanir.

signal arrived(cell: Vector2i)

var arena_bounds: Rect2 = Rect2(-1e9, -1e9, 2e9, 2e9)
var current_cell := Vector2i.ZERO
var respawn_point := Vector2.ZERO
var invuln := 0.0

var _target_world := Vector2.ZERO
var _moving := false
var _respawning := false

var moving: bool:
        get:
                return _moving


func _ready() -> void:
        add_to_group("player_unit")
        var def := UnitDefs.player_def()
        unit_team = "player"
        unit_id = def["id"]
        display_name = def["display"]
        max_hp = int(def["max_hp"])
        hp = max_hp
        move_speed = float(def["speed"])
        attack_damage = int(def["damage"])
        attack_cooldown = float(def["cooldown"])
        attack_range = float(def["range"])
        knockback_power = float(def.get("knockback", 140.0))
        bolt_speed = float(def.get("bolt_speed", 980.0))
        setup_sheets(def["cell"], def["sheets"])
        # turkuaz enerji isigi — ART_DIRECTION: turkuaz enerji yalnizca oyuncuda
        # NOT: energy 0.55 — kristal + gun isigiyla toplam pozlama dengesi
        # (ilk gorsel kosuda asiri pozlama tespit edildi, dusuruldu)
        var light := PointLight2D.new()
        light.texture = LIGHT_TEXTURE
        light.color = Color8(46, 196, 182)
        light.energy = 0.55
        light.texture_scale = 1.15
        light.position = Vector2(0, -80)
        add_child(light)


func _process(delta: float) -> void:
        if dead:
                tick_combat(delta)
                return
        invuln = maxf(invuln - delta, 0.0)
        if invuln > 0.0:
                body.visible = int(invuln * 12.0) % 2 == 0
        else:
                body.visible = true

        # 1) hareket (mevcut davranis: klavye ya da tap hedefi)
        var key_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
        var move_dir := Vector2.ZERO
        var vel := Vector2.ZERO
        if key_dir.length_squared() > 0.01:
                _moving = false
                move_dir = key_dir.normalized()
                vel = key_dir * move_speed
        elif _moving:
                var to := _target_world - position
                var step := move_speed * delta
                if to.length() <= step:
                        position = _target_world
                        _moving = false
                        _update_cell()
                        arrived.emit(current_cell)
                else:
                        move_dir = to.normalized()
                        vel = to.normalized() * move_speed
        vel += apply_knockback(delta)
        if vel.length_squared() > 0.0:
                position += vel * delta
                _clamp_position()
        if move_dir.length_squared() > 0.0:
                set_facing(move_dir.angle())
        _update_cell()

        # 2) savas
        tick_combat(delta)
        _auto_attack()
        pick_locomotion_anim(move_dir.length_squared() > 0.0 or _moving)


func move_to(world_target: Vector2) -> void:
        _target_world = world_target
        _moving = true


func take_hit(amount: int, from_pos: Vector2) -> void:
        if dead or invuln > 0.0 or _respawning:
                return
        super.take_hit(amount, from_pos)
        if dead:
                _respawning = true
                var tw := create_tween()
                tw.tween_interval(1.4)
                tw.tween_callback(_respawn)


## Olum solmasi: oyuncu queue_free YAPMAZ — respawn eder.
func _on_death_fadeout() -> void:
        pass


func _respawn() -> void:
        position = respawn_point
        _update_cell()
        hp = max_hp
        dead = false
        _respawning = false
        invuln = 2.0
        _knockback = Vector2.ZERO
        body.modulate = Color.WHITE
        shadow.modulate = Color.WHITE
        body.visible = true
        _force_anim("idle")
        if hp_bar != null:
                hp_bar.queue_redraw()


func _auto_attack() -> void:
        if registry == null:
                current_target = null
                return
        if current_target != null and (not is_instance_valid(current_target)
                        or current_target.dead
                        or global_position.distance_to(current_target.global_position) > attack_range * 1.15):
                current_target = null
        if current_target == null:
                current_target = registry.nearest(global_position, attack_range, self) as CombatUnit
        if current_target != null:
                set_facing((current_target.global_position - global_position).angle())
                if can_attack():
                        _cooldown = attack_cooldown
                        _force_anim("attack")
                        fire_bolt(current_target.global_position + Vector2(0.0, -50.0), bolt_speed)


func _clamp_position() -> void:
        position.x = clampf(position.x, arena_bounds.position.x, arena_bounds.end.x)
        position.y = clampf(position.y, arena_bounds.position.y, arena_bounds.end.y)


func _update_cell() -> void:
        current_cell = IsoMath.world_to_map(position)
