# Dustbound — ARCHITECTURE.md

> Teknik mimarinin tek doğruluk kaynağıdır. Hedef motor Godot 4.7 (GDScript, Mobile renderer) ve hedef platformlar Android 8.0+/iOS 13+'tır. Süreç kuralları AGENTS.md'de, görsel standartlar ART_DIRECTION.md'de, varlık teknikleri ASSET_PIPELINE.md'de, test kuralları TESTING.md'dedir.

- Sürüm: 0.1.0
- Son güncelleme: 2026-10-28

---

## 1. Genel Bakış

Dustbound; izometrik 2.5D bir harita üzerinde üs kurma, savunma düzeni hazırlama ve periyodik kum fırtınalarına karşı taktik kararlarla ilerleyen, mobil öncelikli bir strateji oyunud. Oyuncu sınırlı kaynakları (enerji, hurda) yöneterek yerleşimini fırtınaya hazırlar; fırtına dalgaları hem görünürlüğü hem de düşman baskısını şekillendirir.

Mimarinin üç temel gereksinimi vardır. Birincisi, mobil cihazlarda istikrarlı kare süresi: her teknik karar en düşük hedef cihaz üzerinden değerlendirilir. İkincisi, test edilebilir deterministik simülasyon: taktik oyunların dengesi, tekrar üretilebilir senaryo testleri olmadan korunamaz. Üçüncüsü, düşük içerik ekleme maliyeti: yeni birim, bina veya bölüm; kod değişikliği gerektirmeden, tanım dosyası ve varlık setiyle eklenebilmelidir.

## 2. Teknik Karar Kaydı

| # | Karar | Seçim | Gerekçe | Reddedilen Alternatif |
|---|---|---|---|---|
| K1 | Render motoru | Mobile (Vulkan) | Mobil hedefte dengeli; 2D ışık ve stencil yetenekleri | Compatibility: daha geniş cihaz desteği ama sınırlı 2D ışık; Forward+: mobilde fill-rate maliyeti |
| K2 | Programlama dili | GDScript (statik tipli) | Motorla tam entegrasyon, hızlı iterasyon | C#: derleme zinciri ve export karmaşıklığı; GDExtension: gereksiz karmaşıklık |
| K3 | Harita | `TileMapLayer` (izometrik, 2:1) | Yerleşik y-sort, batching ve koordinat yardımcıları | Özel grid düğümü: yüksek geliştirme maliyeti |
| K4 | Simülasyon | Sabit adımlı tick (20 TPS) + komut deseni | Determinizm, replay/test, duraklatma kolaylığı | Değişken delta `_process`: deterministik değil |
| K5 | Çözünürlük | 1280×720, `canvas_items`, `expand` | Ekran çeşitliliğinde ölçeklenir, fill-rate dostu | 1080p taban: bellek ve fill maliyeti |
| K6 | Yönlendirme | Yatay (`sensor_landscape`) | İzometrik strateji alan genişliğinden kazanır | Dikey: taktik görüş alanı daralır |
| K7 | Test çerçevesi | GUT 9.x (MIT) | GDScript ekosisteminin fiili standardı | Özel framework: gereksiz iş |
| K8 | Veri modeli | Custom Resource (`.tres`) | Editörde düzenlenebilir, git-diff dostu, tip güvenli | JSON: tip güvenliği ve editör desteği yok |

Bu tablo canlıdır: Aşama ilerledikçe yeni satırlar eklenir. Karar tersine çevrilecekse, eski satır silinmez; gerekçesiyle güncellenir.

## 3. Simülasyon Çekirdeği

### 3.1 Zaman Modeli

Simülasyon, saniyede 20 adım (tick, 50 ms) sabit hızda ilerler ve render döngüsünden bağımsızdır. Render 60 FPS'e kadar serbest çalışır; sim durumları arasında interpolasyon yapılarak akıcılık sağlanır. Duraklatma ve taktik yavaşlatma (`time_scale`) `AppManager` üzerinden simülasyona uygulanır; sahne ağacını veya görsel katmanı etkilemez.

Kesin kural: simülasyon mantığı `_process` içinde yazılmaz. Sim güncellemeleri, tick toplayıcı üzerinden `SimulationRoot`'a iletilir. Görsel davranışlar (animasyon, efekt) `_process`/`_physics_process` içinde serbesttir ancak sim sonucunu asla değiştiremez.

### 3.2 Komut Deseni

