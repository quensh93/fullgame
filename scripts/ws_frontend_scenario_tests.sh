#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FRONTEND_DIR="$ROOT_DIR/gameapp"

echo "[ws-frontend-scenarios] Running frontend websocket contract tests..."
(
  cd "$FRONTEND_DIR"
  flutter test test/core/services/websocket_manager_contract_test.dart
)

echo "[ws-frontend-scenarios] PASS"
