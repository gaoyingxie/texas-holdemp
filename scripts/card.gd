class_name PlayingCard
## 一张扑克牌

var suit: int  # 0=Spades, 1=Hearts, 2=Diamonds, 3=Clubs
var rank: int   # 2=2, ... 10=10, 11=J, 12=Q, 13=K, 14=A

func _init(s: int, r: int):
	suit = s
	rank = r

func card_str() -> String:
	var suits := ["S","H","D","C"]
	var ranks := ["","2","3","4","5","6","7","8","9","10","J","Q","K","A"]
	return ranks[rank] + suits[suit]