Kullanıcı girdisi doğrudan varlıkları değiştirmez; komut üretir. Akış: girdi → `OrderCommand` (ör. `MoveOrder`, `BuildOrder`, `AttackOrder`, `AbilityOrder`) → doğrulama (geçersizse red + UI geri bildirimi) → kuyruk → bir sonraki tick'te uygulanma → `EventBus` sinyali. Komutlar serializable'dır; bu sayede replay ve senaryo testleri mümkündür (TESTING B.4).

Doğrulama katmanı komutun kendi içinde bulunur: hareket emri hedef hücrenin geçilebilirliğini, inşa emri footprint uygunluğunu kontrol eder. Bu, komutların hem canlı oyunda hem testte aynı kurallardan geçmesini garanti eder.

### 3.3 Rastgelelik ve Determinizm

Simülasyon katmanındaki tüm rastgelelik, seed'i `LevelDef`'ten gelen tek bir `RandomNumberGenerator` üzerinden üretilir. Global `randi`/`randf` sim mantığında yasaktır. Görsel efektler (parçacık dağılımı vb.) serbesttir; sim sonucunu etkilemedikçe determinizmi bozmazlar. Kayan nokta: yalnızca lokalden oynanan tek cihaz oyunu hedeflendiğinden float determinizmi yeterlidir; ağ senkronu kapsam dışıdır (AGENTS B.11).

### 3.4 Zamanlayıcı Soyutlaması

`Scheduler` arayüzü iki somutlama planlar: `RealtimeScheduler` (canlı, taktik duraklatmalı) ve `TurnScheduler` (sıra bazlı modlar için). Bölüm 16'daki açık karar noktası kapatılana dek canlı oyun RealtimeScheduler ile geliştirilir; ancak sim çekirdeği zamanlayıcıya bağımsız tasarlanır, böylece geçiş maliyeti düşük kalır.

## 4. Sahne Akışı ve Organizasyonu

```
scenes/boot/boot.tscn
        └─> scenes/menus/main_menu.tscn
                └─> scenes/game/game_main.tscn
                        └─> scenes/ui/results_screen.tscn
```

- **Boot:** Motor başlatma sağlığı, autoload hazır kontrolü, yükleme göstergesi. En küçük ve en hızlı sahne; soğuk açılış bütçesinin (ARCHITECTURE B.13) sahibi.
- **MainMenu:** Kayıt listesi, ayarlar, bölüm seçimi. Oyun durumuna erişmez; yalnızca `AppManager` ve `SaveManager` üzerinden konuşur.
- **GameMain:** Dünya ve HUD'un kapsayıcısı. Alt sahnelere ayrılır: `world` (harita katmanları), `hud` (dokunma arayüzü), `overlay` (fırtına ekran efekti).
- **Results:** Kazanç/kayıp ekranı ve istatistikler; `results_screen.tscn` GameMain içinde katman olarak da açılabilir.

Kural: sahne geçişi yalnızca `SceneRouter` üzerinden yapılır; hiçbir sahne doğrudan `change_scene` çağırmaz. Böylece yükleme ekranı, geçiş animasyonu ve durum temizliği tek noktadan yönetilir.

## 5. Dizin Yapısı

```
dustbound/
├── project.godot            # Motor yapılandırması (bölüm 2 kararları)
├── AGENTS.md                # Süreç ve kurallar
├── ARCHITECTURE.md          # Bu doküman
├── ART_DIRECTION.md         # Görsel yön
├── ASSET_PIPELINE.md        # Varlık standartları ve lisans
├── TESTING.md               # Test stratejisi
├── addons/                  # Eklentiler (GUT)
├── assets/
│   ├── art/{characters, environment/{tiles,props}, ui, vfx, icons}
│   ├── audio/{music, sfx, ambience}
│   ├── fonts/               # Türkçe glif setli fontlar
│   ├── licenses/            # Lisans metni arşivi
│   └── raw/                 # Kaynak dosyalar (.gdignore'lu; motor görmez)
├── scenes/
│   ├── boot/  menus/  game/  entities/  ui/  vfx/
├── scripts/
│   ├── autoload/            # Bölüm 6'daki singleton'lar
│   ├── core/                # IsoMath, komutlar, scheduler, grid
│   ├── entities/            # BaseEntity, komponentler
│   ├── systems/             # StormSystem, economy, build validation
│   └── ui/                  # HUD ve menü betikleri
├── resources/
│   └── defs/{units, buildings, levels, storms}   # .tres tanımları
├── shaders/                 # sh_ önekli shader dosyaları
└── tests/
    ├── unit/  integration/  smoke/
```

