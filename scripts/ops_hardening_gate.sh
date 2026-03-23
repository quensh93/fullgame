#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_PROPERTIES="$ROOT_DIR/gameBackend/src/main/resources/application.properties"
BACKEND_YML="$ROOT_DIR/gameBackend/src/main/resources/application.yml"
BACKEND_PROD_YML="$ROOT_DIR/gameBackend/src/main/resources/application-prod.yml"
FRONT_CONSTANTS="$ROOT_DIR/gameapp/lib/core/constants/app_constants.dart"
RUNBOOK="$ROOT_DIR/docs/CANARY_ROLLOUT_RUNBOOK.md"

fail() {
  echo "[ops-gate] FAIL: $1" >&2
  exit 1
}

[[ -f "$BACKEND_PROPERTIES" ]] || fail "Missing backend properties"
[[ -f "$BACKEND_YML" ]] || fail "Missing backend yml"
[[ -f "$BACKEND_PROD_YML" ]] || fail "Missing backend prod yml"
[[ -f "$FRONT_CONSTANTS" ]] || fail "Missing frontend constants"
[[ -f "$RUNBOOK" ]] || fail "Missing canary rollout runbook"

rg -q "app.ws.protocol.version" "$BACKEND_PROPERTIES" || fail "Missing protocol version in backend properties"
rg -q "app.ws.require-device-id" "$BACKEND_PROPERTIES" || fail "Missing require-device-id in backend properties"
rg -q "app.ws.enforce-game-action-state-version" "$BACKEND_PROPERTIES" || fail "Missing GAME_ACTION stateVersion enforcement in backend properties"
rg -q "app.ws.app-version-gate.enabled" "$BACKEND_PROPERTIES" || fail "Missing app version gate flag in backend properties"
rg -q "app.ws.app-version-gate.min-supported" "$BACKEND_PROPERTIES" || fail "Missing minimum supported app version in backend properties"
rg -Fq 'app.ws.enforce-client-action-id=${WS_ENFORCE_CLIENT_ACTION_ID:true}' "$BACKEND_PROPERTIES" || fail "Backend must enforce clientActionId by default"
rg -Fq 'app.flags.ws-require-game-action-data=${FF_WS_REQUIRE_GAME_ACTION_DATA:true}' "$BACKEND_PROPERTIES" || fail "Backend must require GAME_ACTION data by default"
rg -Fq 'version: ${WS_PROTOCOL_VERSION:v3}' "$BACKEND_YML" || fail "application.yml must default to v3 protocol"

rg -q "ddl-auto: validate" "$BACKEND_PROD_YML" || fail "Production profile must use ddl-auto validate"
rg -q "enabled: true" "$BACKEND_PROD_YML" || fail "Production profile must enable strict flags"
rg -q "app:" "$BACKEND_PROD_YML" || fail "Production profile missing app config"
rg -q "redis:" "$BACKEND_PROD_YML" || fail "Production profile missing redis block"

rg -q "realtimeEnabled" "$FRONT_CONSTANTS" || fail "Missing realtime kill-switch constant in frontend"
rg -q "realtimeDisabledReason" "$FRONT_CONSTANTS" || fail "Missing realtime disable reason in frontend"

for stage in "5%" "25%" "50%" "100%"; do
  rg -q "$stage" "$RUNBOOK" || fail "Runbook missing rollout stage $stage"
done

rg -q "72h" "$RUNBOOK" || fail "Runbook missing stability window guidance"
rg -q "150ms" "$RUNBOOK" || fail "Runbook missing latency SLO guidance"

echo "[ops-gate] PASS"
