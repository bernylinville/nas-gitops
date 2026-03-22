#!/usr/bin/env bash
set -euo pipefail
# check-backup.sh — Restic backup freshness check
# Calls notify.sh if latest snapshot is older than MAX_AGE_HOURS

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="/etc/restic/env"
MAX_AGE_HOURS="${MAX_AGE_HOURS:-25}"

if [[ -f "${ENV_FILE}" ]]; then
    # shellcheck source=/dev/null
    source "${ENV_FILE}"
fi

if [[ -z "${RESTIC_REPOSITORY:-}" || -z "${RESTIC_PASSWORD:-}" ]]; then
    "${SCRIPT_DIR}/notify.sh" warn "Backup Check" "Restic not configured"
    exit 1
fi

# Get latest snapshot time
LATEST=$(restic snapshots --latest 1 --json 2>/dev/null | \
    python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0]['time'][:19] if d else '')" 2>/dev/null || echo "")

if [[ -z "${LATEST}" ]]; then
    "${SCRIPT_DIR}/notify.sh" crit "Backup Missing" "No restic snapshots found"
    exit 1
fi

# Calculate age in hours
LATEST_EPOCH=$(date -d "${LATEST}" +%s 2>/dev/null || date -jf "%Y-%m-%dT%H:%M:%S" "${LATEST}" +%s 2>/dev/null || echo "0")
NOW_EPOCH=$(date +%s)
AGE_HOURS=$(( (NOW_EPOCH - LATEST_EPOCH) / 3600 ))

if [[ "${AGE_HOURS}" -ge "${MAX_AGE_HOURS}" ]]; then
    "${SCRIPT_DIR}/notify.sh" crit "Backup Stale" "Latest backup is ${AGE_HOURS}h old (max: ${MAX_AGE_HOURS}h)\nLast: ${LATEST}"
    exit 1
fi
