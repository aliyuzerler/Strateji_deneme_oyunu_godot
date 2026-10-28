class_name TestArena
extends Node2D
## Izometrik 2.5D kanit sahnesi (Asama 0.5 - kullanici gorevi).
## Kanitlar: duz sirali derinlik (y-sort), kamera takibi, dokunma girdisi,
## blob gorgeler, sinirli dinamik isik (ARCHITECTURE B.13 butcesi: 2/4 isik).
## Not: TileSet kodla kurulur; production'da .tres olacaktir (worklog).

const MAP_SIZE := Vector2i(12, 12)
const SEED: int = 20261028

const PLAYER_START_CELL := Vector2i(5, 7)
const PILLAR_CELL := Vector2i(7, 4)
const FRONT_CELL := Vector2i(7, 5)
const BEHIND_CELL := Vector2i(7, 3)
const CRYSTAL_CELL := Vector2i(3, 8)

const TILE_TEXTURES: Array[String] = [
        "res://assets/art/environment/tiles/tex_env_sand_a_01.png",
        "res://assets/art/environment/tiles/tex_env_sand_b_01.png",
        "res://assets/art/environment/tiles/tex_env_sand_c_01.png",
]

const ROCK_TEXTURE := "res://assets/art/environment/props/tex_prop_rock_01.png"
const PILLAR_TEXTURE := "res://assets/art/environment/props/tex_prop_pillar_01.png"
const CRYSTAL_TEXTURE := "res://assets/art/environment/props/tex_prop_crystal_01.png"
const MARKER_TEXTURE := "res://assets/art/vfx/tex_fx_target_marker_01.png"
const LIGHT_TEXTURE := "res://assets/art/vfx/tex_fx_light_falloff_01.png"

@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var overlay_layer: TileMapLayer = $OverlayLayer
@onready var structure_layer: TileMapLayer = $StructureLayer
@onready var entities_layer: Node2D = $EntitiesLayer
@onready var camera_rig: CameraRig = $CameraRig
@onready var hud: ArenaHud = $HUD
@onready var input_node: ArenaInput = $ArenaInput
@onready var marker: Sprite2D = $TargetMarker
@onready var ground_fx: Node2D = $GroundFx
@onready var loot_layer: Node2D = $LootLayer
@onready var air_fx: CombatFx = $AirFx

var player: PlaceholderPlayer
var pillar: IsoEntity
var world_bounds := Rect2()
var paused := false

# Faz 05: savas orkestrasyonu
var registry: EnemyRegistry = null
var director: EnemyDirector = null
var lock_marker: Sprite2D = null
var _hud_acc := 0.0

# Faz 06: HUD/efekt/odul orkestrasyonu
var fx_budget: FXBudget = null
var player_state: PlayerState = null
var loot: LootDirector = null
var game_hud: GameHud = null
var auto_wave: Timer = null
var _pause_reasons := {}
var _bench_busy := false
## Faz 06: seviye duraklatmasi acik/kapali (eski smoke akislari icin kapali
## tutulabilir; f06 smoke davranisi acik olarak test eder).
var levelup_pause_enabled := true


func _ready() -> void:
        _build_ground()
        _spawn_entities()
        _setup_marker()
        _setup_connections()
        _setup_camera()
        _setup_combat()
        _setup_faz06_args()
        if OS.get_cmdline_user_args().has("--shot"):
                _run_shot_sequence()
        for arg in OS.get_cmdline_user_args():
                if arg.begins_with("--bench="):
                        _run_bench(int(arg.get_slice("=", 1)))
                        break


func _build_ground() -> void:
        var textures: Array[Texture2D] = []
        for path in TILE_TEXTURES:
                textures.append(load(path))
        var tile_set := ArenaTilesetBuilder.build(textures)
        ground_layer.tile_set = tile_set
        structure_layer.tile_set = tile_set
        var rng := RandomNumberGenerator.new()
        rng.seed = SEED
        for x in MAP_SIZE.x:
                for y in MAP_SIZE.y:
                        var variant := rng.randi_range(0, TILE_TEXTURES.size() - 1)
                        ground_layer.set_cell(
                                Vector2i(x, y),
                                ArenaTilesetBuilder.BASE_SOURCE_ID + variant,
                                Vector2i.ZERO
                        )


