#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASK="$HERE/../bin/?"
MOCK="$HERE/mock-opencode.sh"
tmpdir="$(mktemp -d)"
export QM_THREADS_DIR="$tmpdir/threads"
trap 'rm -rf "$tmpdir"' EXIT

assert_eq() {
  [[ "$1" == "$2" ]] || { echo "assertion failed: expected [$2], got [$1]" >&2; exit 1; }
}

assert_contains() {
  grep -qF "$2" "$1" || { echo "assertion failed: [$2] not found in [$1]" >&2; exit 1; }
}

# run_case <name> <expected_code> <expected_out> <expected_err_contains> [args...]
run_case() {
  local name="$1" expected_code="$2" expected_out="$3" expected_err="$4"
  shift 4
  set +e
  OPENCODE_BIN="$MOCK" MOCK_SCENARIO=success "$@" >"$tmpdir/$name.out" 2>"$tmpdir/$name.err"
  code=$?
  set -e
  assert_eq "$code" "$expected_code"
  assert_eq "$(<"$tmpdir/$name.out")" "$expected_out"
  if [[ -n "$expected_err" ]]; then
    assert_contains "$tmpdir/$name.err" "$expected_err"
  fi
}

extract_thread_id() {
  grep -oE '\[thread [0-9a-f]{12}\]' "$1" | grep -oE '[0-9a-f]{12}' | head -1
}

# --- basic cases ---
run_case success 0 'mock answer' '[thinking… opencode default model]' env MOCK_SCENARIO=success "$ASK" why is the sky blue
assert_contains "$tmpdir/success.err" "[thread"
assert_contains "$tmpdir/success.err" "[thinking… opencode default model]"

run_case usage 2 '' 'usage: ?' env "$ASK"
run_case bad-agent 2 '' 'invalid agent type' env "$ASK" -a:wat hello

run_case override-success 0 'mock answer' '[thinking… provider/model]' env MOCK_SCENARIO=success "$ASK" -m:provider/model hello
run_case long-options 0 'mock answer' '[thinking… provider/model]' env MOCK_SCENARIO=success "$ASK" --model:provider/model --workspace:/tmp hello world
run_case agent-type 0 'mock answer' '[thinking… opencode default model]' env MOCK_SCENARIO=success "$ASK" -a:agent do the thing

# model aliases pass through to opencode (expect-model asserts the model arg)
for alias_case in luna terra sol deep flash gemma opus grok; do
  case "$alias_case" in
    luna)  m=openai/gpt-5.6-luna ;;
    terra) m=openai/gpt-5.6-terra ;;
    sol)   m=openai/gpt-5.6-sol ;;
    deep)  m=deepseek/deepseek-v4-pro ;;
    flash) m=deepseek/deepseek-v4-flash ;;
    gemma) m=openrouter/google/gemma-4-31b-it ;;
    opus)  m=anthropic/claude-opus-4 ;;
    grok)  m=x-ai/grok-4 ;;
  esac
  run_case "alias-$alias_case" 0 'mock answer' '[thinking…' env MOCK_SCENARIO=expect-model MOCK_EXPECT_MODEL="$m" "$ASK" -m:"$alias_case" hello
done

run_case override-failure 9 '' 'not a usage-limit error' env MOCK_SCENARIO=override-failure "$ASK" -m:provider/model hello
run_case ordinary-failure 7 '' 'not a usage-limit error' env MOCK_SCENARIO=failure "$ASK" hello

# fallback detects the usage-limit headline on the primary model
set +e
OPENCODE_BIN="$MOCK" MOCK_SCENARIO=limit "$ASK" hello >"$tmpdir/fallback.out" 2>"$tmpdir/fallback.err"
code=$?
set -e
assert_eq "$code" 0
assert_eq "$(<"$tmpdir/fallback.out")" 'fallback answer'
assert_contains "$tmpdir/fallback.err" 'falling back to opencode/gpt-5.6-luna (low)'
assert_contains "$tmpdir/fallback.err" "[thread"

# explicit model never auto-falls back, even on a usage-limit headline
set +e
OPENCODE_BIN="$MOCK" MOCK_SCENARIO=limit "$ASK" -m:my/limited hello >"$tmpdir/nofb.out" 2>"$tmpdir/nofb.err"
nofb_code=$?
set -e
assert_eq "$nofb_code" 29

