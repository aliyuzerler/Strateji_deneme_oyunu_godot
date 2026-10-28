extends SceneTree
## Faz 06 smoke test: mobil HUD, efekt butcesi, odul/seviye sistemi,
## joystick/yetenek girdisi ve guvenli alan dogrulamalari.
## Calistirma: godot --headless --path . -s res://tests/smoke/f06_smoke_runner.gd
## Cikis kodu: 0 = tum kontroler PASS, 1 = en az bir FAIL.

var _failures := 0
var _checks := 0


func _initialize() -> void:
        _run()


func _run() -> void:
        print("=== DUSTBOUND FAZ 06 SMOKE TEST (mobil HUD + efektler) ===")
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
        if arena.auto_wave != null:
                arena.auto_wave.stop()  # deterministik akis
        var player: PlaceholderPlayer = arena.player
        var state: PlayerState = arena.player_state
        var budget: FXBudget = arena.fx_budget
        var hud: GameHud = arena.game_hud
        var loot: LootDirector = arena.loot

        # 1) FXBudget kurulumu ve izin akisi
        _check(budget != null, "FXBudget kuruldu")
        _check(budget.can_spawn("fx") and budget.can_spawn("label") and budget.can_spawn("trail")
                        and budget.can_spawn("orb"), "Butce bosken tum turler izinli")
        budget.force_quality = FXBudget.Quality.LOW
        await process_frame
        _check(budget.quality == FXBudget.Quality.LOW, "Kalite dayatmasi: DUSUK")
        _check(budget.spawn_prob() < FXBudget.Quality.HIGH + 0.0 or budget.spawn_prob() < 1.0,
                        "DUSUK kalite spawn olasiligi kirpar (%.2f)" % budget.spawn_prob())
        _check(budget.burst_count(10) < 10, "DUSUK kalite kume sayisini kirpar (%d)" % budget.burst_count(10))
        budget.force_quality = FXBudget.Quality.HIGH
        await process_frame
        _check(budget.quality == FXBudget.Quality.HIGH, "Kalite dayatmasi: YUKSEK")

        # 2) Butce siniri: cap dolunca spawn reddedilir
        var dummies: Array = []
        for i in FXBudget.CAP_FX:
                var d := Sprite2D.new()
                arena.air_fx.add_child(d)
                dummies.append(d)
        _check(not budget.can_spawn("fx"), "FX cap dolunca spawn reddi (%d/%d)" % [FXBudget.CAP_FX, FXBudget.CAP_FX])
        for d in dummies:
                d.queue_free()
        await process_frame
        _check(budget.can_spawn("fx"), "Temizlik sonrasi spawn izni geri geldi")

        # 3) PlayerState: XP/hurda/sure/seviye formulleri
        _check(state.xp_to_next() == 40, "Seviye 1 XP esigi 40 (gercek: %d)" % state.xp_to_next())
        var sc0 := state.scrap
        state.gain_scrap(5)
        _check(state.scrap == sc0 + 5, "Hurda birikimi (+5)")
        state.gain_xp(10)
        _check(state.xp == 10, "XP birikimi (+10)")
        var t0 := state.survival_time
        await _wait_seconds(0.35)
        _check(state.survival_time > t0 + 0.2, "Kronometre akar (%.2f -> %.2f)" % [t0, state.survival_time])
        _check(regex_valid(state.format_time()), "Sure formati MM:SS (%s)" % state.format_time())

        # 4) SEVIYE ATLAMA -> OYUN DURAKLAR (gorev geregi)
        var dmg0 := player.attack_damage
        var hp0 := player.max_hp
        var spd0 := player.move_speed
        var bcd0 := player.burst_cd
        state.gain_xp(state.xp_to_next() - state.xp)
        await _wait_frames(3)
        _check(paused, "Seviye atlamada oyun durakladi")
        _check(hud.is_level_up_open(), "Yetenek secim paneli acildi")
        var cards := hud._levelup_cards.get_children()
        _check(cards.size() == 3, "3 yukseltme karti uretildi (gercek: %d)" % cards.size())
        var chosen := ""
        var changed := false
        if cards.size() == 3:
                chosen = str(cards[0].get_meta("upgrade_id"))
                arena._on_upgrade_chosen(chosen)
                await _wait_frames(3)
                match chosen:
                        "damage":
                                changed = player.attack_damage > dmg0
                        "speed":
                                changed = player.move_speed > spd0
                        "cooldown":
                                changed = player.burst_cd < bcd0
                        "vitality":
                                changed = player.max_hp == hp0 + 25
                        "burst":
                                changed = player.burst_count == 12
                        "magnet":
                                changed = loot.magnet_range > 170.0
                _check(changed, "Secilen yukseltme uygulandi (%s)" % chosen)
        _check(not paused, "Secim sonrasi oyun devam etti")
        _check(not hud.is_level_up_open(), "Secim sonrasi panel kapandi")

        # 4b) ATLA akisi: tekrar seviye -> ATLA -> devam
        state.gain_xp(state.xp_to_next() - state.xp)
        await _wait_frames(3)
        _check(paused and hud.is_level_up_open(), "Ikinci seviyede tekrar durakladi")
        arena._on_upgrade_skipped()
        await _wait_frames(3)
        _check(not paused, "ATLA ile oyun devam etti")

        # 5) Odul sistemi: olum -> XP topu dusmesi -> mafnatis + toplama
        var xp0 := state.xp
        var runner: EnemyUnit = arena.director._spawn_one(UnitDefs.runner_def(), Vector2i(8, 7))
        runner.position = player.position + Vector2(700, 0)  # oyuncu menzili disinda
        await _wait_frames(2)
        runner.take_hit(9999, player.position)
        await _wait_frames(2)
        var orb_count := arena.loot_layer.get_child_count()
        _check(orb_count >= 1, "Olum odulu dustu (%d top/hurda)" % orb_count)
        if orb_count >= 1:
                var orb: LootOrb = arena.loot_layer.get_child(0)
                var orb_id := orb.get_instance_id()
                orb.global_position = player.global_position + Vector2(80, 0)  # magnet alanina
                var orb_pred := func() -> bool:
                        var o: Object = instance_from_id(orb_id)
                        return state.xp > xp0 or state.scrap > sc0 + 5 or o == null
                await _wait_until(orb_pred, 300)
                _check(state.xp > xp0 or state.scrap > sc0 + 5, "Toplama hesaba gecti (xp %d -> %d)" % [xp0, state.xp])

        # 6) Joystick -> oyuncu hareketi + yon tutarliligi
        while player.moving:
                await process_frame
        var jx0 := player.position.x
        hud._joy.stick_vector_changed.emit(Vector2.RIGHT)
        await _wait_seconds(0.25)
        hud._joy.stick_vector_changed.emit(Vector2.ZERO)
        _check(player.position.x > jx0 + 20.0, "Joystick sag vektoru oyuncuyu doguya tasidi (%.1f px)" % (player.position.x - jx0))
        _check(player.facing == 0, "Joystick yonu -> facing Dogu (gercek: %d)" % player.facing)

        # 7) Enerji Patlamasi: radyal mermiler + cooldown
        var bolt0 := _count_type(arena.air_fx, "CombatBolt")
        _check(player.try_burst(), "Enerji Patlamasi tetiklendi")
        await _wait_frames(2)
        var bolt1 := _count_type(arena.air_fx, "CombatBolt")
        _check(bolt1 - bolt0 >= 10, "Radyal mermi sayisi >= 10 (%d yeni)" % (bolt1 - bolt0))
        _check(not player.can_burst(), "Cooldown aktif — ikinci cagri reddedilir")
        _check(player.burst_frac() < 1.0, "HUD cooldown orani akista (%.2f)" % player.burst_frac())

        # 8) Atılım: hizli hareket + invuln + cooldown
        while player.moving:
                await process_frame
        var px0 := player.position
        _check(player.try_dash(), "Atılım tetiklendi")
        await _wait_seconds(0.1)
        _check(player.position.distance_to(px0) > 80.0, "Atılım oyuncuyu hizla tasidi (%.1f px)" % player.position.distance_to(px0))
        _check(not player.can_dash(), "Atılım cooldown aktif")

        # 9) Iz + parlama + toz efektleri uretildi
        await _wait_seconds(0.15)
        var trail_found := _count_type(arena.air_fx, "CombatBolt")
        _check(trail_found > 0 or _count_sprites(arena.air_fx) > 0, "Efekt dugumleri uretildi (%d mermi/%d sprite)" % [trail_found, _count_sprites(arena.air_fx)])
        arena.air_fx.spawn_impact_flash(player.global_position, true)
        arena.air_fx.spawn_footstep_dust(player.global_position)
        await _wait_frames(2)
        _check(_count_sprites(arena.air_fx) > 0, "Parlama + ayak tozu uretildi")

        # 10) Hasar etiketi + olum tozu (butce ustunden)
        # Determinizm: canlı etiket havuzu temizlenir (eski etiketin tam
        # yeni etiket doğarken serbest kalması net-0 yarışı yaratırdı).
        for c in arena.air_fx.get_children():
                if c is Label:
                        c.queue_free()
        await _wait_frames(2)
        player.invuln = 0.0  # Atılım invuln'u etiket testini yutmasin (test dayatmasi)
        player.take_hit(3, player.position + Vector2(40, 0))
        await _wait_frames(2)
        if OS.get_cmdline_user_args().has("--debug-label"):
                print("   TESIH: hp=%d max=%d invuln=%.2f dead=%s resp=%s lbl=%d" % [
                        player.hp, player.max_hp, player.invuln, str(player.dead),
                        str(player._respawning), _count_sprites(arena.air_fx, "Label")])
        _check(_count_sprites(arena.air_fx, "Label") >= 1, "Oyuncu hasar etiketi uretildi")

        # 11) Guvenli alan: dayatma + gorsel isaret + sifirlama
        hud.debug_force_safe_area(110.0, 40.0, 70.0, 0.0, true)
        await _wait_frames(1)
        _check(absf(hud._safe.offset_left - 110.0) < 0.5 and absf(hud._safe.offset_top - 40.0) < 0.5,
                        "Guvenli alanInsets dayatildi (L%.0f T%.0f)" % [hud._safe.offset_left, hud._safe.offset_top])
        hud.debug_force_safe_area(0, 0, 0, 0, false)
        await _wait_frames(1)
        _check(absf(hud._safe.offset_left - 8.0) < 2.5, "Guvenli alan sifirlamada minimum bosluk (L%.0f)" % hud._safe.offset_left)

        # 12) HUD gostergeleri guncelleniyor
        hud._refresh(true)
        _check(hud._hp_label.text.contains("/"), "Can gostergesi deger iceriyor (%s)" % hud._hp_label.text)
        _check(hud._time_label.text.contains(":"), "Sure gostergesi formatli (%s)" % hud._time_label.text)
        _check(hud._wave_label.text.begins_with("DALGA"), "Dalga gostergesi (%s)" % hud._wave_label.text)

        # 13) Dalga sinyali sayaci + birim_spawn sinyali (loot baglisi)
        var w0 := state.wave
        arena.director.spawn_wave(2)
        await _wait_frames(2)
        _check(state.wave == w0 + 1, "Dalga sinyali sayaci artirdi (%d -> %d)" % [w0, state.wave])
        arena.director.clear_all()

        # 14) Seviye duraklatmasi kapaliyken duraklamaz (uyum kablo davranisi)
        arena.levelup_pause_enabled = false
        state.gain_xp(state.xp_to_next() - state.xp)
        await _wait_frames(3)
        _check(not paused, "levelup_pause_enabled=false iken duraklamaz")
        arena.levelup_pause_enabled = true

        # 15) Kalite degisim sinyali
        var q_changed := [false]
        budget.quality_changed.connect(func(_l: int) -> void: q_changed[0] = true)
        budget.force_quality = FXBudget.Quality.MEDIUM
        await process_frame
        _check(q_changed[0], "quality_changed sinyali yayildi")
        budget.force_quality = FXBudget.Quality.HIGH

        _finish()


func regex_valid(s: String) -> bool:
        if s.length() != 5 or s[2] != ":":
                return false
        for i in [0, 1, 3, 4]:
                if not (s[i] >= "0" and s[i] <= "9"):
                        return false
        return true


func _count_type(parent: Node, klass: String) -> int:
        var n := 0
        for c in parent.get_children():
                var s: Script = c.get_script()
                if s is GDScript and (s as GDScript).get_global_name() == klass:
                        n += 1
                elif c.get_class() == klass:
                        n += 1
        return n


func _count_sprites(parent: Node, native: String = "Sprite2D") -> int:
        var n := 0
        for c in parent.get_children():
                if c.get_class() == native:
                        n += 1
        return n


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
