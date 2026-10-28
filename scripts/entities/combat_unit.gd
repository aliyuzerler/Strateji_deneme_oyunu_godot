class_name CombatUnit
extends IsoEntity
## Savas varligi tabani (Faz 05): 8 yonlu sheet animasyonu, can, hasar,
## geri bildirimler (beyaz flash + hasar etiketi + geri itme) ve olum akisi.
##
## Pivot/golge kurallari IsoEntity'den gelir (ayak-zemin temasi, 2x doku
## 0.5 scale — smoke testinin pivot/olcek kontrolleri bozulmaz). Doku
## degisimi Sprite2D uzerinden yapilir.
##
## Girinti akisi:
##   - oyuncu: _process icinde tick_combat (gorsel akicilik)
##   - dusman: _physics_process icinde tick_combat (sabit adim)
##   - dead iken de advance edilir (olum animasyonu oynasin diye)

signal damaged(unit: CombatUnit, amount: int, hp_left: int)
signal died(unit: CombatUnit)

const HURT_TIME: float = 0.18
const LIGHT_TEXTURE := preload("res://assets/art/vfx/tex_fx_light_falloff_01.png")

var unit_team := "enemy"
var unit_id := "unit"
var display_name := "Birim"
var max_hp := 100
var hp := 100
var move_speed := 200.0
var attack_damage := 10
var attack_cooldown := 1.0
var attack_range := 400.0
var knockback_power := 120.0
var bolt_speed := 700.0

var anim_lib: SpriteAnimLib = null
var facing := 2
var dead := false
var current_target: CombatUnit = null
var registry: EnemyRegistry = null
var fx: CombatFx = null
var bolt_parent: Node2D = null

var _cooldown := 0.0
var _hurt_t := 0.0
var _anim := ""
var _anim_t := 0.0
var _anim_frame := 0
var _anim_done := false
var _knockback := Vector2.ZERO
var _flash_tween: Tween = null
var hp_bar: Node2D = null


func _enter_tree() -> void:
        # Kod ile uretilen birimlerde Body/Shadow yoktur; tscn tabanlarinda
        # mevcutturlar (ikileme onlenir).
        if get_node_or_null("Shadow") == null:
                var sh := Sprite2D.new()
                sh.name = "Shadow"
                sh.show_behind_parent = true
                add_child(sh)
        if get_node_or_null("Body") == null:
                var b := Sprite2D.new()
                b.name = "Body"
                add_child(b)


func _ready() -> void:
        hp = max_hp


## Sheet setini kurar; pivot = ayak-zemin temasi (w/2, h-8), scale = 0.5.
func setup_sheets(cell: Vector2i, sheets: Dictionary) -> void:
        anim_lib = SpriteAnimLib.new()
        anim_lib.setup(cell, sheets)
        var tex := anim_lib.frame("idle", facing, 0)
        body.texture = tex
        var s := tex.get_size()
        body.scale = Vector2(0.5, 0.5)
        body.offset = Vector2(-s.x * 0.5, -(s.y - 8.0))
        if shadow.texture == null:
                shadow.texture = SHADOW_TEXTURE
        # golge olcegi birim sahnesi genisligine oranlanir (blob dokusu 256 px)
        var shadow_scale := (s.x * 0.5) / 256.0 * 0.92
        shadow.scale = Vector2(shadow_scale, shadow_scale)
        if hp_bar == null:
                hp_bar = load("res://scripts/entities/hp_bar.gd").new()
                add_child(hp_bar)
        _apply_anim("idle")


func set_facing(angle: float) -> void:
        facing = SpriteAnimLib.dir_index_from_angle(angle)


func is_alive() -> bool:
        return not dead


func can_attack() -> bool:
        return _cooldown <= 0.0 and not dead


func tick_combat(delta: float) -> void:
        _cooldown = maxf(_cooldown - delta, 0.0)
        if _hurt_t > 0.0:
                _hurt_t -= delta
        _advance_anim(delta)


## Geri itme hizini dondurur ve sönümleyerek azaltir; cagiran konuma ekler.
func apply_knockback(delta: float) -> Vector2:
        var v := _knockback
        _knockback = _knockback.move_toward(Vector2.ZERO, 900.0 * delta)
        return v


