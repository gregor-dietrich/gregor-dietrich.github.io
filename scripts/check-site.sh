#!/bin/bash
# Builds the site strictly and checks its links. Run by scripts/lint.sh
# (internal links only) and .github/workflows/links.yml (--external).
#
# Usage: scripts/check-site.sh [--external] [LYCHEE_ARGS...]
#
# Hugo's --panicOnWarning can't be used yet: PaperMod still calls two APIs
# deprecated in Hugo 0.158 (adityatelange/hugo-PaperMod#1856), and Hugo can't
# silence a theme's warnings selectively. So this fails on any WARN or ERROR line
# EXCEPT those two exact deprecations. Drop KNOWN_WARNINGS once the theme is fixed.
set -euo pipefail

KNOWN_WARNINGS='^WARN  deprecated: \.Language\.Language(Direction|Code) was deprecated in Hugo v0\.158\.0'

# A placeholder host, remapped to the build directory below, so links resolve
# locally. Not baseURL "/": PaperMod's breadcrumb JSON-LD is invalid with it,
# and --minify rejects every post page.
BASE=https://blog.invalid/

offline=(--offline)
if [[ "${1:-}" == --external ]]; then
	offline=()
	shift
fi

cd "$(git rev-parse --show-toplevel)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
SITE="$TMP/public"

if ! hugo --minify --printPathWarnings --baseURL "$BASE" --destination "$SITE" > "$TMP/hugo.log" 2>&1; then
	cat "$TMP/hugo.log"
	echo "check-site: hugo build failed" >&2
	exit 1
fi
if grep -E '^(WARN|ERROR)' "$TMP/hugo.log" | grep -Ev "$KNOWN_WARNINGS"; then
	echo "check-site: hugo printed the warnings above" >&2
	exit 1
fi

# Some theme links stay root-relative (/assets/...), hence --root-dir as well.
# The ${a[@]+...} form: macOS bash 3.2 calls an empty array unbound under set -u.
lychee ${offline[@]+"${offline[@]}"} --no-progress --root-dir "$SITE" \
	--remap "^${BASE//./\\.}(.*)\$ file://$SITE/\$1" "$@" "$SITE/**/*.html"
