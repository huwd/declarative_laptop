# 0013. Derive the age key for dev secrets from an SSH-agent signature

- **Status:** Accepted
- **Decided by:** @huwd
- **Decided:** 2026-10-17
- **Recorded:** 2026-10-17
- **Discussion:** the secrets plan in the `composer` repository (`docs/SECRETS_PLAN.md`), which proposed the scheme, and [#99](https://github.com/huwd/declarative_laptop/pull/99), which adds the tools

## Summary

Dev secrets on the laptop stay encrypted at rest with SOPS and age, and Bitwarden's approval prompt gates their use.
An age key can't be unlocked by the SSH agent directly, so `sops-age-derive` signs a fixed challenge through the Bitwarden agent and turns the signature into an age identity.
The identity exists only in memory, for the length of one command.
This is a small piece of home-made key derivation, so the constants never change, a test pins the output, and the tool uses Python with a possible Rust rewrite later.
The signing key is a dedicated Ed25519 key that nothing else uses, so rotating or exposing the commit-signing key doesn't touch the secrets.
Anyone who obtains that key's private half can derive the same age key, so it must stay inside Bitwarden.

## Context

Development uses secrets such as API keys, access tokens and a NAS sudo password.
They had spread around the laptop as plaintext `.env` files and as a temporary file in `/tmp`, which is on disk and not on tmpfs.
The aim is to keep every dev secret encrypted at rest, make each use pass a Bitwarden approval, and inject the values into one command at a time.

The existing building blocks limit the options:

- SSH keys are held only in the Bitwarden desktop SSH agent, which already holds the commit-signing key ([0009](0009-signed-commits-and-merge-commits.md)).
  The private key is never on disk.
  The agent asks for approval when something requests a signature, and only while the vault is unlocked.
  Unlocking the vault needs the master password or a fingerprint.
  Bitwarden can also be set to approve requests automatically while the vault is unlocked.
- The agent protocol can only sign.
  It can't decrypt, so age can't use the agent as an identity.
- The Bitwarden CLI has no biometric unlock.
- The fingerprint reader works for polkit and sudo, and not for login.

Ed25519 signatures are deterministic: the same key and message always give the same signature.
Signing a fixed challenge through the agent therefore returns the same bytes each time, and each signature is a request that Bitwarden can put to the user for approval.

## Options considered

### Derive an age identity from an agent signature (chosen)

`sops-age-derive` asks `ssh-keygen -Y sign` to sign a fixed challenge in the namespace `sops-age-v1`.
The agent signs it, after asking for approval if Bitwarden is set to ask.
The tool extracts the raw 64-byte Ed25519 signature, runs it through HKDF-SHA256 with a fixed salt and info string, and encodes the 32-byte result as an age identity.
`with-secrets` passes that identity to SOPS in memory, and SOPS decrypts the files that the command needs.

The advantages:

- Nothing secret reaches the disk, and there is no extra password to remember.
- Each use can need an explicit Bitwarden approval, if the agent is set to ask for one every time.
- It uses a key that is already in Bitwarden.

The disadvantages:

- **The dedicated key becomes the root of trust.**
  Anyone who obtains its private half can derive the age key.
- **Rotating the dedicated key changes the derived identity.**
  The files must be re-wrapped with the recovery key.
- **The protection is only as strong as the Bitwarden approval setting.**
  If the vault is unlocked and Bitwarden approves requests automatically, any process running as the user can derive the age key without a prompt.
  Keep the agent set to ask for approval on every request, and treat a vault that stays unlocked as an open door to these secrets.
  The setting is global.
  Bitwarden has no per-key authorisation, so the dedicated key can't be given a stricter policy than the commit-signing key.
  A community feature request asks for one ([a Bitwarden community thread on per-key SSH agent settings](https://community.bitwarden.com/t/ssh-agent-per-key-authorization-customization/101029)), and on 2026-10-17 it had no commitment from Bitwarden.
  Loosening the global setting to cut the number of commit-signing prompts would loosen it for the secrets too.
- **The prompt doesn't say which command asked for the signature.**
  The approval dialog names the requesting program (`ssh-keygen`) and the key (`sops-age`), so an unexpected request for that key is recognisable.
  It doesn't show which command ran `ssh-keygen`, and a process running as the same user can run it too.
  The namespace stops a login challenge from being turned into this signature, but it doesn't help here.
  Defending against hostile local processes is out of scope.
- **It is home-made key derivation.**
  The derivation is short, versioned and tested, and uses only standard primitives (HKDF-SHA256, Ed25519 and bech32), but it hasn't had outside review.

### A plain age key on disk

The earlier plan kept an age key at `~/.config/sops/age/keys.txt`.
It is simple and standard, but the key is a plaintext secret that anything running as the user can read, which is the problem this decision aims to remove.

### A hardware token (YubiKey Bio or a TPM)

`age-plugin-fido2-hmac` with a YubiKey Bio, or a TPM with a PIN, would give a fingerprint-gated key without home-made derivation.
It needs hardware that isn't owned yet, or plugin support that nobody has verified.
It stays the intended successor: it can be added as a third recipient with `sops updatekeys`, and the derived identity can then be retired without touching any secret value.

### Reuse the commit-signing key

One key would mean one item to look after.
It would couple the secrets to the signing key, though: rotating the signing key would force a re-wrap of every file, and exposing the signing key would expose the secrets.
The signing key's public half is also published in `allowed_signers` and in git configuration, and an approval prompt for it looks the same as one for the secrets.
A dedicated key is quick to create in Bitwarden and costs nothing now, while no file is encrypted.

### SOPS or age using the SSH key directly

age can encrypt to SSH keys, but decrypting needs the private key as a file.
The agent can't supply it, and the private key never leaves Bitwarden.

### Language: bash for the derivation

Every step has a standard tool, but bech32 would need about 25 lines of shell arithmetic.
`openssl kdf` takes the key as a command-line argument, so the signature would be visible in `/proc/<pid>/cmdline`, which is readable by other users.
Python's `hmac` works in process.
`with-secrets` and `secrets-edit` stay in bash, and export secrets with the shell's `export` command, so that they never appear in the command-line arguments of any process.

## Decision

- `sops-age-derive` derives the identity as described above and is written in Python with only the standard library.
  It signs with a dedicated Ed25519 key, `~/.ssh/sops-age.pub` by default, that is used for nothing else.
  It is never added to GitHub or `allowed_signers`.
- Files are encrypted with SOPS to two age recipients: the derived laptop identity for daily use, and a recovery identity that is held only in Bitwarden.
- `with-secrets` runs a command with the decrypted values in its environment, and `secrets-edit` edits a file with the temporary file on tmpfs.
  Neither is ever run under `set -x`.
- The tools are packaged in [`packages/secrets-tools.nix`](../../packages/secrets-tools.nix).
  Their build runs the unit tests and `shellcheck`.
- The derivation constants (challenge, namespace, salt, info and key prefix) are a compatibility contract.
  The test in `packages/sops-age-derive/test_sops_age_derive.py` pins the output for a fixed input.
  A change to the derivation is a new version (`v2`) with a new recipient, never an edit to `v1`.

## Consequences

- Dev secrets are encrypted at rest and decrypt only when Bitwarden's agent signs the challenge, which needs an unlocked vault and, with the recommended setting, an approval for each call.
  Each `with-secrets` or `secrets-edit` call asks for one signature.
- Losing or rotating the dedicated key needs the recovery key from Bitwarden.
  Rotating the commit-signing key doesn't.
  [`docs/operations.md`](../operations.md) gives the procedure.
  Test it once end to end.
- The dedicated key must stay inside Bitwarden.
  Writing it to disk would let anyone with the file derive the age key.
- `with-secrets` puts `sops`, `git` and `sops-age-derive` first on the `PATH` of the command that it runs.
- Python can't wipe key material from memory.
  A Rust rewrite would use the `zeroize` crate, and could also become an age plugin that SOPS calls itself.
  It would be a drop-in replacement if it passes the same pinned test.
  Nobody has checked whether SOPS 3.13.3 accepts plugin identities.
- A running process as the same user can still read secrets from another process of the same user while it runs.
  Agent sandboxing and a credential proxy are separate work.

### When to reconsider

Write a new record that supersedes this one when any of these happens:

- A YubiKey Bio or TPM-based identity becomes available and replaces the derived one.
  The global approval setting makes this the real fix for needing a stricter policy, because the token enforces its own touch or fingerprint.
- Bitwarden adds per-key authorisation, which would let the dedicated key always ask while other keys relax.
- The Bitwarden agent stops producing deterministic signatures or changes its approval behaviour.
- The tool grows beyond a short script.
