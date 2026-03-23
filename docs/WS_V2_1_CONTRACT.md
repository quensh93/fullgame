# WS v2.1 Contract (Backend + Flutter)

## Envelope (all WS messages)
- `type`: message type
- `action`: semantic action (when applicable)
- `roomId`: room identifier (when applicable)
- `data`: payload
- `clientActionId`: client-generated id for idempotency (outgoing/incoming when applicable)
- `eventId`: unique server event id
- `traceId`: correlation id
- `serverTime`: UTC ISO-8601 timestamp
- `protocolVersion`: protocol version (`v2.1`)
- `stateVersion`: monotonic state version per stream/room (`long`)

## Client -> Server additions
- `clientSentAt`: UTC ISO-8601 timestamp
- `clientActionId`: required for `GAME_ACTION` (strict mode is default)
- `appVersion`: client app version in `AUTH`
- `capabilities`: client declared features in `AUTH`
- `CLIENT_TELEMETRY`: optional periodic client metrics payload
  - `connect_latency`
  - `ack_latency`
  - `reconnect_attempts`
  - `resync_count`
  - `action_retry_count`
  - `action_timeout_count`
  - `pending_action_count`

## AUTH_SUCCESS payload
- `user`
- `protocolVersion`
- `sessionId`
- `sessionVersion`
- `capabilities`
- `serverSupportsLegacyV2`

## Error contract
- `type = ERROR`
- `errorCode` supported:
  - `AUTH_REQUIRED`
  - `AUTH_EXPIRED`
  - `TOKEN_REVOKED`
  - `INVALID_TOKEN`
  - `ACTION_REJECTED`
  - `STATE_RESYNC_REQUIRED`
  - `APP_VERSION_UNSUPPORTED`

## Action lifecycle
- Optional positive acknowledgement:
  - `type = ACTION_ACK`
  - `data.clientActionId`
  - `data.accepted | data.duplicate`
- Security rule:
  - if `data.playerId` is provided in `GAME_ACTION`, it must match the authenticated session user id; otherwise backend returns `ERROR` with `errorCode=ACTION_REJECTED`.

## Resync flow
- Server may return `type = ERROR` with `errorCode = STATE_RESYNC_REQUIRED`.
- Client requests snapshot with `GET_GAME_STATE_BY_ROOM`.
- Server responds with `type = STATE_SNAPSHOT` (and, during compat window, also `type = GAME_STATE`).

## Compatibility window
- Controlled by backend flag:
  - `app.ws.compat.v2-enabled=true|false`
  - `app.ws.compat.v2-deadline=yyyy-MM-dd` (startup guard for migration window)
- During window:
  - server emits v2.1 envelope fields
  - legacy payload shapes remain accepted only when explicit fallback flags are enabled
    - `app.ws.enforce-client-action-id=false`
    - `app.flags.ws-require-game-action-data=false`
- Migration deadline:
  - `v2 + v2.1` coexistence is time-boxed to **21 days**.

## Frontend Runtime Kill-Switch
- Realtime can be disabled at app runtime via build-time flags:
  - `WS_REALTIME_ENABLED=false`
  - `WS_REALTIME_DISABLED_REASON="<message>"`
- When disabled:
  - Flutter app must not open websocket connection.
  - UX must show a global degradation banner.

## Release Gate Command
- Shared BE/FE gate command:
  - `./scripts/release_gate.sh`
- This command runs:
  - WS contract consistency check
  - protocol version sync across backend + frontend + json contract
  - frontend critical auth/resync error handling presence
  - realtime kill-switch presence validation in Flutter
  - disallow direct `GAME_ACTION` payload sends in game UI (must use `sendGameAction`)
  - backend tests (`./gradlew test --no-daemon`)
  - websocket critical scenario tests (`./scripts/ws_scenario_tests.sh`)
  - frontend websocket contract tests (`./scripts/ws_frontend_scenario_tests.sh`)
  - frontend compile-error gate (`flutter analyze`, errors only)
  - ops hardening gate (`./scripts/ops_hardening_gate.sh`)

## Runtime Metrics (backend)
- `action_latency_ms` (tagged by action)
- `duplicate_action`
- `reconnect_count`
- `ws_room_action_queue_depth`
- `ws_room_action_queue_wait_ms`
- `ws_room_action_processing_ms`
- `ws_room_action_failures`
