#!/usr/bin/env bash
# scripts/tag-deploy.sh — Create and push a deploy tag after successful deployment
# Usage: ./scripts/tag-deploy.sh [--push]
#
# Creates a git tag in format: deploy-YYYYMMDD-HHMM
# With --push flag, also pushes the tag to origin
set -euo pipefail

# --- Configuration ---
TAG_PREFIX="deploy"
DATE_FORMAT="+%Y%m%d-%H%M"

# --- Parse arguments ---
PUSH=false
for arg in "$@"; do
    case "$arg" in
        --push) PUSH=true ;;
        --help|-h)
            echo "Usage: $0 [--push]"
            echo ""
            echo "Creates a deploy tag (deploy-YYYYMMDD-HHMM) on the current commit."
            echo ""
            echo "Options:"
            echo "  --push    Push the tag to origin after creation"
            echo "  --help    Show this help message"
            exit 0
            ;;
        *)
            echo "Error: Unknown argument: $arg" >&2
            exit 2
            ;;
    esac
done

# --- Checks ---
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Error: Not inside a git repository" >&2
    exit 1
fi

# Ensure working directory is clean
if ! git diff --quiet HEAD 2>/dev/null; then
    echo "Error: Working directory has uncommitted changes. Commit or stash first." >&2
    exit 1
fi

# --- Create tag ---
TAG_NAME="${TAG_PREFIX}-$(date "$DATE_FORMAT")"
COMMIT_SHA=$(git rev-parse --short HEAD)

echo "Creating tag: ${TAG_NAME} (commit: ${COMMIT_SHA})"
git tag -a "${TAG_NAME}" -m "Deploy ${TAG_NAME} (${COMMIT_SHA})"

if [ "$PUSH" = true ]; then
    echo "Pushing tag to origin..."
    git push origin "${TAG_NAME}"
    echo "Done: ${TAG_NAME} pushed to origin"
else
    echo "Done: ${TAG_NAME} created locally"
    echo "Run 'git push origin ${TAG_NAME}' to push, or re-run with --push"
fi
