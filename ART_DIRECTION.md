# Dustbound — ART_DIRECTION.md

> Tüm görsel kararların tek kaynağıdır. Teknik üretim detayları (ölçek, pivot, isimlendirme, içe aktarım) ASSET_PIPELINE.md'dedir. Bu dokümanla çelişen görsel iş kabul edilmez.

- Sürüm: 0.1.0
- Son güncelleme: 2026-10-28

---

## 1. Vizyon

Dustbound; kum fırtınalarının yeniden şekillendirdiği bir çöl dünyasında geçen, modern stilize 2D, izometrik 2.5D bir taktik strateji oyunudur. Görsel hedef, "boyalı sıcaklık ile grafik netlik"in aynı sahnede bir arada yaşamasıdır: dokular elle boyalı yumuşaklıkta, siluetler ve renk kodları ise grafik tasarım disiplininde durur.

Üretim yöntemi karma boru hattıdır (ASSET_PIPELINE B.1): karakter ve efektler elle çizilir, çevre ve prop'lar Blender'da low-poly modellerden yüksek çözünürlüklü ön render ile üretilir; iki yöntem tek ışık ve tek palet standardıyla birleştirilir. **Retro piksel art kesinlikle kullanılmaz**; fotorealizm de hedef değildir. Nearest filtre, dithering ve düşük çözünürlüklü sprite estetiği bu projenin sanat dilinin dışındadır.

## 2. Stil Sütunları

**Okunabilir siluet.** Her varlık — birim, bina, tehlike — tek bakışta ayırt edilmelidir. Bu taktik bir oyunun birinci görsel gereksinimidir: oyuncu parmağının altındaki birimin sınıfını, kıpırdamadan önce bilmelidir. Siluet testi (Bölüm 12) her varlık için zorunludur.

**Boyalı sıcaklık, grafik netlik.** Dokular krita boyası sıcaklığında boyanır; ancak kenarlar, renk kodları ve UI net geometrik disiplinde kalır. Sıcaklık dünyada, netlik bilgi içinde aranır. Bu gerilim Dustbound'ın imzasıdır.

**Turkuaz tek canlı renk.** Dünya bilinçli olarak kısır bir amber-grafit aralığında tutulur; sahnedeki tek canlı renk, oyuncunun kontrol ettiği turkuaz enerjidir. Böylece turkuaz, dekor değil anlam taşır: oyuncunun gücünün görsel sesidir.

**Fırtına bir karakter.** Kum fırtınası dekoratif bir arka plan değil, oyunun görsel anlatıcısıdır: yaklaştıkça palet grafitie kayar, kontrast daralır, turkuaz ve kırmızı işaretler parlaklığını korur. Atmosfer değişimi Bölüm 5'teki şemayı izler.

## 3. Ne Değil (Anti-Hedefler)

- **Retro piksel art:** nearest filtre, sınırlı palet, dithering — yasak.
- **Fotorealizm ve PBR objeler:** hedef stilize boyalı dünya, gerçekçi render değil.
- **Neon cyberpunk paleti:** mor/magenta enerji renkleri palet dışıdır; enerji yalnız turkuazdır.
- **Aşırı bloom/glow:** parlama yalnız turkuaz enerji kaynaklarında ve ölçülü kullanılır; her ışık kaynağı parlamaz.
- **Dokusal gürültü:** yüksek frekanslı noise, okunabilirliği düşürür; dokular temiz büyük formlarla kurulur.

## 4. Renk Paleti

### 4.1 Ana Dağılım

| Renk | Rol | Hedef Ekran Oranı |
|---|---|---|
| Kum Amberi | dünya yüzeyi, kum, ekonomi vurguları | %45–55 |
| Grafit | yapılar, teknoloji, UI çatısı, gölgeler | %25–35 |
| Turkuaz Enerji | oyuncu gücü, etkileşim, enerji | %5–10 |
| Tehlike Kırmızısı | düşman, hasar, tehlike alanları | ≤ %5 |
| Nötrler (kum kağıdı, ufuk sisi) | boşluk, UI zemini, geçişler | kalan |

