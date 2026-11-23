# The worked example: roux

roux (https://github.com/jwcarman/roux) is a Spring Boot + React base for apps. Its skill is
`plugins/roux/skills/roux/`; its evals are `plugins/roux/evals/`; the full record of every
measurement, rules and results, is `plugins/roux/evals/PROTOCOL.md`.

## Where each step lives

| Step | roux's files |
| --- | --- |
| Fixture | `plugins/roux/scripts/eval-fixture.sh` (`--app`: a new app from the template, roux's modules installed into the fixture's own Maven repository, npm cache filled, offline build proven by `eval-preflight.sh` under `sandbox-exec`) |
| Cases | `plugins/roux/evals/app-locations/` (prompt with pinned contract, hidden `acceptance/` tests in Java and Playwright) |
| Scoring | `plugins/roux/scripts/eval-acceptance.sh` (hidden tests), `check-roux-way.sh` (the app's own `./mvnw verify -DskipITs` plus roux-specific checks) |
| Running | `plugins/roux/scripts/run-evals.sh` (wraps `claude plugin eval`, scores each run) |
| Recipe | `plugins/roux/skills/roux/references/feature.md` (12 steps, every block marked `file:`/`files:`/`fragment:`) |
| Cards | the other files in `references/` (errors, forms, lists, permissions, users, feedback, tests, app-setup, money, dates, activity-log, email) |
| Agents' check | `plugins/roux/skills/roux/scripts/check.sh` (assumes roux's template: its apps always come from it) |
| Recipe build | `plugins/roux/scripts/check-recipe.sh` (copies the template, writes the recipe, `./mvnw verify -DskipITs`, in CI) |
| Names check | `plugins/roux/scripts/check-guides.mjs` (names in guides and references, imports real, size labels) |

## The rounds

All with Haiku on `app-locations` (a new app), 30 runs per arm, rules committed first.

| Skill | Successes | Mean cost | Mean turns |
| --- | --- | --- | --- |
| Copies of the human guides (~37k words) | 21 of 30 | $0.28 | 53 |
| Recipe + cards, written for agents | 20 of 30 | $0.08 | 40 |
| Round 2: causes fixed, check script, recipe built in CI | 28 of 30 | $0.05 | 28 |

**Round 1** (the rewrite) changed how much agents read, not how often they failed. Its ten failed
builds: 1 formatting, 3 an untested branch, and 6 copied straight from the recipe: a changeset
written after `</databaseChangeLog>` (2), a stale-version test whose first edit changed nothing so
the version never moved (2), one user signed in twice in a test (2). Earlier, on a grown app (the
dojo), the rewrite could not be judged: agents copied the nearest feature and most read no reference.

**Round 2** fixed each cause where it was copied from: the changeset shown inside its file, a full
test class that reaches both sides of the uniqueness check and edits a value before the stale edit,
one sign-in per address. It added `check.sh`, and `check-recipe.sh` so the recipe's code must pass
the template's 100% coverage gates in CI. Removing the own-name test from the recipe made
`check-recipe.sh` fail with "branches covered ratio is 0.50", exactly as five agent runs had.
Two failures remained: one run that skipped `check.sh` (formatting), one whose sandbox denied every
file read.

## What was not possible, and why it mattered

The eval sandbox had no Docker and refused a connection to a local PostgreSQL, so agents could
never run their Java tests. Every lesson above follows from that: failures were what agents could
not verify. A library whose users can test on an embedded database should let agents run tests in
the fixture; that removes a whole class of failures.
