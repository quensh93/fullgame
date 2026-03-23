#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="$ROOT_DIR/gameBackend"

echo "[ws-scenarios] Running websocket critical scenario tests..."
(
  cd "$BACKEND_DIR"
  ./gradlew test --no-daemon \
    --tests "com.gameapp.game.ImprovedWebSocketConfigHistoryTest" \
    --tests "com.gameapp.game.config.SecurityStartupValidatorTest" \
    --tests "com.gameapp.game.services.WsIdempotencyServiceTest" \
    --tests "com.gameapp.game.services.RateLimitServiceTest" \
    --tests "com.gameapp.game.services.RedisWsFanoutServiceTest" \
    --tests "com.gameapp.game.services.RoomActionQueueServiceTest" \
    --tests "com.gameapp.game.services.RealtimeEventPipelineServiceTest" \
    --tests "com.gameapp.game.services.RoomTimerServiceTest"
)

echo "[ws-scenarios] PASS"
