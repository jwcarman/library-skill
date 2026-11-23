# <Library>'s skill: <what this measures> (written before it runs)

<!-- Fill in every <...>, commit this file, then run. Append the result below it afterwards; never
     edit the rules once a run has started. -->

**Hypothesis:** <the change> makes agents <succeed more often / succeed as often at lower cost> on
<the job>, because <the failure causes it fixes, from the baseline>.

- **Model:** <Haiku: a cheap model leans on the docs, so it shows a skill's effect most>.
- **Cases:** <case names>, each with <N> hidden tests.
- **Fixture:** <repository> at <commit> (pinned: the arms must start from the same app).
- **Arms:** <A: no skill / the old skill at <commit>, run from a git worktree> and <B: the skill at
  <commit>>, <30> runs each, alternating in batches of 5 (A first). Every run is reported; none is
  rerun, dropped or replaced. A run that errors, times out or does nothing is a failure.
- **Scoring:** a run succeeds when all <N> hidden tests pass and the fixture's build
  (<command>) passes on the run's work as it stands.
- **Cost:** about $<per run> a run, $<total> in all.

**Decision rule.** One-sided Fisher's exact test on successes (`score.py`):

- **Supported:** B succeeds more often, p < 0.05 (with A at its baseline of <a> of 30, that is
  <b> or more of 30), at a mean cost of at most $<limit>.
- **Refuted:** A succeeds more often, p < 0.05; or <a stated floor>.
- **Not shown:** anything else. With A near <rate>, 30 runs per arm detect a rise to <rate> about
  <power>% of the time, so a null result is weak evidence of no effect, not proof.

Secondary, reported for both arms: mean cost, turns and time; hidden tests and the build as separate
pass counts; which references each run read; whether it ran the check script; why each run failed.

<!-- After the run:

## Result: <what was measured>

| Arm | Successes | Hidden tests all passed | Build passed | Mean turns | Mean time | Mean cost |
|---|---|---|---|---|---|---|

**<Supported | Refuted | Not shown>.** <p values; cost; caveats, e.g. a historical comparison.>

Why runs failed: <table of causes and counts per arm>. -->
