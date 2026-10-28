class_name LootDirector
extends Node
## Faz 06: olum odulu yonetimi. Dusman oldugunde XP toplari ve hurda
## parcaciklari duser; butce doluysa deger en yakin mevcut topa eklenir
## (node patlamasi engellenir). Baglanti: EnemyDirector.unit_spawned ->
## track_unit(unit) -> unit.died.

var loot_parent: Node2D = null
var player: CombatUnit = null
var player_state: PlayerState = null
var fx: CombatFx = null
var budget: FXBudget = null
var magnet_range := 170.0
var rng := RandomNumberGenerator.new()


func _init() -> void:
        rng.seed = 20261028


func setup(p_parent: Node2D, p_player: CombatUnit, p_state: PlayerState,
                p_fx: CombatFx, p_budget: FXBudget = null) -> void:
        loot_parent = p_parent
        player = p_player
        player_state = p_state
        fx = p_fx
        budget = p_budget


func track_unit(unit: CombatUnit) -> void:
        if not unit.died.is_connected(_on_unit_died):
                unit.died.connect(_on_unit_died)


func _on_unit_died(unit: CombatUnit) -> void:
        if player_state == null or loot_parent == null:
                return
        player_state.add_kill()
        var xp_amount := player_state.xp_for(unit.unit_id)
        var scrap_amount := player_state.scrap_for(unit.unit_id)
        _spawn_orb("xp", xp_amount, unit.global_position + Vector2(rng.randf_range(-14, 14), rng.randf_range(-10, 10)))
        if scrap_amount > 0:
                _spawn_orb("scrap", scrap_amount, unit.global_position + Vector2(rng.randf_range(-24, 24), rng.randf_range(-14, 14)))


func _spawn_orb(kind: String, value: int, at: Vector2) -> void:
        if budget != null and not budget.can_spawn("orb"):
                # butce dolu: en yakin ayni tur topu buyutulur (node tasarrufu)
                var nearest := _nearest_orb(kind, at)
                if nearest != null:
                        nearest.value += value
                        return
        var orb := LootOrb.new()
        orb.kind = kind
        orb.value = value
        orb.player = player
        orb.player_state = player_state
        orb.fx = fx
        orb.magnet_range = magnet_range
        loot_parent.add_child(orb)
        orb.position = at


func _nearest_orb(kind: String, at: Vector2) -> LootOrb:
        var best: LootOrb = null
        var best_d := 300.0 * 300.0
        for c in loot_parent.get_children():
                var orb := c as LootOrb
                if orb == null or orb.kind != kind or orb._collected:
                        continue
                var d: float = at.distance_squared_to(orb.global_position)
                if d < best_d:
                        best_d = d
                        best = orb
        return best


func clear_all() -> void:
        if loot_parent == null:
                return
        for c in loot_parent.get_children():
                c.queue_free()
