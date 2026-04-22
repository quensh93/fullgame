#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEPLOY_CONFIG="${DEPLOY_CONFIG:-$ROOT_DIR/.deploy.env}"

if [[ -f "$DEPLOY_CONFIG" ]]; then
  # shellcheck disable=SC1090
  source "$DEPLOY_CONFIG"
fi

: "${DEPLOY_SSH_HOST:?Set DEPLOY_SSH_HOST in .deploy.env}"

DEPLOY_SSH_USER="${DEPLOY_SSH_USER:-root}"
DEPLOY_SSH_PORT="${DEPLOY_SSH_PORT:-22}"
DEPLOY_REMOTE_DIR="${DEPLOY_REMOTE_DIR:-/root/fullgame}"
DEPLOY_ENV_FILE="${DEPLOY_ENV_FILE:-.env.prod}"
DEPLOY_BUILD_BACKEND="${DEPLOY_BUILD_BACKEND:-true}"
DEPLOY_BUILD_FRONTEND="${DEPLOY_BUILD_FRONTEND:-true}"
DEPLOY_SSH_KEY_PATH="${DEPLOY_SSH_KEY_PATH:-$HOME/.ssh/id_ed25519}"
DEPLOY_SSH_PUBLIC_KEY_PATH="${DEPLOY_SSH_PUBLIC_KEY_PATH:-${DEPLOY_SSH_KEY_PATH}.pub}"
DEPLOY_SSH_ADD_TO_AGENT="${DEPLOY_SSH_ADD_TO_AGENT:-true}"
DEPLOY_BOOTSTRAP_SSH_KEY="${DEPLOY_BOOTSTRAP_SSH_KEY:-true}"
DEPLOY_SSH_CONTROL_PERSIST="${DEPLOY_SSH_CONTROL_PERSIST:-10m}"
DEPLOY_SSH_PASSWORD_FALLBACK="${DEPLOY_SSH_PASSWORD_FALLBACK:-true}"
DEPLOY_FORCE_PASSWORD_AUTH="${DEPLOY_FORCE_PASSWORD_AUTH:-false}"
DEPLOY_REMOTE_PULL_RETRIES="${DEPLOY_REMOTE_PULL_RETRIES:-4}"
DEPLOY_BACKEND_RUNTIME_BASE_IMAGE="${DEPLOY_BACKEND_RUNTIME_BASE_IMAGE:-docker.arvancloud.ir/eclipse-temurin:17-jre-jammy}"
DEPLOY_FRONTEND_RUNTIME_BASE_IMAGE="${DEPLOY_FRONTEND_RUNTIME_BASE_IMAGE:-docker.arvancloud.ir/nginx:1.27-alpine}"

SSH_TARGET="${DEPLOY_SSH_USER}@${DEPLOY_SSH_HOST}"
SANITIZED_HOST="${DEPLOY_SSH_HOST//[^[:alnum:]]/_}"
SANITIZED_USER="${DEPLOY_SSH_USER//[^[:alnum:]]/_}"
SSH_CONTROL_PATH="${TMPDIR:-/tmp}/deploy-${SANITIZED_USER}-${SANITIZED_HOST}-${DEPLOY_SSH_PORT}.sock"
SSH_BASE_OPTS=(
  -p "$DEPLOY_SSH_PORT"
  -o ControlMaster=auto
  -o ControlPersist="$DEPLOY_SSH_CONTROL_PERSIST"
  -o ControlPath="$SSH_CONTROL_PATH"
  -o ServerAliveInterval=30
  -o ServerAliveCountMax=3
)
SSH_KEY_OPTS=()
SSH_USE_PASSWORD_AUTH=false

if [[ "$DEPLOY_FORCE_PASSWORD_AUTH" == "true" ]]; then
  SSH_USE_PASSWORD_AUTH=true
fi

if [[ "$SSH_USE_PASSWORD_AUTH" != "true" && -f "$DEPLOY_SSH_KEY_PATH" ]]; then
  SSH_KEY_OPTS=(-i "$DEPLOY_SSH_KEY_PATH" -o IdentitiesOnly=yes)
fi

COMPOSE_CMD="docker compose --env-file ${DEPLOY_ENV_FILE} -f docker-compose.prod.yml"
STARTED_TEMP_SSH_AGENT=false
RSYNC_RSH=""

refresh_ssh_client() {
  SSH_OPTS=("${SSH_BASE_OPTS[@]}")

  if [[ "$SSH_USE_PASSWORD_AUTH" == "true" ]]; then
    SSH_OPTS+=(-o PreferredAuthentications=password -o PubkeyAuthentication=no)
  elif [[ "${#SSH_KEY_OPTS[@]}" -gt 0 ]]; then
    SSH_OPTS+=("${SSH_KEY_OPTS[@]}")
  fi

  SSH_CMD=(ssh "${SSH_OPTS[@]}")
}

