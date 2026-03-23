# WS v3 Contract (Backend + Flutter)

## Envelope (all WS messages)
- `type`: message type
- `action`: semantic action (when applicable)
- `roomId`: room identifier (when applicable)
- `matchId`: match identifier (when applicable)
- `data`: payload object
- `clientActionId`: client-generated id for idempotency
- `eventId`: unique server event id
- `traceId`: correlation id
- `serverTime`: UTC ISO-8601 timestamp
- `protocolVersion`: protocol version (`v3`)
- `stateVersion`: monotonic state version per room/match (`long`)

## AUTH (Client -> Server)
Required fields:
- `type=AUTH`
- `token`
- `protocolVersion`
- `appVersion`
- `capabilities`
- `deviceId`

## AUTH_SUCCESS (Server -> Client)
Required payload fields:
- `sessionId`
- `sessionVersion`
- `capabilities`
- `serverConfig`

## GAME_ACTION (Client -> Server)
Required fields:
- `type=GAME_ACTION`
- `action`
- `roomId`
- `clientActionId`
- `data`
- `data.stateVersion`

## CLIENT_TELEMETRY (Client -> Server)
Required fields:
- `type=CLIENT_TELEMETRY`
- `data`
- `data.connect_latency`
- `data.ack_latency`
- `data.reconnect_attempts`
- `data.resync_count`
- `data.action_retry_count`
- `data.action_timeout_count`
- `data.pending_action_count`

## Error Contract
Only one error shape is valid:
- `type=ERROR`
- `errorCode` in:
  - `AUTH_REQUIRED`
  - `AUTH_EXPIRED`
  - `TOKEN_REVOKED`
  - `INVALID_TOKEN`
  - `APP_VERSION_UNSUPPORTED`
  - `ACTION_REJECTED`
  - `STATE_RESYNC_REQUIRED`
  - `RATE_LIMITED`

## Resync Contract
- Server may emit `ERROR` with `errorCode=STATE_RESYNC_REQUIRED`.
- Client must request snapshot with `GET_GAME_STATE_BY_ROOM`.
- Server answers with `type=STATE_SNAPSHOT`.

## Runtime Kill-Switch (Frontend)
- `WS_REALTIME_ENABLED=false`
- `WS_REALTIME_DISABLED_REASON="..."`

## Shared Release Gate
- `./scripts/release_gate.sh`
