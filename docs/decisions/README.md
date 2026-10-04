# Decision records

Significant decisions about this repository, one per file, with the context
and the options that lost. [0000](0000-record-decisions.md) explains why
they exist and why they take this form.

## When to write one

Write a record when a decision:

- is costly or awkward to reverse, such as the filesystem layout or the CI
  model
- chooses between real alternatives, and the losing options are worth
  remembering
- would leave a future reader asking "why is it like this?"

Routine changes don't need one. When unsure, ask whether the reasoning
would otherwise only live in a closed issue or a PR description.

## How to write one

1. Copy [`template.md`](template.md) to `NNNN-short-slug.md`, using the next
   free number.
2. Fill in every section. The summary is one sentence in the
   [Y-statement](https://medium.com/olzzio/y-statements-10eb07b5a177) form.
3. List the options that lost and why. This is often the most useful part.
4. Link the discussion. Issues with an agreed "Decisions" section are this
   repository's proposals, so the record links to them rather than
   repeating the debate.
5. Add the record to the index below, then check it with `just docs-lint`
   and `just docs-prose`.

### Voice

Name the people who made the decision in the "Decided by" line, by GitHub
handle, such as @huwd. Elsewhere, avoid personal pronouns: write "the
decision was", "this repository" or "the configuration", not "I" or "we".
Anyone can propose a record, and it should read the same whoever wrote it.

### Dates

**Decided** is when the decision was made; **Recorded** is when the record
was written. Many records here were written after the fact. Give both
dates, so a record never appears older than it is.

### Status

| Status | Meaning |
| ------ | ------- |
| Proposed | Written, not yet agreed |
| Accepted | In effect |
| Deprecated | No longer applies, and nothing replaced it |
| Superseded by NNNN | Replaced by a later record |

Don't rewrite an accepted record when a decision changes. Write a new
record, set the old one's status to "Superseded by" with a link, and leave
the rest of it as it was. Fixing typos and broken links is fine.

## Index

| Number | Decision | Status |
| ------ | -------- | ------ |
| [0000](0000-record-decisions.md) | Record decisions in lightweight decision records | Accepted |
| [0001](0001-why-this-project.md) | Build the laptops declaratively with NixOS, in public, as a way to learn | Accepted |
| [0002](0002-track-nixos-unstable.md) | Track nixos-unstable, and move versions only through flake.lock | Accepted |
| [0003](0003-home-manager-as-nixos-module.md) | Run Home Manager as a NixOS module, not standalone | Accepted |
