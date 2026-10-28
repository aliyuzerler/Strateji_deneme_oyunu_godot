# Dustbound — AGENTS.md

> Bu dosya, Dustbound üzerinde çalışan yapay zekâ geliştirme ajanlarının ve ekip üyelerinin ortak operasyon kılavuzudur. **Sonraki tüm görevlerde bu beş doküman (AGENTS, ARCHITECTURE, ART_DIRECTION, ASSET_PIPELINE, TESTING) esas alınır.** Hiçbir kod veya varlık üretimi, ilgili doküman okunmadan başlatılmaz.

- Sürüm: 0.1.1
- Son güncelleme: 2026-10-28
- Aşama: **0.5 — İzometrik Kanıt Sahnesi** (0: Temel Dokümantasyon tamamlandı)

---

## 1. Proje Kartı

| Alan | Değer |
|---|---|
| Proje adı | Dustbound |
| Tür | Taktik strateji (üs kurma, savunma düzeni, fırtınaya karşı taktik kararlar) |
| Tema | Kum fırtınası distopyası: çölde fırtınaya karşı hayatta kalma |
| Motor | Godot 4.7.2 stabil (minimum 4.6.3; yalnızca stabil sürümler) |
| Programlama dili | GDScript (statik tipli; C# kullanılmaz) |
| Hedef platformlar | Android 8.0+ (API 26, arm64), iOS 13+ |
| Render motoru | Mobile (Vulkan) — `project.godot` içinde sabit |
| Görsel yön | Modern stilize 2D, izometrik 2.5D — **retro piksel art yasaktır** |
| Palet | Kum amberi, grafit, turkuaz enerji, kontrollü kırmızı tehlike vurgusu |
| Tasarım çözünürlüğü | 1280×720, `canvas_items` stretch, `expand` aspect, yatay yönlendirme |
| Proje kökü | `/home/z/my-project/dustbound` |
| Paylaşılan iş kaydı | `/home/z/my-project/worklog.md` |

## 2. Mevcut Aşama ve Kapsam Sınırı

Proje şu anda **Aşama 0**'dadır: beş yönetişim dokümanı yazılmış, klasör iskeleti ve minimal `project.godot` yapılandırması kurulmuştur. Bu aşamanın amacı, sonraki tüm işlerin tutarlı kurallar üzerine oturmasını sağlamaktır; oyunun kendisi henüz üretilmeye başlanmamıştır.

Bu aşamada **yapılabilir** olan işler: doküman güncellemeleri, klasör düzeninin korunması, proje yapılandırmasının iyileştirilmesi, GUT test eklentisinin kurulumu (ayrı bir görev olarak), boş sahne şablonlarının tanımlanması ve test altyapısının hazırlanması. Bu aşamada **yasak** olan işler: oyun mekaniği kodu, birim/bina sahnelerinin üretimi, sanat varlığı üretimi veya üçüncü taraf varlık eklenmesi, monetizasyon/analitik/ağ kodu ve sertifika gerektiren export preset kurulumları.

Bu sınırın gerekçesi basittir: temelsiz yazılan her mekaniğin ileride ARCHITECTURE.md'deki yapıya taşınması ikinci kez iş yapmaktır. Bir görevin Aşama 0 sınırını aşması gerekiyorsa, önce bu doküman kümesi güncellenmeli, ardından iş onlara göre planlanmalıdır.

**Aşama 0.5 (kullanıcı göreviyle eklendi):** İzometrik 2.5D kanıt sahnesi — Camera2D takip sistemi, izometrik TileMapLayer zemin, tap-to-move oyuncu hareketi, Y-sort derinlik kanıtı, blob gölgeler ve sınırlı dinamik ışık (2/4 bütçe). Geçici placeholder varlıklar ASSET_PIPELINE ölçü/pivot/palet kurallarına uygun üretildi; TileSet geçici olarak kodla kurulur (production'da .tres). Bu kapsam dışındaki mekanik yasağı (savaş, inşa, ekonomi, kayıt) sürer.

## 3. Doküman Haritası ve Öncelik Sırası

Her görev öncesi okuma sırası: **AGENTS → ARCHITECTURE → görevin konusuna göre ilgili doküman**.

| Doküman | Yönettiği Konu | Ne Zaman Okunur |
|---|---|---|
| AGENTS.md | Süreç, kurallar, iş akışı, kapsam | Her görev öncesi (bu dosya) |
| ARCHITECTURE.md | Sistem tasarımı, sahne yapısı, kamera, girdi, veri modeli, performans bütçeleri | Kod veya yapılandırma yazarken |
| ART_DIRECTION.md | Palet, stil sütunları, ışık, şekil dili, UI görsel kuralları | Görsel karar veya görsel iş üretirken |
| ASSET_PIPELINE.md | Ölçek, pivot, isimlendirme, içe aktarım ayarları, lisans doğrulama | Varlık eklerken veya düzenlerken |
| TESTING.md | Test katmanları, komutlar, performans kapıları, cihaz matrisi | Kod yazarken ve görev tamamlarken |

Çatışma çözümü: görsel konularda sıralama ART_DIRECTION > ASSET_PIPELINE > ARCHITECTURE şeklindedir; teknik konularda ARCHITECTURE diğerlerini geçer; süreç konularında AGENTS önceliklidir. Çözülemeyen bir çatışma, dokümanların güncellenmesiyle (bkz. Altın Kural 7) kalıcı olarak çözülür — sessizce özel istisna üretilerek değil.

## 4. Altın Kurallar

1. **Dokümanlar önce.** İşe başlamadan önce worklog ve görevle ilgili doküman bölümleri okunur. Dokümanda olmayan bir varsayım üzerine kod yazılmaz.
2. **Mobil öncelik (mobile-first).** Her karar, en düşük hedef cihazda (2 GB RAM, Android 8) sorunsuz çalışacak şekilde değerlendirilir. Masaüstü geliştirme kolaylığı, mobil maliyeti asla geçemez.
3. **Statik tipli GDScript.** Yeni tüm kod tipli yazılır (`var hp: int = 10`). Tiplenmemiş tanım ancak dosya içinde gerekçesiyle kullanılabilir.
4. **Konvansiyonlar pazarlıksızdır.** İsimlendirme ASSET_PIPELINE Bölüm 6'daki grameri izler; mimari desenler ARCHITECTURE'daki karar kaydını izler.
5. **Lisans kapısı.** Kayıt (registry) satırı olmayan hiçbir üçüncü taraf varlık repoya giremez. Prosedür ASSET_PIPELINE Bölüm 9'dadır.
6. **Deterministik simülasyon.** Simülasyon katmanında rastgelelik yalnızca seed'li `RandomNumberGenerator` ile olur; sim mantığı `_process` içinde yazılmaz (bkz. ARCHITECTURE Bölüm 3).
7. **Önce doküman, sonra kod.** Davranış veya mimari değişikliği önce ilgili `.md` dosyasına işlenir, sonra uygulanır. Doküman ile kod arasındaki uyuşmazlıkta doküman tek doğruluk kaynağıdır ve kod dokümana getirilir.
8. **Küçük, doğrulanabilir değişiklikler.** Bir görev tek bir sorumluluk alanını değiştirir; büyük değişiklikler küçük adımlara bölünür.
9. **Bütçeler kırmızı çizgidir.** ARCHITECTURE Bölüm 13'teki performans bütçeleri aşıldığında, bütçeyi esnetmek yerine aşan maliyet öncelikli iş haline gelir.
10. **Worklog disiplini.** Her görev sonunda `/home/z/my-project/worklog.md` dosyasına yeni bölüm eklenir (Bölüm 7'deki şablonla).

## 5. Teknoloji Yığını ve Sürüm Politikası

| Bileşen | Seçim | Not |
|---|---|---|
| Motor | Godot 4.7.2 stabil | Sürüm pini `project.godot` feature etiketiyle uyumlu tutulur |
| Dil | GDScript (statik tipli) | C# ve GDExtension kullanılmaz |
| Test çerçevesi | GUT 9.x (MIT) | Kurulumu ayrı görev; `addons/gut` altına |
| Renderer | Mobile (Vulkan) | Editor'de de aynı yöntemle çalışılır (tutarlı önizleme) |
| Veri | Custom Resource (`.tres`) | Denge değerleri kodda değil tanım dosyalarında |

Sürüm yükseltme prosedürü: (1) resmi changelog okunur, (2) yükseltme yedek bir dalda yapılır, (3) headless import ve tüm test katmanları çalıştırılır, (4) mobil export önizlemesi doğrulanır, (5) sürüm pini güncellenir ve worklog'a yazılır. Minor sürüm atlamaları rutin bakım penceresinde, feature sürüm atlamaları ise ayrı bir görev olarak planlanır.

Eklenti politikası: yalnızca belgelendirilmiş gereksinimle eklenti eklenir; her eklenti lisans kapısından geçer (ASSET_PIPELINE B.9). Simülasyon çekirdeği hiçbir harici eklentiye bağımlı tutulmaz, böylece test edilebilirlik korunur.

## 6. Konvansiyon Özeti

| Konu | Kural | Detay |
|---|---|---|
| Dosya/klasör adı | snake_case, yalnız ASCII, boşluksuz | ASSET_PIPELINE B.6 |
| Sınıf adı (`class_name`) | PascalCase | ARCHITECTURE B.10 |
| Düğüm (node) adı | PascalCase | ARCHITECTURE B.10 |
| Sinyal adı | geçmiş zaman, snake_case: `order_executed` | ARCHITECTURE B.10 |
| Fonksiyon adı | fiil öncelikli snake_case: `validate_order` | — |
| Sabit | UPPER_SNAKE_CASE | — |
| Doku öneki | `tex_`, ikon `icon_`, ses `sfx_`/`mus_`/`amb_` | ASSET_PIPELINE B.6 |
| Girinti | Tab (Godot editör standardı) | — |
| Satır uzunluğu | 100 karakteri geçmez | — |

## 7. Ajan İş Akışı

Her görev aşağıdaki yedi adımı izler. Adımlar atlanmaz; atlanan adım, dokümanla uyumsuz sonuç üretmenin başlıca nedenidir.

1. **Bağlamı yükle:** `/home/z/my-project/worklog.md` okunur; görevle ilgili doküman bölümleri okunur.
2. **Plan:** görev, madde madde planlanır; belirsiz karar noktaları kullanıcıya sorulur.
3. **Doküman kontrolü:** plan; palet, bütçe, isimlendirme ve lisans kurallarıyla karşılaştırılır.
4. **Uygula:** küçük adımlarla, her adım çalışır durumda bırakılarak uygulanır.
5. **Test:** TESTING.md'deki ilgili katman çalıştırılır (en az headless import + unit).
6. **Öz-denetim:** Bölüm 9'daki Tamamlanma Tanımı maddeleri tek tek işaretlenir.
7. **Kaydet:** worklog'a aşağıdaki şablonla bölüm eklenir.

```markdown
---
Task ID: <görev kimliği>
Agent: <ajan adı>
Task: <yapılan işin kısa tanımı>

Work Log:
- <somut adım 1>
- <somut adım 2>

Stage Summary:
- <ana sonuçlar / önemli kararlar / üretilen çıktılar>
```

## 8. Komut Kılavuzu

```bash
GODOT=godot-4.7.2                       # kullanılan Godot çalıştırıcısı
ROOT=/home/z/my-project/dustbound

# Varlık içe aktarım sağlığı (her görevde ilk komut)
$GODOT --headless --path $ROOT --import

# Unit testleri (GUT kurulduktan sonra)
$GODOT --headless --path $ROOT -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs -gexit

# Editörü aç
$GODOT --path $ROOT -e
```

Not: `main_scene` şu an kanıt sahnesidir (`scenes/game/test_arena.tscn`, Aşama 0.5). Boot akışı görevi geldiğinde `scenes/boot/boot.tscn` ana sahne olarak atanacaktır. Kanıt sahnesi smoke testle korunmektedir: `godot --headless --path $ROOT -s res://tests/smoke/smoke_runner.gd`.

## 9. Tamamlanma Tanımı (Definition of Done)

Bir görev ancak aşağıdaki maddelerin tümü sağlandığında tamamlanmış sayılır:

- [ ] İlgili dokümanlara aykırılık yok (veya doküman bilinçli güncellendi)
- [ ] `$GODOT --headless --path $ROOT --import` hatasız tamamlandı
- [ ] Görevle ilgili test katmanı yeşil (TESTING.md)
- [ ] Performans bütçeleri aşılmadı (ARCHITECTURE B.13)
- [ ] Yeni varlık varsa: isim, ölçü, pivot ve lisans kaydı tamam (ASSET_PIPELINE)
- [ ] Etkilenen doküman bölümleri güncellendi
- [ ] `worklog.md` kaydı eklendi

## 10. Yaygın Tuzaklar

Bu hatalar benzer projelerde en sık görülenlerden; her biri bir kuralın somut ihlalidir. Gözden kaçırılmaması için burada toplandılar. Ana iş parçacığını bloklamak (dosya IO, ağır hesap) mobilde ani takılmalar üretir — uzun işler parçalanır veya iş parçacığına alınır. `_process` içinde nesne üretmek ayrıştırıcı baskısı yaratır — tekrarlayan nesneler için havuz kullanılır. Sprite'ları non-uniform ölçeklemek ART_DIRECTION'ın şekil dilini bozar — boyut dosyada doğru üretilir. Nearest filtre piksel art hissi verir — yasaktır. Türkçe karakter veya boşluk içeren dosya adları içe aktarım sorunları üretir — yalnız ASCII. Palet dışı renk seçmek görsel tutarlılığı kırar — ART_DIRECTION B.4 rampaları dışına çıkılmaz. Sim katmanında seed'siz rastgelelik determinizmi bozar — test edilemez hale gelir.

## 11. Kapsam Dışı Alanlar

Şu anki kapsamda olmayan ve ayrıca doküman güncellemesi gerektiren alanlar: multiplayer, monetizasyon (IAP/reklam), analitik, reklam SDK'ları, hesap sistemleri, bulut kayıt, kullanıcı üretimi içerik ve masaüstü/konsol sürümleri. Bu alanlardan biri gündeme geldiğinde ilgili doküman (çoğunlukla ARCHITECTURE) yeni karar satırıyla güncellenir, sonra uygulama başlar.
