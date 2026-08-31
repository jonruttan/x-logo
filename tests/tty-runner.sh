#!/bin/sh
# # x-logo -- the Logo lang for x-lang
#
# ## tests/tty-runner.sh -- the REPL's tty contract, pinned executably
#
# @description Drives real pty sessions with expect(1).  The only executable
#   witness of the interactive contract.
# @author [Jon Ruttan](jonruttan@gmail.com)
# @copyright 2026 Jon Ruttan
# @license MIT No Attribution (MIT-0)
#
#     ., .,
#     {O,O}
#     (   )
#      " "
#
# The ctrl-c cancel, exit paths, hooks and execute-once behaviours are
# isatty-guarded and therefore INVISIBLE to every batch-driven suite -- which
# is how they shipped broken. This harness drives real ptys, and it must be
# green BEFORE any rewrite of the Logo reader touches logo/ and stay green
# (modulo known-fail deletions) after.
#
# Tests live in tests/tty/: t*.exp run under expect, t*.sh under plain sh.
# tests/tty/known-fail.txt lists tests that pin a ruling not yet implemented;
# a listed test that PASSES is a failure of this harness (the fix landed --
# delete its line in the same change, so the list can only shrink).
#
# NOT PART OF `make test`.  A pty suite needs a pty, and CI containers and
# `make -j` both take that away; it skips with a note where expect is absent.
# CI runs it as its own job, on both OSes.

set -u

BUNDLE="$(cd "$(dirname "$0")/.." && pwd)"
cd "$BUNDLE"

X="${X:-x}"
command -v "$X" >/dev/null 2>&1 || {
	echo "x-logo: no x on PATH.  Set X=/path/to/x.sh and retry." >&2
	exit 1
}

if ! command -v expect >/dev/null 2>&1; then
	echo "SKIP: expect not installed -- logo tty contract not exercised"
	exit 0
fi

# THIS WORKING TREE IS THE LANG UNDER TEST, which is the one thing the old
# in-repo harness got for free and a bundle has to say.  `x -l logo` searches
# the INSTALLED langs/ by default, so without this the suite would happily
# test whatever copy was installed last -- green against code that is not the
# code in front of you, which is the exact shape of the failure this whole
# repository is a response to.  X_LANG_DIR is the platform's override, and it
# wants the directory bundles sit IN, not the bundle.
X_LANG_DIR="$(dirname "$BUNDLE")/"
export X_LANG_DIR X

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
# the answer when it is a checkout.  The tests therefore reach their own files
# by absolute path rather than relative to a cwd they no longer own.
X_ROOT="$("$X" --share-dir)"
if [ -e "$X_ROOT/lib/x.x" ]; then
	LOGO_SPAWN_DIR="$X_ROOT"       # a checkout: x.sh must stand in its own root
else
	LOGO_SPAWN_DIR="$BUNDLE"       # installed: anywhere works, so stay put
fi
LOGO_EXAMPLES="$BUNDLE/examples"
export LOGO_SPAWN_DIR LOGO_EXAMPLES

# Wall-time guard, same detection as the platform's spec-runner.sh
# (macOS ships no timeout(1); coreutils installs gtimeout).
_TIMEOUT_BIN=""
if command -v timeout >/dev/null 2>&1; then
	_TIMEOUT_BIN="timeout"
elif command -v gtimeout >/dev/null 2>&1; then
	_TIMEOUT_BIN="gtimeout"
fi
TIMEOUT_CMD=""
if [ -n "$_TIMEOUT_BIN" ]; then
	# The per-test wall guard, above the expect timeout inside lib.exp so a
	# stuck wait reports itself rather than being killed from outside with no
	# diagnosis.  A ceiling for hangs, sized for a loaded runner rather than an
	# idle laptop.
	TIMEOUT_CMD="$_TIMEOUT_BIN ${TIMEOUT_LOGO_TTY_SECS:-150}"
fi

ANSI_GREEN='\033[1;32m'
ANSI_RED='\033[1;31m'
ANSI_YELLOW='\033[1;33m'
ANSI_RESET='\033[0m'

KNOWN_FAIL=tests/tty/known-fail.txt

pass=0; fail=0; xfail=0; xpass=0

known_fail() {
	[ -e "$KNOWN_FAIL" ] && grep -qx "$1" "$KNOWN_FAIL"
}

# Each test spawns its own logo session; a wedged one must not strand
# children.  lib.exp records every spawned session leader's pid here; the pty
# makes that pid the pgid of the whole tree (incl. the viewer server, which
# ignores SIGINT by design but not SIGTERM), and orphans keep their pgid even
# after expect is timeout-killed.  Sweeping those groups reaps exactly this
# harness's trees -- a machine-wide pkill -f 'x-bin --batch' killed unrelated
# batch runs the one time it was tried.
PIDFILE=$(mktemp "${TMPDIR:-/tmp}/logo-tty-pids.XXXXXX") || exit 1
LOGO_TTY_PIDFILE="$PIDFILE"
export LOGO_TTY_PIDFILE
trap 'rm -f "$PIDFILE"' EXIT

sweep() {
	[ -s "$PIDFILE" ] || return 0
	while read -r pid; do
		[ -n "$pid" ] && kill -s TERM -- "-$pid" 2>/dev/null
	done < "$PIDFILE"
	# Condition wait, not a fixed second: after a clean test the groups are
	# already gone and this costs nothing; a surviving tree gets polled up to
	# the old 1s, and KILL stays the backstop.
	_i=0
	while [ "$_i" -lt 10 ]; do
		_alive=0
		while read -r pid; do
			[ -n "$pid" ] && kill -0 -- "-$pid" 2>/dev/null && { _alive=1; break; }
		done < "$PIDFILE"
		[ "$_alive" -eq 0 ] && break
		sleep 0.1
		_i=$((_i + 1))
	done
	while read -r pid; do
		[ -n "$pid" ] && kill -s KILL -- "-$pid" 2>/dev/null
	done < "$PIDFILE"
	: > "$PIDFILE"
}

for t in tests/tty/t*.exp tests/tty/t*.sh; do
	[ -e "$t" ] || continue
	name=$(basename "$t")
	case "$t" in
		*.exp) $TIMEOUT_CMD expect "$t" >/dev/null 2>&1 ;;
		*.sh)  $TIMEOUT_CMD sh "$t" >/dev/null 2>&1 ;;
	esac
	status=$?
	sweep
	if [ "$status" -eq 0 ]; then
		if known_fail "$name"; then
			printf "${ANSI_RED}XPASS${ANSI_RESET} %s -- fixed: delete its known-fail.txt line\n" "$name"
			xpass=$((xpass + 1))
		else
			printf "${ANSI_GREEN}ok${ANSI_RESET}    %s\n" "$name"
			pass=$((pass + 1))
		fi
	else
		if known_fail "$name"; then
			printf "${ANSI_YELLOW}xfail${ANSI_RESET} %s (pins a ruling not yet implemented)\n" "$name"
			xfail=$((xfail + 1))
		else
			printf "${ANSI_RED}FAIL${ANSI_RESET}  %s\n" "$name"
			fail=$((fail + 1))
		fi
	fi
done

echo
if [ "$fail" -eq 0 ] && [ "$xpass" -eq 0 ]; then
	printf "${ANSI_GREEN}logo-tty: %d ok, %d known-fail${ANSI_RESET}\n" "$pass" "$xfail"
	exit 0
fi
printf "${ANSI_RED}logo-tty: %d ok, %d FAIL, %d XPASS, %d known-fail${ANSI_RESET}\n" \
	"$pass" "$fail" "$xpass" "$xfail"
exit 1