60-30-10 kuralının bu oyuna uyarlanışı: amber+grafit zemin (~%80), turkuaz vurgu (~%10), kırmızı uyarı (≤%5). Oranlar sahne ekran görüntüleriyle periyodik olarak denetlenir.

### 4.2 Ton Rampaları

**Kum Amberi (KU):** KU-100 `#F6E3B8` (açık kum) · KU-200 `#EAC98F` · KU-300 `#D9A05B` (ana amber) · KU-400 `#B87F3E` · KU-500 `#8A5A28` (derin gölge)

**Grafit (GR):** GR-900 `#14161A` (en koyu) · GR-700 `#26282C` (ana panel) · GR-500 `#3E434B` · GR-300 `#5C636E` · GR-100 `#9AA3AF` (ikincil metin)

**Turkuaz Enerji (TE):** TE-100 `#C9F7EF` (çekirdek ışık) · TE-300 `#7FE9DC` (glow) · TE-500 `#2EC4B6` (ana) · TE-700 `#17958A` · TE-900 `#0E6B63` (derin)

**Tehlike Kırmızısı (TK):** TK-300 `#F09B93` · TK-500 `#D64541` (ana) · TK-700 `#A32C26` · TK-900 `#6E1C17`

**Nötrler:** Kum Kağıdı `#F4E9D2` (UI zemin, açık boşluk) · Ufuk Sisi `#C9B493` (ufuk geçişi) · Alacakaranlık Kum `#7A5F3E` (akşam atmosferi)

Tüm varlık renkleri bu rampalardan seçilir. Rampa dışına çıkma ihtiyacı, önce rampaya yeni bir ton eklenerek (bu dokümanda) çözülür; tekil işte özel renk üretilerek değil.

### 4.3 Kullanım Kuralları

- **Turkuaz yalnızca oyuncunun kontrolündeki güçte:** enerji kaynakları, yetenek efektleri, etkileşimli arayüz. Çevre dekoru ve düşman varlıkları turkuaz içermez.
- **Kırmızı asla dekorasyon değildir:** hasar, düşman, tehlike alanı ve kritik sayaçlar için rezerve edilmiştir. Kırmızı görünürken oyuncu risk altında olmalıdır.
- **UI metin kontrastı:** GR-700 panelde Kum Kağıdı `#F4E9D2` metin; metin/ikon kontrast oranı en az 4.5:1 (WCAG AA) hedeflenir.
- **Renk körlüğü:** kırmızı anlamları asla tek başına renkle taşınmaz; şekil/işaret ile ikili kodlanır (üçgen uyarı simgesi, kesik çizgi sınır). Turkuaz-kırmızı çifti, kırmızı-yeşil çiftinden erişilebilir bir ayrımdır.
- **Fotosensitif güvenlik:** hiçbir efekt 3 Hz'den hızlı yanıp sönmez.

## 5. Işık ve Atmosfer

Ana ışık yönü sol üstten gelen yüksek güneştir; izometrik sahnede form okunabilirliğini bu yön korur. Gölgeleme yumuşak ve düşük opaklıktır: karakterlerin altında blob gölge (yumuşak elips), binalarda yönü belli yumuşak gölge. sert gölge kenarı ve gerçek zamanlı gölge projeksiyonu mobil bütçe gereği kullanılmaz.

Rim ışık iki tipe ayrılır: karakter kenarlarında ince **amber** rim (güneş sıcaklığı), enerji varlıklarında **turkuaz** rim (yayılma ışığı). Rim kalınlığı ekranda 2–4 px'i geçmez; rim bir stil imzasıdır, ışık sahtesi değildir.

Atmosfer şeması, fırtına döngüsünü izler:

| Evre | Palet Eğilimi | Kontrast | Not |
|---|---|---|---|
| Şafak | amber yüksek, uzun gölge | orta | turkuaz enerji en parlak |
| Öğle | açık, düşük kontrast | düşük | okunabilirlik turkuaz/kırmızı işaretlerden gelir |
| Fırtına öncesi | grafit ağırlığı artar, doygunluk düşer | daralır | kırmızı uyarılar devreye girer |
| Fırtına | amber-grafit karışımı, görünürlük maskesi | dar | turkuaz işaretler parlaklığını korur |

