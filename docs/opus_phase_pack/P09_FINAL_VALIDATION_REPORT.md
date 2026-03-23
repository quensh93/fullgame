# P09 - Final Validation + Delivery Report (Paste to Opus)

```md
Final phase: validate integration coverage and return a complete implementation report.

Validation tasks:
1. Run available type-check/lint/tests in the current project.
2. If some commands are unavailable, state exactly what was unavailable and why.
3. Confirm no direct raw `GAME_ACTION` custom maps are left (shared sender only).
4. Confirm stale-state recovery path works (`STATE_RESYNC_REQUIRED` -> `GET_GAME_STATE_BY_ROOM` -> `STATE_SNAPSHOT`).

Required final report sections:
1. **Changed Files**
2. **Request Coverage Table**
   - each request type -> sender location -> response handler
3. **GAME_ACTION Coverage Table**
   - each action -> sender location -> listener/state update path
4. **Signal Coverage Table**
   - each server signal -> handler location
5. **Error Handling Matrix**
   - each error code -> client behavior implemented
6. **Known Mismatches + Fixes**
7. **Remaining TODOs**
   - classify each as blocker/non-blocker

Do not include vague summaries. Provide concrete file paths and function names.
```
