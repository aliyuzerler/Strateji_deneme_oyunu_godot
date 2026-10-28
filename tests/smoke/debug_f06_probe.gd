extends SceneTree
## Tesih: oyuncu hasar etiketi neden uretilmiyor?

func _initialize() -> void:
        await process_frame
        var packed: PackedScene = load("res://scenes/game/test_arena.tscn")
        var arena: TestArena = packed.instantiate()
        root.add_child(arena)
        await process_frame
        await process_frame
        arena.auto_wave.stop()
        var player: PlaceholderPlayer = arena.player
        print("hp=", player.hp, " invuln=", player.invuln, " dead=", player.dead,
                        " respawning=", player._respawning)
        player.invuln = 0.0
        player.take_hit(3, player.position + Vector2(40, 0))
        await process_frame
        await process_frame
        print("hp sonrasi=", player.hp)
        for c in arena.air_fx.get_children():
                print("air_fx cocuk: ", c.get_class(), " | script: ",
                                c.get_script().resource_path if c.get_script() else "-")
        print("budget labels=", arena.fx_budget._count("label"))
        quit(0)