func _arena_world_rect() -> Rect2:
        var corners: Array[Vector2] = [
                ground_layer.map_to_local(Vector2i.ZERO),
                ground_layer.map_to_local(Vector2i(MAP_SIZE.x - 1, 0)),
                ground_layer.map_to_local(Vector2i(0, MAP_SIZE.y - 1)),
                ground_layer.map_to_local(Vector2i(MAP_SIZE.x - 1, MAP_SIZE.y - 1)),
        ]
        var min_p := corners[0]
        var max_p := corners[0]
        for c in corners:
                min_p = min_p.min(c)
                max_p = max_p.max(c)
        var pad := Vector2(IsoMath.HALF_W, IsoMath.HALF_H)
        return Rect2(min_p - pad, (max_p - min_p) + pad * 2.0)


func _spawn_entities() -> void:
        world_bounds = _arena_world_rect()
        pillar = _spawn_prop(PILLAR_TEXTURE, PILLAR_CELL)
        _spawn_prop(ROCK_TEXTURE, Vector2i(3, 3))
        _spawn_prop(ROCK_TEXTURE, Vector2i(9, 8))
        _spawn_prop(ROCK_TEXTURE, Vector2i(10, 2))
        _spawn_crystal(CRYSTAL_TEXTURE, CRYSTAL_CELL)
        var player_scene: PackedScene = load("res://scenes/entities/placeholder_player.tscn")
        player = player_scene.instantiate()
        player.arena_bounds = world_bounds.grow(-16.0)
        entities_layer.add_child(player)
        player.position = ground_layer.map_to_local(PLAYER_START_CELL)
        player.current_cell = PLAYER_START_CELL


func _spawn_prop(texture_path: String, cell: Vector2i) -> IsoEntity:
        var prop: IsoEntity = load("res://scenes/entities/iso_prop.tscn").instantiate()
        entities_layer.add_child(prop)  # once agaca ekle: @onready dugumleri hazir olsun
        prop.setup_texture(load(texture_path))
        prop.position = ground_layer.map_to_local(cell)
        return prop


func _spawn_crystal(texture_path: String, cell: Vector2i) -> IsoEntity:
        var crystal := _spawn_prop(texture_path, cell)
        var light := PointLight2D.new()
        light.texture = load(LIGHT_TEXTURE)
        light.color = Color8(46, 196, 182)  # TE-500
        light.energy = 1.35
        light.texture_scale = 2.1
        light.position = Vector2(0, -110)
        crystal.add_child(light)
        # sinirli dinamik isik: enerji nabzi (tek dinamik isik, butce: 2/4)
        var tween := create_tween().set_loops()
        tween.tween_property(light, "energy", 1.65, 1.1).set_trans(Tween.TRANS_SINE)
        tween.tween_property(light, "energy", 1.2, 1.1).set_trans(Tween.TRANS_SINE)
        return crystal


func _setup_marker() -> void:
        marker.texture = load(MARKER_TEXTURE)
        marker.visible = false


func _setup_connections() -> void:
        input_node.move_order_issued.connect(_on_move_order)
        input_node.zoom_delta.connect(camera_rig.multiply_zoom)
        input_node.pause_toggle_requested.connect(toggle_pause)
        hud.pause_button_pressed.connect(toggle_pause)
        player.arrived.connect(func(_cell: Vector2i) -> void: hud.set_status(""))


func _setup_camera() -> void:
        camera_rig.target = player
        camera_rig.set_bounds(world_bounds.grow(256.0))


