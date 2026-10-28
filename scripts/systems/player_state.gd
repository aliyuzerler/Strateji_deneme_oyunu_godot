class_name PlayerState
extends Node
## Faz 06: oyuncu ilerleme durumu — XP, seviye, hurda, kill ve hayatta kalma
## suresi. Seviye atlama "leveled" sinyalini uretir; arena oyunu duraklatip
## GameHud uzerinden yetenek secimi acar (gorev: "yetenek seciminde duraklat").
##
## Sure birikimi: Node varsayilan process_mode PAUSABLE -> duraklatmada
## kronometre durur (taktik duraklatma sureyi bozmaz).

signal xp_changed(xp: int, xp_next: int)
signal leveled(new_level: int)
signal scrap_changed(total: int)

## Seviye atlama kartlari (GameHud secim paneli). Uretimde def_*.tres olur.
const UPGRADE_POOL: Array[Dictionary] = [
        {"id": "damage", "name": "Enerji Çekirdeği", "desc": "Mermi hasarı +15%", "icon": "burst"},
        {"id": "speed", "name": "Kum Rüzgarı", "desc": "Hareket hızı +12%", "icon": "dash"},
        {"id": "cooldown", "name": "Soğutma Sargısı", "desc": "Tüm soğumalar -12%", "icon": "burst"},
        {"id": "vitality", "name": "Dayanıklı Deri", "desc": "Azami can +25 (dolar)", "icon": "mend"},
        {"id": "burst", "name": "Geniş Patlama", "desc": "Patlama mermisi +2", "icon": "burst"},
        {"id": "magnet", "name": "Mıknatıs Alanı", "desc": "Toplama alanı +30%", "icon": "mend"},
]

var xp := 0
var level := 1
var scrap := 0
var kills := 0
var survival_time := 0.0
var wave := 0
var rng := RandomNumberGenerator.new()


func _init() -> void:
        rng.seed = 20261028


func _process(delta: float) -> void:
        survival_time += delta


func xp_to_next() -> int:
        return 40 + (level - 1) * 25


func gain_xp(amount: int) -> void:
        if amount <= 0:
                return
        xp += amount
        var leveled_now := false
        while xp >= xp_to_next():
                xp -= xp_to_next()
                level += 1
                leveled_now = true
        xp_changed.emit(xp, xp_to_next())
        if leveled_now:
                leveled.emit(level)


func gain_scrap(amount: int) -> void:
        if amount <= 0:
                return
        scrap += amount
        scrap_changed.emit(scrap)


func add_kill() -> void:
        kills += 1


## Dusman tipine gore XP odulu (UnitDefs ile ayni id'ler).
func xp_for(unit_id: String) -> int:
        match unit_id:
                "runner":
                        return 12
                "brute":
                        return 30
                "spitter":
                        return 18
                _:
                        return 8


## Dusman tipine gore hurda odulu (rng tohumlu, deterministik akis).
func scrap_for(unit_id: String) -> int:
        match unit_id:
                "runner":
                        return rng.randi_range(1, 2)
                "brute":
                        return rng.randi_range(3, 5)
                "spitter":
                        return rng.randi_range(2, 3)
                _:
                        return 1


func format_time() -> String:
        var t := int(survival_time)
        return "%02d:%02d" % [t / 60, t % 60]


func reset() -> void:
        xp = 0
        level = 1
        scrap = 0
        kills = 0
        survival_time = 0.0
        wave = 0
        xp_changed.emit(xp, xp_to_next())
        scrap_changed.emit(scrap)