refresh_ssh_client

log() {
  printf '\n[%s] %s\n' "$(date '+%H:%M:%S')" "$1"
}

quote_cmd() {
  printf '%q ' "$@"
}

run_ssh() {
  "${SSH_CMD[@]}" "$SSH_TARGET" "$1"
}

cleanup() {
  if [[ -S "$SSH_CONTROL_PATH" ]]; then
    ssh "${SSH_OPTS[@]}" -O exit "$SSH_TARGET" >/dev/null 2>&1 || true
  fi

  if [[ "$STARTED_TEMP_SSH_AGENT" == "true" && -n "${SSH_AGENT_PID:-}" ]]; then
    ssh-agent -k >/dev/null 2>&1 || true
  fi
}

trap cleanup EXIT

ensure_agent_socket() {
  local agent_status

  set +e
  ssh-add -l >/dev/null 2>&1
  agent_status=$?
  set -e

  if [[ "$agent_status" -eq 2 ]]; then
    log "Starting temporary ssh-agent for this deploy"
    # shellcheck disable=SC2046
    eval "$(ssh-agent -s)" >/dev/null
    STARTED_TEMP_SSH_AGENT=true
  fi
}

ensure_ssh_key_loaded() {
  local public_key

  if [[ "$SSH_USE_PASSWORD_AUTH" == "true" ]]; then
    return 0
  fi

  if [[ "$DEPLOY_SSH_ADD_TO_AGENT" != "true" ]]; then
    return 0
  fi

  if [[ ! -f "$DEPLOY_SSH_KEY_PATH" ]]; then
    log "Deploy SSH key not found at $DEPLOY_SSH_KEY_PATH; continuing without agent preload"
    return 0
  fi

  ensure_agent_socket

  if [[ ! -f "$DEPLOY_SSH_PUBLIC_KEY_PATH" ]]; then
    log "Deploy SSH public key not found at $DEPLOY_SSH_PUBLIC_KEY_PATH; continuing without remote key bootstrap"
    return 0
  fi

  public_key="$(<"$DEPLOY_SSH_PUBLIC_KEY_PATH")"
  if ssh-add -L 2>/dev/null | grep -Fqx "$public_key"; then
    return 0
  fi

  log "Loading deploy key into ssh-agent (passphrase may be requested once)"
  if [[ "$(uname -s)" == "Darwin" ]]; then
    if ssh-add --apple-use-keychain "$DEPLOY_SSH_KEY_PATH" 2>/dev/null || ssh-add "$DEPLOY_SSH_KEY_PATH"; then
      return 0
    fi
  else
    if ssh-add "$DEPLOY_SSH_KEY_PATH"; then
      return 0
    fi
  fi

  if [[ "$DEPLOY_SSH_PASSWORD_FALLBACK" == "true" ]]; then
    log "Could not unlock deploy key; falling back to one server password prompt for this deploy"
    SSH_USE_PASSWORD_AUTH=true
    refresh_ssh_client
    return 0
  fi

  return 1
}

has_key_only_access() {
  if [[ "${#SSH_KEY_OPTS[@]}" -eq 0 ]]; then
    return 1
  fi

  set +e
  ssh \
    "${SSH_BASE_OPTS[@]}" \
    "${SSH_KEY_OPTS[@]}" \
    -o BatchMode=yes \
    -o PreferredAuthentications=publickey \
    -o PasswordAuthentication=no \
    "$SSH_TARGET" "true" >/dev/null 2>&1
  local status=$?
  set -e

  return "$status"
}

ensure_remote_key_auth() {
  local public_key

  if [[ "$DEPLOY_BOOTSTRAP_SSH_KEY" != "true" ]]; then
    return 0
  fi

  if [[ ! -f "$DEPLOY_SSH_PUBLIC_KEY_PATH" ]]; then
    return 0
  fi

  if has_key_only_access; then
    return 0
  fi

  public_key="$(<"$DEPLOY_SSH_PUBLIC_KEY_PATH")"
  log "Fixing public-key login on the server (server password may be requested once)"
  run_ssh "umask 077 && mkdir -p ~/.ssh && touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && (grep -qxF '$public_key' ~/.ssh/authorized_keys || printf '%s\n' '$public_key' >> ~/.ssh/authorized_keys)"

  if has_key_only_access; then
    log "SSH key login is fixed for future deploys"
  else
    log "SSH key login is still unavailable; continuing with the current authenticated session"
  fi
}

