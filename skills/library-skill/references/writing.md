# Step 2: write a recipe and cards

The skill is read by an agent in the middle of a task, with a token budget, that will copy what it
sees. Write for that reader: what to do, in order, with the exact names, and examples that are right
when copied as they stand.

## Shape

```
skills/<library>/
  SKILL.md            # what the library is, conventions as one-line rules with reasons,
                      # "which reference" table with sizes, "before you finish" (run the check)
  references/
    <job>.md          # the recipe: the commonest job end to end
    <topic>.md        # one card per topic
  scripts/check.sh    # the agents' gate (step 3)
```

- **SKILL.md** ≤ ~1,200 words. Its index row for each reference says when to read it and its size:
  ``| A new resource, list or form | `references/feature.md` (~8,100 tokens): start here |``.
  A size lets the agent choose a whole read or a search before opening the file.
- **The recipe** (≤ ~4,000 words): the commonest job, every file in order, each as a complete
  file (package line, imports, the code, its tests), then the checks and the pitfalls. In roux,
  24 of 30 runs read the recipe and nothing else, so it carries everything the common job needs.
- **Cards** (≤ ~1,000 words each), one per topic, in one fixed order: purpose, rules, names, steps,
  example, check, pitfalls. One level deep: SKILL.md links every card; cards don't send the agent
  on to a third file for something the job needs.

## Rules

- **Every failure from step 1 is fixed where the agent copies from.** Most failures are the agent
  copying an example faithfully. roux's three: a changeset shown alone (agents appended it after
  the file's closing tag); a test that signed one user in twice (copied into every test); no test of
  a branch the coverage gate needed. The fix was the example, not a warning elsewhere.
- **Examples are complete and correct**, and proven by building them (step 3). An example missing an
  import costs one failed build per run that copies it.
- **Each rule says why**, in one clause: "do X: Y breaks when Z". An agent that knows the reason
  handles the case the rule did not foresee; a bare NEVER is followed or ignored blindly.
- **Exact names in backticks**: every public type and function, spelled as in the code, so the
  names check (step 3) can prove coverage and the agent can search for them.
- **Say the version** the skill covers and how the agent tells the project's version.
- **Tests in the recipe reach every branch** the project's gates need. If the library's users
  typically have a coverage gate, a recipe whose tests leave a branch uncovered fails it every time.
- **Write plainly.** Telegraphic shorthand saves little and costs accuracy; save tokens by structure
  (one recipe, small cards, sizes) not by dropping words.

## Steps

1. Pick the commonest job from the failure table's cases. Write it as the recipe, as complete files.
2. Write a card per topic the cases touched; leave out what the model already does right.
3. Write SKILL.md: what the library is in three sentences, the conventions as rules with reasons,
   the index with sizes, and "before you finish: run the check script".
4. Walk the failure table: point to the line in the skill that now prevents each cause.
5. Run the names check and the recipe build (step 3) before measuring.

## Check

- Every failure cause has a line in the skill, where the agent copies from.
- Every code block in the recipe is marked for the recipe build and builds.
- SKILL.md and each file are within budget; sizes in the index match the files.

## Pitfalls

- Condensing the human guides: roux did, and its first agent rewrite (20 of 30) did no better than
  the copied guides (21 of 30). Only fixing the measured causes raised it (28 of 30).
- An example "simplified" for reading, with types run together in one block without package lines:
  agents copy it into one file.
- A card that restates the recipe: two places to keep in step, and the agent reads both.
- A description padded with features: it is loaded in every session; keep it to what the library is,
  its package and import names, and the jobs it covers.
