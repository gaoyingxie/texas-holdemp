extends SceneTree
## 下注逻辑测试
## 用法: godot --headless --script test/test_betting.gd

var _passed := 0
var _failed := 0


# ── 本地类（避免与class_name全局注册冲突）─────────────────────────
class T_PC:
    var suit: int
    var rank: int
    func _init(s: int, r: int):
        suit = s; rank = r


class T_Deck:
    var _cards = []
    func _init():
        for s in range(4):
            for r in range(2, 15):
                _cards.append(T_PC.new(s, r))
    func shuffle():
        var rng = RandomNumberGenerator.new()
        for i in range(_cards.size()):
            var j = rng.randi_range(i, _cards.size() - 1)
            var tmp = _cards[i]
            _cards[i] = _cards[j]
            _cards[j] = tmp
    func deal(count: int):
        var hand = []
        for i in range(count):
            if _cards.is_empty():
                break
            hand.append(_cards.pop_back())
        return hand
    func remaining() -> int:
        return _cards.size()


class T_HE:
    func evaluate(cards) -> Array:
        var best = _best_five(cards)
        var rc = _rank_counts(best)
        var flush = _is_flush(best)
        var si = _is_straight(best)
        var is_str = si[0]
        var sh = si[1]
        if flush and is_str and sh == 14:
            return [9, [14]]
        if flush and is_str:
            return [8, [sh]]
        if _has_count(rc, 4):
            var q = _roc(rc, 4)
            return [7, [q, _mk(rc, [q])]]
        if _has_count(rc, 3) and _has_count(rc, 2):
            return [6, [_roc(rc, 3), _roc(rc, 2)]]
        if flush:
            return [5, _sr(best)]
        if is_str:
            return [4, [sh]]
        if _has_count(rc, 3):
            var t3 = _roc(rc, 3)
            return [3, [t3] + _tk(rc, [t3], 2)]
        if _cve(rc, 2) == 2:
            var ps = _rocs(rc, 2)
            ps.sort()
            ps.reverse()
            return [2, ps + _tk(rc, ps, 1)]
        if _has_count(rc, 2):
            var pr = _roc(rc, 2)
            return [1, [pr] + _tk(rc, [pr], 3)]
        return [0, _tk(rc, [], 5)]

    func _best_five(cards):
        if cards.size() <= 5:
            return cards.duplicate()
        var bs = []
        var bh = []
        var n = cards.size()
        for i in range(n - 4):
            for j in range(i + 1, n - 3):
                for k in range(j + 1, n - 2):
                    for l in range(k + 1, n - 1):
                        for m in range(l + 1, n):
                            var combo = [cards[i], cards[j], cards[k], cards[l], cards[m]]
                            var sc = evaluate(combo)
                            if bs.is_empty() or _cmp(sc, bs) > 0:
                                bs = sc
                                bh = combo
        return bh

    func _cmp(a, b) -> int:
        if a[0] != b[0]:
            return a[0] - b[0]
        for i in range(min(a[1].size(), b[1].size())):
            if a[1][i] != b[1][i]:
                return a[1][i] - b[1][i]
        return 0

    func _rank_counts(cards):
        var d = {}
        for c in cards:
            d[c.rank] = d.get(c.rank, 0) + 1
        return d

    func _has_count(rc, t) -> bool:
        for v in rc.values():
            if v == t:
                return true
        return false

    func _cve(rc, t) -> int:
        var n = 0
        for v in rc.values():
            if v == t:
                n += 1
        return n

    func _is_flush(cards) -> bool:
        if cards.size() < 5:
            return false
        var s = cards[0].suit
        for c in cards:
            if c.suit != s:
                return false
        return true

    func _is_straight(cards):
        var ranks = []
        for c in cards:
            ranks.append(c.rank)
        var u = []
        for r in ranks:
            var ri = r as int
            if not (ri in u):
                u.append(ri)
        u.sort()
        if u.size() < 5:
            return [false, 0]
        if u == [2, 3, 4, 5, 14]:
            return [true, 5]
        for start in range(u.size() - 4):
            var ok = true
            for off in range(4):
                if u[start + off + 1] - u[start + off] != 1:
                    ok = false
                    break
            if ok:
                return [true, u[start + 4]]
        return [false, 0]

    func _roc(rc, t) -> int:
        for r in rc:
            if rc[r] == t:
                return r as int
        return 0

    func _rocs(rc, t):
        var res = []
        for r in rc:
            if rc[r] == t:
                res.append(r as int)
        return res

    func _mk(rc, ex) -> int:
        var best = 0
        for r in rc:
            var ri = r as int
            if not (ri in ex) and ri > best:
                best = ri
        return best

    func _tk(rc, ex, n):
        var all = []
        for r in rc:
            var ri = r as int
            if not (ri in ex):
                all.append(ri)
        all.sort()
        all.reverse()
        return all.slice(0, n)

    func _sr(cards):
        var ranks = []
        for c in cards:
            ranks.append(c.rank)
        ranks.sort()
        ranks.reverse()
        return ranks.slice(0, 5)


