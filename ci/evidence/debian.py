"""Show what Debian's security tracker records for each finding (ADR 0027, B).

Usage: debian.py <grype.json> <tracker.json> <debian-names.json> <out-dir> <downloaded-on>

Debian triages every CVE in every package it ships, and records a fixed
version. That is another party's judgement, not a fact about our build,
so under 0027 it is evidence: it never removes a finding. Writes to
<out-dir>:

  debian.json   Debian's verdict for each Nix package finding it covers:
                  fixed-upstream  fixed at or below our version, in Debian's
                                  first revision: the upstream release fixed it
                  fixed-debian    fixed at or below our version, but only in a
                                  later Debian revision: maybe Debian's own patch
                  fixed-later     fixed, but in a version above ours
                  not-affected    Debian records its packages as never affected
                  unimportant     open, and Debian rates it unimportant
                  open            open in Debian
  drafts.ttl    a draft triage statement for each package with fixed-upstream
                findings, to check before adding to triage/vulnerabilities.ttl

Debian's sid (unstable) entry is used, because it tracks upstream most
closely. Versions are compared as Nix compares them.
"""

import json
import re
import sys
from collections import defaultdict
from pathlib import Path


def components(version):
    """Split a version as Nix does: runs of digits, runs of other characters."""
    return re.findall(r"[0-9]+|[^0-9.\-]+", version)


def less(a, b):
    """Nix's compareVersionComponents: is component a lower than b?"""
    a_num, b_num = a.isdigit(), b.isdigit()
    if a_num and b_num:
        return int(a) < int(b)
    if a == "" and b_num:
        return True
    if a == "pre" and b != "pre":
        return True
    if b == "pre":
        return False
    if b_num:
        return True
    if a_num:
        return False
    return a < b


def compare(a, b):
    """builtins.compareVersions: -1, 0 or 1."""
    ca, cb = components(a), components(b)
    for i in range(max(len(ca), len(cb))):
        x = ca[i] if i < len(ca) else ""
        y = cb[i] if i < len(cb) else ""
        if less(x, y):
            return -1
        if less(y, x):
            return 1
    return 0


def upstream(debian_version):
    """The upstream part of a Debian version, and its Debian revision."""
    version = debian_version.split(":", 1)[-1]
    upstream_part, _, revision = version.rpartition("-") if "-" in version else (version, "", "")
    upstream_part = re.sub(r"[+~](dfsg|ds|repack|really).*$", "", upstream_part)
    return upstream_part, revision


def verdict(record, ours):
    sid = record.get("releases", {}).get("sid", {})
    status, fixed = sid.get("status"), sid.get("fixed_version")
    if fixed == "0":
        return "not-affected", sid
    if status == "resolved" and fixed:
        version, revision = upstream(fixed)
        if compare(version, ours) > 0:
            return "fixed-later", sid
        return ("fixed-upstream" if revision in ("", "1") else "fixed-debian"), sid
    if status == "open":
        return ("unimportant" if sid.get("urgency") == "unimportant" else "open"), sid
    return None, sid


def turtle_string(text):
    return '"""\n' + text.replace("\\", "\\\\").replace('"""', '\\"\\"\\"') + '\n        """'


def drafts(entries, downloaded_on):
    by_product = defaultdict(list)
    for e in entries:
        if e["verdict"] == "fixed-upstream":
            by_product[(e["package"], e["version"])].append(e)
    lines = [
        f"# Draft triage statements from Debian's security tracker, downloaded {downloaded_on} (ADR 0027).",
        "# Debian is another party's judgement: check each statement before moving it",
        "# into triage/vulnerabilities.ttl, and remove any CVE you can't confirm.",
        "",
        "@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .",
        "@prefix vex: <https://openvex.dev/ns/v0.2.0#> .",
        "@prefix nvd: <https://nvd.nist.gov/vuln/detail/> .",
        "@prefix triage: <https://huwd.github.io/declarative_laptop/ns/triage#> .",
    ]
    for (package, version), found in sorted(by_product.items()):
        found.sort(key=lambda e: e["cve"])
        name = re.sub(r"[^A-Za-z0-9.-]", "-", f"{package}-{version}-debian")
        notes = "\n".join(
            [
                f"        Debian's security tracker records each of these as fixed upstream at or below {version}, in Debian's first revision of that release:",
            ]
            + [f"        {e['cve']} in {e['fixed']}." for e in found]
            + [f"        Checked against the tracker downloaded on {downloaded_on}."]
        )
        lines += [
            "",
            f"triage:{name}",
            "    a triage:Statement ;",
            f"    vex:product <pkg:nix/{package}@{version}> ;",
            "    vex:vulnerability " + " , ".join(f"nvd:{e['cve']}" for e in found) + " ;",
            '    vex:status "fixed" ;',
            "    vex:statusNotes " + turtle_string(notes) + " ;",
            "    rdfs:seeAlso "
            + " , ".join(f"<https://security-tracker.debian.org/tracker/{e['cve']}>" for e in found)
            + " .",
        ]
    return "\n".join(lines) + "\n", len(by_product)


def main():
    grype_path, tracker_path, names_path, out, downloaded_on = sys.argv[1:6]
    report = json.loads(Path(grype_path).read_text())
    tracker = json.loads(Path(tracker_path).read_text())
    names = {k: v for k, v in json.loads(Path(names_path).read_text()).items() if not k.startswith("_")}

    entries = {}
    for match in report["matches"]:
        artifact = match["artifact"]
        if not artifact["purl"].startswith("pkg:nix/"):
            continue
        ids = [match["vulnerability"]["id"]] + [r["id"] for r in match.get("relatedVulnerabilities") or []]
        cve = next((i for i in ids if i.startswith("CVE-")), None)
        if cve is None:
            continue
        key = (artifact["purl"], cve)
        if key in entries:
            continue
        source = names.get(artifact["name"], artifact["name"])
        record = tracker.get(source, {}).get(cve)
        if record is None:
            continue
        result, sid = verdict(record, artifact["version"])
        if result is None:
            continue
        entries[key] = {
            "package": artifact["name"],
            "version": artifact["version"],
            "purl": artifact["purl"],
            "cve": cve,
            "finding": match["vulnerability"]["id"],
            "source": source,
            "verdict": result,
            "fixed": sid.get("fixed_version"),
            "urgency": sid.get("urgency"),
        }

    ordered = sorted(entries.values(), key=lambda e: (e["package"], e["version"], e["cve"]))
    text, drafted = drafts(ordered, downloaded_on)
    out_dir = Path(out)
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "debian.json").write_text(json.dumps(ordered, indent=2) + "\n")
    (out_dir / "drafts.ttl").write_text(text)
    counts = defaultdict(int)
    for e in ordered:
        counts[e["verdict"]] += 1
    print("Debian tracker: " + ", ".join(f"{v} {n}" for v, n in sorted(counts.items()))
          + f"; {drafted} draft statements", file=sys.stderr)


if __name__ == "__main__":
    main()
