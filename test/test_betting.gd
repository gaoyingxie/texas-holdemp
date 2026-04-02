extends SceneTree
## 下注逻辑 + 游戏状态机 测试
## TDD: 先写测试 RED → 写实现 GREEN

var _passed := 0
var _failed := 0


# ═══════════════════════════════════════════════════════
#  CORE CLASSES
# ═══════════════════════════════════════════════════════
class PC:
    var suit: int; var rank: int
    func _init(s: int, r: int): suit = s; rank = r


class Deck:
    var _cards: Array = []
    func _init():
        for s in range(4):
            for r in range(2, 15): _cards.append(PC.new(s, r))
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


class HE:
    func evaluate(cards: Array) -> Array:
        var best := _best_five(cards)
        var rc := _rc(best)
        var flush := _is_flush(best)
        var si := _is_straight(best)
        var is_str: bool = si[0]; var sh: int = si[1]
        if flush and is_str and sh == 14: return [9, [14]]
        if flush and is_str: return [8, [sh]]
        if _has_count(rc, 4):
            var q: int = _roc(rc, 4)
            return [7, [q, _mk(rc, [q])]]
        if _has_count(rc, 3) and _has_count(rc, 2):
            return [6, [_roc(rc, 3), _roc(rc, 2)]]
        if flush: return [5, _sr(best)]
        if is_str: return [4, [sh]]
        if _has_count(rc, 3):
            var t3: int = _roc(rc, 3)
            return [3, [t3] + _tk(rc, [t3], 2)]
        if _count_eq(rc, 2) == 2:
            var ps: Array = _rocs(rc, 2); ps.sort(); ps.reverse()
            return [2, ps + _tk(rc, ps, 1)]
        if _has_count(rc, 2):
            var pr: int = _roc(rc, 2)
            return [1, [pr] + _tk(rc, [pr], 3)]
        return [0, _tk(rc, [], 5)]

    func compare(h1: Array, h2: Array) -> int:
        return _cmp(evaluate(h1), evaluate(h2))

    func _best_five(cards: Array) -> Array:
        if cards.size() <= 5: return cards.duplicate()
        var bs: Array = []; var bh: Array = []; var n := cards.size()
        for i in range(n - 4):
            for j in range(i + 1, n - 3):
                for k in range(j + 1, n - 2):
                    for l in range(k + 1, n - 1):
                        for m in range(l + 1, n):
                            var combo: Array = [cards[i], cards[j], cards[k], cards[l], cards[m]]
                            var sc: Array = evaluate(combo)
                            if bs.is_empty() or _cmp(sc, bs) > 0:
                                bs = sc; bh = combo
        return bh

    func _cmp(a: Array, b: Array) -> int:
        if a[0] != b[0]: return a[0] - b[0]
        var ta: Array = a[1] as Array; var tb: Array = b[1] as Array
        for i in range(min(ta.size(), tb.size())):
            if ta[i] != tb[i]: return ta[i] - tb[i]
        return 0

    func _rc(cards: Array) -> Dictionary:
        var d: Dictionary = {}
        for c in cards: d[c.rank] = d.get(c.rank, 0) + 1
        return d

    func _has_count(rc: Dictionary, target: int) -> bool:
        for v in rc.values():
            if v == target: return true
        return false

    func _count_eq(rc: Dictionary, target: int) -> int:
        var cnt := 0
        for v in rc.values():
            if v == target: cnt += 1
        return cnt

    func _is_flush(cards: Array) -> bool:
        if cards.size() < 5: return false
        var s: int = cards[0].suit
        for c in cards:
            if c.suit != s: return false
        return true

    func _is_straight(cards: Array) -> Array:
        var ranks: Array = []
        for c in cards: ranks.append(c.rank)
        var u: Array[int] = []
        for r in ranks:
            var ri: int = r as int
            if not (ri in u): u.append(ri)
        u.sort()
        if u.size() < 5: return [false, 0]
        if u == [2, 3, 4, 5, 14]: return [true, 5]
        for start in range(u.size() - 4):
            var ok := true
            for off in range(4):
                if u[start + off + 1] - u[start + off] != 1: ok = false; break
            if ok: return [true, u[start + 4]]
        return [false, 0]

    func _roc(rc: Dictionary, target: int) -> int:
        for r in rc:
            if rc[r] == target: return r as int
        return 0

    func _rocs(rc: Dictionary, target: int) -> Array:
        var res: Array = []
        for r in rc:
            if rc[r] == target: res.append(r as int)
        return res

    func _mk(rc: Dictionary, ex: Array) -> int:
        var best := 0
        for r in rc:
            var ri: int = r as int
            if not (ri in ex) and ri > best: best = ri
        return best

    func _tk(rc: Dictionary, ex: Array, n: int) -> Array:
        var all: Array = []
        for r in rc:
            var ri: int = r as int
            if not (ri in ex): all.append(ri)
        all.sort(); all.reverse()
        return all.slice(0, n)

    func _sr(cards: Array) -> Array:
        var ranks: Array = []
        for c in cards: ranks.append(c.rank)
        ranks.sort(); ranks.reverse()
        return ranks.slice(0, 5)


