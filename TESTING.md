# Dustbound — TESTING.md

> Test stratejisinin, komutlarının, performans kapılarının ve cihaz matrisinin kaynağıdır. AGENTS.md B.7 iş akışının 5. adımı (Test) bu dokümandaki kurallara göre yürütülür. Performans bütçelerinin mimari kaynağı ARCHITECTURE.md B.13'tür; buradaki kapılar onun doğrulama tarafıdır.

- Sürüm: 0.1.0
- Son güncelleme: 2026-10-28

---

## 1. Test Stratejisi

Test çabası, maliyeti en düşük ve geri bildirimi en hızlı katmandan yukarı doğru kademelenir. Amaç, hatayı mümkün olan en erken katmanda yakalamaktır: bir dönüşüm hatası unit testte bir saniyede bulunurken, cihaz testinde günler sürebilir.

| Katman | Kapsam | Ne Zaman |
|---|---|---|
| Unit | Saf mantık: IsoMath, komut doğrulama, ekonomi, hasar formülleri | Her değişiklik, headless, saniyeler |
| Simülasyon/Entegrasyon | Tick senaryoları, scheduler davranışı, kayıt döngüsü | Her PR, headless |
| Smoke | Proje açılışı, sahne yükleme, import sağlığı | Her commit |
| Performans | FPS/RAM/VRAM bütçeleri, termal davranış | Her kilometre taşı |
| Manuel QA | Dokunma UX, yaşam döngüsü, erişilebilirlik | Sürüm adayı |

Denge ilkesi: unit ve sim katmanları kod yoğunluğunun çoğunu taşır; cihaz testi az ama değerli işlemlerdir (bütçe doğrulama, gerçek dokunma davranışı). Cihazda keşfedilen her hata, mümkünse alt katmana indirgenen bir testle kalıcılaştırılır.

## 2. Test Ortamı ve Araçları

- **Godot:** sürüm pini AGENTS.md B.5 ile aynıdır (4.7.2 stabil); testler her zaman headless çalışır.
- **GUT 9.x (MIT):** `addons/gut` altına kurulur (kurulum ayrı bir görevdir; kurulanana dek unit katmanı planlanır ama çalıştırılmaz).
- **Determinizm:** tüm test seed'leri sabittir; zaman/sistem bağımlılıkları testten izole edilir. Simülasyon testleri, ARCHITECTURE B.3'teki determinizm kurallarına dayanır.
- **Ortam bağımsızlığı:** testler dosya yolu olarak yalnız `res://` ve `user://` kullanır; çalıştırıcı makine varsayımı yapılmaz.

## 3. Unit Testleri

Zorunlu kapsam listesi (ilgili kod var olduğunda bu testler olmadan görev tamamlanmaz):

- **IsoMath:** map↔world gidiş-dönüş, footprint anchor hesapları, kenar ve negatif hücreler (ARCHITECTURE B.7.3).
- **Komut doğrulama:** geçersiz emir reddi (yok hücreye hareket, dolu hücreye inşa, yetersiz kaynak).
- **Ekonomi:** maliyet düşümü, üretim dalgaları, fırtına etkisiyle enerji değişimi.
- **Savaş:** hasar formülü, zırh hesapları, menzil sınırı.
- **StormSystem:** yoğunluk eğrisi örnekleme, görünürlük çarpanı.

Adlandırma: `tests/unit/test_<konu>.gd` dosyaları, `test_<davranış>` fonksiyonları. Şablon:

```gdscript
extends GutTest
# tests/unit/test_iso_math.gd

func test_map_world_roundtrip() -> void:
    var iso := IsoMath.new()
    for cell: Vector2i in [Vector2i.ZERO, Vector2i(3, -2), Vector2i(-7, 5)]:
        var world := iso.map_to_world(cell)
        assert_eq(iso.world_to_map(world), cell, "gidiş-dönüş bozuldu: %s" % cell)
```

Testler oyun kodundan bağımsız çalışabilmelidir: test içinde sahne kurulumu gerekiyorsa, kurulum test dosyasının kendisinde yapılır ve smoke katmanına sızdırılmaz.

