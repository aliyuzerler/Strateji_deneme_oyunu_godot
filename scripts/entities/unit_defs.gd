class_name UnitDefs
extends RefCounted
## Faz 05 birim tanimlari (kod tabanli; production'da resources/defs altinda
## def_*.tres olacak). Hiz px/sn (tasarim olcegi), menzil px.
##
## DUSMAN FARKLILASTIRMASI (gorev geregi):
##   runner  — hizli + kirilgan, melee zigzag takip
##   brute   — yavas + dayanikli, telegrafl alan vurusu (slam)
##   spitter — orta hiz, menzilli; guvenli bantta durup strafe yapar
##
## Tum sheet'ler GECICI (TMP rozetli) placeholder'dir; 2x olcekli uretildi,
## sahnede 0.5 scale cizilir (ASSET_PIPELINE B.3).

const SHEET_DIR := "res://assets/art/characters/"


static func _sheets(unit: String) -> Dictionary:
        return {
                "idle": {"path": SHEET_DIR + "tex_unit_%s_idle_sheet_01.png" % unit, "frames": 2, "fps": 2.5, "loop": true},
                "walk": {"path": SHEET_DIR + "tex_unit_%s_walk_sheet_01.png" % unit, "frames": 4, "fps": 9.0, "loop": true},
                "attack": {"path": SHEET_DIR + "tex_unit_%s_attack_sheet_01.png" % unit, "frames": 3, "fps": 12.0, "loop": false},
                "hurt": {"path": SHEET_DIR + "tex_unit_%s_hurt_sheet_01.png" % unit, "frames": 1, "fps": 10.0, "loop": false},
                "death": {"path": SHEET_DIR + "tex_unit_%s_death_sheet_01.png" % unit, "frames": 3, "fps": 6.0, "loop": false},
        }


static func player_def() -> Dictionary:
        return {
                "id": "player", "display": "Kum Yürüyücüsü", "team": "player",
                "max_hp": 120, "speed": 340.0, "damage": 14, "cooldown": 0.65,
                "range": 560.0, "bolt_speed": 980.0, "knockback": 140.0,
                # Faz 06 yetenekleri: Enerji Patlamasi (radyal) + Atılım (dash)
                "burst_count": 10, "burst_damage": 10, "burst_cd": 8.0,
                "burst_speed": 780.0, "dash_dist": 260.0, "dash_cd": 5.0,
                "dash_speed": 1500.0,
                "cell": Vector2i(400, 460), "sheets": _sheets("player"),
        }


static func runner_def() -> Dictionary:
        return {
                "id": "runner", "display": "Kum Koşucusu", "team": "enemy",
                "max_hp": 40, "speed": 300.0, "damage": 7, "cooldown": 0.9,
                "range": 78.0, "aggro": 1400.0, "behavior": "melee",
                "knockback": 90.0, "cell": Vector2i(240, 300),
                "sheets": _sheets("runner"),
        }


static func brute_def() -> Dictionary:
        return {
                "id": "brute", "display": "Grit Muhafız", "team": "enemy",
                "max_hp": 240, "speed": 95.0, "damage": 24, "cooldown": 2.2,
                "range": 150.0, "slam_radius": 140.0, "windup": 0.8,
                "aggro": 1000.0, "behavior": "slam", "knockback": 40.0,
                "cell": Vector2i(460, 560), "sheets": _sheets("brute"),
        }


static func spitter_def() -> Dictionary:
        return {
                "id": "spitter", "display": "Fırtına Salyası", "team": "enemy",
                "max_hp": 70, "speed": 150.0, "damage": 9, "cooldown": 1.5,
                "range": 540.0, "band_min": 340.0, "band_max": 540.0,
                "bolt_speed": 640.0, "aggro": 1400.0, "behavior": "ranged",
                "knockback": 120.0, "cell": Vector2i(320, 420),
                "sheets": _sheets("spitter"),
        }


static func enemy_defs() -> Array[Dictionary]:
        return [runner_def(), brute_def(), spitter_def()]
