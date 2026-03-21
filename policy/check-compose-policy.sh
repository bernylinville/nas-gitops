#!/usr/bin/env bash
# check-compose-policy.sh — Validate Docker Compose files against nas-gitops policies
# Checks: no latest tag, healthcheck required, restart required, no 0.0.0.0 binding
set -euo pipefail

ERRORS=0
COMPOSE_FILES=$(find compose/ -name "docker-compose.yml" -o -name "compose.yml" 2>/dev/null)

if [ -z "$COMPOSE_FILES" ]; then
  echo "INFO: No compose files found, skipping policy checks."
  exit 0
fi

for f in $COMPOSE_FILES; do
  echo "=== Checking: $f ==="

  # Check 1: No 'latest' tag
  if grep -Pn ':\s*latest\s*$' "$f" 2>/dev/null || grep -Pn "image:.*:latest" "$f" 2>/dev/null; then
    echo "ERROR: [no-latest-tag] Found 'latest' tag in $f"
    ERRORS=$((ERRORS + 1))
  fi

  # Check 2: No 0.0.0.0 binding
  if grep -n '0\.0\.0\.0' "$f" 2>/dev/null; then
    echo "ERROR: [no-public-bind] Found 0.0.0.0 binding in $f"
    ERRORS=$((ERRORS + 1))
  fi

  # Check 3: Unqualified port mapping (e.g., "8080:8080" without host IP)
  if grep -Pn '^\s*-\s*"\d+:\d+"' "$f" 2>/dev/null; then
    echo "WARNING: [unqualified-port] Found port mapping without host IP binding in $f (Docker defaults to 0.0.0.0)"
    ERRORS=$((ERRORS + 1))
  fi

  # Check 4: healthcheck required (per service)
  # Simple check: file should contain 'healthcheck' if it contains 'services'
  if grep -q 'services:' "$f" && ! grep -q 'healthcheck:' "$f"; then
    echo "WARNING: [require-healthcheck] No healthcheck found in $f"
    ERRORS=$((ERRORS + 1))
  fi

  # Check 5: restart policy required
  if grep -q 'services:' "$f" && ! grep -q 'restart:' "$f"; then
    echo "WARNING: [require-restart] No restart policy found in $f"
    ERRORS=$((ERRORS + 1))
  fi

  echo ""
done

if [ "$ERRORS" -gt 0 ]; then
  echo "FAILED: $ERRORS policy violation(s) found."
  exit 1
else
  echo "PASSED: All compose policy checks passed."
  exit 0
fi
