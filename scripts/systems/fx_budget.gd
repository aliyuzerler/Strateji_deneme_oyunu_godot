class_name FXBudget
extends Node
## Faz 06: efekt butcesi yoneticisi.
## Gorevler:
##   1) AKTIF EFEKT SINIRLARI — kucuk, kendini temizleyen efekt guvenli ust
##      sinirlarla spawn edilir (ART_DIRECTION: efektler sahneyi kapatmamali;
##      ARCHITECTURE B.13 butce disiplini).
##   2) OTOMATIK KALITE — kayan FPS ornekleme ile YUKSEK/ORTA/DUSUK seviye;
##      dusuk seviyede kozmetik spawn olasiliklari ve kume sayilari kuculur.
##   3) OL Cum — stats() ile HUD/gelistirici paneli ve bench ciktisi besler.
##
## Sayim yontemi: slot sayaci yerine "izlenen ebeveyn cocugu sayimi".
## Efekt dugumleri kendi tween'leriyle queue_free olur; sayim her istekte
## cocuk sayisindan yapilir -> sizinti (leak) riski yoktur.

signal quality_changed(level: int)

enum Quality { HIGH, MEDIUM, LOW }

const CAP_FX := 64          # toz/parlama/halka gibi dunya efektleri
const CAP_LABEL := 16       # hasar/toplama etiketleri
const CAP_TRAIL := 28       # mermi iz noktalari
const CAP_ORB := 40         # XP/hurda toplama nesneleri

const SAMPLE_INTERVAL := 0.5
const FPS_HIGH := 50.0
const FPS_MED := 32.0
const DWELL := 3.0          # kalite degisimleri arasi min. sure (terleme onler)

## -1 = otomatik; yoksa sabit seviye (deterministik test/ekran goruntusu)
var force_quality := -1
var enabled := true

var quality: int = Quality.HIGH
var _parents := {}          # kind -> Array[Node]
var _sample_acc := 0.0
var _fps_sum := 0.0
var _fps_n := 0
var _fps_avg := 0.0
var _dwell := 0.0


func _process(delta: float) -> void:
        if force_quality >= 0:
                _set_quality(force_quality)
                return
        _dwell = maxf(_dwell - delta, 0.0)
        _sample_acc += delta
        var fps := Performance.get_monitor(Performance.TIME_FPS)
        _fps_sum += fps
        _fps_n += 1
        if _sample_acc < SAMPLE_INTERVAL:
                return
        _fps_avg = _fps_sum / maxf(float(_fps_n), 1.0)
        _fps_sum = 0.0
        _fps_n = 0
        _sample_acc = 0.0
        if _dwell > 0.0:
                return
        if _fps_avg < FPS_MED and quality != Quality.LOW:
                _set_quality(Quality.LOW)
        elif _fps_avg < FPS_HIGH and quality == Quality.HIGH:
                _set_quality(Quality.MEDIUM)
        elif _fps_avg >= FPS_HIGH and quality != Quality.HIGH and _dwell <= 0.0:
                _set_quality(Quality.HIGH)


## Efekt ebeveynlerini kaydet: kind -> dugum(ler).
## "fx" ve "label" havuzu AirFx; "ground" halkalari GroundFx; "trail" AirFx;
## "orb" LootLayer. Aynı dugum birden fazla kind'a kaydedilebilir.
func register_parent(kind: String, node: Node) -> void:
        if not _parents.has(kind):
                _parents[kind] = []
        if not _parents[kind].has(node):
                _parents[kind].append(node)


## Tip-duyarli sayim: ayni ebeveyn birden fazla tur icin kullanilabilir
## (AirFx'te etiket+efekt+iz birlikte yasar). "label" yalniz Label, "fx"/
## "trail" yalniz Sprite2D, "orb" tum cocuklari sayar — boylece mermi/iz
## yognasi etiket butcesini yutamaz.
func _count(kind: String) -> int:
        var total := 0
        for p in _parents.get(kind, []):
                if not is_instance_valid(p):
                        continue
                if kind == "label":
                        for c in p.get_children():
                                if c is Label:
                                        total += 1
                elif kind == "orb":
                        total += p.get_child_count()
                else:
                        for c in p.get_children():
                                if c is Sprite2D:
                                        total += 1
        return total


func cap_for(kind: String) -> int:
        match kind:
                "label":
                        return CAP_LABEL
                "trail":
                        return CAP_TRAIL
                "orb":
                        return CAP_ORB
                _:
                        return CAP_FX


## Yeni efekt icin izin: turun butcesi ve genel kalite uygunsa true.
func can_spawn(kind: String) -> bool:
        if not enabled:
                return false
        return _count(kind) < cap_for(kind)


## Kozmetik spawn olasiligi carpani (kaliteye gore).
func spawn_prob() -> float:
        match quality:
                Quality.MEDIUM:
                        return 0.75
                Quality.LOW:
                        return 0.45
                _:
                        return 1.0


## Kume efekt sayisini kaliteye gore kirpar (toz bulutu, patlama halkasi).
func burst_count(base: int) -> int:
        match quality:
                Quality.MEDIUM:
                        return maxi(2, int(round(base * 0.66)))
                Quality.LOW:
                        return maxi(1, int(round(base * 0.5)))
                _:
                        return base


func _set_quality(level: int) -> void:
        if quality == level:
                return
        quality = level
        _dwell = DWELL
        quality_changed.emit(level)


func stats() -> Dictionary:
        return {
                "quality": ["YUKSEK", "ORTA", "DUSUK"][clampi(quality, 0, 2)],
                "fx": _count("fx"),
                "labels": _count("label"),
                "trails": _count("trail"),
                "orbs": _count("orb"),
                "fps_avg": snappedf(_fps_avg, 0.1),
                "caps": "%d/%d/%d/%d" % [CAP_FX, CAP_LABEL, CAP_TRAIL, CAP_ORB],
        }
