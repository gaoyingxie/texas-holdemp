# 德州扑克 — SPEC.md

## 1. 已完成的需求（测试驱动）

### 扑克牌基础
- `[x]` 52张牌，花色×面值不重复
- `[x]` 洗牌后随机发牌
- `[x]` 发牌均匀：每人2张，桌面5张

### 比大小
- `[x]` 同花顺 > 四条 > 葫芦 > 同花 > 顺子 > 三条 > 两对 > 一对 > 高牌
- `[x]` 同 rank 时比踢脚（Kickers）
- `[x]` 花色不比大小（平局时平分底池）

### 下注轮次
- `[x]` Pre-flop：每人2张，押盲注
- `[x]` Flop：翻3张公共牌，下注
- `[x]` Turn：翻第4张，下注
- `[x]` River：翻第5张，下注
- `[x]` Showdown：摊牌比大小

### 行动选项
- `[x]` Fold（弃牌）
- `[x]` Check（过牌）
- `[x]` Call（跟注）
- `[x]` Raise（加注）
- `[x]` All-in（全压）

### 游戏流程
- `[x]` 玩家初始筹码一致（$1000）
- `[x]` 有人筹码归零 → 游戏结束
- `[x]` 可以开始新游戏

### UI层接口
- `[x]` 卡牌文字正确渲染（♠♥♦♣ + 2~A）
- `[x]` 玩家手牌访问（2张）
- `[x]` 公共牌访问（0~5张）
- `[x]` Fold/Call/Raise/All-in 操作
- `[x]` 阶段切换（Pre-flop→River→Showdown）
- `[x]` 游戏结束状态正确设置

## 2. 测试覆盖

| 测试文件 | 测试数 | 覆盖 |
|---|---|---|
| test/runner.gd | 37 | 发牌、洗牌、9种牌型 |
| test/test_betting.gd | 31 | Fold/Call/Raise/All-in、底池、阶段 |
| test/test_integration.gd | 29 | UI层↔核心层所有接口 |

**总计：97 个测试**

## 3. 文件结构

```
texas-holdemp/
├── SPEC.md
├── project.godot
├── icon.svg
├── scenes/
│   └── main.tscn         # 完整UI
├── scripts/
│   ├── card.gd           # PlayingCard 类
│   ├── deck.gd          # 牌组
│   ├── hand_evaluator.gd # 手牌评估（9种牌型）
│   ├── player.gd         # 玩家/AI 基类
│   ├── poker_game.gd     # 游戏状态机
│   └── main.gd          # UI 控制器
└── test/
    ├── runner.gd         # 核心逻辑测试
    ├── test_betting.gd   # 下注逻辑测试
    └── test_integration.gd # UI接口测试
```
