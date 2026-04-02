extends SceneTree
## 德州扑克完整集成测试 — 覆盖 UI层 ↔ 核心层 所有接口
## TDD: 先写测试 RED → 写实现 GREEN

var _passed := 0
var _failed := 0


# ═══════════════════════════════════════════════════════
#  CORE CLASSES (内联所有scripts/，保证类型一致)
# ═══════════════════════════════════════════════════════

class T_PC:
    var suit: int; var rank: int
    func _init(s: int, r: int): suit = s; rank = r
    func _to_string() -> String:
        return str(rank) + ["S","H","D","C"][suit]


class T_Deck:
    var _cards: Array = []
    func _init():
        for s in range(4):
            for r in range(2, 15): _cards.append(T_PC.new(s, r))
    func shuffle():
        var rng := RandomNumberGenerator.new()
        for i in range(_cards.size()):
            var j := rng.randi_range(i, _cards.size() - 1)
            var tmp = _cards[i]; _cards[i] = _cards[j]; _cards[j] = tmp
    func deal(count: int) -> Array:
        var hand: Array = []
        for i in range(count):
            if _cards.is_empty(): break
            hand.append(_cards.pop_back())
        return hand
    func remaining() -> int: return _cards.size()


class T_HE:
    func evaluate(cards: Array) -> Array:
        var best = _best_five(cards)
        var rc = _rank_counts(best)
        var flush = _is_flush(best)
        var si = _is_straight(best)
        var is_str: bool = si[0] as bool
        var sh: int = si[1] as int
        if flush and is_str and sh == 14: return [9, [14]]
        if flush and is_str: return [8, [sh]]
        if _has_count(rc, 4):
            var q := _rank_of_count(rc, 4)
            return [7, [q, _max_kicker_one(rc, [q])]]
        if _has_count(rc, 3) and _has_count(rc, 2):
            return [6, [_rank_of_count(rc, 3), _rank_of_count(rc, 2)]]
        if flush: return [5, _sorted_ranks(best)]
        if is_str: return [4, [sh]]
        if _has_count(rc, 3):
            var t3 := _rank_of_count(rc, 3)
            return [3, [t3] + _top_kickers(rc, [t3], 2)]
        if _count_values_equal(rc, 2) == 2:
            var pairs := _ranks_of_count(rc, 2)
            pairs.sort()
            pairs.reverse()
            return [2, pairs + _top_kickers(rc, pairs, 1)]
        if _has_count(rc, 2):
            var pr := _rank_of_count(rc, 2)
            return [1, [pr] + _top_kickers(rc, [pr], 3)]
        return [0, _top_kickers(rc, [], 5)]

    func compare(h1: Array, h2: Array) -> int:
        return _cmp(evaluate(h1), evaluate(h2))

    func best_five(cards: Array) -> Array:
        return _best_five(cards)

    func _best_five(cards: Array) -> Array:
        if cards.size() <= 5:
            return cards.duplicate()
        var best_score: Array = []
        var best_hand: Array = []
        var n := cards.size()
        for i in range(n - 4):
            for j in range(i + 1, n - 3):
                for k in range(j + 1, n - 2):
                    for l in range(k + 1, n - 1):
                        for m in range(l + 1, n):
                            var combo: Array = [cards[i], cards[j], cards[k], cards[l], cards[m]]
                            var sc: Array = evaluate(combo)
                            if best_score.is_empty() or _cmp(sc, best_score) > 0:
                                best_score = sc
                                best_hand = combo
        return best_hand

    func _cmp(a: Array, b: Array) -> int:
        if a[0] != b[0]:
            return a[0] - b[0]
        var ta: Array = a[1] as Array
        var tb: Array = b[1] as Array
        for i in range(min(ta.size(), tb.size())):
            if ta[i] != tb[i]:
                return ta[i] - tb[i]
        return 0

    func _rank_counts(cards: Array) -> Dictionary:
        var d: Dictionary = {}
        for c in cards:
            d[c.rank] = d.get(c.rank, 0) + 1
        return d

    func _has_count(rc: Dictionary, target: int) -> bool:
        for v in rc.values():
            if v == target:
                return true
        return false

    func _count_values_equal(rc: Dictionary, target: int) -> int:
        var cnt := 0
        for v in rc.values():
            if v == target:
                cnt += 1
        return cnt

    func _is_flush(cards: Array) -> bool:
        if cards.size() < 5:
            return false
        var s: int = cards[0].suit
        for c in cards:
            if c.suit != s:
                return false
        return true

    func _is_straight(cards: Array) -> Array:
        var ranks: Array = []
        for c in cards:
            ranks.append(c.rank)
        var unique: Array[int] = []
        for r in ranks:
            var ri: int = r as int
            if not (ri in unique):
                unique.append(ri)
        unique.sort()
        if unique.size() < 5:
            return [false, 0]
        if unique == [2, 3, 4, 5, 14]:
            return [true, 5]
        for start in range(unique.size() - 4):
            var ok := true
            for off in range(4):
                if unique[start + off + 1] - unique[start + off] != 1:
                    ok = false
                    break
            if ok:
                return [true, unique[start + 4]]
        return [false, 0]

    func _rank_of_count(rc: Dictionary, target: int) -> int:
        for r in rc:
            if rc[r] == target:
                return r as int
        return 0

    func _ranks_of_count(rc: Dictionary, target: int) -> Array:
        var result: Array = []
        for r in rc:
            if rc[r] == target:
                result.append(r as int)
        return result

    func _max_kicker_one(rc: Dictionary, exclude: Array) -> int:
        var best := 0
        for r in rc:
            var ri: int = r as int
            if not (ri in exclude) and ri > best:
                best = ri
        return best

    func _top_kickers(rc: Dictionary, exclude: Array, n: int) -> Array:
        var all: Array = []
        for r in rc:
            var ri: int = r as int
            if not (ri in exclude):
                all.append(ri)
        all.sort()
        all.reverse()
        return all.slice(0, n)

    func _sorted_ranks(cards: Array) -> Array:
        var ranks: Array = []
        for c in cards:
            ranks.append(c.rank)
        ranks.sort()
        ranks.reverse()
        return ranks.slice(0, 5)



