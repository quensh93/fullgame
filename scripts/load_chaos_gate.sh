#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
K6_SCRIPT="$ROOT_DIR/scripts/perf/k6_ws_v3_smoke.js"
CHAOS_SCRIPT="$ROOT_DIR/scripts/perf/chaos_smoke.sh"
LOCAL_LOAD_SCRIPT="$ROOT_DIR/scripts/perf/local_ws_load_smoke.sh"
RUNBOOK="$ROOT_DIR/docs/LOAD_CHAOS_RUNBOOK.md"

fail() {
  echo "[load-chaos-gate] FAIL: $1" >&2
  exit 1
}

[[ -f "$K6_SCRIPT" ]] || fail "Missing k6 smoke script: $K6_SCRIPT"
[[ -f "$CHAOS_SCRIPT" ]] || fail "Missing chaos smoke script: $CHAOS_SCRIPT"
[[ -f "$LOCAL_LOAD_SCRIPT" ]] || fail "Missing local load smoke script: $LOCAL_LOAD_SCRIPT"
[[ -f "$RUNBOOK" ]] || fail "Missing load/chaos runbook: $RUNBOOK"

rg -Fq "p(95)<150" "$K6_SCRIPT" || fail "k6 script missing p95 threshold (<150ms)"
rg -Fq "p(99)<250" "$K6_SCRIPT" || fail "k6 script missing p99 threshold (<250ms)"
rg -q "rollout restart" "$CHAOS_SCRIPT" || fail "Chaos script missing rollout restart action"
rg -q "wait --for=condition=available" "$CHAOS_SCRIPT" || fail "Chaos script missing availability wait"
rg -q "20k" "$RUNBOOK" || fail "Runbook missing 20k CCU target"
rg -q "72h" "$RUNBOOK" || fail "Runbook missing 72h stability requirement"

if [[ "${RUN_LOAD_CHAOS:-false}" == "true" ]]; then
  command -v k6 >/dev/null 2>&1 || fail "k6 is required when RUN_LOAD_CHAOS=true"
  if [[ "${RUN_LOCAL_LOAD_SMOKE:-false}" == "true" ]]; then
    echo "[load-chaos-gate] Running local ws load smoke bootstrap..."
    "$LOCAL_LOAD_SCRIPT"
  else
    [[ -n "${WS_URL:-}" ]] || fail "WS_URL must be set when RUN_LOAD_CHAOS=true and RUN_LOCAL_LOAD_SMOKE=false"
    [[ -n "${WS_TOKEN:-}" ]] || fail "WS_TOKEN must be set when RUN_LOAD_CHAOS=true and RUN_LOCAL_LOAD_SMOKE=false"
    echo "[load-chaos-gate] Running k6 smoke load scenario..."
    k6 run "$K6_SCRIPT"
  fi

  if [[ "${RUN_CHAOS_SMOKE:-false}" == "true" ]]; then
    echo "[load-chaos-gate] Running chaos smoke scenario..."
    "$CHAOS_SCRIPT"
  else
    echo "[load-chaos-gate] RUN_CHAOS_SMOKE=false -> skipping chaos execution (artifact checks passed)."
  fi
else
  echo "[load-chaos-gate] RUN_LOAD_CHAOS=false -> skipping execution (artifact checks passed)."
fi

echo "[load-chaos-gate] PASS"
