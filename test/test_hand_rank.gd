extends SceneTree
## 手牌评估器测试
## 用法: godot --headless --script test/test_hand_rank.gd

var _passed := 0
var _failed := 0


func _init():
    print("━━━ 手牌评估器 测试 ━━━\n")
    call_deferred("_run_tests")


func _run_tests() -> void:
    # 基础：高牌 vs 对子
    _test("对A > 对K",          func(): return _compare("AhAd", "KcKd") > 0)
    _test("对K < 对A",          func(): return _compare("KhKd", "AcAs") < 0)

    # 牌型强度
    _test("皇家同花顺 > 普通同花顺", func(): return _compare("AhKhQhJhTh", "KsQsJsTs9s") > 0)
    _test("同花顺 > 四条",       func(): return _compare("9hThJhQhKh", "8c8d8h8s2c") > 0)
    _test("四条 > 葫芦",         func(): return _compare("AcAdAhAsKd", "KcKdKhQsJh") > 0)
    _test("葫芦 > 同花",         func(): return _compare("KcKdKhJsJd", "Ac8c5c2cJc") > 0)
    _test("同花 > 顺子",         func(): return _compare("7c8c9cJcTc", "5d6d7d8d9d") > 0)
    _test("顺子 > 三条",         func(): return _compare("7d8d9dTdJd", "QcQdQhAhKc") > 0)
    _test("三条 > 两对",         func(): return _compare("JdJhJsKdQs", "KcKdQsJsAs") > 0)
    _test("两对 > 一对",         func(): return _compare("AcAdKsKdJh", "AcAdQsJdTs") > 0)
    _test("一对 > 高牌",         func(): return _compare("AcAdKhQsJd", "AhKcQdJs9h") > 0)

    # 葫芦内部
    _test("葫芦KKKQQ > 葫芦JJJAA", func(): return _compare("KdKhKcQdQh", "JjJdJsAcAd") > 0)
    _test("葫芦KKKQQ > 葫芦KKKJJ", func(): return _compare("KdKhKcQdQh", "KdKhKcJdJh") > 0)

    # 同花顺内部
    _test("Q高顺子 > J高顺子",   func(): return _compare("9cTcJcQcKc", "8d9dTdJdQd") > 0)
    _test("A2345 < 23456",       func(): return _compare("As2s3s4s5s", "2d3d4d5d6d") < 0)

    # 同花内部
    _test("AK同花 > AQ同花",     func(): return _compare("AcKcQdJd9d", "AcQcJd9d8d") > 0)

    # 顺子内部
    _test("顺子6789T > 34567",  func(): return _compare("6c7c8c9cTc", "3c4c5c6c7c") > 0)

    # 三条内部
    _test("三条KKK < 三条AAA",  func(): return _compare("KdKhKcJdTh", "AdAhAcJsTc") < 0)
    _test("三条QQQ > 三条JJJ",  func(): return _compare("QcQdQhKdTh", "JdJhJsKcTc") > 0)
    _test("三条QQQK > 三条QQQJ", func(): return _compare("QcQdQhKdTh", "QcQdQhJdTh") > 0)

    # 两对内部
    _test("两对AAKK > 两对KKJJ", func(): return _compare("AcAdKcKdJh", "KcKdJcJdTs") > 0)
    _test("两对AAKK > 两对AAQQ", func(): return _compare("AcAdKhKdJh", "AcAdQcQdJs") > 0)
    _test("两对AAKK > 两对JJAA", func(): return _compare("AcAdKcKdJh", "JjJdAcAdTs") > 0)
    _test("两对AAKQ > 两对AAQJ", func(): return _compare("AcAdKcQdJh", "AcAdQcJdTh") > 0)

    # 一对内部
    _test("一对8 > 一对7",       func(): return _compare("8c8hKcQdJh", "7c7hKcQdJd") > 0)
    _test("一对同大踢脚K>Q",     func(): return _compare("AcAhKcQdJh", "AcAhQcJdTs") > 0)

    # 高牌内部
    _test("高牌AKJ > 高牌AKQ",   func(): return _compare("AhKhJcJd9s", "AcKcQdJd9h") > 0)
    _test("高牌AKQ = 高牌AKQ（平局）", func(): return _compare("AhKhQcJd9s", "AcKcQdJd9h") == 0)

    # 德州扑克7张选最优
    _test("7张KKKAA2 > 7张QQQJJ", func(): return _compare("KdKhKcAdAh2d", "QdQhQsJdJh3c") > 0)

    _print_summary()
    quit(0 if _failed == 0 else 1)


# ── 手牌评估器 ──
class Card:
    var suit: int
    var rank: int
    func _init(s: int, r: int):
        suit = s; rank = r