# ═══════════════════════════════════════════════════════
#  POKER GAME (与 scripts/poker_game.gd 完全一致)
# ═══════════════════════════════════════════════════════
enum T_GameStage { PREFLOP, FLOP, TURN, RIVER, SHOWDOWN }

class T_Player:
    var name: String
    var chips: int
    var hand: Array = []
    var is_folded: bool = false
    var is_all_in: bool = false
    func _init(n: String, c: int): name = n; chips = c
    func bet_amount(a: int) -> int:
        var actual := mini(a, chips)
        chips -= actual
        if chips == 0:
            is_all_in = true
        return actual

    func reset_g():
        hand.clear()
        is_folded = false
        is_all_in = false


class T_PokerGame:
    var deck: T_Deck
    var evaluator: T_HE
    var players: Array = []
    var community: Array = []
    var stage: GameStage = T_GameStage.PREFLOP
    var pot: int = 0
    var current_bet: int = 0
    var dealer_idx: int = 0
    var game_over: bool = false
    var winner_name: String = ""

    func _init():
        deck = T_Deck.new(); evaluator = T_HE.new()

    func add_player(name: String, chips: int) -> T_Player:
        var p := T_Player.new(name, chips); players.append(p); return p

    func start_new_hand():
        deck = T_Deck.new(); deck.shuffle()
        community.clear(); pot = 0; current_bet = 0
        stage = T_GameStage.PREFLOP; game_over = false; winner_name = ""
        for pl in players: (pl as T_Player).reset_g()
        dealer_idx = (dealer_idx + 1) % players.size()
        deal_hole_cards()

    func deal_hole_cards():
        for pl in players: (pl as T_Player).hand = deck.deal(2)

    func deal_community(count: int):
        for i in range(count):
            if deck.remaining() > 0: community.append(deck.deal(1)[0])

    func next_stage():
        reset_bet()
        match stage:
            T_GameStage.PREFLOP: stage = T_GameStage.FLOP; deal_community(3)
            T_GameStage.FLOP:    stage = T_GameStage.TURN; deal_community(1)
            T_GameStage.TURN:    stage = T_GameStage.RIVER; deal_community(1)
            T_GameStage.RIVER:   stage = T_GameStage.SHOWDOWN

    func active_players() -> Array:
        var active: Array = []
        for pl in players:
            if not (pl as T_Player).is_folded: active.append(pl)
        return active

    func do_fold(pl: T_Player): pl.is_folded = true

    func do_call(pl: T_Player) -> int:
        var amt := pl.bet_amount(current_bet); pot += amt; return amt

    func do_raise(pl: T_Player, total: int) -> int:
        current_bet = total; var amt := pl.bet_amount(total); pot += amt; return amt

    func do_all_in(pl: T_Player) -> int:
        var amt := pl.bet_amount(pl.chips)
        if amt > current_bet: current_bet = amt
        pot += amt; return amt

    func do_check(pl: T_Player) -> int: return 0

    func reset_bet(): current_bet = 0

    func award_pot(winner: T_Player): winner.chips += pot; pot = 0

    func best_hand_of(pl: T_Player) -> Array:
        return evaluator.evaluate((pl as T_Player).hand + community)

    func determine_winner() -> T_Player:
        var active := active_players()
        if active.is_empty(): return null
        if active.size() == 1: return active[0]
        var best: Array = best_hand_of(active[0])
        var winner: T_Player = active[0] as T_Player
        for i in range(1, active.size()):
            var sc: Array = best_hand_of(active[i] as T_Player)
            if evaluator.compare(sc, best) > 0: best = sc; winner = active[i] as T_Player
        return winner

    func resolve_showdown():
        var w := determine_winner()
        if w != null: award_pot(w); winner_name = (w as T_Player).name
        game_over = true


