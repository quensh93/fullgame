# Canary Rollout Runbook (Backend + Flutter)

## Scope
- WebSocket protocol `v3`
- Runtime auth/session checks (`deviceId`, revoke, sessionVersion)
- Redis-backed realtime dependencies

## Progressive Rollout
1. `5%` traffic:
   - Target app versions already supporting `v3` contract.
   - Monitor `ws_auth_fail`, `action_latency_ms`, `state_resync_required`, `ws_rate_limited`.
2. `25%` traffic:
   - Expand only if no critical incident and SLO remains healthy.
3. `50%` traffic:
   - Validate long-session behavior and reconnect storms.
4. `100%` traffic:
   - Complete rollout only after stability window passes.

## Release Gates
- `./scripts/release_gate.sh` must be green.
- Contract checks must pass for BE + FE.
- Critical WS scenario suites must pass for BE + FE.

## Rollback
- Backend:
  - Disable new behavior with feature flags.
- Frontend:
  - Activate realtime kill-switch:
    - `WS_REALTIME_ENABLED=false`
    - `WS_REALTIME_DISABLED_REASON="Realtime degraded. Please retry shortly."`

## Stability Window
- Require at least `72h` production stability with:
  - no critical incident,
  - `p95 action latency < 150ms`,
  - `p99 action latency < 250ms`,
  - no sustained reconnect/resync spikes.