class HandEvaluator:
    func evaluate(cards: Array[Card]) -> Array:
        var best := _best_five(cards)
        var rc: Dictionary = _rank_counts(best)
        var flush := _is_flush(best)
        var straight_info: Array = _is_straight(best)
        var is_straight: bool = straight_info[0]
        var straight_high: int = straight_info[1]

        # 皇家同花顺（rank=9，最高）
        if flush and is_straight and straight_high == 14:
            return [9, [14]]
        # 同花顺（rank=8）
        if flush and is_straight:
            return [8, [straight_high]]
        # 四条
        if _has_count(rc, 4):
            var quads: int = _rank_of_count(rc, 4)
            var kicker: int = _max_kicker_one(rc, [quads])
            return [7, [quads, kicker]]
        # 葫芦（3+2同时满足）
        if _has_count(rc, 3) and _has_count(rc, 2):
            var trips: int = _rank_of_count(rc, 3)
            var pair: int = _rank_of_count(rc, 2)
            return [6, [trips, pair]]
        # 同花
        if flush:
            return [5, _sorted_ranks(best)]
        # 顺子
        if is_straight:
            return [4, [straight_high]]
        # 三条（3但不是葫芦）
        if _has_count(rc, 3):
            var trips3: int = _rank_of_count(rc, 3)
            var kickers3: Array = _top_kickers(rc, [trips3], 2)
            return [3, [trips3] + kickers3]
        # 两对（2+2）
        if _count_values_equal(rc, 2) == 2:
            var pairs: Array = _ranks_of_count(rc, 2)
            pairs.sort(); pairs.reverse()
            var kickers2: Array = _top_kickers(rc, pairs, 1)
            return [2, pairs + kickers2]
        # 一对
        if _has_count(rc, 2):
            var pair_r: int = _rank_of_count(rc, 2)
            var kickers1: Array = _top_kickers(rc, [pair_r], 3)
            return [1, [pair_r] + kickers1]
        # 高牌
        return [0, _top_kickers(rc, [], 5)]

    func _best_five(cards: Array[Card]) -> Array[Card]:
        if cards.size() <= 5:
            return cards.duplicate()
        var best_score: Array = []
        var best_hand: Array[Card] = []
        var n := cards.size()
        for i in range(n - 4):
            for j in range(i + 1, n - 3):
                for k in range(j + 1, n - 2):
                    for l in range(k + 1, n - 1):
                        for m in range(l + 1, n):
                            var combo: Array[Card] = [cards[i], cards[j], cards[k], cards[l], cards[m]]
                            var score: Array = evaluate(combo)
                            if best_score.is_empty() or _cmp(score, best_score) > 0:
                                best_score = score
                                best_hand = combo
        return best_hand

    func _cmp(a: Array, b: Array) -> int:
        if a[0] != b[0]:
            return a[0] - b[0]
        var ta: Array = a[1]
        var tb: Array = b[1]
        for i in range(min(ta.size(), tb.size())):
            if ta[i] != tb[i]:
                return ta[i] - tb[i]
        return 0

    func _rank_counts(cards: Array[Card]) -> Dictionary:
        var counts: Dictionary = {}
        for c in cards:
            counts[c.rank] = counts.get(c.rank, 0) + 1
        return counts

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

    func _is_flush(cards: Array[Card]) -> bool:
        if cards.size() < 5:
            return false
        var s: int = cards[0].suit
        for c in cards:
            if c.suit != s:
                return false
        return true

    func _is_straight(cards: Array[Card]) -> Array:
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
        # Wheel A2345（特殊：1,2,3,4,5）
        if unique == [2, 3, 4, 5, 14]:
            return [true, 5]
        # 检查每个可能的5张顺子：每相邻两张必须差1
        for start in range(unique.size() - 4):
            var all_consecutive: bool = true
            for offset in range(4):
                if unique[start + offset + 1] - unique[start + offset] != 1:
                    all_consecutive = false
                    break
            if all_consecutive:
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
        var best: int = 0
        for r in rc:
            var ri: int = r as int
            if not (ri in exclude) and ri > best:
                best = ri
        return best

    func _top_kickers(rc: Dictionary, exclude: Array, n: int) -> Array:
        var all_ranks: Array = []
        for r in rc:
            var ri: int = r as int
            if not (ri in exclude):
                all_ranks.append(ri)
        all_ranks.sort(); all_ranks.reverse()
        return all_ranks.slice(0, n)

    func _sorted_ranks(cards: Array[Card]) -> Array:
        var ranks: Array = []
        for c in cards:
            ranks.append(c.rank)
        ranks.sort(); ranks.reverse()
        return ranks.slice(0, 5)


# ── 辅助 ──
func _parse(s: String) -> Array[Card]:
    var rank_map := {"2":2,"3":3,"4":4,"5":5,"6":6,"7":7,"8":8,"9":9,"T":10,"J":11,"Q":12,"K":13,"A":14}
    var suit_map := {"S":0,"H":1,"D":2,"C":3}
    var cards: Array[Card] = []
    var i := 0
    while i < s.length():
        if i + 1 < s.length():
            var rs: String = s.substr(i, 1).to_upper()
            var ss: String = s.substr(i + 1, 1).to_upper()
            if rs in rank_map and ss in suit_map:
                cards.append(Card.new(suit_map[ss], rank_map[rs]))
                i += 2
            else:
                i += 1
        else:
            break
    return cards


func _compare(s1: String, s2: String) -> int:
    var ev := HandEvaluator.new()
    var sc1: Array = ev.evaluate(_parse(s1))
    var sc2: Array = ev.evaluate(_parse(s2))
    return ev._cmp(sc1, sc2)


func _test(name: String, cond: Callable) -> void:
    var ok: bool = cond.call()
    if ok:
        _passed += 1
        print("[2e8b57]> ✓ " + name + "[c]")
    else:
        _failed += 1
        print("[dc143c]> ✗ " + name + "[c]")


func _print_summary() -> void:
    print("\n━━━ 结果 ━━━")
    print("  passed: " + str(_passed))
    print("  failed: " + str(_failed))
    if _failed == 0:
        print("  🎉 全部通过！")

# ── 调试用，临时 ──
# (已内联在上方，不再追加)