func _process(delta: float) -> void:
        hud.update_position(IsoMath.world_to_map(player.position), player.position,
                        camera_rig.get_zoom())
        # hedef isareti yalnizca yuruyus surerken gorunur
        marker.visible = player.moving
        _hud_acc += delta
        if _hud_acc >= 0.2:
                _hud_acc = 0.0
                var target_name := "-"
                if player.current_target != null and is_instance_valid(player.current_target):
                        target_name = player.current_target.display_name
                hud.set_combat_info("Düşman: %d  |  HP: %d/%d  |  Hedef: %s" % [
                        registry.count(), player.hp, player.max_hp, target_name])
                if fx_budget != null:
                        var s := fx_budget.stats()
                        hud.set_fx_info("FX: kalite %s · efekt %d/%d · etiket %d · iz %d · top %d · fps_ort %.0f" % [
                                s["quality"], s["fx"], FXBudget.CAP_FX, s["labels"],
                                s["trails"], s["orbs"], s["fps_avg"]])
        if lock_marker != null:
                var t := player.current_target
                if t != null and is_instance_valid(t) and not t.dead:
                        lock_marker.visible = true
                        lock_marker.position = t.global_position
                else:
                        lock_marker.visible = false


func _on_move_order(world_pos: Vector2) -> void:
        if paused:
                return
        var cell := ground_layer.local_to_map(world_pos)
        request_move_to_cell(cell)


func request_move_to_cell(cell: Vector2i) -> void:
        if not Rect2i(Vector2i.ZERO, MAP_SIZE).has_point(cell):
                return
        var target := ground_layer.map_to_local(cell)
        player.move_to(target)
        marker.position = target


# ---------------- duraklatma yonetimi (Faz 06: neden tabanli) ----------------
## Nedenler: "manual" (ESC/dugme), "levelup" (yetenek secimi). Hiçbir aktif
## neden kalmadiginda oyun devam eder. toggle_pause() eski davranisi korur
## (smoke uyumu: cift cagri -> duraklat + devam).
func set_pause_reason(reason: String, on: bool) -> void:
        _pause_reasons[reason] = on
        paused = _pause_reasons.values().has(true)
        get_tree().paused = paused
        hud.set_status("DURAKLATILDI" if paused else "")
        if game_hud != null:
                game_hud.set_paused(paused)
        hud.pause_button.text = "DEVAM" if (paused and _pause_reasons.get("manual", false)) else "DURAKLAT"


func toggle_pause() -> void:
        set_pause_reason("manual", not _pause_reasons.get("manual", false))


# -------------------------------------------------- Faz 05 + 06: savas orkestrasyonu
func _setup_combat() -> void:
        registry = EnemyRegistry.new()
        add_child(registry)
        air_fx.ground_parent = ground_fx
        director = EnemyDirector.new()
        add_child(director)
        director.setup(ground_layer, entities_layer, player, registry, air_fx, world_bounds)
        player.registry = registry
        player.fx = air_fx
        player.bolt_parent = air_fx
        player.respawn_point = player.position
        player.died.connect(_on_player_died)
        director.bench_finished.connect(_on_bench_finished)
        lock_marker = Sprite2D.new()
        lock_marker.texture = load(MARKER_TEXTURE)
        lock_marker.modulate = Color(0.18, 0.77, 0.71, 0.85)
        lock_marker.scale = Vector2(0.8, 0.8)
        ground_fx.add_child(lock_marker)
        lock_marker.visible = false
        hud.wave_button_pressed.connect(func() -> void: spawn_demo_wave())
        hud.bench_button_pressed.connect(_on_manual_bench)
        # ---------------- Faz 06: butce, durum, odul, HUD ----------------
        fx_budget = FXBudget.new()
        add_child(fx_budget)
        fx_budget.register_parent("fx", air_fx)
        fx_budget.register_parent("label", air_fx)
        fx_budget.register_parent("trail", air_fx)
        fx_budget.register_parent("ground", ground_fx)
        fx_budget.register_parent("orb", loot_layer)
        air_fx.budget = fx_budget
        player_state = PlayerState.new()
        add_child(player_state)
        loot = LootDirector.new()
        add_child(loot)
        loot.setup(loot_layer, player, player_state, air_fx, fx_budget)
        director.unit_spawned.connect(loot.track_unit)
        director.wave_spawned.connect(_on_wave_spawned)
        game_hud = $GameHud
        game_hud.setup(player, player_state, fx_budget)
        game_hud.joystick_moved.connect(func(v: Vector2) -> void: player.joystick_vector = v)
        game_hud.ability_burst_pressed.connect(func() -> void: player.try_burst())
        game_hud.ability_dash_pressed.connect(func() -> void: player.try_dash())
        game_hud.pause_pressed.connect(toggle_pause)
        game_hud.dev_toggled.connect(func(shown: bool) -> void: hud.set_dev_visible(shown))
        game_hud.upgrade_chosen.connect(_on_upgrade_chosen)
        game_hud.upgrade_skipped.connect(_on_upgrade_skipped)
        player_state.leveled.connect(_on_leveled)
        player.upgrade_applied.connect(_on_upgrade_applied)
        # otomatik dalga akisi (35 s; duraklatmada Timer de durur)
        auto_wave = Timer.new()
        auto_wave.wait_time = 35.0
        auto_wave.autostart = true
        auto_wave.timeout.connect(func() -> void: spawn_demo_wave(4 + player_state.wave))
        add_child(auto_wave)


