# Decision records

Significant decisions about this repository, one per file, with the context and the options that lost.
[0000](0000-record-decisions.md) explains why they exist and why they take this form.

## When to write one

Write a record when a decision:

- is costly or awkward to reverse, such as the filesystem layout or the CI model
- chooses between real alternatives, and the losing options are worth remembering
- would leave a future reader asking "why is it like this?"

Routine changes don't need one.
When unsure, ask whether the reasoning would otherwise only live in a closed issue or a PR description.

## How to write one

1. Copy [`template.md`](template.md) to `NNNN-short-slug.md`, using the next free number.
2. Fill in every section.
   Write a short, plain-language summary explaining the problem, the choice and why it matters.
3. List the options that lost and why.
   This is often the most useful part.
4. Link the discussion.
   Issues with an agreed "Decisions" section are this repository's proposals, so the record links to them rather than repeating the debate.
5. Add the record to the index below, then check it with `just docs-lint` and `just docs-prose`.

### Voice

Name the people who made the decision in the "Decided by" line, by GitHub handle, such as @huwd.
In records, avoid first-person pronouns ("I" and "we").
Use concrete subjects and verbs, such as "Home Manager manages user settings" or "CI builds each affected host".
Anyone can propose a record, and it should read the same whoever wrote it.

After writing the summary, check whether a reader could explain the choice and why it won.
Use the remaining sections to explain the circumstances, compare alternatives and describe the consequences, without repeating the summary in each section.

### Dates

**Decided** gives the date of the decision; **Recorded** gives the date of writing.
Many records here document past decisions.
Give both dates so readers can distinguish the decision date from the recording date.

### Status

| Status | Meaning |
| ------ | ------- |
| Proposed | Written, not yet agreed |
| Accepted | In effect |
| Deprecated | No longer applies, and nothing replaced it |
| Superseded by NNNN | Replaced by a later record |

Don't rewrite an accepted record when a decision changes.
Write a new record, set the old one's status to "Superseded by" with a link, and keep the rest unchanged.
Editorial improvements can include clearer wording, typo corrections and link fixes, provided they preserve the decision and its reasoning.

## Index

| Number | Decision | Status |
| ------ | -------- | ------ |
| [0000](0000-record-decisions.md) | Record decisions in lightweight decision records | Accepted |
| [0001](0001-why-this-project.md) | Build the laptops declaratively with NixOS, in public, as a way to learn | Accepted |
| [0002](0002-track-nixos-unstable.md) | Track nixos-unstable, and update pinned inputs through flake.lock | Accepted |
| [0003](0003-home-manager-as-nixos-module.md) | Apply Home Manager settings with the NixOS configuration | Accepted |
| [0004](0004-luks-btrfs-systemd-boot.md) | Encrypt system and user data with LUKS2, use btrfs, and boot with systemd-boot | Accepted |
| [0005](0005-build-full-closure-on-every-pr.md) | Build each affected host's full system closure on every pull request | Accepted |
| [0006](0006-enforce-vulnix-in-ci.md) | Fail CI on vulnerability findings unless a justified exception applies | Accepted |
| [0007](0007-dependabot-for-flake-inputs.md) | Use Dependabot for flake input updates, not a scheduled workflow | Accepted |
| [0008](0008-ci-without-write-access.md) | Keep repository-content write access out of CI and pin its tools | Accepted |
| [0009](0009-signed-commits-and-merge-commits.md) | Approve local signing through Bitwarden and preserve signed commits when merging | Accepted |
| [0010](0010-zellij-as-primary-multiplexer.md) | Use zellij as the primary terminal multiplexer | Accepted |
| [0011](0011-vulkan-for-local-inference.md) | Run local inference on the Vulkan backend rather than ROCm | Accepted |
