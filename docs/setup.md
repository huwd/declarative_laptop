# First-boot setup

Complete this checklist after the first successful boot.
It deliberately keeps hardware validation separate from optional personal services and secrets.

## 1. Preserve the generated hardware configuration

Commit and push the real `hosts/<host>/hardware-configuration.nix`.
If you could not push it from the installer, copy the file to persistent media before rebooting and restore it into the permanent clone now.
Do not replace it with the placeholder from `main`.

```bash
cd ~/.config/nixos-config
git add hosts/<host>/hardware-configuration.nix
git commit -m "feat(<host>): add generated hardware configuration"
git push
```

## 2. Apply and verify the configuration

```bash
cd ~/.config/nixos-config
just check
sudo nixos-rebuild switch --flake .#<host>
```

Reboot once more and verify that the new generation appears in systemd-boot.

## 3. Update firmware

Keep the installer USB available while updating firmware so you can recover the system if a boot entry needs reinstalling.

```bash
sudo fwupdmgr refresh
sudo fwupdmgr get-updates
sudo fwupdmgr update
```

## 4. Check the hardware

Check these before moving personal data onto the machine:

- Wi-Fi and Bluetooth, including reconnect after reboot
- speakers, headphone socket, microphone and webcam
- touchpad, keyboard backlight and all expansion cards
- touchscreen input and GNOME fractional scaling
- display refresh-rate choices and external display output through USB-C/HDMI
- suspend/resume: repeat checks on battery and AC power
- battery reporting and all three power profiles

After a failed suspend or hardware event, inspect the current boot journal:

```bash
journalctl -b -p warning
journalctl -b | grep -Ei 'suspend|resume|amdgpu|wifi|firmware|error'
```

Do not add speculative kernel parameters.
Record the failure first and apply a workaround only when it matches the observed kernel, firmware and error.

## 5. Establish credentials

Generate or restore the personal SSH key used for Git hosting, configure Git identity and verify repository access.
Private keys should come from your password manager or offline backup, never from this repository.

The configuration disables the SSH daemon (`services.openssh.enable = false`).
Before enabling it, add a firewall rule for port 22 that limits access to a trusted interface or source.

## 6. Bootstrap agenix when needed

The repository does not currently declare any secrets.
Once the host is stable, check that its SSH host key exists.
With the SSH daemon off, a fresh install may lack this key.
Create a missing key with `sudo ssh-keygen -t ed25519 -N "" -f /etc/ssh/ssh_host_ed25519_key`.
Then copy `/etc/ssh/ssh_host_ed25519_key.pub` into `secrets/secrets.nix` alongside your personal public key, declare the required secret files, and encrypt them with `agenix`.
Commit only the resulting `.age` files.

## 7. Configure optional stateful services

The configuration enables Syncthing, but its devices and folders are not yet declarative.
Add the laptop through the local web UI at <http://127.0.0.1:8384>, verify a small test folder first, and only then connect existing data folders.

Review any browser extensions before installing them, because they sit outside the repository's Nix closure checks.
