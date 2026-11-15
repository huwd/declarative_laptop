# 0018. Let a fingerprint unlock the lock screen, and keep the password for login

- **Status:** Accepted
- **Decided by:** @huwd
- **Decided:** 2026-11-15
- **Recorded:** 2026-11-15
- **Discussion:** [#124](https://github.com/huwd/declarative_laptop/pull/124)

## Summary

The Framework's fingerprint reader now unlocks the GNOME lock screen, as well as approving `sudo` and polkit prompts.
The login screen after a boot still takes the password only, because only the password unlocks the GNOME keyring.

The change was forced by GNOME 51.
Its lock screen tries fingerprint unlock whenever prints are enrolled, and shows no password box when the PAM service for it is missing, which this configuration had removed.
Allowing it on the lock screen fixes that, and means a finger alone can open a running session.
The lock screen is there for short absences from the laptop, and that risk is accepted for the convenience.

## Context

In September 2026 `fprintd` was enabled for the laptop's Goodix fingerprint sensor, which matches prints on the chip.
The configuration let a fingerprint approve `sudo` and polkit prompts, including Bitwarden's biometric unlock.
It disabled the `gdm-fingerprint` PAM service and turned off fingerprint for `login` and `gdm-password`.
No record was written then.
The commit message and the comment in `modules/security.nix` give the reason: a fingerprint can't unlock the GNOME keyring, so the password is needed at login anyway.
That's the only reason on record.

NixOS creates `gdm-fingerprint` by default whenever `fprintd` is enabled.
GDM runs it alongside `gdm-password`, so a finger is offered as an alternative to the password, not a replacement.
The login screen and the lock screen use the same PAM service.
Each reads the `org/gnome/login-screen/enable-fingerprint-authentication` setting from its own dconf profile, though: the `gdm` profile for the login screen, and the user profile for the lock screen.

Logging in unlocks the keyring with the password.
Locking the screen or suspending doesn't lock it again.
A fingerprint is therefore no help at the first login, but works without any further prompt on the lock screen.

On 2026-11-13 a Nixpkgs update moved GNOME Shell from 50.4 to 51.0 and GDM from 50.2 to 51.0.
After that, the lock screen on resume logged `PAM service gdm-fingerprint was not found` on every attempt, and showed no password box.
The session could only be recovered from a text console or by rebooting.
Two fingers were enrolled with `fprintd`, which is why GNOME tried fingerprint unlock.
The immurok daemon from [0017](0017-enable-immurok-without-pam.md) was applied at the same time, and had no part in it.

The laptop's disk is encrypted with LUKS ([0004](0004-luks-btrfs-systemd-boot.md)).
SSH is disabled, so every way in is physical.
The laptop suspends when the lid closes and when idle.

## Options considered

### Fingerprint on the lock screen, password at login (chosen)

Enable `gdm-fingerprint` again, and turn fingerprint off in the `gdm` dconf profile so the login screen doesn't offer it.
The lock screen keeps the GNOME default, which offers it.

This fixes the GNOME 51 lock screen, makes unlocking quicker, and keeps the keyring working at first login.
The cost is security: a finger becomes enough to open a running or suspended session, and with it `sudo`.
Someone who holds the laptop and can present the right finger, or a convincing copy of a print, gets everything a session can reach.

That risk is accepted for these reasons:

- The lock screen guards against short absences, such as walking away from a desk.
- Fingerprint `sudo` already carries the risk of a copied print.
  Someone who takes the laptop while it's unlocked, and has a copy, gets root and can change its settings.
- Someone forcing the maintainer to unlock can force a password as easily as a finger.
- A copied print takes effort and physical access, which is more than the lock screen is meant to resist.
- When the laptop is off, the LUKS passphrase and the password at the login screen still protect it.

### Keep `gdm-fingerprint` disabled and stop GNOME offering fingerprint

Set `enable-fingerprint-authentication` to false in the user dconf profile too.
This keeps the September position exactly, with password-only unlock everywhere.
It fixes the bug just as well.
It lost because fingerprint unlock is worth the risk described above.

### Enable `gdm-fingerprint` on both screens

NixOS's default.
A finger at the login screen starts the session without unlocking the keyring, so GNOME asks for the password straight away anyway.
That's the September objection, and it still holds.

### Stop using `fprintd`

Removes the bug and the risk.
It also loses fingerprint approval for `sudo`, polkit and Bitwarden, which the laptop uses every day.

## Decision

- `modules/security.nix` no longer disables `gdm-fingerprint`, so NixOS creates it.
- The `gdm` dconf profile sets `org/gnome/login-screen/enable-fingerprint-authentication` to false, so the login screen asks for the password only.
- The lock screen offers both the fingerprint and the password.
- `login` and `gdm-password` keep `fprintAuth = false`, and `sudo` keeps `fprintAuth = true`.

## Consequences

- Unlocking after a short absence or a suspend takes a finger, and the password still works.
- `modules/security.nix` is shared, so the Dell gets `gdm-fingerprint` too.
  It has no fingerprint reader, so GNOME never offers it there.
- Someone who holds the laptop and can present the right finger, or a copy of a print, can open a running session and use `sudo`.
- Shutting the laptop down, rather than suspending it, brings back password-only protection.
  Do this when it could be taken away, such as at a border.
- The `gdm-fingerprint` service follows NixOS's definition, and changes with Nixpkgs updates.
  Check the lock screen after GNOME updates, because this broke silently once.
- The immurok key will be a second fingerprint path, and screen unlock is one of the services it supports.
  Its PAM rule for the lock screen should follow this record, and get its own, as [0017](0017-enable-immurok-without-pam.md) requires.
- [0013](0013-derive-age-key-from-ssh-agent.md) and [0017](0017-enable-immurok-without-pam.md) describe logins as password-only.
  That is still true of the login screen, but not of the lock screen.
