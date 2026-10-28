class_name CombatFx
extends Node2D
## Savas efektleri (Faz 05 + Faz 06): hasar etiketleri, isabet puflemeleri,
## telegraf halkalari; Faz 06 ekleri: ayak/olum tozu, carpma parlamasi,
## mermi iz noktalari, XP/hurda toplama efektleri, seviye atlama halkasi.
## Kisa omurlu; her efekt kendi tween'i ile kendini temizler.
## Telegraf halkalari ZEMINDE cizilir -> ground_parent (arena GroundFx).
##
## BUTCE (Faz 06): tum spawn'lar FXBudget'tan izin ister (budget null ise
## gecmiteki gibi sinirsiz — eski smoke akislari bozulmaz). Kozmetik
## efektlerde kaliteye gore olasilik kirpma uygulanir.

const RING_TEXTURE := preload("res://assets/art/vfx/tex_fx_ring_telegraph_01.png")
const DUST_TEXTURE := preload("res://assets/art/vfx/tex_fx_dust_puff_01.png")
const CORE_TEXTURE := preload("res://assets/art/vfx/tex_fx_impact_core_01.png")
const TRAIL_TEXTURE := preload("res://assets/art/vfx/tex_fx_trail_dot_01.png")

## Toplama/butce renkleri (ART_DIRECTION B.4): turkuaz yalnizca oyuncu tarafı
const COL_TEAL := Color(0.18, 0.77, 0.71)
const COL_TEAL_LIGHT := Color(0.44, 0.86, 0.82)
const COL_RED := Color(0.84, 0.27, 0.25)
const COL_AMBER := Color(0.85, 0.63, 0.36)
const COL_DUST := Color(0.91, 0.79, 0.56)

var ground_parent: Node2D = null
var budget: FXBudget = null

var _add_material: CanvasItemMaterial = null


func _material_add() -> CanvasItemMaterial:
        if _add_material == null:
                _add_material = CanvasItemMaterial.new()
                _add_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
        return _add_material


func _rand() -> float:
        return randf()


func spawn_damage_label(at: Vector2, amount: int, color: Color) -> void:
        if budget != null and not budget.can_spawn("label"):
                return
        var lbl := Label.new()
        lbl.text = str(amount)
        lbl.add_theme_font_size_override("font_size", 30)
        lbl.add_theme_color_override("font_color", color)
        lbl.add_theme_color_override("font_outline_color", Color(0.08, 0.09, 0.11, 0.9))
        lbl.add_theme_constant_override("outline_size", 8)
        add_child(lbl)
        lbl.position = at + Vector2(-20.0, -18.0)
        lbl.z_index = 20
        var tw := lbl.create_tween()
        tw.tween_property(lbl, "position:y", lbl.position.y - 52.0, 0.65) \
                .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.5).set_delay(0.2)
        tw.tween_callback(lbl.queue_free)


func spawn_hit_puff(at: Vector2, player_dealt: bool) -> void:
        var s := Sprite2D.new()
        s.texture = RING_TEXTURE
        s.modulate = Color(0.18, 0.77, 0.71, 0.85) if player_dealt else Color(0.84, 0.27, 0.25, 0.85)
        s.scale = Vector2(0.14, 0.14)
        add_child(s)
        s.position = at
        s.z_index = 15
        var tw := s.create_tween()
        tw.tween_property(s, "scale", Vector2(0.32, 0.32), 0.16)
        tw.parallel().tween_property(s, "modulate:a", 0.0, 0.18)
        tw.tween_callback(s.queue_free)


## Brute slam oncesi yer halkasi. Caller iptal etmek icin free_telegraph kullanir.
func spawn_telegraph(at: Vector2, radius_px: float) -> Node2D:
        var parent := ground_parent if ground_parent != null else self
        var s := Sprite2D.new()
        s.texture = RING_TEXTURE
        var k := (radius_px * 2.0) / 220.0
        s.scale = Vector2(k, k)
        s.modulate = Color(1.0, 1.0, 1.0, 0.55)
        parent.add_child(s)
        s.position = at
        var tw := s.create_tween().set_loops()
        tw.tween_property(s, "modulate:a", 0.95, 0.2)
        tw.tween_property(s, "modulate:a", 0.45, 0.2)
        return s


