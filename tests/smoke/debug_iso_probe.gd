extends SceneTree
## Godot izometrik TileMapLayer izdusumunu kesif: gercek formulu turet.


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	var ts := TileSet.new()
	ts.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	ts.tile_layout = TileSet.TILE_LAYOUT_STACKED
	ts.tile_size = Vector2i(256, 128)
	var src := TileSetAtlasSource.new()
	src.texture = load("res://assets/art/environment/tiles/tex_env_sand_a_01.png")
	src.texture_region_size = Vector2i(256, 128)
	src.create_tile(Vector2i.ZERO)
	ts.add_source(src, 100)

	var layer := TileMapLayer.new()
	layer.tile_set = ts
	root.add_child(layer)
	await process_frame

	print("--- map_to_local ---")
	for c in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1),
			Vector2i(2, 0), Vector2i(0, 2), Vector2i(-1, 0), Vector2i(3, 1),
			Vector2i(2, 2), Vector2i(-2, 3)]:
		print(c, " -> ", layer.map_to_local(c))

	print("--- local_to_map ---")
	for p in [Vector2(0, 0), Vector2(128, 64), Vector2(256, 0), Vector2(0, 128),
			Vector2(-128, 64), Vector2(64, 32), Vector2(452.3, 215.55),
			Vector2(1000, 500)]:
		print(p, " -> ", layer.local_to_map(p))

	print("--- tile_y_sort_origin / texture_origin varsayilanlari ---")
	print("tile_size: ", ts.tile_size)
	quit(0)
