# P06 - Gameplay Core Infrastructure (Paste to Opus)

```md
Phase 06 only: implement shared gameplay WS infrastructure before per-game actions.

Core requirements:
1. Add/complete one `sendGameAction(...)` helper with standard payload:
   - `type: GAME_ACTION`
   - `action`
   - `roomId`
   - `data`
   - `clientActionId` (required)
   - `data.stateVersion` (required)
2. Track per-room `stateVersion` from incoming envelopes/messages.
3. Maintain pending actions map by `clientActionId`.
4. Handle `ACTION_ACK`:
   - accepted path
   - duplicate path (`duplicate=true`)
5. On `ERROR` + `STATE_RESYNC_REQUIRED`:
   - call `GET_GAME_STATE_BY_ROOM`
   - replace local room/game state using `STATE_SNAPSHOT`
6. Ensure all game UIs use `sendGameAction(...)` (no raw custom `GAME_ACTION` maps).

Envelope awareness:
- read and preserve: `eventId`, `traceId`, `serverTime`, `protocolVersion`, `stateVersion`

Done criteria:
- gameplay action pipeline is centralized
- idempotency + stale-state recovery are deterministic

Output format:
1. changed files
2. pending-action / ack / resync flow summary
3. list of game UIs switched to `sendGameAction(...)`
```
