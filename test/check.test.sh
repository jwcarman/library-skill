#!/usr/bin/env bash
# check.sh on real projects: roux's eval app (as made, stripped of Spotless and the frontend plugin,
# and broken two ways) and jpa-utils (a library with no frontend). Needs the roux app fixture at
# $ROUX_APP (an eval-fixture.sh --app directory), jpa-utils beside this repository, and Java.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
script="$here/../skills/library-skill/scripts/check.sh"
: "${ROUX_APP:?set ROUX_APP to a roux app fixture (eval-fixture.sh --app)}"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
failed=0
expect() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; failed=1; fi; }
copy() { cp -R "$1" "$work/$2"; echo "$work/$2"; }
run() { (cd "$1" && CHECK_GENERATED="${2:-}" bash "$script" 2>&1); }
roux_generated='./mvnw -B -q test -Dskip.npm -Dtest=PermissionsListTest -Dsurefire.failIfNoSpecifiedTests=false'

strip() { # remove every <plugin> holding the named artifact from a pom
  python3 - "$1" "$2" <<'PY'
import sys
path, artifact = sys.argv[1], f"<artifactId>{sys.argv[2]}</artifactId>"
s = open(path).read()
while artifact in s:
    i = s.index(artifact); start = s.rindex("<plugin>", 0, i); end = s.index("</plugin>", i) + 9
    s = s[:start] + s[end:]
open(path, "w").write(s)
PY
}

app="$(copy "$ROUX_APP" clean)"
out="$(run "$app" "$roux_generated")"; code=$?
expect "roux app: passes" '[ "$code" -eq 0 ] && grep -q "^check: ok   (" <<<"$out"'
expect "roux app: formats with Spotless" 'grep -q "^check: ok   Java formatted" <<<"$out"'
expect "roux app: rewrites generated files" 'grep -q "^check: ok   generated files" <<<"$out"'
expect "roux app: the pom runs the frontend" 'grep -q "^check: ok   frontend tests (run by the build)" <<<"$out"'
expect "roux app: nothing skipped" '! grep -q "^check: skipped" <<<"$out"'

app="$(copy "$ROUX_APP" stripped)"
strip "$app/pom.xml" spotless-maven-plugin; strip "$app/pom.xml" frontend-maven-plugin
out="$(run "$app" "$roux_generated")"; code=$?
expect "stripped: passes" '[ "$code" -eq 0 ]'
expect "stripped: says formatting was skipped" 'grep -q "^check: skipped formatting" <<<"$out"'
expect "stripped: runs the frontend itself" 'grep -q "^check: ok   frontend tests (npm run coverage)" <<<"$out" && grep -q "^check: ok   frontend build (npm run build)" <<<"$out"'

echo 'export function untested(n: number): number { return n + 1; }' >>"$app/frontend/src/queryKeys.ts"
out="$(run "$app" "$roux_generated")"; code=$?
expect "uncovered line: fails" '[ "$code" -eq 1 ] && grep -q "^check: FAIL npm run coverage" <<<"$out"'
expect "uncovered line: names the file" 'grep -q "uncovered: .*queryKeys.ts" <<<"$out"'

app="$(copy "$ROUX_APP" badxml)"
printf '<changeSet id="x" author="app"/>\n' >>"$app/src/main/resources/db/changelog/roles.xml"
out="$(run "$app")"; code=$?
expect "XML after its root: fails with the parser's line" '[ "$code" -eq 1 ] && grep -q "roles.xml is not well-formed" <<<"$out" && grep -q "roles.xml:[0-9]*:" <<<"$out"'

lib="$(copy "$here/../../jpa-utils" jpa-utils)"
rm -rf "$lib/target"
out="$(run "$lib")"; code=$?
expect "jpa-utils: passes on what it has" '[ "$code" -eq 0 ]'
expect "jpa-utils: says there is no frontend" 'grep -q "^check: skipped the frontend" <<<"$out"'
expect "jpa-utils: says there are no generated files" 'grep -q "^check: skipped generated files" <<<"$out"'

[ "$failed" -eq 0 ] || echo "$out" | tail -20
exit "$failed"
