# WebSocket v2 Protocol + Opus Implementation Brief

## 1. Reality check on current docs

`README_WEBSOCKET_V2.md` is **not a complete protocol spec**.
It is mostly usage guidance (manager/provider/how-to) and does not list all request/response contracts, all `type` signals, all `GAME_ACTION` actions, required payload fields, or per-page wiring rules.

Use backend source as the protocol source of truth:

- `gameBackend/src/main/java/com/gameapp/game/ImprovedWebSocketConfig.java`
- `gameBackend/src/main/java/com/gameapp/game/services/WebSocketMessageHandler.java`
- `gameBackend/src/main/java/com/gameapp/game/services/WebSocketRoomService.java`
- Game engines under `gameBackend/src/main/java/com/gameapp/game/services/*EngineService.java`

## 2. Transport and envelope contract

### Endpoint

- `ws://<host>:8080/ws-v2` (actual URL built by frontend `Endpoints.currentWebSocketUrl`)

### Connection bootstrap

1. Open socket.
2. Send auth:
```json
{"type":"AUTH","token":"<jwt>"}
```
3. Send heartbeat every ~30s:
```json
{"type":"HEARTBEAT"}
```

### Request shape

- Most requests:
```json
{"type":"<REQUEST_TYPE>", "...":"..."}
```
- Game actions:
```json
{"type":"GAME_ACTION","action":"<ACTION_NAME>","roomId":123,"...":"..."}
```

### Success response shape

```json
{"type":"<RESPONSE_TYPE>","success":true,"data":{...}}
```

### Error response shape

```json
{"type":"ERROR","action":"<REQUEST_OR_ACTION>","success":false,"error":"<message>"}
```

### Server game event shape

```json
{"type":"GAME_ACTION","action":"<EVENT_ACTION>","roomId":123,"data":{...}}
```

## 3. Supported request `type` values (client -> server)

From `registerMessageProcessors()`:

- `AUTH`
- `HEARTBEAT`
- `CREATE_ROOM`
- `JOIN_ROOM`
- `GET_ROOM`
- `LEAVE_ROOM`
- `CANCEL_ROOM`
- `SUBSCRIBE_ROOMS`
- `UNSUBSCRIBE_ROOMS`
- `GET_ROOM_LIST`
- `GET_FRIENDS`
- `GET_FRIEND_REQUESTS`
- `SEND_FRIEND_REQUEST`
- `ACCEPT_FRIEND_REQUEST`
- `REJECT_FRIEND_REQUEST`
- `REMOVE_FRIEND`
- `BLOCK_USER`
- `UNBLOCK_USER`
- `SEARCH_USERS`
- `SEND_GAME_INVITATION`
- `ACCEPT_GAME_INVITATION`
- `REJECT_GAME_INVITATION`
- `CANCEL_GAME_INVITATION`
- `GET_RECEIVED_INVITATIONS`
- `GET_SENT_INVITATIONS`
- `GET_PROFILE`
- `UPDATE_PROFILE`
- `GET_TRANSACTIONS`
- `GET_WITHDRAW_REQUESTS`
- `REQUEST_WITHDRAW`
- `GET_XP_HISTORY`
- `GET_GAME_HISTORY_USER`
- `GET_GAME_RECENT_USER`
- `GET_GAME_BEST_USER`
- `GET_GAME_STATS_USER`
- `GET_GAME_STATE`
- `GET_GAME_STATE_BY_ROOM`
- `GAME_ACTION`

## 4. Supported `GAME_ACTION` request actions (client -> server)

- `RPS_CHOICE`
- `RPS_ROUND_TIMEOUT`
- `DICE_ROLL`
- `DICE_ROUND_TIMEOUT`
- `BJ_HIT`
- `BJ_STAND`
- `BJ_TURN_TIMEOUT`
- `CASINO_WAR_PICK_CARD`
- `CHOOSE_TRUMP`
- `PLAY_CARD`
- `TURN_TIMEOUT`
- `PASS_CARDS_SELECTION`
- `START_HEARTS_GAME`
- `HEARTS_PASSING_TIMER_ENDED`
- `HEARTS_PLAY_CARD`
- `SHELEM_SUBMIT_BID`
- `SHELEM_PASS_BID`
- `SHELEM_EXCHANGE_CARDS`
- `SHELEM_PLAY_CARD`
- `SHELEM_TURN_TIMEOUT`
- `CE_PLAY_CARD`
- `CE_DRAW_CARD`
- `CE_CHOOSE_SUIT`
- `CE_GIVE_CARD`
- `CE_FORFEIT`
- `CE_TURN_TIMEOUT`
- `RIM_DRAW_CARD`
- `RIM_LAY_MELD`
- `RIM_ADD_TO_MELD`
- `RIM_DISCARD_CARD`
- `CHAHAR_BARG_PLAY_CARD`
- `CHAHAR_BARG_SELECT_CAPTURE`

## 5. Common response and push `type` values (server -> client)

### Standard success responses

- `AUTH_SUCCESS`
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
- `GAME_HISTORY_USER`
- `GAME_RECENT_USER`
- `GAME_BEST_USER`
- `GAME_STATS_USER`

### Room/lobby/broadcast push types

