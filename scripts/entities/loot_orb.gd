class_name LootOrb
extends Node2D
## Faz 06: dunyada duran toplama nesnesi (XP topu / hurda parcasi).
##   - zemine yakin kucuk blob golge (iso temas okunabilirligi)
##   - hafif yukari-asagi salinim (bob)
##   - oyuncu magnet alanina girince ivmelenerek yaklasir, temasinda toplanir
##   - omur dolunca son 3 saniye yanip soner ve kendini yok eder
## Butce: uretim FXBudget "orb" turu uzerinden yapilir (LootDirector).

const TEX_XP := preload("res://assets/art/vfx/tex_fx_xp_orb_01.png")
const TEX_SCRAP := preload("res://assets/art/vfx/tex_fx_scrap_01.png")
const SHADOW_TEX := preload("res://assets/art/vfx/tex_fx_blob_shadow_01.png")

const MAGNET_RADIUS := 170.0
const COLLECT_RADIUS := 52.0
const LIFETIME := 20.0
const BLINK_AT := 17.0

var kind := "xp"           # "xp" | "scrap"
var value := 10
var player: Node2D = null
var player_state: PlayerState = null
var fx: CombatFx = null
var magnet_range := MAGNET_RADIUS

var _sprite: Sprite2D
var _shadow: Sprite2D
var _life := 0.0
var _speed := 0.0
var _bob_t := 0.0
var _collected := false


func _ready() -> void:
        _bob_t = randf() * TAU
        _shadow = Sprite2D.new()
        _shadow.texture = SHADOW_TEX
        _shadow.scale = Vector2(0.12, 0.12)
        _shadow.modulate = Color(1, 1, 1, 0.55)
        _shadow.show_behind_parent = true
        add_child(_shadow)
        _sprite = Sprite2D.new()
        _sprite.texture = TEX_XP if kind == "xp" else TEX_SCRAP
        _sprite.scale = Vector2(0.5, 0.5)
        add_child(_sprite)
        # dogus pop animasyonu
        _sprite.scale = Vector2(0.1, 0.1)
        var tw := create_tween()
        tw.tween_property(_sprite, "scale", Vector2(0.5, 0.5), 0.22) \
                .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
        if _collected:
                return
        _life += delta
        if _life >= LIFETIME:
                queue_free()
                return
        # son 3 saniye uyari yanip sondmesi (ART_DIRECTION: 3 Hz ustu yok)
        if _life > BLINK_AT:
                _sprite.modulate.a = 0.45 + 0.45 * sin(_life * 9.0)
        _bob_t += delta * 3.0
        _sprite.position.y = -6.0 - 3.0 * sin(_bob_t)
        _sprite.rotation = 0.12 * sin(_bob_t * 0.7)
        # magnet + toplama
        if player != null and is_instance_valid(player):
                var to_p: Vector2 = player.global_position - global_position
                var d := to_p.length()
                if d <= magnet_range:
                        _speed = move_toward(_speed, 820.0, 2400.0 * delta)
                        global_position += to_p.normalized() * _speed * delta
                if d <= COLLECT_RADIUS:
                        _collect()
                        return


func _collect() -> void:
        _collected = true
        if player_state != null:
                if kind == "xp":
                        player_state.gain_xp(value)
                else:
                        player_state.gain_scrap(value)
        if fx != null:
                if kind == "xp":
                        fx.spawn_xp_collect(global_position, value)
                else:
                        fx.spawn_scrap_collect(global_position, value)
        queue_free()
