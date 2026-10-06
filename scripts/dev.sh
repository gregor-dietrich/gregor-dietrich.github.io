#!/bin/bash
# Local preview server: `hugo server` with drafts, at http://localhost:1313/
# (Hugo picks another port if 1313 is taken, and says which).
#
# Usage:
#   scripts/dev.sh [HUGO_ARGS...]            # foreground; Ctrl+C stops it
#   scripts/dev.sh --detach [HUGO_ARGS...]   # background; returns once it's serving
#   scripts/dev.sh --stop                    # stop the background server
#   scripts/dev.sh --status                  # is a background server running?
#
# The background server's PID and log live in the git directory
# (.git/hugo-server.pid, .git/hugo-server.log), outside the work tree.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
PID_FILE="$(git rev-parse --git-path hugo-server.pid)"
LOG_FILE="$(git rev-parse --git-path hugo-server.log)"

# Prints the background server's PID if it's running. The command-name check
# guards against a stale PID file whose PID the OS has since reused.
running_pid() {
	local pid
	[[ -f "$PID_FILE" ]] || return 1
	pid="$(cat "$PID_FILE")"
	if [[ "$pid" =~ ^[0-9]+$ ]] && ps -p "$pid" -o comm= 2> /dev/null | grep -q hugo; then
		echo "$pid"
	else
		rm -f "$PID_FILE"
		return 1
	fi
}

server_url() {
	grep -oE 'http://[^ ]+' "$LOG_FILE" | tail -1
}

case "${1:-}" in
	--stop)
		if ! pid="$(running_pid)"; then
			echo "dev: no background server running"
			exit 0
		fi
		kill "$pid"
		for _ in $(seq 1 50); do
			ps -p "$pid" > /dev/null 2>&1 || break
			sleep 0.1
		done
		if ps -p "$pid" > /dev/null 2>&1; then
			echo "dev: server (PID $pid) didn't stop; try: kill -9 $pid" >&2
			exit 1
		fi
		rm -f "$PID_FILE"
		echo "dev: stopped server (PID $pid)"
		;;
	--status)
		if pid="$(running_pid)"; then
			echo "dev: running (PID $pid) at $(server_url)"
		else
			echo "dev: not running"
			exit 1
		fi
		;;
	--detach)
		shift
		if pid="$(running_pid)"; then
			echo "dev: already running (PID $pid) at $(server_url)"
			exit 0
		fi
		nohup hugo server --buildDrafts "$@" > "$LOG_FILE" 2>&1 &
		pid=$!
		echo "$pid" > "$PID_FILE"
		# Wait until Hugo reports it's serving, or give up after ~30s.
		for _ in $(seq 1 300); do
			if ! ps -p "$pid" > /dev/null 2>&1; then
				rm -f "$PID_FILE"
				cat "$LOG_FILE" >&2
				echo "dev: server exited during startup (log above)" >&2
				exit 1
			fi
			if grep -q 'Web Server is available at' "$LOG_FILE"; then
				echo "dev: serving at $(server_url) (PID $pid); stop with: scripts/dev.sh --stop"
				exit 0
			fi
			sleep 0.1
		done
		echo "dev: server started (PID $pid) but isn't serving yet; see $LOG_FILE" >&2
		exit 1
		;;
	*)
		if pid="$(running_pid)"; then
			echo "dev: a background server is already running (PID $pid) at $(server_url)" >&2
			echo "     stop it first with: scripts/dev.sh --stop" >&2
			exit 1
		fi
		exec hugo server --buildDrafts "$@"
		;;
esac