# ═══════════════════════════════════════════════════════
#  UI CONTROLLER MOCK (模拟 main.gd 的逻辑)
# ═══════════════════════════════════════════════════════
const SUIT_SYMBOLS := ["♠","♥","♦","♣"]
const RANK_SYMBOLS := ["X","2","3","4","5","6","7","8","9","10","J","Q","K","A"]

class UIGame:
    var game: T_PokerGame
    var player: T_Player
    var ai1: T_Player
    var ai2: T_Player
    var is_game_over: bool = false
    var last_winner: String = ""

    func _init():
        game = T_PokerGame.new()
        player = game.add_player("你", 1000)
        ai1 = game.add_player("AI-1", 1000)
        ai2 = game.add_player("AI-2", 1000)
        game.start_new_hand()
        is_game_over = false

    func card_text(card: T_PC) -> String:
        if card == null: return "?"
        return RANK_SYMBOLS[card.rank] + SUIT_SYMBOLS[card.suit]

    func player_card_text(idx: int) -> String:
        if idx < (player as T_Player).hand.size():
            return card_text((player as T_Player).hand[idx] as T_PC)
        return "?"

    func community_card_text(idx: int) -> String:
        if idx < game.community.size():
            return card_text(game.community[idx] as T_PC)
        return "?"

    func fold_action():
        if is_game_over or (player as T_Player).is_folded: return
        game.do_fold(player as T_Player)

    func call_action():
        if is_game_over or (player as T_Player).is_folded: return
        if game.current_bet > 0: game.do_call(player as T_Player)
        else: game.do_check(player as T_Player)

    func raise_action(extra: int):
        if is_game_over or (player as T_Player).is_folded: return
        if extra > 0: game.do_raise(player as T_Player, game.current_bet + extra)

    func all_in_action():
        if is_game_over or (player as T_Player).is_folded: return
        game.do_all_in(player as T_Player)

    func stage_name() -> String:
        match game.stage:
            T_GameStage.PREFLOP: return "Pre-flop"
            T_GameStage.FLOP: return "Flop"
            T_GameStage.TURN: return "Turn"
            T_GameStage.RIVER: return "River"
            T_GameStage.SHOWDOWN: return "Showdown"
        return "?"

    func advance_game():
        if game.stage == T_GameStage.PREFLOP:
            game.next_stage()
        elif game.stage == T_GameStage.FLOP:
            game.next_stage()
        elif game.stage == T_GameStage.TURN:
            game.next_stage()
        elif game.stage == T_GameStage.RIVER:
            game.resolve_showdown()
            is_game_over = true
            last_winner = game.winner_name

    func new_hand():
        if (player as T_Player).chips <= 0 or (ai1 as T_Player).chips <= 0 and (ai2 as T_Player).chips <= 0:
            player = game.add_player("你", 1000); ai1 = game.add_player("AI-1", 1000); ai2 = game.add_player("AI-2", 1000)
        if (ai1 as T_Player).chips <= 0: game.players.erase(ai1)
        if (ai2 as T_Player).chips <= 0: game.players.erase(ai2)
        game.start_new_hand(); is_game_over = false; last_winner = ""


