# OPSEC

This document records the threat model for a public NixOS configuration
repository, the risks accepted by working in the open, and the mitigations
in place. It is intended to be honest about gaps rather than reassuring.

---

## What is exposed by making this repo public

### Identity

The username `huw` maps directly to a real name given this repo is published
under a personal GitHub account. This is accepted — the transparency benefit
of an open dotfiles repo is the point, and the identity link is already
established.

### Hardware fingerprint

The config names the specific machine: Framework Laptop 13 Pro, AMD Ryzen AI
300 (Strix Point). This exposes:

- **Firmware attack surface** — an adversary targeting Framework or AMD
  firmware supply chains knows this is a plausible target
- **Hardware-specific CVEs** — AMD and Intel regularly publish microcode and
  firmware CVEs. Knowing the exact SoC narrows the relevant CVE set
- **Physical identification** — in combination with other signals, hardware
  model contributes to device fingerprinting

Mitigation: `services.fwupd.enable = true` keeps BIOS and controller firmware
current via LVFS. Framework's relative obscurity compared to Dell/Lenovo
provides some security by minority. No stronger mitigation is practical.

### Software inventory

The full package list is public. This enables:

- **Targeted CVE research** — an adversary can enumerate all declared packages
  and query known vulnerabilities without needing to probe the machine
- **AI-assisted attack chain construction** — an LLM can reason across the
  specific combination of software versions and find non-obvious lateral paths
  that a naive CVE search would miss. This is a materially new risk that
  grows as AI tooling improves.
- **Trawling efficiency** — automated scanning looking for specific vulnerable
  versions is cheaper when the manifest is published than when it requires
  active probing

This is the primary risk of a public config. It is accepted as the cost of
working in the open.

---

## Active vulnerability management as mitigation — stress test

The config implements:

- **vulnix** scanning the Nix store closure against NVD on every PR
- **Weekly automated** `nix flake update` with vulnix scan on the result
- **Historic CVE analysis** via committed `flake.lock` history
- **fwupd** for firmware currency

### Where this holds

| Threat | Covered? | How |
|--------|----------|-----|
| Known CVE in Nix package | Yes | vulnix + NVD |
| Stale packages | Yes | weekly flake update |
| Retroactive exposure analysis | Yes | flake.lock git history |
| Firmware vulnerabilities | Partially | fwupd / LVFS |

### Where it fails

**Zero-days.** vulnix queries NVD. A vulnerability not yet assigned a CVE is
invisible to it by definition. The published software manifest gives an
adversary the information to weaponise a zero-day before it becomes a CVE.
No practical mitigation exists beyond minimising installed software surface,
which the "per-project dev shells" approach partially addresses.

**Pre-NVD supply chain compromise.** If a package in nixpkgs is backdoored
before a CVE is filed — the xz/liblzma incident is the canonical example —
vulnix will not catch it. Mitigation: the reproducible build model means
compromised packages produce a different hash and fail the build, but only
if the build is verified against a known-good state. This is not currently
implemented.

**The time window.** Weekly updates mean up to seven days of exposure after
a CVE is published. For a critical vulnerability in a widely-deployed package,
that window is meaningful. Mitigation: `workflow_dispatch` on the update
workflow allows manual early trigger when a high-severity CVE breaks in the
press.

**Firmware.** vulnix does not scan firmware. LVFS covers most of what
Framework ships, but UEFI, EC firmware, and microcode are outside the NVD
model. fwupd is the only practical mitigation and it is configured.

**Configuration vulnerabilities.** vulnix scans *packages* not
*configuration*. A service that is correctly versioned but misconfigured
(unnecessarily exposed, weak permissions, insecure default) is not caught.
The security module applies conservative defaults; there is no automated
configuration audit.

**Flatpak blind spot.** Anything installed via Flatpak is outside the Nix
store and therefore outside vulnix's reach. See the Flatpak section below.

**Browser extensions.** Firefox and Chrome extensions are installed at runtime
and entirely unscanned. This is a meaningful blind spot — extensions run with
broad permissions and have a poor security track record.

### Honest conclusion

Active vulnerability management significantly reduces exposure to *known CVEs
in declared Nix packages*. It does not eliminate the supply chain or targeted
attack risks, and a published manifest modestly raises the value of this
machine as a target.

The preparation likely outweighs the exposure: an attacker who exploits the
published manifest to construct an attack still has to execute it against a
machine that is patched weekly, has a locked-down firewall, and runs SSH only
over a trusted network. The realistic threat model for a personal laptop is
opportunistic attack, not nation-state targeting — and for opportunistic
attack, staying current is the dominant mitigation.

---

## Flatpak

Flatpak is enabled as a safety valve for applications not in nixpkgs. As of
initial setup, nothing is installed via Flatpak.

### The gap

Flatpak applications are installed and updated at runtime, outside the Nix
store and outside the declarative config. vulnix cannot see them. The CI
pipeline cannot audit them because CI does not know what is installed on the
running machine.

### Mitigations in place

**Automatic updates** — a systemd timer runs `flatpak update` weekly,
keeping runtimes and apps current without manual intervention.
See `modules/services.nix`.

**grype scanning** — a systemd service runs grype against the Flatpak
installation directory after each update and writes a report to the journal.
This provides CVE coverage for Flatpak runtimes (the GNOME runtime, etc.)
but coverage for individual app internals varies by how the app is packaged.

**Sandbox** — Flatpak applications run in a sandboxed environment. A
vulnerable Flatpak app has a meaningfully reduced blast radius compared to
a vulnerable system package, because it cannot directly access system
resources without explicit portal permissions.

### Remaining gap

grype's Flatpak coverage is runtime-only: it sees the runtimes but not
necessarily all libraries bundled inside individual app containers. A
fully-scanned Flatpak app would require the app author to publish an SBOM.
Most do not.

**Preference**: use Flatpak only for apps where no nixpkgs alternative
exists and the app is from a reputable publisher. Keep the Flatpak footprint
small and reviewed.

---

## Browser extensions

No scanning is in place. Extensions are the highest-risk unmanaged surface on
this system — they are installed by the user, updated silently, and run with
access to all page content and often storage.

Mitigate by:
- Installing only extensions from established publishers
- Auditing the installed extension list periodically
- Preferring extensions with open-source codebases
- Removing extensions that are no longer actively maintained

This is not automated and is tracked here as a known gap.

---

## Accepted risk register

| Risk | Accepted? | Rationale |
|------|-----------|-----------|
| Identity linkage from username | Yes | Open work requires it |
| Hardware fingerprint exposure | Yes | Obscurity not relied upon; fwupd mitigates |
| Software inventory enabling targeted research | Yes | Active scanning is the mitigation |
| AI-assisted attack chain construction | Yes | No practical mitigation; accepted |
| Zero-day exposure window | Yes | Unavoidable; manual update trigger on critical CVEs |
| Flatpak partial scan coverage | Yes | Auto-updates + grype + sandbox |
| Browser extension risk | Yes | Manual hygiene; tracked as known gap |