Kaynak dosyalar `assets/raw` içinde, `.gdignore` sayesinde motor dışı tutulur; dışa aktarılmış çıktılar `assets` altına ASSET_PIPELINE kurallarıyla girer. `scenes` ve `scripts` ayrımı, yeniden kullanılabilir varlık sahneleri (`entities`) ile ekran kompozisyonlarını (`game`, `menus`, `ui`) netleştirir.

## 6. Otomatik Yükleyiciler (Autoload)

| Autoload | Sorumluluk | Yasak |
|---|---|---|
| EventBus | Global sinyal hub'ı; sistemler arası gevşek bağ | İş mantığı, durum tutma |
| AppManager | Oyun durumu makinesi (boot/menu/game/pause), `time_scale` | Sahne yapısı bilgisi |
| SceneRouter | Sahne geçişi, yükleme ekranı, geçiş animasyonu | Oyun durumu tutma |
| SaveManager | Kayıt yaz/oku, şema migrasyonu, atomik dosya işlemi | İş kuralları |
| SettingsService | Ses/grafik preset/dil ayarları; kalıcı | Oyun içi durum |
| AudioManager | Müzik/ambiyans/SFX kanal yönetimi, ses havuzu | Ses üretimi (dosya kaynağı dışı) |

Yüklenme sırası bağımlılık sırasıdır: EventBus → AppManager → SceneRouter → SaveManager → SettingsService → AudioManager. Otomatik yükleyiciler birbirine `get_node("/root/...")` yerine doğrudan sınıf erişimiyle ulaşır; döngüsel bağımlılık kurulamaz — iletişim ihtiyacı `EventBus` sinyalleriyle çözülür.

## 7. İzometrik Dünya Sistemi

### 7.1 Tile Standartları

Tile oranı 2:1 elmas; ekranda 256×128 tasarım px (kaynak 512×256, bkz. ASSET_PIPELINE B.3). Yükseklik kademeleri 64 tasarım px'tir; elevasyon farkları siluetle okunur. Tile dokuları elmas merkezi pivotlu üretilir (ASSET_PIPELINE B.4).

### 7.2 Katman Yapısı

| Katman | Düğüm | Y-sort | İçerik |
|---|---|---|---|
| GroundLayer | TileMapLayer | Kapalı | Zemin tile'ları |
| OverlayLayer | TileMapLayer | Kapalı | Zemin işaretleri, yerleşim göstergeleri |
| StructureLayer | TileMapLayer | Açık | Duvarlar, tile bazlı binalar |
| EntitiesLayer | Node2D | Açık | Birim ve prop sahneleri |
| AirLayer | Node2D | Yok (üstte) | Uçan mermiler, hava FX |

Y-sort kuralı: ekranda çakışabilen her şey (bina, birim, prop) y-sort açık katmandadır; birim sahnesi pivotu ayak-zemin temasında olduğundan sort doğal olarak doğru çalışır.

### 7.3 Koordinat Dönüşümleri

`scripts/core/iso_math.gd`, map↔world dönüşümlerinin tek kaynağıdır: `map_to_world`, `world_to_map`, footprint anchor hesapları ve hücre komşuluk yardımcıları. TileMapLayer'ın yerleşik `local_to_map`/`map_to_local` çağrıları bu sarmalayıcı üzerinden kullanılır. Saf fonksiyonlardan oluştuğu için birim test zorunluluğu vardır (TESTING B.3).

### 7.4 Fırtına Görünürlüğü

`StormSystem`, hücre bazlı görüş değeri üretir; `OverlayLayer` işaretleri ve bir görsel maske shader'ı (`sh_storm_fog.gdshader`) bu değeri sahneye yansıtır. Fırtına yoğunluğu arttıkça görüş yarıçapı düşer, enerji üretimi dalgalanır (B.11). Görsel şiddet ART_DIRECTION B.5'teki atmosfer şemasını izler.

## 8. Kamera Sistemi

`scenes/game/camera_rig.tscn`: `Node2D` (pivot) → `Camera2D`. Kamera 2.5D sabit açıya bağlıdır: rotasyon ve eğim yoktur; yalnızca pan ve zoom vardır. Bu hem taktik okunabilirliği korur hem mobil maliyeti sabitler.

- **Pan:** tek parmak sürükleme (boş alanda), hedef konuma yumuşak sönümleme.
- **Zoom:** iki parmak pinch, 0.6–1.8 aralığı, pinch merkezli.
- **Odaklama:** çift dokunuş, seçili birime/lokasyona tween ile odaklanma.
- **Sınır:** kamera merkezi `LevelDef.map_rect` ile kelepçelenir; harita dışı boşluk gösterilmez.
- **Zoom tabanlı detay:** 1.0 altında birim etiketleri ve HP barları kademeli gizlenir; eşikler ayarlardan gelir.

