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
	# THE ONE FAILURE THAT IS NOT THIS BUNDLE'S, named so nobody debugs it
	# twice.  A platform before x-lang#683 computed a group's preload from
	# the FIRST file in it, so every other file's `; lint-known:` line was
	# dropped -- and logo/serve.x, ninth of thirteen, declares %lang-root
	# (a `bundle`-class seam row).  It reports as Undefined on a name the
	# file plainly declares, which reads as a bundle defect and is not one.
	echo >&2
	echo "x-logo: if the only finding is Undefined on a name its own file" >&2
	echo "  declares with '; lint-known:', this x predates x-lang#683 --" >&2
	echo "  the group preload dropped it.  Upgrade x; the tree is fine." >&2
	exit "$_rc"
}
