extends SceneTree

func _init():
    print("━━━ 调试皇家同花顺 ━━━")
    call_deferred("_run")

func _run() -> void:
    var ev := HandEvaluator.new()
    var h1 := _parse("AhKhQhJhTh")
    var h2 := _parse("TsJsQsKsAs")
    print("royal (AhKhQhJhTh): ", ev.evaluate(h1))
    print("straight flush (TsJsQsKsAs): ", ev.evaluate(h2))
    print("cmp: ", ev._cmp(ev.evaluate(h1), ev.evaluate(h2)))
    quit(0)

class Card:
    var suit: int; var rank: int
    func _init(s: int, r: int): suit = s; rank = r

class HandEvaluator:
    func evaluate(cards: Array[Card]) -> Array:
        var best := _best_five(cards)
        var rc: Dictionary = _rank_counts(best)
        var flush := _is_flush(best)
        var si: Array = _is_straight(best)
        var is_straight: bool = si[0]
        var straight_high: int = si[1]
        print("  flush=", flush, " is_straight=", is_straight, " high=", straight_high)
        if flush and is_straight and straight_high == 14: return [9, [14]]
        if flush and is_straight: return [8, [straight_high]]
        if _has_count(rc, 4):
            var quads: int = _rank_of_count(rc, 4)
            var kicker: int = _max_kicker_one(rc, [quads])
            return [7, [quads, kicker]]
        if _has_count(rc, 3) and _has_count(rc, 2):
            var trips: int = _rank_of_count(rc, 3)
            var pair: int = _rank_of_count(rc, 2)
            return [6, [trips, pair]]
        if flush: return [5, _sorted_ranks(best)]
        if is_straight: return [4, [straight_high]]
        if _has_count(rc, 3):
            var trips3: int = _rank_of_count(rc, 3)
            var kickers3: Array = _top_kickers(rc, [trips3], 2)
            return [3, [trips3] + kickers3]
        if _count_values_equal(rc, 2) == 2:
            var pairs: Array = _ranks_of_count(rc, 2); pairs.sort(); pairs.reverse()
            var kickers2: Array = _top_kickers(rc, pairs, 1)
            return [2, pairs + kickers2]
        if _has_count(rc, 2):
            var pair_r: int = _rank_of_count(rc, 2)
            var kickers1: Array = _top_kickers(rc, [pair_r], 3)
            return [1, [pair_r] + kickers1]
        return [0, _top_kickers(rc, [], 5)]

    func _best_five(cards: Array[Card]) -> Array[Card]:
        return cards.duplicate()

    func _cmp(a: Array, b: Array) -> int:
        if a[0] != b[0]: return a[0] - b[0]
        var ta: Array = a[1]; var tb: Array = b[1]
        for i in range(min(ta.size(), tb.size())):
            if ta[i] != tb[i]: return ta[i] - tb[i]
        return 0
    func _rank_counts(cards: Array[Card]) -> Dictionary:
        var counts: Dictionary = {}
        for c in cards: counts[c.rank] = counts.get(c.rank, 0) + 1
        return counts
    func _has_count(rc: Dictionary, target: int) -> bool:
        for v in rc.values():
            if v == target: return true
        return false
    func _count_values_equal(rc: Dictionary, target: int) -> int:
        var cnt := 0
        for v in rc.values():
            if v == target: cnt += 1
        return cnt
    func _is_flush(cards: Array[Card]) -> bool:
        if cards.size() < 5: return false
        var s: int = cards[0].suit
        for c in cards:
            if c.suit != s: return false
        return true
    func _is_straight(cards: Array[Card]) -> Array:
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
            var all_consecutive: bool = true
            for offset in range(4):
                if unique[start + offset + 1] - unique[start + offset] != 1:
                    all_consecutive = false; break
            if all_consecutive:
                return [true, unique[start + 4]]
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
        var best: int = 0
        for r in rc:
            var ri: int = r as int
            if not (ri in exclude) and ri > best: best = ri
        return best
    func _top_kickers(rc: Dictionary, exclude: Array, n: int) -> Array:
        var all_ranks: Array = []
        for r in rc:
            var ri: int = r as int
            if not (ri in exclude): all_ranks.append(ri)
        all_ranks.sort(); all_ranks.reverse()
        return all_ranks.slice(0, n)
    func _sorted_ranks(cards: Array[Card]) -> Array:
        var ranks: Array = []
        for c in cards: ranks.append(c.rank)
        ranks.sort(); ranks.reverse()
        return ranks.slice(0, 5)

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
                cards.append(Card.new(suit_map[ss], rank_map[rs])); i += 2
            else: i += 1
        else: break
    return cards
