# Dustbound — Faz 05 Test ve Uygulama Raporu

**Faz:** 05 — Savaş Varlıkları (oyuncu + 3 düşman tipi + otomatik hedefleme/saldırı)
**Tarih:** 2026-10-28 · **Ortam:** Godot 4.7.2-stable, Mobile (Vulkan) hedef; doğrulama headless + Mesa llvmpipe (gl_compatibility geçici override)
**Smoke sonucu:** Orijinal kanıt sahnesi **17/17 PASS** (sıfır regresyon) · Yeni savaş paketi **36/36 PASS**

---

## 1. Kapsam

Mevcut izometrik kanıt sahnesi (Aşama 0.5) **bozulmadan** aşağıdakiler eklendi:

| Bileşen | Dosya | Not |
|---|---|---|
| 8 yönlü sheet animasyon kütüphanesi | `scripts/core/sprite_anim_lib.gd` | Satır=yön (E→NE), sütun=kare; açı→dir indeks |
| Birim tanımları | `scripts/entities/unit_defs.gd` | Kod tabanlı; production'da `def_*.tres` olacak |
| Savaş varlık tabanı | `scripts/entities/combat_unit.gd` | Can, hasar, flash, knockback, ölüm akışı, HP çubuğu |
| Oyuncu (savaş yetenekli) | `scripts/entities/placeholder_player.gd` | Mevcut sınıf adı korunarak genişletildi |
| Düşman AI | `scripts/entities/enemy_unit.gd` | IDLE→CHASE→WINDUP durum makinesi |
| Mermi | `scripts/entities/projectile.gd` | Düz hat + yarıçap çarpışması |
| Spatial hash | `scripts/systems/enemy_registry.gd` | nearest / in_radius / separation |
| FX | `scripts/systems/combat_fx.gd` | Hasar etiketi, püf, telegraf halkası |
| Dalga + ölçüm | `scripts/systems/enemy_director.gd` | Dalga üretimi + bench |
| Arena entegrasyonu | `scripts/systems/test_arena.gd`, `scenes/game/test_arena.tscn`, `scripts/ui/arena_hud.gd` | GroundFx/AirFx katmanları, DALGA/ÖLÇÜM butonları |
| Test | `tests/smoke/f05_smoke_runner.gd` | 36 kontrol |
| Geçici sanat | `assets/art/characters/tex_unit_*_sheet_01.png` (+2 raw yok), `assets/art/vfx/tex_fx_bolt_*`, `tex_fx_ring_telegraph_01` | 23 dosya, hepsi TMP rozetli |

## 2. Düşman Tipi Farklılaştırması (görev gereksinimi)

| Tip | Davranış | Hız | Can | Hasar | Soğuma | Özel |
|---|---|---|---|---|---|---|
| **Kum Koşucusu** (runner) | Melee, zigzag takip | 300 px/s | 40 | 7 | 0.9 s | Yüksek hız, düşük can |
| **Grit Muhafız** (brute) | Slam, 0.8 s telegraf halkası + alan vuruşu (r=140) | 95 px/s | 240 | 24 | 2.2 s | Yavaş/tank, telegraflı AOE |
| **Fırtına Salyası** (spitter) | Ranged; 340–540 px güvenli bantta durur, strafe yapar, yaklaşınca kaçar | 150 px/s | 70 | 9 | 1.5 s | Menzilli, mesafe koruma |

Oyuncu: 120 can, 340 px/s, otomatik hedefleme (en yakın, 560 px), turkuaz enerji mermisi (14 hasar, 0.65 s, 980 px/s). Turkuaz enerji **yalnızca oyuncuda** (ART_DIRECTION kuralı); düşman vurguları kırmızı (göz/namlu ucu — kontrollü kullanım).

## 3. Tutarlılık Kanıtları (görev gereksinimleri)

- **Hareket yönü ↔ animasyon yönü:** Kuzeye yürüyüşte `facing=6` ve `walk` animasyonu smoke ile doğrulandı (36/36 içinde). 8 yön ayrı görsellerle üretildi (ön/arka/profil farklı çizilir; arkada vizör yok).
- **Zemin temas noktası:** Pivot ayak-zemin teması `(w/2, h-8)` — orijinal smoke'ın pivot kontrolü **0.000 px sapma** ile PASS (yeni sheet'lerle de korunuyor).
- **Gölge:** Tüm birimlerde ayak altında blob gölge; ölçek birim genişliğiyle oransal.
- **Y-sort:** `EntitiesLayer.y_sort_enabled` korunur; savaş karesinde spitter oyuncunun arkasına geçtiğinde doğru örtülme **ekran görüntüsüyle kanıtlandı** (`arena_f05_combat_late.png`).

## 4. Hasar ve Ölüm (görev gereksinimi)

- Hasar anı: beyaz flash (0.14 s), kırmızı tint'li hurt karesi, geri itme (birim başına güç), yüzen hasar etiketi (oyuncuya kırmızı, düşmana turkuaz), HP çubuğu (yalnızca hasarlı birimde).
- Ölüm: 3 karelik yığılma animasyonu → gölge+gövde solması → `queue_free` (düşman) / **respawn** (oyuncu: 1.4 s sonra başlangıç noktasında, 2 s dokunulmazlık yanıp sönmesi).
- Oyuncu ölümü HUD'da "DÜŞTÜ — yeniden doğuluyor..." durumu.

## 5. Test Sonuçları

### 5.1 Orijinal smoke (regresyon) — 17/17 PASS
Tümü geçti; kritik olanlar: pivot 0.000 px, 2× doku 0.5 scale, IsoMath↔TileMap uyumu 0.000 px, ışık bütçesi 3/4, y-sort flag'leri, tap→hareket boru hattı.

