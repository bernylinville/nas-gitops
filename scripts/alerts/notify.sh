#!/usr/bin/env bash
set -euo pipefail
# notify.sh — Unified notification framework
# Usage: notify.sh <severity> <subject> <body>
#   severity: info | warn | crit
#
# Environment (from /etc/nas-gitops/notify.env):
#   TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="/etc/nas-gitops/notify.env"

# Load environment
if [[ -f "${ENV_FILE}" ]]; then
    # shellcheck source=/dev/null
    source "${ENV_FILE}"
fi

# Arguments
SEVERITY="${1:-info}"
SUBJECT="${2:-No Subject}"
BODY="${3:-No Body}"
DRY_RUN="${DRY_RUN:-false}"

# Validate
if [[ -z "${TELEGRAM_BOT_TOKEN:-}" || -z "${TELEGRAM_CHAT_ID:-}" ]]; then
    echo "[ERROR] TELEGRAM_BOT_TOKEN or TELEGRAM_CHAT_ID not set" >&2
    exit 1
fi

# Emoji by severity
case "${SEVERITY}" in
    info) EMOJI="ℹ️" ;;
    warn) EMOJI="⚠️" ;;
    crit) EMOJI="🚨" ;;
    *)    EMOJI="📌" ;;
esac

# Format message
HOSTNAME="$(hostname)"
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"
MESSAGE="${EMOJI} *${SUBJECT}*
Host: \`${HOSTNAME}\`
Time: \`${TIMESTAMP}\`
Severity: \`${SEVERITY}\`

${BODY}"

# Send
if [[ "${DRY_RUN}" == "true" ]]; then
    echo "[DRY-RUN] Would send to Telegram:"
    echo "${MESSAGE}"
    exit 0
fi

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d "chat_id=${TELEGRAM_CHAT_ID}" \
    -d "text=${MESSAGE}" \
    -d "parse_mode=Markdown" \
    -d "disable_web_page_preview=true")

if [[ "${HTTP_CODE}" -ne 200 ]]; then
    echo "[ERROR] Telegram API returned HTTP ${HTTP_CODE}" >&2
    exit 1
fi
