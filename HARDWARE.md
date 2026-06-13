# Hardware: Framework Laptop 13 Pro (AMD Ryzen AI 300 Series)

Product: https://frame.work/gb/en/products/laptop13pro-amd-ai300/configuration/new

## Specification

| Component | Detail |
|-----------|--------|
| CPU | AMD Ryzen AI 300 Series (Strix Point, Zen 5 cores) |
| iGPU | AMD Radeon 890M (RDNA 3.5) |
| NPU | AMD XDNA 2 (AI/ML accelerator) |
| RAM | Up to 64 GB LPDDR5X (user-upgradeable) |
| Storage | NVMe M.2 2280 (user-replaceable) |
| Display | 13.5" 2256×1504 (3:2), 120 Hz |
| WiFi | Intel Wi-Fi 6E / BE200 (BE200 on newer configs) |
| Bluetooth | 5.3+ |
| Webcam | 1080p 60fps |
| Battery | 61 Wh |
| Ports | 2× USB4 (40Gbps), modular expansion bay (×2) |
| Audio | 2× speaker array, 3-mic beamforming array |
| Biometrics | Fingerprint reader |

> Verify exact component revisions at point of purchase — Framework iterates quietly
> between batches (WiFi card in particular).

## Linux Compatibility

### CPU / Platform

**Good.** Zen 5 is well-supported from kernel 6.10+. Full performance scaling,
thermal management, and CPU frequency governors work correctly. Use
`linux_latest` on NixOS to ensure you have a recent enough kernel.

### GPU (RDNA 3.5 iGPU)

**Excellent.** The `amdgpu` open-source driver ships in-kernel. No proprietary
blobs, no drama. Hardware video decode (VA-API) and Vulkan work out of the box.
GNOME on Wayland runs well on AMD iGPU.

### NPU (XDNA 2 / AI accelerator)

**Partial.** The NPU is not yet well-supported on Linux as of mid-2025. The
AMDXDNA driver is in early upstream stages. Ignore it for now — it is not
needed for the target use case and will improve over time.

### WiFi (Intel BE200 / AX210)

**Excellent.** Intel WiFi has first-class Linux support. The `iwlwifi` driver
ships in-kernel. BE200 requires firmware from `linux-firmware`; this is
handled automatically on NixOS with `hardware.enableRedistributableFirmware`.

### Suspend / Resume

**Mostly good, with caveats.** Strix Point suspend/resume has known quirks in
early kernel versions. As of kernel 6.11+ reports are generally positive.
s2idle (modern standby) is the supported suspend mode; deep sleep may not be
available depending on firmware. Monitor the Framework Linux community forum
for your specific BIOS version.

### Fingerprint Reader

**Check at time of purchase.** Framework has shipped both supported and
unsupported fingerprint sensors across batches. Supported sensors work via
`fprintd`. Verify your batch against the Framework Linux wiki before expecting
this to work.

### Display / HiDPI

**Good.** The 2256×1504 panel at 13.5" is ~201 PPI. Set fractional scaling to
125% or 150% in GNOME. Wayland handles fractional scaling better than X11;
use Wayland.

### Audio

**Generally good.** PipeWire + WirePlumber is the correct stack. Some
Framework models have required SOF (Sound Open Firmware) kernel config; the
`nixos-hardware` module for your model will handle this.

### Thunderbolt / USB4

**Good.** Works for display output, docks, and storage. Hotplug is reliable
on recent kernels.

### Framework Expansion Cards

**Excellent.** USB-A, USB-C, HDMI, DisplayPort, SD, microSD, and storage
expansion cards all present as standard USB or PCIe devices. No special
drivers needed.

### Firmware Updates

Framework ships firmware via LVFS (Linux Vendor Firmware Service). Updates
are applied via `fwupdmgr` — works on NixOS with `services.fwupd.enable = true`.

## Overall Linux Rating: B+ → A

Strong hardware choice for Linux. The main uncertainty at time of writing is
suspend/resume reliability on Strix Point and NPU support. Both will improve
with kernel updates. Everything else is first-class.

Check the Framework Linux community subforum for your specific BIOS version
before purchase: https://community.frame.work/c/framework-laptop/linux

---

## NixOS-Specific Notes

### nixos-hardware module

A dedicated `nixos-hardware` module for the Framework 13 AI 300 may not exist
yet or may be recent. Start from the closest existing module (7040 series) and
verify which settings apply:

```nix
# flake.nix inputs
nixos-hardware.url = "github:NixOS/nixos-hardware/master";

# configuration.nix
imports = [
  nixos-hardware.nixosModules.framework-13-7040-amd  # adjust when AI 300 module ships
];
```

Track this issue in the nixos-hardware repo:
https://github.com/NixOS/nixos-hardware

### Kernel pin

```nix
boot.kernelPackages = pkgs.linuxPackages_latest;
```

Strix Point benefits from the most recent stable kernel. `linuxPackages_latest`
tracks the latest stable release in nixpkgs.

### Firmware and microcode

```nix
hardware.enableRedistributableFirmware = true;
hardware.cpu.amd.updateMicrocode = true;
```

### Power management

```nix
services.power-profiles-daemon.enable = true;  # or tlp, not both
```

Framework recommends `power-profiles-daemon` for AMD models. Avoid running
both simultaneously.

### Suspend

```nix
# If s2idle is not the default, force it
boot.kernelParams = [ "mem_sleep_default=s2idle" ];
```

### Firmware updates

```nix
services.fwupd.enable = true;
```

Run `sudo fwupdmgr update` after initial setup and periodically thereafter.
Framework releases BIOS and controller firmware updates via LVFS.
