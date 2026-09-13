#!/bin/sh
# # x-logo -- Logo turtle graphics on x-lang
#
# ## tests/lint.sh -- shim onto the lang kit's linter
#
# @description Runs the platform's linter over this bundle's sources.
# @author [Jon Ruttan](jonruttan@gmail.com)
# @copyright 2026 Jon Ruttan
# @license MIT No Attribution (MIT-0)
#
#     ., .,
#     {O,O}
#     (   )
#      " "
#
# The linter ships with the platform, like the spec runner and the release-refs
# check; this script locates it and names the files to lint.
#
# Advisory findings are printed and do not fail the run.  The kit's --strict
# also fails on the structural rules -- ladder, ladder-dict and shape -- which
# logo/types.x currently reports one of, so this runs without it.
#
# Set X to point at a particular x; X_LANG_KIT overrides the kit location.
set -e

BUNDLE="$(cd "$(dirname "$0")/.." && pwd)"
X="${X:-x}"

command -v "$X" >/dev/null 2>&1 || {
	echo "x-logo: no x on PATH.  Set X=/path/to/x.sh and retry." >&2
	exit 1
}

KIT="${X_LANG_KIT:-$("$X" --share-dir)/tools/lang-kit}"

# An x whose kit carries no linter skips at exit 0, so this gate can be wired
# up before every supported x ships one.
[ -f "$KIT/lint.sh" ] || {
	echo "x-logo: no linter at $KIT/lint.sh -- skipping." >&2
	exit 0
}

# The files the Makefile's PAYLOAD installs.  Naming them keeps an unpacked
# copy under dist/ out of the sweep.  The glob expands from the bundle root, so
# the target list does not depend on the caller's working directory.
cd "$BUNDLE"
[ $# -gt 0 ] || set -- run.x logo/*.x

BUNDLE="$BUNDLE" X="$X" sh "$KIT/lint.sh" "$@"
