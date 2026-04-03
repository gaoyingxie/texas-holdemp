#!/bin/bash
# 自测脚本：跑所有测试 + 主动检测 Editor 级别 parse error
set -e
cd "$(dirname "$0")"

GODOT=${GODOT:-godot}
PASS=0
FAIL=0

run_test() {
    local name="$1"
    local cmd="$2"
    echo "━━━ $name ━━━"
    if $cmd 2>&1 | grep -q "Parse Error"; then
        echo "  ✗ 发现 parse error"
        FAIL=$((FAIL+1))
    elif $cmd 2>&1 | grep -q "failed: [1-9]"; then
        echo "  ✗ 测试有失败"
        FAIL=$((FAIL+1))
    else
        echo "  ✓ 通过"
        PASS=$((PASS+1))
    fi
}

echo "=== 自测开始 ==="
run_test "预检: Editor级parse error检测" "$GODOT --headless --path . --script test/check_all.gd"
run_test "runner" "$GODOT --headless --path . --script test/runner.gd"
run_test "betting" "$GODOT --headless --path . --script test/test_betting.gd"
run_test "integration" "$GODOT --headless --path . --script test/test_integration.gd"

echo ""
echo "━━━ 汇总 ━━━"
echo "  ✓ $PASS 项通过"
echo "  ✗ $FAIL 项失败"
[ $FAIL -eq 0 ] && echo "  🎉 全部通过，可安全打开编辑器！" || echo "  ⚠️  有问题，修复后再打开编辑器"
exit $FAIL
