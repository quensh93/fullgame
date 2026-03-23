# OPUS WS v3 Implementation Guide

Version: 2026-02-20

This document is the implementation contract for agent-driven frontend socket integration against the current backend `ws-v3` runtime.

## 1. Scope, Endpoint, Auth Prerequisites

### Scope
- In scope: `ws://<host>:<port>/ws-v3` protocol v3 and active request/action/signal surface.
- Out of scope: legacy v2 behavior, old test/debug pages, and non-v3 websocket flows.

### Source of truth
Use these files as authoritative:
- `gameBackend/src/main/java/com/gameapp/game/ImprovedWebSocketConfig.java`
- `gameBackend/src/main/java/com/gameapp/game/services/WebSocketMessageHandler.java`
- `gameBackend/src/main/java/com/gameapp/game/services/WsEnvelopeService.java`
- `gameBackend/src/main/java/com/gameapp/game/services/WebSocketRoomService.java`
- `gameBackend/src/main/java/com/gameapp/game/config/WsProtocolSettings.java`
- `gameBackend/src/main/java/com/gameapp/game/constants/WsErrorCodes.java`

### Legacy note
`docs/README_WEBSOCKET_V2.md` is outdated and is not normative for v3 integration.

### Runtime prerequisites
- Valid access JWT.
- `AUTH` must include `protocolVersion`, `appVersion`, `capabilities`, and `deviceId` when required by server flags.
- Default production/runtime gates are strict:
  - `enforce-client-action-id=true`
  - `enforce-game-action-state-version=true`
  - `enforce-token-revocation=true`
  - `strict-player-binding=true`
  - `require-device-id=true`
  - app version gate enabled (default min `3.0.0`).

## 2. Envelope Contract and Field Semantics

All websocket messages use a v3 envelope.

### Client -> Server base envelope
- Required in practice:
  - `type`
  - `protocolVersion`
  - `traceId`
- Common optional envelope keys:
  - `action`
  - `roomId`
  - `matchId`
  - `data`
  - `clientActionId`
  - `clientSentAt`
  - `stateVersion`

### Server -> Client success envelope
- `type`
- `action` (when applicable)
- `roomId` (when applicable)
- `matchId` (when applicable)
- `success=true`
- `data` (when applicable)
- `eventId`
- `traceId`
- `serverTime` (UTC ISO-8601)
- `protocolVersion`
- `stateVersion`
- `clientActionId` (echoed when applicable)

### Server -> Client error envelope
- `type=ERROR`
- `action`
- `roomId` (when applicable)
- `matchId` (when applicable)
- `success=false`
- `errorCode`
- `error`
- `clientActionId` (when applicable)
- `eventId`
- `traceId`
- `serverTime`
- `protocolVersion`
- `stateVersion` (when available)

### Semantic notes
- `stateVersion` is monotonic per game stream/room state and drives stale detection.
- `eventId` is used by client dedup logic.
- `traceId` is correlation metadata; preserve across client-generated envelopes.

## 3. Connection Bootstrap (AUTH, AUTH_SUCCESS, CLIENT_TELEMETRY, HEARTBEAT)

1. Connect to `/ws-v3`.
2. Send `AUTH` with token and v3 metadata.
3. On `AUTH_SUCCESS`:
   - store `sessionId`, `sessionVersion`, `capabilities`, and `serverConfig`
   - start/continue heartbeat loop
   - flush `CLIENT_TELEMETRY` snapshot
4. Send `HEARTBEAT` periodically (default client interval 30s).
5. Continue sending `CLIENT_TELEMETRY` snapshots on interval/significant deltas.

### AUTH request shape
```json
{
  "type": "AUTH",
  "token": "<jwt>",
  "protocolVersion": "v3",
  "appVersion": "3.0.0",
  "capabilities": [
    "CLIENT_ACTION_ID",
    "EVENT_DEDUP",
    "ACTION_ACK",
    "ACTION_REJECTED",
    "RESYNC_HANDLER",
    "STATE_VERSION",
    "MATCH_ID",
    "CLIENT_TELEMETRY"
  ],
  "deviceId": "dev-..."
}
```

## 4. Request Catalog

Each row lists business payload keys only. Envelope keys are defined in Section 2.

