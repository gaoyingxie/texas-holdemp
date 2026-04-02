class_name Deck
## 52张扑克牌组

var _cards: Array[PlayingCard] = []


func _init():
    for suit in range(4):
        for rank in range(2, 15):
            _cards.append(PlayingCard.new(suit, rank))


func shuffle() -> void:
    var rng := RandomNumberGenerator.new()
    for i in range(_cards.size()):
        var j := rng.randi_range(i, _cards.size() - 1)
        var tmp := _cards[i]
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
