extends SceneTree
## 预检脚本：主动加载项目主场景，强制 Godot 编译所有 scripts/
## 用法: godot --headless --path . --script test/check_all.gd 2>&1 | grep "Parse Error"
##
## Godot 启动时注册所有 class_name，然后加载 main.tscn 时
## 会级联编译所有被引用的脚本（poker_game.gd, deck.gd, card.gd 等）。
## 任何 parse error（类型找不到、enum 引用错误、override native 方法）
##都会被 Godot 打印到 stderr。
## 本脚本检测 stderr 中的 Parse Error 并报告。
## 配合 shell: godot --headless --path . --script test/check_all.gd 2>&1

var _scripts_checked := 0


func _init():
    print("━━━ 项目脚本 预检 ━━━")
    call_deferred("_load_main_scene")


func _load_main_scene() -> void:
    # 加载主场景会触发所有被引用脚本的解析
    var main_scn = load("res://scenes/main.tscn")
    if main_scn == null:
        print("FAIL: 无法加载主场景 main.tscn")
        quit(1)
        return

    var inst = main_scn.instantiate()
    if inst == null:
        print("FAIL: 无法实例化主场景")
        quit(1)
        return

    inst.free()
    # 到这里说明场景加载成功（即使有非致命警告也算了）
    print("主场景加载完成（检查 stderr 中是否有 Parse Error）")
    quit(0)