# ═══════════════════════════════════════════════════════
#  POKER GAME
# ═══════════════════════════════════════════════════════
enum GameStage { PREFLOP, FLOP, TURN, RIVER, SHOWDOWN }

class Player:
    var name: String
    var chips: int
    var hand: Array = []
    var is_folded: bool = false
    var is_all_in: bool = false
    func _init(n: String, c: int):
        name = n; chips = c
    func bet_amount(amount: int) -> int:
        var actual := mini(amount, chips)
        chips -= actual
        if chips == 0: is_all_in = true
        return actual
    func reset_game():
        hand.clear(); is_folded = false; is_all_in = false


class PokerGame:
    var deck: Deck
    var evaluator: HE
    var players: Array = []
    var community: Array = []
    var stage: GameStage = GameStage.PREFLOP
    var pot: int = 0
    var current_bet: int = 0
    var dealer_idx: int = 0

    func _init():
        deck = Deck.new()
        evaluator = HE.new()

    func add_player(name: String, chips: int) -> Player:
        var p := Player.new(name, chips)
        players.append(p)
        return p

    func start_new_hand():
        deck = Deck.new()
        deck.shuffle()
        community.clear()
        pot = 0
        current_bet = 0
        stage = GameStage.PREFLOP
        for p in players:
            (p as Player).reset_game()

    func deal_hole_cards():
        for p in players:
            p.hand = deck.deal(2)

    func deal_community(count: int):
        for i in range(count):
            if deck.remaining() > 0:
                community.append(deck.deal(1)[0])

    func next_stage():
        match stage:
            GameStage.PREFLOP:
                stage = GameStage.FLOP; deal_community(3)
            GameStage.FLOP:
                stage = GameStage.TURN; deal_community(1)
            GameStage.TURN:
                stage = GameStage.RIVER; deal_community(1)
            GameStage.RIVER:
                stage = GameStage.SHOWDOWN

    func active_players() -> Array:
        var active: Array = []
        for p in players:
            if not (p as Player).is_folded: active.append(p)
        return active

    func fold(pl: Player):
        pl.is_folded = true

    func do_call(pl: Player) -> int:
        var amount := pl.bet_amount(current_bet)
        pot += amount
        return amount

    func do_raise(pl: Player, total: int) -> int:
        current_bet = total
        var amount := pl.bet_amount(total)
        pot += amount
        return amount

    func do_all_in(pl: Player) -> int:
        var amount := pl.bet_amount(pl.chips)
        if amount > current_bet: current_bet = amount
        pot += amount
        return amount

    func award_pot(winner: Player):
        winner.chips += pot
        pot = 0

    func best_hand_of(pl: Player) -> Array:
        return evaluator.evaluate(pl.hand + community)

    func determine_winner() -> Player:
        var active := active_players()
        if active.is_empty(): return null
        if active.size() == 1: return active[0]
        var best: Array = best_hand_of(active[0])
        var winner: Player = active[0] as Player
        for i in range(1, active.size()):
            var sc: Array = best_hand_of(active[i] as Player)
            if evaluator.compare(sc, best) > 0:
                best = sc; winner = active[i] as Player
        return winner


# ═══════════════════════════════════════════════════════
#  TESTS
# ═══════════════════════════════════════════════════════
func _init():
    print("━━━ 下注逻辑 + 游戏状态机 测试 ━━━\n")
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
    var g := PokerGame.new()
    var alice := g.add_player("Alice", 1000)
    g.add_player("Bob", 1000)
    _assert_eq(g.players.size(), 2, "2名玩家")
    _assert_eq(alice.chips, 1000, "Alice初始1000筹码")


func _test_blind_and_dealing() -> void:
    print("━━ 发牌 ━━")
    var g := PokerGame.new()
    g.add_player("Alice", 1000)
    g.add_player("Bob", 1000)
    g.start_new_hand()
    g.deal_hole_cards()
    var alice: Player = g.players[0] as Player
    _assert_eq(alice.hand.size(), 2, "Alice拿2张")
    _assert_eq(g.deck.remaining(), 48, "牌堆剩48张")


func _test_fold() -> void:
    print("━━ Fold ━━")
    var g := PokerGame.new()
    var alice: Player = g.add_player("Alice", 1000) as Player
    var bob: Player = g.add_player("Bob", 1000) as Player
    g.start_new_hand()
    g.deal_hole_cards()
    g.fold(alice)
    _assert(alice.is_folded, "Alice已Fold")
    _assert(not bob.is_folded, "Bob未Fold")
    _assert_eq(g.active_players().size(), 1, "剩1名活跃")


