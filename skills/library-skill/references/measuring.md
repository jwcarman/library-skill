# Step 4: measure, with the rules written first

A skill that reads better can do no better: roux's first rewrite for agents scored 20 of 30 against
the copied guides' 21. Only a measurement says whether a change helped, and only if its rules were
fixed before any run, so the result cannot choose them.

## Rules

- **Write the rules first and commit them** (`PROTOCOL-template.md`): hypothesis, arms, cases,
  fixture commit, runs, scoring, the decision rule with its thresholds, what is reported besides.
  The commit's date proves they came first.
- **Two arms, interleaved.** No skill against the skill, or the old skill against the new. Alternate
  batches of 5 (A, B, A, B, ...), so a slow hour or a model change hits both. An arm compared with
  runs from earlier is a historical comparison: say so in the result.
- **~30 runs per arm** to show a change. 5–10 runs find failure modes but cannot tell 70% from 90%.
  Even 30 per arm detects 75% → 95% only about 60% of the time, so a null result is weak evidence of
  no effect, not proof.
- **Success = all hidden tests pass and the fixture's build passes** on the run's work as it stands.
- **Every run counts.** An error, a timeout or a run the sandbox broke is a failure. Never rerun,
  drop or replace one.
- **Report cost, turns and time** for both arms. Cost separated roux's arms when success did not
  (70% cheaper at equal success); a skill that only makes agents cheaper is still worth shipping.
- **A cheap model shows a skill's effect most**: it leans on the docs. roux measured with Haiku.

## The decision rule

One-sided Fisher's exact test on successes, `scripts/score.py`:

- **Supported:** the new arm succeeds more often, p < 0.05 (state the count that reaches it, e.g.
  "27 or more of 30 against 20 of 30"), at a mean cost no higher than a stated limit.
- **Refuted:** the old arm succeeds more often at p < 0.05, or a stated floor is missed.
- **Not shown:** anything else.

## Steps

1. Fill in and commit the protocol.
2. State the cost before running (a Haiku run on a small feature cost roux $0.05–$0.30).
3. Run: `scripts/run-evals.sh` (both arms, batches of 5, alternating). Check the first batch: every
   run loaded the arm's skill (and only that skill's files), the hidden tests ran, the scorer's count
   matches the log.
4. Score with `scripts/score.py`; classify every failure by cause, as in step 1.
5. Append the result to the protocol file: the table, the verdict by the rule, the failure causes,
   the caveats. Commit.
6. The failure causes left are the next round's step 1.

## Pitfalls

- Stopping early because the numbers look good: decide the run count first and run them all.
- Running the arms one after the other on different days: interleave, or call it historical.
- A shared fixture changed between arms: pin the fixture's commit in the protocol.
- Different plugin versions in one checkout: run the old arm from a git worktree at the old commit.
- Counting a run whose sandbox broke as "not the skill's fault" and dropping it: the rule decides,
  not the result.
