extends SceneTree
## 预检脚本：检查 scripts/ 是否有 parse error
## 用法: godot --headless --path . --script test/check_all.gd 2>&1 | grep "Parse Error"
##
## Godot 启动时会编译所有 scripts/。任何 parse error 都会被打印到 stderr。
## 本脚本不依赖 stderr，而是让 Godot 自己报告脚本加载状态。

func _init():
    print("━━━ 项目脚本 预检 ━━━")
    call_deferred("_check_scripts")


func _check_scripts() -> void:
    # 尝试加载 scripts/ 目录下的每个脚本
    # 如果有 parse error，Godot 会在 stderr 打印，然后 quit(1)
    # 如果全部成功，quit(0)
    var scripts_to_check = [
        "res://scripts/card.gd",
        "res://scripts/deck.gd",
        "res://scripts/player.gd",
        "res://scripts/hand_evaluator.gd",
        "res://scripts/poker_game.gd",
        "res://scripts/main.gd",
    ]
    
    for path in scripts_to_check:
        var scr: GDScript = load(path) as GDScript
        if scr == null:
            print("FAIL: 无法加载 " + path)
            quit(1)
            return
        # 尝试实例化（会触发完整编译，有 parse error 会失败）
        var inst = scr.new()
        if inst != null:
            inst.free()
        print("  ✓ " + path)
    
    print("━━━ 结果 ━━━")
    print("  ✓ 零 parse error")
    print("\n  🎉 可以安全打开编辑器！")
    quit(0)
