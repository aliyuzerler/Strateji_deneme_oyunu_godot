extends SceneTree
## Faz 05 smoke test: savas varliklari dogrulamalari.
## Calistirma: godot --headless --path . -s res://tests/smoke/f05_smoke_runner.gd
## Kapsam: yonlu animasyon, otomatik hedefleme, hasar/olum, dusman tip
## davranislari, registry, knockback, respawn, 100 dusman spawn maliyeti.
## Cikis kodu: 0 = tum kontroler PASS, 1 = en az bir FAIL.

var _failures := 0
var _checks := 0


func _initialize() -> void:
        _run()


func _run() -> void:
        print("=== DUSTBOUND FAZ 05 SMOKE TEST (savas varliklari) ===")
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
        # ---- Faz 06 uyum kablosu (kontroller degismedi) ----
        # Yeni oduul sistemi dusman oldumlerinden XP toplar; seviye duraklatmasi
        # ve otomatik dalga bu ESKI akista deterministigi bozar -> devre disi.
        # Seviye-duraklatma davranisi f06_smoke_runner.gd icinde acik test edilir.
        arena.levelup_pause_enabled = false
        if arena.auto_wave != null:
                arena.auto_wave.stop()
        var player: PlaceholderPlayer = arena.player
        var registry: EnemyRegistry = arena.registry
        var director: EnemyDirector = arena.director

        # 1) Sheet kurulumu: 5 animasyon, walk 4 kare, hucre boyutu dogru
        _check(player.anim_lib != null, "Oyuncu sheet kutuphanesi kuruldu")
        _check(player.anim_lib.frame_count("walk") == 4, "Walk 4 kare")
        _check(player.anim_lib.frame_count("death") == 3 and player.anim_lib.frame_count("hurt") == 1,
                        "Death 3 / hurt 1 kare")
        _check(player.anim_lib.cell == Vector2i(400, 460), "Oyuncu hucre 400x460 (2x)")

        # 2) Yon indeks eslemesi (E, S, W, N, SE)
        _check(SpriteAnimLib.dir_index_from_angle(0.0) == 0, "Acis 0 -> Dogu (0)")
        _check(SpriteAnimLib.dir_index_from_angle(PI / 2.0) == 2, "Acis PI/2 -> Guney (2)")
        _check(SpriteAnimLib.dir_index_from_angle(PI) == 4, "Acis PI -> Bati (4)")
        _check(SpriteAnimLib.dir_index_from_angle(-PI / 2.0) == 6, "Acis -PI/2 -> Kuzey (6)")
        _check(SpriteAnimLib.dir_index_from_angle(PI / 8.0) == 1, "Acis PI/8 -> GD (1)")

        # 3) Yonlu yuruyus: kuzeye hareket -> facing 6 + walk animasyonu
        arena.request_move_to_cell(Vector2i(5, 5))
        await _wait_frames(8)
        _check(player.facing == 6, "Kuzeye yuruyuste facing = 6 (gercek: %d)" % player.facing)
        _check(player.anim_state() == "walk", "Yururken walk animasyonu (gercek: %s)" % player.anim_state())
        await _wait_until(func() -> bool: return not player.moving, 1200)

        # 4) Otomatik hedefleme: runner 300 px doguda
        var runner: EnemyUnit = director._spawn_one(UnitDefs.runner_def(), Vector2i(8, 7))
        runner.position = player.position + Vector2(300, 0)
        await _wait_until(func() -> bool: return player.current_target == runner, 600)
        _check(player.current_target == runner, "Otomatik hedef kilidi (en yakin dusman)")

        # 5) Atis ve isabet: cooldown dolunca mermi urer, runner hasar alir
        var hp0: int = runner.hp
        await _wait_seconds(1.2)
        _check(runner.hp < hp0 or runner.dead, "Oyuncu mermisi dusmana isabet etti (hp %d -> %d)" % [hp0, runner.hp])

        # 6) take_hit hasar matematiği
        if not runner.dead:
                var hp1: int = runner.hp
                runner.take_hit(10, player.position)
                _check(runner.hp == hp1 - 10, "take_hit 10 hasar uygular (%d -> %d)" % [hp1, runner.hp])

        # 7) Olum akisi: animasyon + registry cikisi + temizlik
        var before_count: int = registry.count()
        runner.take_hit(9999, player.position)
        _check(runner.dead, "Olumcu hasar -> dead")
        _check(runner.anim_state() == "death", "Olum animasyonu calisiyor")
        _check(registry.count() == before_count - 1, "Olum -> registry'den cikarildi")
        await _wait_seconds(1.4)
        _check(not is_instance_valid(runner), "Olum sonrasi temizlik (queue_free)")

        # 8) Dusman tipi farklilastirmasi (hiz/dayaniklilik/davranis)
        var rdef := UnitDefs.runner_def()
        var bdef := UnitDefs.brute_def()
        var sdef := UnitDefs.spitter_def()
        _check(float(rdef["speed"]) > float(sdef["speed"]) and float(sdef["speed"]) > float(bdef["speed"]),
                        "Hiz siralamasi: runner > spitter > brute")
        _check(int(bdef["max_hp"]) > int(sdef["max_hp"]) and int(sdef["max_hp"]) > int(rdef["max_hp"]),
                        "Dayaniklilik siralamasi: brute > spitter > runner")
        _check(rdef["behavior"] == "melee" and bdef["behavior"] == "slam" and sdef["behavior"] == "ranged",
                        "Davranis tipleri: melee / slam / ranged")

        # 9) Spitter guvenli bant davranisi: cok yakin -> geri cekilir
        var spitter: EnemyUnit = director._spawn_one(UnitDefs.spitter_def(), Vector2i(6, 7))
        spitter.position = player.position + Vector2(200, 0)
        await _wait_frames(4)
        var d0: float = spitter.global_position.distance_to(player.global_position)
        await _wait_seconds(0.8)
        var d1: float = spitter.global_position.distance_to(player.global_position)
        _check(d1 > d0 + 24.0, "Spitter yakin mesafeden kacar (%.0f -> %.0f px)" % [d0, d1])

        # 10) Brute telegraf + alan vurusu
        var brute: EnemyUnit = director._spawn_one(UnitDefs.brute_def(), Vector2i(6, 8))
        brute.position = player.position + Vector2(110, 0)
        await _wait_seconds(0.3)
        var telegraph_ok := brute.ai_state() == EnemyUnit.State.WINDUP \
                        or (arena.ground_fx != null and arena.ground_fx.get_child_count() > 0)
        _check(telegraph_ok, "Brute windup + telegraf halkasi")
        var php0: int = player.hp
        await _wait_seconds(1.3)
        _check(player.hp < php0, "Brute slam'i oyuncuya hasar verdi (%d -> %d)" % [php0, player.hp])
        brute.take_hit(9999, player.position)

        # 11) Hasar etiketi uretimi
        var runner2: EnemyUnit = director._spawn_one(UnitDefs.runner_def(), Vector2i(6, 7))
        runner2.position = player.position + Vector2(400, 0)
        runner2.take_hit(5, player.position)
        var label_found := false
        for c in arena.air_fx.get_children():
                if c is Label:
                        label_found = true
                        break
        _check(label_found, "Hasar etiketi uretildi")
        registry.unregister(runner2)
        runner2.queue_free()

        # 12) Registry nearest dogrulugu (3 aday)
        var a: EnemyUnit = director._spawn_one(UnitDefs.runner_def(), Vector2i(7, 7))
        var b: EnemyUnit = director._spawn_one(UnitDefs.runner_def(), Vector2i(2, 7))
        var c: EnemyUnit = director._spawn_one(UnitDefs.runner_def(), Vector2i(5, 4))
        a.position = player.position + Vector2(180, 0)
        b.position = player.position + Vector2(-600, 0)
        c.position = player.position + Vector2(0, 700)
        var expect: Node2D = a
        var best := INF
        for u: Node2D in [a, b, c]:
                var dd: float = player.position.distance_squared_to(u.global_position)
                if dd < best:
                        best = dd
                        expect = u
        var got: Node2D = registry.nearest(player.position, 5000.0)
        _check(got == expect, "nearest() en yakin adayi dondurur")
        a.take_hit(9999, player.position)
        b.take_hit(9999, player.position)
        c.take_hit(9999, player.position)
        await _wait_seconds(0.2)

        # 13) Geri itme (knockback)
        var runner3: EnemyUnit = director._spawn_one(UnitDefs.runner_def(), Vector2i(6, 7))
        runner3.position = player.position + Vector2(250, 0)
        await _wait_frames(2)
        var p0: Vector2 = runner3.global_position
        runner3.take_hit(5, player.position)
        await _wait_seconds(0.25)
        var moved: float = runner3.global_position.distance_to(p0)
        _check(moved > 6.0, "Geri itme pozisyonu kaydirir (%.1f px)" % moved)
        runner3.take_hit(9999, player.position)

        # 14) Y-sort ve isik butcesi korundu
        _check(arena.entities_layer.y_sort_enabled, "EntitiesLayer y_sort_enabled (korundu)")
        var lights := root.find_children("*", "Light2D", true, false)
        _check(lights.size() <= 4, "Isik butcesi <= 4 (gercek: %d)" % lights.size())

        # 15) 100 dusman spawn + kare maliyeti (gevsek esik; rapor degeri)
        director.clear_all()
        await _wait_seconds(1.3)
        _check(registry.count() == 0, "Temizlik: onceden kalanlar bosaltildi (%d)" % registry.count())
        var spawned: Array = director.spawn_mixed(100)
        _check(spawned.size() == 100, "100 dusman uretildi (uretilen: %d)" % spawned.size())
        _check(registry.count() >= 95, "Registry dolu (cetesme: %d, catisma kayiplari normal)" % registry.count())
        await _wait_seconds(0.5)
        var acc := 0.0
        var n := 120
        var t0 := Time.get_ticks_usec()
        for i in n:
                await process_frame
        acc = (Time.get_ticks_usec() - t0) / 1000.0
        var avg_ms := acc / float(n)
        _check(avg_ms < 50.0, "100 dusman avg kare maliyeti < 50 ms (gercek: %.2f ms — rapor degeri)" % avg_ms)
        print("   BENCH_SNAPSHOT avg=%.2f ms  alive=%d  nodes=%d" % [
                avg_ms, registry.count(),
                int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))])
        director.clear_all()
        await _wait_seconds(1.3)
        _check(registry.count() == 0, "Temizlik: registry bosaltilir (%d)" % registry.count())

        # 16) Oyuncu olumu ve respawn
        var php: int = player.max_hp
        player.take_hit(99999, player.position)
        _check(player.dead, "Olumcu hasar -> oyuncu dustu")
        await _wait_seconds(2.4)
        _check(not player.dead and player.hp == php, "Respawn: can tazelendi, yerinde (%.0f, %.0f)" % [
                player.position.x, player.position.y])

        _finish()


func _wait_until(predicate: Callable, max_frames: int) -> void:
        for i in max_frames:
                if predicate.call():
                        return
                await process_frame
        print("   UYARI: beklenen kosul %d karede gerceklesmedi" % max_frames)


func _wait_seconds(s: float) -> void:
        await create_timer(s).timeout


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
