#!/usr/bin/env bash
# check-names.mjs reproduces roux's check (361 distinct names, all documented; roux prints 368 because it counts a name exported twice twice) and reports every public name
# of a library with no skill (jpa-utils: 16) as missing. Needs roux and jpa-utils checked out beside
# this repository.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
script="$here/../skills/library-skill/scripts/check-names.mjs"
failed=0
expect() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; failed=1; fi; }

out="$(node "$script" "$here/roux-names.json" 2>&1)"; code=$?
expect "roux: exit 0" '[ "$code" -eq 0 ]'
expect "roux: ok: 361 public names documented" '[ "$out" = "ok: 361 public names documented" ]'

out="$(node "$script" "$here/jpa-utils-names.json" 2>&1)"; code=$?
expect "jpa-utils without a skill: exit 1" '[ "$code" -eq 1 ]'
expect "jpa-utils without a skill: 16 missing" '[ "$(grep -c "^missing from no-such-skill: " <<<"$out")" -eq 16 ]'
expect "jpa-utils: names the file" 'grep -q "missing from no-such-skill: Paginator (src/main/java/.*/Paginator.java)" <<<"$out"'

exit "$failed"
