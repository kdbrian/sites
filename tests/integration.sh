#!/usr/bin/env bash
# Integration test with real containers: start, serve, live edit, mount, stop.
# Needs podman + podman-compose. Does not open a public tunnel.
set -euo pipefail

SITES="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")/../sites")"
T="$(mktemp -d)"
export SITES_REGISTRY="$T/registry" SITES_BASE_PORT="${SITES_BASE_PORT:-18081}" NO_COLOR=1
cleanup() { (cd "$T/itest" 2>/dev/null && "$SITES" stop >/dev/null 2>&1) || true; rm -rf "$T"; }
trap cleanup EXIT
cd "$T"

fail() { echo "FAIL $*" >&2; podman ps -a >&2 || true; exit 1; }
get()  { local _; for _ in $(seq 1 20); do curl -fsS "$1" 2>/dev/null && return 0; sleep 0.5; done; return 1; }

"$SITES" new itest >/dev/null
cd itest
PORT="$(grep '^PORT=' .env | cut -d= -f2)"
URL="http://127.0.0.1:$PORT"

"$SITES" start
get "$URL/" | grep -q '<h1>itest</h1>' || fail "serves template page"
echo "ok   serves template page"

echo '<p>live-edit</p>' > public/live.html
get "$URL/live.html" | grep -q live-edit || fail "live edit"
echo "ok   live edit visible without restart"

mkdir -p "$T/host" && echo mounted-file > "$T/host/hello.txt"
"$SITES" mount "$T/host:/files"
get "$URL/files/hello.txt" | grep -q mounted-file || fail "bind mount served"
echo "ok   bind mount served at /files"

"$SITES" status | grep -q 'itest.*running' || fail "status shows running"
echo "ok   status shows running"

"$SITES" stop
curl -fsS "$URL/" >/dev/null 2>&1 && fail "stopped site still answering"
echo "ok   stop"

echo "integration tests passed"