| Request `type` | Required payload keys | Optional payload keys | Auth required | Success signal(s) | Typical usage |
|---|---|---|---|---|---|
| `AUTH` | `token`, `protocolVersion`, `appVersion`, `capabilities` | `deviceId` (required when gate enabled) | No | `AUTH_SUCCESS` | initial handshake |
| `HEARTBEAT` | none | none | No | none | keep session active |
| `CLIENT_TELEMETRY` | `data` | telemetry fields inside `data` | Yes | `CLIENT_TELEMETRY_ACK` | runtime metrics |
| `CREATE_ROOM` | `gameType`, `roomType`, `entryFee` | `maxPlayers`, `gameScore`, `diceWinnerType` | Yes | `ROOM_CREATED` | create lobby room |
| `JOIN_ROOM` | `roomId` | none | Yes | `JOIN_ROOM_SUCCESS` | join existing room |
| `GET_ROOM` | `roomId` | none | Yes (runtime validation on sensitive types) | `ROOM_DETAILS` | fetch room details |
| `LEAVE_ROOM` | `roomId` | `data.roomId` accepted fallback | Yes | `LEAVE_ROOM_SUCCESS` | leave room / forfeit handling |
| `CANCEL_ROOM` | `roomId` | none | Yes | `CANCEL_ROOM_SUCCESS` | owner cancels room |
| `SUBSCRIBE_ROOMS` | `gameType` | none | Yes | `SUBSCRIBE_ROOMS_SUCCESS` plus async `room_list` | subscribe room list stream |
| `UNSUBSCRIBE_ROOMS` | `gameType` | none | Yes | `UNSUBSCRIBE_ROOMS_SUCCESS` | unsubscribe room list stream |
| `GET_ROOM_LIST` | `gameType` | none | Yes | async `room_list` | one-shot room list |
| `GET_FRIENDS` | none | none | Yes | `FRIENDS_LIST` | friends list |
| `GET_FRIEND_REQUESTS` | none | none | Yes | `FRIEND_REQUESTS` | incoming requests |
| `SEND_FRIEND_REQUEST` | `targetUserId` | none | Yes | `FRIEND_REQUEST_SENT` | send request |
| `ACCEPT_FRIEND_REQUEST` | `senderId` | none | Yes | `FRIEND_REQUEST_ACCEPTED` | accept request |
| `REJECT_FRIEND_REQUEST` | `senderId` | none | Yes | `FRIEND_REQUEST_REJECTED` | reject request |
| `REMOVE_FRIEND` | `friendId` | none | Yes | `FRIEND_REMOVED` | remove friendship |
| `BLOCK_USER` | `targetUserId` | none | Yes | `USER_BLOCKED` | block user |
| `UNBLOCK_USER` | `targetUserId` | none | Yes | `USER_UNBLOCKED` | unblock user |
| `SEARCH_USERS` | `query` (3-50 chars) | none | Yes | `SEARCH_RESULTS` | user search |
| `SEND_GAME_INVITATION` | `receiverId`, `gameType`, `entryFee`, `maxPlayers` | none | Yes | `GAME_INVITATION_SENT` | invite user |
| `ACCEPT_GAME_INVITATION` | `invitationId` | none | Yes | `GAME_INVITATION_ACCEPTED` | accept invite |
| `REJECT_GAME_INVITATION` | `invitationId` | none | Yes | `GAME_INVITATION_REJECTED` | reject invite |
| `CANCEL_GAME_INVITATION` | `invitationId` | none | Yes | `GAME_INVITATION_CANCELLED` | cancel outgoing invite |
| `GET_RECEIVED_INVITATIONS` | none | none | Yes | `RECEIVED_INVITATIONS` | received invites |
| `GET_SENT_INVITATIONS` | none | none | Yes | `SENT_INVITATIONS` | sent invites |
| `GET_PROFILE` | none | none | Yes | `USER_PROFILE` | profile fetch |
| `UPDATE_PROFILE` | profile fields (`firstName`, `phone`, `bio`, `gender`, `country`, etc.) | any accepted by `UpdateProfileRequest` | Yes | `PROFILE_UPDATED` | profile update |
| `GET_TRANSACTIONS` | none | none | Yes | `TRANSACTIONS_LIST` | wallet transactions |
| `GET_WITHDRAW_REQUESTS` | none | none | Yes | `WITHDRAW_REQUESTS` | withdrawal history |
| `REQUEST_WITHDRAW` | `amount` | none | Yes | `WITHDRAW_REQUESTED` | submit withdrawal |
| `GET_XP_HISTORY` | none | none | Yes | `XP_HISTORY` | XP history |
| `GET_GAME_HISTORY_USER` | none | `limit` (1..100), `userId` ignored server-side | Yes | `GAME_HISTORY_USER` | full history |
| `GET_GAME_RECENT_USER` | none | `limit` (1..100), `userId` ignored server-side | Yes | `GAME_RECENT_USER` | recent history |
| `GET_GAME_BEST_USER` | none | `userId` ignored server-side | Yes | `GAME_BEST_USER` | best sessions |
| `GET_GAME_STATS_USER` | none | `userId` ignored server-side | Yes | `GAME_STATS_USER` | aggregate stats |
| `GET_GAME_STATE` | `gameStateId` | none | Yes | `GAME_STATE` | state by ID |
| `GET_GAME_STATE_BY_ROOM` | `roomId` | none | Yes | `STATE_SNAPSHOT` | snapshot by room (resync path) |
| `GAME_ACTION` | `action`, `roomId`, `clientActionId` (when required), `data`, `data.stateVersion` (when required) | `matchId` | Yes | `ACTION_ACK`, async `GAME_ACTION` updates | gameplay command |

