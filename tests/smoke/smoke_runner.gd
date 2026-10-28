extends SceneTree
## Smoke test (TESTING B.5): izometrik kanit sahnesi dogrulamalari.
## Calistirma: godot --headless --path . -s res://tests/smoke/smoke_runner.gd
## Cikis kodu: 0 = tum kontroler PASS, 1 = en az bir FAIL.

var _failures := 0
var _checks := 0


func _initialize() -> void:
        _run()


func _run() -> void:
        print("=== DUSTBOUND SMOKE TEST (kanit sahnesi) ===")
        await process_frame
        var packed: PackedScene = load("res://scenes/game/test_arena.tscn")
        if packed == null:
                _fail("arena sahnesi yuklenemedi")
                _finish()
                return
        var arena: TestArena = packed.instantiate()
        root.add_child(arena)
        await process_frame
        await process_frame

        # 1) IsoMath gidi-donus tutarliligi
        var roundtrip_ok := true
        for x in range(-8, 9):
                for y in range(-8, 9):
                        var cell := Vector2i(x, y)
                        if IsoMath.world_to_map(IsoMath.map_to_world(cell)) != cell:
                                roundtrip_ok = false
        _check(roundtrip_ok, "IsoMath gidiş-dönüş (17x17 hücre)")

        # 2) IsoMath <-> TileMapLayer merkez uyumu
        var max_diff := 0.0
        var sample_cells: Array[Vector2i] = [
                Vector2i.ZERO, Vector2i(11, 0), Vector2i(0, 11), Vector2i(11, 11),
                Vector2i(7, 4), Vector2i(5, 7),
        ]
        for c in sample_cells:
                var diff: Vector2 = IsoMath.map_to_world(c) - arena.ground_layer.map_to_local(c)
                max_diff = maxf(max_diff, diff.length())
        _check(max_diff < 0.6, "IsoMath <-> TileMapLayer merkez uyumu (maks %.3f px)" % max_diff)

        # 2b) rastgele nokta hücre seçim uyumu
        var rng := RandomNumberGenerator.new()
        rng.seed = 42
        var pick_ok := true
        for i in 40:
                var p := Vector2(rng.randf_range(-1400, 1400), rng.randf_range(-100, 1300))
                if IsoMath.world_to_map(p) != arena.ground_layer.local_to_map(p):
                        pick_ok = false
                        print("   uyusmazlik: p=", p,
                                        " iso=", IsoMath.world_to_map(p),
                                        " tilemap=", arena.ground_layer.local_to_map(p))
        _check(pick_ok, "IsoMath <-> TileMapLayer nokta seçimi (40 rastgele nokta)")

        # 3) Zemin dolulugu
        var used := arena.ground_layer.get_used_cells().size()
        _check(used == 144, "Zemin 144 hücre dolu (gerçek: %d)" % used)

        # 4) Y-sort yapilandirmasi
        _check(arena.entities_layer.y_sort_enabled, "EntitiesLayer y_sort_enabled")
        _check(arena.structure_layer.y_sort_enabled, "StructureLayer y_sort_enabled")

        # 5) Pivot: ayak = dugum origin (ASSET_PIPELINE B.4)
        # Doku pikseli (w/2, h-8) node-lokal uzayde offset ile origin'e tasinir:
        # body.offset + ayak_pikseli == (0, 0) olmali; to_global ile sahnede dogrulanir.
        var body: Sprite2D = arena.player.get_node("Body")
        var tex_size := body.texture.get_size()
        var feet_tex := Vector2(tex_size.x * 0.5, tex_size.y - 8.0)
        var feet_node_local: Vector2 = body.offset + feet_tex
        var feet_delta: float = body.to_global(feet_node_local).distance_to(arena.player.global_position)
        _check(feet_delta < 0.5, "Oyuncu pivotu ayak-zemin temasında (%.3f px sapma)" % feet_delta)

        # 6) 2x olcek kurali (ASSET_PIPELINE B.3)
        _check(body.scale.is_equal_approx(Vector2(0.5, 0.5)), "Karakter 2x doku 0.5 scale ile çiziliyor")

        # 7) Hareket emri: hedef hucreye ulasim
        var target_cell := Vector2i(7, 5)
        arena.request_move_to_cell(target_cell)
        await _wait_until(func() -> bool: return not arena.player.moving, 1200)
        var move_dist: float = (arena.player.position - arena.ground_layer.map_to_local(target_cell)).length()
        _check(move_dist < 2.0, "Hareket emri hedef hücreye ulaşır (%.3f px sapma)" % move_dist)

        # 8) Dokunma simülasyonu (viewport girdi boru hattı üzerinden)
        var tap_cell := Vector2i(5, 6)
        var tap_world: Vector2 = arena.ground_layer.map_to_local(tap_cell)
        var screen: Vector2 = root.get_canvas_transform() * tap_world
        var press := InputEventScreenTouch.new()
        press.index = 0
        press.pressed = true
        press.position = screen
        root.push_input(press, true)  # in_local_coords: cihaz teslim uzayi (viewport-lokal)
        await process_frame
        var release := InputEventScreenTouch.new()
        release.index = 0
        release.pressed = false
        release.position = screen
        root.push_input(release, true)
        await process_frame
        await process_frame
        _check(arena.player.moving, "Dokunma tap -> hareket emri (viewport girdi dağıtımı)")
        await _wait_until(func() -> bool: return not arena.player.moving, 1200)

        # 9) Derinlik iliskisi: oyuncu kulenin kuzeyine gecince arkasinda olmali
        arena.request_move_to_cell(Vector2i(7, 3))
        await _wait_until(func() -> bool: return not arena.player.moving, 1200)
        var behind_ok := arena.player.position.y < arena.pillar.position.y
        _check(behind_ok, "Derinlik: oyuncu kule arkasına geçti (y-sort ön koşulu)")

        # 10) Kamera yakinsamasi
        await _wait_frames(100)
        var cam_dist: float = arena.camera_rig.global_position.distance_to(arena.player.global_position)
        _check(cam_dist < 10.0, "Kamera oyuncuyu takip ediyor (%.2f px sapma)" % cam_dist)

        # 11) Isik butcesi (ARCHITECTURE B.13): <= 4
        var lights := root.find_children("*", "Light2D", true, false)
        _check(lights.size() <= 4, "Işık bütçesi ≤ 4 (gerçek: %d)" % lights.size())

        # 12) Zoom sinirlari (ARCHITECTURE B.8)
        arena.camera_rig.multiply_zoom(10.0)
        _check(absf(arena.camera_rig.get_zoom() - 1.8) < 0.001, "Zoom üst sınırı 1.8")
        arena.camera_rig.multiply_zoom(0.01)
        _check(absf(arena.camera_rig.get_zoom() - 0.6) < 0.001, "Zoom alt sınırı 0.6")

        # 13) Duraklatma dongusu
        arena.toggle_pause()
        _check(paused, "Duraklatma çalışıyor")
        arena.toggle_pause()
        _check(not paused, "Devam etme çalışıyor")

        _finish()


func _wait_until(predicate: Callable, max_frames: int) -> void:
        for i in max_frames:
                if predicate.call():
                        return
                await process_frame
        print("   UYARI: beklenen koşul %d karede gerçekleşmedi" % max_frames)


func _wait_frames(n: int) -> void:
        for i in n:
                await process_frame


func _check(cond: bool, label: String) -> void:
        _checks += 1
        if cond:
                print("PASS: ", label)
        else:
                _failures += 1
                print("FAIL: ", label)


func _fail(label: String) -> void:
        _failures += 1
        print("FAIL: ", label)


func _finish() -> void:
        print("=== SONUÇ: %d/%d PASS ===" % [_checks - _failures, _checks])
        quit(1 if _failures > 0 else 0)
