# Build Plan

End-to-end provisioning guide: from blank hardware to a fully managed NixOS
system with ongoing automated dependency and security management.

---

## Phase 0: Bootstrap the Config Repo (Before Touching the Hardware)

Do this on your current machine before you have the laptop.

### 0.1 Create the repo

```bash
mkdir nixos-config && cd nixos-config
git init
git checkout -b main
```

### 0.2 Write the initial flake

```nix
# flake.nix
{
  description = "Huw's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-hardware, home-manager, agenix, ... }: {
    nixosConfigurations.framework-13 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hosts/framework-13/configuration.nix
        home-manager.nixosModules.home-manager
        agenix.nixosModules.default
      ];
    };
  };
}
```

### 0.3 Scaffold the directory structure

```bash
mkdir -p hosts/framework-13 modules/{desktop,development} home/huw secrets
touch hosts/framework-13/configuration.nix
touch modules/desktop/gnome.nix
touch home/huw/default.nix
touch secrets/secrets.nix
```

### 0.4 Write a minimal `configuration.nix`

Leave `hardware-configuration.nix` absent for now — it gets generated on the
target machine. Reference it with an import that you'll add after install.

### 0.5 Commit and push

```bash
git add .
git commit -m "chore: initial flake scaffold"
git remote add origin git@github.com:you/nixos-config.git
git push -u origin main
```

---

## Phase 1: Build the System Image ("The ROM")

In NixOS terms, "building the ROM" means producing a bootable installer and
validating that your configuration builds successfully before touching real
hardware.

### 1.1 Validate the flake builds

```bash
nix flake check
nix build .#nixosConfigurations.framework-13.config.system.build.toplevel
```

This builds the full system closure locally without installing anything. Fix
any errors before proceeding.

### 1.2 Generate a custom installer ISO (optional but useful)

A custom ISO bakes your SSH keys in so you can access the machine immediately
after booting, without needing a monitor or keyboard to complete setup:

```nix
# hosts/installer/default.nix
{ modulesPath, ... }: {
  imports = [ "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix" ];
  users.users.root.openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAA..." ];
  services.openssh.enable = true;
}
```

```bash
nix build .#nixosConfigurations.installer.config.system.build.isoImage
```

Alternatively, download the official GNOME installer ISO from nixos.org —
acceptable for a local hands-on install.

### 1.3 Write the installer to USB

```bash
sudo dd if=result/iso/*.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

---

## Phase 2: Installation

### 2.1 Boot and partition

Boot the USB. Use a UEFI boot with secure boot disabled (you can re-enable
later with `lanzaboote` — see Learning Plan).

Partition layout (adjust sizes to taste):

```
/dev/nvme0n1p1   512M    EFI System Partition    vfat
/dev/nvme0n1p2   100%    Linux filesystem         (LUKS container)
  └─ /dev/mapper/cryptroot
       └─ LVM or btrfs subvolumes
```

Recommended filesystem: **btrfs** with subvolumes for `/` and `/home`, enabling
snapshotting. NixOS generations + btrfs snapshots = belt and braces rollback.

```bash
# Example (adapt to your partition layout)
cryptsetup luksFormat /dev/nvme0n1p2
cryptsetup open /dev/nvme0n1p2 cryptroot
mkfs.btrfs /dev/mapper/cryptroot
mount -o subvol=@ /dev/mapper/cryptroot /mnt
mkdir /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot
```

### 2.2 Generate hardware configuration

```bash
nixos-generate-config --root /mnt
```

This produces `/mnt/etc/nixos/hardware-configuration.nix`. Copy it out:

```bash
cat /mnt/etc/nixos/hardware-configuration.nix
```

### 2.3 Clone your config repo and integrate hardware config

```bash
nix-shell -p git
git clone https://github.com/you/nixos-config /mnt/etc/nixos-config
cp /mnt/etc/nixos/hardware-configuration.nix \
   /mnt/etc/nixos-config/hosts/framework-13/
