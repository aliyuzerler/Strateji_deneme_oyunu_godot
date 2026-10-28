# Dustbound — ASSET_PIPELINE.md

> Varlıkların üretimden oyuna girişine kadar tüm teknik standartları tanımlar: ölçek, pivot noktaları, isimlendirme, içe aktarım ayarları ve lisans doğrulama. Görsel kararlar (renk, stil, ışık) ART_DIRECTION.md'dedir; bu dokümandaki teknik kurallar onun uygulama detayıdır.

- Sürüm: 0.1.0
- Son güncelleme: 2026-10-28

---

## 1. Boru Hattına Genel Bakış

```
[Kaynak: .kra / .psd / .blend]
        │  (assets/raw/ içinde; .gdignore ile motor dışı)
        v
[Dışa Aktarım: PNG / WAV / OGG]  ── ASSET_PIPELINE standartları (B.7)
        v
[assets/ altına yerleştirme]     ── isimlendirme grameri (B.6)
        v
[Doğrulama]                      ── ölçü (B.3) + pivot (B.4) + palet
        v
[Kayıt]                          ── ASSET_LICENSES.csv + lisans arşivi (B.9)
        v
[Godot içe aktarım ayarları]     ── B.8 tablosu
```

İki alan birbirinden kesin ayrılır: `assets/raw/` kaynak dosyaları barındırır ve içindeki `.gdignore` dosyası sayesinde Godot motoru bu klasörü hiç görmez; motor içinde yaşayan her şey ise dışa aktarılmış, isimlendirilmiş ve kayıtlı çıktılardır. Kaynaksız bir çıktı, geriye doğru kaynak dosyasına izlenemiyorsa kabul edilmez.

## 2. Dizin Kuralları

| Yol | İçerik |
|---|---|
| `assets/raw/` | Kaynak dosyalar (.kra, .psd, .blend, projeler); motor dışı |
| `assets/art/characters/` | Birim ve karakter sprite setleri |
| `assets/art/environment/tiles/` | İzometrik tile dokuları |
| `assets/art/environment/props/` | Çevre objeleri |
| `assets/art/ui/` | Arayüz dokuları |
| `assets/art/vfx/` | Efekt sprite'ları |
| `assets/art/icons/` | İkon setleri |
| `assets/audio/{music,sfx,ambience}/` | Ses varlıkları |
| `assets/fonts/` | Font dosyaları (Türkçe glif setli) |
| `assets/licenses/` | Lisans metinleri: `<varlik-id>/LICENSE.txt` |

Klasör içi alt gruplama ihtiyacı doğarsa (örneğin çok sayıda düşman seti), yeni alt klasör `konu_adi` biçiminde açılır ve bu tablo güncellenir.assets klasöründe beklenmeyen klasör görünmesi bir ihlaldir.

## 3. Çözünürlük ve Ölçek Standardı

**Üretim ölçeği 2×'tir:** tüm görseller, ekrandaki tasarım boyutunun iki katı üretilir. Gerekçe: kamera zoom aralığı 0.6–1.8'dir (ARCHITECTURE B.8); 1.8 zoom'da dokunun keskinliğini korumak için kaynağın iki katı çözünürlük gerekir. Bu, HD sanatta (piksel art dışı) standart uygulama olan üretim-scaledown zinciridir.

| Varlık | Ekranda (1.0 zoom) | Kaynak dosya (2×) |
|---|---|---|
| Elmas tile | 256×128 px | 512×256 px |
| Yükseklik kademesi | 64 px | 128 px |
| Piyade birim boyu | ~200 px | ~400 px |
| Motorlu birim | ~320 px | ~640 px |
| Bina (1×1 hücre taban) | 256×(yükseklik) | 512×(yükseklik×2) |
| UI ikon | 32/48 px | 64/96 px |

