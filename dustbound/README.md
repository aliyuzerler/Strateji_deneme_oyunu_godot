# Dustbound

> Kum fırtınası distopyasında geçen, **izometrik 2.5D taktik strateji** —
> Godot 4.7 + GDScript, Android & iOS hedefli.

[![Aşama](https://img.shields.io/badge/a%C5%9Fama-Faz%2006%20%E2%80%94%20Mobil%20HUD%20%2B%20Efektler-2EC4B6)](#faz-ge%C3%A7mi%C5%9Fi)
[![Motor](https://img.shields.io/badge/Godot-4.7.2%20Mobile(Vulkan)-D9A05B)](https://godotengine.org)
[![Smoke](https://img.shields.io/badge/smoke-96%2F96%20PASS-brightgreen)](#test-ve-do%C4%9Frulama)

---

## İçindekiler

1. [Proje Hakkında](#proje-hakkında)
2. [Ekran Görüntüleri](#ekran-görüntüleri)
3. [Hızlı Başlangıç](#hızlı-başlangıç)
4. [APK ile Telefonda Test](#apk-ile-telefonda-test)
5. [Kontroller](#kontroller)
6. [Faz Geçmişi](#faz-geçmişi)
7. [Faz 06: Mobil HUD ve Savaş Efektleri](#faz-06-mobil-hud-ve-savaş-efektleri)
8. [Sistem Mimarisi](#sistem-mimarisi)
9. [Performans Bütçeleri ve Ölçüm](#performans-bütçeleri-ve-ölçüm)
10. [Güvenli Alan ve En-Boy Oranı Desteği](#güvenli-alan-ve-en-boy-oranı-desteği)
11. [Test ve Doğrulama](#test-ve-doğrulama)
12. [Proje Yapısı](#proje-yapısı)
13. [Sanat Yönü ve Geçici Varlık Politikası](#sanat-yönü-ve-geçici-varlık-politikası)
14. [Yol Haritası](#yol-haritası)
15. [Katkı / Ajan İş Akışı](#katkı--ajan-iş-akışı)

---

## Proje Hakkında

**Dustbound**, kum fırtınalarıyla kuşatılmış bir distopyada üs kurma, savunma
düzeni ve taktik kararlar üzerine kurulu bir mobil strateji oyunudur. Görsel
kimlik **modern stilize 2D / izometrik 2.5D**'dir; retro piksel art bilinçli
olarak yasaktır. Renk dili: kum amberi (dünya), grafit (panel/strateji),
**turkuaz enerji (yalnızca oyuncu tarafı)** ve kontrollü kırmızı (tehlike,
ekranın en fazla ~%5'i).

Depo şu anda oynanabilir bir **kanıt sahnesi** (12×12 izometrik arena) ve
üzerine kurulu savaş + HUD sistemlerini içerir. Tüm kararlar `docs/`
altındaki beş yönetişim dokümanıyla (AGENTS, ARCHITECTURE, ART_DIRECTION,
ASSET_PIPELINE, TESTING) kilitlenmiştir; çatışma durumunda dokümanlar tek
doğruluk kaynağıdır.

## Ekran Görüntüleri

Kanıt kareleri `tests/smoke/shots/` altında üretilir (Xvfb + llvmpipe referans
render). En güncel Faz 06 kanıtları:

| | |
|---|---|
| **Mobil HUD** — can/XP/süre/dalga/hurda + joystick + yetenekler | `arena_f06_hud.png` |
| **Yetenek seçimi (duraklatma)** — seviye atlama paneli | `arena_f06_levelup.png` |
| **Çentik simülasyonu** — güvenli alan (`--safe-test`) | `arena_f06safe_f06_hud.png` |
| **19.5:9** — uzun ekran yerleşimi | `arena_f06r195_f06_hud.png` |
| **4:3** — tablet yerleşimi | `arena_f06r43_f06_hud.png` |
| **Geliştirici paneli** — FPS/draw/VRAM + FX bütçesi | `arena_f06_dev.png` |
| **Savaş** — otomatik hedefleme + mermi izleri | `arena_f05_combat.png` |

## Hızlı Başlangıç

**Gereksinim:** Godot 4.7.2 (stabil). Mobile render hedefi masada otomatik
olarak llvmpipe/uyumluluk ile de çalışır.

```bash
# 1) Depoyu aç ve içe aktarmayı çalıştır (ilk açılışta kaynaklar derlenir)
godot --headless --path . --import

# 2) Editörde aç
godot --path .

# 3) Doğrudan sahneyi çalıştır (main_scene = test_arena.tscn)
godot --path .
```

**Komut satırı anahtarları** (`--` sonrası):

| Anahtar | Amaç |
|---|---|
| `--shot` | Kanıt görüntüsü dizisi üretir (`tests/smoke/shots/`) ve kapanır |
| `--shot-prefix=<yol>` | Kanıt dosya adı öneki |
| `--bench=100` | Headless performans ölçümü (100 düşman, 8 s) → `F05_BENCH_JSON` + `F06_BENCH_JSON` |
| `--safe-test` | Çentik/kulak simülasyonu (sol 110, üst 40, sağ 70 px) + görsel işaret |
| `--fx-high` | FX kalitesini YÜKSEK'e sabitle (deterministik çekim/ölçüm) |

## APK ile Telefonda Test

**Ön derlenmiş APK:** `download/Dustbound-0.1.0-debug.apk` (~31 MB, debug imzalı)

| Özellik | Değer |
|---|---|
| Paket | `com.dustbound.game` |
| Sürüm | 0.1.0 (versionCode 1) |
| Min. Android | 7.0 (minSdk 24) · hedef API 36 |
| Mimari | arm64-v8a (2016 sonrası telefonların neredeyse tamamı) |
| Yön / Ekran | Sensör-landscape, immersive tam ekran (çentik güvenli) |
| İmza | Debug keystore — yalnızca test amaçlı, mağazaya uygun değil |

**Kurulum:**

1. APK'yı telefona aktar (USB, kablosuz aktarım, Drive vb.).
2. Dosya yöneticisinden APK'ya dokun; çıkan uyarıda **"Bu kaynaktan kurulum"a izin ver** de.
3. Kur → Aç. Oyun yatay açılır; sol alt joystick ile hareket, sağ alt yetenek düğmeleri.

> Emülatör / x86 cihazlar desteklenmez (yalnızca arm64-v8a paketlendi).
> İlk cihaz testi için `docs/CIHAZ_OLCUM.md` (M1–M6) protokolünü izle; FPS, draw
> call ve FX bütçesi canlı olarak sağ üst **DEV** panelinden okunur.

**Kaynaktan derleme:**

```bash
# Gereksinimler: Godot 4.7.2 + Android SDK (build-tools 34.0.0, platform-tools,
# platforms;android-34) + JDK 17+. Editör Ayarları → Export → Android altında
# Java SDK Path ve Android SDK Path ayarlanmalı.
godot --headless --path . --import
godot --headless --path . --export-debug "Android" Dustbound.apk
```

`export_presets.cfg` repoda hazırdır (arm64-v8a, immersive, sensor-landscape);
imzalama debug keystore ile otomatik yapılır. Release imzası için ayrı
keystore gereklidir.

## Kontroller

| Eylem | Dokunmatik | Klavye/Fare (geliştirici) |
|---|---|---|
| Hareket | **Sol alt joystick** | WASD / ok tuşları |
| Yürüyüş emri | Arena'ya tek dokunuş | Sol tık |
| Yakınlaştırma | İki parmak pinch | Tekerlek |
| **Enerji Patlaması** | Sağ alt düğme (Q rozeti) | `Q` |
| **Atılım (dash)** | Sağ alt düğme (E rozeti) | `E` |
| Duraklat | Sağ üst `II` düğmesi | `ESC` |
| Yetenek seçimi | Seviye atlayınca otomatik açılır; kart seç veya **ATLA** | Fare ile kart tıkla |
| Geliştirici paneli | Sağ üst `DEV` | — |

Oyun ilkesi: dokunma hedefleri ≥ 64×64 tasarım px (joystick 320×320,
yetenekler 96×96); her dokunuşta görsel geri bildirim vardır.

## Faz Geçmişi

| Faz | Kapsam | Rapor |
|---|---|---|
| 0 | Yönetişim dokümanları + proje iskeleti | — |
| 0.5 | İzometrik kanıt sahnesi: kamera takibi, y-sort derinlik kanıtı, blob gölgeler, sınırlı dinamik ışık, dokunma girdisi | `docs/` |
| 05 | Savaş varlıkları: oyuncu + 3 düşman tipi (runner/brute/spitter), otomatik hedefleme, hasar/ölüm, dalga üretimi | `docs/FAZ05_RAPOR.md` |
| **06** | **Mobil HUD + savaş efektleri + ödül/seviye sistemi + efekt bütçesi** | `docs/FAZ06_RAPOR.md` |

## Faz 06: Mobil HUD ve Savaş Efektleri

### HUD Yerleşimi (güvenli alan içinde)

```
┌──────────────────────────────────────────────────────────────┐
│ CAN ▓▓▓▓▓▓▓░░ 113/120   00:10   [hurda ♦ 0] [DEV] [II]      │
│ XP  ▓▓░░ SVY 1 · 0/40           DALGA 1                      │
│                                                              │
│                        (izometrik arena)                     │
│                                                              │
│  ╭──────╮                                    ┌────┐ ┌────┐  │
│  │ ◉    │  joystick                          │ Q  │ │ E  │  │
│  ╰──────╯  (sol alt)                          └────┘ └────┘  │
│                                          yetenekler (sağ alt)│
└──────────────────────────────────────────────────────────────┘
```

- **Can barı:** amber; %30 altında kırmızıya döner (tehlike dili).
- **XP barı:** turkuaz (enerji = oyuncu kuralı); seviye kartları `SVY n · x/y`.
- **Kronometre:** hayatta kalma süresi MM:SS; duraklatmada durur.
- **Hurda:** düşman ölümlerinden toplanır; ikon + sayaç.
- **Dalga:** otomatik dalga akışı 35 s'de bir büyür; `DALGA +6` (dev) elle tetikler.
- **Yetenek düğmeleri:** radyal cooldown kapağı + kalan saniye + hazır nabzı.
- **Seviye atlama:** oyun **duraklar**, 3 rastgele yükseltme kartı sunulur
  (Enerji Çekirdeği/Kum Rüzgarı/Soğutma Sargısı/Dayanıklı Deri/Geniş Patlama/
  Mıknatıs Alanı havuzundan), seçim veya ATLA ile devam.

### Efekt Kataloğu (FXBudget denetiminde)

| Efekt | Tetik | Bütçe türü |
|---|---|---|
| Enerji izi (additive nokta) | Mermi uçuşu (30 px aralık) | `trail` ≤ 28 |
| Çarpma parlaması | Mermi isabeti | `fx` ≤ 64 |
| Ayak tozu | Yürüyüş (0.14 s) | `fx` ≤ 64, olasılık |
| Atılım toz izi | Dash | `fx` |
| Ölüm tozu bulutu | Birim ölümü | `fx`, küme 3–5 |
| Hasar etiketi | Hasar alımı | `label` ≤ 16 |
| XP/hurda toplama | Toplama anı | `label` + `fx` |
| Seviye halkası | Seviye atlama | `ground` |
| XP topu / hurda | Düşman ölümü | `orb` ≤ 40 (dolunca değer birleştirir) |

**Otomatik kalite:** kayan FPS örnekleme (0.5 s) → YÜKSEK (≥50) / ORTA (≥32) /
DÜŞÜK. Düşük kalite toz/iz olasılığını 0.45'e, küme sayılarını yarıya indirir.
3 saniye dwell terlemeyi önler. `--fx-high` ile sabitlenebilir.

## Sistem Mimarisi

```
TestArena (orkestratör)
├─ GroundLayer / OverlayLayer / StructureLayer (TileMapLayer, y-sort)
├─ GroundFx  → telegraf halkaları, seviye halkası, kilit işareti
├─ LootLayer → LootOrb (XP topu / hurda)
├─ EntitiesLayer (y-sort) → PlaceholderPlayer(CombatUnit), EnemyUnit, IsoProp
├─ AirFx (CombatFx) → mermi, iz, toz, parlama, etiket havuzları
├─ CameraRig → lerp takip + pinch zoom (0.6–1.8) + arena limiti
├─ ArenaInput → tap→hareket, pinch→zoom, pause
├─ EnemyDirector → dalga üretimi (40/30/30 karışım) + bench
│   └─ unit_spawned / wave_spawned sinyalleri
├─ LootDirector → ödül düşürme + mıknatıs toplama
├─ PlayerState → XP/seviye/hurda/kill/süre
├─ FXBudget → cap + otomatik kalite + stats()
├─ ArenaHud (DEV paneli) → teşhis satırları
└─ GameHud → mobil HUD (safe area, joystick, yetenekler, seviye paneli)
```

Düşman AI durum makinesi: `IDLE → CHASE → (WINDUP) → saldırı`
(melee zigzag / slam telegraf / ranged bant+strafe — Faz 05'ten).

## Performans Bütçeleri ve Ölçüm

Hedefler (ARCHITECTURE §13): giriş cihazı 30 FPS, orta segment 60 FPS,
draw call ≤ 120, VRAM ≤ 200 MB, RAM ≤ 700 MB, soğuk açılış ≤ 8 s.

Mevcut referans ölçüm (headless llvmpipe, gerçek cihaz ölçümü değildir):

```
baseline 6.70 ms → 100 düşman 6.92 ms avg / 8.53 p95   (net savaş ≈ 0.21 ms/kare)
501 node · FX cap'leri: 64 efekt / 16 etiket / 28 iz / 40 top
```

Gerçek cihaz adımları için **`docs/CIHAZ_OLCUM.md`** protokolünü izleyin
(M1–M6 ölçüm adımları + G1–G4 kabul kapıları + kalibrasyon kolları).
HUD'daki `DEV` paneli cihaz üzerinde canlı FPS/draw/VRAM/FX okuması verir;
`ÖLÇÜM 100` düğmesi 100 düşmanlık standart koşuyu tetikler.

## Güvenli Alan ve En-Boy Oranı Desteği

- HUD kökü `DisplayServer.get_display_safe_area()` ile hesaplanan iç
  boşlukları uygular; `size_changed` sinyaliyle yeniden hizalanır.
- Tüm yerleşim çapa tabanlıdır + `canvas_items`/`expand` stretch →
  16:9, 19.5:9, 4:3'te öğeler köşelere yapışık kalır, oyun görüntüsü ortada
  tam genişler.
- Kanıt: `--safe-test` ile çentik simülasyonu (koyu bantlar + amber kenar),
  2532×1170 ve 1024×768 çekimleri.

## Test ve Doğrulama

```bash
# Import sağlığı
godot --headless --path . --import

# Smoke katmanı (toplam 96 kontrol)
godot --headless --path . -s res://tests/smoke/smoke_runner.gd       # 17 — kanıt sahnesi
godot --headless --path . -s res://tests/smoke/f05_smoke_runner.gd   # 36 — savaş varlıkları
godot --headless --path . -s res://tests/smoke/f06_smoke_runner.gd   # 43 — HUD/efekt/ödül
```

Sonuç (2026-10-28): **17/17 + 36/36 + 43/43 = 96/96 PASS**, çıkış kodu 0.
f06 paketi kapsamı: bütçe cap'leri, kalite dayatma, XP/hurda birikimi,
seviye→duraklatma→seçim→devam, ATLA akışı, ödül düşme+mıknatıs toplama,
joystick→hareket+yon tutarlılığı, radyal patlama, dash, iz/parlama/toz,
hasar etiketi, safe area dayatma, HUD göstergeleri, dalga sinyali,
kalite değişim sinyali.

## Proje Yapısı

```
dustbound/
├─ project.godot              # 1280×720, canvas_items+expand, mobile renderer
├─ scenes/
│  ├─ game/test_arena.tscn    # ana kanıt sahnesi (HUD + GameHud + LootLayer)
│  └─ entities/               # placeholder_player, iso_prop
├─ scripts/
│  ├─ core/                   # iso_math, sprite_anim_lib, arena_tileset_builder
│  ├─ entities/               # combat_unit, enemy_unit, placeholder_player,
│  │                          # projectile, loot_orb, hp_bar, unit_defs
│  ├─ systems/                # test_arena, arena_input, camera_rig,
│  │                          # enemy_director, enemy_registry, combat_fx,
│  │                          # fx_budget, player_state, loot_director
│  └─ ui/                     # game_hud, virtual_joystick, arena_hud (dev)
├─ assets/art/                # ui/, vfx/, characters/, environment/
├─ docs/                      # yönetişim + faz raporları + lisanslar + ölçüm
├─ tests/smoke/               # 3 smoke runner + teşhis probe'ları + shots/
└─ shaders/                   # (fazlar ilerledikçe)
```

## Sanat Yönü ve Geçici Varlık Politikası

Tüm görseller **geçici (TMP) placeholder'dır** ve açıkça işaretlenir:

- Karakter sheet'leri: her karede `TMP` rozeti (Faz 05).
- Statik UI dokuları (joystick, ikonlar): dokuya `TMP` rozeti (Faz 06).
- Küçük/çok tekrar eden FX dokuları (toz, iz, top, hurda, parlama): rozet
  dokuya işlenmez (görsel gürültü); bunun yerine lisans kaydı + geliştirici
  paneli + bu README ile işaretlenir.
- Tam liste ve politika: `docs/ASSET_LICENSES.csv` (46 kayıt).

Palet rampaları, 2× üretim ölçeği (sahnede 0.5), ayak pivotu (w/2, h−8),
60-30-10 renk dağılımı ve fotosensitif güvenlik (3 Hz üstü yanıp sönme yok)
kuralları `docs/ART_DIRECTION.md` + `docs/ASSET_PIPELINE.md` içinde
kilitlenmiştir. Turkuaz **yalnızca** oyuncu enerjisi/XP için kullanılır;
düşman vurguları kırmızıdır.

## Yol Haritası

1. **Cihaz doğrulama** — `docs/CIHAZ_OLCUM.md` protokolüyle G1–G4 kapıları
2. **Üretim sanat paketi** — TMP dokularının değişimi (karakter + UI + FX)
3. **def_*.tres hattı** — birim/yükseltme tanımlarının Resource'a taşınması
4. **Boot akışı + autoload'lar** — EventBus/AppManager/SceneRouter/...
5. **Grid yol bulma (MovementComponent)** — düz hat hareketin değişimi
6. **RTwP çekirdek + komut deseni + deterministik RNG** — ARCHITECTURE K-decision
7. **GUT 9.x test geçişi** — smoke'tan birim/integrasyon katmanına

## Katkı / Ajan İş Akışı

- `docs/AGENTS.md` 10 altın kural + 7 adımlı iş akışı içerir; her görev
  `worklog.md`'ye kaydedilir (Task ID + kararlar + kanıt).
- Her commit'te: headless import hatasız + 96 smoke kontrolü PASS +
  bütçe uyumu.
- Geçici varlık eklemeden önce `ASSET_LICENSES.csv` kaydı zorunludur.
