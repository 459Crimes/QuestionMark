#!/usr/bin/env bash
# Mock opencode CLI: emits the same newline-delimited JSON event stream the
# real `opencode run --format json` produces, so the wrapper parses it the
# same way in tests.
set -u

args=" $* "

mock_session() {
  echo "${MOCK_SESSION:-ses_mock_probe_001}"
}

emit_start() {
  local sid session
  session="$(mock_session)"
  sid="$(printf '%s' "$session" | sed 's/[^A-Za-z0-9]//g')"
  printf '{"type":"step_start","timestamp":0,"sessionID":"%s","part":{"type":"step-start","messageID":"msg_mock","sessionID":"%s"}}\n' "$session" "$session"
  export MOCK_EMIT_SID="$session"
}

emit_text() {
  printf '{"type":"text","timestamp":0,"sessionID":"%s","part":{"type":"text","messageID":"msg_mock","sessionID":"%s","text":"%s"}}\n' "$MOCK_EMIT_SID" "$MOCK_EMIT_SID" "$1"
}

emit_error() {
  printf '{"type":"error","timestamp":0,"sessionID":"%s","error":{"name":"MockError","data":{"message":"%s"}}}\n' "$MOCK_EMIT_SID" "$1"
}

emit_finish() {
  printf '{"type":"step_finish","timestamp":0,"sessionID":"%s","part":{"type":"step-finish","reason":"stop","messageID":"msg_mock","sessionID":"%s"}}\n' "$MOCK_EMIT_SID" "$MOCK_EMIT_SID"
}

read_model() {
  local prev=''
  for a in $*; do
    if [[ "$prev" == "--model" ]]; then
      echo "$a"
      return 0
    fi
    prev="$a"
  done
  echo 'opencode/default'
}

read_session() {
  local prev=''
  for a in $*; do
    if [[ "$prev" == "--session" ]]; then
      echo "$a"
      return 0
    fi
    prev="$a"
  done
  echo ''
}

model="$(read_model "$@")"
session_arg="$(read_session "$@")"
if [[ -n "$session_arg" ]]; then
  export MOCK_SESSION="$session_arg"
fi

emit_start

case "${MOCK_SCENARIO:-success}" in
  success)
    emit_text 'mock answer'
    emit_finish
    ;;
  limit)
    if [[ "$model" == "opencode/gpt-5.6-luna" ]]; then
      emit_text 'fallback answer'
      emit_finish
    else
      emit_error 'HTTP 429: usage limit reached'
      exit 29
    fi
    ;;
  failure)
    emit_error 'network unavailable'
    exit 7
    ;;
  override-failure)
    emit_error 'chosen model unavailable'
    exit 9
    ;;
  expect-model)
    [[ "$model" == "${MOCK_EXPECT_MODEL:?MOCK_EXPECT_MODEL is required}" ]] || {
      echo "expected model $MOCK_EXPECT_MODEL, received -- $model" >&2
      exit 10
    }
    emit_text 'mock answer'
    emit_finish
    ;;
  expect-session)
    [[ "$session_arg" == "${MOCK_EXPECT_SESSION:?MOCK_EXPECT_SESSION is required}" ]] || {
      echo "expected session $MOCK_EXPECT_SESSION, received '$session_arg'" >&2
      exit 11
    }
    emit_text 'mock answer'
    emit_finish
    ;;
  *)
    echo "unknown mock scenario: ${MOCK_SCENARIO}" >&2
    exit 99
    ;;
esac