#!/usr/bin/env bash
set -euo pipefail
# check-smart.sh — SMART health check for data disks
# Calls notify.sh on failure

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SMART_DEVICES="${SMART_DEVICES:-/dev/sdb /dev/sdc}"

FAILED=0
DETAILS=""

for DEV in ${SMART_DEVICES}; do
    if ! smartctl -H "${DEV}" 2>/dev/null | grep -q "PASSED"; then
        FAILED=1
        STATUS=$(smartctl -H "${DEV}" 2>&1 | grep -i "result" || echo "unknown")
        DETAILS="${DETAILS}${DEV}: ${STATUS}\n"
    fi
done

if [[ "${FAILED}" -eq 1 ]]; then
    "${SCRIPT_DIR}/notify.sh" crit "SMART Health Check Failed" "$(echo -e "${DETAILS}")"
    exit 1
fi
