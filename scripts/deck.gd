# 预加载 PlayingCard（解决类型解析顺序问题）
class_name Deck

const _CardRef = preload("res://scripts/card.gd")

## 52张扑克牌组

var _cards = []


func _init():
    for suit in range(4):
        for rank in range(2, 15):
            _cards.append(_CardRef.new(suit, rank))


func shuffle() -> void:
    var rng = RandomNumberGenerator.new()
    for i in range(_cards.size()):
        var j = rng.randi_range(i, _cards.size() - 1)
        var tmp = _cards[i]
        _cards[i] = _cards[j]
        _cards[j] = tmp


func deal(count: int) -> Variant:
    var hand = []
    for i in range(count):
        if _cards.is_empty():
            break
        hand.append(_cards.pop_back())
    return hand


func remaining() -> int:
    return _cards.size()