Yasaklar: serbest rotasyon, alan derinliği (DOF) efekti ve sürekli edge-pan (ekran kenarı kaydırma) mobil UX ve maliyet nedeniyle kullanılmaz.

## 9. Girdi Sistemi

Girdi, cihaz bağımsız `InputMap` aksiyonları üzerinden soyutlanır; kodda ham tuş/parmak eşlemesi olmaz.

| Aksiyon | Mobil eşleme | Açıklama |
|---|---|---|
| `select` | kısa dokunuş | Birim/bina seçimi |
| `order_move` | seçim sonrası hedef dokunuşu | Hareket emri |
| `order_attack` | düşman hedefine dokunuş | Saldırı emri |
| `order_build` | bina menüsünden sürükle-yerleştir | İnşa yerleşimi |
| `multi_select_box` | uzun basılı sürükleme | Kutu ile çoklu seçim |
| `camera_pan` | tek parmak (boş alan) sürükleme | Kamera kaydırma |
| `camera_zoom` | pinch | Yakınlaştırma |
| `pause_toggle` | HUD düğmesi | Taktik duraklatma |
| `cancel` | geri/iptal düğmesi | Emir ve menü iptali |

Kurallar: dokunma hedefi en az 64×64 tasarım px; her dokunma görsel geri bildirim (highlight) üretir; editör testleri `emulate_touch_from_mouse` ile yapılır (project.godot içinde açık). Girdi eşiği ve jest süresi sabitleri `SettingsService` üzerinden ayarlanabilir olmalıdır.

## 10. Varlıklar ve Veri Odaklı Tasarım

### 10.1 Sınıf Yapısı

`BaseEntity` (Node2D) ortak temeldir; `UnitEntity` ve `BuildingEntity` türetilir. Davranışlar komponent düğümlerine bölünür: `HealthComponent`, `MovementComponent` (grid tabanlı yol izleme), `CombatComponent`, `BuilderComponent`. Komponentler birbirini doğrudan çağırmaz; `EventBus` sinyalleriyle haberleşir.

### 10.2 Tanım Kaynakları

| Tanım | Örnek Alanlar |
|---|---|
| `UnitDef` | id, display_name, max_hp, move_speed, attack_damage, attack_range, vision_radius, cost_energy, cost_salvage, sprite_path, anim_map |
| `BuildingDef` | id, display_name, footprint_cells, build_time, max_hp, energy_output, energy_drain, defense_profile, sprite_path |
| `LevelDef` | id, map_size, start_resources, storm_schedule, spawn_table, win_condition, lose_condition, seed |
| `StormDef` | intensity_curve, visibility_multiplier, damage_per_tick, particle_profile |

Tanım dosyaları `resources/defs/` altında `def_<tür>_<ad>.tres` adıyla durur. Kural: mekanik davranış kodda, sayısal değerler tanımdadır; denge ayarı hiçbir zaman kod değişikliği gerektirmemelidir.

### 10.3 Üretim

`EntityFactory`, tanım id'sinden doğru sahneyi ve komponent setini örneklendirir. Yeni bir birim eklemek için: (1) `UnitDef` `.tres` oluştur, (2) sprite setini ASSET_PIPELINE'a göre hazırla, (3) fabrika kaydını ekle, (4) testleri çalıştır, (5) denge kaydını worklog'a yaz.

## 11. Üs, İnşa ve Ekonomi

Yerleşim validasyonu `IsometricWorld`'ün tuttuğu grid occupancy haritası üzerinden yapılır: her hücre, onu kaplayan varlık referansını bilir. İnşa doğrulaması üç koşulu denetler: footprint boş mu, elevasyon uygun mu, kaynak yeterli mi. Onaylanmayan yerleşim, görsel önizlemede kırmızı tehlike rengiyle (ART_DIRECTION B.4 kuralları) reddedilir.

Ekonomi iki kaynak üzerine kuruludur: **Enerji** (turkuaz; jeneratör binalarından üretilir, fırtınada dalgalanır) ve **Hurda** (amber tonu; keşif ve savaşla kazanılır). Savunma düzeni, fırtına dalgalarının spawn tetiklemesiyle sınanır; oyuncu hem savunma yapılarını hem birim komutlarını yönetir. Kaynak sayısı bilinçli olarak ikiye sabittir; yeni kaynak eklemek bir mimari karardır ve karar kaydına işlenmelidir.