func _setup_faz06_args() -> void:
        var args := OS.get_cmdline_user_args()
        if args.has("--fx-high") and fx_budget != null:
                fx_budget.force_quality = FXBudget.Quality.HIGH
        if args.has("--safe-test") and game_hud != null:
                # cihet/kulak simülasyonu: L110 T40 R70 B0 + gorsel isaret
                game_hud.debug_force_safe_area(110.0, 40.0, 70.0, 0.0, true)


func spawn_demo_wave(count: int = 6) -> void:
        director.spawn_wave(count)


func _on_wave_spawned(count: int) -> void:
        player_state.wave += 1
        game_hud.toast("DALGA %d GELİYOR" % player_state.wave)


func _on_leveled(level: int) -> void:
        air_fx.spawn_levelup(player.global_position)
        if player.dead or not levelup_pause_enabled:
                game_hud.toast("SEVİYE %d" % level)
                return
        # YETENEK SECIMI -> OYUNU DURAKLAT (gorev geregi)
        var pool := PlayerState.UPGRADE_POOL.duplicate()
        pool.shuffle()
        var options: Array = pool.slice(0, 3)
        set_pause_reason("levelup", true)
        game_hud.show_level_up(level, options)


func _on_upgrade_chosen(id: String) -> void:
        player.apply_upgrade(id)
        game_hud.hide_level_up()
        set_pause_reason("levelup", false)
        for def in PlayerState.UPGRADE_POOL:
                if def["id"] == id:
                        game_hud.toast("Yükseltme: %s" % def["name"])
                        break


func _on_upgrade_skipped() -> void:
        game_hud.hide_level_up()
        set_pause_reason("levelup", false)
        game_hud.toast("Seviye atlandı")


## "magnet" yukseltmesi loot alanini buyutur (oyuncu bilmez, arena uygular).
func _on_upgrade_applied(kind: String) -> void:
        if kind == "magnet" and loot != null:
                loot.magnet_range *= 1.3


func _on_player_died(_unit: CombatUnit) -> void:
        hud.set_status("DÜŞTÜ — yeniden doğuluyor...")
        game_hud.toast("DÜŞTÜN — yeniden doğuluyor")


func _on_manual_bench() -> void:
        if _bench_busy:
                return
        _bench_busy = true
        auto_wave.stop()
        await director.run_bench(100, 8.0)
        auto_wave.start()
        _bench_busy = false


func _on_bench_finished(r: Dictionary) -> void:
        hud.set_status("ÖLÇÜM: %d düşman · avg %.2f ms · p95 %.2f ms · max %.2f ms" % [
                r["alive"], r["avg_ms"], r["p95_ms"], r["max_ms"]])


