# P00 - Context Bootstrap (Paste to Opus)

```md
You are integrating frontend WebSocket against backend **WS v3**.

Constraints:
- You cannot access my local absolute file paths.
- Work only with files visible in your current sandbox project.
- Do not ask for large full-file pastes unless strictly needed.

Global rules:
1. Target endpoint: `/ws-v3`
2. Protocol version: `v3`
3. Ignore legacy `/ws-v2` docs/behavior.
4. Treat this as incremental delivery: implement only the current phase request.
5. At the end of each phase, return:
   - changed files
   - what was implemented
   - what is still pending for next phase

Wait for my next message containing Phase 01 prompt.
```
