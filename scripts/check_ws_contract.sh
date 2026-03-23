#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MD_CONTRACT="$ROOT_DIR/docs/WS_V3_CONTRACT.md"
JSON_CONTRACT="$ROOT_DIR/docs/ws_v3_protocol_contract.json"
ERROR_CODES_SRC="$ROOT_DIR/gameBackend/src/main/java/com/gameapp/game/constants/WsErrorCodes.java"
BACKEND_PROPERTIES="$ROOT_DIR/gameBackend/src/main/resources/application.properties"
BACKEND_PROTOCOL_SETTINGS="$ROOT_DIR/gameBackend/src/main/java/com/gameapp/game/config/WsProtocolSettings.java"
FRONT_PROTOCOL_SRC="$ROOT_DIR/gameapp/lib/core/constants/app_constants.dart"
FRONT_WS_MANAGER="$ROOT_DIR/gameapp/lib/core/services/websocket_manager.dart"
FRONT_GAME_UI_DIR="$ROOT_DIR/gameapp/lib/features/game/ui"
FRONT_WS_TEST="$ROOT_DIR/gameapp/test/core/services/websocket_manager_contract_test.dart"
FRONT_WS_TEST_SCRIPT="$ROOT_DIR/scripts/ws_frontend_scenario_tests.sh"
BACKEND_WS_CONFIG="$ROOT_DIR/gameBackend/src/main/java/com/gameapp/game/ImprovedWebSocketConfig.java"

fail() {
  echo "[contract-check] FAIL: $1" >&2
  exit 1
}

[[ -f "$MD_CONTRACT" ]] || fail "Missing markdown contract: $MD_CONTRACT"
[[ -f "$JSON_CONTRACT" ]] || fail "Missing json contract: $JSON_CONTRACT"
[[ -f "$ERROR_CODES_SRC" ]] || fail "Missing error code source: $ERROR_CODES_SRC"
[[ -f "$BACKEND_PROPERTIES" ]] || fail "Missing backend properties: $BACKEND_PROPERTIES"
[[ -f "$BACKEND_PROTOCOL_SETTINGS" ]] || fail "Missing backend protocol settings: $BACKEND_PROTOCOL_SETTINGS"
[[ -f "$FRONT_PROTOCOL_SRC" ]] || fail "Missing frontend protocol config: $FRONT_PROTOCOL_SRC"
[[ -f "$FRONT_WS_MANAGER" ]] || fail "Missing websocket manager: $FRONT_WS_MANAGER"
[[ -d "$FRONT_GAME_UI_DIR" ]] || fail "Missing game UI directory: $FRONT_GAME_UI_DIR"
[[ -f "$FRONT_WS_TEST" ]] || fail "Missing frontend websocket contract test: $FRONT_WS_TEST"
[[ -f "$FRONT_WS_TEST_SCRIPT" ]] || fail "Missing frontend websocket scenario script: $FRONT_WS_TEST_SCRIPT"
[[ -f "$BACKEND_WS_CONFIG" ]] || fail "Missing backend websocket config: $BACKEND_WS_CONFIG"

required_envelope_fields=(
  "type"
  "action"
  "roomId"
  "matchId"
  "data"
  "clientActionId"
  "eventId"
  "traceId"
  "serverTime"
  "protocolVersion"
  "stateVersion"
)

for field in "${required_envelope_fields[@]}"; do
  rg -q "\"$field\"" "$JSON_CONTRACT" || fail "JSON contract missing envelope field: $field"
  rg -q "\`$field\`" "$MD_CONTRACT" || fail "Markdown contract missing envelope field: $field"
done

auth_required_fields=("protocolVersion" "appVersion" "capabilities" "deviceId")
for field in "${auth_required_fields[@]}"; do
  rg -q "\"$field\"" "$JSON_CONTRACT" || fail "JSON contract missing AUTH field: $field"
  rg -q "\`$field\`" "$MD_CONTRACT" || fail "Markdown contract missing AUTH field: $field"
done

error_codes="$(rg -o '"[A-Z_]+"' "$ERROR_CODES_SRC" | tr -d '"' | sort -u)"
while IFS= read -r code; do
  [[ -n "$code" ]] || continue
  rg -q "\"$code\"" "$JSON_CONTRACT" || fail "JSON contract missing error code: $code"
  rg -q "\`$code\`" "$MD_CONTRACT" || fail "Markdown contract missing error code: $code"
done <<< "$error_codes"

