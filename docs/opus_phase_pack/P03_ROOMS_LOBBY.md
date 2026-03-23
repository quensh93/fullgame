# P03 - Rooms + Lobby Lifecycle (Paste to Opus)

```md
Phase 03 only: wire room/lobby requests and subscriptions.

Requests to implement (send paths + response handling):
- `CREATE_ROOM` -> `ROOM_CREATED`
- `JOIN_ROOM` -> `JOIN_ROOM_SUCCESS`
- `GET_ROOM` -> `ROOM_DETAILS`
- `LEAVE_ROOM` -> `LEAVE_ROOM_SUCCESS`
- `CANCEL_ROOM` -> `CANCEL_ROOM_SUCCESS`
- `SUBSCRIBE_ROOMS` -> `SUBSCRIBE_ROOMS_SUCCESS`
- `UNSUBSCRIBE_ROOMS` -> `UNSUBSCRIBE_ROOMS_SUCCESS`
- `GET_ROOM_LIST` -> async `room_list`

Async room signals to support:
- `room_list`
- `room_created`
- `room_update`
- `room_cancelled`
- `room_removed`
- `GAME_STARTED`
- `ownership_transferred`

Rules:
1. Preserve mixed casing exactly (uppercase and lowercase signal names are both valid).
2. Ensure lobby pages unsubscribe on unmount/navigation.
3. Ensure room detail page updates from both direct response and async room updates.

Done criteria:
- lobby list is live-updating via room async signals
- room join/leave/cancel lifecycle is fully socket-driven
- no duplicate subscription handlers

Output format:
1. changed files
2. page/component mapping for each room request/signal
3. pending gaps for next phase
```
