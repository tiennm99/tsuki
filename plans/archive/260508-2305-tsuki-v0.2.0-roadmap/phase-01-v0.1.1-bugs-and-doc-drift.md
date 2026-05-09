---
phase: 1
title: "v0.1.1 bugs & doc/code drift"
status: completed
completed_date: 2026-05-08
priority: P1
effort: "1d"
dependencies: []
ships_as: v0.1.1
---

# Phase 1: v0.1.1 bugs & doc/code drift

## Context Links

- Audit: `plans/reports/code-reviewer-260508-2305-tsuki-v0.1.0-audit.md` — Critical + High sections
- Researcher: `plans/reports/researcher-260508-2306-hugo-theme-best-practices.md` — § 8 Performance benchmarks

## Overview

Patch release. Resolve audit-flagged correctness bugs and doc/code drift. No new user-facing features. Goal: docs match behavior, tag URLs survive taxonomy renames, route gates work, no 404 SEO leakage, CSS budget enforced in CI.

## Requirements

**Functional**
- `params.toc.enable` and `params.toc.minWordCount` actually gate render
- Tag/category URLs resolve through Hugo's taxonomy graph (survive renames)
- All template-referenced i18n keys exist in `vi.yml`
- `params.search.enable: false` removes the route, not just the header button
- Home page emits no `<link rel=prev/next>` to non-existent paginated paths
- Code-copy button hidden when `navigator.clipboard` unavailable

**Non-functional**
- CSS bundle ≤ 4 KB gz asserted in CI (fails build if exceeded)
- No CHANGELOG drift after merge

## Architecture

Single-file template + asset edits, no new partials, no JS additions. CI gains one assertion step.

## Related Code Files

**Modify**
- `layouts/single.html:28` — TOC gate
- `layouts/_partials/footer.html:19` — JS TOC gate
- `layouts/_partials/meta.html:16` — replace hardcoded `/tags/` with `.GetTerms`
- `layouts/single.html:21` — same
- `layouts/_partials/head.html:55` — drop `.IsHome` from paginator linking; gate on `gt .Paginator.TotalPages 1`
- `layouts/search/list.html` — wrap body in `params.search.enable | default true`
- `layouts/_partials/home/recent-posts.html:2,15` — bind `$all` once
- `assets/js/code-copy.js:5` — early-return when `!navigator.clipboard`
- `i18n/vi.yml` — add 8 missing keys (`comments`, `month`, `pageNotFound`, `backHome`, `featuredProjects`, `viewAll`, `searchSuggestion`, `altSearch`); remove unused `previousPage`/`nextPage` OR rename pagination call sites
- `docs/data-schemas.md` — security note on `bio` HTML rendering (C2 docs path)
- `.github/workflows/pages.yml` — add CSS budget assertion step

## Implementation Steps

1. **TOC config (C1)** — replace hardcoded 400 in `single.html` and `footer.html` with `site.Params.toc.minWordCount | default 400`; honor `site.Params.toc.enable | default true`. Per-page `Params.toc != false` still wins.
2. **Tag URLs (C3)** — switch `meta.html` and `single.html` tag iteration to `.GetTerms "tags"` + `$term.RelPermalink` + `$term.LinkTitle`. Add same for categories if Phase 2 surfaces them.
3. **i18n keys (H1)** — add the 8 missing keys to `vi.yml` with vi translations. For `month`, return `"Tháng {{ .Number }}"`. Audit `previousPage`/`nextPage` vs `prev`/`next` and unify.
4. **Search gate (H2)** — wrap `search/list.html` body in `{{- if site.Params.search.enable | default true -}}` else emit a localized "search disabled" message.
5. **Home pagination 404 (H4)** — change `head.html` paginator gate to `{{- with .Paginator -}}{{- if gt .TotalPages 1 -}} … {{- end -}}{{- end -}}` and drop `.IsHome` from the kind whitelist. Verify `home.html` doesn't call `.Paginator`.
6. **Code-copy clipboard fallback (H5)** — at top of attach loop, `if (!navigator.clipboard) return;` before button creation.
7. **Recent-posts double-where (H8)** — bind `$all := where (where site.RegularPages "Type" "post") "Draft" false` once; reuse for `len` check. Drop `"Draft" false` unless explicitly supporting `--buildDrafts`.
8. **CSS budget assertion (H3)** — add CI step that gzips the fingerprinted CSS bundle and fails if > 4200 B. Use `find exampleSite/public -name 'tsuki.bundle.*.css'` then `gzip -9 -c | wc -c`.
9. **C2 docs decision** — Maintainer answers Q1 (is `unsafe: true` required?). If no, drop `markup.goldmark.renderer.unsafe: true` from theme defaults and from docs; this kills the bio XSS surface. If yes, add a `! Security` block to `docs/data-schemas.md` near `bio` warning HTML executes.
10. **Verify exampleSite still renders** — `cd exampleSite && hugo --gc --minify` clean.
11. **CHANGELOG** — add `[0.1.1]` section listing each fix. Reference audit IDs in commit body.
12. **Tag and release** — `v0.1.1` git tag.

## Todo

- [x] C1 TOC gate honors `params.toc.{enable,minWordCount}`
- [x] C3 tag URLs use `.GetTerms`
- [x] H1 8 missing i18n keys added; unused keys removed
- [x] H2 `search/list.html` gated on `params.search.enable`
- [x] H4 home Paginator no longer emits dead prev/next links
- [x] H5 code-copy hidden when clipboard API absent
- [x] H8 recent-posts query bound once
- [x] H3 CSS budget asserted in CI (≤ 4200 B gz)
- [x] C2 maintainer decision recorded; docs OR config updated
- [x] CHANGELOG `[0.1.1]` written
- [x] `v0.1.1` tagged

## Success Criteria

- `cd exampleSite && hugo --gc --minify` produces a build with no broken `/tags/...` links (verify with `htmltest`)
- Setting `params.toc.enable: false` in `exampleSite/hugo.yaml` suppresses TOC site-wide
- Setting `params.toc.minWordCount: 99999` suppresses TOC on all current posts
- Renaming `taxonomies: { tag: tag }` in `exampleSite/hugo.yaml` does not produce 404 tag links
- `params.search.enable: false` returns empty `/search/` body with i18n message
- Disabling JS or running on `http://` non-localhost: no orphan code-copy buttons
- CI rejects a PR that pushes `tsuki.bundle.css` gzipped over 4200 B

## Risk Assessment

- **CSS budget cliff**: post-minify is ~3.7-3.9 KB; 4200 B has ~250 B headroom. Risk: any Phase 2/3 CSS addition tips the budget. Mitigation: assertion catches it; if breached, audit which selectors are unused or compressible.
- **i18n key churn**: changing `previousPage` → `prev` (or vice versa) across both templates and `vi.yml` is a textual rename, low risk if grep-driven.
- **`.GetTerms` Vietnamese titles**: tags with diacritics (`ghi-chú`) — verify `.LinkTitle` displays diacritics correctly in browser, not the URL slug.
- **C2 decision** — if maintainer wants `unsafe: true` removed, need to verify exampleSite posts don't use raw HTML; otherwise content breaks.

## Security Considerations

- C2 (XSS via bio) resolved by either docs warning or removing `unsafe: true`. The latter is preferred if compatible with content.
- N5 generator meta privacy — defer to Phase 2 (low priority, doesn't ship in v0.1.1).

## Next Steps

→ Phase 2 (parallel-safe after Phase 1 lands) — accessibility polish picks up M3, L5, M4, render hooks.
