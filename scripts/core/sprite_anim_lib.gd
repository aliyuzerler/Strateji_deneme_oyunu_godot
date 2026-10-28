class_name SpriteAnimLib
extends RefCounted
## Sheet tabanli 8 yonlu animasyon kutuphanesi (Faz 05).
##
## Sheet yerlesimi: satir = yon (E, SE, S, SW, W, NW, N, NE), sutun = kare.
## Godot ekran acisi: 0 = +x (dogu), y asagi, pozitif aci saat yonu.
## Hucre pivotu: ayak-zemin temasi (w/2, h-8) — ASSET_PIPELINE B.4.
## Dokular 2x uretildi; sahnede 0.5 scale cizilir (B.3).


const DIR_COUNT: int = 8

var cell := Vector2i.ZERO
var anims: Dictionary = {}
var _cache: Dictionary = {}


static func dir_index_from_angle(angle: float) -> int:
        return posmod(int(round(angle / (PI / 4.0))), DIR_COUNT)


func setup(cell_size: Vector2i, defs: Dictionary) -> void:
        cell = cell_size
        anims = defs
        _cache.clear()


func frame_count(anim: String) -> int:
        return int(anims[anim]["frames"])


func fps(anim: String) -> float:
        return float(anims[anim]["fps"])


func loops(anim: String) -> bool:
        return bool(anims[anim]["loop"])


func has_anim(anim: String) -> bool:
        return anims.has(anim)


func frame(anim: String, dir: int, frame_idx: int) -> AtlasTexture:
        if not _cache.has(anim):
                var def: Dictionary = anims[anim]
                var tex: Texture2D = load(def["path"])
                var cols := frame_count(anim)
                var list: Array = []
                for d in DIR_COUNT:
                        for f in cols:
                                var at := AtlasTexture.new()
                                at.atlas = tex
                                at.region = Rect2(f * cell.x, d * cell.y, cell.x, cell.y)
                                list.append(at)
                _cache[anim] = list
        var f2 := clampi(frame_idx, 0, frame_count(anim) - 1)
        var d2 := posmod(dir, DIR_COUNT)
        return _cache[anim][d2 * frame_count(anim) + f2]
