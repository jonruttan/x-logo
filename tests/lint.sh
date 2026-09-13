#!/bin/sh
# # x-logo -- Logo turtle graphics on x-lang
#
# ## tests/lint.sh -- shim onto the lang kit's linter
#
# @description Sources the PLATFORM's lint; vendors nothing.
# @author [Jon Ruttan](jonruttan@gmail.com)
# @copyright 2026 Jon Ruttan
# @license MIT No Attribution (MIT-0)
#
#     ., .,
#     {O,O}
#     (   )
#      " "
#
# THE SAME RULING AS tests/spec-runner.sh AND tools/check/release-refs.sh: the
# platform ships the check, this bundle points at it.  `make lint-x` sweeps
# x-lang's own lib/ and apps/; a lang under languages/ was swept by nothing, so
# every rule the linter knows was advice this bundle never heard.
#
# NOT --strict, AND THAT IS A CHOICE ABOUT THIS BUNDLE RATHER THAN ABOUT THE
# RULES.  The kit's --strict fails on the structural findings -- ladder,
# ladder-dict, shape -- and logo/types.x currently carries one: `shape` on
# %logo-base-make, which arrived with the state-image work (88073f1).  Turning
# the gate on at a level the tree cannot hold means turning it off again within
# the week, which is how the rules went unheard the first time.  So this gates
# on the FAILURE class -- Undefined, malformed, unbound: a file the linter says
# is wrong rather than merely unlovely -- and the advisory findings are printed
# for a reader.  Tighten to --strict once types.x is clear; it is one word.
#
# Set X to point at a particular x; X_LANG_KIT overrides the kit.
set -e

BUNDLE="$(cd "$(dirname "$0")/.." && pwd)"
X="${X:-x}"

command -v "$X" >/dev/null 2>&1 || {
	echo "x-logo: no x on PATH.  Set X=/path/to/x.sh and retry." >&2
	exit 1
}

KIT="${X_LANG_KIT:-$("$X" --share-dir)/tools/lang-kit}"

# A GATE THE PLATFORM CANNOT RUN YET SKIPS; it does not fail the build.  The
# ruling x-coreutils wrote for this same file: the kit linter is newer than
# most released x, and hard-failing on its absence would break the gate on
# every x that predates it, which is a cadence this bundle does not set.  The
# notice names the exact missing file, and the day an x ships it the gate is
# live here with no edit.
[ -f "$KIT/lint.sh" ] || {
	echo "x-logo: SKIPPING lint -- no $KIT/lint.sh in this x." >&2
	echo "x-logo: it arrives with the lang kit's linter; upgrade x to gate on it." >&2
	exit 0
}

# THE PAYLOAD, NAMED.  Given no targets the kit sweeps every .x under the
# bundle, which is right until `make bundle` has left an unpacked copy in
# dist/ and the sweep lints this tree twice.  These are the same files the
# Makefile's PAYLOAD installs -- what the bundle IS.  The glob expands from
# the bundle root rather than the caller's cwd, so `sh x-logo/tests/lint.sh`
# from anywhere names the same files.
cd "$BUNDLE"
[ $# -gt 0 ] || set -- run.x logo/*.x

BUNDLE="$BUNDLE" X="$X" sh "$KIT/lint.sh" "$@" || {
	_rc=$?
	# THE TWO FAILURES THAT ARE NOT THIS BUNDLE'S, named so nobody debugs
	# either of them twice.  Both were found by wiring this gate up, and
	# both are the platform rather than the tree:
	#
	#   Undefined on a name its own file declares with `; lint-known:`.
	#     A group's preload was computed from its FIRST file only, so every
	#     other file's declaration was dropped -- and logo/serve.x, ninth of
	#     thirteen, declares %lang-root (a `bundle`-class seam row).
	#     x-lang#683.
	#
	#   `(no verdict -- engine died mid-group)` on every file at once,
	#     with `include: cannot open`.  The linter loads the boot amalgam,
	#     and the probe for it looked only where an INSTALL puts it; driven
	#     from a CHECKOUT, as a bundle's CI drives it, it fell through to a
	#     library whose opening include is root-relative and died.
	#     x-lang#687.
	#
	# Neither is reachable from anything in this repository, so the note
	# says so rather than leaving someone to bisect a tree that is fine.
	echo >&2
	echo "x-logo: two lint failures are the PLATFORM, not this bundle:" >&2
	echo "  * Undefined on a name its own file declares with '; lint-known:'" >&2
	echo "    -- the group preload dropped it (x-lang#683)" >&2
	echo "  * '(no verdict -- engine died mid-group)' everywhere, with" >&2
	echo "    'include: cannot open' -- the linter could not find the boot" >&2
	echo "    amalgam in a checkout (x-lang#687)" >&2
	echo "  Both are fixed upstream; upgrade x.  Anything else is ours." >&2
	exit "$_rc"
}
