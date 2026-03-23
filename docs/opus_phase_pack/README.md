# Opus WS-v3 Phase Pack

Date: 2026-02-20

Use this pack when Opus cannot access your local files.

## How to use
1. Open `P00_CONTEXT.md` and paste its prompt to Opus.
2. Wait for Opus to finish that phase.
3. Continue in order: `P00.5` -> `P01` -> `P02` -> ... -> `P09`.
4. If Opus loses context, paste `P00_CONTEXT.md` again, then continue.

## Important
- Each phase is intentionally short and self-contained.
- Do not paste all phases at once.
- These prompts are based on WS v3 only.
- `README_WEBSOCKET_V2.md` is legacy and not authoritative.

## Phase list
- `P00_CONTEXT.md`
- `P00.5_AUTH_REST_BOOTSTRAP.md`
- `P01_TRANSPORT_AUTH.md`
- `P02_ROUTING_ERRORS_RESYNC.md`
- `P03_ROOMS_LOBBY.md`
- `P04_FRIENDS_INVITES.md`
- `P05_PROFILE_WALLET_HISTORY_STATE.md`
- `P06_GAMEPLAY_CORE.md`
- `P07_GAME_ACTIONS_SET_A.md`
- `P08_GAME_ACTIONS_SET_B.md`
- `P09_FINAL_VALIDATION_REPORT.md`
