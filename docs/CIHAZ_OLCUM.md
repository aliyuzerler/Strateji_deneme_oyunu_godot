# Dustbound — Gerçek Cihaz Ölçüm Protokolü (Faz 06)

**Amaç:** Mobil HUD ve savaş efektlerinin (Faz 06) gerçek Android/iOS cihazlarda
TESTING.md B.8 performans kapılarına (G1–G4) göre doğrulanması. Yazılım
render'lı (llvmpipe) masaüstü ölçümleri yalnızca *referanstır*; kabul kriteri
gerçek cihaz ölçümüdür.

---

## 1. Ölçüm Öncesi Hazırlık

1. Projeyi cihaza kurmadan önce `--bench` olmadan **temiz kurulum** yap
   (debug overlay kapalı başlar; DEV paneli yalnızca ölçüm sırasında açılır).
2. Cihazı hazırla: pil ≥ %80, geliştirici seçeneklerinde "profili daima aç"
   (Android), arka plan uygulamaları kapat, uçak modu + sabit parlaklık.
3. Termal durum: ölçüme cihaz oda sıcaklığında başla; 10 dakikalık maraton
   koşusunu ayrı bir "ısınmış cihaz" ölçümü olarak kaydet (TESTING G2).

## 2. HUD Üzerinden Ölçüm Adımları

| Adım | İşlem | Kaydedilecek |
|---|---|---|
| M1 | Oyunu aç, DEV panelini aç | Soğuk açılış süresi (G3: ≤ 8 s), boot FPS'i |
| M2 | 3 dk serbest oyun (joystick + yetenekler) | FPS avg/min, draw call max, VRAM max |
| M3 | "DALGA +6" ×3 bas | Dalga yoğunluğunda FPS avg/min |
| M4 | "ÖLÇÜM 100" bas | 100 düşman: avg/p95/max ms, node sayısı |
| M5 | Seviye atla, seçim paneli açık bekleyen kare | Duraklatmada render maliyeti |
| M6 | Ekran görüntüsü al (HUD + dev panel) | Rapor kanıtı |

> Dev panel satırları: `FPS | Draw call | Objeler | VRAM` ve
> `FX: kalite · efekt n/64 · etiket · iz · top · fps_ort`.
> Kalite etiketi **DÜŞÜK**'e düşünüyorsa cihaz G1 kapısındadır; not al.

## 3. Otomatik Bench (Masaüstü Doğrulama Referansı)

```bash
godot --headless --path . -- --bench=100
# Çıktılar:
#   F05_BENCH_JSON  {avg_ms, p95_ms, max_ms, nodes, ...}
#   F06_BENCH_JSON  {f05: {...}, fx: {quality, fx, labels, trails, orbs, fps_avg, caps}, player: {level, xp, scrap, kills}}
```

llvmpipe referans değerler (2026-10-28, headless):
baseline **6.70 ms** → 100 düşman **6.92 ms** avg / 8.53 p95 (net savaş maliyeti
≈ **0.21 ms/kare**), 501 node. FX cap'leri: efekt 64 · etiket 16 · iz 28 · top 40.

## 4. Kabul Kapıları (TESTING.md B.8 özeti)

| Kapı | Kriter | Faz 06 ölçümü |
|---|---|---|
| G1 | Orta segment gerçek cihaz **60 FPS** dalga yoğunluğunda | M3 koşusu; FXBudget kalitesi ≥ ORTA kalmalı |
| G2 | 10 dk maraton: FPS çöküşü yok, VRAM sabit | M2 uzun koşu; efekt sayacı sızıntısı yok (stats() dengeli) |
| G3 | Soğuk açılış ≤ 8 s | M1 |
| G4 | Çizim çağrısı ≤ 120 (giriş cihazı hedefi) | M3/M4 draw call maksimumu |

## 5. FX Bütçe Kalibrasyonu

Gerçek cihazda kalite sık sık DÜŞÜK'e iniyorsa sırasıyla:
1. `FXBudget.CAP_TRAIL` 28 → 16 (en yüksek kâr/maliyet),
2. toz olasılığı `spawn_prob()` LOW 0.45 → 0.3,
3. iz noktası aralığı `CombatBolt.TRAIL_SPACING` 30 → 44 px.
Bu üçü görsel kimliği en az bozan ayar kollarıdır; cap'leri düşürmeden önce
kare maliyet profili alın (M4 avg ms farkı).

## 6. Bildirilecek Alanlar

- FPS min/avg (M2/M3), draw call max, VRAM baş/son farkı
- FXBudget kalite geçiş sayısı (terleme tespiti: 3 sn dwell sonrası bile
  salınım varsa `DWELL` artırılmalı)
- Dokunma UX notları: joystick ölü bölge hissi, 96 px yetenek hedefi
  parmak konforu, notch simülasyonu (`--safe-test`) ile HUD çakışması