## 5. `GAME_ACTION` Catalog

### Global `GAME_ACTION` rules
- Required envelope keys: `type=GAME_ACTION`, `action`, `roomId`, `data`.
- `clientActionId` required when strict gate enabled (default true).
- `data.stateVersion` required when strict gate enabled (default true).
- `data.playerId` is validated against authenticated user when provided.
- Server applies strict player binding: effective `playerId` resolves to authenticated session user.
- On duplicate `clientActionId`, server returns `ACTION_ACK` with `duplicate=true`.
- On stale state (`client stateVersion < server stateVersion`), server returns `ERROR` with `STATE_RESYNC_REQUIRED` and `stateVersion`.

### Action-level payload requirements

| Action | Required `data` keys | Optional `data` keys | Notes |
|---|---|---|---|
| `RPS_CHOICE` | `gameStateId`, `playerId`, `choice` | none | submits RPS choice |
| `RPS_ROUND_TIMEOUT` | `gameStateId` | none | force timeout path |
| `DICE_ROLL` | `gameStateId`, `playerId` | none | roll dice |
| `DICE_ROUND_TIMEOUT` | `gameStateId` | none | timeout path |
| `BJ_HIT` | `gameStateId`, `playerId` | none | blackjack hit |
| `BJ_STAND` | `gameStateId`, `playerId` | none | blackjack stand |
| `BJ_TURN_TIMEOUT` | `gameStateId` | none | blackjack timeout |
| `CASINO_WAR_PICK_CARD` | `cardIndex` or `cardSlotIndex` | `playerId` | `playerId` can be derived from session |
| `CHOOSE_TRUMP` | `gameStateId`, `trumpSuit` | `trumpMode` | hokm trump choice |
| `PLAY_CARD` | `gameStateId`, `card` | none | hokm card play |
| `TURN_TIMEOUT` | `gameStateId` | none | hokm timeout |
| `PASS_CARDS_SELECTION` | `playerId`, `cards` | none | hearts passing selection; cards as `{suit, rank}` objects |
| `START_HEARTS_GAME` | none | none | currently no-op (kept for compatibility) |
| `HEARTS_PASSING_TIMER_ENDED` | none | none | ignored; server timer authoritative |
| `HEARTS_PLAY_CARD` | `playerId`, `card` object | none | card object includes `suit`, `rank` |
| `SHELEM_SUBMIT_BID` | `gameStateId`, `bidAmount` | none | shelem bidding |
| `SHELEM_PASS_BID` | `gameStateId` | none | shelem pass |
| `SHELEM_EXCHANGE_CARDS` | `gameStateId`, `cardsToReturn` | none | list of strings or `{suit, rank}` objects |
| `SHELEM_PLAY_CARD` | `gameStateId`, `card` | none | card as string or `{suit, rank}` |
| `SHELEM_TURN_TIMEOUT` | `gameStateId` | none | shelem timeout |
| `CE_PLAY_CARD` | `roomId`, `card` | none | crazy eights play |
| `CE_DRAW_CARD` | `roomId` | none | crazy eights draw |
| `CE_CHOOSE_SUIT` | `roomId`, `suit` | none | crazy eights choose suit |
| `CE_GIVE_CARD` | `roomId`, `targetPlayerId` | none | crazy eights give card |
| `CE_FORFEIT` | `roomId` | none | crazy eights forfeit |
| `CE_TURN_TIMEOUT` | `roomId` | none | crazy eights timeout |
| `RIM_DRAW_CARD` | `source` | `roomId`, `playerId` | `roomId` may be taken from envelope |
| `RIM_LAY_MELD` | `cards` | `roomId`, `playerId` | cards list must be non-empty |
| `RIM_ADD_TO_MELD` | `meldId`, `card`, `side` | `roomId`, `playerId` | side usually `START` or `END` |
| `RIM_DISCARD_CARD` | `card` | `roomId`, `playerId` | rim discard |
| `CHAHAR_BARG_PLAY_CARD` | `gameStateId`, `playerId`, `card` | none | chahar barg play |
| `CHAHAR_BARG_SELECT_CAPTURE` | `gameStateId`, `playerId`, `optionIndex` | none | capture selection |