func _test_call() -> void:
    print("━━ Call ━━")
    var g := PokerGame.new()
    var alice: Player = g.add_player("Alice", 1000) as Player
    g.add_player("Bob", 1000)
    g.current_bet = 50
    var before := alice.chips
    var paid := g.do_call(alice)
    _assert_eq(paid, 50, "跟注50")
    _assert_eq(alice.chips, before - 50, "Alice剩余950")
    _assert_eq(g.pot, 50, "底池50")


func _test_raise() -> void:
    print("━━ Raise ━━")
    var g := PokerGame.new()
    var alice: Player = g.add_player("Alice", 1000) as Player
    g.add_player("Bob", 1000)
    g.current_bet = 50
    var paid := g.do_raise(alice, 200)
    _assert_eq(paid, 200, "加注到200")
    _assert_eq(alice.chips, 800, "Alice剩余800")
    _assert_eq(g.pot, 200, "底池200")
    _assert_eq(g.current_bet, 200, "当前最低200")


func _test_all_in() -> void:
    print("━━ All-In ━━")
    var g := PokerGame.new()
    var alice: Player = g.add_player("Alice", 500) as Player
    g.add_player("Bob", 1000)
    g.current_bet = 50
    var paid := g.do_all_in(alice)
    _assert_eq(paid, 500, "All-in 500")
    _assert_eq(alice.chips, 0, "Alice筹码归零")
    _assert(alice.is_all_in, "Alice已All-in")
    _assert_eq(g.pot, 500, "底池500")
    _assert_eq(g.current_bet, 500, "最低跟注500")


func _test_award_pot() -> void:
    print("━━ 底池分配 ━━")
    var g := PokerGame.new()
    var alice: Player = g.add_player("Alice", 1000) as Player
    g.add_player("Bob", 1000)
    g.pot = 200
    var before := alice.chips
    g.award_pot(alice)
    _assert_eq(alice.chips, before + 200, "赢家获得底池")
    _assert_eq(g.pot, 0, "底池清零")


func _test_stages() -> void:
    print("━━ 游戏阶段 ━━")
    var g := PokerGame.new()
    g.add_player("Alice", 1000)
    g.add_player("Bob", 1000)
    g.start_new_hand()
    _assert(g.stage == GameStage.PREFLOP, "初始Pre-flop")
    g.deal_hole_cards()
    g.next_stage()
    _assert(g.stage == GameStage.FLOP, "翻牌Flop")
    _assert_eq(g.community.size(), 3, "3张公共牌")
    g.next_stage()
    _assert(g.stage == GameStage.TURN, "转牌Turn")
    _assert_eq(g.community.size(), 4, "4张公共牌")
    g.next_stage()
    _assert(g.stage == GameStage.RIVER, "河牌River")
    _assert_eq(g.community.size(), 5, "5张公共牌")
    g.next_stage()
    _assert(g.stage == GameStage.SHOWDOWN, "摊牌Showdown")


func _test_no_active_players() -> void:
    print("━━ 边角情况 ━━")
    var g := PokerGame.new()
    var alice: Player = g.add_player("Alice", 1000) as Player
    var bob: Player = g.add_player("Bob", 1000) as Player
    g.start_new_hand()
    g.fold(alice)
    g.fold(bob)
    _assert_eq(g.active_players().size(), 0, "无活跃玩家")


func _test_showdown() -> void:
    print("━━ Showdown ━━")
    var g := PokerGame.new()
    var alice: Player = g.add_player("Alice", 1000) as Player
    var bob: Player = g.add_player("Bob", 1000) as Player
    g.start_new_hand()
    g.fold(alice)
    g.fold(bob)
    var w = g.determine_winner()
    _assert(w == null, "全部Fold时无赢家")


# ═══════════════════════════════════════════════════════
#  UTILS
# ═══════════════════════════════════════════════════════
func _t(name: String, ok: bool) -> void:
    if ok: _passed += 1; print("  ✓ " + name)
    else: _failed += 1; print("  ✗ " + name)

func _assert(cond: bool, detail: String) -> void:
    if not cond: _failed += 1; print("  ✗ " + detail)
    else: _passed += 1

func _assert_eq(a: int, b: int, detail: String) -> void:
    if a != b: _failed += 1; print("  ✗ " + detail + " (期望" + str(b) + "，实际" + str(a) + ")")
    else: _passed += 1

func _print_summary() -> void:
    print("\n━━━ 结果 ━━━")
    print("  ✓ passed: " + str(_passed))
    print("  ✗ failed: " + str(_failed))
    if _failed == 0: print("  🎉 全部通过！")
    else: print("  ⚠️  " + str(_failed) + " 个失败")
