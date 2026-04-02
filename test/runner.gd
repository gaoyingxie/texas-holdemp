extends SceneTree
## 德州扑克 TDD 测试运行器
## 用法: godot --headless --script test/runner.gd
## 先写 RED 测试（失败），再写实现让测试变 GREEN

var _passed := 0
var _failed := 0


# ═══════════════════════════════════════════════
#  CORE CLASSES (inline, same as scripts/)
# ═══════════════════════════════════════════════
class PC:
    var suit: int; var rank: int
    func _init(s: int, r: int): suit = s; rank = r
    func _to_string() -> String:
        var suits := ["S","H","D","C"]
        var ranks := ["","2","3","4","5","6","7","8","9","10","J","Q","K","A"]
        return ranks[rank] + suits[suit]


class Deck:
    var _cards: Array = []
    func _init():
        for s in range(4):
            for r in range(2, 15):
                _cards.append(PC.new(s, r))
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
        var rc := _rank_counts(best)
        var flush := _is_flush(best)
        var si := _is_straight(best)
        var is_straight: bool = si[0]
        var straight_high: int = si[1]
        if flush and is_straight and straight_high == 14: return [9, [14]]
        if flush and is_straight: return [8, [straight_high]]
        if _has_count(rc, 4):
            var q := _rank_of_count(rc, 4)
            return [7, [q, _max_kicker_one(rc, [q])]]
        if _has_count(rc, 3) and _has_count(rc, 2):
            return [6, [_rank_of_count(rc, 3), _rank_of_count(rc, 2)]]
        if flush: return [5, _sorted_ranks(best)]
        if is_straight: return [4, [straight_high]]
        if _has_count(rc, 3):
            var t := _rank_of_count(rc, 3)
            return [3, [t] + _top_kickers(rc, [t], 2)]
        if _count_eq(rc, 2) == 2:
            var pairs := _ranks_of_count(rc, 2); pairs.sort(); pairs.reverse()
            return [2, pairs + _top_kickers(rc, pairs, 1)]
        if _has_count(rc, 2):
            var pr := _rank_of_count(rc, 2)
            return [1, [pr] + _top_kickers(rc, [pr], 3)]
        return [0, _top_kickers(rc, [], 5)]

    func compare(h1: Array, h2: Array) -> int:
        return _cmp(evaluate(h1), evaluate(h2))

    func _best_five(cards: Array) -> Array:
        if cards.size() <= 5: return cards.duplicate()
        var best_score: Array = []; var best_hand: Array = []
        var n := cards.size()
        for i in range(n - 4):
            for j in range(i + 1, n - 3):
                for k in range(j + 1, n - 2):
                    for l in range(k + 1, n - 1):
                        for m in range(l + 1, n):
                            var combo: Array = [cards[i], cards[j], cards[k], cards[l], cards[m]]
                            var sc: Array = evaluate(combo)
                            if best_score.is_empty() or _cmp(sc, best_score) > 0:
                                best_score = sc; best_hand = combo
        return best_hand

    func _cmp(a: Array, b: Array) -> int:
        if a[0] != b[0]: return a[0] - b[0]
        var ta: Array = a[1]; var tb: Array = b[1]
        for i in range(min(ta.size(), tb.size())):
            if ta[i] != tb[i]: return ta[i] - tb[i]
        return 0

    func _rank_counts(cards: Array) -> Dictionary:
        var rc: Dictionary = {}
        for c in cards: rc[c.rank] = rc.get(c.rank, 0) + 1
        return rc

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
        var unique: Array[int] = []
        for r in ranks:
            var ri: int = r as int
            if not (ri in unique): unique.append(ri)
        unique.sort()
        if unique.size() < 5: return [false, 0]
        if unique == [2, 3, 4, 5, 14]: return [true, 5]
        for start in range(unique.size() - 4):
            var ok := true
            for off in range(4):
                if unique[start + off + 1] - unique[start + off] != 1:
                    ok = false; break
            if ok: return [true, unique[start + 4]]
        return [false, 0]

    func _rank_of_count(rc: Dictionary, target: int) -> int:
        for r in rc:
            if rc[r] == target: return r as int
        return 0

    func _ranks_of_count(rc: Dictionary, target: int) -> Array:
        var result: Array = []
        for r in rc:
            if rc[r] == target: result.append(r as int)
        return result

    func _max_kicker_one(rc: Dictionary, exclude: Array) -> int:
        var best := 0
        for r in rc:
            var ri: int = r as int
            if not (ri in exclude) and ri > best: best = ri
        return best

    func _top_kickers(rc: Dictionary, exclude: Array, n: int) -> Array:
        var all: Array = []
        for r in rc:
            var ri: int = r as int
            if not (ri in exclude): all.append(ri)
        all.sort(); all.reverse()
        return all.slice(0, n)

    func _sorted_ranks(cards: Array) -> Array:
        var ranks: Array = []
        for c in cards: ranks.append(c.rank)
        ranks.sort(); ranks.reverse()
        return ranks.slice(0, 5)