## 6. Server Signal Catalog

### A. Direct response signals (`sendSuccess` path)
- `AUTH_SUCCESS`
- `CLIENT_TELEMETRY_ACK`
- `ROOM_CREATED`
- `JOIN_ROOM_SUCCESS`
- `ROOM_DETAILS`
- `LEAVE_ROOM_SUCCESS`
- `CANCEL_ROOM_SUCCESS`
- `SUBSCRIBE_ROOMS_SUCCESS`
- `UNSUBSCRIBE_ROOMS_SUCCESS`
- `FRIENDS_LIST`
- `FRIEND_REQUESTS`
- `FRIEND_REQUEST_SENT`
- `FRIEND_REQUEST_ACCEPTED`
- `FRIEND_REQUEST_REJECTED`
- `FRIEND_REMOVED`
- `USER_BLOCKED`
- `USER_UNBLOCKED`
- `SEARCH_RESULTS`
- `GAME_INVITATION_SENT`
- `GAME_INVITATION_ACCEPTED`
- `GAME_INVITATION_REJECTED`
- `GAME_INVITATION_CANCELLED`
- `RECEIVED_INVITATIONS`
- `SENT_INVITATIONS`
- `USER_PROFILE`
- `PROFILE_UPDATED`
- `TRANSACTIONS_LIST`
- `WITHDRAW_REQUESTS`
- `WITHDRAW_REQUESTED`
- `XP_HISTORY`
- `GAME_STATE`
- `STATE_SNAPSHOT`
- `ACTION_ACK`
- `GAME_HISTORY_USER`
- `GAME_RECENT_USER`
- `GAME_BEST_USER`
- `GAME_STATS_USER`

### B. Async room/social signal types (`WebSocketRoomService` and related services)
- `room_list`
- `room_created`
- `room_update`
- `room_cancelled`
- `room_removed`
- `GAME_STARTED`
- `GAME_ACTION` (runtime game stream, see list below)
- `FRIENDS_LIST` (push refresh)
- `FRIEND_REQUESTS` (push refresh)
- `GAME_INVITATION_SENT` (push to receiver)
- `GAME_INVITATION_RESPONSE` (push invitation status)
- `USER_STATUS`
- `USER_PROFILE` (targeted profile update push)
- `ownership_transferred`

Non-normative note: `STICKER` and `QUICK_MESSAGE` are emitted by legacy controller paths and are excluded from the Opus `/ws-v3` integration baseline.

