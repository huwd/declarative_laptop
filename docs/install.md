# Installation guide

This guide covers getting a bootable NixOS installer onto a USB drive, partitioning a target machine with full-disk encryption, and installing from this flake.
It assumes a Linux machine for writing the USB.

The install is manual.
You type the disk layout yourself, so the commands here must match [the record of the disk layout](decisions/0004-luks-btrfs-systemd-boot.md).
[#93](https://github.com/huwd/declarative_laptop/issues/93) tracks building an installer that does this for you.

Throughout this guide, replace `<host>` with the name of the host you are installing (e.g. `framework-13` or `dell-xps-13-9343`), and `<username>` with the username you have configured in `hosts/<host>/configuration.nix`.

## What you will decide

| Decision | Where |
|----------|-------|
| Which host to install | Steps 10 and 11 |
| Which disk to erase | Steps 3 to 6 |
| The disk encryption passphrase | Step 6 |
| The root password | Step 11 |
| The password for your user | Step 12 |
| How to connect to the network | Step 2 |

---

## 1. Get the installer

Download the latest NixOS minimal ISO from <https://nixos.org/download>.

Write it to a USB drive:

```bash
# identify your USB device — check carefully before writing
lsblk

# write the image (replace /dev/sdX with your USB device)
sudo cp nixos-minimal-*.iso /dev/sdX && sync
```

The minimal ISO includes every tool this guide uses: `git`, `gdisk`, `cryptsetup`, `mkfs.btrfs`, `mkfs.fat`, NetworkManager, `nixos-generate-config` and `nixos-install`.
It doesn't contain this configuration, so the install downloads the system from the internet.

---

## 2. Boot and connect to the network

Boot the target machine from the USB.
Use Ethernet via a USB adapter if available; Wi-Fi firmware may not be available in the installer environment.

If Wi-Fi is the only option, use `nmtui` to choose a network interactively, or:

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

The rest of this guide uses `/dev/nvme0n1` as the target disk.
Substitute your actual device — most modern laptops use NVMe (`nvme0n1`); SATA drives appear as `sda`.

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

Type `YES` (uppercase) to confirm, then choose a strong passphrase.
This passphrase is the only protection for your data — store it securely somewhere offline.

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
| `@home` | `/home` | User data — supports independent snapshots |
| `@nix` | `/nix` | Nix store — separate from root and home snapshots |

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

This writes `/mnt/etc/nixos/hardware-configuration.nix` containing your disk UUIDs, LUKS device, CPU microcode flag, and required kernel modules.
You need this file in the repo before running `nixos-install`.

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

The installer doesn't enable flakes, but `nixos-install --flake` turns them on for this command, so you need no extra setup.
It builds the full system closure, installs the bootloader (systemd-boot), and copies everything to `/mnt`.
When prompted, set a root password.

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

Log out and log back in as `<username>`.
The installer's `/tmp/config` clone no longer exists after reboot, so clone the repository into its permanent location:

```bash
mkdir -p ~/.config
git clone <your-repo-url> ~/.config/nixos-config
```

From here, continue with [docs/setup.md](setup.md) to complete post-install configuration.