Ölçekleme kuralları: sahnedeki sprite `scale` değeri her zaman `1.0` kalır — boyut dosyada doğru üretilir, sahnede ölçeklenerek düzeltilemez. Yalnızca uniform ölçekleme yapılır; non-uniform (x≠y) ölçek sanat dilini bozar ve yasaktır. Filtreleme her zaman Linear'dır; nearest yasaktır. Büyük dokularda mipmaps açıktır (B.8).

## 4. Pivot Noktaları

Pivot, sprite üretiminde dosyanın içinde sabitlenir: dışa aktarılan tuval, pivotun doğru noktada olduğu şekilde hizalanır. Sahnede `offset` ile düzeltme yasaktır — pivotu yanlış dosya, düzeltilmiş dosyadan daha pahalı hataya yol açar.

| Varlık | Pivot konumu | Kaynak px içinde | Not |
|---|---|---|---|
| Karakter/birim | Ayak–zemin teması | `(w/2, h-8)` | y-sort referansı; blob gölge pivotla hizalı |
| Bina | Taban hücre elmas merkezi | footprint güney hücresi | çok hücreli yerleşimde anchor hücre |
| Tile | Elmas merkezi | `(w/2, h/2)` | Godot izometrik tile standardı |
| Prop | Zemin teması | `(w/2, h-8)` | gömülü prop'larda özel, dosya notuna yazılır |
| Mermi | Merkez | `(w/2, h/2)` | — |
| Yer FX | Zemin teması | `(w/2, h-8)` | patlama, toz halkası vb. |
| Hava FX | Merkez | `(w/2, h/2)` | havada kalır, y-sort üstü |

Ayak pivotunun 8 px marjı, gölge sprite'ının taban çizgisi payıdır. Bu tablo bağlayıcıdır: kabul kontrol listesi (B.10) pivotları bu değerlerle karşılaştırır.

## 5. İzometrik Tile Spesifikasyonu

Tile oranı 2:1 elmas; ekranda 256×128 px, yükseklik kademeleri 64 px'tir. Tile dokusu, elmas formu tuvali tam dolduracak şekilde çerçevelenir; yükseklik içeren tile'lar (duvar, tepe) üst boşluk bırakır ve elmas tabana hizalıdır.

**3D ön render kamera kurulumu (karma boru hattı):** tüm çevre ve prop modelleri tek Blender kurulumuyla render edilir — ortografik kamera, rotasyon X=35.264°, Z=45° (gerçek izometrik; ekranda 2:1 iz düşümü verir), Film > Transparent açık, Color Management > Standard. Düşürülen çözünürlük 2× standardıdır. Bu kurulum her modelde birebir aynıdır; kamera açısı değişen modeller kabul edilmez, çünkü sahnede ayrışır.

Tile setleri TileSet `.tres` içinden yönetilir; ayrı atlas dosyası üretimi zorunlu değildir. Fizik katmanı (geçilebilirlik, elevasyon) TileSet verisinde tanımlanır; özel harita dosyası kullanılmaz.

## 6. Dosya ve İsimlendirme Kuralları