open_control_master() {
  if ssh "${SSH_OPTS[@]}" -O check "$SSH_TARGET" >/dev/null 2>&1; then
    return 0
  fi

  log "Opening reusable SSH connection"
  ssh "${SSH_OPTS[@]}" -MNf "$SSH_TARGET"
}

build_backend() {
  log "Building backend jar locally"
  cd "$ROOT_DIR/gameBackend"
  ./gradlew --no-daemon bootJar -x test
  cp -f build/libs/*.jar app.jar
  ls -lh app.jar
}

build_frontend() {
  log "Building frontend dist locally"
  cd "$ROOT_DIR/gameweb"
  if [[ ! -d node_modules ]]; then
    npm ci
  fi
  npm run build
}

prepull_remote_base_images() {
  log "Ensuring runtime base images are available on the server"
  run_ssh "set -e
retry_pull() {
  image=\"\$1\"
  attempts=\"$DEPLOY_REMOTE_PULL_RETRIES\"
  attempt=1

  if docker image inspect \"\$image\" >/dev/null 2>&1; then
    echo \"Using cached base image \$image\"
    return 0
  fi

  while true; do
    echo \"Pulling \$image (attempt \$attempt/\$attempts)\"
    if docker pull \"\$image\"; then
      return 0
    fi

    if [ \"\$attempt\" -ge \"\$attempts\" ]; then
      echo \"Failed to pull \$image after \$attempts attempts\" >&2
      return 1
    fi

    sleep \$((attempt * 5))
    attempt=\$((attempt + 1))
  done
}
retry_pull '$DEPLOY_BACKEND_RUNTIME_BASE_IMAGE'
retry_pull '$DEPLOY_FRONTEND_RUNTIME_BASE_IMAGE'"
}

prepare_remote() {
  log "Preparing remote directories"
  run_ssh "mkdir -p '$DEPLOY_REMOTE_DIR/gameBackend' '$DEPLOY_REMOTE_DIR/gameweb/dist'"
}

sync_files() {
  log "Syncing deploy files to server"
  RSYNC_RSH="$(quote_cmd ssh "${SSH_OPTS[@]}")"

  rsync -az -e "$RSYNC_RSH" \
    "$ROOT_DIR/docker-compose.prod.yml" \
    "$SSH_TARGET:$DEPLOY_REMOTE_DIR/"

  rsync -az -e "$RSYNC_RSH" \
    "$ROOT_DIR/gameBackend/Dockerfile.runtime" \
    "$ROOT_DIR/gameBackend/.dockerignore" \
    "$ROOT_DIR/gameBackend/app.jar" \
    "$SSH_TARGET:$DEPLOY_REMOTE_DIR/gameBackend/"

  rsync -az -e "$RSYNC_RSH" \
    "$ROOT_DIR/gameweb/Dockerfile.runtime" \
    "$ROOT_DIR/gameweb/.dockerignore" \
    "$ROOT_DIR/gameweb/nginx.conf" \
    "$SSH_TARGET:$DEPLOY_REMOTE_DIR/gameweb/"

  rsync -az --delete -e "$RSYNC_RSH" \
    "$ROOT_DIR/gameweb/dist/" \
    "$SSH_TARGET:$DEPLOY_REMOTE_DIR/gameweb/dist/"
}

deploy_remote() {
  log "Rebuilding and starting containers on server"
  run_ssh "cd '$DEPLOY_REMOTE_DIR' && BACKEND_RUNTIME_BASE_IMAGE='$DEPLOY_BACKEND_RUNTIME_BASE_IMAGE' FRONTEND_RUNTIME_BASE_IMAGE='$DEPLOY_FRONTEND_RUNTIME_BASE_IMAGE' DOCKER_BUILDKIT=0 COMPOSE_DOCKER_CLI_BUILD=0 $COMPOSE_CMD build backend frontend && BACKEND_RUNTIME_BASE_IMAGE='$DEPLOY_BACKEND_RUNTIME_BASE_IMAGE' FRONTEND_RUNTIME_BASE_IMAGE='$DEPLOY_FRONTEND_RUNTIME_BASE_IMAGE' $COMPOSE_CMD up -d --no-build"
}

show_status() {
  log "Remote container status"
  run_ssh "cd '$DEPLOY_REMOTE_DIR' && $COMPOSE_CMD ps"
}

main() {
  if [[ "$DEPLOY_BUILD_BACKEND" == "true" ]]; then
    build_backend
  fi

  if [[ "$DEPLOY_BUILD_FRONTEND" == "true" ]]; then
    build_frontend
  fi

  ensure_ssh_key_loaded
  open_control_master
  ensure_remote_key_auth
  prepare_remote
  sync_files
  prepull_remote_base_images
  deploy_remote
  show_status
}

main "$@"
