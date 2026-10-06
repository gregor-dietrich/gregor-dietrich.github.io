#!/bin/bash
# Installs the linters scripts/lint.sh runs, at pinned versions, on Linux
# (amd64 or arm64): used by CI (.github/actions/setup-tools) and for Debian
# setup. On macOS, use Homebrew instead (README.md, Setup).
#
# Usage: scripts/install-linters.sh [PREFIX]   # installs into PREFIX/bin, default ~/.local
#
# Needs curl and npm. hugo and shellcheck come from elsewhere (README.md).
set -euo pipefail

MARKDOWNLINT_CLI2_VERSION=0.23.3
TYPOS_VERSION=1.51.0
VALE_VERSION=3.24.0
ACTIONLINT_VERSION=1.7.12
LYCHEE_VERSION=0.24.2

PREFIX="${1:-$HOME/.local}"
BIN="$PREFIX/bin"

if [[ "$(uname -s)" != Linux ]]; then
	echo "install-linters: Linux only; on macOS use Homebrew (README.md, Setup)" >&2
	exit 1
fi
case "$(uname -m)" in
	x86_64) rust=x86_64 vale=64-bit go=amd64 ;;
	aarch64 | arm64) rust=aarch64 vale=arm64 go=arm64 ;;
	*)
		echo "install-linters: unsupported architecture $(uname -m)" >&2
		exit 1
		;;
esac

mkdir -p "$BIN"

# fetch REPO RELEASE_PATH TAR_ARGS...: extract a release tarball's binary into $BIN.
fetch() {
	echo "install-linters: $1 ${2%%/*}"
	curl -sSfL "https://github.com/$1/releases/download/$2" | tar -xz -C "$BIN" "${@:3}"
}

fetch crate-ci/typos "v$TYPOS_VERSION/typos-v$TYPOS_VERSION-$rust-unknown-linux-musl.tar.gz" ./typos
fetch errata-ai/vale "v$VALE_VERSION/vale_${VALE_VERSION}_Linux_$vale.tar.gz" vale
fetch rhysd/actionlint "v$ACTIONLINT_VERSION/actionlint_${ACTIONLINT_VERSION}_linux_$go.tar.gz" actionlint
fetch lycheeverse/lychee "lychee-v$LYCHEE_VERSION/lychee-$rust-unknown-linux-gnu.tar.gz" \
	--strip-components=1 "lychee-$rust-unknown-linux-gnu/lychee"

echo "install-linters: markdownlint-cli2 v$MARKDOWNLINT_CLI2_VERSION"
npm install --global --prefix "$PREFIX" --no-fund --no-audit --loglevel=error \
	"markdownlint-cli2@$MARKDOWNLINT_CLI2_VERSION"

echo "install-linters: done; make sure $BIN is on your PATH"