# custom config: QM_CONFIG_FILE controls default model and aliases
cat >"$tmpdir/custom.conf" <<'EOF'
QM_DEFAULT_MODEL=my/custom-default
QM_ALIAS_myalias=my/custom-model
QM_FALLBACK_MODEL=my/custom-fallback
EOF
run_case cfg-default 0 'mock answer' '[thinking… my/custom-default]' env MOCK_SCENARIO=expect-model MOCK_EXPECT_MODEL=my/custom-default QM_CONFIG_FILE="$tmpdir/custom.conf" "$ASK" hello
run_case cfg-alias 0 'mock answer' '[thinking… my/custom-model]' env MOCK_SCENARIO=expect-model MOCK_EXPECT_MODEL=my/custom-model QM_CONFIG_FILE="$tmpdir/custom.conf" "$ASK" -m:myalias hello

# --- threads: create, list, search, continue ---
OPENCODE_BIN="$MOCK" MOCK_SCENARIO=success MOCK_SESSION=ses_abc123def456 "$ASK" first question >"$tmpdir/t1.out" 2>"$tmpdir/t1.err"
first_id="$(extract_thread_id "$tmpdir/t1.err")"
[[ -n "$first_id" ]] || { echo "first run produced no thread id" >&2; exit 1; }
assert_eq "$(<"$tmpdir/t1.out")" 'mock answer'
[[ -f "$QM_THREADS_DIR/$first_id.json" ]] || { echo "thread json missing: $first_id" >&2; exit 1; }

# 6-char suffix resolves against today's date and finds the same thread
suffix="${first_id:6}"
OPENCODE_BIN="$MOCK" MOCK_SCENARIO=expect-session MOCK_EXPECT_SESSION=ses_abc123def456 "$ASK" -t:"$suffix" follow up >"$tmpdir/t2.out" 2>"$tmpdir/t2.err"
assert_eq "$(<"$tmpdir/t2.out")" 'mock answer'
assert_contains "$tmpdir/t2.err" "[thread $first_id] (continued)"

# full 12-char id also continues
OPENCODE_BIN="$MOCK" MOCK_SCENARIO=expect-session MOCK_EXPECT_SESSION=ses_abc123def456 "$ASK" -t:"$first_id" follow up again >"$tmpdir/t3.out" 2>"$tmpdir/t3.err"
assert_eq "$(<"$tmpdir/t3.out")" 'mock answer'

# nonexistent thread errors cleanly
run_case missing-thread 2 '' 'no thread found' env MOCK_SCENARIO=success "$ASK" -t:2608130badf0 x

# 6-hex continuation is not limited to today: with no thread from today for
# that suffix, the newest thread carrying the suffix wins.
import_synthetic_thread() {
  local id="$1" session="$2" updated="$3"
  QM_THREADS_DIR="$QM_THREADS_DIR" QM_ID="$id" QM_SESSION="$session" QM_UPDATED="$updated" python3 - <<'PY'
import os, json, time
d = os.environ["QM_THREADS_DIR"]
id_ = os.environ["QM_ID"]
data = {
    "id": id_,
    "date": id_[:6],
    "hex": id_[6:],
    "sessionID": os.environ["QM_SESSION"],
    "agentType": "ask",
    "model": "default",
    "directory": "/tmp",
    "question": "synthetic " + id_,
    "lastQuestion": "synthetic " + id_,
    "created": int(os.environ["QM_UPDATED"]),
    "updated": int(os.environ["QM_UPDATED"]),
}
os.makedirs(d, exist_ok=True)
with open(os.path.join(d, id_ + ".json"), "w") as f:
    json.dump(data, f, indent=2)
PY
}

# Two older threads share suffix c0ffee; the one updated later must win.
import_synthetic_thread 250101c0ffee ses_old_one 1000
import_synthetic_thread 250111c0ffee ses_newer_one 5000
OPENCODE_BIN="$MOCK" MOCK_SCENARIO=expect-session MOCK_EXPECT_SESSION=ses_newer_one "$ASK" -t:c0ffee recent one >"$tmpdir/t4.out" 2>"$tmpdir/t4.err"
assert_eq "$(<"$tmpdir/t4.out")" 'mock answer'
assert_contains "$tmpdir/t4.err" "[thread 250111c0ffee] (continued)"

# list shows the thread; search finds it by question
"$ASK" -l >"$tmpdir/list.out" 2>"$tmpdir/list.err"
assert_contains "$tmpdir/list.out" "$first_id"
assert_contains "$tmpdir/list.out" 'follow up again'

"$ASK" -s:first >"$tmpdir/search.out" 2>"$tmpdir/search.err"
assert_contains "$tmpdir/search.out" "$first_id"

run_case search-empty 0 'no threads found' '' env MOCK_SCENARIO=success "$ASK" -s:nonexistent-term

echo 'wrapper tests passed'