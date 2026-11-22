"""Prove ffmpeg findings absent when their code isn't compiled in (ADR 0027, D).

Usage: ffmpeg_config.py <grype.json> <sbom.cdx.json> <out-dir>

Some ffmpeg CVEs are in a wrapper around an external library, such as
libavcodec/libaribcaption.c, which ffmpeg compiles only when configured
with --enable-libaribcaption. Each ffmpeg library embeds the configure
flags it was built with, so this reads them from the build in the store.

A finding is proved absent when its description names a wrapper file and
our build was configured with that library explicitly disabled. Nixpkgs
compiles in nearly every internal codec, so internal files aren't checked.
Writes to <out-dir>:

  ffmpeg-config.json          each wrapper finding, and whether it's built
  ffmpeg-config.openvex.json  a "not_affected" statement for each one that isn't

It needs the closure in the store, as it is after `nix build` or in CI.
"""

import json
import re
import sys
import time
from pathlib import Path

PACKAGES = {"ffmpeg", "ffmpeg-headless"}
WRAPPER = re.compile(r"\blib(?:avcodec|avformat|avfilter|avdevice)/(lib[a-z0-9_]+)\.c\b")
FLAG = re.compile(rb"--(enable|disable)-(lib[a-z0-9_]+)")


def flags(lib_output):
    """The --enable-lib* and --disable-lib* flags embedded in libavcodec."""
    library = Path(lib_output) / "lib" / "libavcodec.so"
    if not library.exists():
        return None
    enabled, disabled = set(), set()
    for state, name in FLAG.findall(library.read_bytes()):
        (enabled if state == b"enable" else disabled).add(name.decode())
    return enabled, disabled


def candidates(stem):
    """Configure names for a wrapper file: liboapvenc.c is built by --enable-liboapv."""
    names = [stem]
    for suffix in ("enc", "dec"):
        if stem.endswith(suffix):
            names.append(stem[: -len(suffix)])
    return names


def main():
    grype_path, sbom_path, out = sys.argv[1:4]
    report = json.loads(Path(grype_path).read_text())
    sbom = json.loads(Path(sbom_path).read_text())

    # Each grype artifact keeps its SBOM bom-ref, the derivation path.
    outputs = {}
    for component in sbom.get("components", []):
        paths = [p["value"] for p in component.get("properties", []) if p["name"] == "nix:output_path"]
        outputs[component["bom-ref"]] = paths

    configs = {}
    entries = {}
    for match in report["matches"]:
        artifact, vulnerability = match["artifact"], match["vulnerability"]
        if artifact["name"] not in PACKAGES:
            continue
        files = WRAPPER.findall(vulnerability.get("description") or "")
        if not files:
            continue
        key = (artifact["purl"], vulnerability["id"])
        if key in entries:
            continue
        lib = next((p for p in outputs.get(artifact["id"], []) if p.endswith("-lib")), None)
        if lib not in configs:
            configs[lib] = flags(lib) if lib else None
        config = configs[lib]
        if config is None:
            continue
        enabled, disabled = config
        built = []
        for stem in files:
            names = candidates(stem)
            if any(n in enabled for n in names):
                built.append({"file": stem + ".c", "flag": next(n for n in names if n in enabled), "built": True})
            elif any(n in disabled for n in names):
                built.append({"file": stem + ".c", "flag": next(n for n in names if n in disabled), "built": False})
            else:
                built.append({"file": stem + ".c", "flag": None, "built": None})
        entries[key] = {
            "package": artifact["name"],
            "version": artifact["version"],
            "purl": artifact["purl"],
            "cve": vulnerability["id"],
            "library": lib,
            "files": built,
            # Absent only when every file it names is explicitly disabled.
            "absent": all(f["built"] is False for f in built),
        }

    ordered = sorted(entries.values(), key=lambda e: (e["package"], e["version"], e["cve"]))
    statements = [
        {
            "vulnerability": {"name": e["cve"]},
            "products": [{"@id": e["purl"]}],
            "status": "not_affected",
            "justification": "vulnerable_code_not_present",
            "impact_statement": (
                "The vulnerable code is in "
                + ", ".join(f"{f['file']}, which ffmpeg compiles only with --enable-{f['flag']}" for f in e["files"])
                + f"; this build's libavcodec was configured with --disable-{e['files'][0]['flag']} (ADR 0027)."
            ),
        }
        for e in ordered
        if e["absent"]
    ]
    vex = {
        "@context": "https://openvex.dev/ns/v0.2.0",
        "@id": "urn:declarative-laptop:ffmpeg-config",
        "author": "ci/evidence/ffmpeg_config.py",
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "version": 1,
        "statements": statements,
    }
    out_dir = Path(out)
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "ffmpeg-config.json").write_text(json.dumps(ordered, indent=2) + "\n")
    (out_dir / "ffmpeg-config.openvex.json").write_text(json.dumps(vex, indent=2) + "\n")
    print(f"ffmpeg build config: {len(ordered)} wrapper findings, {len(statements)} not compiled in",
          file=sys.stderr)


if __name__ == "__main__":
    main()
