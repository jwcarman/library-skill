# library-skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A local Claude Code plugin whose skill walks an agent through writing a library's agent
skill the way roux's was made, with script templates generalized from roux's and proven on roux.

**Architecture:** A plugin repo: `SKILL.md` (the process), five references (one per phase plus the
roux example), and scripts the agent copies into a library and adapts. Every script is proven by
reproducing a roux result. This plan builds library-skill; proving it on jpa-utils is a second plan,
written with library-skill's own process once this one is done.

**Tech Stack:** Markdown, bash, Node (no dependencies), Python 3 (stdlib only), `claude plugin`.

**Spec:** `docs/specs/2026-11-23-library-skill-design.md`.

## Global Constraints

- Scripts must not assume a project's tooling: detect it, run what exists, report what was skipped,
  never report a skipped step as passed.
- Every place a library must adapt a script is marked `# ADAPT:` (or `// ADAPT:`) with what to change.
- SKILL.md ≤ 1,200 words; each reference ≤ ~1,200 words; each reference row in SKILL.md carries
  `(~N tokens)`.
- Rules carry their reason. No star imports and no warning suppression in anything shipped.
- First version: Java and TypeScript only.
- Only public repositories change. Nothing in roux changes in this plan (it is only read).

## Review Focus

1. `check.sh` in a project with none of the tools it knows (no Spotless, no frontend): it must pass
   on compile alone and list every skipped step.
2. `check-names.mjs` on a library with no skill yet: one clear line per missing name, exit 1.
3. `score.py` on a run that errored or produced no result files: counted as a failure, not dropped.
4. `check-recipe.sh` on a recipe with a block marked for a fragment it has no adapter for: fails
   naming the fragment, does not silently skip it.
5. SKILL.md's process followed in a library that already has human guides: it must say to start from
   measured failures, not from condensing the guides.

---

### Task 1: The plugin and its process

**Files:** Create `.claude-plugin/plugin.json`, `skills/library-skill/SKILL.md`, `README.md`.

