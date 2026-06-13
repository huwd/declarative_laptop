# Learning Plan: NixOS for an Experienced Ubuntu User

You know Linux well. The shell, systemd, networking, filesystems — none of that
needs re-learning. What's new is the Nix ecosystem: a different way of thinking
about packages, configuration, and reproducibility.

Expect a 2–4 week adjustment period before things feel fluent. The rough edges
are real but finite.

---

## Mental Model Shift

The core thing to internalise before anything else:

> **Nix is not a package manager. It is a build system that happens to manage
> packages.**

Every package, every config file, every system service is the output of a
*derivation* — a pure function from inputs to outputs. The same inputs always
produce the same output. This is why builds are reproducible.

Consequences you will keep bumping into:

- You cannot install a `.deb` or run `./configure && make install` and have
  it work — FHS assumptions break. Use `nix-ld` for pre-compiled binaries.
- `which python` may return nothing even if Python is "installed" — it may
  live in a dev shell, not your PATH.
- Editing a file under `/nix/store` is not possible — the store is read-only.
  To change something, change its derivation and rebuild.

---

## Stage 1: The Nix Language

**Goal:** read and write basic `.nix` files without reaching for docs every
five minutes.

Nix is a pure, lazy, dynamically typed functional language. It has a small
surface area. The weirdness comes from what is absent (no statements, no
mutation, no loops) rather than what is present.

### Key concepts

| Concept | What it is |
|---------|-----------|
| Attribute set | `{ key = value; }` — the fundamental data structure |
| `let ... in` | local bindings |
| `with pkgs;` | bring an attrset's keys into scope (use sparingly) |
| String interpolation | `"hello ${name}"` |
| `import ./file.nix` | evaluate a .nix file and return its value |
| `pkgs.lib.*` | standard library functions (map, filter, strings, etc.) |
| `rec { }` | recursive attrset — keys can reference each other |

### Resources

- **nix.dev** — the canonical learning resource; start with "Nix language
  basics"
- **Nix Pills** — longer, builds from first principles; useful for internalising
  the derivation model
- `nix repl` — interactive REPL; invaluable for exploration:
  ```bash
  nix repl
  :l <nixpkgs>           # load nixpkgs into scope
  pkgs.git               # inspect a derivation
  pkgs.lib.strings       # explore the stdlib
  ```

### Experiments

- Write a derivation that produces a simple shell script
- Use `nix-instantiate --eval` to evaluate expressions from the command line
- Explore `pkgs.lib` in `nix repl` — `pkgs.lib.strings.toUpper "hello"`

---

## Stage 2: Flakes

**Goal:** understand what a flake is, what `flake.nix` and `flake.lock` do,
and be comfortable updating inputs.

Flakes are the modern (and correct) way to structure Nix projects. They solve
hermetic inputs: every dependency is pinned in `flake.lock`.

### Key concepts

| Concept | What it is |
|---------|-----------|
| `inputs` | external dependencies (nixpkgs, home-manager, etc.) |
| `outputs` | what this flake produces (NixOS configs, packages, shells) |
| `flake.lock` | auto-generated; pins exact git revisions of all inputs |
| `nix flake update` | update all inputs to their latest revisions |
| `nix flake update nixpkgs` | update a single input |

### The outputs schema

```nix
outputs = { self, nixpkgs, ... }: {
  nixosConfigurations.hostname = ...;   # nixos-rebuild reads this
  homeConfigurations."user@host" = ...; # home-manager reads this
  devShells.x86_64-linux.default = ...; # nix develop reads this
  packages.x86_64-linux.foo = ...;      # nix build reads this
};
```

### Experiments

- `nix flake show github:NixOS/nixpkgs` — explore nixpkgs' outputs
- `nix flake metadata` — see what inputs your flake has and their versions
- Update a single input and observe `flake.lock` change
- `nix flake check` — validates your flake structure

---

## Stage 3: NixOS Modules

**Goal:** understand how NixOS configuration composes, and be able to write
your own modules.

