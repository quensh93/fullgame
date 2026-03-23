# P08 - Game Actions Set B (Paste to Opus)

```md
Phase 08 only: wire remaining `GAME_ACTION` actions (send + receive-driven UI updates).

Implement action send payload validation for:
1. `SHELEM_SUBMIT_BID` -> required: `gameStateId`, `bidAmount`
2. `SHELEM_PASS_BID` -> required: `gameStateId`
3. `SHELEM_EXCHANGE_CARDS` -> required: `gameStateId`, `cardsToReturn` (strings or `{suit, rank}` objects)
4. `SHELEM_PLAY_CARD` -> required: `gameStateId`, `card`
5. `SHELEM_TURN_TIMEOUT` -> required: `gameStateId`

6. `CE_PLAY_CARD` -> required: `roomId`, `card`
7. `CE_DRAW_CARD` -> required: `roomId`
8. `CE_CHOOSE_SUIT` -> required: `roomId`, `suit`
9. `CE_GIVE_CARD` -> required: `roomId`, `targetPlayerId`
10. `CE_FORFEIT` -> required: `roomId`
11. `CE_TURN_TIMEOUT` -> required: `roomId`

12. `RIM_DRAW_CARD` -> required: `source`; optional: `roomId`, `playerId`
13. `RIM_LAY_MELD` -> required: `cards` (non-empty); optional: `roomId`, `playerId`
14. `RIM_ADD_TO_MELD` -> required: `meldId`, `card`, `side`; optional: `roomId`, `playerId`
15. `RIM_DISCARD_CARD` -> required: `card`; optional: `roomId`, `playerId`

16. `CHAHAR_BARG_PLAY_CARD` -> required: `gameStateId`, `playerId`, `card`
17. `CHAHAR_BARG_SELECT_CAPTURE` -> required: `gameStateId`, `playerId`, `optionIndex`

Done criteria:
- all listed actions integrated through shared gameplay pipeline
- each action has strict client-side input guards
- action results reflected via incoming `GAME_ACTION` stream and/or snapshot refresh

Output format:
1. changed files
2. action -> sender page -> listener mapping
3. unresolved mismatches (if any)
```