## 12. Kayıt Sistemi

Kayıtlar `user://saves/slot_N.json` yoluna yazılır. Dosya şeması `schema_version` alanıyla sürümlenir; eski şemalar `SaveManager` içinde migrasyon fonksiyonlarıyla güncel şemaya taşınır. Yazma atomiktir: önce `.tmp` dosyasına yazılır, sonra yeniden adlandırılır; böylece yarı yazılmış kayıt oluşamaz.

Kayıt içeriği: level_id, kaynaklar, bina listesi (id + anchor hücre), birim listesi, fırtına zamanlayıcı durumu ve simülasyon seed'i. Kayıt okuma başarısızlığında orijinal dosya silinmez; bozuk kayıt yedeklenir ve kullanıcı bilgilendirilir. Kayıt işlemleri yalnızca `SaveManager` üzerinden yapılabilir; başka hiçbir sistem `user://` yoluna yazmaz.

## 13. Performans Bütçeleri

Bu tablo bağlayıcıdır (AGENTS Altın Kural 9). "Entry" 2 GB RAM Android taban çizgisi, "Mid" 6 GB orta segment hedefidir. Ölçüm yöntemleri TESTING.md B.7'dedir.

| Metrik | Entry | Mid | Ölçüm |
|---|---|---|---|
| FPS | ≥ 30 | 60 | Debugger > Monitors |
| Çerçeve süresi | ≤ 33 ms | render ≤ 12 ms | Profiler |
| Draw call | ≤ 120 | ≤ 200 | Monitors |
| Texture/VRAM | ≤ 200 MB | ≤ 350 MB | Monitors |
| Node sayısı (sahne) | ≤ 1200 | ≤ 2000 | Monitors |
| Aktif 2D ışık | ≤ 4 | ≤ 8 | Sahne denetimi |
| Parçacık (aynı anda) | ≤ 150 | ≤ 300 | Sahne denetimi |
| RAM (uygulama) | ≤ 700 MB | ≤ 1.0 GB | Cihaz ölçümü |
| Soğuk açılış | ≤ 8 sn | ≤ 5 sn | Log/kronometre |
| İlk indirme (AAB) | ≤ 120 MB | — | Play Console |

## 14. Platform Notları

**Android:** AAB paketleme hedeflidir; minSdk 26, arm64-v8a zorunludur. Başlangıçta uygulama izni istenmez; ileride gerektiğinde her izin, gerekçesiyle karar kaydına işlenir. İmza dosyaları repoya girmez (.gitignore).

**iOS:** Safe area (çentik/kulak bölgesi) HUD yerleşiminde mutlaka korunur; HUD üst katmanları `DisplayServer.get_display_safe_area` ile hizalanır. Arka plan/ön plan geçişlerinde ses oturumu duraklatılır. Test cihaz taban çizgisi TESTING B.8'dedir.

**Her ikisi:** girdi tamamen dokunmadır; fare yalnızca geliştirme kolaylığıdır. Fiziksel geri tuşu (Android) `cancel` aksiyonuna eşlenir.

## 15. Genişletme Rehberi

Yeni birim ekleme: B.10.3'teki beş adım. Yeni bina ekleme: aynı adımlar `BuildingDef` ile. Yeni bölüm ekleme: `LevelDef` + `StormDef` + spawn tablosu; hiçbir bölüm için özel kod yazılmaz. Yeni görsel efekt: `sh_` önekli shader veya `scenes/vfx` sahnesi + parçacık bütçesi kontrolü.

Her genişletme işi tamamlandığında, ilgili dokümandaki ilgili bölüm (örneğin ASSET_PIPELINE kabul listesi) ve worklog güncellenir. Dokümanlarda o varlık türü için bölüm yoksa, önce bölüm eklenir.

## 16. Açık Karar Noktaları

| Karar | Mevcut Taslak | Etkisi |
|---|---|---|
| Gerçek zamanlı+taktik duraklatma mı, sıra bazlı mı? | RTwP çekirdek; `TurnScheduler` soyutlaması hazır | Scheduler seçimi, HUD akışı |
| Fırtına görünürlük tekniği | Hücre bazlı maske + shader | VFX maliyeti, performans |
| Otomatik savaş ile tam komut dengesi | Açık | Girdi ve birim komponent tasarımı |

Bu noktalar kapatılırken Bölüm 2'ye yeni karar satırı eklenir ve worklog'a yazılır. Kapalı kararı yeniden açmak, açık kararı kapattığından daha büyük bir iştir; bu nedenle karar satırları bilinçli yönetilir.