Zorunlu kurallar: yalnız ASCII, küçük harf, boşluk yok, Türkçe karakter yok, ayraç alt çizgi. Sürüm numarası dosya adında yer almaz (v2, final, new gibi ekler yasak; sürüm kontrolü git'in işidir).

**Gramer:** `{kategori}_{konu}_{varyant}_{durum}_{indeks}.{uzantı}` — boş alanlar atlanır, sıra korunur.

| Önek | Tür | Örnekler |
|---|---|---|
| `tex_` | Doku/sprite | `tex_unit_infantry_idle_01.png`, `tex_env_dune_a_01.png`, `tex_prop_ruin_tower_damaged_01.png` |
| `icon_` | İkon | `icon_energy_32.png`, `icon_unit_infantry_48.png` |
| `sfx_` | Ses efekti | `sfx_impact_dust_01.wav`, `sfx_build_place_01.wav` |
| `mus_` | Müzik | `mus_main_theme.ogg`, `mus_battle_storm.ogg` |
| `amb_` | Ambiyans | `amb_desert_wind_01.ogg` |
| `sh_` | Shader | `sh_storm_fog.gdshader` |
| `def_` | Tanım Resource | `def_unit_infantry.tres`, `def_level_dawnfield.tres` |
| (öneksiz) | Sahne | `unit_infantry.tscn`, `game_main.tscn`, `camera_rig.tscn` |

Durum kelimeleri: `idle`, `walk`, `attack`, `damaged`, `destroyed`, `selected`, `disabled`. Varyantlar: küçük harf (`a/b/c`) veya işlev/kademe (`l1/l2`). Animasyon adları snake_case'tir (`walk_start`, `attack_light_01`) ve sprite dosyalarının durum alanıyla uyumludur.

## 7. Dışa Aktarım Standartları

**Görsel:** PNG-24/32 (alfa), interlace kapalı, sRGB renk profili. JPEG yasaktır. Tek doku en fazla 2048×2048; tercih 1024'e sığdır. Krita'dan dışa aktarımda gizli/yardımcı katmanlar temizlenir; Blender'da Film > Transparent açık, Color Management > Standard seçili (tone curve sürprizi olmasın).

**Ses:** SFX — WAV PCM 16-bit, 44.1 kHz, mono (stereo panel efekti gereksinimi yoksa), peak −6 dBFS. Müzik ve ambiyans — OGG Vorbis q6, entegre loudness hedefi −16 LUFS, loop noktaları temiz kurgulanmış. Ses seviyesi standardı: tüm SFX dosyaları, içe aktarımda ek volume düzeltmesi gerektirmeden oynatılabilir olmalıdır.

**Font:** TTF/WOFF; OFL lisanslı olmalı (B.9); **Türkçe glif seti zorunlu** — doğrulama B.9.3'te.

## 8. Godot İçe Aktarım Ayarları

| Tür | Mipmaps | Filtre | Sıkıştırma | Not |
|---|---|---|---|---|
| Dünya dokusu (tile/prop/bina) | Açık | Linear | VRAM Compressed (ASTC) | Mobil fill-rate ve bellek dostu |
| Karakter sprite (≥512 px) | Açık | Linear | VRAM Compressed (ASTC) | Zoom keskinliği + bellek |
| Karakter sprite (<512 px) | Kapalı | Linear | Lossless | — |
| UI/ikon | Kapalı | Linear | Lossless | Keskin kenar zorunlu |
| VFX sprite | Kapalı | Linear | Lossless | Add-blend ile kullanılır |

Ses içe aktarımları: WAV loop varsayılan kapalı (loop gerektiren SFX dosya adına `_loop` alır); OGG müzik ve ambiyans loop açık. Font: Dynamic, antialiasing açık. `.import` dosyaları git'e işlenir — içe aktarım ayarları sürümlenen veridir ve bilgisayarlar arası tutarlılık sağlar.

## 9. Lisans Doğrulama Süreci

### 9.1 İzin Tablosu

| Lisans | Durum | Şart |
|---|---|---|
| MIT | İzinli | Telif notu korunur |
| CC0 1.0 | İzinli | — |
| CC BY 4.0 | İzinli | Atıf zorunlu (CREDITS) |
| Apache 2.0 | İzinli | NOTICE korunur |
| OFL 1.1 (font) | İzinli | Font adı değişiklik kurallarına uyulur |
| CC BY-NC / CC BY-ND | **Yasak** | Ticari/türev engeli |
| Kaynaksız/belirsiz lisans | **Yasak** | — |
| Oyun rip'i/çıkarılmış varlık | **Yasak** | — |
| AI üretimi varlık | Koşullu | Araç hakları belgelenir, B.9.4 süreci |

### 9.2 Doğrulama Adımları

1. Kaynağı seç; lisans metnini `assets/licenses/<varlik-id>/LICENSE.txt` olarak arşivle.
2. `docs/ASSET_LICENSES.csv` kayıt dosyasına satır ekle. Sütunlar: `id, dosya_yolu, kaynak_url, uretici, lisans, surum, tarih, ticari_izin, turetme_izin, atif_metni, dogrulayan`.
3. Ticari kullanım ve değiştirme/üretme hakkını doğrula — iki alan da "evet" olmalıdır.
4. Varlığı Godot'a al; isim (B.6), ölçü (B.3) ve pivot (B.4) kontrolünü yap.
5. Atıf gerekiyorsa CREDITS listesine ekle (oyun içi krediler ekranı bu kayıttan üretilir).
6. **Merge kapısı:** kayıt satırı olmayan bir varlık içeren PR kabul edilmez.

### 9.3 Font Glif Doğrulaması

Font eklendikten sonra şu karakter kümesi görsel olarak kontrol edilir: `ş ğ İ ı ç ö ü Ç Ğ Ö Ü â î û`. Türkçe metinler ana dildir; glif eksikliği, içe aktarım sırasında fark edilmesi gereken bir engeldir. Kontrol, editörde örnek metin etiketiyle yapılır ve worklog'a kaydedilir.

### 9.4 AI Üretimi Varlıklar

Yalnızca ticari kullanım hakkı belgelenmiş araçlar kullanılır. Kayıt satırına üretim aracı, tarih ve komut kaydı işlenir; her AI üretimi varlık insan incelemesinden (palet, siluet testi) geçmeden repoya girmez. AI üretimi, lisans riski taşıyan alanlardır; şüphe varsa kaynak reddedilir.

## 10. Varlık Kabul Kontrol Listesi

- [ ] Ölçüler B.3 tablosuna uygun
- [ ] Pivot B.4 tablosuna uygun (dosyada sabitlenmiş)
- [ ] İsimlendirme B.6 gramerine uygun (ASCII, önek, durum)
- [ ] Renkler ART_DIRECTION B.4 rampalarından
- [ ] İçe aktarım ayarları B.8 tablosuna uygun
- [ ] Lisans kaydı tamam (B.9); atıf gerekiyorsa CREDITS'te
- [ ] %25 uzaklıkta okunabilirlik testi yapıldı
- [ ] Dosya boyutu makul (tek doku ≤ 4 MB hedef)

## 11. Optimizasyon Kuralları

Gereksiz boş alfa alanı kırpılır; kırpma pivotu kaydırmayacak şekilde tuval düzenlenerek yapılır. Tekrarlayan sprite'lar TileSet/atlas öncelikli kullanılır. Aynı doku birden çok varlıkta paylaşılabilir; paylaşım bilinçli seçimdir ve dosya yolu tek yerde tutulur. Toplam başlangıç paketi hedefi ARCHITECTURE B.13 ile uyumludur: ilk indirme ≤ 120 MB. Bu hedef, doku boyut kararlarında her zaman hatırlanır; "kalite için 4K" gerekçesi paket bütçesini geçmez.

Depolama disiplini: kullanılmayan varlık hiçbir klasörde bekletilmez; çıkarılan varlık git geçmişinde yaşamaya devam eder. Ayrımlar (kırpılmış kopyalar, deneme varyantları) `assets/raw` altında tutulur, motor klasörüne hiç girmez.

## 12. Teslim Süreci

Varlık teslim akışı: kaynak üretimi → dışa aktarım → import → kabul kontrol listesi (B.10) → kayıt (B.9) → PR. PR açıklamasında şunlar bulunur: varlık listesi, lisans kaydı bağlantısı ve işaretli kontrol listesi. Görsel işler için ART_DIRECTION B.12 kabul listesi de ayrıca tamamlanır.

İnceleme reddi durumunda düzeltme yine bu akıştan geçer; "küçük düzeltme" istisnası yoktur, çünkü kayıt dışı varlık ileride izlenemez hale gelir ve boru hattının tek değeri izlenebilirliktir.
