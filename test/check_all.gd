extends SceneTree
## 预检脚本：加载项目主场景，触发所有 scripts/ 的编译检查
## 用法: godot --headless --path . --script test/check_all.gd 2>&1
##
## 任何 parse error（class_name找不到、enum引用错误、override native方法）
## 都会被 Godot 打印到 stderr。
## self_test.sh 通过检查 stderr 中是否含 "Parse Error" 来判断成功/失败。

func _init():
    print("━━━ 项目脚本 预检 ━━━")
    call_deferred("_load_main_scene")


func _load_main_scene() -> void:
    # 加载主场景会级联编译所有被引用的脚本
    var main_scn = load("res://scenes/main.tscn")
    if main_scn == null:
        print("FAIL: 无法加载 main.tscn")
        quit(1)
        return

    var inst = main_scn.instantiate()
    if inst == null:
        print("FAIL: 无法实例化主场景")
        quit(1)
        return

    inst.free()
    print("主场景加载完成（父进程请检查 stderr 中是否有 Parse Error）")
    quit(0)
