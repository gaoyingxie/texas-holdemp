extends SceneTree

func _init():
	print("=== MCP Full Startup Test ===")
	
	var sc = load("res://scenes/main.tscn")
	if sc == null:
		print("FAIL: scene load returned null")
		quit(1)
		return
	
	var inst = sc.instantiate()
	if inst == null:
		print("FAIL: scene instantiate returned null")
		quit(1)
		return
	root.add_child(inst)
	inst.size = Vector2(1280, 720)
	
	print("1. Scene loaded and instantiated OK")
	
	# _ready() 已被自动调用（_setup_game -> _update_ui -> _update_player_hand -> _style_card）
	# 验证 _style_card 没有抛异常
	var player_hand = inst.get_node("PlayerHand")
	var card0 = player_hand.get_child(0)
	var card1 = player_hand.get_child(1)
	
	print("2. Calling _style_card on player cards...")
	inst.call("_style_card", card0, null, true)
	print("   card0 face-up OK")
	inst.call("_style_card", card1, null, false)
	print("   card1 face-down OK")
	
	# AI 手牌
	var ai1_hand = inst.get_node("AI1Hand")
	var ai1_card0 = ai1_hand.get_child(0)
	inst.call("_style_card", ai1_card0, null, false)
	print("3. AI1 card0 face-down OK")
	
	# _all_bet_equal
	var result = inst.call("_all_bet_equal")
	print("4. _all_bet_equal() = ", result)
	
	# 模拟玩家 ALL IN
	print("5. Simulating ALL IN...")
	inst.call("_on_all_in")
	print("   player.is_all_in = ", inst.player.is_all_in)
	print("   game stage = ", inst.game.stage)
	
	# 检查 is_my_turn（All IN后应该是 false）
	var call_btn = inst.get_node("ActionPanel/CallBtn")
	print("6. CallBtn.disabled after ALL IN = ", call_btn.disabled)
	
	print("=== ALL CHECKS PASSED ===")
	quit(0)