Ufuk sisi `#C9B493` dünya kenarlarını yumuşatır; harita sınırı sert bir çizgi olarak değil, kum bulaşmış bir pusla bitiştirilir. Fırtınada okunabilirlik önceliğidir: atmosfer karanlığı, işaret renklerinin (TE-500, TK-500) parlaklığını asla yutmayacak kadar sınırlı tutulur.

## 6. Şekil Dili

Şekil dili, tarafsız bakışta bile taraf söylemelidir. **Oyuncu birimleri** yuvarlak, organik konturlu ve tam siluetlidir; güven veren hacim. **Düşmanlar** kırık kenarlı, açılı ve asimetriktir; siluetleri "kırılmış kum" metaforunu taşır. **Binalar** dikey güç silueti kurar: grafit iskelet + amber yüzey; işlev üstten okunur (kule dikey ve sivri, jeneratör yatay ve geniş). **Enerji** akışkan eğriler ve düğümlerle çizilir; hiçbir enerji formu sert açı içermez. **Tehlike alanları** kesik çizgi sınır + düşük opak kırmızı dolgu ile belirtilir.

Okunabilirlik ölçüsü: bir varlık %25 zoom'da (uzak taktik görünüm) bile sınıfını belli etmelidir. Bu ölçü, detay yoğunluğunun üst sınırını belirler: küçülünce kaybolan detay gereksiz detaydır.

## 7. Karakter ve Birim Tasarımı

Oranlar 4–4.5 kafa aralığındadır: stilize yarı gerçekçi; ne chibi ne realistik. Bu aralık izometrik kamera altında hem yüz ifadesi hem hareket okunabilirliği verir. Boy kontrastı sınıfları ayrıştırır: piyade referans boy ~200 tasarım px, motorlu birim ~1.6×, büyük yapılar 2.5–4×.

Sınıf kodlaması renkle yapılır: piyade sınıfı amber kuşak, mühendis/ağır sınıf grafit zırh, enerji taşıyıcılar turkuaz aksesuar. Aksesuarlar siluette de ayrıştırıcıdır (kule omuz, jeneratör sırt). Renk ve siluet birlikte okunduğunda, birim listesi karışıklığı imkânsız hale gelmelidir.

Gerekli görünümler: izometrik ana açı (tek açı, 2.5D standardı), seçim halkası altında duruş ve UI portresi için 3/4 yüz. Animasyon adları ve kare standartları ASSET_PIPELINE B.6'dadır.

## 8. Çevre ve Tile Tasarımı

Zemin tile'ları 2:1 elmas, 256×128 tasarım px; yükseklik kademeleri 64 px'tir. Yükseklik farkları siluet ve ton farkıyla okunur; aynı tile yüzeyinde kademeli ton geçişi kullanılır, keskin banding kullanılmaz.

Kum malzeme kuralları: büyük yumuşak ton geçişleri, düşük granülasyon, doku tekrarı hissi yok. Her tile tipi en az 3 varyant üretilir (ASSET_PIPELINE B.6 varyant harfleri) ve harita rastgele karıştırır. Kalıntılar ve yapılar grafit palettedir; kum, yapının dibini yarı-gömülü örter — "kum bulaşması" Dustbound'ın çevre imzasıdır ve tüm prop'larda beklenir.

3D ön render (karma boru hattı) çevre kuralları: tüm prop/bina modelleri tek Blender kamera kurulumuyla (ortografik, X=35.264°, Z=45° — ASSET_PIPELINE B.5) render edilir; tek ana ışık (sol üst, amber) + turkuaz rim; toon-lite materyal, düşük spesüler. Kenarlar render sonrası hafif kontrast geçişiyle netleştirilir. İki yöntemin (el çizimi + 3D render) aynı sahnede ayrışmaması için bu kurulum değişmez.

