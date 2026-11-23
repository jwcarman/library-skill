# library-skill

A Claude Code plugin for writing, improving and measuring the agent skill a library ships for its
users. It is the method behind [roux](https://github.com/jwcarman/roux)'s skill, whose measured
success with Haiku rose from 20 to 28 of 30 runs at $0.05 a run: find agents' failures first, write
a recipe and cards, give agents a check script, build the examples in CI, and prove the result with
a measurement whose rules are written before it runs.

## Install (local)

```bash
claude plugin marketplace add ~/IdeaProjects/library-skill
claude plugin install library-skill@library-skill
```

Then, in a library's repository: "write a skill for this library's users".

## License

Apache-2.0
