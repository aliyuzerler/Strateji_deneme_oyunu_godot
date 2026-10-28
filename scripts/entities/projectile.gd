class_name CombatBolt
extends Node2D
## Duz hatli mermi (Faz 05) + Faz 06: enerji izi (trail noktalari) ve
## isabet carpma parlamasi. Hedef takibi yok; isabet = yaricap sorgusu.
## Oyuncu mermisi EnemyRegistry tarar; dusman mermisi dogrudan oyuncuyu
## kontrol eder. Omru dolan / sahneyi asan mermi kendini yok eder.

const TEX_PLAYER := preload("res://assets/art/vfx/tex_fx_bolt_player_01.png")
const TEX_ENEMY := preload("res://assets/art/vfx/tex_fx_bolt_enemy_01.png")
const TRAIL_SPACING := 30.0

var velocity := Vector2.ZERO
var damage := 10
var team := "player"
var max_life := 2.2
var hit_radius := 40.0
var registry: EnemyRegistry = null
var fx: Node2D = null
var player_target: Node2D = null

var _life := 0.0
var _trail_acc := 0.0


func setup(p_team: String, p_damage: int, p_registry: EnemyRegistry, p_fx: Node2D, p_player: Node2D = null) -> void:
        team = p_team
        damage = p_damage
        registry = p_registry
        fx = p_fx
        player_target = p_player
        var sprite := Sprite2D.new()
        sprite.texture = TEX_PLAYER if team == "player" else TEX_ENEMY
        sprite.scale = Vector2(0.5, 0.5)
        add_child(sprite)


func _physics_process(delta: float) -> void:
        var step := velocity * delta
        position += step
        _life += delta
        # Faz 06: iz noktalari — hareket yonu tersine sabit aralikla birakilir
        _trail_acc += step.length()
        if _trail_acc >= TRAIL_SPACING and fx is CombatFx:
                _trail_acc = 0.0
                (fx as CombatFx).spawn_trail_dot(position - step.normalized() * 14.0, team)
        if _life >= max_life:
                queue_free()
                return
        if team == "player":
                if registry == null:
                        return
                var hit: Node2D = registry.nearest(position, hit_radius)
                var cu := hit as CombatUnit
                if cu != null and not cu.dead:
                        cu.take_hit(damage, position)
                        if fx is CombatFx:
                                var cfx := fx as CombatFx
                                cfx.spawn_impact_flash(position, true)
                                cfx.spawn_hit_puff(position, true)
                        queue_free()
        else:
                if player_target == null or not is_instance_valid(player_target):
                        return
                var pu := player_target as CombatUnit
                if pu == null or pu.dead:
                        return
                if position.distance_to(pu.global_position) <= hit_radius:
                        pu.take_hit(damage, position)
                        if fx is CombatFx:
                                var cfx2 := fx as CombatFx
                                cfx2.spawn_impact_flash(position, false)
                                cfx2.spawn_hit_puff(position, false)
                        queue_free()