```

Add the hardware-configuration import to `configuration.nix`, then commit it
from the installer environment or push it after first boot.

### 2.4 Install

```bash
nixos-install --flake /mnt/etc/nixos-config#framework-13 --root /mnt
```

Set the root password when prompted. Reboot.

### 2.5 First boot

- Log in, change your user password
- Clone the config repo to `~/.config/nixos-config` (symlink `/etc/nixos` →
  here, or manage separately)
- Generate your SSH host key (happens automatically) — record its public key
  for agenix

---

## Phase 3: Post-Install Setup

### 3.1 Set up agenix secrets

On your existing machine (or the new one after first boot):

```bash
# Add host's public SSH key to secrets.nix
# Re-encrypt all secrets for the new host
agenix -r -i ~/.ssh/id_ed25519
```

Push the updated encrypted secrets. On the new machine:

```bash
nixos-rebuild switch --flake ~/.config/nixos-config#framework-13
```

### 3.2 Enable Home Manager

Home Manager runs as a NixOS module (already in the flake). After rebuild, all
dotfiles, shell config, and user packages declared in `home/huw/` are active.

### 3.3 Firmware update

```bash
sudo fwupdmgr refresh
sudo fwupdmgr update
```

Reboot if firmware was updated. Do this before considering the system settled.

### 3.4 Validate suspend/resume

```bash
systemctl suspend
# wake the machine, check journalctl for errors
journalctl -b -1 | grep -i "suspend\|resume\|error"
```

Note any issues and apply kernel parameter workarounds in `configuration.nix`
if needed.

---

## Phase 4: Ongoing Management

### 4.1 Applying changes

All system changes go through the config repo:

```bash
# Edit a .nix file
nixos-rebuild switch --flake ~/.config/nixos-config#framework-13
# or for Home Manager only changes:
home-manager switch --flake ~/.config/nixos-config#framework-13
```

### 4.2 Updating packages (the Dependabot workflow)

```bash
nix flake update                          # update flake.lock
nvd diff /run/current-system $(nix build --print-out-paths \
  .#nixosConfigurations.framework-13.config.system.build.toplevel --no-link)
```

Review the diff, then apply and commit:

```bash
nixos-rebuild switch --flake .#framework-13
git add flake.lock
git commit -m "chore: update nixpkgs $(date +%Y-%m-%d)"
```

### 4.3 CVE scanning with vulnix

```bash
vulnix --system                          # scan current running system
vulnix --gc-roots                        # scan all installed generations
```

For historic analysis — was I exposed to a CVE in the past?

```bash
git checkout <past-commit>               # check out an old flake.lock
nix build .#nixosConfigurations.framework-13.config.system.build.toplevel \
  --no-link --print-out-paths > /tmp/old-closure
vulnix --closure /tmp/old-closure
git checkout main
```

### 4.4 Rolling back

NixOS keeps previous generations. If an update breaks something:

```bash
nixos-rebuild --rollback switch          # roll back one generation
# or at boot: select previous generation in GRUB
```

List generations:

```bash
nix-env --list-generations --profile /nix/var/nix/profiles/system
```

### 4.5 Garbage collection

Nix accumulates old generations. Prune periodically:

```bash
# Keep last 5 generations
nix-collect-garbage --delete-older-than 30d
sudo nix-collect-garbage --delete-older-than 30d   # system profiles
```

Automate in `configuration.nix`:

```nix
nix.gc = {
  automatic = true;
  dates = "weekly";
  options = "--delete-older-than 30d";
};
```

---

## Phase 5: CI/CD Pipeline

A GitHub Actions workflow that keeps dependencies fresh and flags CVEs before
they reach your machine.

### 5.1 Workflow: weekly dependency update

```yaml
# .github/workflows/update.yml
name: Update flake inputs

on:
  schedule:
    - cron: "0 9 * * 1"   # Monday 09:00
  workflow_dispatch:

jobs:
  update:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: DeterminateSystems/nix-installer-action@main
      - uses: DeterminateSystems/magic-nix-cache-action@main

      - name: Update flake inputs
        run: nix flake update

      - name: Build system closure
        run: |
          nix build .#nixosConfigurations.framework-13.config.system.build.toplevel \
            --no-link

      - name: Generate nvd diff
        run: |
          OLD=$(git stash list | head -1)  # simplified; see note below
          nix run nixpkgs#nvd -- diff /run/current-system result

      - name: Run vulnix scan
        run: |
          nix run nixpkgs#vulnix -- --closure result

      - name: Open PR if flake.lock changed
        uses: peter-evans/create-pull-request@v6
        with:
          commit-message: "chore: update nixpkgs"
          title: "chore: weekly nixpkgs update"
          body: |
            Automated weekly `nix flake update`.

            See the vulnix and nvd outputs in the CI run for CVE findings
            and package diffs.
          branch: chore/nixpkgs-update
          delete-branch: true
```

### 5.2 Workflow: validate on every PR

```yaml
# .github/workflows/check.yml
name: Validate NixOS config

on:
  pull_request:
  push:
    branches: [main]

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: DeterminateSystems/nix-installer-action@main
      - uses: DeterminateSystems/magic-nix-cache-action@main

      - name: Flake check
        run: nix flake check

      - name: Build system
        run: |
          nix build .#nixosConfigurations.framework-13.config.system.build.toplevel \
            --no-link

      - name: CVE scan
        run: nix run nixpkgs#vulnix -- --closure result
        continue-on-error: true   # informational until you tune whitelists
```

> CI builds the full NixOS closure — this is slow on GitHub-hosted runners the
> first time (~20–40 min). `magic-nix-cache-action` caches derivations between
> runs and dramatically reduces subsequent build times. Consider a self-hosted
> runner on an x86 machine for faster builds.

---

## Quick Reference

| Task | Command |
|------|---------|
| Apply config changes | `nixos-rebuild switch --flake .#framework-13` |
| Apply home changes only | `home-manager switch --flake .#framework-13` |
| Update all packages | `nix flake update` |
| Diff pending update | `nvd diff /run/current-system result` |
| CVE scan current system | `vulnix --system` |
| Roll back one generation | `nixos-rebuild --rollback switch` |
| List generations | `nix-env -p /nix/var/nix/profiles/system --list-generations` |
| Enter a dev shell | `nix develop` or `devenv shell` |
| Run a one-off tool | `nix run nixpkgs#ripgrep` |
| Update firmware | `sudo fwupdmgr update` |
