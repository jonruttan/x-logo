#!/bin/sh
# # x-logo -- the Logo lang for x-lang
#
# ## tests/spec-runner.sh -- the bundle's runner
#
# @description Sources the PLATFORM's spec runner; vendors nothing.
# @author [Jon Ruttan](jonruttan@gmail.com)
# @copyright 2026 Jon Ruttan
# @license MIT No Attribution (MIT-0)
#
#     ., .,
#     {O,O}
#     (   )
#      " "
#
# NOT ONE PATH INTO THE X-LANG SOURCE TREE.  The 2024 generation of langs
# reached the platform as "$SCRIPT_DIR/../../../tests/spec-runner.sh" and both
# that and its X_BIN dangled the moment the lang left the repo -- the failure
# x-lang's docs/lang-contract.md calls "addressing, not sharing".  Everything
# here comes from x itself: --share-dir says which tree x reads from (repo root
# in a checkout, share/x installed) and --engine-path says where the engine is
# after the wrapper's full discovery order.
#
# Set X to point at a particular x; otherwise the one on PATH is used.
set -e

BUNDLE="$(cd "$(dirname "$0")/.." && pwd)"
X="${X:-x}"

command -v "$X" >/dev/null 2>&1 || {
	echo "x-logo: no x on PATH.  Set X=/path/to/x.sh and retry." >&2
	exit 1
}

X_ROOT="$("$X" --share-dir)"
# X_BIN is env-overridable, the way x-lang's own tests/x/spec-runner.sh makes
# it -- so the same runner can drive a variant or patched engine without
# moving anything.
X_BIN="${X_BIN:-$("$X" --engine-path)}"

# REQUIRED FROM AN INSTALLED TREE.  The runner finds its awk harness from the
# directory holding the ENGINE -- true in a checkout, where the binary sits
# beside tests/, and false in an install, where the engine is under libexec/x.
# A sourced script cannot portably find its own path, so the caller says.
SPEC_RUNNER_DIR="$X_ROOT/tests"
export SPEC_RUNNER_DIR

# The harness is GENERATED, never committed: it embeds two absolute paths
# that are facts of this machine, not of the bundle.
sh "$BUNDLE/tests/gen-harness.sh" "$X_ROOT" "$BUNDLE"

LANG_LIB="$BUNDLE/tests/lib/harness.gen.x"
# SPEC_PATH is env-overridable so a single spec file can be run in isolation
# while diagnosing, without moving anything into the suite.
SPEC_PATH="${SPEC_PATH:-$BUNDLE/tests/specs}"

# THIS SUITE IS HEAVY, and it is worth knowing why before running it beside
# anything else.  The turtle kernel loads the tower plus Logo's own tokenizer,
# expression parser and dispatcher; x-lang's runner records the resident heap
# at 5-7GB, which is what its `@weight 7` row is for and why that row survived
# the move.  Two of these in parallel is a swapping machine, and a swapping
# machine reports failures that are not there -- x-lang's tools/contract/
# langs.x has the measurement.  Run it on a quiet one.
# NO COLLECT AT THE SNIPPET SEAM.  The platform runner grew a per-seam
# heap-collect (x-lang#568 has the diagnosis, #572 the knob), and with it on,
# this suite dies wholesale: 69 of 83 red -- the tokenizer specs first, which is
# every spec in a bundle whose whole point is its own tokenizer types.  With
# the knob at 0 the suite is exactly its recorded self.  Measured both ways
# against the #572 head rather than reasoned about; x-python's wrapper made
# the same call for the same reason, and a runner without the knob (the
# pinned release) ignores the export.
export SPEC_SEAM_COLLECT=0

. "$X_ROOT/tests/spec-runner.sh"