### C. `GAME_ACTION` stream (`type=GAME_ACTION`, action-specific payload)
Observed active action values from service flows:
- `BID_PASSED`
- `BID_SUBMITTED`
- `BID_WINNER`
- `BJ_CARD_DRAWN`
- `BJ_GAME_FINISHED`
- `BJ_PLAYER_BUSTED`
- `BJ_PLAYER_STOOD`
- `BJ_ROUND_RESULT`
- `BJ_ROUND_STARTED`
- `CARD_PLAYED`
- `CASINO_WAR_CARD_PICKED`
- `CASINO_WAR_GAME_FINISHED`
- `CASINO_WAR_PLAYER_FORFEITED`
- `CASINO_WAR_REVEAL_COUNTDOWN`
- `CASINO_WAR_ROUND_RESULT`
- `CASINO_WAR_ROUND_STARTED`
- `CE_CARD_DRAWN`
- `CE_CARD_GIVEN`
- `CE_CARD_PLAYED`
- `CE_GAME_FINISHED`
- `CE_GAME_STARTED`
- `CE_PLAY_ERROR`
- `CE_PLAYER_LEFT`
- `CE_SUIT_CHANGED`
- `CHAHAR_BARG_CAPTURE_OPTIONS`
- `CHAHAR_BARG_GAME_FINISHED`
- `CHAHAR_BARG_GAME_STARTED`
- `CHAHAR_BARG_HAND_FINISHED`
- `CHAHAR_BARG_STATE_UPDATED`
- `DICE_GAME_FINISHED`
- `DICE_ROLL_MADE`
- `DICE_ROUND_RESULT`
- `DICE_ROUND_STARTED`
- `DICE_ROUND_TIMEOUT`
- `GAME_FINISHED`
- `GAME_STATE_UPDATED`
- `HAND_WON`
- `HEARTS_PLAYING_STARTED`
- `HEARTS_ROUND_STARTED`
- `HEARTS_TRICK_FINISHED`
- `NEW_ROUND_STARTED`
- `RIM_ERROR`
- `RIM_GAME_FINISHED`
- `RIM_GAME_STARTED`
- `RIM_HAND_FINISHED`
- `RIM_STATE_UPDATED`
- `ROUND_ENDED`
- `RPS_CHOICE_MADE`
- `RPS_GAME_FINISHED`
- `RPS_ROUND_RESULT`
- `RPS_ROUND_STARTED`
- `RPS_ROUND_TIMEOUT`
- `TRUMP_SET`
- `TURN_TIMER_STARTED`

## 7. Error Handling Matrix

| Error code | Typical trigger | Client action |
|---|---|---|
| `AUTH_REQUIRED` | missing/invalid runtime session for sensitive request | redirect to login flow and re-auth |
| `AUTH_EXPIRED` | expired token or session version mismatch | clear auth state, force login |
| `TOKEN_REVOKED` | blocklist/store revocation at auth/runtime | clear auth state, disconnect, force login |
| `INVALID_TOKEN` | malformed/signature invalid/unsupported token | clear auth state, force login |
| `APP_VERSION_UNSUPPORTED` | app version below minimum gate | block realtime, force app update UX |
| `ACTION_REJECTED` | validation failure (`clientActionId`, payload shape, unknown action, etc.) | surface error, clear pending action if correlated |
| `STATE_RESYNC_REQUIRED` | stale client state or queue processing failure | immediately send `GET_GAME_STATE_BY_ROOM`, replace local state |
| `RATE_LIMITED` | per-user/per-action throttle exceeded | backoff and retry later |

## 8. Reliability and Ordering Rules

- Idempotency: `clientActionId` dedup window exists (server dedups and ACKs duplicates).
- Optimistic ACK: `ACTION_ACK` with `accepted=true` means accepted into processing path, not guaranteed final game-state success.
- Duplicate ACK: `ACTION_ACK` with `duplicate=true` means server already processed or observed same action id.
- Ordered processing: game actions are serialized by room queue.
- Resync policy: any stale/error path can return `STATE_RESYNC_REQUIRED`; client must request snapshot and reconcile.
- Envelope dedup: client drops duplicate `eventId` within dedup window.
- Out-of-order guard: client drops older `stateVersion` updates for ordered streams.
- Runtime session enforcement applies beyond initial auth; token/session version checks can close connection with policy violation.
- Frontend kill switch:
  - `WS_REALTIME_ENABLED=false`
  - `WS_REALTIME_DISABLED_REASON="..."`

