class_name CombatFx
extends Node2D
## Savas efektleri (Faz 05): hasar etiketleri, isabet puflemeleri, telegraf
## halkalari. Kisa omurlu; her efekt kendi tween'i ile kendini temizler.
## Telegraf halkalari ZEMINDE cizilir -> ground_parent (arena GroundFx).

const RING_TEXTURE := preload("res://assets/art/vfx/tex_fx_ring_telegraph_01.png")

var ground_parent: Node2D = null


func spawn_damage_label(at: Vector2, amount: int, color: Color) -> void:
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
