extends SceneTree

func _init():
    var scene = load("res://scenes/main.tscn")
    var inst = scene.instantiate()
    print("Scene instantiated OK")
    root.add_child(inst)
    print("Added to tree OK")
    
    var main = inst as Control
    main.size = Vector2(1280, 720)
    print("Set size OK")
    
    # Try calling _setup_game
    main.call("_setup_game")
    print("_setup_game OK")
    
    # Try _update_ui
    main.call("_update_ui")
    print("_update_ui OK")
    
    print("=== ALL OK ===")
    quit()
