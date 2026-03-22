#!/usr/bin/env bash
set -euo pipefail
# check-raid.sh — mdadm RAID health check
# Calls notify.sh if RAID is degraded

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

MDSTAT=$(cat /proc/mdstat 2>/dev/null || echo "")

if [[ -z "${MDSTAT}" ]]; then
    "${SCRIPT_DIR}/notify.sh" warn "RAID Check" "Cannot read /proc/mdstat"
    exit 1
fi

if ! echo "${MDSTAT}" | grep -q "\[UU\]"; then
    "${SCRIPT_DIR}/notify.sh" crit "RAID Degraded" "${MDSTAT}"
    exit 1
fi
