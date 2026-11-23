#!/usr/bin/env bash
# The checks an agent can run before it finishes, without Docker, in the order the build needs them.
# Copy this into the library's skill (skills/<library>/scripts/check.sh), adapt the ADAPT: lines,
# and have SKILL.md say: from the project's root, run `bash <skill base directory>/scripts/check.sh`.
#
# It never assumes the project's tools. It finds them, runs what exists, and ends by listing what it
# skipped, so a skipped step is never reported as passed:
#   1. XML resources are well-formed (a broken changelog or config stops the app from starting).
#   2. The formatter, if the build has one (Spotless): later build runs check the format and fail.
#   3. Generated files, rewritten by the commands you list (a build fails against a stale one).
#   4. Compile main and test code (Maven: test-compile; Gradle: testClasses).
#   5. The frontend's tests and build: through the build when it runs them, here otherwise.
# It stops at the first failure with the lines that say why, and the full log's path.
set -uo pipefail

# ADAPT: commands that rewrite generated files, one per line; each may fail once (when it rewrote a
# file) and must pass the second time. Example (roux): a test that writes the frontend's permissions.
generated="${CHECK_GENERATED:-}"
# ADAPT: the XML files to parse (find(1) arguments under src/).
xml_files=(src/main/resources -name '*.xml')
# ADAPT: where the frontend is, if anywhere (the first folder holding a package.json wins).
frontend_dirs=(frontend web ui .)
# ADAPT: the last line, saying what this script cannot check.
cannot="tests that need Docker: run the build's full verify where Docker is"

log="$(mktemp -t check.XXXXXX)"
skipped=()

fail() {
  echo "check: FAIL $1" >&2
  echo "  $2" >&2
  [ -n "${3:-}" ] && head -n 5 "$log" | sed 's/^/  /' >&2
  # Compile errors, failing tests and type errors; then coverage rows that list uncovered lines.
  grep -E '^\[ERROR\] .*\.(java|kt|xml)|^e: |ERROR: Coverage|error TS|FAIL |AssertionError|violations|Expected' "$log" \
    | sed -E 's/^\[INFO\] //' | awk '!seen[$0]++' | head -n 20 | sed 's/^/  /' >&2
  grep -E '\|[^|]*\|[^|]*\|[^|]*\|[^|]*\| *[0-9][0-9,-]* *$' "$log" | sed -E 's/^\[INFO\] //' \
    | head -n 10 | sed 's/^/  uncovered: /' >&2
  echo "  full output: $log" >&2
  exit 1
}

# The build.
build=""
if [ -x ./mvnw ]; then build="./mvnw -B"; buildfile=pom.xml
elif [ -x ./gradlew ]; then build="./gradlew -q"; buildfile="$(ls build.gradle.kts build.gradle 2>/dev/null | head -n 1)"
elif [ -f pom.xml ] && command -v mvn >/dev/null; then build="mvn -B"; buildfile=pom.xml
fi
maven() { [ "${buildfile:-}" = pom.xml ]; }

# 1. XML.
if [ -d src ]; then
  while IFS= read -r xml; do
    if command -v xmllint >/dev/null; then
      xmllint --noout "$xml" >"$log" 2>&1
    else
      python3 -c 'import sys, xml.dom.minidom; xml.dom.minidom.parse(sys.argv[1])' "$xml" >"$log" 2>&1
    fi || fail "$xml is not well-formed XML" "content after the root element's closing tag, or a tag left open" raw
  done < <(find "${xml_files[@]}" 2>/dev/null)
  echo "check: ok   XML well-formed"
fi

if [ -n "$build" ]; then
  # 2. Format.
  if grep -Eq "<artifactId>spotless-maven-plugin</artifactId>|com\.diffplug\.spotless" "$buildfile" 2>/dev/null; then
    if maven; then $build spotless:apply >"$log" 2>&1; else $build spotlessApply >"$log" 2>&1; fi \
      || fail "the formatter (Spotless)" "a source file that does not parse"
    echo "check: ok   Java formatted"
  else
    skipped+=("formatting (no Spotless in $buildfile)")
  fi

  # 3. Generated files.
  if [ -n "$generated" ]; then
    while IFS= read -r command; do
      [ -n "$command" ] || continue
      bash -c "$command" >"$log" 2>&1 || bash -c "$command" >"$log" 2>&1 \
        || fail "$command" "it compiles the code first: a compile error below, or the generator's own message"
    done <<<"$generated"
    echo "check: ok   generated files rewritten"
  else
    skipped+=("generated files (none listed in check.sh)")
  fi

  # 4. Compile.
  if maven; then $build test-compile >"$log" 2>&1; else $build testClasses >"$log" 2>&1; fi \
    || fail "compile" "a compile error, or a frontend step the build runs"
  echo "check: ok   main and test code compile"
else
  skipped+=("the Java build (no mvnw, gradlew or pom.xml)")
fi

# 5. The frontend.
frontend=""
for dir in "${frontend_dirs[@]}"; do
  if [ -f "$dir/package.json" ]; then frontend="$dir"; break; fi
done
build_runs() { # whether the build runs this npm script itself (frontend-maven-plugin, or a Gradle task)
  [ -n "${buildfile:-}" ] || return 1
  if maven; then
    grep -Eq "<arguments>run $1( [^<]*)?</arguments>" "$buildfile"
  else
    grep -Eq "\"run\", *\"$1\"|['\"]run $1['\" ]" "$buildfile" # ADAPT: how your Gradle build calls npm
  fi
}
has_script() {
  node -e 'process.exit(require(process.argv[1]).scripts?.[process.argv[2]] ? 0 : 1)' "$(cd "$frontend" && pwd)/package.json" "$1" 2>/dev/null
}
if [ -n "$frontend" ]; then
  if build_runs coverage || build_runs test; then
    echo "check: ok   frontend tests (run by the build)"
  else
    test_script=""
    if has_script coverage; then test_script=coverage; elif has_script test; then test_script=test; fi
    if [ -n "$test_script" ]; then
      [ -d "$frontend/node_modules" ] || (cd "$frontend" && npm ci) >"$log" 2>&1 || fail "npm ci" "the frontend's dependencies"
      once=()
      [ "$test_script" = test ] && once=(-- --run) # vitest's test script watches without it
      (cd "$frontend" && npm run "$test_script" "${once[@]+"${once[@]}"}") >"$log" 2>&1 \
        || fail "npm run $test_script" "a failing frontend test or uncovered lines"
      echo "check: ok   frontend tests (npm run $test_script)"
    else
      skipped+=("frontend tests (no coverage or test script)")
    fi
  fi
  if build_runs build; then
    echo "check: ok   frontend build (run by the build)"
  elif has_script build; then
    (cd "$frontend" && npm run build) >"$log" 2>&1 || fail "npm run build" "a type error or a bundling error"
    echo "check: ok   frontend build (npm run build)"
  else
    skipped+=("the frontend build (no build script)")
  fi
else
  skipped+=("the frontend (no package.json)")
fi

rm -f "$log"
for step in "${skipped[@]+"${skipped[@]}"}"; do
  echo "check: skipped $step"
done
echo "check: ok   (not checked here: $cannot)"
