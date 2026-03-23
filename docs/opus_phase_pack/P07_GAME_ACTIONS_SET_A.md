# P07 - Game Actions Set A (Paste to Opus)

```md
Phase 07 only: wire these `GAME_ACTION` actions (send + receive-driven UI updates).

Implement action send payload validation for:
1. `RPS_CHOICE` -> required: `gameStateId`, `playerId`, `choice`
2. `RPS_ROUND_TIMEOUT` -> required: `gameStateId`
3. `DICE_ROLL` -> required: `gameStateId`, `playerId`
4. `DICE_ROUND_TIMEOUT` -> required: `gameStateId`
5. `BJ_HIT` -> required: `gameStateId`, `playerId`
6. `BJ_STAND` -> required: `gameStateId`, `playerId`
7. `BJ_TURN_TIMEOUT` -> required: `gameStateId`
8. `CASINO_WAR_PICK_CARD` -> required: (`cardIndex` or `cardSlotIndex`), optional `playerId`
9. `CHOOSE_TRUMP` -> required: `gameStateId`, `trumpSuit`; optional: `trumpMode`
10. `PLAY_CARD` -> required: `gameStateId`, `card`
11. `TURN_TIMEOUT` -> required: `gameStateId`
12. `PASS_CARDS_SELECTION` -> required: `playerId`, `cards` (array of `{suit, rank}`)
13. `START_HEARTS_GAME` -> compatibility no-op (keep backward-safe path)
14. `HEARTS_PASSING_TIMER_ENDED` -> compatibility no-op (server timer authoritative)
15. `HEARTS_PLAY_CARD` -> required: `playerId`, `card` object `{suit, rank}`

Streaming behavior:
- consume `type=GAME_ACTION` updates and update UI state reactively
- do not treat `ACTION_ACK` as final game state

Done criteria:
- all listed actions send through shared `sendGameAction(...)`
- each action has input guard + error UX
- pages react to incoming `GAME_ACTION` updates

Output format:
1. changed files
2. action -> page/component mapping
3. rejected-input cases handled
```
