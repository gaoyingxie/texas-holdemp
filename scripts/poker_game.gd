class_name PokerGame

# 预加载class_name脚本，确保全局类型在方法体执行前已注册
const _DeckRef = preload("res://scripts/deck.gd")
const _HE = preload("res://scripts/hand_evaluator.gd")
const _PlayerRef = preload("res://scripts/player.gd")
const _CardRef = preload("res://scripts/card.gd")

## 德州扑克游戏状态机
## 管理轮次、下注、结算

enum GameStage { PREFLOP, FLOP, TURN, RIVER, SHOWDOWN }
enum Action { FOLD, CHECK, CALL, RAISE, ALLIN, WAITING }

var deck
var evaluator
var players = []
var community = []
var stage = GameStage.PREFLOP
var pot: int = 0
var current_bet: int = 0   # 本轮最低跟注额
var dealer_idx: int = 0
var to_act_idx: int = 0
var game_over: bool = false
var winner_name: String = ""

var bb_amount: int = 20

func _init():
    deck = _DeckRef.new()
    evaluator = _HE.new()


func add_player(name: String, chips: int) -> Variant:
    var p = _PlayerRef.new(name, chips)
    players.append(p)
    return p


func start_new_hand():
    deck = _DeckRef.new()
    deck.shuffle()
    community.clear()
    pot = 0
    current_bet = 0
    stage = GameStage.PREFLOP
    game_over = false
    winner_name = ""
    for p in players:
        p.reset()
    dealer_idx = (dealer_idx + 1) % players.size()
    deal_hole_cards()


func deal_hole_cards():
    for p in players:
        p.hand = deck.deal(2)


func deal_community(count: int):
    for i in range(count):
        if deck.remaining() > 0:
            community.append(deck.deal(1)[0])


func next_stage():
    reset_bet()
    match stage:
        GameStage.PREFLOP: stage = GameStage.FLOP; deal_community(3)
        GameStage.FLOP:    stage = GameStage.TURN; deal_community(1)
        GameStage.TURN:    stage = GameStage.RIVER; deal_community(1)
        GameStage.RIVER:   stage = GameStage.SHOWDOWN


func active_players() -> Variant:
    var active = []
    for p in players:
        if not p.is_folded:
            active.append(p)
    return active


func folded_players() -> Variant:
    var folded = []
    for p in players:
        if p.is_folded:
            folded.append(p)
    return folded


func do_fold(pl):
    pl.is_folded = true


func do_call(pl) -> int:
    var amount = pl.bet(current_bet)
    pot += amount
    return amount


func do_raise(pl, total: int) -> int:
    current_bet = total
    var amount = pl.bet(total)
    pot += amount
    return amount


func do_all_in(pl) -> int:
    var amount = pl.bet(pl.chips)
    if amount > current_bet:
        current_bet = amount
    pot += amount
    return amount


func do_check(pl) -> int:
    return 0


func reset_bet():
    current_bet = 0


func award_pot(winner):
    winner.chips += pot
    pot = 0


func best_hand_of(pl) -> Array:
    return evaluator.evaluate(pl.hand + community)


func determine_winner() -> Variant:
    var active = active_players()
    if active.is_empty():
        return null
    if active.size() == 1:
        return active[0]
    var best: Array = best_hand_of(active[0])
    var winner = active[0]
    for i in range(1, active.size()):
        var sc: Array = best_hand_of(active[i])
        if evaluator.compare(sc, best) > 0:
            best = sc
            winner = active[i]
    return winner


func resolve_showdown():
    var w = determine_winner()
    if w != null:
        award_pot(w)
        winner_name = w.name
    game_over = true
