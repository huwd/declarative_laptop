# 0000. Record decisions in lightweight decision records

- **Status:** Accepted
- **Decided by:** @huwd
- **Decided:** 2026-10-04
- **Recorded:** 2026-10-04
- **Discussion:** #50

## Summary

In the context of a personal NixOS configuration whose reasoning was
scattered across issues, PR descriptions, module comments and planning
documents, facing a growing number of choices nobody could explain from
the repository alone, the decision was for short Markdown decision records based
on Michael Nygard's format, with a one-line summary, the options
considered and two dates, and against both plain Nygard records and
heavier processes like MADR or RFCs, to achieve a durable "why" for each
significant choice, accepting the effort of writing records, many of them
after the fact.

## Context

By October 2026 this repository had made many deliberate choices: NixOS
itself, the disk layout, the CI model, how updates arrive, how commits
are signed. The reasoning behind them lived in several places, none of
them designed to last:

- issues with an agreed "Decisions" section, such as #39 and #54
- PR descriptions, such as #62 and #63
- comments in `.nix` modules
- planning documents (`OS.md`, `PLAN.md`) that mixed decisions with
  descriptions that had since gone stale

Issues and PRs close and sink out of sight. Planning documents rot as the
configuration changes underneath them. Module comments explain a line,
not the alternatives that lost. #50 set out to separate lasting decisions
from reference material, which needed somewhere for the decisions to go.

Most of these decisions are made by one person, working with AI coding
agents, and many have already been made. Whatever form the records take,
it must suit writing them after the fact, without a team to review them.

## Options considered

### Nygard records with three additions (chosen)

Michael Nygard's 2011 format: title, status, context, decision and
consequences, in a short Markdown file. To that, add:

- a one-sentence summary in Olaf Zimmermann's Y-statement form, so each
  record can be understood at a glance
- an "Options considered" section, taken from MADR, because the losing
  options are often the most useful part: ROCm against Vulkan in #39, or
  fixing the CI cache against dropping per-PR builds in #54
- separate "Decided" and "Recorded" dates, because many records are
  written after the fact, and a single date would make them look older
  than they are

It keeps Nygard's brevity and adds only what this repository's decisions
need.

### Plain Nygard records

The format #50 originally agreed. It is the most widely recognised and
the smallest. It has no place for rejected options, so they would either
be lost or crammed into "Context", and it can't show that a record was
written after the fact.

### MADR 4

"Markdown Any Decision Records": Nygard plus decision drivers, options
with pros and cons, a confirmation step, and metadata such as
deciders and consulted parties. Its rename from "Architectural" to "Any"
reflects that most decisions aren't architecture, which fits here. The
full template is built for teams, and filling in every section for a
one-person repository would make records slower to write without making
them more useful. Its options section is borrowed instead.

### RFCs or design documents

A proposal written and circulated *before* deciding. This repository
already has an equivalent: issues with an agreed "Decisions" section.
They do the proposing and discussing; a record captures the outcome. An
RFC process on top would duplicate the issues.

### No records

Keep relying on issues, PRs and comments. It costs nothing to start, but
it's what produced the problem: stale planning documents, and reasoning
that can only be found by someone who already knows where to look.

### Tooling such as adr-tools or log4brains

Generators and static sites for ADRs. #50 rejected them in keeping with
this repository's minimal-dependency approach. Plain Markdown files are
enough, and the documentation site planned in #51 can render them.

## Decision

Significant decisions are recorded as numbered Markdown files in
`docs/decisions/`, using [`template.md`](template.md): Nygard's sections,
plus a Y-statement summary, the options considered, and both a decided
and a recorded date.

Each record names who made the decision in a "Decided by" line, by GitHub
handle, and otherwise avoids personal pronouns. Anyone can propose a
record, and it reads the same whoever wrote it.

They're called **decision records**, not architecture decision records,
because many of them, such as how commits are signed or how dependency
updates arrive, are about process rather than architecture.

[`README.md`](README.md) in the same folder covers when and how to write
one, and indexes them. Issues remain the place where decisions are
discussed; each record links the issue or PR that led to it.

## Consequences

- Past decisions get retrospective records, with honest dates and links
  to where they were made.
- `OS.md` and `PLAN.md` can be retired once their decisions are recorded,
  leaving reference documents that only describe how things are.
- Changing a decision means writing a new record and marking the old one
  superseded, so the history of the reasoning stays readable.
- Changing this format means superseding this record. Practical guidance
  in the README can change freely.
- Records are more writing for each significant change. The "When to
  write one" section of the README exists to keep that effort for
  decisions that need it.
