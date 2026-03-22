#!/usr/bin/env bash
set -euo pipefail
# check-disk.sh — Disk space usage check
# Calls notify.sh if usage exceeds threshold

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THRESHOLD="${DISK_THRESHOLD:-85}"
MOUNT_POINTS="${MOUNT_POINTS:-/ /data}"

FAILED=0
DETAILS=""

for MP in ${MOUNT_POINTS}; do
    if [[ ! -d "${MP}" ]]; then
        continue
    fi
    USAGE=$(df "${MP}" --output=pcent | tail -1 | tr -d '[:space:]%')
    if [[ "${USAGE}" -ge "${THRESHOLD}" ]]; then
        FAILED=1
        DETAILS="${DETAILS}${MP}: ${USAGE}% (threshold: ${THRESHOLD}%)\n"
    fi
done

if [[ "${FAILED}" -eq 1 ]]; then
    "${SCRIPT_DIR}/notify.sh" warn "Disk Space Warning" "$(echo -e "${DETAILS}")"
    exit 1
fi
