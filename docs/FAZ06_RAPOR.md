# Dustbound — Faz 06 Test ve Uygulama Raporu

**Faz:** 06 — Mobil HUD ve Savaş Efektleri
**Tarih:** 2026-10-28 · **Ortam:** Godot 4.7.2-stable, Mobile (Vulkan) hedef; doğrulama headless + Mesa llvmpipe (gl_compatibility geçici override)
**Smoke sonucu:** Orijinal kanıt sahnesi **17/17 PASS** · Faz 05 paketi **36/36 PASS** · Yeni Faz 06 paketi **43/43 PASS** (toplam 96 kontrol, sıfır regresyon)

---

## 1. Kapsam

Mevcut izometrik savaş sahnesi (Faz 05) **bozulmadan** aşağıdakiler eklendi:

| Bileşen | Dosya | Not |
|---|---|---|
| Efekt bütçesi + otomatik kalite | `scripts/systems/fx_budget.gd` | Cap'ler: efekt 64 · etiket 16 · iz 28 · top 40; FPS örnekleme ile YÜKSEK/ORTA/DÜŞUK |
| Oyuncu ilerleme durumu | `scripts/systems/player_state.gd` | XP/seviye/hurda/kill/süre; `leveled` sinyali |
| Ödül sistemi | `scripts/entities/loot_orb.gd`, `scripts/systems/loot_director.gd` | XP topu + hurda; mıknatıs, toplama, butçe dolunca değer birleştirme |
| Efekt paketi | `scripts/systems/combat_fx.gd` (genişletildi) | Ayak/ölüm tozu, çarpma parlaması (additive), iz noktası, XP/hurda toplama, seviye halkası |
| Mermi görselleri | `scripts/entities/projectile.gd` (genişletildi) | Enerji izi (30 px aralık) + isabet parlaması |
| Oyuncu girdi/yetenek | `scripts/entities/placeholder_player.gd` (genişletildi) | Joystick vektörü, Enerji Patlaması (10 radyal mermi), Atılım (dash + invuln + toz), yükseltme uygulama |
| Sanal joystick | `scripts/ui/virtual_joystick.gd` | Sol alt; 320×320 hedef, çoklu dokunma güvenli, ölü bölge 0.18 |
| Mobil HUD | `scripts/ui/game_hud.gd` | Can/XP/hurda/süre/dalga; yetenek çubuğu; seviye paneli; safe area; bildirimler |
| Geliştirici paneli | `scripts/ui/arena_hud.gd` (dönüştürüldü) | Eski teşhis HUD'u DEV düğmesiyle açılır panele taşındı |
| Arena orkestrasyonu | `scripts/systems/test_arena.gd` (genişletildi) | Neden tabanlı duraklatma, otomatik dalga (35 s), FX istatistik satırı, `--safe-test` / `--fx-high` |
| Sinyaller | `scripts/systems/enemy_director.gd` (genişletildi) | `unit_spawned` / `wave_spawned` |
| Test | `tests/smoke/f06_smoke_runner.gd` | 43 kontrol |
| Geçici sanat | `assets/art/ui/*` (5), `assets/art/vfx/*` (5) | 10 dosya, 2×, TMP politikası §5 |

## 2. Görev Gereksinimleri → Uygulama Karşılaması

| Gereksinim | Durum | Kanıt |
|---|---|---|
| Can, XP, hurda, süre göstergeleri okunabilir | ✅ | Sol üst: can barı (amber; %30 altı kırmızı) + XP barı (turkuaz) + seviye; orta üst: MM:SS + DALGA; sağ üst: hurda ikonu + sayı. Tüm metinler kontur+gölge ile (ART_DIRECTION B.12) |
| Hareket kontrolü sol alt | ✅ | TouchJoystick 320×320 hedef; çoklu dokunmada yalnız kendi parmağını izler |
| Yetenekler sağ alt | ✅ | Enerji Patlaması (Q) + Atılım (E), 96×96 px, radyal cooldown kapağı + saniye sayacı + hazır nabzı |
| Enerji mermisi efekti | ✅ | Turkuaz mermi + additive iz noktaları (kaliteye göre olasılık) |
| Çarpma parlaması | ✅ | Additive 4 uçlu parlama + mevcut püf halkası; oyuncu vurgusu turkuaz-beyaz, düşman kızıl |
| Toz | ✅ | Yürüyüş ayak tozu (0.14 s ölçümlü), Atılım toz izi, ölüm toz bulutu (kaliteye göre küme) |
| Hasar efekti | ✅ | Faz 05 hasar etiketleri korundu + bütçeye bağlandı |
| XP toplama efekti | ✅ | Turkuaz halka + "+N XP" etiketi; hurda için amber halka + "+N" |
| Yetenek seçiminde duraklatma | ✅ | Seviye atlayınca oyun duraklar, 3 kartlık seçim paneli açılır; seçim/ATLA ile devam (f06 smoke 43/43 içinde kanıtlandı) |
| Güvenli ekran alanları | ✅ | `DisplayServer.get_display_safe_area` → iç boşluk; `--safe-test` ile çentik simülasyonu + görsel işaret (kanıt karesi) |
| Farklı en-boy oranları | ✅ | `canvas_items+expand` + tam çapa tabanlı yerleşim; 16:9 / 19.5:9 (2532×1170) / 4:3 (1024×768) kanıt kareleri |
| Efektleri sınırla | ✅ | FXBudget tip-duyarlı sayım (etiket bütçesi mermi yoğunluğundan etkilenmez), kaliteye göre olasılık/küme kırpma, terleme önleyen 3 sn dwell |
| Gerçek cihaz performans hazırlığı | ✅ | `docs/CIHAZ_OLCUM.md` protokolü (M1–M6), DEV panelinde FX satırı, `F06_BENCH_JSON` çıktısı |

