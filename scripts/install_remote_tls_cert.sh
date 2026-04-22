#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEPLOY_CONFIG="${DEPLOY_CONFIG:-$ROOT_DIR/.deploy.env}"

if [[ -f "$DEPLOY_CONFIG" ]]; then
  # shellcheck disable=SC1090
  source "$DEPLOY_CONFIG"
fi

usage() {
  cat <<'EOF'
Usage:
  ./scripts/install_remote_tls_cert.sh <domain> <local-fullchain.pem> <local-privkey.pem>

Environment overrides:
  DEPLOY_SSH_HOST       Required if not set in .deploy.env
  DEPLOY_SSH_USER       Defaults to root
  DEPLOY_SSH_PORT       Defaults to 22
  DEPLOY_SSH_KEY_PATH   Optional ssh private key path
  REMOTE_CERT_BASE_DIR  Defaults to /etc/ssl

Example:
  ./scripts/install_remote_tls_cert.sh \
    game.jarvislabs.ir \
    /tmp/game-fullchain.pem \
    /tmp/game-privkey.pem
EOF
}

if [[ $# -ne 3 ]]; then
  usage >&2
  exit 1
fi

: "${DEPLOY_SSH_HOST:?Set DEPLOY_SSH_HOST in .deploy.env or env}"

DOMAIN="$1"
LOCAL_FULLCHAIN="$2"
LOCAL_PRIVKEY="$3"

DEPLOY_SSH_USER="${DEPLOY_SSH_USER:-root}"
DEPLOY_SSH_PORT="${DEPLOY_SSH_PORT:-22}"
DEPLOY_SSH_KEY_PATH="${DEPLOY_SSH_KEY_PATH:-}"
REMOTE_CERT_BASE_DIR="${REMOTE_CERT_BASE_DIR:-/etc/ssl}"
REMOTE_CERT_DIR="${REMOTE_CERT_BASE_DIR%/}/$DOMAIN"
REMOTE_TMP_DIR="/root/${DOMAIN}.cert-upload"
REMOTE_SITE_PATH="/etc/nginx/sites-enabled/$DOMAIN"
SSH_TARGET="${DEPLOY_SSH_USER}@${DEPLOY_SSH_HOST}"

if [[ ! -f "$LOCAL_FULLCHAIN" ]]; then
  echo "Local fullchain not found: $LOCAL_FULLCHAIN" >&2
  exit 1
fi

if [[ ! -f "$LOCAL_PRIVKEY" ]]; then
  echo "Local private key not found: $LOCAL_PRIVKEY" >&2
  exit 1
fi

SSH_OPTS=(
  -p "$DEPLOY_SSH_PORT"
  -o ServerAliveInterval=30
  -o ServerAliveCountMax=3
)

if [[ -n "$DEPLOY_SSH_KEY_PATH" ]]; then
  SSH_OPTS+=(-i "$DEPLOY_SSH_KEY_PATH" -o IdentitiesOnly=yes)
fi

SSH_CMD=(ssh "${SSH_OPTS[@]}")
SCP_CMD=(scp "${SSH_OPTS[@]}")

echo "[1/4] Preparing remote upload directory"
"${SSH_CMD[@]}" "$SSH_TARGET" "mkdir -p '$REMOTE_TMP_DIR' && chmod 700 '$REMOTE_TMP_DIR'"

echo "[2/4] Uploading certificate files"
"${SCP_CMD[@]}" "$LOCAL_FULLCHAIN" "$SSH_TARGET:$REMOTE_TMP_DIR/fullchain.pem"
"${SCP_CMD[@]}" "$LOCAL_PRIVKEY" "$SSH_TARGET:$REMOTE_TMP_DIR/privkey.pem"

echo "[3/4] Installing certificate on remote host"
"${SSH_CMD[@]}" "$SSH_TARGET" "set -e
mkdir -p '$REMOTE_CERT_DIR'
install -m 644 '$REMOTE_TMP_DIR/fullchain.pem' '$REMOTE_CERT_DIR/fullchain.pem'
install -m 600 '$REMOTE_TMP_DIR/privkey.pem' '$REMOTE_CERT_DIR/privkey.pem'
rm -rf '$REMOTE_TMP_DIR'

if test -f '$REMOTE_SITE_PATH'; then
  grep -q '$REMOTE_CERT_DIR/fullchain.pem' '$REMOTE_SITE_PATH' || {
    echo 'Nginx site does not reference expected fullchain path: $REMOTE_CERT_DIR/fullchain.pem' >&2
    exit 1
  }
  grep -q '$REMOTE_CERT_DIR/privkey.pem' '$REMOTE_SITE_PATH' || {
    echo 'Nginx site does not reference expected private key path: $REMOTE_CERT_DIR/privkey.pem' >&2
    exit 1
  }
fi

nginx -t
systemctl reload nginx"

echo "[4/4] Verifying live certificate on remote host"
"${SSH_CMD[@]}" "$SSH_TARGET" "echo | openssl s_client -servername '$DOMAIN' -connect 127.0.0.1:443 2>/dev/null | openssl x509 -noout -subject -issuer -dates"

echo "Installed and reloaded TLS certificate for $DOMAIN"
