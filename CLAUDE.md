# Working in this repository

This project exists to learn NixOS ([0001](docs/decisions/0001-why-this-project.md)).
Agents help most by teaching, not by doing the work for the maintainer.

## Learning first

- Explain why a change is needed and what each part does, then give the exact commands.
  Let the maintainer type them, and check the result afterwards.
- Make the change directly only when the maintainer asks, for example "you can do this one" or "take the lead".
  Even then, explain what changed.
- Work through a backlog of judgement calls, such as "keep or drop this setting", differently.
  The value there is in the decision, so implement each choice as soon as it's made.
- Ask when the history or the code doesn't show why something is the way it is.
  Don't invent the reasoning, and say in the record when a reason is a recollection.

## Making changes

- Work on a branch, open a pull request, and merge it with a merge commit.
  Squash merges are not used, and neither is "rebase and merge", which breaks commit signatures.
- Commits and pushes are signed through Bitwarden, which asks the maintainer to approve each one.
  Warn the maintainer before committing or pushing.
- `main` requires a pull request and passing checks, and blocks force-pushes.
- Don't base a new branch on `main` while another branch that hasn't merged yet is applied to the running system, because applying from `main` would undo that branch.
  Stack the branches, or wait for the merge.
- `just apply` needs `sudo`, so ask the maintainer to run it.
- Run `just check` before committing.
  Don't pipe its output through `tail` or `head`, because that hides failures.
- Every entry in `vulnix.toml` needs a specific justification.
  Accepted real vulnerabilities also need an `until` date.

## Documentation

- Follow the [style guide](docs/style-guide.md), and run `just docs-lint` and `just docs-prose` on changed Markdown.
- Record significant decisions in [`docs/decisions/`](docs/decisions/README.md).
- Keep reference pages (how things work now) separate from decision records (why a choice was made).
