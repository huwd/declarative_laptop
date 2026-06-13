# Installation guide

This guide covers getting a bootable NixOS installer onto a USB drive, partitioning a target machine with full-disk encryption, and installing from this flake. It assumes a Linux machine for writing the USB.

Throughout this guide, replace `<host>` with the name of the host you are installing (e.g. `framework-13` or `dell-xps-13-9343`), and `<username>` with the username you have configured in `hosts/<host>/configuration.nix`.

---

## 1. Get the installer

### Option A — official NixOS ISO (recommended)

Download the latest NixOS minimal ISO from <https://nixos.org/download>.

Write it to a USB drive:

```bash
# identify your USB device — check carefully before writing
lsblk

# write the image (replace /dev/sdX with your USB device)
sudo cp nixos-minimal-*.iso /dev/sdX && sync
```

The official installer includes git, nix, and all partitioning tools needed for this guide.

### Option B — custom ISO from this flake

Builds a live environment that reflects your config. Useful for air-gapped installs or verifying hardware support before committing to install.

```bash
nix run github:nix-community/nixos-generators -- \
  --format iso \
  --flake .#<host>

sudo cp result /dev/sdX && sync
```

The ISO choice only affects the installer environment — `nixos-install` is the same either way.

---

## 2. Boot and connect to the network

Boot the target machine from the USB. Ethernet via a USB adapter is recommended; wifi firmware may not be available in the installer environment.

If wifi is the only option:

```bash
nmcli device wifi connect "<SSID>" password "<password>"
```

Verify connectivity:

```bash
ping -c 3 nixos.org
```

---

## 3. Identify your disk

```bash
lsblk
```

The rest of this guide uses `/dev/nvme0n1` as the target disk. Substitute your actual device — most modern laptops use NVMe (`nvme0n1`); SATA drives appear as `sda`.

> **Warning:** the next steps will erase all data on the target disk.

---

## 4. Partition the disk

```bash
gdisk /dev/nvme0n1
```

Inside gdisk:

| Command | What it does |
|---------|-------------|
| `o` | Create a new GPT partition table (confirm with `y`) |
| `n` → `1` → Enter → `+512M` → `EF00` | 512 MB EFI System Partition |
| `n` → `2` → Enter → Enter → `8309` | Remaining space, Linux LUKS type |
| `w` | Write changes and exit |

Verify the result:

```bash
lsblk /dev/nvme0n1
```

---

## 5. Format the EFI partition

```bash
mkfs.fat -F32 -n boot /dev/nvme0n1p1
```

---

## 6. Set up full-disk encryption (LUKS2)

```bash
cryptsetup luksFormat --type luks2 /dev/nvme0n1p2
```

Type `YES` (uppercase) to confirm, then choose a strong passphrase. This passphrase is the only protection for your data — store it securely somewhere offline.

Open the encrypted container:

```bash
cryptsetup open /dev/nvme0n1p2 cryptroot
```

---

## 7. Create the btrfs filesystem and subvolumes

Format:

```bash
mkfs.btrfs -L nixos /dev/mapper/cryptroot
```

Mount temporarily to create subvolumes:

```bash
mount /dev/mapper/cryptroot /mnt

btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix

umount /mnt
```

The three subvolumes serve different purposes:

| Subvolume | Mountpoint | Purpose |
|-----------|-----------|---------|
| `@` | `/` | Root filesystem |
| `@home` | `/home` | User data — snapshotted independently |
| `@nix` | `/nix` | Nix store — large, fully reproducible, excluded from snapshots |

---

## 8. Mount everything

```bash
BTRFS_OPTS="compress=zstd:1,space_cache=v2,noatime"

mount -o "subvol=@,$BTRFS_OPTS"     /dev/mapper/cryptroot /mnt
mkdir -p /mnt/{boot,home,nix}
mount -o "subvol=@home,$BTRFS_OPTS" /dev/mapper/cryptroot /mnt/home
mount -o "subvol=@nix,$BTRFS_OPTS"  /dev/mapper/cryptroot /mnt/nix
mount /dev/nvme0n1p1 /mnt/boot
```

Verify the layout looks right:

```bash
lsblk
findmnt /mnt
```

---

## 9. Generate the hardware configuration

```bash
nixos-generate-config --root /mnt
```

This writes `/mnt/etc/nixos/hardware-configuration.nix` containing your disk UUIDs, LUKS device, CPU microcode flag, and required kernel modules. You need this file in the repo before running `nixos-install`.

---

## 10. Add hardware configuration to the repo

Clone the repo into the installer environment:

```bash
git clone <your-repo-url> /tmp/config
cd /tmp/config
```

Copy the generated file into the correct host directory:

```bash
cp /mnt/etc/nixos/hardware-configuration.nix hosts/<host>/hardware-configuration.nix
```

Open the file and check that it contains:

- `boot.initrd.luks.devices` — the LUKS device by UUID
- `fileSystems` entries for `/`, `/home`, `/nix`, and `/boot` with the correct UUIDs and btrfs options
- `hardware.cpu.<intel|amd>.updateMicrocode = true`

If the btrfs subvolume mount options are missing, add them manually to match the options used in step 8:

```nix
fileSystems."/" = {
  device = "/dev/disk/by-uuid/<uuid>";
  fsType = "btrfs";
  options = [ "subvol=@" "compress=zstd:1" "space_cache=v2" "noatime" ];
};
```

Commit the file:

```bash
git add hosts/<host>/hardware-configuration.nix
git commit -m "feat(<host>): add hardware-configuration.nix"
```

You can push now or after first boot — `nixos-install` only needs the local clone.

---

## 11. Install

```bash
nixos-install --flake /tmp/config#<host>
```

This builds the full system closure, installs the bootloader (systemd-boot), and copies everything to `/mnt`. When prompted, set a root password.

When the install completes:

```bash
reboot
```

Remove the USB drive when the machine powers off.

---

## 12. First boot

Log in as `root` using the password set during install, then set a password for your user account:

```bash
passwd <username>
```

Log out, log back in as `<username>`, and push your `hardware-configuration.nix` commit if you haven't already:

```bash
cd /tmp/config   # or re-clone if the installer environment is gone
git push
```

From here, continue with [docs/setup.md](setup.md) to complete post-install configuration.
