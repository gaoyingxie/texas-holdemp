#!/bin/bash
# 自测脚本：跑所有测试 + 主动检测 Editor 级别 parse error
# 用法: cd texas-holdemp && bash self_test.sh
cd "$(dirname "$0")"

GODOT=${GODOT:-godot}
TMP=$(mktemp)
FAIL_COUNT=0

cleanup() { rm -f "$TMP"; }
trap cleanup EXIT

echo "=== Texas Hold'em 自测开始 ==="
echo ""

# 预检：Editor级 parse error 检测
echo "━━━ 预检: Editor级parse error检测 ━━━"
# 运行 Godot 加载项目，捕获 stderr 中所有 Parse Error
# redirect stderr to TMP, stdout to /dev/null
$GODOT --headless --path . --quit >/dev/null 2>"$TMP"
PARSE_ERRORS=$(grep -c "Parse Error" "$TMP" || true)
if [ "$PARSE_ERRORS" -gt 0 ]; then
    echo "  ✗ 发现 $PARSE_ERRORS 个 parse error（Editor级，必须修复）"
    grep "Parse Error" "$TMP" | head -5 | sed 's/^/    /'
    FAIL_COUNT=$((FAIL_COUNT+1))
else
    echo "  ✓ 零 parse error，可以安全打开编辑器"
fi
echo ""

# 跑测试套件
run_test() {
    local name="$1"; shift
    local cmd="$*"
    echo "━━━ $name ━━━"
    local out=$($cmd 2>/dev/null | grep -E "passed|failed|✓|✗" | tail -5)
    if echo "$out" | grep -q "failed: [1-9]"; then
        echo "$out"
        echo "  ✗ 测试有失败"
        FAIL_COUNT=$((FAIL_COUNT+1))
    else
        echo "$out"
        echo "  ✓ 通过"
    fi
}

run_test "runner" "$GODOT --headless --path . --script test/runner.gd"
run_test "betting" "$GODOT --headless --path . --script test/test_betting.gd"
run_test "integration" "$GODOT --headless --path . --script test/test_integration.gd"

echo ""
echo "━━━ 汇总 ━━━"
if [ $FAIL_COUNT -eq 0 ]; then
    echo "  🎉 全部通过，可安全打开编辑器！"
else
    echo "  ✗ $FAIL_COUNT 项失败，需修复后再打开编辑器"
fi
exit $FAIL_COUNT
