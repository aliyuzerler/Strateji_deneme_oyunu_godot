class_name EnemyDirector
extends Node
## Faz 05: dusman dalga uretimi + performans olcumu (bench).
## Dalga kapilari arena kenarlarindadir; tip karisimi 40% runner / 30% brute
## / 30% spitter (rng tohumlu — deterministik uretim).

signal bench_finished(results: Dictionary)

const GATE_CELLS: Array[Vector2i] = [
        Vector2i(1, 1), Vector2i(10, 1), Vector2i(1, 10), Vector2i(10, 10),
        Vector2i(5, 0), Vector2i(0, 5), Vector2i(6, 11), Vector2i(11, 6),
]

var ground_layer: TileMapLayer = null
var entities_layer: Node2D = null
var player: CombatUnit = null
var registry: EnemyRegistry = null
var fx: CombatFx = null
var world_bounds := Rect2()
var rng := RandomNumberGenerator.new()


func _init() -> void:
        rng.seed = 20261028


func setup(p_ground: TileMapLayer, p_entities: Node2D, p_player: CombatUnit,
                p_registry: EnemyRegistry, p_fx: CombatFx, p_bounds: Rect2) -> void:
        ground_layer = p_ground
        entities_layer = p_entities
        player = p_player
        registry = p_registry
        fx = p_fx
        world_bounds = p_bounds


func spawn_wave(count: int) -> Array:
        var defs := UnitDefs.enemy_defs()
        var out: Array = []
        for i in count:
                out.append(_spawn_one(defs[i % defs.size()], GATE_CELLS[i % GATE_CELLS.size()]))
        return out


func spawn_mixed(total: int) -> Array:
        var out: Array = []
        for i in total:
                var roll := rng.randf()
                var def: Dictionary
                if roll < 0.4:
                        def = UnitDefs.runner_def()
                elif roll < 0.7:
                        def = UnitDefs.brute_def()
                else:
                        def = UnitDefs.spitter_def()
                var gate := GATE_CELLS[i % GATE_CELLS.size()]
                out.append(_spawn_one(def, gate))
        return out


func clear_all() -> void:
        for u in registry.all_units():
                var cu := u as CombatUnit
                if cu != null and not cu.dead:
                        cu.take_hit(999999, Vector2.ZERO)


func _spawn_one(def: Dictionary, cell: Vector2i) -> EnemyUnit:
        var e := EnemyUnit.new()
        entities_layer.add_child(e)
        e.setup_from_def(def, player, registry, fx)
        e.position = ground_layer.map_to_local(cell) \
                + Vector2(rng.randf_range(-48.0, 48.0), rng.randf_range(-24.0, 24.0))
        e.set_bounds(world_bounds.grow(-24.0))
        registry.register(e)
        return e


## Bos sahne kare maliyeti (referans deger).
func measure_baseline(frames: int) -> float:
        var t0 := Time.get_ticks_usec()
        for i in frames:
                await get_tree().process_frame
        return (Time.get_ticks_usec() - t0) / 1000.0 / float(frames)


func run_bench(total: int, seconds: float) -> Dictionary:
        var baseline := await measure_baseline(90)
        var spawned := spawn_mixed(total)
        for i in 30:
                await get_tree().process_frame
        var samples := PackedFloat64Array()
        var frames := 0
        var t_end := Time.get_ticks_usec() + int(seconds * 1e6)
        while Time.get_ticks_usec() < t_end:
                var f0 := Time.get_ticks_usec()
                await get_tree().process_frame
                samples.append(float(Time.get_ticks_usec() - f0) / 1000.0)
                frames += 1
        samples.sort()
        var sum := 0.0
        for v in samples:
                sum += v
        var avg := sum / maxf(float(samples.size()), 1.0)
        var p95: float = samples[int(samples.size() * 0.95)] if samples.size() > 0 else 0.0
        var maxv: float = samples[samples.size() - 1] if samples.size() > 0 else 0.0
        var results := {
                "requested": total,
                "spawned": spawned.size(),
                "alive": registry.count(),
                "frames": frames,
                "seconds": seconds,
                "baseline_ms": snappedf(baseline, 0.001),
                "avg_ms": snappedf(avg, 0.001),
                "p95_ms": snappedf(p95, 0.001),
                "max_ms": snappedf(maxv, 0.001),
                "nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
                "objects": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
                "fps": int(Performance.get_monitor(Performance.TIME_FPS)),
                "headless": DisplayServer.get_name() == "headless",
        }
        print("F05_BENCH_JSON ", JSON.stringify(results))
        bench_finished.emit(results)
        return results
