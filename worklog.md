# Dustbound Projesi — Paylaşılan İş Kaydı (Worklog)

Bu dosya tüm ajanların ortak günlüğüdür. Append-only çalışır; mevcut kayıtlar asla silinmez. Format kuralları /home/z/my-project/dustbound/AGENTS.md B.7'dedir.

---
Task ID: 1
Agent: main
Task: Dustbound Godot 4 proje temeli — mevcut yapı incelemesi, kullanıcı kararları, beş yönetişim dokümanı (AGENTS, ARCHITECTURE, ART_DIRECTION, ASSET_PIPELINE, TESTING) ve minimal proje iskeleti.

Work Log:
- /home/z/my-project incelendi: proje boştu (yalnızca download/README.md); Dustbound sıfırdan kuruldu.
- Kullanıcı kararları alındı: tür = taktik strateji (üs/savunma yönetimi); doküman dili = Türkçe; renderer = Mobile (Vulkan); 2.5D üretim = karma (karakter/FX el çizimi + çevre/prop 3D ön render); test = unit + smoke + performans; mobil hedef = geniş uyumluluk (Android 8.0+/iOS 13+, 2 GB RAM taban); kapsam = dokümanlar + klasör iskeleti + project.godot (oyun kodu yok); tema = kum fırtınası distopyası.
- Godot güncel stabil sürüm web aramasıyla doğrulandı: 4.7.2 (4.7 feature sürümü 2026-06-18; bakım 4.7.1/4.7.2). Sürüm pini dokümanlara işlendi.
- Klasör iskeleti oluşturuldu: addons, assets (art/audio/fonts/licenses/raw), scenes (boot/menus/game/entities/ui/vfx), scripts (autoload/core/entities/systems/ui), resources/defs (units/buildings/levels/storms), shaders, tests (unit/integration/smoke); .gitkeep dosyaları ve assets/raw/.gdignore eklendi.
- project.godot yazıldı: 1280×720 canvas_items/expand, sensor_landscape, mobile renderer, ASTC sıkıştırma, touch emulation, grafit boot splash. .gitignore ve icon.svg (amber elmas + turkuaz çekirdek) eklendi.
- AGENTS.md yazıldı: proje kartı, Aşama 0 kapsamı, doküman haritası/öncelik, 10 altın kural, sürüm politikası, konvansiyon özeti, 7 adımlı ajan iş akışı, komut kılavuzu, Definition of Done, tuzaklar.
- ARCHITECTURE.md yazıldı: 8 satırlık teknik karar kaydı (K1–K8), 20 TPS deterministik sim çekirdeği + komut deseni, sahne akışı, autoload tablosu, izometrik TileMapLayer katman yapısı (2:1, 256×128 tile, 64 px yükseklik kademesi), kamera sistemi (pan/pinch 0.6–1.8), InputMap aksiyon tablosu, UnitDef/BuildingDef/LevelDef/StormDef veri modeli, ekonomi (enerji/hurda), kayıt sistemi, performans bütçe tablosu (entry/mid), platform notları, 3 açık karar noktası.
- ART_DIRECTION.md yazıldı: 4 stil sütunu, anti-hedefler (piksel art yasak), palet rampaları hex kodlu (KU/GR/TE/TK + nötrler), ekran oranı kuralları (kırmızı ≤ %5), ışık ve fırtına atmosfer şeması, şekil dili, birim tasarım standartları, tile tasarımı, UI/tipografi (Türkçe glif zorunlu), VFX limitleri, 4 referans oyun, görsel kabul listesi.
- ASSET_PIPELINE.md yazıldı: boru hattı şeması (raw → export → assets → doğrulama → kayıt → import), 2× üretim ölçeği tablosu, pivot tablosu (ayak/bina anchor/tile elmas merkezi/merkez), Blender izometrik kamera kurulumu (X=35.264°, Z=45°), isimlendirme grameri ve önek tablosu, dışa aktarım standartları, import ayar tablosu, lisans izin tablosu + 6 adımlı doğrulama + ASSET_LICENSES.csv şeması + merge kapısı, AI üretimi kuralları, kabul kontrol listesi.
- TESTING.md yazıldı: 5 katmanlı test stratejisi, GUT şablonu, deterministik senaryo testi tanımı, smoke listesi, komut kılavuzu, performans kapıları (G1–G4), 6 cihazlık test matrisi, manuel QA listesi, hata şiddet seviyeleri (determinizm ihlali min S2), sürüm öncesi checklist.
- Beş doküman, kullanıcının kolay indirmesi için /home/z/my-project/download/dustbound-docs/ altına da kopyalandı.