- `room_list`
- `room_created`
- `room_update`
- `room_removed`
- `room_cancelled`
- `GAME_STARTED`
- `GAME_ACTION`
- `STICKER`
- `QUICK_MESSAGE`
- `USER_STATUS`
- `GAME_INVITATION_RESPONSE`

## 6. Known important event actions emitted by server (`type = GAME_ACTION`)

- `RPS_ROUND_STARTED`
- `RPS_CHOICE_MADE`
- `RPS_ROUND_RESULT`
- `RPS_ROUND_TIMEOUT`
- `RPS_GAME_FINISHED`
- `DICE_ROLL_MADE`
- `DICE_ROUND_STARTED`
- `DICE_ROUND_TIMEOUT`
- `DICE_ROUND_RESULT`
- `DICE_GAME_FINISHED`
- `BJ_ROUND_STARTED`
- `BJ_CARD_DRAWN`
- `BJ_PLAYER_STOOD`
- `BJ_PLAYER_BUSTED`
- `BJ_ROUND_RESULT`
- `BJ_GAME_FINISHED`
- `CASINO_WAR_ROUND_STARTED`
- `CASINO_WAR_CARD_PICKED`
- `CASINO_WAR_REVEAL_COUNTDOWN`
- `CASINO_WAR_ROUND_RESULT`
- `CASINO_WAR_PLAYER_FORFEITED`
- `CASINO_WAR_GAME_FINISHED`
- `GAME_STATE_UPDATED`
- `HAND_WON`
- `ROUND_ENDED`
- `NEW_ROUND_STARTED`
- `GAME_FINISHED`
- `TURN_TIMER_STARTED`
- `TRUMP_SET`
- `HEARTS_ROUND_STARTED`
- `HEARTS_PLAYING_STARTED`
- `HEARTS_TRICK_FINISHED`
- `CARD_PLAYED`
- `CE_GAME_STARTED`
- `CE_CARD_PLAYED`
- `CE_CARD_DRAWN`
- `CE_SUIT_CHANGED`
- `CE_CARD_GIVEN`
- `CE_PLAYER_LEFT`
- `CE_GAME_FINISHED`
- `CE_PLAY_ERROR`
- `RIM_GAME_STARTED`
- `RIM_STATE_UPDATED`
- `RIM_HAND_FINISHED`
- `RIM_GAME_FINISHED`
- `RIM_ERROR`
- `CHAHAR_BARG_GAME_STARTED`
- `CHAHAR_BARG_STATE_UPDATED`
- `CHAHAR_BARG_CAPTURE_OPTIONS`
- `CHAHAR_BARG_HAND_FINISHED`
- `CHAHAR_BARG_GAME_FINISHED`

## 7. Important mismatch to fix while wiring pages

Current CE UI listens for `CE_SUIT_CHOSEN` and `CE_GAME_STATE`, while backend emits `CE_SUIT_CHANGED` and does not emit `CE_GAME_STATE` in current flow.

If new pages copy current UI behavior blindly, these mismatches can break state updates.

## 8. Copy-paste prompt for Opus (use this as-is)

```md
You are implementing full WebSocket v2 integration for this project.

Goal:
- Connect all relevant UI pages to existing backend socket protocol.
- Do not invent new protocol names. Use exact request/response/action names already implemented in backend.

Protocol source of truth:
- gameBackend/src/main/java/com/gameapp/game/ImprovedWebSocketConfig.java
- gameBackend/src/main/java/com/gameapp/game/services/WebSocketMessageHandler.java
- gameBackend/src/main/java/com/gameapp/game/services/WebSocketRoomService.java
- gameBackend/src/main/java/com/gameapp/game/services/*EngineService.java
- docs/OPUS_SOCKET_IMPLEMENTATION_BRIEF.md

Execution requirements:
1. Build/keep one shared socket manager with:
   - connect, disconnect, auth, heartbeat
   - reconnect strategy
   - typed event routing by `type` and by `action` when `type=GAME_ACTION`
   - listener registration + cleanup per page lifecycle
2. Implement per-page wiring:
   - lobby rooms list and updates
   - room join/leave/cancel lifecycle
   - friends, invites, profile, wallet/history requests and updates
   - all game pages should send valid `GAME_ACTION` requests and consume matching server `GAME_ACTION` events
3. Enforce payload validation before sending each request/action.
4. Add clear error handling for `type=ERROR` events.
5. Fix protocol naming mismatches where UI expects unsupported actions.
6. Keep existing backend contract unchanged unless absolutely necessary.

Validation checklist:
1. Successful AUTH over `/ws-v2`.
2. No unsupported `type` errors in backend logs during normal flows.
3. Each page receives and renders expected updates from socket events.
4. Reconnect recovers subscriptions/state cleanly.
5. Manual test each game action flow end-to-end.

Deliverables:
1. Code changes.
2. A concise protocol map (request types, response types, action names) generated from actual source.
3. A page-by-page mapping table: page -> sent messages -> listened events.
4. A short list of protocol mismatches found and fixed.
```

## 9. Definition of done

1. Every migrated page uses socket as primary data path.
2. No stale HTTP fallback for features already supported by `ws-v2`.
3. Listener cleanup prevents duplicate handlers after navigation.
4. End-to-end test runs show no dropped critical events.
