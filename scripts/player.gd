class_name Player
## 玩家/AI 基类

var name: String
var chips: int
var hand: Array[PlayingCard] = []
var is_folded: bool = false
var is_all_in: bool = false

func _init(n: String, c: int):
    name = n
    chips = c


func bet(amount: int) -> int:
    var actual := mini(amount, chips)
    chips -= actual
    if chips == 0:
        is_all_in = true
    return actual


func reset():
    hand.clear()
    is_folded = false
    is_all_in = false