func take_hit(amount: int, from_pos: Vector2) -> void:
        if dead:
                return
        hp = maxi(hp - amount, 0)
        damaged.emit(self, amount, hp)
        if fx != null:
                var col := Color(0.84, 0.27, 0.25)
                if unit_team == "enemy":
                        col = Color(0.18, 0.77, 0.71)
                fx.spawn_damage_label(global_position + Vector2(0.0, _head_offset()), amount, col)
        if hp <= 0:
                _start_death()
                return
        _hurt_t = HURT_TIME
        _knockback = (global_position - from_pos).normalized() * knockback_power
        _flash()
        _force_anim("hurt")
        if hp_bar != null:
                hp_bar.queue_redraw()


func fire_bolt(target_pos: Vector2, p_speed: float, p_damage: int = -1) -> void:
        if bolt_parent == null:
                return
        var bolt: CombatBolt = load("res://scripts/entities/projectile.gd").new()
        bolt.setup(unit_team, p_damage if p_damage >= 0 else attack_damage, registry, fx, _bolt_player_ref())
        bolt.position = global_position + Vector2(0.0, -60.0)
        var dir := (target_pos - bolt.position).normalized()
        if dir == Vector2.ZERO:
                dir = Vector2(0.0, -1.0)
        bolt.velocity = dir * p_speed
        bolt.rotation = dir.angle()
        bolt_parent.add_child(bolt)


func _bolt_player_ref() -> Node2D:
        # Dusman mermisi icin hedef: oyuncu. Oyuncu mermisi icin gereksizdir.
        return null if unit_team == "player" else get_tree().get_first_node_in_group("player_unit")


func _head_offset() -> float:
        if anim_lib != null:
                return -float(anim_lib.cell.y) * 0.5
        return -100.0


func _flash() -> void:
        if _flash_tween != null and _flash_tween.is_valid():
                _flash_tween.kill()
        body.modulate = Color(2.2, 2.2, 2.2, 1.0)
        _flash_tween = create_tween()
        _flash_tween.tween_property(body, "modulate", Color.WHITE, 0.14)


func _start_death() -> void:
        dead = true
        current_target = null
        if registry != null:
                registry.unregister(self)
        _force_anim("death")
        # Faz 06: olum tozu bulutu (turkuaz tint yalnizca oyuncuda)
        if fx is CombatFx:
                (fx as CombatFx).spawn_death_dust(global_position, unit_team == "player")
        if hp_bar != null:
                hp_bar.queue_redraw()
        died.emit(self)
        var tw := create_tween()
        tw.tween_interval(0.45)
        tw.tween_property(shadow, "modulate:a", 0.0, 0.5)
        tw.parallel().tween_property(body, "modulate:a", 0.0, 0.5)
        tw.tween_callback(_on_death_fadeout)


## Olum solmasi bittikten sonra ne olacagi; oyuncu override eder
## (respawn yapar, queue_free yapmaz).
func _on_death_fadeout() -> void:
        queue_free()


# ---------------- animasyon motoru ----------------

func _apply_anim(anim: String) -> void:
        if _anim == anim:
                return
        _anim = anim
        _anim_t = 0.0
        _anim_frame = 0
        _anim_done = false
        if anim_lib != null and anim_lib.has_anim(anim):
                body.texture = anim_lib.frame(anim, facing, 0)


func _force_anim(anim: String) -> void:
        _anim = ""
        _apply_anim(anim)


func _advance_anim(delta: float) -> void:
        if anim_lib == null or _anim == "" or _anim_done:
                return
        _anim_t += delta
        var period := 1.0 / maxf(anim_lib.fps(_anim), 0.01)
        while _anim_t >= period:
                _anim_t -= period
                if _anim_frame < anim_lib.frame_count(_anim) - 1:
                        _anim_frame += 1
                elif anim_lib.loops(_anim):
                        _anim_frame = 0
                else:
                        _anim_frame = anim_lib.frame_count(_anim) - 1
                        _anim_done = true
                        break
        body.texture = anim_lib.frame(_anim, facing, _anim_frame)


func anim_state() -> String:
        return _anim


## Yuruyus/durmus animasyonu secimi; saldiri ve hasar animasyonlarina dokunmaz.
func pick_locomotion_anim(moving: bool) -> void:
        if dead or _hurt_t > 0.0:
                return
        if _anim == "attack" and not _anim_done:
                return
        _apply_anim("walk" if moving else "idle")