Stage Summary:
- Proje kökü: /home/z/my-project/dustbound — Aşama 0 tamamlandı (oyun kodu yok, kasıtlı).
- Sonraki tüm görevler bu beş dokümanı esas alacaktır; çatışmada doküman tek doğruluk kaynağıdır.
- Açık karar noktaları ARCHITECTURE B.16'da: RTwP vs sıra bazlı finali, fırtına görünürlük tekniği, otomatik savaş dengesi.
- Önerilen sonraki görevler: GUT 9.x kurulumu (MIT), boot.tscn + autoload iskeleti, ilk izometrik test haritası tile'larının üretimi.

---
Task ID: 2
Agent: main
Task: Godot 4 izometrik 2.5D kanıt sahnesi — Camera2D takip, izometrik zemin, oyuncu hareketi, Y-sort derinlik kanıtı, blob gölgeler, sınırlı dinamik ışık, Android dokunma girdisi; sahne çalıştırma, görsel hata incelemesi ve test raporu.

Work Log:
- Godot 4.7.2-stable Linux çalıştırıcısı GitHub releases'tan indirildi (/home/z/my-project/tools/godot), Mesa llvmpipe + Xvfb ile gerçek render doğrulandı.
- Geçici placeholder sanat üretildi (scripts/gen_placeholder_art.py): 3 kum tile varyantı (1× runtime + 2× raw), oyuncu 400×460, kaya/kule/kristal prop'ları, hedef işareti, blob gölge, ışık dokusu. Tümü ART_DIRECTION B.4 palet rampalarından, ASSET_PIPELINE B.3 (2×) ve B.4 (ayak pivotu) kurallarına uygun. İlk üretimde PIL alpha-yazma hatası (harmanlama yerine üzerine yazma) görsel incelemeyle yakalandı, ön-harmanlanmış dolgularla düzeltildi.
- scripts/core/iso_math.gd: Godot TILE_SHAPE_ISOMETRIC + TILE_LAYOUT_STACKED formülü debug probe ile 4.7.2'de keşfedildi (merkez = (128 + 256cx + 128(cy&1), 64+64cy)); IsoMath bu konvansiyona hizalandı.
- scripts/: arena_tileset_builder (kodla TileSet — geçici), iso_entity (2× doku 0.5 scale + ayak pivotu + blob gölge), placeholder_player (tap hedefine düz hat + bob animasyonu + klavye geliştirici girdisi), camera_rig (lerp takip, zoom 0.6–1.8 kelepçe, limitler), arena_input (tap→hareket, pinch→zoom, tekerlek, InputMap pause), arena_hud (FPS/draw call/VRAM/hücre izleyicisi), test_arena (orkestratör: zemin doldurma, varlık spawn, ışık, ekran görüntüsü modu).
- Sahne: scenes/game/test_arena.tscn (5 katman + CanvasModulate + DirectionalLight2D + HUD), placeholder_player.tscn, iso_prop.tscn, camera_rig.tscn. project.godot: main_scene + 5 InputMap aksiyonu + default_clear_color (GR-900).
- docs/ASSET_LICENSES.csv oluşturuldu (13 placeholder varlık kaydı; merge kapısı uyumu).
- Smoke test (tests/smoke/smoke_runner.gd, SceneTree script): 17 kontrol. Bulunan ve giderilen hatalar: (1) setup_texture ağaca girmeden @onready erişimi → add_child sıralaması düzeltildi; (2) headless 64×64 penceresinde push_input pencere-uzayı dönüşümü tap'ı harita dışına atıyordu → in_local_coords=true ile çözüldü; (3) pivot testinde to_global API yanlış kullanımı → offset tabanlı doğru onaylama. Sonuç: 17/17 PASS, exit 0.
- Görsel koşu (Xvfb + gl_compatibility geçici override): 3 ekran görüntüsü alındı. Bulunan ve giderilen görsel hatalar: (1) aşırı pozlama (güneş 0.5 → 0.32 + CanvasModulate 0.78/0.74/0.68), (2) harita dışı gri arka plan (default_clear_color GR-900), (3) kristal ışığı okunmuyordu (enerji 1.35, scale 2.1 + kadraj düzeltmesi), (4) hücre merkezleri arası 128 px yatay mesafe örtüşme kanıtını engelliyordu → sürekli konum kanıtına geçildi.
- Derinlik kanıtı: oyuncu kule güneyinde → oyuncu kule gövdesinin üstüne çiziliyor; kule kuzeyinde → oyuncu tamamen kule arkasında gizleniyor (yalnız turkuaz omuz yaması kırıntısı). Y-sort sürekli konumda da doğrulandı.
- AGENTS.md 0.1.1'e yükseltildi (Aşama 0.5 kaydı, main_scene notu). Kanıt görüntüleri download/dustbound-proof-shots/ altına kopyalandı.

