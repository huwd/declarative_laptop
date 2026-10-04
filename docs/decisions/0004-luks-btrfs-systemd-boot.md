# 0004. Encrypt system and user data with LUKS2, use btrfs, and boot with systemd-boot

- **Status:** Accepted
- **Decided by:** @huwd
- **Decided:** 2026-06; installed on the Framework in 2026-09
- **Recorded:** 2026-10-04
- **Discussion:** [#6](https://github.com/huwd/declarative_laptop/pull/6) (installation guide), [#19](https://github.com/huwd/declarative_laptop/pull/19) (generated hardware configuration)

## Summary

The laptop needs protection for personal data at rest and a disk layout that can support separate snapshots of user data.
The chosen layout uses LUKS2 for the system and data partition, btrfs subvolumes for root, home and the Nix store, and systemd-boot for UEFI booting.
The EFI partition remains unencrypted.
The accepted costs are entering a passphrase at boot and leaving Secure Boot for a later decision.

## Context

Changing the disk layout later would require a disruptive migration or reinstall, so the installation plan needed a layout in advance.
[The installation guide](../install.md), introduced in [#6](https://github.com/huwd/declarative_laptop/pull/6), records the chosen layout.

Loss or theft of a portable laptop makes protection of personal data at rest necessary.
NixOS generations provide a way to revert system configuration, but do not restore personal files in the home directory.
Separate subvolumes allow different snapshot policies for these kinds of data.
LVM was a familiar option from other contexts, but btrfs offered the desired snapshotting within the filesystem.
The maintainer knew about ZFS but did not compare it in detail.

## Options considered

### Filesystem layout

#### LUKS2 with btrfs subvolumes (chosen)

One LUKS2 container occupies the disk apart from the unencrypted EFI partition.
Inside it, btrfs with three subvolumes:

- `@`, mounted at `/`
- `@home`, mounted at `/home`, which can be snapshotted on its own
- `@nix`, mounted at `/nix`, so snapshots of root and home can exclude the Nix store

LUKS2 provides encryption beneath the filesystem; btrfs provides subvolumes, snapshots and compression.
The subvolumes share free space within one filesystem, avoiding the need to divide the disk into separately sized logical volumes for these paths.
Snapshots can preserve an earlier view of one subvolume without copying all its data immediately.
The [btrfs subvolume documentation](https://btrfs.readthedocs.io/en/latest/btrfs-subvolume.html) explains these properties and the distinction from LVM snapshots.

This meets the laptop's needs without adding LVM solely for volume separation and snapshots.
It also introduces a filesystem to learn and maintain: snapshot retention and available disk space still need attention.
Snapshots kept on the same disk do not protect against losing that disk.

#### LVM on LUKS

Use LVM inside the encrypted container, with logical volumes for the filesystems.
Prior experience with LVM made this a credible alternative.
It provides volume management and block-level snapshots, but adds a separate layer to configure and maintain.
For this laptop, btrfs subvolumes and filesystem snapshots met the requirements without that extra layer.

### Bootloader

#### systemd-boot (chosen)

systemd-boot supports UEFI booting and provides entries for the saved NixOS generations.
It meets these requirements with fewer features to configure than GRUB.

#### GRUB

The original planning documents assumed GRUB.
It supports legacy BIOS and more complex setups that are not requirements for these laptops.

## Decision

The installation guide defines the layout for these laptops: an unencrypted EFI partition, a LUKS2 system and data partition, btrfs with `@`, `@home` and `@nix` subvolumes, and systemd-boot.
The Framework uses this layout; the Dell hardware configuration remains a placeholder until installation.
Secure Boot is off.
The installation guide and host configuration specify the partition sizes, mount options and boot-entry limit.

## Consequences

- Encryption protects the contents of the locked LUKS2 partition after loss of a powered-off laptop.
  The passphrase needs to be strong, with a recovery copy kept separately from the laptop.
- Every boot needs the passphrase typed in.
- The layout supports independent snapshots of `@home`, but the configuration includes no automated snapshot tool.
  The layout enables snapshots; it does not provide a snapshot schedule or backups.
- Without Secure Boot, someone with physical access could tamper with the unencrypted boot partition (an "evil maid" attack).
  [lanzaboote](https://github.com/nix-community/lanzaboote) is a possible route to Secure Boot, which could reduce boot-tampering risks when configured appropriately.
  Adopting it would need a separate decision.
- Changing the filesystem or partition layout requires a disruptive migration or reinstall.
  Bootloader settings can change independently of that layout.
