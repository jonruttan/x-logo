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
# --strict fails the run on the structural rules -- ladder, ladder-dict and
# depth -- which this bundle reports none of.  The advisory rules print either
# way and never fail a run.
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

# An x older than the release lang.xon names skips too, for the same reason:
# the modules import platform libraries such a tree has no file for, and the
# linter preloads them, so the run dies per file on `include: cannot open` --
# which reads as a defect in this source rather than as a platform too old.
#
# Conservative on purpose.  Only a release that can be read AND is below the
# floor skips; an x whose release is unreadable runs the lint, so a version
# this cannot parse never silently disables the gate.
FLOOR=$(sed -n 's/^(requires-release "v\{0,1\}\([0-9.]*\)").*/\1/p' "$BUNDLE/lang.xon" | head -1)
HAVE=$("$X" --version 2>/dev/null |
	sed -n 's/.*library release v\{0,1\}\([0-9.]*\).*/\1/p' | head -1)
if [ -n "$FLOOR" ] && [ -n "$HAVE" ] && ! awk -v a="$HAVE" -v b="$FLOOR" 'BEGIN {
		na = split(a, have, "."); nb = split(b, want, ".")
		n = na > nb ? na : nb
		for (i = 1; i <= n; i++) {
			u = (i <= na ? have[i] + 0 : 0)
			v = (i <= nb ? want[i] + 0 : 0)
			if (u > v) exit 0
			if (u < v) exit 1
		}
		exit 0
	}'; then
	echo "x-logo: SKIPPING lint -- this x is $HAVE, lang.xon needs $FLOOR." >&2
	echo "x-logo: install a current x to gate on it." >&2
	exit 0
fi

# The files the Makefile's PAYLOAD installs.  Naming them keeps an unpacked
# copy under dist/ out of the sweep.  The glob expands from the bundle root, so
# the target list does not depend on the caller's working directory.
cd "$BUNDLE"
[ $# -gt 0 ] || set -- run.x logo/*.x

BUNDLE="$BUNDLE" X="$X" sh "$KIT/lint.sh" --strict "$@"
