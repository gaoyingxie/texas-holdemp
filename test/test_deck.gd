extends SceneTree
## 德州扑克 TDD 运行器
## 用法: godot --headless --script test/test_deck.gd

const PASS := "2e8b57"
const FAIL := "dc143c"
const RESET := "c"

var _passed := 0
var _failed := 0


func _init():
    print("━━━ 德州扑克 测试 ━━━\n")
    call_deferred("_run_tests")


func _run_tests() -> void:
    _test_deck_size()
    _test_deck_no_duplicates()
    _test_shuffle_changes_order()
    _test_deal_removes_cards()
    _test_deal_five_players()
    _test_draw_from_empty()
    _print_summary()
    quit(0 if _failed == 0 else 1)


# ── deck.gd 最小实现 ──
class PlayingCard:
    var suit: int
    var rank: int

    func _init(s: int, r: int):
        suit = s
        rank = r

    func _to_string() -> String:
        var suit_names := ["S","H","D","C"]
        var rank_names := ["","","2","3","4","5","6","7","8","9","10","J","Q","K","A"]
        return rank_names[rank] + suit_names[suit]


class Deck:
    var _cards: Array[PlayingCard] = []

    func _init():
        for suit in range(4):
            for rank in range(2, 15):
                _cards.append(PlayingCard.new(suit, rank))

    func shuffle() -> void:
        var rng := RandomNumberGenerator.new()
        for i in range(_cards.size()):
            var j := rng.randi_range(i, _cards.size() - 1)
            var tmp: PlayingCard = _cards[i]
            _cards[i] = _cards[j]
            _cards[j] = tmp

    func deal(count: int) -> Array[PlayingCard]:
        var hand: Array[PlayingCard] = []
        for i in range(count):
            if _cards.is_empty():
                break
            hand.append(_cards.pop_back())
        return hand

    func remaining() -> int:
        return _cards.size()


# ── 测试：52张牌 ──
func _test_deck_size() -> void:
    var d := Deck.new()
    _assert(d._cards.size() == 52, "牌堆应有52张，当前=" + str(d._cards.size()))


# ── 测试：没有重复牌 ──
func _test_deck_no_duplicates() -> void:
    var d := Deck.new()
    var seen_keys: Array[String] = []
    for card in d._cards:
        var key := str(card.suit) + "-" + str(card.rank)
        if key in seen_keys:
            _failed += 1
            print("[dc143c]> ✗ 有重复: " + key + "[" + RESET + "]")
            return
        seen_keys.append(key)
    _passed += 1
    print("[2e8b57]> ✓ 无重复牌[" + RESET + "]")


# ── 测试：洗牌后顺序改变 ──
func _test_shuffle_changes_order() -> void:
    var d1 := Deck.new()
    var order1: Array = d1._cards.map(func(c: PlayingCard) -> String: return str(c.suit) + str(c.rank))
    d1.shuffle()
    var order2: Array = d1._cards.map(func(c: PlayingCard) -> String: return str(c.suit) + str(c.rank))
    var same := true
    for i in range(order1.size()):
        if order1[i] != order2[i]:
            same = false
            break
    _assert(not same, "洗牌后顺序应改变")


# ── 测试：发牌移除卡牌 ──
func _test_deal_removes_cards() -> void:
    var d := Deck.new()
    var before := d.remaining()
    var hand := d.deal(5)
    _assert(d.remaining() == before - 5, "发5张后剩余=" + str(before - 5) + "，当前=" + str(d.remaining()))
    _assert(hand.size() == 5, "应发5张，当前=" + str(hand.size()))


# ── 测试：5人发牌（2+2+2+5+2+2=15张）──
func _test_deal_five_players() -> void:
    var d := Deck.new()
    d.deal(2)  # p1
    d.deal(2)  # p2
    d.deal(2)  # p3
    var flop := d.deal(5)  # 公共牌
    d.deal(2)  # p4
    d.deal(2)  # p5
    _assert(d.remaining() == 52 - 15, "应剩37张，当前=" + str(d.remaining()))


# ── 测试：空牌堆不能继续发 ──
func _test_draw_from_empty() -> void:
    var d := Deck.new()
    d.deal(52)
    var empty_hand := d.deal(1)
    _assert(empty_hand.size() == 0, "空堆应返回空数组")


# ── 工具 ──
func _test(name: String, cond: bool, detail: String = "") -> void:
    if cond:
        _passed += 1
        _print("[2e8b57]", "✓ " + name)
    else:
        _failed += 1
        _print("[dc143c]", "✗ " + name + (": " + detail if detail else ""))


func _assert(cond: bool, detail: String) -> void:
    if not cond:
        _failed += 1
        _print("[dc143c]", "  assertion failed: " + detail)


func _print(color: String, msg: String) -> void:
    print(color + "> " + msg + "[" + RESET + "]")


func _print_summary() -> void:
    print("\n━━━ 结果 ━━━")
    _print("[2e8b57]", "  ✓ passed: " + str(_passed))
    _print("[dc143c]", "  ✗ failed: " + str(_failed))
    if _failed == 0:
        _print("[2e8b57]", "  🎉 全部通过！")
    else:
        _print("[dc143c]", "  ⚠️  " + str(_failed) + " 个失败")
