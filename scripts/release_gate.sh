#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="$ROOT_DIR/gameBackend"
FRONTEND_DIR="$ROOT_DIR/gameapp"
CONTRACT_CHECK_SCRIPT="$ROOT_DIR/scripts/check_ws_contract.sh"
WS_SCENARIO_SCRIPT="$ROOT_DIR/scripts/ws_scenario_tests.sh"
WS_FRONTEND_SCENARIO_SCRIPT="$ROOT_DIR/scripts/ws_frontend_scenario_tests.sh"
OPS_HARDENING_SCRIPT="$ROOT_DIR/scripts/ops_hardening_gate.sh"
LOAD_CHAOS_GATE_SCRIPT="$ROOT_DIR/scripts/load_chaos_gate.sh"

echo "[release-gate] Step 1/7: WS contract consistency"
"$CONTRACT_CHECK_SCRIPT"

echo "[release-gate] Step 2/7: Backend tests"
(
  cd "$BACKEND_DIR"
  ./gradlew test --no-daemon
)

echo "[release-gate] Step 3/7: WebSocket critical scenarios"
"$WS_SCENARIO_SCRIPT"

echo "[release-gate] Step 4/7: Frontend websocket critical scenarios"
"$WS_FRONTEND_SCENARIO_SCRIPT"

echo "[release-gate] Step 5/7: Flutter analyze (compile errors gate)"
analyze_log="$(mktemp)"
cleanup() {
  rm -f "$analyze_log"
}
trap cleanup EXIT

set +e
(
  cd "$FRONTEND_DIR"
  flutter analyze >"$analyze_log" 2>&1
)
analyze_rc=$?
set -e

if rg -q "error •" "$analyze_log"; then
  echo "[release-gate] Flutter compile errors detected:"
  rg "error •" "$analyze_log"
  exit 1
fi

if [[ $analyze_rc -ne 0 ]]; then
  echo "[release-gate] flutter analyze exited with code $analyze_rc (warnings/info are non-blocking here)."
fi

echo "[release-gate] Step 6/7: Ops hardening gate"
"$OPS_HARDENING_SCRIPT"

echo "[release-gate] Step 7/7: Load and chaos gate"
"$LOAD_CHAOS_GATE_SCRIPT"

echo "[release-gate] PASS"
