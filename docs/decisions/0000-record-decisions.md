# 0000. Record decisions in lightweight decision records

- **Status:** Accepted
- **Decided by:** @huwd
- **Decided:** 2026-10-04
- **Recorded:** 2026-10-04
- **Discussion:** [#50](https://github.com/huwd/declarative_laptop/issues/50)

## Summary

Record significant choices in short Markdown files so their reasons remain easy to find as the configuration changes.
Each record explains the choice, the alternatives considered and when the decision took place.
This adds some writing for each significant change, but keeps the reasoning alongside the configuration it explains.

## Context

By October 2026 this repository had made many deliberate choices: NixOS itself, the disk layout, the CI model, dependency updates and commit signing.
The reasoning behind them lived in:

- issues with an agreed "Decisions" section, such as [#39](https://github.com/huwd/declarative_laptop/issues/39) and [#54](https://github.com/huwd/declarative_laptop/issues/54)
- PR descriptions, such as [#62](https://github.com/huwd/declarative_laptop/pull/62) and [#63](https://github.com/huwd/declarative_laptop/pull/63)
- comments in `.nix` modules
- planning documents (`OS.md`, `PLAN.md`) that mixed decisions with descriptions that had since gone stale

Issues and PRs close and sink out of sight.
Planning documents become outdated as the configuration changes.
Module comments explain a line, not the alternatives that lost.
[#50](https://github.com/huwd/declarative_laptop/issues/50) set out to separate lasting decisions from reference material, which needed somewhere for the decisions to go.

One person, working with AI coding agents, makes most decisions.
Many records will document past decisions.
Whatever form the records take, it must suit writing them after the fact, without a team to review them.

## Options considered

The choice covers the record format, how records relate to proposals and whether to use dedicated tooling.
The options below address these parts of the decision.

### Nygard records with three additions (chosen)

Michael Nygard's 2011 format: title, status, context, decision and consequences, in a short Markdown file.
To that, add:

- a short, plain-language summary to help readers understand each decision quickly
- an "Options considered" section, taken from MADR, because the losing options are often the most useful part: ROCm against Vulkan in [#39](https://github.com/huwd/declarative_laptop/issues/39), or fixing the CI cache against dropping per-PR builds in [#54](https://github.com/huwd/declarative_laptop/issues/54)
- separate "Decided" and "Recorded" dates, because many records document past decisions and readers need to distinguish the decision date from the recording date

It keeps Nygard's brevity and adds only what this repository's decisions need.

### Plain Nygard records

The format [#50](https://github.com/huwd/declarative_laptop/issues/50) originally agreed.
Its standard sections do not include rejected options, so the author would need to include them in the context section or leave them out.
Its standard template also does not distinguish the decision date from the recording date.

### MADR 4

"Markdown Any Decision Records": Nygard plus decision drivers, options with pros and cons, a confirmation step, and metadata such as deciders and consulted parties.
Its rename from "Architectural" to "Any" reflects that most decisions aren't architecture, which fits here.
The full template serves teams, and filling in every section for a one-person repository would make records slower to write without making them more useful.
This format borrows its options section instead.

### RFCs or design documents

A proposal written and circulated *before* deciding.
Issues with an agreed "Decisions" section already serve that purpose in this repository.
They do the proposing and discussing; a record captures the outcome.
An RFC process on top would duplicate the issues.

### No records

Keep relying on issues, PRs and comments.
It costs nothing to start, but it's what produced the problem: stale planning documents, and reasoning that readers can find only if they already know where to look.

### Tooling such as adr-tools or log4brains

Generators and static sites for ADRs.
[#50](https://github.com/huwd/declarative_laptop/issues/50) rejected them in keeping with this repository's minimal-dependency approach.
Plain Markdown files are enough, and the documentation site planned in [#51](https://github.com/huwd/declarative_laptop/issues/51) can render them.

## Decision

Record significant decisions as numbered Markdown files in `docs/decisions/`, using [`template.md`](template.md): Nygard's sections, plus a short, plain-language summary, the options considered, and both a decided and a recorded date.

Each record names who made the decision in a "Decided by" line, by GitHub handle, and otherwise avoids first-person pronouns ("I" and "we").
Anyone can propose a record, and it reads the same whoever wrote it.

They're called **decision records**, not architecture decision records, because many of them, such as commit signing or how dependency updates arrive, are about process rather than architecture.

[`README.md`](README.md) in the same folder covers when and how to write one, and indexes them.
Issues remain the place to discuss decisions; each record links the issue or PR that led to it.

## Consequences

- Past decisions get retrospective records, with separate decision and recording dates and links to the original discussions.
- The repository can retire `OS.md` and `PLAN.md` once decision records cover their choices, leaving reference documents that only describe how things are.
- Changing a decision means writing a new record and marking the old one superseded, so the history of the reasoning stays readable.
- Changes to the required sections or the role of records mean superseding this record.
  Records, templates and guidance can receive editorial improvements that preserve the decision and its reasoning.
- Records are more writing for each significant change.
  The "When to write one" section of the README exists to keep that effort for decisions that need it.
