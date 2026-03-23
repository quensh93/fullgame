# P05 - Profile + Wallet + History + Snapshot APIs (Paste to Opus)

```md
Phase 05 only: wire profile/wallet/history/state request-response flows.

Profile/Wallet requests:
- `GET_PROFILE` -> `USER_PROFILE`
- `UPDATE_PROFILE` -> `PROFILE_UPDATED`
- `GET_TRANSACTIONS` -> `TRANSACTIONS_LIST`
- `GET_WITHDRAW_REQUESTS` -> `WITHDRAW_REQUESTS`
- `REQUEST_WITHDRAW` -> `WITHDRAW_REQUESTED`
- `GET_XP_HISTORY` -> `XP_HISTORY`

Game history/stat requests:
- `GET_GAME_HISTORY_USER` -> `GAME_HISTORY_USER`
- `GET_GAME_RECENT_USER` -> `GAME_RECENT_USER`
- `GET_GAME_BEST_USER` -> `GAME_BEST_USER`
- `GET_GAME_STATS_USER` -> `GAME_STATS_USER`

Game state snapshot requests:
- `GET_GAME_STATE` -> `GAME_STATE`
- `GET_GAME_STATE_BY_ROOM` -> `STATE_SNAPSHOT` (important)

Mandatory compatibility rule:
- Resync path must use `GET_GAME_STATE_BY_ROOM` and consume `STATE_SNAPSHOT`.
- Do not expect `GAME_STATE` for room-based resync.

Done criteria:
- all above requests are integrated with loading/success/error UI states
- state snapshot pipeline is reusable for gameplay resync

Output format:
1. changed files
2. request -> response handler mapping
3. fields normalized/parsed for UI models
```
