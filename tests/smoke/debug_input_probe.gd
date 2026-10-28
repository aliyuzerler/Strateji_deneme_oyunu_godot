extends SceneTree
## Girdi dagitimi tesih probedi: push_input yolu _unhandled_input'a ulasiyor mu?


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	var arena: TestArena = (load("res://scenes/game/test_arena.tscn") as PackedScene).instantiate()
	root.add_child(arena)
	await process_frame
	await process_frame

	# genel dinleyici: herhangi bir unhandled input dusuyor mu?
	var probe := Node.new()
	probe.set_script(load("res://tests/smoke/input_probe_node.gd"))
	root.add_child(probe)
	await process_frame

	var target_world: Vector2 = arena.ground_layer.map_to_local(Vector2i(5, 6))
	var canvas_xform: Transform2D = root.get_canvas_transform()
	var screen: Vector2 = canvas_xform * target_world
	print("canvas_xform.origin=", canvas_xform.origin, " scale=", canvas_xform.get_scale())
	print("target_world=", target_world, " screen=", screen)
	print("viewport visible_rect=", root.get_visible_rect(), " size=", root.size)

	var press := InputEventScreenTouch.new()
	press.index = 0
	press.pressed = true
	press.position = screen
	root.push_input(press)
	await process_frame
	var release := InputEventScreenTouch.new()
	release.index = 0
	release.pressed = false
	release.position = screen
	root.push_input(release)
	await process_frame
	await process_frame

	print("probe events: ", probe.received_count, " son tur: ", probe.last_types)
	print("arena input touch count: ", arena.input_node.debug_touch_count)
	print("player moving: ", arena.player.moving)
	quit(0)
