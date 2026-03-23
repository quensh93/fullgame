# Load + Chaos Runbook (v3)

## Goal
- Validate realtime SLO under stress and runtime resilience before production rollout.

## SLO Targets
- `p95 action latency < 150ms`
- `p99 action latency < 250ms`
- Target scale reference: `20k` CCU (progressive ramp, not one-shot jump)

## Load Smoke (k6)
1. Provide env:
   - `WS_URL`
   - `WS_TOKEN`
   - optional: `ROOM_ID`, `K6_VUS`, `K6_DURATION`, `ACTION_INTERVAL_MS`
2. Run:
   - `RUN_LOAD_CHAOS=true ./scripts/load_chaos_gate.sh`

## Local Bootstrap Load Smoke (no deployed env)
1. Preconditions:
   - `k6`, `jq`, `curl` installed
2. Run:
   - `RUN_LOAD_CHAOS=true RUN_LOCAL_LOAD_SMOKE=true ./scripts/load_chaos_gate.sh`
3. What it does:
   - boots backend locally with H2,
   - signs up a throwaway user,
   - extracts access token,
   - executes k6 smoke against `ws://127.0.0.1:8080/ws-v3`.

## Chaos Smoke
1. Provide env:
   - `KUBE_NAMESPACE`
   - `BACKEND_DEPLOYMENT`
   - `REDIS_STATEFULSET`
2. Run with load gate:
   - `RUN_LOAD_CHAOS=true RUN_CHAOS_SMOKE=true ./scripts/load_chaos_gate.sh`

## Required Production Stability Window
- After canary reaches 100%, observe `72h` stability with no critical incident.

## Notes
- `load_chaos_gate.sh` always validates artifacts and thresholds.
- Runtime execution is opt-in via env flags for CI/CD stages that have cluster access.
