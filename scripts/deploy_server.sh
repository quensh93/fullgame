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

SSH_TARGET="${DEPLOY_SSH_USER}@${DEPLOY_SSH_HOST}"
SSH_CMD=(ssh -p "$DEPLOY_SSH_PORT")
RSYNC_RSH="ssh -p $DEPLOY_SSH_PORT"
COMPOSE_CMD="docker compose --env-file ${DEPLOY_ENV_FILE} -f docker-compose.prod.yml"

log() {
  printf '\n[%s] %s\n' "$(date '+%H:%M:%S')" "$1"
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

prepare_remote() {
  log "Preparing remote directories"
  "${SSH_CMD[@]}" "$SSH_TARGET" "mkdir -p '$DEPLOY_REMOTE_DIR/gameBackend' '$DEPLOY_REMOTE_DIR/gameweb/dist'"
}

sync_files() {
  log "Syncing deploy files to server"
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
  "${SSH_CMD[@]}" "$SSH_TARGET" "cd '$DEPLOY_REMOTE_DIR' && $COMPOSE_CMD up -d --build"
}

show_status() {
  log "Remote container status"
  "${SSH_CMD[@]}" "$SSH_TARGET" "cd '$DEPLOY_REMOTE_DIR' && $COMPOSE_CMD ps"
}

main() {
  if [[ "$DEPLOY_BUILD_BACKEND" == "true" ]]; then
    build_backend
  fi

  if [[ "$DEPLOY_BUILD_FRONTEND" == "true" ]]; then
    build_frontend
  fi

  prepare_remote
  sync_files
  deploy_remote
  show_status
}

main "$@"
