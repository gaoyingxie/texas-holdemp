extends Control
## 德州扑克主界面

const SUIT_SYMBOLS := ["♠", "♥", "♦", "♣"]
const RANK_SYMBOLS := ["?", "?", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]

# 预加载依赖（解决Godot 4类型解析顺序问题）


# 预加载依赖（解决Godot 4 class_name类型作为标识符的解析顺序问题）
const _PGR = preload("res://scripts/poker_game.gd")
const _CR = preload("res://scripts/card.gd")
const _PR = preload("res://scripts/player.gd")

var game
var player
var ai1
var ai2
var is_game_over: bool = false
var show_ai_hands: bool = false


func _ready() -> void:
    _setup_game()

    $ActionPanel/FoldBtn.pressed.connect(_on_fold)
    $ActionPanel/CheckBtn.pressed.connect(_on_check)
    $ActionPanel/CallBtn.pressed.connect(_on_call)
    $ActionPanel/RaiseBtn.pressed.connect(_on_raise)
    $ActionPanel/AllInBtn.pressed.connect(_on_all_in)
    $ActionPanel/NextHandBtn.pressed.connect(_on_next_hand)

    _update_ui()


func _setup_game() -> void:
    game = _PGR.new()
    player = game.add_player("你", 1000)
    ai1 = game.add_player("AI-1", 1000)
    ai2 = game.add_player("AI-2", 1000)
    game.start_new_hand()
    is_game_over = false
    show_ai_hands = false
    $ResultLabel.visible = false
    $ActionPanel/NextHandBtn.disabled = true
    _update_ui()


func _card_text(card) -> Dictionary:
    if card == null:
        return {"text": "?", "color": Color(1, 1, 1, 1)}
    var suit_sym = SUIT_SYMBOLS[card.suit]
    var rank_sym = RANK_SYMBOLS[card.rank]
    var color = Color(0.1, 0.1, 0.1, 1)  # 黑桃/梅花黑色
    if card.suit == 1 or card.suit == 2:
        color = Color(1, 0.3, 0.3, 1)  # 红心/方块红色
    return {"text": rank_sym + suit_sym, "color": color}


func _update_community_cards() -> void:
    var cards = game.community
    for i in range(5):
        var card_node = $CommunityCards.get_child(i)
        var label = card_node.get_node("Label")
        if i < cards.size():
            var c = cards[i]
            var info = _card_text(c)
            label.text = info.text
            label.modulate = info.color
            _style_card(card_node, c)
        else:
            label.text = "?"
            label.modulate = Color(0.5, 0.5, 0.5, 1)
            card_node.remove_theme_color_override("background_color")
            var style = StyleBoxFlat.new()
            style.bg_color = Color(0.2, 0.25, 0.2, 0.8)
            style.corner_radius_top_left = 4
            style.corner_radius_top_right = 4
            style.corner_radius_bottom_right = 4
            style.corner_radius_bottom_left = 4
            card_node.add_theme_stylebox_override("panel", style)


func _style_card(card_node: Panel, card) -> void:
    var style = StyleBoxFlat.new()
    style.bg_color = Color(1, 1, 1, 1)
    style.corner_radius_top_left = 4
    style.corner_radius_top_right = 4
    style.corner_radius_bottom_right = 4
    style.corner_radius_bottom_left = 4
    card_node.add_theme_stylebox_override("panel", style)


func _update_player_hand() -> void:
    var cards = player.hand
    for i in range(2):
        var card_node = $PlayerHand.get_child(i)
        var label = card_node.get_node("Label")
        if i < cards.size():
            var c = cards[i]
            var info = _card_text(c)
            label.text = info.text
            label.modulate = info.color
            _style_card(card_node, c)
        else:
            label.text = "?"
            label.modulate = Color(0.5, 0.5, 0.5, 1)


func _update_ai_hands() -> void:
    # 非结算时AI牌盖住，结算或ALL IN后全亮
    var reveal = is_game_over or show_ai_hands
    # Update AI-1 hand display
    var ai1_hand_nodes = $AI1Hand.get_children()
    for i in range(2):
        var card_node = ai1_hand_nodes[i]
        var label = card_node.get_node("Label")
        if reveal and i < ai1.hand.size():
            var c = ai1.hand[i]
            var info = _card_text(c)
            label.text = info.text
            label.modulate = info.color
            _style_card(card_node, c)
        else:
            label.text = "?"
            label.modulate = Color(0.5, 0.5, 0.5, 1)

    # Update AI-2 hand display
    var ai2_hand_nodes = $AI2Hand.get_children()
    for i in range(2):
        var card_node = ai2_hand_nodes[i]
        var label = card_node.get_node("Label")
        if reveal and i < ai2.hand.size():
            var c = ai2.hand[i]
            var info = _card_text(c)
            label.text = info.text
            label.modulate = info.color
            _style_card(card_node, c)
        else:
            label.text = "?"
            label.modulate = Color(0.5, 0.5, 0.5, 1)


func _show_all_hands() -> void:
    # Show all players' cards during showdown
    _update_ai_hands()
    # 结果标签显示各玩家手牌
    var result_lines = []
    for p in [player, ai1, ai2]:
        if p.is_folded:
            result_lines.append(p.name + ": 弃牌")
        else:
            var hand_str = ""
            for c in p.hand:
                var info = _card_text(c)
                hand_str += info.text + " "
            result_lines.append(p.name + ": " + hand_str)
    var community_str = "公共: "
    for c in game.community:
        var info = _card_text(c)
        community_str += info.text + " "
    $ResultLabel.text = "\n".join(result_lines) + "\n" + community_str


