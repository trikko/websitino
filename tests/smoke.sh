#!/usr/bin/env bash
# Serve a random file over http and https and check that curl downloads it intact.
# Usage: tests/smoke.sh path/to/websitino
set -euo pipefail

bin=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
work=$(mktemp -d)
export HOME="$work/home" XDG_CACHE_HOME="$work/home/.cache"
mkdir -p "$work/site" "$HOME"
head -c 1048576 /dev/urandom > "$work/site/test.bin"

md5of() { openssl md5 -r "$1" | cut -d' ' -f1; }
expected=$(md5of "$work/site/test.bin")

check() {
	local name=$1 port=$2 url=$3; shift 3
	"$bin" "$work/site" -p "$port" "$@" > "$work/$name.log" 2>&1 &
	local pid=$!
	if ! curl -sf --retry 10 --retry-connrefused --retry-delay 1 ${curlopts[@]+"${curlopts[@]}"} "$url" -o "$work/$name.bin"; then
		cat "$work/$name.log"; kill $pid; echo "$name: download failed"; exit 1
	fi
	kill $pid; wait $pid 2>/dev/null || true
	local got; got=$(md5of "$work/$name.bin")
	if [ "$got" != "$expected" ]; then echo "$name: md5 $got, expected $expected"; exit 1; fi
	echo "$name: ok ($got)"
}

curlopts=()
check http 8123 http://localhost:8123/test.bin

if [ "${2:-}" != "--no-https" ]; then
	# the first run creates the certificate: curl trusts it, so it checks the names too
	curlopts=(--cacert "$XDG_CACHE_HOME/websitino/selfsigned.crt")
	[ "$(uname)" = Darwin ] && curlopts=(--cacert "$HOME/Library/Caches/websitino/selfsigned.crt")
	"$bin" "$work/site" -p 8124 --https > "$work/cert.log" 2>&1 & pid=$!
	for _ in $(seq 20); do [ -s "${curlopts[1]}" ] && break; sleep 0.5; done
	kill $pid; wait $pid 2>/dev/null || true
	check https 8124 https://localhost:8124/test.bin --https
fi

rm -rf "$work"