## 3. Duraklatma Yönetimi (Yeni)

Neden tabanlı duraklatma: `set_pause_reason(id, on)` — "manual" (ESC/düğme)
ve "levelup" (yetenek seçimi) bağımsız takip edilir; hiçbir neden aktif değilse
oyun akar. Eski `toggle_pause()` davranışı korunur (orijinal smoke 17/17).

## 4. Performans Ölçümleri

**Headless bench (`--bench=100`, 8 s, 1157 kare):** baseline 6.70 ms → 100
düşman **6.92 ms avg** / 8.53 p95 / 40.3 max (spawn karesi) — net savaş
maliyeti ≈ 0.21 ms/kare; 501 node. FX istatistikleri `F06_BENCH_JSON` ile
raporlanır.

**llvmpipe görsel koşu (referans, yazılım GL):** FPS 15, draw call ≈ 160–170,
VRAM ≈ 260 MB (100 düşmanlı olçüm butonu haricinde 6 düşmanla daha düşük).
Gerçek cihaz doğrulaması `docs/CIHAZ_OLCUM.md` akışıyla yapılacaktır.

**Bütçe disiplini:** Efekt spawn'ları FXBudget üzerinden geçer; dolu cap'te
kozmetikler sessizce düşer (oyun bilgisi taşıyan hasar etiketleri öncelikli).
Kalite DÜŞÜK'te: toz olasılığı 0.45, iz olasılığı 0.45, küme sayıları yarıya.

## 5. Geçici Görsel İşaretleme Politikası

- **Statik UI dokuları** (joystick taban/topuz, 3 yetenek/upseltme ikonu):
  doku üzerine "TMP" rozeti işlenir (açık işaret).
- **Çok sayıda tekrar eden FX dokuları** (toz, iz, parlama, XP topu, hurda):
  her puflemeye rozet basmak gürültü yaratacağından rozet dokuya işlenmez;
  bunun yerine (a) `docs/ASSET_LICENSES.csv` kayıtları "PLACEHOLDER (TMP)",
  (b) geliştirici paneli "TMP FX" bağlamı, (c) README uyarısı ile açık
  işaretlenir. Üretim sanat paketi (Faz 07+ hattı) bu dokuların tamamını
  değiştirecektir.
- Karakter sheet'lerindeki kare başına TMP rozetleri Faz 05'ten korundu.

## 6. Bulunan ve Giderilen Sorunlar

1. **`VirtualJoystick` ad çakışması:** Godot 4.7'de aynı adlı yerel sınıf
   var → sınıf `TouchJoystick` olarak yeniden adlandırıldı.
2. **Bütçe sayımı çapraz bulaşma:** etiket/efekt/iz aynı ebeveyni paylaşınca
   mermi izleri etiket bütçesini tüketiyordu → `FXBudget._count` tip-duyarlı
   yapıldı (Label / Sprite2D ayrımı).
3. **Küçük FX dokularında kare bozulma:** 64–192 px dokular ~20 px'e küçülürken
   mipmap'siz minifikasyon blok görünüm üretiyordu → 8 FX dokusunda
   `mipmaps/generate=true` (kum karosu benekleri ile karıştırmayın; onlar
   zemin dokusunun kendi süsüdür).
4. **Eski f05 smoke'un determinizmi:** yeni ödül sistemi eski akıştaki
   ölümlerden XP toplayıp seviye duraklatması tetikliyordu →
   `TestArena.levelup_pause_enabled` anahtarı eklendi; f05 smoke başında
   kaplanır (kontroller değişmedi), davranış f06 smoke'ta açıkça test edilir.
5. **SceneTree betiğinde `get_tree()`:** smoke runner'da doğrudan `paused`
   kullanılmalıydı (parse hatası) → düzeltildi.
6. **lambda'da serbest nesne yakalama:** toplama testinde orb serbest kalınca
   uyarı → `instance_id` üzerinden güvenli erişim.

## 7. Ekran Görüntüsü Kanıtları (`tests/smoke/shots/` → `download/dustbound-proof-shots/`)

| Dosya | İçerik |
|---|---|
| `arena_f06_hud.png` | Oyun içi HUD: can/XP/süre/dalga/hurda, joystick, yetenek çubuğu (cooldown 8 s), iz noktaları |
| `arena_f06_fx_burst.png` | Atılım toz izi + efekt karesi |
| `arena_f06_levelup.png` | Duraklatılmış yetenek seçim paneli (3 kart + ATLA) |
| `arena_f06_dev.png` | Geliştirici paneli: FPS/draw/VRAM + FX bütçe satırı |
| `arena_f06safe_f06_hud.png` | `--safe-test` çentik simülasyonu; HUD güvenli alana kaymış |
| `arena_f06r195_f06_hud.png` | 19.5:9 (2532×1170) yerleşim |
| `arena_f06r43_f06_hud.png` | 4:3 (1024×768) yerleşim |
| `arena_f05_combat*.png` | Regresyon: Faz 05 savaş kareleri (yeni görsellerle) |

## 8. Açık Konular

- Gerçek cihaz ölçümü (TESTING B.8 matrisi) — protokol hazır: `docs/CIHAZ_OLCUM.md`
- TMP UI/FX sanatı → üretim sanat paketi
- PlayerState yükseltme kartları → `resources/defs/units` altında `def_*.tres` hattı
- Ses geri bildirimi (toplama/saldırı) ayrı görev
- GUT 9.x geçişi ayrı görev