The NixOS module system is how configuration is structured. Every `.nix` file
in your config is a module. Modules declare *options* and set *config* values.
The system merges them all into one final evaluated config.

### Key concepts

| Concept | What it is |
|---------|-----------|
| `options` | declare what configuration keys a module accepts |
| `config` | set values — what actually configures the system |
| `imports` | pull in other modules |
| `mkIf` | conditional config |
| `mkMerge` | merge multiple config attrsets |
| `mkOption` | declare a new option with type and default |

### Reading existing modules

The NixOS source is your best reference. When you see `services.nginx.enable`,
find its definition:

```bash
nix-instantiate --eval -E '(import <nixpkgs/nixos> {}).options.services.nginx' \
  --json | jq
# or just read:
# https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/web-servers/nginx/
```

NixOS search (search.nixos.org) shows all options with descriptions — use it
constantly.

### Experiments

- Write a module that toggles some configuration on or off via a boolean option
- Add a custom system package list in a module and import it
- Use `mkIf config.myModule.enable` to make a service conditional

---

## Stage 4: Home Manager

**Goal:** manage your entire user environment declaratively.

Home Manager is home-manager — it does for your `~` what NixOS does for `/`.
Shell config, dotfiles, editor config, user packages, `~/.config/*` — all
declared in Nix.

### What it replaces

| Old way | Home Manager way |
|---------|-----------------|
| `cp dotfiles/.zshrc ~/.zshrc` | `programs.zsh.initExtra = "..."` |
| `pip install --user` | `home.packages = [ pkgs.python3 ]` |
| manually editing `~/.gitconfig` | `programs.git = { ... }` |
| Stow / chezmoi | Home Manager modules |

### Key programs with dedicated modules

`programs.git`, `programs.zsh`, `programs.fish`, `programs.neovim`,
`programs.tmux`, `programs.alacritty`, `programs.kitty`, `programs.direnv`,
`programs.starship`, `programs.ssh`.

Each module accepts structured config rather than raw dotfile content — the
module generates the correct dotfile format.

### Experiments

- Migrate your `.gitconfig` to `programs.git` in Home Manager
- Declare your shell aliases in `programs.zsh.shellAliases`
- Add neovim config via `programs.neovim.extraConfig`
- Set `programs.direnv.enable = true` and observe `.envrc` auto-activation

---

## Stage 5: Dev Environments

**Goal:** replace rbenv / pyenv / nvm / asdf with per-project nix shells.

### `nix develop`

A project with a `flake.nix` exposing a `devShells.default` gets:

```bash
cd my-project
nix develop    # drops into a shell with project tools available
ruby --version # project's pinned Ruby
exit
ruby --version # command not found
```

### `devenv`

A higher-level wrapper for dev shells. Recommended for projects with services
(databases, queues) as well as language toolchains:

```nix
# devenv.nix
{ pkgs, ... }: {
  languages.ruby.enable = true;
  languages.ruby.version = "3.3.0";

  services.postgres.enable = true;

  scripts.test.exec = "bundle exec rspec";
}
```

```bash
devenv shell     # enter the shell
devenv up        # start services (Postgres, etc.)
```

### `direnv` auto-activation

With `programs.direnv.enable = true` in Home Manager:

```bash
# .envrc in project root:
use flake      # or: use devenv
```

Now `cd project` activates the shell automatically. No manual `nix develop`.

### Experiments

- Create a simple `flake.nix` with a `devShells.default` for a language you use
- Replace your global `rbenv` Ruby with a per-project `devenv.nix`
- Add `direnv` auto-activation to an existing project

---

## Stage 6: Secrets Management with agenix

**Goal:** store encrypted secrets in the config repo safely.

agenix encrypts secrets with `age` public keys (your SSH public key or a
dedicated age key). Decryption happens at system activation using the host's
SSH host key.

### How it works

```nix
# secrets/secrets.nix — declares who can decrypt what
let
  huw = "ssh-ed25519 AAAA...";       # your personal key
  framework13 = "ssh-ed25519 AAAA..."; # host's /etc/ssh/ssh_host_ed25519_key.pub
in {
  "github-token.age".publicKeys = [ huw framework13 ];
  "wifi-home.age".publicKeys = [ huw framework13 ];
}
```