Stage Summary:
- Sahne: /home/z/my-project/dustbound (main_scene = test_arena.tscn) — headless smoke 17/17 PASS; görsel koşu llvmpipe üzerinde 3 kanıt görüntüsü üretti.
- Performans gözlemi (yazılım GL, referans değer): FPS 23-27, draw call 114-116 (< 200 mid bütçesi), VRAM 25.4 MB, 2/4 ışık. Gerçek cihaz ölçümü ayrı görevdir (TESTING B.8 matrisi).
- Bilinen geçici durumlar: TileSet kodla kuruluyor (.tres'e taşınacak), hareket düz hat (MovementComponent/pathfinding gelecek), klavye girdisi geliştirici kolaylığı, kristal ışık yoğunluğu ince ayar açık konu.
- Geçici teşhis araçları: tests/smoke/debug_iso_probe.gd, debug_input_probe.gd, input_probe_node.gd (izometrik konvansiyon ve girdi boru hattı referansı).

---
Task ID: faz-05
Agent: main
Task: GitHub'a push (snapshot) + Faz 05: izometrik test sahnesini bozmadan oyuncu karakteri, üç düşman tipi ve otomatik hedefleme/saldırı sistemi; hasar/ölüm animasyonları; tip farkları (hız/dayanıklılık/davranış); geçici görsellerin açık işaretlenmesi; çoklu düşmanla performans ölçümü.

Work Log:
- Kullanıcı token'ı ile GitHub doğrulandı (login: aliyuzerler); repo aliyuzerler/Strateji_deneme_oyunu_godot boş bulundu. dustbound/ altında temiz nested git repo kuruldu (dış repo kökünde .env gibi hassas dosyalar olduğundan yalnız oyun klasörü push edildi). "Asama 0.5" snapshot commit'i main dalına pushlandı (rollback noktası).
- Faz 05 geçici sanatı üretildi (scripts/f05_art_lib.py + gen_f05_art.py, PIL, tohumlu): oyuncu + runner/brute/spitter için 8 yönlü sheet'ler (idle 2, walk 4, attack 3, hurt 1, death 3), 2× ölçek, ayak pivotu (w/2, h-8), her kareye TMP rozeti. Önizleme turunda tespit edilen sorunlar giderildi: ölüm karelerinde devrilme hücre taşması -> çökerek yığılma (rot+squash); runner gövdesi büyütüldü; brute kafası gövdeye oturtuldu; spitter kapüşonu birleştirildi.
- Çekirdek: sprite_anim_lib (8 yön sheet çıkarımı), unit_defs (kod tabanlı birim kartları), enemy_registry (128 px spatial hash: nearest/in_radius/all_units), combat_unit (can/hasar/flash/knockback/ölüm akışı + kod tabanlı Sprite2D doku değişimli animasyon motoru — smoke pivot/scale kontrollerini korur), hp_bar, combat_fx (hasar etiketi/püf/telegraf), projectile (düz hat mermi), enemy_unit (IDLE/CHASE/WINDUP; melee zigzag / slam telegraf+r140 / ranged 340-540 bant+strafe+kaçış), enemy_director (dalga 40/30/30 + bench), placeholder_player CombatUnit'e genişletildi (sınıf adı korunarak): otomatik hedefleme + turkuaz mermi + respawn (1.4 s, 2 s invuln) + oyuncuya özel turkuaz enerji ışığı.
- Arena entegrasyonu: test_arena.tscn'ye GroundFx (zemin halkaları) + AirFx (mermi/etiket) katmanları; HUD'a savaş satırı + DALGA +6 / ÖLÇÜM 100 butonları (>=64 px dokunma hedefi); hedef kilidi işareti mevcut target_marker dokusuyla; --shot akışına 2 savaş karesi, --bench=N arg'ı headless ölçüm+çıkış eklendi.
- Doğrulama: headless import OK; ORİJİNAL smoke 17/17 PASS (sıfır regresyon: pivot 0.000 px, 2x/0.5, IsoMath 0.000 px, ışık 3/4, y-sort, tap hattı); yeni f05 smoke 36/36 PASS.
- Bulunan ve giderilen hatalar: (1) tree_exiting çift bağlantı (register guard), (2) clear_all içinde in_radius(1e7) 24 milyar hücre taraması -> all_units() (smoke 240 s timeout sebebi), (3) oyuncu turkuaz ışığı + kristal + güneş = aşırı pozlama (Xvfb görsel koşuda tespit; energy 0.55/scale 1.15), (4) ölüm karesi hücre taşması (sanat), (5) sabit 256 px gölge küçük birimlerde büyük kalıyor -> oransal gölge ölçeği.
- Performans: headless --bench=100 (8 s, 1158 kare): baseline 6.70 ms -> 100 düşman 6.91 ms (net savaş maliyeti ~0.21 ms/kare, p95 8.43, maks 30.9 spawn karesi, 445 node). llvmpipe görsel koşu (6 düşman): FPS 16-21, draw call 123-131 (< 200 mid), VRAM 216-249 MB. Draw bütçe yorumu: mid ~50-60, entry ~25-30 eş zamanlı düşman; cihaz doğrulaması ÖLÇÜM 100 butonuyla yapılabilir.
- Kanıt görüntüleri (tests/smoke/shots/): arena_front/behind/crystal (regresyon, yeni görsellerle) + arena_f05_combat.png, arena_f05_combat_late.png (hedef kilidi, saldırı animasyonu turkuaz enerji topu, hasar etiketi "7" kırmızı, HP çubuğu 113/120, spitter Y-sort örtülmesi, oransal gölgeler). download/dustbound-proof-shots/ altına kopyalandı.
- Dokümantasyon: docs/FAZ05_RAPOR.md (kapsamlı test+performans raporu), ASSET_LICENSES.csv'ye 23 TMP kaydı (tpl-014..tpl-036), AGENTS.md 0.2.0 (Faz 05). "Faz 05" commit'i GitHub'a pushlandı.

Stage Summary:
- Sahne bozulmadı: 17/17 orijinal + 36/36 yeni = 53 kontrol PASS; savaş sistemi kanıt sahnesinin üzerine eklendi.
- 3 düşman tipi davranış farkları smoke ile kanıtlandı (hız/can/davranış sıralamaları + kaçış + telegraf).
- Açık konular: TMP sanat -> Faz 06 sanat paketi; UnitDefs -> def_*.tres hattı; cihaz üstü gerçek FPS ölçümü (TESTING B.8 matrisi); GUT geçişi ayrı görev.
- Token güvenlik notu: kullanıcı token'ı sohbette paylaşıldı; iş bitiminde iptal/rotasyon önerilir.

---
Task ID: faz-06
Agent: main
Task: Mobil HUD ve savaş efektleri — okunabilir can/XP/hurda/süre göstergeleri, sol alt joystick + sağ alt yetenekler, enerji mermisi/çarpma parlaması/toz/hasar/XP toplama efektleri, yetenek seçiminde duraklatma, güvenli alan + en-boy oranı desteği, efekt sınırlama + gerçek cihaz performans hazırlığı. Sonrasında ekran görüntüsü + detaylı README + GitHub push.

Work Log:
- Geçici UI/FX sanatı üretildi (scripts/gen_f06_art.py, 10 doku 2×): joystick taban/topuz, 3 ikon (patlama/atılım/onarım), XP topu, hurda, toz pufi, parlama çekirdeği, iz noktası. Statik UI dokularına TMP rozeti; çok tekrar eden FX dokularında rozet yerine lisans CSV + dev panel işaretlemesi (gürültü gerekçesiyle, raporda belgelendi).
- Yeni sistemler: fx_budget.gd (cap: 64 efekt/16 etiket/28 iz/40 top; FPS örneklemeli YÜKSEK/ORTA/DÜŞUK kalite, 3 sn dwell, tip-duyarlı sayım), player_state.gd (XP/seviye/hurda/kill/süre + leveled sinyali + 6 kartlık yükseltme havuzu), loot_orb.gd + loot_director.gd (düşme/mıknatıs/toplama; butçe dolunca değer birleştirme), virtual_joystick.gd (TouchJoystick — Godot 4.7'de yerel VirtualJoystick sınıf çakışması nedeniyle yeniden adlandırıldı; 320×320 hedef, çoklu dokunma güvenli), game_hud.gd (tam mobil HUD).
- Efektler: combat_fx.gd'ye ayak/ölüm tozu, additive çarpma parlaması, iz noktası, XP/hurda toplama halkaları + etiketler, seviye halkası eklendi; projectile.gd'ye 30 px aralıklı iz + isabet parlaması; combat_unit.gd'ye ölüm tozu; oyuncuya joystick girdisi, Enerji Patlaması (10 radyal mermi), Atılım (dash + 0.32 s invuln + toz izi), yükseltme uygulaması, ayak tozu.
- HUD: GameHud — sol üst can (amber, %30 altı kırmızı) + XP (turkuaz) + seviye; orta üst MM:SS + DALGA + toast; sağ üst hurda ikonu/sayı + DEV + II; sol alt joystick; sağ alt 2 yetenek düğmesi (96 px, radyal cooldown kapağı + saniye + hazır nabzı); merkezde seviye seçim paneli (3 kart + ATLA). Safe area: DisplayServer.get_display_safe_area → iç boşluk, size_changed'de yeniden; --safe-test ile çentik simülasyonu + görsel işaret. Eski teşhis HUD'u (arena_hud.gd) DEV paneline dönüştürüldü (varsayılan gizli; metot sözleşmeleri korundu).
- Arena: neden tabanlı duraklatma (manual/levelup), otomatik dalga Timer (35 s), unit_spawned/wave_spawned sinyalleri, magnet yükseltmesi bağlantısı, bench sırasında otomatik dalga dondurma, F06_BENCH_JSON çıktısı (FX + oyuncu istatistikleri), --fx-high/--safe-test argümanları, --shot akışına 4 yeni kare.
- Doğrulama: headless import temiz; smoke 17/17 + 36/36 + yeni f06 43/43 = 96/96 PASS (f05 smoke'a 3 satırlık uyum kablosu: levelup duraklatması + otomatik dalga eski akışta kaplanır; kontroller değişmedi — davranış f06'da açıkça test edilir).
- Bulunan ve giderilen hatalar: (1) VirtualJoystick ad çakışması → TouchJoystick, (2) bütçe sayımı çapraz bulaşma (izler etiket bütçesini yutuyordu) → tip-duyarlı sayım, (3) küçük FX dokularında mipmap'siz minifikasyon kareleri → 8 dokuda mipmaps/generate=true, (4) f05 smoke determinizmi → levelup_pause_enabled anahtarı, (5) SceneTree betiğinde get_tree() parse hatası, (6) lambda'da serbest nesne yakalama → instance_id.
- Performans: headless --bench=100: baseline 6.70 ms → 100 düşman 6.92 ms avg / 8.53 p95 (net savaş ≈ 0.21 ms/kare), 501 node. llvmpipe görsel koşu: draw call ≈ 160-170, VRAM ≈ 260 MB (referans). Gerçek cihaz protokolü docs/CIHAZ_OLCUM.md (M1-M6 adımları + G1-G4 kapıları + kalibrasyon kolları).
- Kanıt görüntüleri: arena_f06_hud / f06_fx_burst / f06_levelup / f06_dev + f06safe (çentik simülasyonu) + f06r195 (2532×1170) + f06r43 (1024×768) + f05 regresyon kareleri. download/dustbound-proof-shots/ altına kopyalandı.
- Dokümantasyon: README.md (yeni, detaylı — 14 bölüm), docs/FAZ06_RAPOR.md, docs/CIHAZ_OLCUM.md, ASSET_LICENSES.csv +10 kayıt (tpl-037..046), AGENTS.md 0.3.0 (Faz 06 kaydı).

Stage Summary:
- Görev gereksinimlerinin tamamı karşılandı: okunabilir göstergeler, sol alt hareket + sağ alt yetenek, 5 efekt ailesi, yetenek seçiminde duraklatma, safe area + 3 en-boy oranı kanıtı, efekt cap + otomatik kalite, gerçek cihaz ölçüm protokolü.
- Açık konular: gerçek cihaz ölçümü (TESTING B.8), TMP sanat → üretim paketi, def_*.tres hattı, ses geri bildirimi, GUT geçişi.
- Token güvenlik notu: push sonrası remote config'den temizlendi; kullanıcı token rotasyonu yapmalı.

---
Task ID: faz-06b-apk
Agent: main
Task: Test icin APK olusturma (telefonda calistirilacak debug imzali Android paketi).

Work Log:
- Ortam dogrulandi: Godot 4.7.2.stable binary mevcut (tools/godot/godot), JDK 21, git temiz; export templates + Android SDK yoktu.
- Godot 4.7.2 export templates (1.19 GB) indirildi; android_debug/release.apk XDG_DATA_HOME altina cikarildi (.xdg/data/godot/export_templates/4.7.2.stable/).
- Android SDK kuruldu: cmdline-tools + platform-tools + platforms;android-34 + build-tools;34.0.0 (aapt2/apksigner/zipalign) -> /home/z/my-project/android-sdk.
- Debug keystore uretildi (android-build/debug.keystore, androiddebugkey/android, RSA 2048, 10000 gun).
- export_presets.cfg olusturuldu: Android, arm64-v8a, immersive, sensor-landscape, package com.dustbound.game, vCode 1 / vName 0.1.0, raw/docs/tests haric.
- Editör ayarlarina SDK yollari yazildi (~/.config/godot/editor_settings-4.7.tres: java_sdk_path + android_sdk_path + debug keystore). Not: Godot 4.7 ANDROID_HOME/JAVA_HOME ortam degiskenlerini export'ta dikkate almiyor; Editor Settings sart.
- Headless import temiz (rc=0). Export basarili: download/Dustbound-0.1.0-debug.apk = 30.9 MB, apksigner ile imzali, aapt2 dogrulamasi OK (minSdk 24, targetSdk 36, arm64-v8a, label Dustbound). Not: export sonrasi adb daemon uyarisina ragmen paket gecerli.
- README.md'ye "APK ile Telefonda Test" bolumu eklendi (kurulum adimlari + kaynaktan derleme + cihaz olcum baglantisi), TOC guncellendi.

Stage Summary:
- APK teslim edildi: download/Dustbound-0.1.0-debug.apk (debug imzali, arm64-v8a, Android 7.0+).
- Acik konu: release imzali paket icin ayri keystore; x86/armeabi-v7a hedefleri kapatildi (test telefonu arm64).