func spawn_slam_burst(at: Vector2) -> void:
        var parent := ground_parent if ground_parent != null else self
        var s := Sprite2D.new()
        s.texture = RING_TEXTURE
        s.scale = Vector2(0.4, 0.4)
        s.modulate = Color(0.84, 0.27, 0.25, 0.9)
        parent.add_child(s)
        s.position = at
        var tw := s.create_tween()
        tw.tween_property(s, "scale", Vector2(1.15, 1.15), 0.22) \
                .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        tw.parallel().tween_property(s, "modulate:a", 0.0, 0.24)
        tw.tween_callback(s.queue_free)


func free_telegraph(node: Node2D) -> void:
        if node != null and is_instance_valid(node):
                node.queue_free()


# ============================== Faz 06: yeni efektler ==============================

## Ayak tozu: oyuncu yururken periyodik cagirilir; kaliteye gore olasilik.
func spawn_footstep_dust(at: Vector2) -> void:
        if budget != null and (not budget.can_spawn("fx") or randf() > budget.spawn_prob()):
                return
        var s := Sprite2D.new()
        s.texture = DUST_TEXTURE
        s.position = at + Vector2(_rand() * 14.0 - 7.0, _rand() * 8.0 - 4.0)
        s.scale = Vector2(0.14, 0.14)
        s.modulate = Color(COL_DUST.r, COL_DUST.g, COL_DUST.b, 0.55)
        s.z_index = 8
        add_child(s)
        var tw := s.create_tween()
        tw.tween_property(s, "position:y", s.position.y - 14.0, 0.5) \
                .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        tw.parallel().tween_property(s, "scale", Vector2(0.24, 0.24), 0.5)
        tw.parallel().tween_property(s, "modulate:a", 0.0, 0.5)
        tw.tween_callback(s.queue_free)


## Olum tozu: birim oldugunde toz bulutu (kaliteye gore kume sayisi).
func spawn_death_dust(at: Vector2, is_player: bool = false) -> void:
        var count := 5
        var tint := COL_DUST
        if is_player:
                tint = COL_TEAL_LIGHT
        if budget != null:
                if not budget.can_spawn("fx"):
                        return
                count = budget.burst_count(5)
        for i in count:
                var s := Sprite2D.new()
                s.texture = DUST_TEXTURE
                var ang := TAU * float(i) / float(count) + _rand() * 0.6
                var dist := 16.0 + _rand() * 30.0
                s.position = at + Vector2(cos(ang) * dist, sin(ang) * dist * 0.5)
                s.scale = Vector2(0.16, 0.16)
                s.modulate = Color(tint.r, tint.g, tint.b, 0.6)
                s.z_index = 9
                add_child(s)
                var tw := s.create_tween()
                tw.tween_interval(0.03 * i)
                tw.tween_property(s, "scale", Vector2(0.3, 0.3), 0.42) \
                        .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
                tw.parallel().tween_property(s, "modulate:a", 0.0, 0.44)
                tw.tween_callback(s.queue_free)


## Carpma parlamasi: parlak cekirdek (additive) — mermi isabetinde puf ile
## birlikte cagrilir. Oyuncu vurgusu turkuaz-beyaz, dusman vurgusu kizil.
func spawn_impact_flash(at: Vector2, player_dealt: bool) -> void:
        if budget != null and not budget.can_spawn("fx"):
                return
        var s := Sprite2D.new()
        s.texture = CORE_TEXTURE
        s.material = _material_add()
        s.rotation = _rand() * TAU
        var base := Color.WHITE
        if player_dealt:
                base = Color(0.75, 1.0, 0.97)
        else:
                base = Color(1.0, 0.72, 0.7)
        s.modulate = base
        s.scale = Vector2(0.18, 0.18)
        s.z_index = 16
        add_child(s)
        s.position = at
        var tw := s.create_tween()
        tw.tween_property(s, "scale", Vector2(0.36, 0.36), 0.14) \
                .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        tw.parallel().tween_property(s, "modulate:a", 0.0, 0.16)
        tw.tween_callback(s.queue_free)


