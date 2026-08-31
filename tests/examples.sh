#!/bin/sh
# # x-logo -- the Logo lang for x-lang
#
# ## tests/examples.sh -- every example runs, and its output is pinned
#
# @description Runs each examples/*.logo in batch under this bundle and
#   compares stdout against its .expect sidecar.
# @author [Jon Ruttan](jonruttan@gmail.com)
# @copyright 2026 Jon Ruttan
# @license MIT No Attribution (MIT-0)
#
# Usage:
#   sh tests/examples.sh            check
#   UPDATE=1 sh tests/examples.sh   regenerate the sidecars
#
# WHY THIS IS NOT THE SPEC SUITE.  The specs exercise the turtle KERNEL
# through the harness -- no reader, no dispatcher, no entry.  An example is a
# Logo program, and running one exercises the whole path a user takes: the
# indentation preprocessor, the tokenizer, the infix parser, the dispatcher
# and the batch launcher.  x-lang's own gate on this file caught the -f
# discard shipping broken for three months, and it caught it because nothing
# else ran the language end to end.
#
# .expect, NOT .out: a global *.out ignore for compiler artifacts silently
# swallows the sidecars, which demotes every pinned example to status-only in
# a fresh clone -- a check that quietly stops checking.
#
# AN EMPTY SIDECAR IS A REAL PIN.  ch1.logo defines procedures and draws; it
# prints nothing, and "prints nothing" is exactly what regressed when the
# batch path started echoing results.  Absent sidecar means status-only, and
# the run says which it was -- no silent caps.
set -u

BUNDLE="$(cd "$(dirname "$0")/.." && pwd)"
cd "$BUNDLE"

X="${X:-x}"
command -v "$X" >/dev/null 2>&1 || {
	echo "x-logo: no x on PATH.  Set X=/path/to/x.sh and retry." >&2
	exit 1
}

# This working tree is the lang under test -- see the same note in
# tests/tty-runner.sh.
X_LANG_DIR="$(dirname "$BUNDLE")/"
export X_LANG_DIR

# WHERE x MUST BE RUN FROM, which is not always here.  An INSTALLED x works
# from any directory: its boot entries are amalgams under share/x/boot with
# zero path literals.  A CHECKOUT's x.sh does not -- it detects repo mode by
# finding lib/x.x in the CURRENT directory, because the boot includes it cats
# are cwd-relative "lib/..." literals.  Run it from anywhere else and it
# decides it is installed, then dies looking for share/x/boot/rn.x beside the
# wrapper.
#
# That is the platform's arrangement and not this bundle's to relitigate, so
# the runner asks --share-dir (which DOES answer from any cwd) and spawns from
# the answer when it is a checkout.  The example paths below are therefore absolute.
X_ROOT="$("$X" --share-dir)"
if [ -e "$X_ROOT/lib/x.x" ]; then
	LOGO_SPAWN_DIR="$X_ROOT"       # a checkout: x.sh must stand in its own root
else
	LOGO_SPAWN_DIR="$BUNDLE"       # installed: anywhere works, so stay put
fi
LOGO_EXAMPLES="$BUNDLE/examples"
export LOGO_SPAWN_DIR LOGO_EXAMPLES

ANSI_GREEN='\033[1;32m'
ANSI_RED='\033[1;31m'
ANSI_RESET='\033[0m'

total=0; pinned=0; failed=0
_TMP="${TMPDIR:-/tmp}/x-logo-examples.$$"
mkdir -p "$_TMP"
trap 'rm -rf "$_TMP"' EXIT

for f in examples/*.logo; do
	[ -e "$f" ] || continue
	total=$((total + 1))
	name=$(basename "$f")
	got="$_TMP/$name.out"
	# The viewer server is not forked in batch (main.x guards it on %batch?),
	# so nothing here binds a port and examples can run unattended.
	( cd "$LOGO_SPAWN_DIR" && "$X" -l logo -f "$BUNDLE/$f" ) \
		> "$got" 2>"$_TMP/$name.err"
	status=$?
	if [ "$status" -ne 0 ]; then
		printf "${ANSI_RED}FAIL${ANSI_RESET}  %s -- exit %d\n" "$name" "$status"
		sed 's/^/      /' "$_TMP/$name.err" | head -5
		failed=$((failed + 1))
		continue
	fi
	sidecar="$f.expect"
	if [ ! -e "$sidecar" ]; then
		printf "${ANSI_GREEN}ok${ANSI_RESET}    %s (status-only -- no %s)\n" "$name" "$(basename "$sidecar")"
		continue
	fi
	if [ "${UPDATE:-0}" = 1 ]; then
		cp "$got" "$sidecar"
		printf "${ANSI_GREEN}ok${ANSI_RESET}    %s (sidecar updated)\n" "$name"
		pinned=$((pinned + 1))
		continue
	fi
	if diff -u "$sidecar" "$got" > "$_TMP/$name.diff"; then
		printf "${ANSI_GREEN}ok${ANSI_RESET}    %s (pinned)\n" "$name"
		pinned=$((pinned + 1))
	else
		printf "${ANSI_RED}FAIL${ANSI_RESET}  %s -- output differs from %s\n" "$name" "$sidecar"
		sed 's/^/      /' "$_TMP/$name.diff" | head -20
		failed=$((failed + 1))
	fi
done

echo
if [ "$failed" -eq 0 ]; then
	printf "${ANSI_GREEN}examples: %d ok (%d pinned)${ANSI_RESET}\n" "$total" "$pinned"
	exit 0
fi
printf "${ANSI_RED}examples: %d run, %d FAILED${ANSI_RESET}\n" "$total" "$failed"
exit 1