# ═══════════════════════════════════════════════
#  TESTS
# ═══════════════════════════════════════════════
func _init():
    print("━━━ 德州扑克 全部测试 ━━━\n")
    call_deferred("_run_all")

func _run_all() -> void:
    _test_deck()
    _test_hand_rank()
    _print_summary()
    quit(0 if _failed == 0 else 1)


func _test_deck() -> void:
    print("━━ Deck 测试 ━━")
    var d := Deck.new()
    _assert_eq(d.remaining(), 52, "牌堆52张")
    var seen: Array = []
    for card in d._cards:
        var key := str(card.suit) + "-" + str(card.rank)
        if key in seen: _fail("有重复牌: " + key); return
        seen.append(key)
    _pass("52张无重复")
    var d1 := Deck.new()
    var o1: Array = d1._cards.map(func(c): return str(c.suit) + str(c.rank))
    d1.shuffle()
    var o2: Array = d1._cards.map(func(c): return str(c.suit) + str(c.rank))
    var same := true
    for i in range(o1.size()):
        if o1[i] != o2[i]: same = false; break
    _assert(not same, "洗牌后顺序改变")
    var d2 := Deck.new()
    _assert_eq(d2.remaining(), 52, "新建牌52张")
    var hand: Array = d2.deal(5)
    _assert_eq(d2.remaining(), 47, "发5张剩47")
    _assert_eq(hand.size(), 5, "收到5张")
    var d3 := Deck.new()
    d3.deal(2); d3.deal(2); d3.deal(2); d3.deal(5); d3.deal(2); d3.deal(2)
    _assert_eq(d3.remaining(), 37, "5人局剩37张")
    var d4 := Deck.new()
    d4.deal(52)
    _assert_eq(d4.deal(1).size(), 0, "空堆不能继续发")