# ═══════════════════════════════════════════════════════
#  TESTS — 所有接口全覆盖
# ═══════════════════════════════════════════════════════
func _init():
    print("━━━ 德州扑克 集成测试 ━━━\n")
    call_deferred("_run_all")

func _run_all() -> void:
    _test_ui_card_text()
    _test_player_hand_access()
    _test_community_card_access()
    _test_fold_action()
    _test_call_action()
    _test_raise_action()
    _test_all_in_action()
    _test_stage_transitions()
    _test_full_hand_flow()
    _test_new_hand_resets()
    _test_game_over_after_showdown()
    _print_summary()
    quit(0 if _failed == 0 else 1)


func _test_ui_card_text() -> void:
    print("━━ UI卡牌文字 ━━")
    var ui = UIGame.new()
    _assert(ui.card_text(null) == "?", "null返回?")
    var c = T_PC.new(0, 14)  # A♠
    _assert(ui.card_text(c) == "A♠", "A♠显示正确")
    c = T_PC.new(1, 10)        # 10♥
    _assert(ui.card_text(c) == "10♥", "10♥显示正确")
    c = T_PC.new(2, 12)       # Q♦
    _assert(ui.card_text(c) == "Q♦", "Q♦显示正确")
    c = T_PC.new(3, 11)       # J♣
    _assert(ui.card_text(c) == "J♣", "J♣显示正确")


func _test_player_hand_access() -> void:
    print("━━ 玩家手牌访问 ━━")
    var ui = UIGame.new()
    _assert(ui.player_card_text(0) != "?", "第0张手牌已发")
    _assert(ui.player_card_text(1) != "?", "第1张手牌已发")
    _assert(ui.player_card_text(2) == "?", "第2张不存在")


func _test_community_card_access() -> void:
    print("━━ 公共牌访问 ━━")
    var ui = UIGame.new()
    _assert(ui.community_card_text(0) == "?", "初始无公共牌")
    _assert(ui.community_card_text(5) == "?", "超出范围返回?")
    # 发3张公共牌
    ui.game.deal_community(3)
    _assert(ui.community_card_text(0) != "?", "第1张公共牌")
    _assert(ui.community_card_text(2) != "?", "第3张公共牌")
    _assert(ui.community_card_text(3) == "?", "第4张还不存在")


func _test_fold_action() -> void:
    print("━━ Fold操作 ━━")
    var ui = UIGame.new()
    ui.fold_action()
    _assert((ui.player as T_Player).is_folded, "Fold后玩家已弃牌")
    _assert(not (ui.ai1 as T_Player).is_folded, "其他玩家未弃牌")
    _assert(ui.is_game_over == false, "Fold不直接结束游戏")


func _test_call_action() -> void:
    print("━━ Call操作 ━━")
    var ui = UIGame.new()
    ui.game.current_bet = 50
    var before: int = (ui.player as T_Player).chips
    ui.call_action()
    _assert((ui.player as T_Player).chips == before - 50, "跟注扣筹码")
    _assert(ui.game.pot == 50, "底池增加50")

    # Check
    ui.game.reset_bet()
    before = (ui.player as T_Player).chips
    ui.call_action()
    _assert((ui.player as T_Player).chips == before, "Check不扣筹码")


func _test_raise_action() -> void:
    print("━━ Raise操作 ━━")
    var ui = UIGame.new()
    ui.game.current_bet = 50
    var before: int = (ui.player as T_Player).chips
    ui.raise_action(50)  # 加50 -> 到100
    _assert((ui.player as T_Player).chips == before - 100, "加注到100扣100")
    _assert(ui.game.current_bet == 100, "当前最低100")