enum T_GameStage { PREFLOP, FLOP, TURN, RIVER, SHOWDOWN }


class T_Player:
    var name: String
    var chips: int
    var hand = []
    var is_folded: bool = false
    var is_all_in: bool = false
    func _init(n: String, c: int):
        name = n; chips = c
    func bet_amount(a: int) -> int:
        var actual = mini(a, chips)
        chips = chips - actual
        if chips == 0:
            is_all_in = true
        return actual
    func reset_g():
        hand.clear()
        is_folded = false
        is_all_in = false


class T_PokerGame:
    var _deck: T_Deck
    var _evaluator: T_HE
    var players = []
    var community = []
    var stage: int = T_GameStage.PREFLOP
    var pot: int = 0
    var current_bet: int = 0
    var dealer_idx: int = 0
    var game_over: bool = false
    var winner_name: String = ""

    func _init():
        _deck = T_Deck.new()
        _evaluator = T_HE.new()

    func add_player(name: String, chips: int) -> T_Player:
        var p = T_Player.new(name, chips)
        players.append(p)
        return p

    func start_new_hand():
        _deck = T_Deck.new()
        _deck.shuffle()
        community.clear()
        pot = 0
        current_bet = 0
        stage = T_GameStage.PREFLOP
        game_over = false
        winner_name = ""
        for pl in players:
            (pl as T_Player).reset_g()
        dealer_idx = (dealer_idx + 1) % players.size()
        deal_hole_cards()

    func deal_hole_cards():
        for pl in players:
            (pl as T_Player).hand = _deck.deal(2)

    func deal_community(count: int):
        for i in range(count):
            if _deck.remaining() > 0:
                community.append(_deck.deal(1)[0])

    func next_stage():
        reset_bet()
        if stage == T_GameStage.PREFLOP:
            stage = T_GameStage.FLOP
            deal_community(3)
        elif stage == T_GameStage.FLOP:
            stage = T_GameStage.TURN
            deal_community(1)
        elif stage == T_GameStage.TURN:
            stage = T_GameStage.RIVER
            deal_community(1)
        elif stage == T_GameStage.RIVER:
            stage = T_GameStage.SHOWDOWN

    func active_players():
        var active = []
        for pl in players:
            if not (pl as T_Player).is_folded:
                active.append(pl)
        return active

    func do_fold(pl):
        (pl as T_Player).is_folded = true

    func do_call(pl) -> int:
        var amt = (pl as T_Player).bet_amount(current_bet)
        pot = pot + amt
        return amt

    func do_raise(pl, total: int) -> int:
        current_bet = total
        var amt = (pl as T_Player).bet_amount(total)
        pot = pot + amt
        return amt

    func do_all_in(pl) -> int:
        var amt = (pl as T_Player).bet_amount((pl as T_Player).chips)
        if amt > current_bet:
            current_bet = amt
        pot = pot + amt
        return amt

    func reset_bet():
        current_bet = 0

    func award_pot(winner):
        (winner as T_Player).chips = (winner as T_Player).chips + pot
        pot = 0

    func best_hand_of(pl) -> Array:
        return _evaluator.evaluate((pl as T_Player).hand + community)

    func determine_winner():
        var active = active_players()
        if active.is_empty():
            return null
        if active.size() == 1:
            return active[0]
        var best = best_hand_of(active[0])
        var winner = active[0]
        for i in range(1, active.size()):
            var sc = best_hand_of(active[i])
            if _evaluator._cmp(sc, best) > 0:
                best = sc
                winner = active[i]
        return winner

    func resolve_showdown():
        var w = determine_winner()
        if w != null:
            award_pot(w)
            winner_name = (w as T_Player).name
        game_over = true


# ── TESTS ──────────────────────────────────────────────────────
func _init():
    print("━━━ 下注逻辑 测试 ━━━\n")
    call_deferred("_run_all")

func _run_all() -> void:
    _test_game_setup()
    _test_blind_and_dealing()
    _test_fold()
    _test_call()
    _test_raise()
    _test_all_in()
    _test_award_pot()
    _test_stages()
    _test_no_active_players()
    _test_showdown()
    _print_summary()
    quit(0 if _failed == 0 else 1)


func _test_game_setup() -> void:
    print("━━ 游戏设置 ━━")
    var g = T_PokerGame.new()
    var alice = g.add_player("Alice", 1000)
    g.add_player("Bob", 1000)
    _assert_eq(g.players.size(), 2, "2名玩家")
    _assert_eq((alice as T_Player).chips, 1000, "Alice初始1000筹码")


func _test_blind_and_dealing() -> void:
    print("━━ 发牌 ━━")
    var g = T_PokerGame.new()
    g.add_player("Alice", 1000)
    g.add_player("Bob", 1000)
    g.start_new_hand()
    var alice = g.players[0] as T_Player
    _assert_eq(alice.hand.size(), 2, "Alice拿2张")
    _assert_eq(g._deck.remaining(), 48, "牌堆剩48张")


