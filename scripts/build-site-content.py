#!/usr/bin/env python3
"""Assemble the Zola content tree from the repository's Markdown.

The Markdown files stay as plain CommonMark so they read well on GitHub and
pass the house linters.  This script copies them into Zola's layout, adds
front matter, and rewrites relative links so Zola can check them.

Usage: build-site-content.py <repo-root> <content-dir>
"""

import re
import sys
from pathlib import PurePosixPath
from pathlib import Path

REPO_URL = "https://github.com/huwd/declarative_laptop"

# (source path in the repository, destination under content/, title override)
PAGES = [
    ("README.md", "overview.md", "Overview"),
    ("docs/install.md", "guides/install.md", None),
    ("docs/setup.md", "guides/setup.md", None),
    ("docs/operations.md", "guides/operations.md", None),
    ("docs/local-llm.md", "guides/local-llm.md", None),
    ("HARDWARE.md", "reference/hardware.md", None),
    ("OPSEC.md", "reference/opsec.md", None),
    ("docs/decisions/README.md", "decisions/_index.md", "Decision records"),
    ("docs/decisions/template.md", "decisions/template.md", "Decision record template"),
    ("CLAUDE.md", "contributing/agents.md", "Working with AI agents"),
    ("docs/style-guide.md", "contributing/style-guide.md", None),
]

SECTIONS = {
    "guides": ("Guides", "Install a machine, set it up, and run it."),
    "reference": ("Reference", "Hardware notes and the security threat model."),
    "contributing": ("Contributing", "How to write and work in this repository."),
}


def decision_pages(root: Path):
    for path in sorted((root / "docs/decisions").glob("[0-9][0-9][0-9][0-9]-*.md")):
        yield (f"docs/decisions/{path.name}", f"decisions/{path.name}", None)


def toml_string(value: str) -> str:
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def split_title(text: str, source: str):
    lines = text.splitlines()
    if not lines or not lines[0].startswith("# "):
        sys.exit(f"{source}: expected the first line to be a level-one heading")
    return lines[0][2:].strip(), "\n".join(lines[1:]).lstrip("\n") + "\n"


LINK = re.compile(r"\]\(([^)\s]+)\)")


def rewrite_links(body: str, source: str, site_paths: dict):
    out = []
    in_fence = False
    for line in body.splitlines():
        if line.lstrip().startswith("```"):
            in_fence = not in_fence
        if not in_fence:
            line = LINK.sub(lambda m: "](" + resolve(m.group(1), source, site_paths) + ")", line)
        out.append(line)
    return "\n".join(out) + "\n"


def resolve(target: str, source: str, site_paths: dict) -> str:
    if re.match(r"^[a-z][a-z0-9+.-]*:", target) or target.startswith("#"):
        return target
    path, _, fragment = target.partition("#")
    resolved = PurePosixPath(PurePosixPath(source).parent, path)
    parts = []
    for part in resolved.parts:
        if part == "..":
            parts.pop()
        elif part != ".":
            parts.append(part)
    repo_path = "/".join(parts)
    suffix = f"#{fragment}" if fragment else ""
    if repo_path in site_paths:
        return f"@/{site_paths[repo_path]}{suffix}"
    kind = "tree" if target.endswith("/") or "." not in parts[-1] else "blob"
    return f"{REPO_URL}/{kind}/main/{repo_path}{suffix}"


def main(root: Path, content: Path):
    pages = PAGES[:7] + list(decision_pages(root)) + PAGES[7:]
    site_paths = {src: dest for src, dest, _ in pages}

    for index, (source, dest, override) in enumerate(pages, start=1):
        title, body = split_title((root / source).read_text(), source)
        title = override or title
        body = rewrite_links(body, source, site_paths)
        target = content / dest
        target.parent.mkdir(parents=True, exist_ok=True)
        front = f"+++\ntitle = {toml_string(title)}\nweight = {index}\n"
        if dest == "decisions/_index.md":
            front += 'sort_by = "weight"\n'
        target.write_text(front + "+++\n\n" + body)

    for name, (title, description) in SECTIONS.items():
        target = content / name / "_index.md"
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(
            f'+++\ntitle = {toml_string(title)}\ndescription = {toml_string(description)}\nsort_by = "weight"\n+++\n'
        )


if __name__ == "__main__":
    main(Path(sys.argv[1]), Path(sys.argv[2]))
