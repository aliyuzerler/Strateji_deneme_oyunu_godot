class_name UnitHpBar
extends Node2D
## Bas ustunde kucuk can cubugu (Faz 05). Yalnizca birim hasar aldiginda
## gorunur; node cizimi ucuzdur (iki draw_rect). Parent = CombatUnit.


func _ready() -> void:
        var u := get_parent() as CombatUnit
        if u != null and u.anim_lib != null:
                position = Vector2(0, 0)
                z_index = 30
                queue_redraw()


func _draw() -> void:
        var u := get_parent() as CombatUnit
        if u == null or u.anim_lib == null:
                return
        if u.dead or u.hp >= u.max_hp:
                return
        var w := 64.0
        var h := 9.0
        var y := -float(u.anim_lib.cell.y) * 0.5 - 16.0
        draw_rect(Rect2(-w / 2.0, y, w, h), Color(0.08, 0.09, 0.11, 0.9))
        var frac := float(u.hp) / float(maxi(u.max_hp, 1))
        var col := Color(0.18, 0.77, 0.71)
        if u.unit_team != "player":
                col = Color(0.84, 0.27, 0.25)
        draw_rect(Rect2(-w / 2.0 + 1.0, y + 1.0, (w - 2.0) * frac, h - 2.0), col)
