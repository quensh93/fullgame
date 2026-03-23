#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BACKEND_DIR="$ROOT_DIR/gameBackend"
K6_SCRIPT="$ROOT_DIR/scripts/perf/k6_ws_v3_smoke.js"

SERVER_HOST="${SERVER_HOST:-127.0.0.1}"
SERVER_PORT="${SERVER_PORT:-8080}"
BASE_URL="${BASE_URL:-http://${SERVER_HOST}:${SERVER_PORT}}"
WS_URL="${WS_URL:-ws://${SERVER_HOST}:${SERVER_PORT}/ws-v3}"

JWT_SECRET="${JWT_SECRET:-local-load-smoke-jwt-secret-32-bytes-min-2026}"
ALLOWED_ORIGINS="${ALLOWED_ORIGINS:-http://localhost:3000,http://127.0.0.1:3000}"

K6_VUS="${K6_VUS:-25}"
K6_DURATION="${K6_DURATION:-30s}"
ACTION_INTERVAL_MS="${ACTION_INTERVAL_MS:-800}"
MAX_ACTIONS_PER_CONN="${MAX_ACTIONS_PER_CONN:-20}"
STATE_VERSION="${STATE_VERSION:-0}"

LOAD_USER_EMAIL="${LOAD_USER_EMAIL:-load-smoke-$(date +%s)@local.test}"
LOAD_USER_USERNAME="${LOAD_USER_USERNAME:-loadsmoke$(date +%s)}"
LOAD_USER_PASSWORD="${LOAD_USER_PASSWORD:-Passw0rd!23456}"

BOOT_LOG="$(mktemp -t local_ws_load_boot.XXXXXX.log)"
BACKEND_PID=""

cleanup() {
  if [[ -n "$BACKEND_PID" ]] && kill -0 "$BACKEND_PID" >/dev/null 2>&1; then
    kill "$BACKEND_PID" >/dev/null 2>&1 || true
    wait "$BACKEND_PID" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

fail() {
  echo "[local-ws-load-smoke] FAIL: $1" >&2
  echo "[local-ws-load-smoke] Boot log: $BOOT_LOG" >&2
  exit 1
}

command -v curl >/dev/null 2>&1 || fail "curl is required"
command -v jq >/dev/null 2>&1 || fail "jq is required"
command -v k6 >/dev/null 2>&1 || fail "k6 is required"
[[ -f "$K6_SCRIPT" ]] || fail "Missing k6 script at $K6_SCRIPT"

if lsof -iTCP:"$SERVER_PORT" -sTCP:LISTEN >/dev/null 2>&1; then
  fail "Port $SERVER_PORT is already in use. Stop existing service or set SERVER_PORT."
fi

echo "[local-ws-load-smoke] Starting backend on ${BASE_URL} (bootRun + H2)..."
(
  cd "$BACKEND_DIR"
  JWT_SECRET="$JWT_SECRET" \
  ALLOWED_ORIGINS="$ALLOWED_ORIGINS" \
  SPRING_DATASOURCE_URL="jdbc:h2:mem:loadsmoke;MODE=PostgreSQL;DATABASE_TO_UPPER=false;DB_CLOSE_DELAY=-1" \
  SPRING_DATASOURCE_DRIVER_CLASS_NAME="org.h2.Driver" \
  SPRING_DATASOURCE_USERNAME="sa" \
  SPRING_DATASOURCE_PASSWORD="" \
  SPRING_JPA_DATABASE_PLATFORM="org.hibernate.dialect.H2Dialect" \
  SPRING_JPA_HIBERNATE_DDL_AUTO="create-drop" \
  SPRING_FLYWAY_ENABLED="false" \
  SPRING_SQL_INIT_MODE="never" \
  REDIS_ENABLED="false" \
  REDIS_REQUIRE_HEALTHY="false" \
  SERVER_PORT="$SERVER_PORT" \
  ./gradlew bootRun --no-daemon >"$BOOT_LOG" 2>&1
) &
BACKEND_PID=$!

echo "[local-ws-load-smoke] Waiting for backend readiness..."
for _ in $(seq 1 120); do
  if ! kill -0 "$BACKEND_PID" >/dev/null 2>&1; then
    tail -n 200 "$BOOT_LOG" >&2 || true
    fail "Backend process exited before readiness"
  fi

  code="$(curl -s -o /dev/null -w '%{http_code}' "${BASE_URL}/api/auth/check-email?email=probe@local.test" || true)"
  if [[ "$code" == "200" ]]; then
    break
  fi
  sleep 1
done

code="$(curl -s -o /dev/null -w '%{http_code}' "${BASE_URL}/api/auth/check-email?email=probe@local.test" || true)"
[[ "$code" == "200" ]] || fail "Backend did not become ready in time"

echo "[local-ws-load-smoke] Creating load test user..."
signup_response="$(curl -s -X POST "${BASE_URL}/api/auth/signup" \
  -H 'Content-Type: application/json' \
  -d "{\"email\":\"${LOAD_USER_EMAIL}\",\"username\":\"${LOAD_USER_USERNAME}\",\"password\":\"${LOAD_USER_PASSWORD}\"}")"

access_token="$(printf '%s' "$signup_response" | jq -r '.accessToken // .token // empty')"
[[ -n "$access_token" && "$access_token" != "null" ]] || {
  echo "$signup_response" >&2
  fail "Failed to obtain access token from signup response"
}

echo "[local-ws-load-smoke] Running k6 smoke (vus=${K6_VUS}, duration=${K6_DURATION})..."
k6 run "$K6_SCRIPT" \
  -e WS_URL="$WS_URL" \
  -e WS_TOKEN="$access_token" \
  -e K6_VUS="$K6_VUS" \
  -e K6_DURATION="$K6_DURATION" \
  -e ACTION_INTERVAL_MS="$ACTION_INTERVAL_MS" \
  -e MAX_ACTIONS_PER_CONN="$MAX_ACTIONS_PER_CONN" \
  -e STATE_VERSION="$STATE_VERSION"

echo "[local-ws-load-smoke] PASS"
echo "[local-ws-load-smoke] Boot log saved at: $BOOT_LOG"
