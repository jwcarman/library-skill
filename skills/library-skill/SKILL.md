---
name: library-skill
description: Writes, improves and measures the Claude Code skill a library ships for the agents that use it (Java or TypeScript). Use it when asked to write a skill for a library's users, make a library agent-friendly, fix an existing library skill, or evaluate whether a library's skill helps.
---

# Writing a library's skill

A library's skill is for agents *using* the library in someone's project: it exists to make them
build correctly, first time, at low cost. It is not the library's contributor guide (`AGENTS.md`)
and not its human guides condensed. General skill writing (structure, frontmatter, triggering) is
`skill-creator`'s job; this skill is the method that made one measurably work.

## Why this method

roux's skill, Haiku on a new app, 30 runs each, rules written before each run:

| roux skill | Successes | Mean cost |
| --- | --- | --- |
| The human guides, copied | 21 of 30 | $0.28 |
| Rewritten for agents (recipe + cards) | 20 of 30 | $0.08 |
| Failures fixed at their source | 28 of 30 | $0.05 |

Wording for agents cut cost 70% but not failures. Failures came from what agents could not check
(their sandbox had no Docker) and what they copied from the skill's own examples. The jump to 28 came
from complete, CI-built examples, tests in the recipe that reach every branch, and a check script.
Details and file paths: `references/roux-example.md` (~900 tokens).

## The process

Do the steps in order; each has a reference. Read it before the step.

1. **Find the failures first.** Build a small public fixture app that uses the library the way a
   user would, write 2–3 tasks with hidden acceptance tests, and run them with no skill (5–10 runs
   each, a cheap model). Classify every failure by cause. The skill exists to fix these; without
   them you will write what the agent already knows. `references/baseline.md` (~1,200 tokens)
2. **Write a recipe and cards.** One end-to-end recipe for the commonest job, with complete files
   (package, imports, tests), then one card per topic: rules with their reasons, exact names,
   steps, one example, a check, pitfalls. Agents copy examples literally, so every example must be
   correct, and every failure from step 1 must have its fix in the text an agent copies.
   `references/writing.md` (~1,000 tokens)
3. **Give agents checks, and check the skill.** Ship a script agents run before they finish (it
   finds the project's tools and runs what exists, in the order the build needs). Build the
   recipe's code into the fixture in CI, and check every public name appears in the skill.
   `references/checks.md` (~1,100 tokens)
4. **Measure, with the rules written first.** No skill against the skill (or old against new), ~30
   runs per arm, interleaved, scored by hidden tests plus the fixture's build. Commit the decision
   rule before any run; report every run. `references/measuring.md` (~800 tokens)

Then repeat 1–4 on what still fails. Stop when the measurement says the skill helps, or says the
change did not.

## Scripts

Copy them into the library (a `skill-tools/` or `scripts/` folder) and adapt every line marked
`ADAPT:`. Run them; you need not read them first.

| Script | Does |
| --- | --- |
| `scripts/check-names.mjs` | every public Java type and TS export appears in backticks in the docs you name |
| `scripts/check.sh` | the agents' gate: finds the build, formatter, generated files and frontend, runs what exists, lists what it skipped |
| `scripts/check-recipe.sh` | writes the recipe's marked blocks into a copy of the fixture and runs its build |
| `scripts/check-recipe-fragments.example.py` | how fragments (pieces of existing files) are put in place; roux's, to adapt |
| `scripts/run-evals.sh` | alternates two arms in batches around `claude plugin eval` and scores each run |
| `scripts/score.py` | successes, cost, turns, time per arm, and one-sided Fisher's exact p |
| `scripts/PROTOCOL-template.md` | the measurement's rules, to fill in and commit before running |

## Rules

- **Never assume the project's tooling.** Users bring their own build: a formatter, a coverage gate,
  Docker. A script that assumes one fails confusingly where it is missing; detect, run what exists,
  and say what was skipped, so a skipped step is never reported as passed.
- **The skill lives in the library's repository**, versioned and released with the code, so its names
  match the version an agent installs.
- **State the version it covers** in the skill, and how to tell the project's version.
- **Don't trust a skill you haven't measured.** A rewrite that reads better can do no better; roux's
  first rewrite did not.
- **Keep the names check and the recipe build in CI**, so a renamed API breaks the build, not the
  agents.
- **Never suppress warnings; no star imports**, in anything the skill shows or ships.

## Pitfalls

- Starting from the human guides: the skill comes out long and aimed at nothing.
- An example that is right in spirit but missing an import, a package line or a test: agents copy it
  and fail the build.
- Judging by reading the output: score with hidden tests and the real build.
- Too few runs: 5–10 find failure modes; showing a change takes ~30 per arm.
- Measuring only in a grown project: agents there copy the nearest code and barely read the skill.
  Include a new-project case.
