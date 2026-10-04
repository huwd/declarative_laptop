# 0004. Encrypt the whole disk with LUKS2, use btrfs subvolumes, and boot with systemd-boot

- **Status:** Accepted
- **Decided by:** @huwd
- **Decided:** 2026-06; installed on the Framework in 2026-09
- **Recorded:** 2026-10-04
- **Discussion:** #6 (installation guide), #19 (generated hardware
  configuration)

## Summary

In the context of a laptop that travels and holds personal data, facing
a once-only choice of disk layout at install time, the decision was for
LUKS2 full-disk encryption with btrfs subvolumes for root, home and the
Nix store, booted by systemd-boot, and against unencrypted or ext4 or
LVM layouts and GRUB, to achieve data that is unreadable if the laptop
is lost, and room for snapshots, accepting a passphrase at every boot
and no Secure Boot for now.

## Context

The disk layout is the hardest decision to change later: changing it
means reinstalling. It had to be settled before the Framework arrived,
and was written up as `docs/install.md` in #6.

A laptop can be lost or stolen, so data at rest needs encrypting. NixOS
already keeps every previous system generation, but those don't cover
personal files in the home directory.

## Options considered

### LUKS2 with btrfs subvolumes and systemd-boot (chosen)

One LUKS2 container fills the disk apart from a 512 MB EFI partition.
Inside it, btrfs with three subvolumes:

- `@`, mounted at `/`
- `@home`, mounted at `/home`, which can be snapshotted on its own
- `@nix`, mounted at `/nix`: large and fully reproducible, so it can be
  left out of snapshots

All are mounted with `compress=zstd:1,space_cache=v2,noatime`.
systemd-boot is simple, UEFI-only, and lists each NixOS generation as a
boot entry.

### ext4 on LUKS

Simpler and mature, but no subvolumes, snapshots or compression.

### LVM on LUKS

The original plan offered "LVM or btrfs". LVM gives flexible volumes and
its own snapshots, but adds a layer that btrfs subvolumes make
unnecessary.

{@TODO: was ZFS considered? It's the other common choice on NixOS.
Add it as an option if so.}

### GRUB

The original planning documents assumed GRUB. It supports legacy BIOS
and more complex setups, none of which this hardware needs. systemd-boot
does less and is easier to reason about.

### Impermanence

Root on `tmpfs`, wiped at every boot, with only declared paths
persisting. Listed as a stretch goal in
[0001](0001-why-this-project.md), and deliberately not adopted at
install time.

## Decision

The Framework was installed as `docs/install.md` describes, and any
future install, including the Dell, follows the same guide: LUKS2
full-disk encryption, btrfs with `@`, `@home` and `@nix` subvolumes, and
systemd-boot. The Framework keeps at most 20 boot entries
(`configurationLimit`) to bound how much space generations use on the
EFI partition. Secure Boot is off.

## Consequences

- If the laptop is lost while powered off, the data on it can't be read.
  The passphrase is the only protection, so it has to be strong and
  stored offline.
- Every boot needs the passphrase typed in.
- `@home` can be snapshotted independently.
  {@TODO: no snapshot tool (snapper, btrbk) is configured yet, so the
  layout allows snapshots but nothing takes them. Decide whether to add
  one, which would be a new record, or stop describing `@home` as
  snapshotted in `docs/install.md`.}
- Without Secure Boot, someone with physical access could tamper with the
  unencrypted boot partition (an "evil maid" attack). lanzaboote, a
  stretch goal, would close that gap; adopting it would be a new record.
- Changing any of this means reinstalling.