## Mermi iz noktasi: enerji mermisi arkasinda kisa omurlu parlayan nokta.
func spawn_trail_dot(at: Vector2, team: String) -> void:
        if budget != null and (not budget.can_spawn("trail") or randf() > budget.spawn_prob()):
                return
        var s := Sprite2D.new()
        s.texture = TRAIL_TEXTURE
        s.material = _material_add()
        s.position = at
        s.modulate = COL_TEAL_LIGHT if team == "player" else Color(1.0, 0.55, 0.5)
        s.scale = Vector2(0.34, 0.34)
        s.z_index = 12
        add_child(s)
        var tw := s.create_tween()
        tw.tween_property(s, "scale", Vector2(0.12, 0.12), 0.26)
        tw.parallel().tween_property(s, "modulate:a", 0.0, 0.26)
        tw.tween_callback(s.queue_free)


## XP toplama efektleri: kucuk turkuaz halka + "+N XP" etiketi.
func spawn_xp_collect(at: Vector2, amount: int) -> void:
        _collect_ring(at, COL_TEAL)
        if budget == null or budget.can_spawn("label"):
                var lbl := Label.new()
                lbl.text = "+%d XP" % amount
                lbl.add_theme_font_size_override("font_size", 19)
                lbl.add_theme_color_override("font_color", Color(0.79, 0.97, 0.94))
                lbl.add_theme_color_override("font_outline_color", Color(0.08, 0.09, 0.11, 0.9))
                lbl.add_theme_constant_override("outline_size", 6)
                add_child(lbl)
                lbl.position = at + Vector2(-30.0, -46.0)
                lbl.z_index = 20
                var tw := lbl.create_tween()
                tw.tween_property(lbl, "position:y", lbl.position.y - 40.0, 0.55) \
                        .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
                tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.5).set_delay(0.12)
                tw.tween_callback(lbl.queue_free)


## Hurda toplama efektleri: amber halka + "+N" etiketi.
func spawn_scrap_collect(at: Vector2, amount: int) -> void:
        _collect_ring(at, COL_AMBER)
        if budget == null or budget.can_spawn("label"):
                var lbl := Label.new()
                lbl.text = "+%d" % amount
                lbl.add_theme_font_size_override("font_size", 19)
                lbl.add_theme_color_override("font_color", Color(0.95, 0.79, 0.5))
                lbl.add_theme_color_override("font_outline_color", Color(0.08, 0.09, 0.11, 0.9))
                lbl.add_theme_constant_override("outline_size", 6)
                add_child(lbl)
                lbl.position = at + Vector2(-14.0, -38.0)
                lbl.z_index = 20
                var tw := lbl.create_tween()
                tw.tween_property(lbl, "position:y", lbl.position.y - 34.0, 0.5) \
                        .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
                tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.45).set_delay(0.1)
                tw.tween_callback(lbl.queue_free)


## Seviye atlama halkasi: buyuyen turkuaz halka + parlama.
func spawn_levelup(at: Vector2) -> void:
        var parent := ground_parent if ground_parent != null else self
        var s := Sprite2D.new()
        s.texture = RING_TEXTURE
        s.position = at
        s.scale = Vector2(0.25, 0.25)
        s.modulate = Color(COL_TEAL.r, COL_TEAL.g, COL_TEAL.b, 0.9)
        parent.add_child(s)
        var tw := s.create_tween()
        tw.tween_property(s, "scale", Vector2(1.0, 1.0), 0.5) \
                .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        tw.parallel().tween_property(s, "modulate:a", 0.0, 0.55)
        tw.tween_callback(s.queue_free)
        var core := Sprite2D.new()
        core.texture = CORE_TEXTURE
        core.material = _material_add()
        core.position = at + Vector2(0, -60)
        core.modulate = Color(0.7, 1.0, 0.96, 0.9)
        core.scale = Vector2(0.3, 0.3)
        core.z_index = 18
        add_child(core)
        var tw2 := core.create_tween()
        tw2.tween_property(core, "scale", Vector2(0.6, 0.6), 0.35) \
                .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        tw2.parallel().tween_property(core, "modulate:a", 0.0, 0.4)
        tw2.tween_callback(core.queue_free)


func _collect_ring(at: Vector2, color: Color) -> void:
        var s := Sprite2D.new()
        s.texture = RING_TEXTURE
        s.position = at
        s.scale = Vector2(0.08, 0.08)
        s.modulate = Color(color.r, color.g, color.b, 0.9)
        s.z_index = 14
        add_child(s)
        var tw := s.create_tween()
        tw.tween_property(s, "scale", Vector2(0.2, 0.2), 0.22)
        tw.parallel().tween_property(s, "modulate:a", 0.0, 0.24)
        tw.tween_callback(s.queue_free)
