#!/bin/bash
# 自测脚本：跑所有测试 + 主动检测 Editor 级别 parse error
# 用法: cd texas-holdemp && bash self_test.sh
set -e
cd "$(dirname "$0")"

GODOT=${GODOT:-godot}
TMP=$(mktemp)

cleanup() { rm -f "$TMP"; }
trap cleanup EXIT

run_test() {
    local name="$1"
    local cmd="$2"
    echo "━━━ $name ━━━"
    # 捕获 stdout+stderr，然后分别处理
    if $cmd >"$TMP.out" 2>&1; then
        # 命令成功退出，看 stderr 有没有 Parse Error
        if grep -q "Parse Error" "$TMP.out" 2>/dev/null; then
            local count=$(grep -c "Parse Error" "$TMP.out")
            echo "  ✗ 发现 $count 个 parse error（Editor级，必须修复）"
            grep "Parse Error" "$TMP.out" | sed 's/^/    /'
            return 1
        fi
        # 成功且无 parse error
        if grep -q "failed: [1-9]" "$TMP.out" 2>/dev/null; then
            echo "  ✗ 测试有失败"
            return 1
        fi
        echo "  ✓ 通过"
        return 0
    else
        # 命令退出码非0
        if grep -q "Parse Error" "$TMP.out" 2>/dev/null; then
            local count=$(grep -c "Parse Error" "$TMP.out")
            echo "  ✗ 发现 $count 个 parse error"
            return 1
        fi
        echo "  ✗ 非零退出码"
        return 1
    fi
}

echo "=== Texas Hold'em 自测开始 ==="
echo ""

PASS=0
FAIL=0

run_test "预检: Editor级parse error检测" \
    "$GODOT --headless --path . --script test/check_all.gd" || FAIL=$((FAIL+1))
run_test "runner" \
    "$GODOT --headless --path . --script test/runner.gd" || FAIL=$((FAIL+1))
run_test "betting" \
    "$GODOT --headless --path . --script test/test_betting.gd" || FAIL=$((FAIL+1))
run_test "integration" \
    "$GODOT --headless --path . --script test/test_integration.gd" || FAIL=$((FAIL+1))

echo ""
echo "━━━ 汇总 ━━━"
echo "  ✓ $PASS 项通过"
echo "  ✗ $FAIL 项失败"
echo ""
if [ $FAIL -eq 0 ]; then
    echo "  🎉 全部通过，可安全打开编辑器！"
else
    echo "  ⚠️  有问题，修复后再打开编辑器"
    echo "     Editor级parse error修复方法："
    echo "     1. 确保 class_name 脚本先于使用它的脚本被加载"
    echo "     2. 检查 scripts/ 中是否有类型注解用错了名字"
fi

exit $FAIL
