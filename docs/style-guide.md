# Style guide

How to write documentation in this repository. It applies to every Markdown
file: the README, `docs/`, plans, ADRs and issue templates.

## Base standard

Follow the [GOV.UK style guide](https://www.gov.uk/guidance/style-guide) and
its advice on [writing for GOV.UK](https://www.gov.uk/guidance/content-design/writing-for-gov-uk).
In short:

- use plain English: short sentences, common words, the point first
- write to the reader as "you"
- use sentence case for headings
- use descriptive link text, never "click here"

This page only records where this repository adds to or differs from that
standard.

## Spelling

Use British English with `-ise` endings: organise, realise, colour,
behaviour, licence (noun), license (verb).

## Terminology

Write these names exactly as shown in prose. Inside code, use whatever the
command or file needs.

| Write | Not | Notes |
| ----- | --- | ----- |
| NixOS | `Nixos`, `nixos` | `nixos-rebuild`, `nixos-config` in code are fine |
| Nix | `nix` | The language and package manager; `nix build` in code |
| Nixpkgs | `nixpkgs` | The package collection; `nixpkgs` when it means the flake input |
| Home Manager | `home-manager` | `home-manager` is the command and module name |
| GitHub | `Github`, `github` | |
| Wi-Fi | `WiFi`, `wifi` | |
| Flatpak, Ryzen, Radeon, NVMe, PCIe | lower case | Product names keep their own capitalisation |

### Nix concepts

Use these terms consistently and with these meanings.

| Term | Meaning |
| ---- | ------- |
| flake | The repository's `flake.nix` and everything it describes |
| flake input | A dependency declared in `flake.nix` `inputs`, such as `nixpkgs` or `home-manager` |
| `flake.lock` | The committed file pinning every flake input to an exact revision |
| derivation | A build recipe that Nix evaluates and realises into a store path |
| store path | An immutable path under `/nix/store` |
| closure | A store path plus everything it depends on; "the system closure" is the whole built system |
| generation | One numbered, bootable system (or Home Manager) configuration; switching creates a new one |
| rebuild, apply | Build the configuration and switch to it (`just apply`); prefer "apply" when talking about this repository's workflow |

## Markdown

- Give every fenced code block a language: `bash` for commands, `nix` for
  Nix, `text` for diagrams, trees and output.
- Wrap bare URLs in `<...>` or give them link text.
- Don't hard-wrap prose to a fixed width, and don't align table pipes. Both
  are optional and only make diffs noisier.
- Repeat a heading only under different parents, such as an "Experiments"
  section in each phase of a plan.

## Decision records

Significant decisions are recorded in [`docs/decisions/`](decisions/README.md).
Its README covers when to write one and how, and includes a template.

## Checking your work

```bash
just docs-lint                  # Markdown structure — runs in CI and `just check`
just docs-prose [files...]      # spelling and style — local only, advisory
```

`just docs-lint` must pass. For `just docs-prose`:

- fix every error (spelling, terminology)
- treat warnings (passive voice, wordiness) as prompts to reconsider, not
  rules — leave the text alone if the change wouldn't make it clearer
- add genuine project terms to
  `.vale/styles/config/vocabularies/House/accept.txt`; use `(?i)` for
  ordinary words, and leave product names case-sensitive so their
  capitalisation is checked

Rule configuration lives in `.markdownlint-cli2.jsonc`, `.vale.ini` and
`.vale/styles/`.