func _test_fold() -> void:
    print("━━ Fold ━━")
    var g = T_PokerGame.new()
    var alice = g.add_player("Alice", 1000) as T_Player
    var bob = g.add_player("Bob", 1000) as T_Player
    g.start_new_hand()
    g.do_fold(alice)
    _assert(alice.is_folded, "Alice已Fold")
    _assert(not bob.is_folded, "Bob未Fold")
    _assert_eq(g.active_players().size(), 1, "剩1名活跃")


func _test_call() -> void:
    print("━━ Call ━━")
    var g = T_PokerGame.new()
    var alice = g.add_player("Alice", 1000) as T_Player
    g.add_player("Bob", 1000)
    g.current_bet = 50
    var before = alice.chips
    var paid = g.do_call(alice)
    _assert_eq(paid, 50, "跟注50")
    _assert_eq(alice.chips, before - 50, "Alice剩余950")
    _assert_eq(g.pot, 50, "底池50")


func _test_raise() -> void:
    print("━━ Raise ━━")
    var g = T_PokerGame.new()
    var alice = g.add_player("Alice", 1000) as T_Player
    g.add_player("Bob", 1000)
    g.current_bet = 50
    var paid = g.do_raise(alice, 200)
    _assert_eq(paid, 200, "加注到200")
    _assert_eq(alice.chips, 800, "Alice剩余800")
    _assert_eq(g.pot, 200, "底池200")
    _assert_eq(g.current_bet, 200, "当前最低200")


func _test_all_in() -> void:
    print("━━ All-In ━━")
    var g = T_PokerGame.new()
    var alice = g.add_player("Alice", 500) as T_Player
    g.add_player("Bob", 1000)
    g.current_bet = 50
    var paid = g.do_all_in(alice)
    _assert_eq(paid, 500, "All-in 500")
    _assert_eq(alice.chips, 0, "Alice筹码归零")
    _assert(alice.is_all_in, "Alice已All-in")
    _assert_eq(g.pot, 500, "底池500")
    _assert_eq(g.current_bet, 500, "最低跟注500")


func _test_award_pot() -> void:
    print("━━ 底池分配 ━━")
    var g = T_PokerGame.new()
    var alice = g.add_player("Alice", 1000) as T_Player
    g.add_player("Bob", 1000)
    g.pot = 200
    var before = alice.chips
    g.award_pot(alice)
    _assert_eq(alice.chips, before + 200, "赢家获得底池")
    _assert_eq(g.pot, 0, "底池清零")


func _test_stages() -> void:
    print("━━ 游戏阶段 ━━")
    var g = T_PokerGame.new()
    g.add_player("Alice", 1000)
    g.add_player("Bob", 1000)
    g.start_new_hand()
    _assert(g.stage == T_GameStage.PREFLOP, "初始Pre-flop")
    g.next_stage()
    _assert(g.stage == T_GameStage.FLOP, "翻牌Flop")
    _assert_eq(g.community.size(), 3, "3张公共牌")
    g.next_stage()
    _assert(g.stage == T_GameStage.TURN, "转牌Turn")
    _assert_eq(g.community.size(), 4, "4张公共牌")
    g.next_stage()
    _assert(g.stage == T_GameStage.RIVER, "河牌River")
    _assert_eq(g.community.size(), 5, "5张公共牌")
    g.next_stage()
    _assert(g.stage == T_GameStage.SHOWDOWN, "摊牌Showdown")


func _test_no_active_players() -> void:
    print("━━ 边角情况 ━━")
    var g = T_PokerGame.new()
    var alice = g.add_player("Alice", 1000) as T_Player
    var bob = g.add_player("Bob", 1000) as T_Player
    g.start_new_hand()
    g.do_fold(alice)
    g.do_fold(bob)
    _assert_eq(g.active_players().size(), 0, "无活跃玩家")


func _test_showdown() -> void:
    print("━━ Showdown ━━")
    var g = T_PokerGame.new()
    var alice = g.add_player("Alice", 1000) as T_Player
    var bob = g.add_player("Bob", 1000) as T_Player
    g.start_new_hand()
    g.do_fold(alice)
    g.do_fold(bob)
    var w = g.determine_winner()
    _assert(w == null, "全部Fold时无赢家")


# ── UTILS ──────────────────────────────────────────────────────
func _t(name: String, ok: bool) -> void:
    if ok:
        _passed += 1
        print("  ✓ " + name)
    else:
        _failed += 1
        print("  ✗ " + name)

func _assert(cond: bool, detail: String) -> void:
    if not cond:
        _failed += 1
        print("  ✗ " + detail)
    else:
        _passed += 1

func _assert_eq(a: int, b: int, detail: String) -> void:
    if a != b:
        _failed += 1
        print("  ✗ " + detail + " (期望" + str(b) + "，实际" + str(a) + ")")
    else:
        _passed += 1

func _print_summary() -> void:
    print("\n━━━ 结果 ━━━")
    print("  ✓ passed: " + str(_passed))
    print("  ✗ failed: " + str(_failed))
    if _failed == 0:
        print("  🎉 全部通过！")
    else:
        print("  ⚠️  " + str(_failed) + " 个失败")