func _run_bench(total: int) -> void:
        if auto_wave != null:
                auto_wave.stop()
        var r := await director.run_bench(total, 8.0)
        # Faz 06: FX butcesi + HUD metrikleriyle zenginlestirilmis cikti
        var f06 := {
                "f05": r,
                "fx": fx_budget.stats(),
                "player": {
                        "level": player_state.level, "xp": player_state.xp,
                        "scrap": player_state.scrap, "kills": player_state.kills,
                        "wave": player_state.wave,
                },
        }
        print("F06_BENCH_JSON ", JSON.stringify(f06))
        print("F05_BENCH_DONE")
        get_tree().quit()


# -------------------------------------------------- ekran goruntusu modu
func _shot_prefix() -> String:
        var prefix := "/home/z/my-project/dustbound/tests/smoke/shots/arena"
        for arg in OS.get_cmdline_user_args():
                if arg.begins_with("--shot-prefix="):
                        prefix = arg.trim_prefix("--shot-prefix=")
        return prefix


func _run_shot_sequence() -> void:
        var prefix := _shot_prefix()
        await get_tree().create_timer(1.0).timeout
        # Kesin occlusion kaniti: y-sort surekli konumda da gecerlidir (global Y).
        # Hucere merkezleri yatayda en az 128 px ayrildigindan, varlik genisliklerinin
        # ustuste binmesi icin kuleye yakin surekli konumlar kullanilir.
        var pillar_pos := ground_layer.map_to_local(PILLAR_CELL)
        await _walk_and_shoot(pillar_pos + Vector2(0, 58), prefix + "_front.png")
        await _walk_and_shoot(pillar_pos + Vector2(0, -58), prefix + "_behind.png")
        await _walk_and_shoot(ground_layer.map_to_local(CRYSTAL_CELL + Vector2i(1, 1)),
                        prefix + "_crystal.png")
        # Faz 05 savas kaniti: dalga uret, eylem anlarini yakala
        director.spawn_wave(6)
        await get_tree().create_timer(1.8).timeout
        await _capture(prefix + "_f05_combat.png")
        await get_tree().create_timer(1.6).timeout
        await _capture(prefix + "_f05_combat_late.png")
        # ---------------- Faz 06 kanitlari ----------------
        # 1) HUD + joystick + yetenek cubugu + efektler (oyun ici)
        player.try_burst()
        await get_tree().create_timer(0.35).timeout
        await _capture(prefix + "_f06_hud.png")
        # 2) yetenek patlamasi karesi (mermi izleri + carpma parlaklari)
        player.try_dash()
        await get_tree().create_timer(0.22).timeout
        await _capture(prefix + "_f06_fx_burst.png")
        # 3) seviye atlama secimi: oyun duraklatilir, panel acilir
        player_state.gain_xp(player_state.xp_to_next() - player_state.xp)
        await get_tree().create_timer(0.5).timeout
        await _capture(prefix + "_f06_levelup.png")
        # secimi tamamla (ilk kart) ve devam et
        if game_hud.is_level_up_open():
                var cards := game_hud._levelup_cards.get_children()
                if cards.size() > 0:
                        _on_upgrade_chosen(str(cards[0].get_meta("upgrade_id")))
        await get_tree().create_timer(0.4).timeout
        # 4) dev paneli acik kare
        hud.set_dev_visible(true)
        await get_tree().create_timer(0.35).timeout
        await _capture(prefix + "_f06_dev.png")
        hud.set_dev_visible(false)
        print("SHOT_SEQUENCE_DONE")
        get_tree().quit()


func _walk_and_shoot(world_target: Vector2, path: String) -> void:
        player.move_to(world_target)
        marker.position = world_target
        while player.moving:
                await get_tree().process_frame
        await get_tree().create_timer(0.7).timeout  # kamera yakinsamasi
        await _capture(path)


func _capture(path: String) -> void:
        await RenderingServer.frame_post_draw
        var img := get_viewport().get_texture().get_image()
        if img == null or img.is_empty():
                print("SHOT_FAILED bos goruntu: ", path)
                return
        img.save_png(path)
        print("SHOT_SAVED ", path)
