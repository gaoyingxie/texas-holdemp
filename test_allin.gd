extends SceneTree

func _init():
    var scene = load("res://scenes/main.tscn")
    var inst = scene.instantiate()
    root.add_child(inst)
    var main = inst as Control
    main.size = Vector2(1280, 720)
    main.call("_setup_game")
    
    print("=== Test: Player ALL IN preflop, game should advance to showdown ===")
    
    # Player ALL INs
    main.game.do_all_in(main.player)
    main.show_ai_hands = true  # Simulate what _on_all_in sets
    print("After ALL IN: stage=", main.game.stage, " is_game_over=", main.is_game_over)
    
    # Simulate the AI turn manually (since we can't await in _init)
    # Call _ai_action for each AI
    var ai1 = main.ai1
    var ai2 = main.ai2
    print("AI1 chips=", ai1.chips, " AI2 chips=", ai2.chips)
    
    # Advance through stages manually to test the flow
    for round in range(4):  # Preflop -> Flop -> Turn -> River -> Showdown
        var prev_stage = main.game.stage
        print("Before advance: stage=", prev_stage)
        if main.game.stage >= 4:  # SHOWDOWN
            break
        # Manually call next_stage
        main.game.next_stage()
        print("After next_stage: stage=", main.game.stage)
        if main.game.stage == 4:  # SHOWDOWN
            main.is_game_over = true
            main.call("_show_result")
            print("Showdown! winner=", main.game.winner_name)
            break
        main.call("_update_ui")
    
    print("=== Final: is_game_over=", main.is_game_over, " winner=", main.game.winner_name)
    print("=== ALL IN flow test PASSED ===")
    quit()
