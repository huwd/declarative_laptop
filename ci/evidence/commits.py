"""Check whether each finding's fix commit is in the release we run (ADR 0027, C).

Usage: commits.py <grype.json> <repos.json> <out-dir> [<cache.json>]

Many CVE records link the commit that fixes them. For each grype finding
with no fixed version, on a package listed in repos.json, this asks
GitHub whether a linked commit is an ancestor of the release tag the
package is built from. Writes to <out-dir>:

  commits.json         one entry for each finding it could check:
                         in-release      a fix commit is in the tag: proof
                         not-in-release  the fix commits exist upstream, but
                                         none is in the tag
  commits.openvex.json a "fixed" statement for each in-release finding,
                       which grype reads on its second pass

A commit that GitHub doesn't know in that repository, such as one from a
fork or a distribution's tree, is skipped. A fix backported under a
different commit isn't seen, so not-in-release is evidence, not proof.

Whether a commit is an ancestor of a tag never changes, so each answer is
kept in <cache.json>, when given, and reused on later runs. It reads a
GitHub token from GH_TOKEN or GITHUB_TOKEN, or from `gh auth token`, for
the API rate limit.
"""

import json
import os
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

SHA = re.compile(r"[0-9a-f]{12,40}")
VERSION = re.compile(r"^[0-9][0-9A-Za-z.\-]*$")


def token():
    for name in ("GH_TOKEN", "GITHUB_TOKEN"):
        if os.environ.get(name):
            return os.environ[name]
    try:
        return subprocess.run(
            ["gh", "auth", "token"], capture_output=True, text=True, check=True
        ).stdout.strip()
    except (OSError, subprocess.CalledProcessError):
        return None


class GitHub:
    def __init__(self, cache_path):
        self.token = token()
        self.cache_path = Path(cache_path) if cache_path else None
        self.cache = {}
        if self.cache_path and self.cache_path.exists():
            self.cache = json.loads(self.cache_path.read_text())
        self.calls = 0

    @staticmethod
    def key(repo, tag, sha):
        return f"{repo} {tag} {sha}"

    def fetch(self, triples):
        """Ask GitHub about every (repo, tag, sha) not already in the cache."""
        todo = sorted({t for t in triples if self.key(*t) not in self.cache})
        with ThreadPoolExecutor(max_workers=8) as pool:
            for triple, status in zip(todo, pool.map(lambda t: self._compare(*t), todo)):
                self.cache[self.key(*triple)] = status
        if self.cache_path:
            self.cache_path.parent.mkdir(parents=True, exist_ok=True)
            self.cache_path.write_text(json.dumps(self.cache, indent=0, sort_keys=True) + "\n")

    def compare(self, repo, tag, sha):
        """Return GitHub's compare status of sha against tag, or None."""
        return self.cache.get(self.key(repo, tag, sha))

    def _compare(self, repo, tag, sha):
        url = f"https://api.github.com/repos/{repo}/compare/{tag}...{sha}?per_page=1"
        request = urllib.request.Request(url, headers={"Accept": "application/vnd.github+json"})
        if self.token:
            request.add_header("Authorization", f"Bearer {self.token}")
        for attempt in range(3):
            self.calls += 1
            try:
                with urllib.request.urlopen(request, timeout=30) as response:
                    return json.load(response)["status"]
            except urllib.error.HTTPError as error:
                if error.code in (404, 422):
                    return None
                if error.code in (403, 429, 500, 502, 503) and attempt < 2:
                    time.sleep(5 * (attempt + 1))
                    continue
                raise
        return None


def fix_commits(urls, links):
    """The commit SHAs among a record's URLs that point at the mapped repository."""
    shas = []
    for url in urls:
        if not any(url.startswith(prefix) for prefix in links):
            continue
        found = SHA.findall(url.rsplit("/", 1)[-1]) or SHA.findall(url)
        for sha in found:
            if sha not in shas:
                shas.append(sha)
    return shas


def main():
    grype_path, repos_path, out = sys.argv[1:4]
    cache_path = sys.argv[4] if len(sys.argv) > 4 else None
    report = json.loads(Path(grype_path).read_text())
    repos = {k: v for k, v in json.loads(Path(repos_path).read_text()).items() if not k.startswith("_")}
    github = GitHub(cache_path)
    checked_on = time.strftime("%Y-%m-%d", time.gmtime())

    # First collect every question, so they can be asked in parallel.
    candidates = []
    for match in report["matches"]:
        artifact, vulnerability = match["artifact"], match["vulnerability"]
        if (vulnerability.get("fix") or {}).get("state"):
            continue
        source = repos.get(artifact["name"])
        version = artifact["version"]
        if source is None or not VERSION.match(version):
            continue
        key = (artifact["purl"], vulnerability["id"])
        if any(c[0] == key for c in candidates):
            continue
        shas = fix_commits(vulnerability.get("urls") or [], source["links"])
        if not shas:
            continue
        tag = source["tag"].format(version=version)
        candidates.append((key, artifact, vulnerability["id"], source["repo"], tag, shas))

    github.fetch((repo, tag, sha) for *_, repo, tag, shas in candidates for sha in shas)

    results = {}
    for key, artifact, cve, repo, tag, shas in candidates:
        if key in results:
            continue
        version = artifact["version"]
        statuses = {sha: github.compare(repo, tag, sha) for sha in shas}
        inside = [sha for sha, status in statuses.items() if status in ("behind", "identical")]
        outside = [sha for sha, status in statuses.items() if status in ("ahead", "diverged")]
        if inside:
            status, commits = "in-release", inside
        elif outside:
            status, commits = "not-in-release", outside
        else:
            continue
        results[key] = {
            "package": artifact["name"],
            "version": version,
            "purl": artifact["purl"],
            "cve": cve,
            "status": status,
            "repo": repo,
            "tag": tag,
            "commits": commits,
        }

    entries = sorted(results.values(), key=lambda e: (e["package"], e["version"], e["cve"]))
    statements = [
        {
            "vulnerability": {"name": e["cve"]},
            "products": [{"@id": e["purl"]}],
            "status": "fixed",
            "status_notes": (
                f"The fix commit {e['commits'][0][:12]}, linked from the CVE record, is in "
                f"{e['repo']} at {e['tag']}, the release this package is built from "
                f"(checked {checked_on}, ADR 0027)."
            ),
        }
        for e in entries
        if e["status"] == "in-release"
    ]
    vex = {
        "@context": "https://openvex.dev/ns/v0.2.0",
        "@id": "urn:declarative-laptop:fix-commits",
        "author": "ci/evidence/commits.py",
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "version": 1,
        "statements": statements,
    }
    out_dir = Path(out)
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "commits.json").write_text(json.dumps(entries, indent=2) + "\n")
    (out_dir / "commits.openvex.json").write_text(json.dumps(vex, indent=2) + "\n")
    proved = len(statements)
    print(f"fix commits: {len(entries)} findings checked, {proved} in the release, "
          f"{len(entries) - proved} not, {github.calls} GitHub calls", file=sys.stderr)


if __name__ == "__main__":
    main()