## 4. Simülasyon ve Entegrasyon Testleri

Bu katman, simülasyon çekirdeğinin uçtan uca davranışını doğrular. Temel araç **senaryo dosyasıdır**: sabit seed, sıralı komut listesi (JSON) ve beklenen durum imzası. Test akışı: sim başlat → komutları oynat → N tick ilerlet → durum hash'ini karşılaştır. Uyuşmazlık, determinizmin kırıldığının kanıtıdır ve S2 hata sayılır.

Zorunlu senaryo sınıfları: hareket emirleri zinciri, inşa→üretim→fırtına dalgası döngüsü, duraklatma/sürdürme (`time_scale`) geçişleri ve kayıt döngüsü (save → load → save; dosyalar birebir eşit olmalı). Scheduler testleri: RealtimeScheduler'ın tick sayımı, duraklatmada tick donması, hız değişiminde geçiş doğruluğu.

Entegrasyon testleri autoload zincirini de kapsar: EventBus sinyal sırası kritik akışlarda (emir→uygulama→sinyal) doğrulanır. Sinyal sırası, UI geri bildirim tutarlılığının temelidir.

## 5. Smoke Testleri

Smoke katmanı en ucuz güvenlik ağıdır ve her commit'te çalışır:

- Headless proje açılışı hatasız (kayıp script, bozuk sahne yok).
- Autoload zinciri sırayla hazır: EventBus → AppManager → SceneRouter → SaveManager → SettingsService → AudioManager.
- `--headless --import` temiz çalışır; kayıp varlık uyarısı yok.
- Tanımlı sahnelerin tümü yüklenebilir (sahne listesi büyüdükçe genişler).

## 6. Komut Kılavuzu

```bash
GODOT=godot-4.7.2
ROOT=/home/z/my-project/dustbound

# 1) İçe aktarım sağlığı (her görevde ilk komut)
$GODOT --headless --path $ROOT --import

# 2) Unit testler
$GODOT --headless --path $ROOT -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs -gexit

# 3) Entegrasyon (sim) testler
$GODOT --headless --path $ROOT -s addons/gut/gut_cmdln.gd -gdir=res://tests/integration -ginclude_subdirs -gexit

# 4) Editörü aç
$GODOT --path $ROOT -e
```

CI entegrasyonu (gelecek): GitHub Actions üzerinde `--import` + GUT adımları; cihaz testi pipeline dışında kalmaya devam eder (B.11).

## 7. Performans Testleri

**Yöntem:** Godot Debugger > Monitors (FPS, Process/Physics Time, Draw Calls, Video Memory, Object Count) birincil ölçümdür. Cihazda ölçüm, debug derleme + uzaktan hata ayıklayıcı üzerinden yapılır; 10 saniyelik ölçüm pencereleri üç kez tekrarlanır ve medyan değer alınır. Fırtına en yoğun evresiyle ölçülür — sakin an ölçümü gerçekçi değildir.

**Zorunlu ölçümler:**

- Yoğun sahnenin FPS eğrisi (min/ort/medyan).
- Draw call ve VRAM (bütçe tablosuna karşı).
- Termal test: mid cihazda 30 dk kesintisiz oturum; FPS düşüşü %10'u geçerse başarısız.
- Bellek sızıntısı: 10 dk oturumda RAM artışı ≤ 5 MB; oturum sonunda temiz serbest bırakma.

**Kapılar:**

| Kapı | Ölçüt | Ne Zaman |
|---|---|---|
| G1 Sahne render | Mid cihazda 60 FPS stabil, draw call ≤ 200 | İlk oynanabilir sahne |
| G2 Entry çalışır | Entry cihazda 30 FPS, RAM ≤ 700 MB | İlk cihaz derlemesi |
| G3 Yükleme | Soğuk açılış ≤ 8 sn (entry) | Boot akışı tamamlandığında |
| G4 Termal | 30 dk oturumda düşüş ≤ %10 | Sürüm adayı öncesi |

