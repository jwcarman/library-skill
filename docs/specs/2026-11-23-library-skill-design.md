# library-skill: a skill for writing a library's agent skill

## Intent

James maintains open-source libraries (roux, jpa-utils, who, mocapi). Each should ship a Claude Code
skill that helps coding agents *use* the library: build with it correctly, cheaply, first time.
roux's skill taught us how to make one that measurably works. This skill hands that method to an
agent working in any of James's libraries, so the next library's skill starts where roux's ended,
not where it began.

It is built locally (`~/IdeaProjects/library-skill`, shaped as a Claude Code plugin) and published
only after it has produced a skill that measures well in a second library: jpa-utils.

## What roux taught (the evidence)

From `roux/plugins/roux/evals/PROTOCOL.md`, Haiku on a new app, 30 runs per arm:

| roux skill | Successes | Mean cost |
|---|---|---|
| Copies of the human guides | 21 of 30 | $0.28 |
| Rewritten for agents (recipe + cards) | 20 of 30 | $0.08 |
| Round 2: failures fixed at their source | 28 of 30 | $0.05 |

- Agent-friendly wording cut cost 70% but did not raise success.
- Failures were not misunderstandings of the API. They were what the agent could not verify (no
  Docker in its sandbox) and what it copied from the skill's own examples (a changeset after the
  root element, a test that signed one address in twice, an untested branch).
- Round 2's gain came from three things: every example complete and correct, proven by building it
  in CI; a check script the agent runs; tests in the recipe that reach every branch the gates need.
- In a grown project agents copy the nearest existing code and barely read the skill. A skill earns
  its keep where there is nothing to copy.
- 5–10 runs find failure modes; showing a change takes ~30 runs per arm, rules written first.

## Goals

- An agent in a library's repository, asked to write or improve that library's skill, follows a
  measured process: baseline failures first, then recipe and cards, a check script, examples built
  in CI, then a pre-registered measurement.
- It brings tooling to adapt, not only advice: the checks are where roux's quality came from.
- Its first real use, jpa-utils' skill, beats no skill on a pre-registered measurement.

## Non-goals

- General skill-writing (structure, descriptions, triggering): `skill-creator` and
  `superpowers:writing-skills` cover that; this skill points to them.
- Skills for applications or workflows; this is for libraries that other code depends on.
- Languages beyond Java and TypeScript in the first version.

## Anti-goals

- **Assuming a project's tooling.** roux may assume its template (Spotless, 100% gates); a library's
  users bring their own build. Check scripts must find what a project has (formatter, coverage gate,
  test database) and say what they skipped, never report a skipped step as passed.
- Turning the library's human guides into the skill by condensing them (that was roux round 1).
- Claiming a skill works without a measurement.

## Approaches

1. **Its own plugin repo with the skill and adaptable scripts (chosen).** Installed once, used from
   any library; publishing is making the repo public. One more repo to keep.
2. A personal skill in `~/.claude/skills`: quickest, but tied to one machine and unpublishable as is.
3. Inside roux: wrong home; it would ship roux's assumptions with it.

James chose 1, local first, published once it proves out.

## Shape

```
library-skill/
  .claude-plugin/plugin.json
  skills/library-skill/
    SKILL.md                    # the process, in order, with the reason for each step
    references/
      baseline.md               # finding failures: tasks, fixture app, hidden tests, scoring
      writing.md                # recipe + cards, rules with reasons, size labels, one level deep
      checks.md                 # the check script and building the examples in CI
      measuring.md              # protocol template, run counts, Fisher's test, cost, caveats
      roux-example.md           # what roux did, with links, as the worked example
    scripts/                    # templates the agent copies into the library and adapts
      check-names.mjs           # every public name appears in the skill (Java + TS name lists)
      check-recipe.sh           # build the recipe's marked blocks into a fixture app, run its build
      check.sh                  # the agent's gate: detects the project's tools, runs what exists
      run-evals.sh, score.py    # interleaved arms, hidden tests + build, Fisher's exact test
      PROTOCOL-template.md
```

Each script is generalized from roux's (`check-guides.mjs`, `check-recipe.sh`, `check.sh`,
`run-evals.sh`, the scoring script) with roux's specifics turned into marked places to adapt.

## Proving it: jpa-utils

jpa-utils is public, small (16 source files: `BaseEntity`, auditing, `PageSpec`/`PageDto`,
`Paginator`, `Searchable`/`MatchMode`, stable paging, property validation, web binding) and has
~5,000 words of human guides but no skill for its users.

1. With library-skill installed, an agent in jpa-utils writes its skill (in jpa-utils, e.g.
   `skills/jpa-utils/`, shipped with the library), its checks, and its eval cases.
2. The eval needs a small public fixture app that uses jpa-utils (Spring Boot + JPA), kept in the
   jpa-utils repository. roux's plain-stack fixture comes from a private repository and is not
   usable. 2–3 cases with hidden tests (e.g. a paged, sorted, searchable list endpoint; stable
   paging over a changing table; an auditable entity).
3. Baseline: Haiku, no skill, ~10 runs per case, to find the failures the skill must fix.
4. Measurement, rules written first: Haiku, no skill vs. the jpa-utils skill, 30 runs per arm.
   Success = hidden tests + the fixture's build.

library-skill is published when step 4 shows the skill better on success or on cost at equal
success, and James likes how it was to use.

## Constraints

- No star imports, no warning suppression, in anything it writes or ships.
- Only public repositories are changed (roux, jpa-utils); no private ones (noir-*).
- Token budget: Haiku for eval runs; state the cost of a measurement before running it.
- Commits only on request; jpa-utils changes go through its own CI and release process.

## Left to the builder

- Exact script interfaces and how each marks the places to adapt.
- The fixture app's shape and test database (jpa-utils tests use H2 and Testcontainers; H2 would let
  agents run tests without Docker, which roux's agents could not).
- The jpa-utils eval cases' exact wording and hidden tests.

## Calls to check

- The jpa-utils skill lives in the jpa-utils repository (as roux's lives in roux's), not in
  library-skill.
- The first version covers Java and TypeScript name lists only.
- Proof is one library (jpa-utils) before publishing, not two.
