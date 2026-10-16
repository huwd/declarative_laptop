# OPSEC

This document records the threat model for a public NixOS configuration repository, the risks accepted by working in the open, and the mitigations in place.
It describes gaps rather than offering reassurance.

---

## What this public repository exposes

### Identity

The username `huw` maps directly to a real name because a personal GitHub account publishes this repository.
The project accepts this link as part of working in the open; the account already links the identity.

### Hardware fingerprint

The config names the specific machine: Framework Laptop 13 Pro, AMD Ryzen AI 300 (Strix Point).
This exposes:

- **Firmware attack surface** — an adversary targeting Framework or AMD firmware supply chains knows this is a plausible target
- **Hardware-specific CVEs** — AMD and Intel regularly publish microcode and firmware CVEs.
  Knowing the exact SoC narrows the relevant CVE set
- **Physical identification** — in combination with other signals, hardware model contributes to device fingerprinting

Mitigation: `services.fwupd.enable = true` keeps BIOS and controller firmware current via LVFS.
Framework's relative obscurity compared to Dell/Lenovo provides some security by minority.
No stronger mitigation is practical.

### Software inventory

The full package list is public.
This enables:

- **Targeted CVE research** — an adversary can list all declared packages and query known vulnerabilities without needing to probe the machine
- **AI-assisted attack chain construction** — an LLM can reason across the specific combination of software versions and find non-obvious lateral paths that a naive CVE search would miss.
  This is a materially new risk that grows as AI tooling improves.
- **Trawling efficiency** — automated scanning looking for specific vulnerable versions costs less when a public manifest provides the inventory than when it requires active probing

This is the primary risk of a public config.
The project accepts it as a cost of working in the open.

---

## Active vulnerability management as mitigation — stress test

The config implements:

- **vulnix** scanning the Nix store closure against NVD on every PR
- **Weekly Dependabot checks** proposing input updates, with CI scanning the resulting closures
- **Historic CVE analysis** via committed `flake.lock` history
- **fwupd** for firmware currency

### Where this holds

| Threat | Covered? | How |
|--------|----------|-----|
| Known CVE in Nix package | Yes | vulnix + NVD |
| Stale packages | Yes | weekly Dependabot update PRs |
| Retroactive exposure analysis | Yes | flake.lock git history |
| Firmware vulnerabilities | Partially | fwupd / LVFS |

### Where it fails

**Zero-days.** vulnix queries NVD.
A vulnerability not yet assigned a CVE is invisible to it by definition.
The published software manifest gives an adversary the information to weaponise a zero-day before it becomes a CVE.
No practical mitigation exists beyond minimising installed software surface, which the "per-project dev shells" approach partially addresses.

**Pre-NVD supply chain compromise.** If an attacker compromises a package before its vulnerability appears in NVD, vulnix cannot report that vulnerability.
Rebuilding from the same compromised inputs does not establish that the package is safe.
This repository has no independent verification against known-good build outputs.

**The time window.** Weekly checks and the Dependabot cooldown can delay an update after disclosure of a CVE.
They provide no guaranteed time to a fix.
For urgent fixes, run `just update` locally and open a pull request without waiting for the scheduled check, as [0007](docs/decisions/0007-dependabot-for-flake-inputs.md) describes.

**Firmware.** vulnix does not scan firmware.
LVFS covers most of what Framework ships, but UEFI, EC firmware, and microcode are outside the NVD model.
The configuration enables fwupd to apply firmware updates.

**Configuration vulnerabilities.** vulnix scans *packages* not *configuration*.
A service that is correctly versioned but misconfigured (unnecessarily exposed, weak permissions, insecure default) is not caught.
The security module applies conservative defaults; there is no automated configuration audit.

**Flatpak blind spot.** Anything installed via Flatpak is outside the Nix store and outside vulnix's reach.
See the Flatpak section below.

**Browser extensions.** Users install Firefox and Chrome extensions at runtime, outside the configured scanning.
This is a meaningful blind spot — extensions run with broad permissions and have a poor security track record.

### Honest conclusion

Active vulnerability management helps identify and assess *known CVEs in declared Nix packages*.
It does not remove supply chain or targeted attack risks, and a published manifest modestly raises the value of this machine as a target.

The preparation likely outweighs the exposure: an attacker who exploits the published manifest to construct an attack still has to execute it against a machine whose maintainer reviews updates regularly and whose firewall restricts incoming connections.
The realistic threat model for a personal laptop is opportunistic attack, not nation-state targeting — and for opportunistic attack, staying current is the dominant mitigation.

---

## Flatpak

The configuration enables Flatpak as a safety valve for applications outside Nixpkgs.
The initial setup included no Flatpak applications.

### The gap

Users install Flatpak applications at runtime, and the configured timer updates them outside the Nix store and declarative configuration.
vulnix cannot see them.
CI does not have an inventory of the applications on the running machine, so its closure scan cannot audit them.

### Mitigations in place

**Automatic updates** — a systemd timer runs `flatpak update` weekly, keeping runtimes and apps current without manual intervention.
See `modules/services.nix`.

**grype scanning** — a systemd service runs grype against the Flatpak installation directory after each update and writes a report to the journal.
This provides CVE coverage for Flatpak runtimes (the GNOME runtime, etc.) but coverage for individual app internals varies with their packaging.

**Sandbox** — Flatpak applications run in a sandboxed environment.
A vulnerable Flatpak app has a meaningfully reduced blast radius compared to a vulnerable system package, because it cannot directly access system resources without explicit portal permissions.

### Remaining gap

grype's Flatpak coverage is runtime-only: it sees the runtimes but not necessarily all libraries bundled inside individual app containers.
A fully-scanned Flatpak app would require the app author to publish an SBOM.
Most do not.

**Preference**: use Flatpak only for apps where no nixpkgs alternative exists and the app is from a reputable publisher.
Keep the Flatpak footprint small and reviewed.

---

## Browser extensions

No scanning is in place.
Extensions are an unmanaged surface on this system: users install them, browsers update them, and their permissions can grant access to page content and storage.

Mitigate by:

- Installing only extensions from established publishers
- Auditing the installed extension list periodically
- Preferring extensions with open-source codebases
- Removing extensions that are no longer actively maintained

The repository records this lack of automated review as a known gap.

---

## Accepted risk register

| Risk | Accepted? | Rationale |
|------|-----------|-----------|
| Identity linkage from username | Yes | Open work requires it |
| Hardware fingerprint exposure | Yes | Obscurity not relied upon; fwupd mitigates |
| Software inventory enabling targeted research | Yes | Active scanning is the mitigation |
| AI-assisted attack chain construction | Yes | No practical mitigation; accepted |
| Zero-day exposure window | Yes | Unavoidable; manual update PR for critical CVEs |
| Flatpak partial scan coverage | Yes | Auto-updates + grype + sandbox |
| Browser extension risk | Yes | Manual hygiene; tracked as known gap |
