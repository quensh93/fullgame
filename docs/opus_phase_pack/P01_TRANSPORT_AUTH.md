# P01 - Transport + Auth Bootstrap (Paste to Opus)

```md
Phase 01 only: implement WS v3 transport/bootstrap foundation.

Requirements:
1. Connect to `/ws-v3`.
2. Enforce outgoing base envelope:
   - required: `type`, `protocolVersion`, `traceId`
   - common optional: `roomId`, `action`, `data`, `clientActionId`, `clientSentAt`, `stateVersion`
3. Implement AUTH bootstrap:
   - send `AUTH` with: `token`, `protocolVersion`, `appVersion`, `capabilities`
   - include `deviceId` when available
4. Handle `AUTH_SUCCESS`.
5. Immediately send `CLIENT_TELEMETRY` after `AUTH_SUCCESS`.
6. Handle `CLIENT_TELEMETRY_ACK`.
7. Implement `HEARTBEAT` send path (timer-based keepalive).
8. Add reconnect strategy with safe listener cleanup.

Signals to support in this phase:
- `AUTH_SUCCESS`
- `CLIENT_TELEMETRY_ACK`
- `ERROR`

Done criteria:
- one central socket manager exists
- successful connect -> AUTH -> AUTH_SUCCESS -> CLIENT_TELEMETRY flow
- no duplicate listeners after reconnect

Output format:
1. changed files
2. exact bootstrap flow implemented
3. risks left for next phase
```
