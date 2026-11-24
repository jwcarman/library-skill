# Step 1: find the failures first

Before writing any of the skill, watch agents use the library without it and record exactly how they
fail. The skill exists to remove those failures. Without them you write what the agent already knows
(general Java, general React) and miss what it gets wrong (your names, your order of steps, your
build's gates).

## Rules

- **Tasks are what users ask for**, worded the way a user would ("add a paged, searchable list of
  customers"), not "use `Paginator`". Naming the API in the prompt hides whether the agent finds it.
- **Pin the contract the hidden tests check** in the prompt (paths, JSON shapes, status codes, field
  names, what a page shows). Otherwise a run fails for naming something differently, and you
  measure guessing, not the library.
- **Score by script, never by reading.** Success = every hidden acceptance test passes **and** the
  fixture's own build passes on the run's work, untouched. A reviewer reading a diff misses a build
  that fails on format, coverage or a stale generated file; roux's runs failed mostly there.
- **Hidden tests are hidden**: the agent never sees them; they are copied in after the run.
- **A run that errors, times out or does nothing is a failure.** Never rerun or drop it.

## The fixture app

A small public app that uses the library the way a user would, built and committed so each run starts
from the same state (its git history makes a run's changes a diff).

- **New, not grown, at least for one case.** In a grown app agents copy the nearest existing feature
  and barely read a skill; a new app is where the skill earns its keep.
- **Builds offline.** An eval sandbox has no network and no home directory: pre-fill the build's
  caches inside the fixture (Maven: a local repository in the fixture, pointed at by
  `.mvn/maven.config` or `jvm.config`; npm: a cache folder) and prove it with one offline build.
- **A test database agents can reach**, if the library allows one without Docker (H2, SQLite). roux's
  could not (PostgreSQL in Testcontainers), so its agents never ran their Java tests; that caused
  most of its failures. Use what users of the library really use, though: a fixture on H2 when users
  run PostgreSQL measures the wrong thing.
- **Public.** It ships with the library's evals; nothing private in it.

## Cases

2–3 cases, each one job a user brings, covering the library's main paths. A case is:

```
evals/<case>/
  case.yaml          # name, expected_outcome (what success is, for the report), scaffold script
  prompt.md          # the user's request + the pinned contract; frontmatter: max_turns, timeout, tools
  place-app.sh       # copies the fixture into the run directory
  acceptance/        # hidden tests, copied in after the run (API tests, browser tests)
  graders/           # optional: did the skill load (type: tool_used, tool: Skill)
```

roux's `app-locations` prompt, abridged: "Add a Locations page. The owner keeps the school's training
locations: each has a name (required, at most 40 characters, unique) and a kind ... Other code and
tests rely on this contract, so keep to it exactly: `GET /api/locations` answers every location as
`[{"id", "name", "kind", "version"}]`, sorted by name. ... A name that is refused (blank, too long,
or another location's) is a `400` whose problem details name the field `name`."

## Steps

1. Build the fixture; prove an offline build in a sandbox like the eval's (on macOS, `sandbox-exec`
   with the home directory unreadable and a proxy that refuses every request).
2. Write the cases and their hidden tests. Run the hidden tests against a correct solution you wrote,
   so a failure later means the run, not the test.
3. Run each case with **no skill**, 5–10 runs, a cheap model (Haiku): `scripts/run-evals.sh --ablation none`, scored with `score.py <out> 'b*'`.
4. Classify every failed run by its first cause: read the build log and the diff, not the agent's
   summary. Keep a table: cause, count, example run.
5. For each cause, decide where it is fixed: the recipe's example (most), a rule with its reason, a
   check script step (anything the agent could detect by running something), or the library itself
   (an API that invites the mistake; often the best fix).

## Check

- Every case has hidden tests that pass on a known-good solution and fail on the untouched fixture.
- The fixture builds offline in the sandbox.
- The failure table exists and every cause has a planned fix.

## Pitfalls

- Too few failures to learn from: the model may already be good. Try a cheaper model or a less
  common job before concluding the library needs no skill.
- A contract left unpinned: runs fail on a path or field name and look like library failures.
- Classifying by the agent's own explanation: it is often wrong about why its build failed.
- A contract that asks for something the library does not do (jpa-utils: whole-phrase search, where
  the library matches each word). Agents read the sources, see the difference, and write their own:
  the case then measures the prompt, not the library. Pin the library's behavior, and read a batch's
  diffs for "written by hand rather than with ..." before trusting its successes.
- An example value in the prompt is a contract too: `"2026-11-23T14:05:00Z"` taught one run to cut
  timestamps to whole seconds, which a hidden test then failed. Give examples in the form the tests
  accept.
- When nothing fails (jpa-utils: 19 of 20 on Haiku), the skill's measure is cost: count the tool
  calls spent reading the library's jar or sources per run; that is what a skill can save.