## 8. Cihaz Matrisi

| Katman | Örnek Cihaz | SoC / RAM | Hedef | Not |
|---|---|---|---|---|
| Android entry | Redmi 9A | Helio G25 / 2 GB | 30 FPS, düşük preset | Birincil kısıt; tüm kararların taban çizgisi |
| Android mid | Galaxy A54 | Exynos 1380 / 6 GB | 60 FPS, orta preset | Ana hedef kitle |
| Android high | Galaxy S23 | SD 8 Gen 2 / 8 GB | 60 FPS, yüksek preset | Görsel şov cihazı |
| iOS min | iPhone SE 2 (A13) | A13 / 3 GB | 30–60 FPS, orta preset | iOS taban çizgisi |
| iOS mid | iPhone 12 | A14 / 4 GB | 60 FPS, orta-yüksek | — |
| iOS high | iPhone 15 | A16 / 6 GB | 60 FPS, yüksek preset | — |

Kural: entry cihazda kırılan özellik "kapatılabilir" olmalıdır (grafik preseti düşürür); oyun mekaniği entry cihazda hiç eksilmez. Düşük preset; parçacık yoğunluğu, ışık sayısı ve fırtına FX katmanlarını ölçekler (ARCHITECTURE B.13) — varlık çözünürlüğünü değil.

## 9. Manuel QA Kontrol Listesi

Sürüm adayı öncesi gerçek cihazlarda yürütülür:

- [ ] Dokunma jestleri (seçim, kutu seçimi, pinch zoom) gerçek parmakla doğrulandı
- [ ] Safe area: çentik/kulak bölgesi HUD ile çakışmıyor
- [ ] Kesinti: gelen arama/bildirim sonrası oyun kaldığı yerden devam ediyor
- [ ] Arka plan → ön plan: ses ve sim durumu tutarlı geri geldi
- [ ] Kaydet → uygulamayı kapat → yeniden aç: kayıt bozulmadan yüklendi
- [ ] Türkçe metinlerde taşma/kesilme yok
- [ ] Renk körlüğü simülasyonu ile kritik bilgi okunabilir
- [ ] 30 dk oturumda aşırı ısınma/pil davranışı makul

## 10. Hata Şiddet Seviyeleri

| Seviye | Tanım | Aksiyon |
|---|---|---|
| S1 | Çökme, kayıt kaybı, ilerleme engeli | Sürüm engelleyici; derhal düzeltme |
| S2 | Ana akış bozulur ama geçilebilir | Kilometre taşı öncesi zorunlu düzeltme |
| S3 | Yanlış davranış; geçici çözüm mümkün | Planlanır, backlog |
| S4 | Kozmetik | Backlog, düşük öncelik |

Determinizm ihlalleri (B.4) mekanik olarak S2'den aşağı inemez: tekrar üretilemeyen simülasyon, denge çalışmasını ve test güvenini çökertir. Hata kayıtları, üretim adımını (hangi katmanda yakalandı) içermelidir; bu, kaçış analizi (test piramidindeki delikleri bulma) için veri sağlar.

## 11. Gelecek Genişletme

Şu an kapsamda olmayan, ihtiyaç doğduğunda eklenecek alanlar: CI pipeline (GitHub Actions: headless import + GUT), otomatik export derlemeleri, cihaz tarımı (bulut test çiftlikleri) ve çökme raporlama. Bu alanların her biri açılığında ARCHITECTURE karar kaydına satır ekler ve worklog'a işlenir; sessizce araç eklenmez.

## 12. Sürüm Öncesi Kontrol Listesi

- [ ] Tüm test katmanları yeşil (B.6 komutları)
- [ ] Performans kapıları G1–G4 işaretli
- [ ] Manuel QA listesi (B.9) tam
- [ ] Export preset doğrulandı (AAB, imza; sertifika dosyaları repoda değil)
- [ ] Sürüm numarası ve changelog güncel
- [ ] Kayıt şeması sürümü ile migrasyon test edildi
- [ ] worklog.md'de sürüm kaydı mevcut
