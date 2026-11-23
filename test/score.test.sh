#!/usr/bin/env bash
# score.py reproduces roux's round-2 result from its run files (rewrite 20 of 30, round 2 28 of 30,
# p = 0.0106), and counts a run whose result files are gone as a failure, not a missing run.
# Needs roux's Haiku results at $ROUX_RESULTS (the folder holding new-b1 ... and round2-b1 ...).
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
score="$here/../skills/library-skill/scripts/score.py"
: "${ROUX_RESULTS:?set ROUX_RESULTS to the haiku results folder of roux}"
failed=0
expect() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; failed=1; fi; }

out="$(python3 -I "$score" "$ROUX_RESULTS" 'new-b*' 'round2-b*' --hidden 10 2>&1)"
expect "arm A: 20 of 30" 'grep -q "^A new-b\*: n=30 success=20 " <<<"$out"'
expect "arm B: 28 of 30" 'grep -q "^B round2-b\*: n=30 success=28 " <<<"$out"'
expect "p(B better) = 0.0106" 'grep -q "^p(B better than A) = 0.0106" <<<"$out"'
expect "mean cost of B" 'grep -q "^B .*cost=\$0.052" <<<"$out"'

copy="$(mktemp -d)"
trap 'rm -rf "$copy"' EXIT
cp -R "$ROUX_RESULTS"/round2-b1 "$copy/"
rm "$copy"/round2-b1/app-locations-with-2.accept.txt "$copy"/round2-b1/app-locations-with-2.check.txt
out="$(python3 -I "$score" "$copy" 'round2-b1' 'round2-b1' --hidden 10 2>&1)"
expect "missing result files: still 5 runs, 4 successes" 'grep -q "^A round2-b1: n=5 success=4 " <<<"$out"'

exit "$failed"
