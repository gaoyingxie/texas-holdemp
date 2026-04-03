extends SceneTree

func _init():
    print("=== STEP 1: Load and instantiate scene ===")
    var scene = load("res://scenes/main.tscn")
    var inst = scene.instantiate()
    root.add_child(inst)
    var main = inst as Control
    main.size = Vector2(1280, 720)
    print("STEP 1 OK")
    
    print("=== STEP 2: _setup_game ===")
    main.call("_setup_game")
    print("STEP 2 OK")
    
    print("=== STEP 3: _update_ui ===")
    main.call("_update_ui")
    print("STEP 3 OK")
    
    print("=== STEP 4: Check all nodes exist ===")
    var required_nodes = [
        "Background", "HUD", "CommunityCards", "PlayerHand",
        "AI1Hand", "AI2Hand", "ActionPanel", "ResultLabel",
        "HUD/PlayerChips", "HUD/AI1Chips", "HUD/AI2Chips", "HUD/PotLabel",
        "CommunityCards/Card0/Label", "CommunityCards/Card1/Label",
        "PlayerHand/HandCard0/Label", "PlayerHand/HandCard1/Label",
        "AI1Hand/AICard0/Label", "AI1Hand/AICard1/Label",
        "AI2Hand/AICard0/Label", "AI2Hand/AICard1/Label",
        "ActionPanel/FoldBtn", "ActionPanel/CheckBtn",
        "ActionPanel/CallBtn", "ActionPanel/RaiseBtn", "ActionPanel/AllInBtn",
        "ActionPanel/StageLabel"
    ]
    for path in required_nodes:
        var node = inst.get_node_or_null(path)
        if node == null:
            print("ERROR: Node NOT FOUND: " + path)
        else:
            print("  OK: " + path)
    print("STEP 4 CHECK DONE")
    
    print("=== STEP 5: Simulate full game flow ===")
    # Preflop round
    for i in range(4):
        main.call("_on_call")  # player calls
    main.call("_update_ui")
    print("After preflop bets, stage=", main.game.stage)
    
    main.call("_advance_stage")
    main.call("_update_ui")
    print("After Flop, community cards=", main.game.community.size())
    
    main.call("_advance_stage")
    main.call("_update_ui")
    print("After Turn, community cards=", main.game.community.size())
    
    main.call("_advance_stage")
    main.call("_update_ui")
    print("After River, community cards=", main.game.community.size())
    
    main.call("_advance_stage")
    main.call("_update_ui")
    print("After Showdown, is_game_over=", main.is_game_over, " winner=", main.game.winner_name)
    
    print("=== ALL STEPS COMPLETE ===")
    quit()
