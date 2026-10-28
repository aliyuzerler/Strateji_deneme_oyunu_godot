class_name IsoMath
extends RefCounted
## Izometrik 2:1 elmas koordinat donusumleri (ARCHITECTURE B.7.3).
##
## KONVANSIYON: Godot TileSet TILE_SHAPE_ISOMETRIC + TILE_LAYOUT_STACKED
## adreslemesidir (debug_iso_probe.gd ile 4.7.2'de dogrulanmistir):
##   merkez(cx, cy) = (128 + 256*cx + 128*(cy & 1), 64 + 64*cy)
## Yani hucre (0,0) dokusu kutusunun merkezi lokal (128, 64)'tedir ve
## tek satirlar yarim karo (128 px) yatay kaymistir. Elmas sahipligi:
##   |dx|/128 + |dy|/64 <= 1
##
## Tasarim olcusu: tile 256x128 (ASSET_PIPELINE B.3). Saf fonksiyonlardir;
## unit test zorunlulugu TESTING B.3'tedir.

const TILE_W: int = 256
const TILE_H: int = 128
const HALF_W: float = 128.0
const HALF_H: float = 64.0


## Hucre kordinatini katman-lokal dunya konumuna (hucre MERKEZI) cevirir.
static func map_to_world(cell: Vector2i) -> Vector2:
	var x := HALF_W + cell.x * TILE_W + (cell.y & 1) * HALF_W
	var y := HALF_H * (cell.y + 1.0)
	return Vector2(x, y)


## Dunya konumunu iceren hucreyi dondurur (elmas icindekiler dahil).
## Yontem: dogrulanmis elmas-izdusum (u,v) secimi yapilir, ardindan Godot
## stacked adreslemesine cevrilir:  cy = i + j - 1,  cx = (i - j - 1 - (cy & 1)) / 2.
static func world_to_map(world: Vector2) -> Vector2i:
	var a := world.x / HALF_W
	var b := world.y / HALF_H
	var i := int(floor((a + b) * 0.5 + 0.5))
	var j := int(floor((b - a) * 0.5 + 0.5))
	var cy := i + j - 1
	var cx := (i - j - 1 - (cy & 1)) >> 1  # terim her zaman cifttir; tam bolme
	return Vector2i(cx, cy)
