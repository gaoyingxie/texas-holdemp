class_name HandEvaluator
## 德州扑克手牌评估器
## evaluate(cards) 返回 [hand_rank, kickers]
## hand_rank: 9=皇家同花顺,8=同花顺,7=四条,6=葫芦,5=同花,4=顺子,3=三条,2=两对,1=一对,0=高牌

func evaluate(cards: Array[PlayingCard]) -> Array:
    var best := _best_five(cards)
    var rc: Dictionary = _rank_counts(best)
    var flush := _is_flush(best)
    var si: Array = _is_straight(best)
    var is_straight: bool = si[0]
    var straight_high: int = si[1]

    # 皇家同花顺（rank=9，最高）
    if flush and is_straight and straight_high == 14:
        return [9, [14]]
    # 同花顺（rank=8）
    if flush and is_straight:
        return [8, [straight_high]]
    # 四条（rank=7）
    if _has_count(rc, 4):
        var quads: int = _rank_of_count(rc, 4)
        var kicker: int = _max_kicker_one(rc, [quads])
        return [7, [quads, kicker]]
    # 葫芦（rank=6，3+2同时满足）
    if _has_count(rc, 3) and _has_count(rc, 2):
        var trips: int = _rank_of_count(rc, 3)
        var pair: int = _rank_of_count(rc, 2)
        return [6, [trips, pair]]
    # 同花（rank=5）
    if flush:
        return [5, _sorted_ranks(best)]
    # 顺子（rank=4）
    if is_straight:
        return [4, [straight_high]]
    # 三条（rank=3，3但不是葫芦）
    if _has_count(rc, 3):
        var trips3: int = _rank_of_count(rc, 3)
        var kickers3: Array = _top_kickers(rc, [trips3], 2)
        return [3, [trips3] + kickers3]
    # 两对（rank=2，两个2）
    if _count_values_equal(rc, 2) == 2:
        var pairs: Array = _ranks_of_count(rc, 2)
        pairs.sort(); pairs.reverse()
        var kickers2: Array = _top_kickers(rc, pairs, 1)
        return [2, pairs + kickers2]
    # 一对（rank=1）
    if _has_count(rc, 2):
        var pair_r: int = _rank_of_count(rc, 2)
        var kickers1: Array = _top_kickers(rc, [pair_r], 3)
        return [1, [pair_r] + kickers1]
    # 高牌（rank=0）
    return [0, _top_kickers(rc, [], 5)]


## 7张选5张最优
func best_five(cards: Array[PlayingCard]) -> Array[PlayingCard]:
    return _best_five(cards)


## 比较两手牌，返回 1=hand1赢，-1=hand2赢，0=平局
func compare(hand1: Array[PlayingCard], hand2: Array[PlayingCard]) -> int:
    var s1: Array = evaluate(hand1)
    var s2: Array = evaluate(hand2)
    return _cmp(s1, s2)


func _best_five(cards: Array[PlayingCard]) -> Array[PlayingCard]:
    if cards.size() <= 5:
        return cards.duplicate()
    var best_score: Array = []
    var best_hand: Array[PlayingCard] = []
    var n := cards.size()
    for i in range(n - 4):
        for j in range(i + 1, n - 3):
            for k in range(j + 1, n - 2):
                for l in range(k + 1, n - 1):
                    for m in range(l + 1, n):
                        var combo: Array[PlayingCard] = [cards[i], cards[j], cards[k], cards[l], cards[m]]
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


func _rank_counts(cards: Array[PlayingCard]) -> Dictionary:
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


func _is_flush(cards: Array[PlayingCard]) -> bool:
    if cards.size() < 5:
        return false
    var s: int = cards[0].suit
    for c in cards:
        if c.suit != s:
            return false
    return true


func _is_straight(cards: Array[PlayingCard]) -> Array:
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
    # Wheel A-2-3-4-5（特殊）
    if unique == [2, 3, 4, 5, 14]:
        return [true, 5]
    # 5张顺子：每相邻两张必须差1
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


func _sorted_ranks(cards: Array[PlayingCard]) -> Array:
    var ranks: Array = []
    for c in cards:
        ranks.append(c.rank)
    ranks.sort(); ranks.reverse()
    return ranks.slice(0, 5)