### 5.2 Yeni savaş smoke — 36/36 PASS
Öne çıkanlar: yön indeks eşlemeleri, kuzeye yürüyüşte facing=6, otomatik hedef kilidi, mermi isabeti (hp 40→26), take_hit matematiği, ölüm→registry çıkışı→temizlik, tip sıralamaları (hız/can/davranış), spitter kaçış davranışı (203→321 px), brute telegraf+slam hasarı (113→89), hasar etiketi, nearest() doğruluğu, knockback (64.6 px kayma), 100 düşman spawn, temizlik, oyuncu respawn.

### 5.3 Performans ölçümü (görev gereksinimi)

**Headless (`--bench=100`, 8 s, 1158 kare):**

| Metrik | Değer |
|---|---|
| Spawn edilen | 100 (40/30/30 karışım, tohumlu RNG) |
| **Boş sahne (baseline)** | **6.70 ms/kare** |
| **100 düşmanlı ortalama** | **6.91 ms/kare** → **net savaş maliyeti ≈ 0.21 ms/kare** |
| p95 / maks | 8.43 ms / 30.9 ms (maks = spawn karesi) |
| Node sayısı | 445 (baseline'la birlikte ölçüm anında) |

**Görsel koşu (llvmpipe yazılım GL, referans):** 6 düşmanla FPS 16-21, draw call **123–131** (< 200 mid bütçesi), VRAM 216–249 MB. Yazılım GL değerleri yalnızca rega göredir; cihaz ölçümü TESTING.md B.8 matrisi gereği ayrı görevdir. HUD'daki **ÖLÇÜM 100** butonu ile aynı ölçüm cihaz üzerinde gerçek render ile tekrarlanabilir.

**Bütçe değerlendirmesi:** Mantık tarafı 100 düşmanda bile çok rahat (0.21 ms net). Draw call tarafında 100 düşman ~300 sprite çizimi gerektirir; mid hedefi (≤200) için ~50-60 düşman, entry bütçesi (≤120) için ~25-30 düşman uygundur — sprite atlas tek tek paylaşım sayesinde batch davranışı cihazda doğrulanmalıdır. Bu nedenle **ÖLÇÜM 100** aracı kasıtlı olarak stres değerindedir.

## 6. Tespit Edilen ve Giderilen Hatalar

1. **Aşırı pozlama:** Oyuncunun yeni turkuaz ışığı kristal + güneş ışığıyla toplanınca sahneyi yaktı → enerji 1.1→0.55, ölçek 1.5→1.15 (görsel koşu ile tespit).
2. **`tree_exiting` çift bağlantı:** Registry `update_position` bucket değişiminde unregister→register yaparken bağlantıyı yeniden kurmaya çalışıyordu → `is_connected` guard.
3. **`clear_all` performans tuzağı:** `in_radius(…, 1e7)` 24 milyar hücre taraması açıyordu (smoke 240 s timeout) → `all_units()` doğrudan üye döngüsü.
4. **Ölüm karesi taşması (sanat):** Devrilme rotasyonu hücre dışına taşıp kırpılıyordu → "çökerek yığılma" (küçük rot + dikey squash) çözümü.
5. **Gölge ölçeği:** Sabit 256 px blob küçük düşmanlarda büyük kalıyordu → birim genişliğiyle oransal ölçek.

**Bilinen açık görsel konular (geçici/aten):** Arena dışı arka plan kara kalıyor (default_clear_color, tasarım kabulü); TMP rozetli placeholder'lar Faz 06 sanat paketinde değişecek; hasar etiketi fontu Godot varsayılanı (production Türkçe glif doğrulamalı font gelecek).

## 7. Geçici Varlıklar (açık işaret)

23 dosya; **her kareye soluk "TMP" rozeti** basıldı, dosya adları `tex_unit_*_sheet_01` / `tex_fx_bolt_*` / `tex_fx_ring_telegraph_01`, `docs/ASSET_LICENSES.csv`'ye "PLACEHOLDER (TMP rozetli)" olarak 23 yeni kayıt (tpl-014…tpl-036) işlendi. Üretim aracı: `scripts/gen_f05_art.py` + `scripts/f05_art_lib.py` (deterministik, palet ART_DIRECTION B.4'ten).

## 8. Deviations ve Notlar

- `PlaceholderPlayer` sınıf adı korundu (mevcut sahne/smoke referansları); production oyuncu birimi ayrı görevde `PlayerUnit` olarak netleşecek.
- Birim tanımları kod tabanlı (`UnitDefs`); ARCHITECTURE'daki `def_*.tres` hattına Faz 06'da taşınacak.
- GUT yerine mevcut zero-bağımlılık smoke çerçevesi genişletildi (addon uyumluluk riski alınmadı; TESTING.md'deki GUT geçişi ayrı görev).
- Animasyonlar kod tabanlı Sprite2D doku değişimiyle yürüyor (AnimatedSprite2D değil) — smoke pivot/scale kontrollerinin bozulmaması ve 2×/0.5 kuralının korunması için bilinçli seçim.

## 9. Kanıt Görüntüleri

`tests/smoke/shots/` (kopyası `download/dustbound-proof-shots/`):
- `arena_front.png` / `arena_behind.png` — klasik Y-sort kanıtı, yeni görsellerle (regresyon)
- `arena_crystal.png` — kristal ışığı dengesi
- `arena_f05_combat.png` — savaş başlangıcı: hedef kilidi, saldırı animasyonu, HUD savaş satırı
- `arena_f05_combat_late.png` — hasar etiketi + HP çubuğu + Y-sort örtülme + oransal gölgeler
