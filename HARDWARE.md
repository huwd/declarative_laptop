# Hardware: Framework Laptop 13 Pro (AMD Ryzen AI 9 HX 370)

Product: <https://frame.work/gb/en/products/laptop13pro-amd-ai300/configuration/new>

## Specification

| Component | Detail |
|-----------|--------|
| CPU | AMD Ryzen AI 9 HX 370 (Strix Point, 12 cores / 24 threads) |
| iGPU | AMD Radeon 890M (RDNA 3.5) |
| NPU | AMD XDNA 2 (AI/ML accelerator) |
| RAM | 64 GB DDR5-5600 (2 × 32 GB, user-upgradeable) |
| Storage | NVMe M.2 2280 (user-replaceable) |
| Display | 13.5" 2880×1920 touchscreen (3:2), 30–120 Hz |
| Wi-Fi | AMD RZ717 Wi-Fi 7 |
| Bluetooth | 5.3+ |
| Webcam | 1080p 60fps |
| Battery | 74 Wh |
| Ports | 4× user-selectable expansion-card bays |
| Audio | 2× speaker array, 3-mic beamforming array |
| Biometrics | Fingerprint reader |

> Verify exact component revisions when buying — Framework iterates quietly between batches (Wi-Fi card in particular).

## Linux Compatibility

### CPU / Platform

**Good.** Zen 5 has been well supported since about kernel 6.10.
Full performance scaling, thermal management, and CPU frequency governors work correctly.
Use `linux_latest` on NixOS to ensure you have a recent enough kernel.

### GPU (RDNA 3.5 iGPU)

The `amdgpu` open-source driver ships in-kernel.
No proprietary blobs, no drama.
Hardware video decode (VA-API) and Vulkan work out of the box.
GNOME on Wayland runs well on AMD iGPU.

### NPU (XDNA 2 / AI accelerator)

**Partial.** The NPU was not well supported on Linux when the project began.
The configuration doesn't use it, and the [local LLM setup](docs/local-llm.md) runs on the GPU instead.
Check the AMDXDNA driver's upstream status before relying on it.

### Wi-Fi (AMD RZ717)

**Expected to be good on a current kernel.** The Framework uses the AMD RZ717 Wi-Fi 7 module, not the Intel card assumed by the original plan.
It needs firmware that `hardware.enableRedistributableFirmware` provides.
Confirm Wi-Fi and Bluetooth in the live installer before partitioning the disk.

### Suspend / Resume

Strix Point suspend/resume has known quirks in early kernel versions.
As of kernel 6.11+ reports are generally positive.
s2idle (modern standby) is the supported suspend mode; deep sleep may not be available depending on firmware.
Follow the Framework Linux community forum for your specific BIOS version.

### Fingerprint Reader

**Works.** The `framework-13` host uses a Goodix sensor through `fprintd`.
`modules/security.nix` enables it for `sudo` and polkit prompts, and deliberately not for login.
Framework has shipped both supported and unsupported sensors across batches, so check your batch against the Framework Linux wiki before buying.

### Display / HiDPI

**Good.** The 2880×1920 touchscreen is a high-density 3:2 panel with variable 30–120 Hz refresh.
Start with 150% or 175% fractional scaling in GNOME and verify touch, rotation behaviour, variable refresh rate and power use.

### Audio

**Generally good.** PipeWire + WirePlumber is the correct stack.
Some Framework models have required SOF (Sound Open Firmware) kernel config; the `nixos-hardware` module for your model will handle this.

### Thunderbolt / USB4

**Good.** Works for display output, docks, and storage.
Hotplug is reliable on recent kernels.

### Framework Expansion Cards

USB-A, USB-C, HDMI, DisplayPort, SD, microSD, and storage expansion cards all present as standard USB or PCIe devices.
No special drivers needed.

### Firmware Updates

Framework ships firmware via LVFS (Linux Vendor Firmware Service).
Apply updates with `fwupdmgr`, which works on NixOS with `services.fwupd.enable = true`.

## Linux support rating

A strong hardware choice for Linux.
The main uncertainty is suspend/resume reliability on Strix Point, and the NPU is unused.
The other components work well on a current kernel.

Check the Framework Linux community subforum for your specific BIOS version before buying: <https://community.frame.work/c/framework-laptop/linux>

---

## NixOS-Specific Notes

### nixos-hardware module

The pinned `nixos-hardware` input includes a dedicated Framework 13 AMD AI 300 Series module.
`flake.nix` adds it to the `framework-13` host's modules:

```nix
nixos-hardware.nixosModules.framework-amd-ai-300-series
```

It supplies the shared Framework/AMD configuration, Framework EC integration, firmware updates, audio enhancement device and model-specific audio workarounds.

### Kernel pin

```nix
boot.kernelPackages = pkgs.linuxPackages_latest;
```

Strix Point benefits from the most recent stable kernel.
`linuxPackages_latest` tracks the latest stable release in nixpkgs.

### Firmware and microcode

`hosts/framework-13/configuration.nix` sets `hardware.enableRedistributableFirmware = true`.
The generated `hardware-configuration.nix` enables AMD microcode updates.

### Power management

```nix
services.power-profiles-daemon.enable = true;  # or tlp, not both
```

Framework recommends `power-profiles-daemon` for AMD models.
Avoid running both simultaneously.

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
