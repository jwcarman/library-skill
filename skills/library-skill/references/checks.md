# Step 3: give agents checks, and check the skill

Three checks. One the agents run (`check.sh`), two the library's CI runs on the skill itself
(`check-recipe.sh`, `check-names.mjs`). Copy each script from this skill's `scripts/` into the
library and adapt every `ADAPT:` line.

## The agents' check: `check.sh`

Agents fail on what they cannot see: an unformatted file, a stale generated file, a coverage gate,
a test they could not run. A script turns "remember these five commands in this order" into "run
this", and it costs nothing to read. In roux, 26 of 30 runs ran it; the one Spotless failure left was
a run that didn't.

- **Find the project's tools; never assume them.** The script looks for the build (`./mvnw`,
  `./gradlew`), a formatter (Spotless), generated files and the command that rewrites them, a
  frontend (`package.json` scripts) and what the build already runs. It runs what exists, in the
  order the build needs, and prints what it skipped. A skipped step reported as passed is a lie the
  agent will repeat to the user.
- **Order matters.** Format first (later Maven runs check the format and fail on it); then rewrite
  generated files (a frontend build fails against a stale one); then compile and run what the build
  runs.
- **Stop at the first failure, with the lines that say why**: compile errors with file and line,
  failing tests, coverage rows naming uncovered lines; and the full log's path.
- **Say what it cannot do.** If tests need Docker, its last line says so; the skill tells the agent
  to read its tests against the recipe instead.
- In the skill: SKILL.md's "before you finish" says **run** it, from the project root, by the skill's
  base directory (`bash <skill base directory>/scripts/check.sh`); the recipe's check section says
  the same.
- Prove it on the fixture: clean (passes), and one broken copy per failure cause from step 1 (each
  fails with its line, or is fixed and passes).

## The recipe build: `check-recipe.sh`

Every code block an agent will copy is built in CI, so an example cannot drift or stop compiling.

- Mark each block in the recipe with an HTML comment on the line before it:
  - `<!-- file: <path> -->` the block is that whole file, relative to the app's root;
  - `<!-- files: <dir>/ -->` a Java block of several top-level types: package and imports, then one
    file per type;
  - `<!-- fragment: <name> -->` a piece of an existing file; the fragments file puts it in place.
- The script copies the fixture, writes the files, calls the fragments file for each fragment (an
  unknown name fails the script), and runs the fixture's full build, tests and gates included.
- Prove it fails: remove one test the gate needs from a copy of the recipe; it must fail. In roux it
  failed exactly as five agent runs had (branch coverage 0.50).
- Run it in the library's CI on every change. It needs whatever the build needs (Docker for
  Testcontainers): CI runners have it.

## The names check: `check-names.mjs`

Every public type (Java) and export (TypeScript entry points) appears in backticks in the skill, so
an agent can find each by name and a new API cannot ship undocumented to agents.

- Config: the Java source roots, the TS entry `index.ts` files, names to leave out (auto-configuration
  and other wiring users never name), and the docs folders to scan.
- A backtick span is counted only on one line: keep each name's span on a single line.
- Also worth adding (roux has them in `check-guides.mjs`): every import a reference shows is a real
  export; every reference's size label in SKILL.md is within 20% of the file.

## Steps

1. Copy `check.sh`; fill its `ADAPT:` lines (generated files, XML or other files to parse); prove it
   clean and broken.
2. Mark the recipe's blocks; write the fragments file from `check-recipe-fragments.example.py`;
   run `check-recipe.sh` until it passes; prove it fails without a needed test.
3. Write the names config; run `check-names.mjs` until `ok`.
4. Add the recipe build and names check to CI.

## Pitfalls

- A formatter run inside a later step (Prettier over generated files rewrote roux's
  `permissions.gen.ts` and failed its check): format only what the build formats.
- A check that runs Maven's `test` phase before formatting: the format check inside it fails first,
  with a misleading message.
- A frontend coverage gate counts only files some test loads: an untested file nothing imports is
  invisible to it, in the check and in the real build alike.
