#!/bin/bash
# The commit gate: scripts/lint.sh, the same checks CI runs before deploying.
#
# Installed by scripts/setup.sh as the pre-commit hook, as a COPY rather than
# via core.hooksPath (a hooks path inside the work tree would let whatever
# branch is checked out supply the hooks). Skip it once with
# `git commit --no-verify`; CI stays the backstop.
#
# It checks the WORKING TREE, not the staged index, so unstaged edits count.

ROOT="$(git rev-parse --show-toplevel)" || exit 1
cd "$ROOT" || exit 1

# git exports repository pointers (GIT_INDEX_FILE etc.) to hooks; lint.sh's own
# git calls must see the repository as a plain shell here would.
while IFS= read -r var; do
	unset "$var"
done < <(git rev-parse --local-env-vars)

echo "pre-commit: scripts/lint.sh (skip once with 'git commit --no-verify')"
# Quiet on success; the full report (Vale warnings included) on failure.
LOG="$(mktemp)" || exit 1
trap 'rm -f "$LOG"' EXIT
if ! scripts/lint.sh > "$LOG" 2>&1; then
	cat "$LOG"
	exit 1
fi