func _test_all_in_action() -> void:
    print("━━ All-In操作 ━━")
    var ui = UIGame.new()
    var before: int = (ui.player as T_Player).chips
    ui.all_in_action()
    _assert((ui.player as T_Player).chips == 0, "All-in后筹码归零")
    _assert((ui.player as T_Player).is_all_in, "标记All-in状态")
    _assert(ui.game.pot == before, "底池=原筹码")


func _test_stage_transitions() -> void:
    print("━━ 阶段切换 ━━")
    var ui = UIGame.new()
    _assert(ui.game.stage == T_GameStage.PREFLOP, "初始Pre-flop")
    _assert(ui.stage_name() == "Pre-flop", "阶段名Pre-flop")

    ui.game.next_stage()
    _assert(ui.game.stage == T_GameStage.FLOP, "翻牌Flop")
    _assert(ui.game.community.size() == 3, "3张公共牌")
    _assert(ui.stage_name() == "Flop", "阶段名Flop")

    ui.game.next_stage()
    _assert(ui.game.stage == T_GameStage.TURN, "转牌Turn")
    _assert(ui.game.community.size() == 4, "4张公共牌")
    _assert(ui.stage_name() == "Turn", "阶段名Turn")

    ui.game.next_stage()
    _assert(ui.game.stage == T_GameStage.RIVER, "河牌River")
    _assert(ui.game.community.size() == 5, "5张公共牌")
    _assert(ui.stage_name() == "River", "阶段名River")


func _test_full_hand_flow() -> void:
    print("━━ 完整手牌流程 ━━")
    var ui = UIGame.new()
    # Pre-flop
    _assert((ui.player as T_Player).hand.size() == 2, "每人2张底牌")
    _assert((ui.ai1 as T_Player).hand.size() == 2, "AI-1底牌")
    _assert((ui.ai2 as T_Player).hand.size() == 2, "AI-2底牌")
    _assert(ui.game.deck.remaining() == 52 - 6, "还剩46张")

    # 模拟各阶段推进
    ui.game.next_stage()  # Flop
    _assert(ui.game.stage == T_GameStage.FLOP, "进入Flop")
    ui.game.next_stage()  # Turn
    _assert(ui.game.stage == T_GameStage.TURN, "进入Turn")
    ui.game.next_stage()  # River
    _assert(ui.game.stage == T_GameStage.RIVER, "进入River")
    ui.game.next_stage()  # Showdown
    _assert(ui.game.stage == T_GameStage.SHOWDOWN, "进入Showdown")
    _assert(ui.is_game_over, "Showdown后游戏结束")


func _test_new_hand_resets() -> void:
    print("━━ 新手牌重置 ━━")
    var ui = UIGame.new()
    ui.game.pot = 500
    (ui.player as T_Player).chips = 800
    ui.game.fold_action()  # 弃掉
    _assert((ui.player as T_Player).is_folded, "当前手牌已Fold")

    ui.new_hand()
    _assert(not (ui.player as T_Player).is_folded, "新手牌重置")
    _assert((ui.player as T_Player).hand.size() == 2, "重新发2张")
    _assert(ui.game.pot == 0, "底池重置")
    _assert(ui.is_game_over == false, "游戏未结束")


func _test_game_over_after_showdown() -> void:
    print("━━ Showdown后状态 ━━")
    var ui = UIGame.new()
    # 推进到Showdown
    ui.game.next_stage()
    ui.game.next_stage()
    ui.game.next_stage()
    ui.game.next_stage()
    _assert(ui.is_game_over == true, "Showdown后游戏结束")
    _assert(ui.last_winner != "", "有赢家")
    _assert(ui.game.winner_name != "", "游戏记录赢家名字")


# ═══════════════════════════════════════════════════════
#  UTILS
# ═══════════════════════════════════════════════════════
func _t(name: String, ok: bool) -> void:
    if ok: _passed += 1; print("  ✓ " + name)
    else: _failed += 1; print("  ✗ " + name)

func _assert(cond: bool, detail: String) -> void:
    if not cond: _failed += 1; print("  ✗ " + detail)
    else: _passed += 1

func _print_summary() -> void:
    print("\n━━━ 结果 ━━━")
    print("  ✓ passed: " + str(_passed))
    print("  ✗ failed: " + str(_failed))
    if _failed == 0: print("  🎉 全部通过！")
    else: print("  ⚠️  " + str(_failed) + " 个失败")