func _update_ui() -> void:
    # 筹码
    $HUD/PlayerChips.text = "你: $%d" % player.chips
    $HUD/AI1Chips.text = "  AI-1: $%d" % ai1.chips
    $HUD/AI2Chips.text = "  AI-2: $%d" % ai2.chips
    $HUD/PotLabel.text = "  底池: $%d" % game.pot

    # 阶段
    var stage_names = ["Pre-flop", "Flop", "Turn", "River", "Showdown"]
    $ActionPanel/StageLabel.text = "阶段: " + stage_names[game.stage]

    # 公共牌
    _update_community_cards()

    # 玩家手牌
    _update_player_hand()

    # AI手牌（结算前隐藏）
    _update_ai_hands()

    # 按钮状态（ALL IN后无需操作）
    var is_my_turn = not player.is_folded and not is_game_over and not player.is_all_in
    $ActionPanel/FoldBtn.disabled = not is_my_turn
    $ActionPanel/CheckBtn.disabled = not is_my_turn
    $ActionPanel/CallBtn.disabled = not is_my_turn
    $ActionPanel/RaiseBtn.disabled = not is_my_turn
    $ActionPanel/AllInBtn.disabled = not is_my_turn

    # Call 按钮显示
    if game.current_bet > 0:
        $ActionPanel/CallBtn.text = "跟注 $%d" % game.current_bet
    else:
        $ActionPanel/CallBtn.text = "过牌 (Check)"


func _on_fold() -> void:
    if is_game_over or player.is_folded or player.is_all_in: return
    game.do_fold(player)
    _ai_turn()


func _on_check() -> void:
    if is_game_over or player.is_folded or player.is_all_in: return
    game.do_check(player)
    _ai_turn()


func _on_call() -> void:
    if is_game_over or player.is_folded or player.is_all_in: return
    if game.current_bet > 0:
        game.do_call(player)
    else:
        game.do_check(player)
    _ai_turn()


func _on_raise() -> void:
    if is_game_over or player.is_folded or player.is_all_in: return
    # 简化：加注到 current_bet + 50
    var raise_to = game.current_bet + 50
    if raise_to > player.chips:
        raise_to = player.chips
    if raise_to > 0:
        game.do_raise(player, raise_to)
    _ai_turn()


func _on_all_in() -> void:
    if is_game_over or player.is_folded or player.is_all_in: return
    game.do_all_in(player)
    show_ai_hands = true
    _ai_turn()


func _ai_turn() -> void:
    # 简单AI：随机行动
    for p in [ai1, ai2]:
        if p.is_folded or is_game_over: continue
        await get_tree().create_timer(0.6).timeout
        _ai_action(p)
        _update_ui()
        # 每步行动后检查是否结束本轮
        if _should_end_round():
            break
    _check_round_end()


func _ai_action(p) -> void:
    var rng = RandomNumberGenerator.new()
    var roll = rng.randf()
    if roll < 0.15:
        game.do_fold(p)
    elif roll < 0.4:
        if game.current_bet > 0:
            game.do_call(p)
        else:
            game.do_check(p)
    else:
        if p.chips > game.current_bet + 20:
            game.do_raise(p, game.current_bet + 20)
        else:
            game.do_all_in(p)
    _update_ui()


func _check_round_end() -> void:
    var active = game.active_players()
    if active.size() <= 1:
        _end_hand_early()
        return
    if game.stage == _PGR.GameStage.SHOWDOWN:
        return
    if _should_end_round():
        _advance_stage()


func _should_end_round() -> bool:
    # ALL IN 或所有活跃玩家都已下注相等（简化：只剩all-in玩家时结束）
    var active = game.active_players()
    var has_non_all_in = false
    for p in active:
        if not p.is_all_in and not p.is_folded:
            has_non_all_in = true
            break
    return not has_non_all_in  # 没有还需要行动的玩家就结束


func _all_bet_equal() -> bool:
    var active = game.active_players()
    if active.size() <= 1: return true
    for p in active:
        if p.is_all_in: continue
        # 简化：检查 current_bet 是否所有人已处理
    return true


func _advance_stage() -> void:
    game.next_stage()
    if game.stage == _PGR.GameStage.SHOWDOWN:
        game.resolve_showdown()
        is_game_over = true
        _show_result()
    _update_ui()


func _end_hand_early() -> void:
    var active = game.active_players()
    if active.is_empty(): return
    var winner = active[0]
    game.award_pot(winner)
    game.winner_name = winner.name
    is_game_over = true
    _show_result()


func _show_result() -> void:
    if game.winner_name == "":
        $ResultLabel.text = "平局！"
    else:
        $ResultLabel.text = game.winner_name + " 获胜！ +$%d" % game.pot
    $ResultLabel.visible = true
    $ActionPanel/NextHandBtn.disabled = false
    _show_all_hands()
    _update_ui()


func _on_next_hand() -> void:
    # 如果有人破产
    if player.chips <= 0 or (ai1.chips <= 0 and ai2.chips <= 0):
        _setup_game()
        return
    if ai1.chips <= 0:
        game.players.erase(ai1)
    if ai2.chips <= 0:
        game.players.erase(ai2)
    game.start_new_hand()
    is_game_over = false
    show_ai_hands = false
    $ResultLabel.visible = false
    $ActionPanel/NextHandBtn.disabled = true
    _update_ui()