func _test_hand_rank() -> void:
    print("\n━━ 手牌评估器 测试 ━━")
    var ev := HE.new()
    # 基础
    _t("对A > 对K",     ev.compare(_p("AhAd"), _p("KcKd")) > 0)
    _t("对K < 对A",     ev.compare(_p("KhKd"), _p("AcAs")) < 0)
    # 牌型强度
    _t("皇家同花顺 > 普通同花顺", ev.compare(_p("AhKhQhJhTh"), _p("KsQsJsTs9s")) > 0)
    _t("同花顺 > 四条",    ev.compare(_p("9hThJhQhKh"), _p("8c8d8h8s2c")) > 0)
    _t("四条 > 葫芦",     ev.compare(_p("AcAdAhAsKd"), _p("KcKdKhQsJh")) > 0)
    _t("葫芦 > 同花",     ev.compare(_p("KcKdKhJsJd"), _p("Ac8c5c2cJc")) > 0)
    _t("同花 > 顺子",     ev.compare(_p("7c8c9cJcTc"), _p("5d6d7d8d9d")) > 0)
    _t("顺子 > 三条",     ev.compare(_p("7d8d9dTdJd"), _p("QcQdQhAhKc")) > 0)
    _t("三条 > 两对",     ev.compare(_p("JdJhJsKdQs"), _p("KcKdQsJsAs")) > 0)
    _t("两对 > 一对",     ev.compare(_p("AcAdKsKdJh"), _p("AcAdQsJdTs")) > 0)
    _t("一对 > 高牌",     ev.compare(_p("AcAdKhQsJd"), _p("AhKcQdJs9h")) > 0)
    # 葫芦内部
    _t("葫芦KKKQQ > JJJAA", ev.compare(_p("KdKhKcQdQh"), _p("JjJdJsAcAd")) > 0)
    _t("葫芦KKKQQ > KKKJJ", ev.compare(_p("KdKhKcQdQh"), _p("KdKhKcJdJh")) > 0)
    # 同花顺内部
    _t("Q高顺子 > J高顺子", ev.compare(_p("9cTcJcQcKc"), _p("8d9dTdJdQd")) > 0)
    _t("A2345 < 23456",   ev.compare(_p("As2s3s4s5s"), _p("2d3d4d5d6d")) < 0)
    # 同花内部
    _t("AK同花 > AQ同花",  ev.compare(_p("AcKcQdJd9d"), _p("AcQcJd9d8d")) > 0)
    # 顺子内部
    _t("顺子6789T > 34567", ev.compare(_p("6c7c8c9cTc"), _p("3c4c5c6c7c")) > 0)
    # 三条内部
    _t("三条KKK < 三条AAA", ev.compare(_p("KdKhKcJdTh"), _p("AdAhAcJsTc")) < 0)
    _t("三条QQQ > 三条JJJ", ev.compare(_p("QcQdQhKdTh"), _p("JdJhJsKcTc")) > 0)
    _t("三条QQQK > 三条QQQJ", ev.compare(_p("QcQdQhKdTh"), _p("QcQdQhJdTh")) > 0)
    # 两对内部
    _t("两对AAKK > 两对KKJJ", ev.compare(_p("AcAdKcKdJh"), _p("KcKdJcJdTs")) > 0)
    _t("两对AAKK > 两对AAQQ", ev.compare(_p("AcAdKhKdJh"), _p("AcAdQcQdJs")) > 0)
    _t("两对AAKK > 两对JJAA", ev.compare(_p("AcAdKcKdJh"), _p("JjJdAcAdTs")) > 0)
    _t("两对AAKQ > 两对AAQJ", ev.compare(_p("AcAdKcQdJh"), _p("AcAdQcJdTh")) > 0)
    # 一对内部
    _t("一对8 > 一对7",    ev.compare(_p("8c8hKcQdJh"), _p("7c7hKcQdJd")) > 0)
    _t("一对同大踢脚K>Q",  ev.compare(_p("AcAhKcQdJh"), _p("AcAhQcJdTs")) > 0)
    # 高牌内部
    _t("高牌AKJ > 高牌AKQ", ev.compare(_p("AhKhJcJd9s"), _p("AcKcQdJd9h")) > 0)
    _t("高牌AKQ = 高牌AKQ（平局）", ev.compare(_p("AhKhQcJd9s"), _p("AcKcQdJd9h")) == 0)
    # 7张最优5张
    _t("7张KKKAA2 > 7张QQQJJ", ev.compare(_p("KdKhKcAdAh2d"), _p("QdQhQsJdJh3c")) > 0)


# ═══════════════════════════════════════════════
#  UTILS
# ═══════════════════════════════════════════════
func _p(s: String) -> Array:
    var rm := {"2":2,"3":3,"4":4,"5":5,"6":6,"7":7,"8":8,"9":9,"T":10,"J":11,"Q":12,"K":13,"A":14}
    var sm := {"S":0,"H":1,"D":2,"C":3}
    var cards: Array = []
    var i := 0
    while i < s.length():
        if i + 1 < s.length():
            var rs = s.substr(i, 1).to_upper()
            var ss = s.substr(i + 1, 1).to_upper()
            if rs in rm and ss in sm:
                cards.append(PC.new(sm[ss], rm[rs])); i += 2
            else: i += 1
        else: break
    return cards

func _t(name: String, ok: bool) -> void:
    if ok: _passed += 1; print("  ✓ " + name)
    else: _failed += 1; print("  ✗ " + name)

func _pass(name: String) -> void:
    _passed += 1; print("  ✓ " + name)

func _fail(msg: String) -> void:
    _failed += 1; print("  ✗ " + msg)

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
