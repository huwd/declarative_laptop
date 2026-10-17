# Operating the system

Commands for the day-to-day tasks that the other guides don't cover: rolling back, listing generations, and checking an earlier configuration for a vulnerability.
[The README](../README.md) covers applying and updating the configuration.

## Roll back

Every `just apply` creates a new generation.
If a change breaks something, switch back to the previous generation:

```bash
sudo nixos-rebuild switch --rollback
```

If the system doesn't boot, choose an earlier generation in the systemd-boot menu.
The boot menu keeps the 20 most recent generations (`configurationLimit` in `hosts/framework-13/configuration.nix`).

Rolling back restores the system configuration.
It doesn't undo changes to personal files or application data.

## List generations

```bash
nixos-rebuild list-generations
```

The garbage collector deletes generations older than 30 days each week.
See `nix.gc` in `hosts/framework-13/configuration.nix`.

## Dev secrets

Dev secrets are SOPS-encrypted files that `with-secrets` decrypts for one command at a time.
[0013](decisions/0013-derive-age-key-from-ssh-agent.md) explains the design.
Each call that decrypts asks the Bitwarden SSH agent for one signature.
The agent needs an unlocked vault, and with the recommended setting it asks you to approve each request.

### Set up

Do this once, after applying the configuration that installs the tools.

Create a dedicated Ed25519 SSH key in Bitwarden, named `sops-age`, and save its public half as `~/.ssh/sops-age.pub`.
Use this key for nothing else: don't add it to GitHub or `allowed_signers`.
Then create the recovery key on tmpfs, store it in Bitwarden, then delete the file:

```bash
age-keygen -o "$XDG_RUNTIME_DIR/recovery.txt"
```

Copy the whole file into a Bitwarden secure note called "SOPS recovery age key".
Note the public key (the `age1…` line), then delete the file:

```bash
shred -u "$XDG_RUNTIME_DIR/recovery.txt"
```

Compute the laptop recipient, which asks the agent for one signature:

```bash
sops-age-derive | age-keygen -y
```

Put both public keys in the `.sops.yaml` of the secrets repository and of each project:

```yaml
creation_rules:
  - path_regex: (^|/)[^/]*\.sops\.env$
    age: >-
      age1<laptop-recipient>,
      age1<recovery-recipient>
```

### Daily use

| Task | Command |
| ---- | ------- |
| Run a command with secrets | `with-secrets <command>` |
| Add or edit a secret | `secrets-edit <file>` |
| List the variable names in a file, without values | `grep -o '^[A-Z_]*=' <file>` |
| Inject only some variables | `with-secrets --only A,B -- <command>` |

By default, `with-secrets` decrypts `~/.secrets/dev.sops.env` and the `secrets.sops.env` at the root of the current git repository, with the project file winning.
It warns when either file is missing.

The two files layer rather than compete, so a project needs only the values that differ from the shared file.
Three options change that:

- `SECRETS_CENTRAL=<file>` replaces the shared file for that command, for example to use another checkout of the secrets repository.
- `-f <file>` (repeatable) replaces both defaults, and later files win.
- `--only A,B` injects just the named variables from whatever was decrypted.

It puts `sops`, `git` and `sops-age-derive` first on the `PATH` of the command that it runs.

Never run these tools under `set -x`, which prints the secrets.

A new file starts with example entries from SOPS: a comment and the keys `hello`, `example_key` and `example_multiline`.
Delete them when you first edit the file, because `with-secrets` would export them into every command.

`with-secrets` exports each value exactly as `sops decrypt` prints it.
That is fine for tokens and passwords, but a multi-line value, such as a PEM key, arrives with a literal `\n` where each line break was, and whatever reads it must convert them.

### Add, edit and remove secrets

Choose the file first:

| Where the secret is used | File |
| ------------------------ | ---- |
| By more than one project | `~/.secrets/dev.sops.env` |
| By one project only | `secrets.sops.env` at the root of that project's git repository |

When both files define a name, the project's value wins.
Every file must be called `*.sops.env`, which is what `.sops.yaml` matches to encrypt it to both recipients.

**Add or edit** a secret by opening the file:

```bash
secrets-edit ~/.secrets/dev.sops.env
```

Bitwarden asks you to approve the request, then your editor shows the decrypted content as one `NAME=value` line for each secret.
Add a line, or change the value on an existing one, then save and quit.
Names use letters, digits and underscores, and can't start with a digit.
If you quit without saving, nothing changes.

Check that a value was stored, without printing it:

```bash
with-secrets --only NAME sh -c 'test -n "$NAME" && echo set'
```

**Remove** a secret by opening the file in the same way and deleting its line.
To remove a whole file, delete it and commit the deletion.

Removing a secret doesn't undo an exposure.
Earlier commits of the encrypted file stay in git history, and both recipients can decrypt them.
If a secret has leaked, or you're retiring it, revoke or rotate it at the service that issued it.

Commit the encrypted file, never a plaintext `.env` file.
Before committing, check that the values in the file read `ENC[…]`:

```bash
grep -c 'ENC\[' <file>
```

### Scan for committed secrets

Encryption doesn't stop a plaintext file from being committed by mistake.
The laptop provides `betterleaks` for that ([0014](decisions/0014-betterleaks-as-secret-scanner.md)).
To check the staged changes of a repository, run this from its root:

```sh
betterleaks git --staged
```

The laptop doesn't run this for you.
Each project decides whether to call it from a hook or from CI.

### Add or remove a recipient

Edit `.sops.yaml`, then re-wrap each file:

```bash
sops updatekeys <file>
```

After removing a recipient, also replace the file's data key, because the removed recipient could still decrypt an old copy:

```bash
sops rotate -i <file>
```

### Recover after losing or rotating the dedicated key

Rotating the `sops-age` key changes the derived identity, and the old identity can no longer be derived.
Use the recovery key to re-wrap every file to the new one.

1. Read the recovery key from Bitwarden into a variable, without echoing it or saving it in shell history:

   ```bash
   read -rs SOPS_AGE_KEY && export SOPS_AGE_KEY
   ```

2. Compute the new laptop recipient with `sops-age-derive | age-keygen -y`, and replace the old one in `.sops.yaml`.
3. Re-wrap each file with `sops updatekeys <file>`.
4. Clear the variable:

   ```bash
   unset SOPS_AGE_KEY
   ```

Test this once end to end before relying on it.

## Check an earlier configuration for a vulnerability

The history of `flake.lock` records the dependency versions of every earlier configuration.
This answers "did CVE-YYYY-NNNNN affect the configuration on this date?", but it can't prove what was running on the laptop at the time.

Build the closure for an earlier commit without checking it out, then scan it with vulnix.
This is the scan that CI runs, including the mirror that replaces NVD's retired data feeds:

```bash
rev=<commit>
nix build "github:huwd/declarative_laptop/$rev#nixosConfigurations.framework-13.config.system.build.toplevel" \
  --no-link --print-out-paths > /tmp/old-closure
nix run nixpkgs#vulnix -- \
  --mirror https://vig-os.github.io/nvd-mirror/ \
  --closure "$(cat /tmp/old-closure)"
```

Leave out `--whitelist` to see every finding, including the ones that `vulnix.toml` accepts today.
[OPSEC.md](../OPSEC.md) explains what vulnix can and can't see.