## 9. Page Integration Matrix (Current App Mapping)

### Core app bootstrap
- Files:
  - `gameapp/lib/main.dart`
  - `gameapp/lib/core/services/websocket_manager.dart`
- Behavior:
  - connect once app starts
  - register auth-invalidated listener
  - auto-auth via `AUTH`
  - run heartbeat and telemetry loops

### Rooms and lobby
- Provider files:
  - `gameapp/lib/features/game/providers/game_rooms_provider_v2.dart`
  - `gameapp/lib/features/game/providers/game_provider_v2.dart`
- Sends:
  - `SUBSCRIBE_ROOMS`, `GET_ROOM_LIST`, `UNSUBSCRIBE_ROOMS`
  - `CREATE_ROOM`, `JOIN_ROOM`, `GET_ROOM`, `LEAVE_ROOM`, `CANCEL_ROOM`
- Subscribes:
  - `room_list`, `room_created`, `room_update`, `room_removed`, `room_cancelled`
  - `ROOM_CREATED`, `JOIN_ROOM_SUCCESS`, `JOIN_ROOM_ERROR`
  - `ROOM_DETAILS`, `LEAVE_ROOM_SUCCESS`, `CANCEL_ROOM_SUCCESS`

### Game state and gameplay stream
- Files:
  - `gameapp/lib/features/game/providers/game_provider_v2.dart`
  - `gameapp/lib/features/game/ui/game_ui/*.dart`
- Sends:
  - `GET_GAME_STATE`, `GET_GAME_STATE_BY_ROOM`
  - `GAME_ACTION` via `sendGameAction(...)`
- Subscribes:
  - `GAME_STATE`
  - `GAME_ACTION`
  - `STATE_SNAPSHOT` handled through manager aliasing (`STATE_SNAPSHOT` also triggers `GAME_STATE` callbacks)

### Game action send mapping by UI file
- `rps_game_ui.dart`: `RPS_CHOICE`
- `dice_game_ui.dart`: `DICE_ROLL`
- `blackjack_game_ui.dart`: `BJ_HIT`, `BJ_STAND`, `BJ_TURN_TIMEOUT`
- `casino_war_game_ui.dart`: `CASINO_WAR_PICK_CARD`
- `hokm_game_ui.dart`: `CHOOSE_TRUMP`, `PLAY_CARD`, `TURN_TIMEOUT`
- `hearts_game_ui.dart`: `HEARTS_PLAY_CARD`, `PASS_CARDS_SELECTION`
- `shelem_game_ui.dart`: `SHELEM_SUBMIT_BID`, `SHELEM_PASS_BID`, `SHELEM_EXCHANGE_CARDS`, `SHELEM_PLAY_CARD`, `SHELEM_TURN_TIMEOUT`
- `crazy_eights_game_ui.dart`: `CE_PLAY_CARD`, `CE_DRAW_CARD`, `CE_CHOOSE_SUIT`, `CE_GIVE_CARD`, `CE_FORFEIT`
- `rim_game_ui.dart`: `RIM_DRAW_CARD`, `RIM_LAY_MELD`, `RIM_ADD_TO_MELD`, `RIM_DISCARD_CARD`
- `chahar_barg_game_ui.dart`: `CHAHAR_BARG_PLAY_CARD`, `CHAHAR_BARG_SELECT_CAPTURE`

### Friends
- File: `gameapp/lib/features/friends/providers/friends_provider_v2.dart`
- Sends: `GET_FRIENDS`, `SEND_FRIEND_REQUEST`, `REMOVE_FRIEND`, `BLOCK_USER`, `UNBLOCK_USER`
- Subscribes: `FRIENDS_LIST`, `USER_STATUS`, `FRIEND_REQUEST_SENT`, `FRIEND_REQUEST_ACCEPTED`, `FRIEND_REMOVED`, `USER_BLOCKED`, `USER_UNBLOCKED`

### Friend requests and search
- File: `gameapp/lib/features/friends/providers/friends_provider_v2.dart`
- Sends: `GET_FRIEND_REQUESTS`, `ACCEPT_FRIEND_REQUEST`, `REJECT_FRIEND_REQUEST`, `SEARCH_USERS`
- Subscribes: `FRIEND_REQUESTS`, `FRIEND_REQUEST_ACCEPTED`, `FRIEND_REQUEST_REJECTED`, `SEARCH_RESULTS`

