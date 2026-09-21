# Hardware: Framework Laptop 13 Pro (AMD Ryzen AI 9 HX 370)

Product: https://frame.work/gb/en/products/laptop13pro-amd-ai300/configuration/new

## Specification

| Component | Detail |
|-----------|--------|
| CPU | AMD Ryzen AI 9 HX 370 (Strix Point, 12 cores / 24 threads) |
| iGPU | AMD Radeon 890M (RDNA 3.5) |
| NPU | AMD XDNA 2 (AI/ML accelerator) |
| RAM | 64 GB DDR5-5600 (2 × 32 GB, user-upgradeable) |
| Storage | NVMe M.2 2280 (user-replaceable) |
| Display | 13.5" 2880×1920 touchscreen (3:2), 30–120 Hz |
| WiFi | AMD RZ717 Wi-Fi 7 |
| Bluetooth | 5.3+ |
| Webcam | 1080p 60fps |
| Battery | 74 Wh |
| Ports | 4× user-selectable expansion-card bays |
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

**Expected to be good on a current kernel.** The ordered system uses the AMD
RZ717 Wi-Fi 7 module rather than the Intel card assumed by the original plan.
Confirm Wi-Fi and Bluetooth in the live installer before partitioning the disk.

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

**Good.** The 2880×1920 touchscreen is a high-density 3:2 panel with variable
30–120 Hz refresh. Start with 150% or 175% fractional scaling in GNOME and
verify touch, rotation behaviour, variable refresh rate and power use.

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

The pinned `nixos-hardware` input includes a dedicated Framework 13 AMD AI 300
Series module, enabled in `flake.nix`:

```nix
# flake.nix inputs
nixos-hardware.url = "github:NixOS/nixos-hardware/master";

# configuration.nix
imports = [
  nixos-hardware.nixosModules.framework-amd-ai-300-series
];
```

It supplies the shared Framework/AMD configuration, Framework EC integration,
firmware updates, audio enhancement device and model-specific audio workarounds.

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
