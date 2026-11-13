# 0016. Attribute AI help with Assisted-by and Generated-by trailers, a human sign-off and a Co-Authored-By trailer

- **Status:** Accepted
- **Decided by:** @huwd
- **Decided:** 2026-11-13
- **Recorded:** 2026-11-13
- **Discussion:** the [commit-attribution research report](https://heios.github.io/research/2026-07-08/ai-commit-attribution/), read while setting up [huwd/immurok-nix](https://github.com/huwd/immurok-nix)

## Summary

AI agents help write most of the commits in this repository, so each commit says so.
`Assisted-by` and `Generated-by` trailers record how much the agent did, a human `Signed-off-by` records who is responsible, and a `Co-Authored-By` trailer makes GitHub show that an AI took part.
Keeping `Co-Authored-By` departs from the report that prompted this record, which advises against it for AI.
The departure is deliberate, and the other trailers take priority over it when they disagree.

## Context

An AI agent makes commits in this repository, and it adds a `Co-Authored-By` trailer by default.
A research report on commit attribution, written with an AI workflow and published in July 2026, compares the common trailers.
It recommends `Assisted-by: <tool>:<model>` for light help and `Generated-by: <tool>` for large pieces of output, with a human `Signed-off-by`.
It advises against `Co-Authored-By` for AI, because the trailer asserts equal authorship and an AI can't certify a sign-off.
It also says GitHub renders `Co-Authored-By`, and no other trailer, as a linked co-author.

The report is analysis, not a standard, and its legal points are its own reading.
The concerns here are narrower: readers of the history should see at once that an AI took part, and who answers for each change.

## Options considered

### Assisted-by or Generated-by, a human Signed-off-by, and Co-Authored-By (chosen)

The agent adds `Assisted-by` or `Generated-by` to every commit it helps with.
The maintainer signs off every commit.
`Co-Authored-By` stays, only so that GitHub shows the involvement.

The advantage is that the history says what happened in a form tools can read, and the web interface says it too.
The cost is three attribution lines on a commit, and a `Co-Authored-By` that read alone would suggest equal authorship.

### Follow the report: drop Co-Authored-By

The cleanest reading of the trailers, and the one the report recommends.
GitHub then shows nothing, so a reader browsing commits on the web has to open each message to find out that an AI helped.

### Keep only the default Co-Authored-By

No work to do, and GitHub shows it.
It records nothing about how much the agent did, and it implies equal authorship for a commit that the maintainer wrote almost entirely.

### Disclose in the pull request body only

Safe, and some projects require it.
It isn't machine-readable, and `git log` doesn't show it.

## Decision

Each commit made with an AI agent's help carries these trailers, in this order:

```text
Assisted-by: Claude Code:claude-sonnet-5-5
Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
Signed-off-by: Huw Diprose <mail@huwdiprose.co.uk>
```

- **Which tool trailer.** `Assisted-by: <tool>:<model>` applies when the maintainer did most of the work and the agent helped, for example by reviewing, suggesting or fixing.
  `Generated-by: <tool>:<model>` applies when the agent produced a large part from the prompts of the maintainer.
  How much the maintainer did, set against how much the agent produced from prompts, decides which one, and the agent states its choice when it commits.
- **Sign-off.** `Signed-off-by` names the maintainer, on every commit.
  The agent never writes its own `Signed-off-by` line.
  The line comes from the git configuration of the maintainer, through `git commit -s`, and the maintainer approves each commit when Bitwarden asks to sign it ([0009](0009-signed-commits-and-merge-commits.md)).
- **Co-Authored-By.** The trailer stays on every AI-assisted commit, purely because GitHub is the forge here and renders it.
  It doesn't claim equal authorship.
  Where it seems to conflict with `Assisted-by` or `Generated-by`, those two take priority.
- **Pull requests.** Descriptions keep the agent's generated-with line.
- **History.** Earlier commits aren't rewritten, because `main` doesn't allow it.

## Consequences

- `git log --grep='^Assisted-by'` and `--grep='^Generated-by'` find the commits.
- Choosing between the two needs judgement each time, and the line between them is unclear.
  Revisit the rule if it produces arbitrary results.
- `git commit -s` is now part of the commit command, and the sign-off is one more thing that the maintainer answers for.
- GitHub shows the AI as a co-author chip.
  If the maintainer ever cares about contribution credit or the hover text, this is the part to reconsider.
- Earlier commits carry `Co-Authored-By` only.
- Other repositories can adopt the same policy, and the skills repository has a note about a setup skill that would apply it.
