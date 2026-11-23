#!/usr/bin/env bash
# run-evals.sh without running anything (--dry-run): two plugins alternate A, B, A, B; bad usage exits
# 2. Live runs cost money; their scoring is first exercised by a library's real measurement.
set -uo pipefail
script="$(cd "$(dirname "$0")" && pwd)/../skills/library-skill/scripts/run-evals.sh"
failed=0
expect() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; failed=1; fi; }
fixture="$(mktemp -d)"; mkdir "$fixture/.git"
out="$(bash "$script" --a /old --b /new --fixture "$fixture" --batches 2 --dry-run /tmp/out case1 2>&1)"
expect "alternates a-b1 b-b1 a-b2 b-b2" '[ "$(awk "{print \$2}" <<<"$out" | tr "\n" " ")" = "a-b1 b-b1 a-b2 b-b2 " ]'
out="$(bash "$script" --a /one --fixture "$fixture" --dry-run /tmp/out case1 2>&1)"
expect "one plugin: with and without in one batch" 'grep -q "eval b1 case1 plugin=/one ablation=with-without" <<<"$out"'
bash "$script" --a /x /tmp/out case1 >/dev/null 2>&1; code=$?
expect "no fixture: usage, exit 2" '[ "$code" -eq 2 ]'
rm -rf "$fixture"
exit "$failed"
