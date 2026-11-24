# library-skill

A Claude Code plugin for writing, improving and measuring the agent skill a library ships for its
users. It is the method behind [roux](https://github.com/jwcarman/roux)'s skill, whose measured
success with Haiku rose from 20 to 28 of 30 runs at $0.05 a run: find agents' failures first, write
a recipe and cards, give agents a check script, build the examples in CI, and prove the result with
a measurement whose rules are written before it runs.

Its first use from scratch was [jpa-utils](https://github.com/jwcarman/jpa-utils)' skill: a baseline
showed Haiku already succeeded without one (19 of 20), so the skill was measured on cost instead,
and cut it by 36% and time by 30% at equal success (20 runs an arm, p < 0.001;
`plugins/jpa-utils/evals/PROTOCOL.md` there).

## Install

```bash
claude plugin marketplace add jwcarman/library-skill
claude plugin install library-skill@library-skill
```

Then, in a library's repository: "write a skill for this library's users".

## License

Apache-2.0
