#!/usr/bin/env bash
# check-recipe.sh builds roux's recipe into roux's app template with the example fragments file (as
# roux's own check-recipe.sh does), and fails, naming it, on a fragment the fragments file does not
# know. Needs roux beside this repository with its modules installed and roux-web built (roux's
# check-recipe.sh does both), Java, and Docker.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
scripts="$here/../skills/library-skill/scripts"
roux="$(cd "$here/../../roux" && pwd)"
recipe="$roux/plugins/roux/skills/roux/references/feature.md"
failed=0
expect() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; failed=1; fi; }

# roux's template links ../../web/roux-web and the root pom, so the copy must sit two levels down.
export RECIPE_APP_DIR="$roux/target/recipe-app"
mvnw="$roux/mvnw -f $RECIPE_APP_DIR/pom.xml -B -q"
generated="$mvnw test -Dskip.npm -Dtest=PermissionsListTest -Dsurefire.failIfNoSpecifiedTests=false"
build="$mvnw spotless:apply && ($generated || $generated) && $roux/mvnw -f $RECIPE_APP_DIR/pom.xml -B verify -DskipITs"

bad="$(mktemp -d)/feature.md"
sed 's/<!-- fragment: nav -->/<!-- fragment: sidebar -->/' "$recipe" >"$bad"
out="$(bash "$scripts/check-recipe.sh" "$bad" "$roux/templates/app" "$scripts/check-recipe-fragments.example.py" -- "$build" 2>&1)"; code=$?
expect "unknown fragment: fails" '[ "$code" -ne 0 ]'
expect "unknown fragment: names it" 'grep -q "unknown fragment: sidebar" <<<"$out"'

out="$(bash "$scripts/check-recipe.sh" "$recipe" "$roux/templates/app" "$scripts/check-recipe-fragments.example.py" -- "$build" 2>&1)"; code=$?
expect "roux's recipe: builds and passes its gates" '[ "$code" -eq 0 ] && grep -q "Tests run: 22, Failures: 0, Errors: 0" <<<"$out"'
expect "roux's recipe: says how many blocks" 'grep -q "check-recipe: wrote 17 blocks" <<<"$out"'

[ "$failed" -eq 0 ] || tail -25 <<<"$out"
exit "$failed"
