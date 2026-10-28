class_name PlaceholderPlayer
extends CombatUnit
## Kanit sahnesi oyuncusu — Faz 05 ile savas yetenekli, Faz 06 ile mobil
## girdi ve aktif yetenekler:
##   - tap hedefi duz hat hareketi + gelistirici klavye + SANAL JOYSTICK
##   - otomatik hedefleme + turkuaz enerji mermisi (turkuaz yalnizca oyuncuda)
##   - Enerji Patlamasi: radyal N mermi (Q / HUD dugmesi)
##   - Atılım: kisa invuln'lu hücum, toz izi (E / HUD dugmesi)
##   - seviye yukseltmeleri PlayerState kartlarindan uygulanir
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

# Faz 06: mobil girdi — joystick vektoru (GameHud/Arena baglar)
var joystick_vector := Vector2.ZERO

# Faz 06: yetenek parametreleri (player_def'ten)
var burst_count := 10
var burst_damage := 10
var burst_cd := 8.0
var burst_speed := 780.0
var dash_dist := 260.0
var dash_cd := 5.0
var dash_speed := 1500.0

var _target_world := Vector2.ZERO
var _moving := false
var _respawning := false

# Faz 06: ic durum
var _burst_t := 0.0
var _dash_t := 0.0
var _dash_dir := Vector2.ZERO
var _dust_acc := 0.0
var _last_move_dir := Vector2(0, 1)
var _base_damage := 0.0
var _base_speed := 0.0
var _base_cooldown := 0.0

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
        burst_count = int(def.get("burst_count", 10))
        burst_damage = int(def.get("burst_damage", 10))
        burst_cd = float(def.get("burst_cd", 8.0))
        burst_speed = float(def.get("burst_speed", 780.0))
        dash_dist = float(def.get("dash_dist", 260.0))
        dash_cd = float(def.get("dash_cd", 5.0))
        dash_speed = float(def.get("dash_speed", 1500.0))
        _base_damage = float(attack_damage)
        _base_speed = move_speed
        _base_cooldown = attack_cooldown
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
        _burst_t = maxf(_burst_t - delta, 0.0)
        _dash_t = maxf(_dash_t - delta, 0.0)

        # gelistirici klavye kisayollari (dokunmatik HUD dugmeleri ayri)
        if Input.is_action_just_pressed("ability_burst"):
                try_burst()
        if Input.is_action_just_pressed("ability_dash"):
                try_dash()

        # 1) hareket — oncelik: klavye > joystick > tap hedefi > atılım
        var key_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
        var stick := joystick_vector
        if stick.length() < 0.18:
                stick = Vector2.ZERO  # oluj bolge
        var move_dir := Vector2.ZERO
        var vel := Vector2.ZERO
        if _dash_t > 0.0:
                move_dir = _dash_dir
                vel = _dash_dir * dash_speed
                _dust_acc += delta
                if _dust_acc >= 0.03:
                        _dust_acc = 0.0
                        if fx is CombatFx:
                                (fx as CombatFx).spawn_footstep_dust(position + Vector2(0, 4))
        elif key_dir.length_squared() > 0.01:
                _moving = false
                move_dir = key_dir.normalized()
                vel = key_dir * move_speed
        elif stick.length_squared() > 0.01:
                _moving = false
                move_dir = stick.normalized()
                vel = stick * move_speed
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
                _last_move_dir = move_dir.normalized()
        _update_cell()

        # 2) savas
        tick_combat(delta)
        _auto_attack()
        var is_walking := move_dir.length_squared() > 0.0 or _moving
        pick_locomotion_anim(is_walking)
        # 3) ayak tozu (Faz 06) — yuruyus sirasinda olcuklu uretim
        if is_walking and vel.length() > 60.0 and not (_dash_t > 0.0):
                _dust_acc += delta
                if _dust_acc >= 0.14:
                        _dust_acc = 0.0
                        if fx is CombatFx:
                                (fx as CombatFx).spawn_footstep_dust(position + Vector2(0, 4))


func move_to(world_target: Vector2) -> void:
        _target_world = world_target
        _moving = true


# ---------------- Faz 06: aktif yetenekler ----------------

func can_burst() -> bool:
        return _burst_t <= 0.0 and not dead


func can_dash() -> bool:
        return _dash_t <= 0.0 and not dead


## 0..1 arasi hazirlik orani (HUD cooldown halkasi icin).
func burst_frac() -> float:
        return 1.0 - _burst_t / maxf(burst_cd, 0.01)


func dash_frac() -> float:
        return 1.0 - _dash_t / maxf(dash_cd, 0.01)


## Enerji Patlamasi: radyal N mermi; cagiran HUD/komuta katmanidir.
func try_burst() -> bool:
        if not can_burst():
                return false
        _burst_t = burst_cd
        _force_anim("attack")
        for i in burst_count:
                var ang := TAU * float(i) / float(burst_count) + 0.15
                fire_bolt(global_position + Vector2.from_angle(ang) * 120.0, burst_speed, burst_damage)
        if fx is CombatFx:
                (fx as CombatFx).spawn_impact_flash(global_position + Vector2(0, -50), true)
        return true


## Atılım: yon = son hareket yonu (yoksa baktigi yon); kisa invuln + toz izi.
func try_dash() -> bool:
        if not can_dash():
                return false
        var dir := _last_move_dir
        if dir.length_squared() < 0.01:
                dir = Vector2.from_angle(facing * PI / 4.0)
        _dash_dir = dir.normalized()
        _dash_t = dash_dist / dash_speed
        invuln = maxf(invuln, 0.32)
        _dust_acc = 0.0
        set_facing(_dash_dir.angle())
        return true


## PlayerState seviye kartlarindan uygulanir ("magnet" arenaya sinyallenir).
func apply_upgrade(kind: String) -> void:
        match kind:
                "damage":
                        _base_damage *= 1.15
                        attack_damage = int(round(_base_damage))
                "speed":
                        _base_speed *= 1.12
                        move_speed = _base_speed
                "cooldown":
                        _base_cooldown *= 0.88
                        attack_cooldown = _base_cooldown
                        burst_cd *= 0.88
                        dash_cd *= 0.88
                "vitality":
                        max_hp += 25
                        hp = mini(hp + 25, max_hp)
                        if hp_bar != null:
                                hp_bar.queue_redraw()
                "burst":
                        burst_count += 2
                "magnet":
                        pass  # arena baglantisi upgrade_applied ile yapar
        upgrade_applied.emit(kind)


signal upgrade_applied(kind: String)


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
