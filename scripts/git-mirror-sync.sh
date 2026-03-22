#!/usr/bin/env bash
# scripts/git-mirror-sync.sh — Sync git mirror repositories
# Called by systemd timer: git-mirror.timer
# Config: /etc/git-mirror/repos.conf (one repo URL per line)
set -euo pipefail

MIRROR_DIR="${GIT_MIRROR_DIR:-/data/git-mirrors}"
REPOS_CONF="${GIT_MIRROR_CONF:-/etc/git-mirror/repos.conf}"
LOG_TAG="git-mirror"

log() { logger -t "$LOG_TAG" "$*"; echo "[$(date '+%F %T')] $*"; }

if [ ! -f "$REPOS_CONF" ]; then
    log "ERROR: repos config not found: $REPOS_CONF"
    exit 1
fi

mkdir -p "$MIRROR_DIR"

FAIL_COUNT=0
TOTAL=0

while IFS= read -r repo_url || [ -n "$repo_url" ]; do
    # Skip comments and empty lines
    [[ "$repo_url" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${repo_url// /}" ]] && continue

    TOTAL=$((TOTAL + 1))
    repo_name=$(basename "$repo_url" .git)
    mirror_path="$MIRROR_DIR/$repo_name.git"

    if [ -d "$mirror_path" ]; then
        log "Updating mirror: $repo_name"
        if ! git -C "$mirror_path" remote update --prune 2>&1 | logger -t "$LOG_TAG"; then
            log "ERROR: Failed to update $repo_name"
            FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
    else
        log "Cloning mirror: $repo_name"
        if ! git clone --mirror "$repo_url" "$mirror_path" 2>&1 | logger -t "$LOG_TAG"; then
            log "ERROR: Failed to clone $repo_name"
            FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
    fi
done < "$REPOS_CONF"

if [ "$FAIL_COUNT" -gt 0 ]; then
    log "WARN: $FAIL_COUNT/$TOTAL mirrors failed"
    exit 1
fi

log "OK: $TOTAL mirrors synced successfully"
exit 0
