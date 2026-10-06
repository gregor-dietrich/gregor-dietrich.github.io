#!/bin/bash
# The quality gate: run by CI (.github/workflows/hugo.yml) before every deploy,
# and locally by the pre-commit hook (scripts/hooks/pre-commit.sh). Runs every
# check even after one fails, so a single run shows everything that's wrong.
set -uo pipefail

cd "$(git rev-parse --show-toplevel)" || exit 1

missing=()
for tool in hugo markdownlint-cli2 typos vale actionlint shellcheck lychee; do
	command -v "$tool" > /dev/null || missing+=("$tool")
done
if [[ ${#missing[@]} -gt 0 ]]; then
	echo "lint: missing tools: ${missing[*]} (see README.md, Setup)" >&2
	exit 1
fi

# Vale's style packages are downloaded, not committed.
if [[ ! -d .vale/styles/proselint || ! -d .vale/styles/write-good ]]; then
	vale sync > /dev/null || exit 1
fi

failed=()
run() {
	echo "==> $*"
	"$@" || failed+=("$1")
}

run markdownlint-cli2
run typos
run vale content README.md
run actionlint
run shellcheck scripts/*.sh scripts/hooks/*.sh
run scripts/check-site.sh

if [[ ${#failed[@]} -gt 0 ]]; then
	echo "lint: FAILED: ${failed[*]}" >&2
	exit 1
fi
echo "lint: all checks passed"
