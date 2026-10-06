#!/bin/bash
# One-time (idempotent) setup for a fresh clone: installs the pre-commit hook
# and downloads Vale's style packages. Safe to re-run; rerun it after
# scripts/hooks/pre-commit.sh changes, since the hook is installed as a copy.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

# --git-path honours core.hooksPath, so this lands wherever git looks for hooks.
HOOKS_DIR="$(git rev-parse --git-path hooks)"
TARGET="$HOOKS_DIR/pre-commit"
SOURCE=scripts/hooks/pre-commit.sh
MARKER='# The commit gate: scripts/lint.sh'

mkdir -p "$HOOKS_DIR"
if [[ -e "$TARGET" ]] && ! grep -qF "$MARKER" "$TARGET"; then
	echo "setup: $TARGET exists and isn't ours; leaving it alone." >&2
	echo "       Remove it and rerun, or call $SOURCE from it." >&2
	exit 1
fi
if cmp -s "$SOURCE" "$TARGET"; then
	echo "setup: pre-commit hook already up to date"
else
	install -m 755 "$SOURCE" "$TARGET"
	echo "setup: installed pre-commit hook -> $TARGET"
fi

vale sync
