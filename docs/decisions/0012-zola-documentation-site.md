# 0012. Publish the documentation as a Zola site on GitHub Pages

- **Status:** Accepted
- **Decided by:** @huwd
- **Decided:** 2026-09-23
- **Recorded:** 2026-10-16
- **Discussion:** [#51](https://github.com/huwd/declarative_laptop/issues/51), [#50](https://github.com/huwd/declarative_laptop/issues/50), [#90](https://github.com/huwd/declarative_laptop/pull/90), [#91](https://github.com/huwd/declarative_laptop/pull/91)

## Summary

The guides and decision records are Markdown files in the repository.
GitHub shows them, but offers no search across them and no navigation between them.
A static site generated from the same files fixes both without a second copy of the content.
Zola builds the site, Nix packages the build, and GitHub Pages serves it.

## Context

By October 2026 the repository held install and setup guides, reference pages and a growing set of decision records.
[#50](https://github.com/huwd/declarative_laptop/issues/50) decided which content stays, so that the site wouldn't reorganise it twice.
The repository is already public, so a public site exposes nothing new ([OPSEC.md](../../OPSEC.md)).

The project also builds everything else declaratively, so the site should build the same way: from the repository, with tools pinned by `flake.lock`.

## Options considered

### Zola (chosen)

Zola is a single static Rust binary that nixpkgs packages.
It adds no language dependency tree to the closure, so there is nothing extra for vulnix to track.
Its `@/` links make the build fail when an internal link is broken, and it builds a search index at build time.

Zola has no ready-made documentation theme that fits, so the site uses a small custom theme in `site/`.
That costs some template and CSS work, and it keeps the theme in the repository with no upstream to follow.
The same approach can serve a second repository, which @huwd plans for a separate PC configuration.

### MkDocs Material

MkDocs Material has the best search and navigation out of the box.
It was rejected because the project reaches end of life on 2026-11-05, and its successor, Zensical, was still catching up on features.
Revisit it if Zola's search proves a burden.

### Docusaurus

Docusaurus has the largest dependency tree of the options.
Its extra capabilities, versioned documentation and React-based pages, are things this site doesn't need.

### GitHub's Markdown rendering

Doing nothing keeps one copy of the content and no extra build.
It offers no search across files and no site navigation, which was the problem.

## Decision

`nix build .#docs-site` builds the site with Zola.
`scripts/build-site-content.py` copies the repository's Markdown into Zola's layout and rewrites relative links to `@/` links.
The Markdown files stay as plain CommonMark, so GitHub still renders them and the existing lint checks still apply.

The Docs workflow builds the site when its sources change, and the build fails on any broken internal link.
A push to `main` publishes the result to GitHub Pages.

Pages deployment runs in a separate job with `pages: write` and `id-token: write`, and no repository-content write access.
The build job keeps `contents: read`.
This follows [0008](0008-ci-without-write-access.md): no workflow can commit to the repository, but the deploy job can change what the public site shows.

## Consequences

- Adding a page means adding it to the `PAGES` list in `scripts/build-site-content.py`.
  An explicit list keeps unintended files off the site, and a new page that is missing from the list doesn't appear.
- Search uses elasticlunr, which Zola builds into the site.
  It matches words, not meanings, and it works only in the browser.
- The deploy job is one more place where a compromised tool could publish misleading content, though not change the repository.
  The workflow pins its actions to commit SHAs, as 0008 requires.
- Changes to the site's sources no longer build the laptops' system closures, because they can't affect them.
- GitHub Pages must use "GitHub Actions" as its source, which only a repository administrator can set.
