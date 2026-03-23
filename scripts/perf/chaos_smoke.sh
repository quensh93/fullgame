#!/usr/bin/env bash
set -euo pipefail

KUBE_NAMESPACE="${KUBE_NAMESPACE:-default}"
BACKEND_DEPLOYMENT="${BACKEND_DEPLOYMENT:-game-backend}"
REDIS_STATEFULSET="${REDIS_STATEFULSET:-redis}"
INCLUDE_REDIS_FAILOVER="${INCLUDE_REDIS_FAILOVER:-true}"

fail() {
  echo "[chaos-smoke] FAIL: $1" >&2
  exit 1
}

command -v kubectl >/dev/null 2>&1 || fail "kubectl is required"
kubectl cluster-info >/dev/null 2>&1 || fail "kubectl cannot reach a Kubernetes cluster (check KUBECONFIG/context)"

echo "[chaos-smoke] Restarting backend deployment: ${BACKEND_DEPLOYMENT} (ns=${KUBE_NAMESPACE})"
kubectl -n "$KUBE_NAMESPACE" rollout restart "deployment/${BACKEND_DEPLOYMENT}"
kubectl -n "$KUBE_NAMESPACE" rollout status "deployment/${BACKEND_DEPLOYMENT}" --timeout=240s
kubectl -n "$KUBE_NAMESPACE" wait --for=condition=available --timeout=240s "deployment/${BACKEND_DEPLOYMENT}"

if [[ "$INCLUDE_REDIS_FAILOVER" == "true" ]]; then
  echo "[chaos-smoke] Restarting redis statefulset: ${REDIS_STATEFULSET} (ns=${KUBE_NAMESPACE})"
  kubectl -n "$KUBE_NAMESPACE" rollout restart "statefulset/${REDIS_STATEFULSET}"
  kubectl -n "$KUBE_NAMESPACE" rollout status "statefulset/${REDIS_STATEFULSET}" --timeout=300s
  kubectl -n "$KUBE_NAMESPACE" wait --for=condition=ready --timeout=300s "pod/${REDIS_STATEFULSET}-0"
fi

echo "[chaos-smoke] PASS"
