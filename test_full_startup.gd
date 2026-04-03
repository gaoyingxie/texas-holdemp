extends SceneTree

func _init():
    print("=== Stage 1: Load scene ===")
    var scene = load("res://scenes/main.tscn")
    print("=== Stage 2: Instantiate ===")
    var inst = scene.instantiate()
    print("=== Stage 3: Add to tree ===")
    root.add_child(inst)
    print("=== Stage 4: Set size ===")
    var main = inst as Control
    main.size = Vector2(1280, 720)
    print("=== Stage 5: _setup_game ===")
    main.call("_setup_game")
    print("=== Stage 6: _update_ui ===")
    main.call("_update_ui")
    print("=== Stage 7: Check AI hands ===")
    var ai1h = inst.get_node_or_null("AI1Hand")
    var ai2h = inst.get_node_or_null("AI2Hand")
    print("AI1Hand exists: ", ai1h != null)
    print("AI2Hand exists: ", ai2h != null)
    if ai1h:
        print("AI1Hand children: ", ai1h.get_children().map(func(n): return n.name))
    if ai2h:
        print("AI2Hand children: ", ai2h.get_children().map(func(n): return n.name))
    print("=== Stage 8: Advance stage to Flop ===")
    main.call("_advance_stage")
    main.call("_update_ui")
    print("=== Stage 9: Try Fold ===")
    main.call("_on_fold")
    main.call("_update_ui")
    print("=== ALL STAGES PASSED ===")
    quit()