- [ ] **Step 1:** `plugin.json` (name `library-skill`, description, version `0.1.0`, author James Carman).
- [ ] **Step 2:** SKILL.md: frontmatter description ≤ 60 words (triggers: "write/improve a skill for
  this library", "agent skill for users of a library", "eval a library's skill"); body = the process
  in order, each step with its reason and the reference that details it:
  1. Find failures first (baseline runs on a fixture app, hidden tests) — `references/baseline.md`.
  2. Write a recipe for the commonest job plus cards — `references/writing.md`.
  3. Give agents a check script and build the recipe's examples in CI — `references/checks.md`.
  4. Measure, rules written first — `references/measuring.md`.
  Plus: what this skill is not for (general skill writing → `skill-creator`), and the roux results
  table from the spec as the reason for the method.
- [ ] **Step 3:** `claude plugin validate .` → valid. Commit `feat: the plugin and its process`.

### Task 2: The references

**Files:** Create `skills/library-skill/references/{baseline,writing,checks,measuring,roux-example}.md`.

- [ ] **Step 1:** Each reference: purpose, rules (with reasons), steps, the roux example inline (short
  excerpts, not links alone), pitfalls. Content comes from the spec's "What roux taught" and roux's
  PROTOCOL.md; `roux-example.md` maps each step to roux's files (paths in jwcarman/roux) and results.
  - `baseline.md`: fixture app (public, small, uses the library like a user would; a test database
    agents can reach without Docker if the library allows), 2–3 cases with hidden acceptance tests,
    5–10 runs per case with no skill, failures classified by cause.
  - `writing.md`: recipe + cards, rules with reasons, examples are copied literally so must be
    complete and correct, names in backticks, size labels, references one level deep, what agents
    in grown projects do (copy nearest code).
  - `checks.md`: the agent's check script (detects tools; runs what exists; order the build needs),
    building recipe blocks in CI (`file:`/`files:`/`fragment:` markers), the names check.
  - `measuring.md`: protocol template use, interleaved arms, ~30 runs per arm, success = hidden tests
    + build, Fisher's exact one-sided, cost/turns/time, historical-comparison caveat, never rerun or
    drop a run.
- [ ] **Step 2:** Word counts within budget; SKILL.md rows carry `(~N tokens)`. Commit
  `docs: the references`.

### Task 3: `check-names.mjs`

**Files:** Create `skills/library-skill/scripts/check-names.mjs`, `scripts/test/check-names.test.sh`.

**Interfaces:** `node check-names.mjs <config.json>`; config:
`{ "java": ["<src/main/java dir>"...], "ts": ["<entry index.ts>"...], "exclude": [names],
"docs": ["<dir of .md>"...] }`. Exit 1 with `missing from <dir>: <name> (<file>)` per gap, else
`ok: N public names documented`.

- [ ] **Step 1:** Test: config for roux (its runtime modules, roux-web entries, its exclusions, docs =
  `docs/guides` and the skill's references) → expect `ok: 368`. Config for jpa-utils with docs = an
  empty dir → expect exit 1 and 16 `missing` lines. Run → fails (no script).
- [ ] **Step 2:** Write it, generalized from roux's `check-guides.mjs` (a)+(b); backtick scan on one
  line; `ADAPT:` at the config reading.
- [ ] **Step 3:** Test passes. Commit `feat: the names check`.

### Task 4: `check.sh`, the agent's gate

**Files:** Create `skills/library-skill/scripts/check.sh`, `scripts/test/check.test.sh`.

- [ ] **Step 1:** Test against copies of roux's eval app fixture (`fixture-app.local` path): as is →
  every step runs, `check: ok`; with Spotless and frontend-maven-plugin removed from the pom →
  `check: skipped formatting ...` and frontend run directly; with an uncovered frontend line → FAIL
  naming the file; with a changelog after its root → FAIL. Run → fails (no script).
- [ ] **Step 2:** Write it from roux's reverted detection version (roux commit f28c15b) with the
  roux-only step (PermissionsListTest) turned into an `ADAPT:` hook list ("generated files: the
  command that rewrites them"), Maven and Gradle detected (`./mvnw` or `./gradlew`), XML files to
  parse as an `ADAPT:` glob.
- [ ] **Step 3:** Tests pass. Commit `feat: the agent's check script`.

### Task 5: `check-recipe.sh`

**Files:** Create `skills/library-skill/scripts/check-recipe.sh`, `check-recipe-fragments.example.py`,
`scripts/test/check-recipe.test.sh`.

**Interfaces:** `check-recipe.sh <recipe.md> <fixture dir> <fragments.py> -- <build command>`; copies
the fixture to a temp dir, writes `file:`/`files:` blocks, calls `fragments.py <name> <block file>
<app dir>` for each `fragment:` (exit non-zero for an unknown name → the script fails naming it),
runs the build command there.

- [ ] **Step 1:** Test: roux's `feature.md` with a fragments file ported from roux's
  `check-recipe.sh` (changelog, roles, query-keys, nav, PermissionClasses) on a copy of roux's
  template → exit 0. Same with a fragment renamed in a copy of the recipe → exit 1 naming it.
  Run → fails (no script).
- [ ] **Step 2:** Write it; the example fragments file is the roux port, with `ADAPT:` notes.
- [ ] **Step 3:** Tests pass (the first needs Docker; ~4 min). Commit `feat: the recipe check`.

### Task 6: `run-evals.sh`, `score.py`, the protocol template

**Files:** Create `skills/library-skill/scripts/{run-evals.sh,score.py,PROTOCOL-template.md}`,
`scripts/test/score.test.sh`.

**Interfaces:** `score.py <results dir> <arm A glob> <arm B glob> [--cases N hidden tests]` prints per
arm n, successes, hidden, build, errors, mean cost/turns/time, and both one-sided Fisher p values.
`run-evals.sh` alternates arms in batches (`--runs`, `--model`, `--batches`) around
`claude plugin eval`, with `ADAPT:` hooks for the acceptance and build scorers.

- [ ] **Step 1:** Test: `score.py` on roux's Haiku results in this machine's scratchpad (rewrite vs
  round 2) → `20` vs `28`, `p = 0.0106`; on a copy with one run's result files deleted → that run
  counted as a failure. Run → fails.
- [ ] **Step 2:** Write them; `PROTOCOL-template.md` has hypothesis, arms, scoring, decision rule
  (with the run-count/power note), secondary measures, and the "written before it runs" line.
- [ ] **Step 3:** Tests pass. Commit `feat: running and scoring a measurement`.

### Task 7: Install locally and read-through

- [ ] **Step 1:** Add the repo as a local marketplace and install the plugin
  (`claude plugin marketplace add ~/IdeaProjects/library-skill`, then `claude plugin install`);
  in a fresh session in jpa-utils, "write a skill for this library's users" loads library-skill.
- [ ] **Step 2:** Sizes and labels hold; every `ADAPT:` names what to change; README says how to
  install locally. Commit `docs: install locally`. Then the jpa-utils plan, written with this skill.
