class_name ArenaTilesetBuilder
extends RefCounted
## Kanit sahnesi TileSet kurucusu. Production'da TileSet .tres ile yonetilir;
## burada kodla kurulmasi test sahnesine ozeldir (worklog'a islenmistir).
## Tile dokulari 1x (256x128) calisma zamanindadir; kaynak 2x raw klasorundedir.

const TILE_SIZE := Vector2i(256, 128)
const BASE_SOURCE_ID: int = 100


static func build(tile_textures: Array[Texture2D]) -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	tile_set.tile_layout = TileSet.TILE_LAYOUT_STACKED
	tile_set.tile_size = TILE_SIZE
	for i in tile_textures.size():
		var source := TileSetAtlasSource.new()
		source.texture = tile_textures[i]
		source.texture_region_size = TILE_SIZE
		source.create_tile(Vector2i.ZERO)
		tile_set.add_source(source, BASE_SOURCE_ID + i)
	return tile_set