## 9. UI ve Tipografi

Panel dili: GR-700 zemin, 8/12 px köşe yarıçapı (küçük/büyük paneller), ince GR-500 kontur, Kum Kağıdı metin. Vurgu hiyerarşisi: amber (ekonomi/ödül), turkuaz (etkileşim/enerji), kırmızı (uyarı). Hiçbir UI öğesi palet rampası dışı renk kullanmaz; yarı saydam katmanlar Kum Kağıdı/GR-900 çiftinden türetilir.

Tipografi: Inter veya Noto Sans; **Türkçe glif seti zorunludur** (ş ğ İ ı ç ö ü Ç Ğ Ö Ü — kontrol listesi ASSET_PIPELINE B.9.3). Başlıkta semibold, gövdede regular; minimal font sayısı (en fazla 2 aile) tutulur. Boyut skalası: 16/18/22/28/36 tasarım px; daha küçük metin mobilde okunmaz, üretilmez.

İkonlar: dolu (filled) minimal stil; tek renk + turkuaz/amber vurgu; 24/32/48 px setleri üretılır. Dokunma hedefi en az 64×64 tasarım px; safe area (çentik) boşlukları HUD yerleşiminde korunur (ARCHITECTURE B.14). HUD yoğunluğu ilkesi: taktik sahne her zaman görünürlükte kalır; HUD, dünyanın üstünü kapatmaz.

## 10. VFX ve Parçacık

Enerji efektleri turkuaz rampasından (TE-300→TE-700) kurulur; add-blend glow yalnız çekirdek noktada. Kum efektleri amber rampa + yumuşak sprite; fırtına üç katmanlıdır: ön sis, orta kum sürüklenmesi, arka bulut şeridi. Hasar/tehlike efektleri kırmızıdır ve ölçülüdür: isabet flash'ı 200 ms'yi geçmez.

Parçacık bütçeleri ARCHITECTURE B.13'te bağlayıcıdır: entry cihazda aynı anda ≤ 150 parçacık. Bu nedenle efektler "az sprite, güçlü siluet" ilkesiyle tasarlanır; yoğunluk, parçacık sayısından değil sprite boyutundan gelir. Uzun ömürlü ambiyans parçacıkları (sürekli kum akıntısı) en düşük yoğunlukta sürekli çalışır ve fırtına katmanlarıyla ölçeklenir.

## 11. Referanslar

- **Hades** — izometrik sahneleme disiplini, rim ışık kullanımı, renk kodu ile okunabilirlik.
- **Bastion** — boyalı izometrik dünya sıcaklığı, elle boyalı dokunun gücü.
- **Into the Breach** — taktik okunabilirliğin zirvesi; renk kodu ile bilgi aktarımı, HUD mütevazılığı.
- **Frostpunk** — distopya atmosferi; ısı ve paletin hikâye anlatması.

Kural: referanslar ilham içindir; hiçbir varlık kopyalanmaz, izlenerek üretilmez. Bir varlık bir referansı "hatırlatıyor"sa, stil sütunlarından (Bölüm 2) geçirilerek Dustbound diline çevrilir.

## 12. Görsel Kabul Kontrol Listesi

Görsel iş, aşağıdaki listede tam puan almadan teslim edilmez:

- [ ] Tüm renkler Bölüm 4 rampalarından mı?
- [ ] Siluet testi: tek renk (siyah) dolgu ile varlık sınıfı ayırt edilebiliyor mu?
- [ ] %25 zoom (uzak taktik görünüm) okunabilirliği korunuyor mu?
- [ ] Kırmızı toplam sahne oranı %5'i aşıyor mu?
- [ ] Turkuaz yalnızca oyuncu gücü/etkileşiminde mi?
- [ ] Türkçe metin glifleri doğru görünüyor mu?
- [ ] Safe area boşlukları korunuyor mu?
- [ ] Parçacık bütçesi (entry ≤ 150) aşılmadı mı?
- [ ] Işık yönü (sol üst) ve rim kurallarına uyuldu mu?