backend_protocol_line="$(rg -F 'app.ws.protocol.version=${WS_PROTOCOL_VERSION:' "$BACKEND_PROPERTIES" | head -n1)"
backend_protocol="$(echo "$backend_protocol_line" | sed -E 's/.*:([^}]+)\}.*/\1/')"
[[ -n "$backend_protocol" ]] || fail "Cannot resolve backend default protocol version"

frontend_protocol="$(rg -o "static const String protocolVersion = '[^']+'" "$FRONT_PROTOCOL_SRC" | sed -E "s/.*'([^']+)'.*/\1/" | head -n1)"
[[ -n "$frontend_protocol" ]] || fail "Cannot resolve frontend protocol version constant"

json_protocol="$(rg -o '"protocolVersion":\s*"[^"]+"' "$JSON_CONTRACT" | sed -E 's/.*"([^"]+)"$/\1/' | head -n1)"
[[ -n "$json_protocol" ]] || fail "Cannot resolve protocolVersion from JSON contract"

[[ "$backend_protocol" == "$frontend_protocol" ]] || fail "Protocol mismatch backend=$backend_protocol frontend=$frontend_protocol"
[[ "$backend_protocol" == "$json_protocol" ]] || fail "Protocol mismatch backend=$backend_protocol jsonContract=$json_protocol"
[[ "$backend_protocol" == "v3" ]] || fail "Backend default protocol must be v3"

critical_front_error_codes=(
  "TOKEN_REVOKED"
  "AUTH_EXPIRED"
  "APP_VERSION_UNSUPPORTED"
  "STATE_RESYNC_REQUIRED"
)
for code in "${critical_front_error_codes[@]}"; do
  rg -q "$code" "$FRONT_WS_MANAGER" || fail "Frontend websocket_manager missing critical error handling: $code"
done

direct_game_action_hits="$(mktemp)"
if rg -n "'type'\\s*:\\s*'GAME_ACTION'|\"type\"\\s*:\\s*\"GAME_ACTION\"" "$FRONT_GAME_UI_DIR" >"$direct_game_action_hits"; then
  echo "[contract-check] Direct GAME_ACTION sends found in UI:"
  cat "$direct_game_action_hits"
  rm -f "$direct_game_action_hits"
  fail "UI must use sendGameAction adapter only"
fi
rm -f "$direct_game_action_hits"

rg -q "sendGameAction\\(" "$FRONT_GAME_UI_DIR" || fail "No sendGameAction usage found in game UI"

rg -Fq 'app.ws.enforce-client-action-id=${WS_ENFORCE_CLIENT_ACTION_ID:true}' "$BACKEND_PROPERTIES" || fail "Backend default must enforce clientActionId"
rg -Fq 'app.ws.enforce-game-action-state-version=${WS_ENFORCE_GAME_ACTION_STATE_VERSION:true}' "$BACKEND_PROPERTIES" || fail "Backend default must enforce GAME_ACTION stateVersion"
rg -Fq 'app.ws.require-device-id=${WS_REQUIRE_DEVICE_ID:true}' "$BACKEND_PROPERTIES" || fail "Backend default must require AUTH deviceId"
rg -Fq 'app.flags.ws-require-game-action-data=${FF_WS_REQUIRE_GAME_ACTION_DATA:true}' "$BACKEND_PROPERTIES" || fail "Backend default must require GAME_ACTION data"

rg -q "CLIENT_TELEMETRY" "$MD_CONTRACT" || fail "Contract doc missing CLIENT_TELEMETRY"
rg -q "\"CLIENT_TELEMETRY\"" "$JSON_CONTRACT" || fail "JSON contract missing CLIENT_TELEMETRY"
rg -q "CLIENT_TELEMETRY" "$BACKEND_WS_CONFIG" || fail "Backend missing CLIENT_TELEMETRY processor"
rg -q "CLIENT_TELEMETRY" "$BACKEND_PROTOCOL_SETTINGS" || fail "Backend auth capabilities missing CLIENT_TELEMETRY"
rg -q "CLIENT_TELEMETRY" "$FRONT_WS_MANAGER" || fail "Frontend websocket manager missing CLIENT_TELEMETRY sender"

rg -q "realtimeEnabled" "$FRONT_PROTOCOL_SRC" || fail "Frontend protocol config missing realtime kill-switch constant"
rg -q "realtimeDisabledReason" "$FRONT_PROTOCOL_SRC" || fail "Frontend protocol config missing realtime disable reason"

echo "[contract-check] PASS"
