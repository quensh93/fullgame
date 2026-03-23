# P02 - Message Routing + Error Matrix + Resync (Paste to Opus)

```md
Phase 02 only: implement runtime routing and mandatory error/resync behavior.

Routing requirements:
1. Route by `type` first.
2. If `type == GAME_ACTION`, route by `action` too.
3. Keep a pending-action map by `clientActionId`.
4. Handle `ACTION_ACK` as acceptance/dedup only (not final game success).

Mandatory error codes and client behavior:
- `AUTH_REQUIRED`: stop restricted flows, request re-auth.
- `AUTH_EXPIRED`: clear auth state, disconnect, force login.
- `TOKEN_REVOKED`: clear auth state, disconnect, force login.
- `INVALID_TOKEN`: clear auth state, force login.
- `APP_VERSION_UNSUPPORTED`: block realtime path and show update-required state.
- `ACTION_REJECTED`: surface error; if correlated by `clientActionId`, clear that pending action.
- `STATE_RESYNC_REQUIRED`: immediately send `GET_GAME_STATE_BY_ROOM`, then replace local room/game state from `STATE_SNAPSHOT`.
- `RATE_LIMITED`: apply backoff and retry strategy.

Envelope fields to preserve from server messages:
- `eventId`, `traceId`, `serverTime`, `protocolVersion`, `stateVersion`

Done criteria:
- `ERROR` handling is centralized and deterministic.
- stale-state path (`STATE_RESYNC_REQUIRED`) triggers immediate snapshot pull.
- duplicate ACK / rejected action cleanup works by `clientActionId`.

Output format:
1. changed files
2. error-code -> behavior mapping implemented
3. resync flow details
```
