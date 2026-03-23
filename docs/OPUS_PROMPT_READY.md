# OPUS Prompt Ready (WS v3)

Date: 2026-02-20

Use the block below as-is in Opus 4.6.

```md
You are implementing full frontend WebSocket integration for GameApp using **ws-v3** only.

## Mission
Wire the current Flutter app to the backend v3 socket contract end-to-end, page by page, without changing backend runtime behavior.

## Strict source of truth (authoritative)
Read and follow these files first:
1. /Users/sajadrahmanipour/Documents/game project/docs/OPUS_WS_V3_IMPLEMENTATION_GUIDE.md
2. /Users/sajadrahmanipour/Documents/game project/docs/opus_ws_v3_contract.json

Backend implementation references (for cross-check only):
1. /Users/sajadrahmanipour/Documents/game project/gameBackend/src/main/java/com/gameapp/game/ImprovedWebSocketConfig.java
2. /Users/sajadrahmanipour/Documents/game project/gameBackend/src/main/java/com/gameapp/game/services/WebSocketMessageHandler.java
3. /Users/sajadrahmanipour/Documents/game project/gameBackend/src/main/java/com/gameapp/game/services/WsEnvelopeService.java
4. /Users/sajadrahmanipour/Documents/game project/gameBackend/src/main/java/com/gameapp/game/services/WebSocketRoomService.java
5. /Users/sajadrahmanipour/Documents/game project/gameBackend/src/main/java/com/gameapp/game/config/WsProtocolSettings.java
6. /Users/sajadrahmanipour/Documents/game project/gameBackend/src/main/java/com/gameapp/game/constants/WsErrorCodes.java

## Legacy exclusion (important)
- Treat /Users/sajadrahmanipour/Documents/game project/docs/README_WEBSOCKET_V2.md as outdated/non-authoritative.
- Do not design or wire based on /ws-v2 behavior.
- Exclude debug/test-controller-only websocket surfaces from normative ws-v3 page wiring.

## Non-negotiable protocol rules
1. Endpoint: `/ws-v3`
2. Respect v3 envelope fields: `eventId`, `traceId`, `serverTime`, `protocolVersion`, `stateVersion`
3. AUTH bootstrap must follow v3 contract:
   - send `AUTH` with required fields (`token`, `protocolVersion`, `appVersion`, `capabilities`, and `deviceId` when required)
   - wait for `AUTH_SUCCESS`
   - then send `CLIENT_TELEMETRY`
4. For gameplay writes, follow strict gates:
   - include `clientActionId`
   - include `data.stateVersion`
5. `ACTION_ACK` means accepted/duplicate handling only, not final game apply success.
6. On `ERROR` with `STATE_RESYNC_REQUIRED`, immediately request `GET_GAME_STATE_BY_ROOM` and replace local state from `STATE_SNAPSHOT`.
7. `GET_GAME_STATE_BY_ROOM` -> `STATE_SNAPSHOT` (not `GAME_STATE`).
8. Handle mixed signal casing exactly as emitted (e.g. lowercase room stream vs uppercase direct responses).

## Implementation constraints
1. Do not modify backend Java behavior unless absolutely required by a compile blocker.
2. Reuse existing frontend architecture/services when possible.
3. Keep one stable socket manager with:
   - connect/disconnect
   - auth/bootstrap
   - heartbeat handling
   - reconnect strategy
   - routing by `type` and by `action` for `type=GAME_ACTION`
   - listener registration/cleanup to prevent duplicate handlers
4. Validate request/action payloads before send.
5. Ensure all migrated game pages use `sendGameAction(...)` and do not send raw `type: GAME_ACTION` maps directly.

## Required work order
1. Parse contract JSON and build an internal map of:
   - all request types
   - all `GAME_ACTION` actions
   - all server signals
   - error code behaviors
2. Audit current Flutter websocket paths and identify gaps against contract.
3. Implement/fix socket wiring in:
   - core bootstrap/auth flow
   - lobby/room lifecycle
   - friends/invitations
   - profile/wallet/history
   - gameplay pages and `GAME_ACTION` listeners
4. Apply page mapping from `page_mapping` in the contract.
5. Add/fix handling for all mandatory error paths.
6. Run tests and provide final coverage report.

## Validation commands (must run)
1. `bash /Users/sajadrahmanipour/Documents/game project/scripts/check_ws_contract.sh`
2. `cd /Users/sajadrahmanipour/Documents/game project/gameBackend && ./gradlew test --tests com.gameapp.game.ImprovedWebSocketConfigHistoryTest --tests com.gameapp.game.services.WsIdempotencyServiceTest --tests com.gameapp.game.services.RedisWsFanoutServiceTest`
3. `cd /Users/sajadrahmanipour/Documents/game project/gameapp && flutter test test/core/services/websocket_manager_contract_test.dart`

## Required final output
Return all of the following:
1. Code changes summary with exact files changed.
2. Request coverage table: each registered processor -> implemented caller page/service.
3. GAME_ACTION coverage table: each action -> sender + listener + state update path.
4. Signal coverage table: each signal -> handler location.
5. Error matrix confirmation: each error code -> concrete client behavior.
6. Known mismatches found/fixed (especially naming/casing and stale-state resync).
7. Any remaining TODOs explicitly marked as blocker/non-blocker.

Start now and implement end-to-end.
```
