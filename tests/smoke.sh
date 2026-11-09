#!/usr/bin/env bash
# Smoke tests that don't need containers: project creation, resolution, mounts, help.
set -euo pipefail

SITES="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")/../sites")"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
export SITES_REGISTRY="$T/registry" NO_COLOR=1
cd "$T"

pass=0
ok()   { pass=$((pass + 1)); echo "ok   $*"; }
fail() { echo "FAIL $*" >&2; exit 1; }
expect_ok()   { local d="$1"; shift; "$@" >/dev/null 2>&1 && ok "$d" || fail "$d"; }
expect_fail() { local d="$1"; shift; "$@" >/dev/null 2>&1 && fail "$d (should fail)" || ok "$d"; }
expect_out()  { local d="$1" pat="$2" out; shift 2; out="$("$@" 2>&1 || true)"; grep -qE -- "$pat" <<< "$out" && ok "$d" || fail "$d (no match: $pat)"; }

# help
expect_out "help overview"        "usage: sites"            "$SITES" help
expect_out "help topic"           "usage: sites start"      "$SITES" help start
expect_out "--help on command"    "usage: sites mount"      "$SITES" mount --help
expect_fail "unknown command"                               "$SITES" bogus

# new
expect_ok   "new ./dir"            "$SITES" new blog
[[ -f blog/compose.yaml && -f blog/.env && -f blog/public/index.html ]] && ok "template copied" || fail "template copied"
grep -q '^NAME=blog$' blog/.env && grep -q '^PORT=8081$' blog/.env && ok "placeholders filled" || fail "placeholders filled"
expect_fail "duplicate name"       "$SITES" new other/blog
expect_fail "invalid explicit name" "$SITES" new x --name Bad_Name
mkdir "My Shop"
(cd "My Shop" && "$SITES" new -y >/dev/null) && grep -q '^NAME=my-shop$' "My Shop/.env" && ok "new -y slugifies" || fail "new -y slugifies"
grep -q '^PORT=8082$' "My Shop/.env" && ok "next free port" || fail "next free port"
mkdir keep keep/public && echo MINE > keep/public/index.html
"$SITES" new keep >/dev/null && [[ "$(cat keep/public/index.html)" == MINE ]] && ok "never overwrites" || fail "never overwrites"
expect_fail "new without tty/args"  "$SITES" new </dev/null
expect_out  "re-register existing"  "registered existing" bash -c "cd blog && '$SITES' new -y"

# resolution
expect_ok   "resolve by name"      "$SITES" url blog
expect_ok   "resolve by ./path"    "$SITES" url ./blog
expect_ok   "resolve from cwd"     bash -c "cd blog/public && '$SITES' url"
expect_ok   "resolve ."            bash -c "cd blog && '$SITES' url ."
expect_fail "unknown name"         "$SITES" url nope
expect_fail "outside project"      "$SITES" url
expect_out  "status lists all"     "my-shop"  "$SITES" status

# mounts
mkdir -p host/pics && echo img > host/pics/a.jpg
cd blog
expect_ok   "mount default url"    "$SITES" mount ../host/pics
[[ -d public/pics ]] && ok "placeholder created" || fail "placeholder created"
expect_ok   "mount custom url rw"  "$SITES" mount ../host/pics:/gallery:rw
grep -q 'html/gallery:rw' compose.mounts.yaml && ok "override generated" || fail "override generated"
expect_fail "mount over root"      "$SITES" mount ../host/pics:/
expect_fail "mount .. segment"     "$SITES" mount ../host/pics:/a/../b
expect_fail "mount missing src"    "$SITES" mount ./nope
expect_fail "mount bad mode"       "$SITES" mount ../host/pics:/x:zz
expect_out  "mounts lists"         "/gallery" "$SITES" mounts
expect_ok   "unmount by url"       "$SITES" unmount /pics
[[ ! -e public/pics ]] && ok "placeholder removed" || fail "placeholder removed"
expect_ok   "unmount last"         "$SITES" unmount /gallery
[[ ! -e compose.mounts.yaml && ! -e .mounts ]] && ok "override cleaned up" || fail "override cleaned up"

echo "all $pass smoke tests passed"