```bash
# Create/edit a secret
agenix -e github-token.age -i ~/.ssh/id_ed25519
```

The `.age` file is committed. The private key never is.

### Experiments

- Encrypt a test secret and commit it
- Reference it in a NixOS module via `age.secrets.my-secret.file`
- Verify it decrypts correctly on `nixos-rebuild switch`

---

## Stage 7: Debugging and Introspection

The tools that save you when things go wrong.

| Tool | What it does |
|------|-------------|
| `nix repl` | Interactive evaluation; load your flake with `:lf .` |
| `nix why-depends` | Why is package X pulling in package Y? |
| `nix-tree` | Visual TUI of the dependency closure |
| `nix path-info -r` | List all paths in a closure |
| `journalctl -b` | Same as Ubuntu — NixOS uses systemd |
| `nixos-rebuild dry-run` | Show what would change without applying |
| `nix store diff-closures` | Diff two system generations |
| `nix doctor` | Sanity check your Nix install |

### Finding packages

```bash
nix search nixpkgs ripgrep         # search by name
nix-locate bin/rg                  # find package providing a binary (needs nix-index)
```

### Understanding build failures

Nix error messages are verbose and often point to the wrong line. Strategies:

1. Read the last 20 lines of the error — the actual failure is usually there
2. `nix build --keep-failed` — preserves the failed build directory for inspection
3. `nix log /nix/store/...-foo.drv` — view full build log
4. Reduce: comment out parts of your config until it builds, then add back

---

## Stage 8: Stretch Topics

Once the above feels natural, these are worth exploring:

### Secure Boot with lanzaboote

Replace the standard NixOS bootloader with one that participates in UEFI
Secure Boot, with keys you control. Intermediate difficulty; good for a
security-focused setup.

### Overlays and overrides

Patch or override upstream packages:

```nix
nixpkgs.overlays = [(final: prev: {
  my-patched-tool = prev.some-tool.overrideAttrs (old: {
    patches = old.patches ++ [ ./my-fix.patch ];
  });
})];
```

### NixOS containers and VMs

`nixos-container` for lightweight system containers. `nixos-rebuild build-vm`
to spin up a VM of your config for testing — invaluable before applying
risky changes.

### Cross-machine deployment with deploy-rs or nixos-anywhere

If you ever add a second machine (home server, VPS), `deploy-rs` lets you
push NixOS configs to remote hosts from your laptop. `nixos-anywhere` installs
NixOS on a remote machine over SSH.

### Impermanence

A pattern where `/` is a tmpfs that is wiped on each boot. Only explicitly
declared paths (home dir, secrets, state) persist. Forces you to be honest
about what state your system actually needs. Advanced but philosophically
aligned with the NixOS ethos.

---

## Suggested Progression

| Week | Focus |
|------|-------|
| 1 | Nix language (`nix repl`, nix.dev tutorials). Get a basic flake building. |
| 2 | NixOS modules. Stand up GNOME. Get Home Manager managing your shell. |
| 3 | Migrate dotfiles to Home Manager. Set up agenix. First full rebuild from scratch on the real hardware. |
| 4 | Dev shells for 2–3 real projects. Wire up CI. First `vulnix` scan. |
| ongoing | Overlays when you hit a package that needs patching. Secure Boot. Impermanence. |

---

## Reference Bookmarks

| Resource | URL |
|----------|-----|
| Nix language basics | https://nix.dev/tutorials/nix-language |
| NixOS option search | https://search.nixos.org/options |
| Nixpkgs package search | https://search.nixos.org/packages |
| Home Manager options | https://nix-community.github.io/home-manager/options.xhtml |
| nixos-hardware | https://github.com/NixOS/nixos-hardware |
| devenv docs | https://devenv.sh |
| agenix | https://github.com/ryantm/agenix |
| Framework Linux community | https://community.frame.work/c/framework-laptop/linux |
| NixOS Discourse | https://discourse.nixos.org |