### Profile
- File: `gameapp/lib/features/profile/providers/profile_provider_v2.dart`
- Sends: `GET_PROFILE`, `UPDATE_PROFILE`
- Subscribes: `USER_PROFILE`, `PROFILE_UPDATED`

### Wallet and XP
- File: `gameapp/lib/features/wallet/providers/wallet_provider_v2.dart`
- Sends: `GET_TRANSACTIONS`, `GET_WITHDRAW_REQUESTS`, `REQUEST_WITHDRAW`, `GET_XP_HISTORY`
- Subscribes: `TRANSACTIONS_LIST`, `WITHDRAW_REQUESTS`, `WITHDRAW_REQUESTED`, `XP_HISTORY`

### History and stats
- File: `gameapp/lib/features/game/providers/game_history_provider.dart`
- Sends: `GET_GAME_HISTORY_USER`, `GET_GAME_RECENT_USER`, `GET_GAME_BEST_USER`, `GET_GAME_STATS_USER`
- Subscribes: `GAME_HISTORY_USER`, `GAME_RECENT_USER`, `GAME_BEST_USER`, `GAME_STATS_USER`

## 10. Opus Execution Recipe (Deterministic)

1. Build one reusable websocket client wrapper with v3 envelope defaults.
2. Implement connection lifecycle:
   - connect
   - send `AUTH`
   - start heartbeat
   - start telemetry loop
3. Add critical error interceptor for `ERROR` codes:
   - `TOKEN_REVOKED`, `AUTH_EXPIRED`, `APP_VERSION_UNSUPPORTED`: clear auth + disconnect + route to login/update
   - `STATE_RESYNC_REQUIRED`: call `GET_GAME_STATE_BY_ROOM` and replace room state from `STATE_SNAPSHOT`
4. Implement `sendGameAction(action, roomId, data, clientActionId?)` adapter:
   - inject `data.stateVersion` from latest known room stream
   - ensure `clientActionId` exists
   - track pending action until `ACTION_ACK` or correlated `ERROR`
5. Implement stream ordering guards:
   - dedup by `eventId`
   - drop out-of-order messages by `stateVersion` per room stream
6. Wire feature modules according to Section 9 mapping.
7. Use only documented request/signal names from this guide.
8. Do not depend on v2 docs or v2 endpoint names.

## 11. Known Mismatches and Migration Notes

- `GET_GAME_STATE_BY_ROOM` returns `STATE_SNAPSHOT` (not `GAME_STATE`).
- `ACTION_ACK` confirms acceptance/dedup handling, not guaranteed final apply success.
- `ERROR` + `STATE_RESYNC_REQUIRED` must trigger immediate snapshot pull.
- Runtime auth/session validation can close an already-authenticated socket when token/session state changes.
- `GAME_INVITATION_SENT` can arrive in two shapes:
  - direct request response (`success=true`)
  - async push notification payload (may omit `success`)
- Event name casing differs in some streams:
  - room broadcasts: `room_list`, `room_created`, `room_update`, `room_cancelled`, `room_removed`
  - direct success: uppercase style like `ROOM_CREATED`, `JOIN_ROOM_SUCCESS`
- Debug/test-controller-only surfaces are excluded from this contract.
- Legacy v2 docs and `/ws-v2` behavior are non-authoritative for current implementation.

## 12. Payload-Complete Runtime Artifacts

For implementation/runtime enforcement, use these frontend artifacts:
- `gameapp/lib/core/websocket/ws_contract_catalog.dart`
- `gameapp/lib/core/websocket/ws_contract_runtime.dart`
- `gameapp/lib/core/websocket/ws_envelope.dart`
- `gameapp/lib/core/websocket/ws_normalization_adapter.dart`
- `gameapp/lib/core/websocket/ws_error_policy.dart`

For compact handoff to constrained agents (no local file access), use:
- `docs/OPUS_WS_V3_CONTRACT_CHUNKS.md`
- `docs/WS_V3_PAYLOAD_INVENTORY.md`
