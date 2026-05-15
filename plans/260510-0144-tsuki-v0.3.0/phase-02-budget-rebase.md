---
phase: 2
title: "Theme-budget rebase — per-kind CSS + JS gate + default cleanup"
status: completed
priority: P1
effort: "1d"
dependencies: [1]
completed_date: 2026-05-15
---

# Phase 2: Theme-budget rebase

## Overview

Frees ~1.2 KB gz from the CSS bundle by switching from "concat-all-on-every-page" to per-page-kind bundles, gates `code-copy.js` on post pages only, and prunes ~30 redundant `| default ""` calls. This phase enables Phase 5 (Speculation Rules) and Phase 3 (details CSS) without breaching the 4 KB gz cap.

## Context Links

- Source: `plans/reports/code-reviewer-260510-0144-tsuki-v0.2.0-post-release-improvements.md` (P2-2, P2-3, P2-9)
- CI assertion: `.github/workflows/pages.yml` CSS budget step

## Requirements

- Functional: every page kind (home, single, list, taxonomy, search) renders identically to v0.2.0
- Non-functional: total CSS gz ≤ 4 KB on **each** kind individually (currently aggregate ≈ 4.2 KB)
- JS gz ≤ 1 KB on site-wide bundle; `code-copy.js` excluded from non-post pages

## Key Insights

- Reviewer estimates ~30% of bundle is dead bytes on home/list/taxonomy (toc.css + comments.css + archive.css unused)
- Per-kind split: `core.css` (always) + `home.css` (home only) + `single.css` (post only, includes toc/callouts/comments) + `archive.css` (list+archives) + `search.css` (search only)
- Hugo `resources.Concat` accepts a slice; `head.html` switches on `.Kind`

## Architecture

```
head.html
├── always: tokens.css + reset.css + typography.css + layout.css + components.css + view-transitions.css → core.css
├── if .Kind == "home": + home.css → home.css
├── if .Kind == "page": + toc.css + callouts.css + comments.css → single.css
├── if .Kind == "term"|"taxonomy"|"section": + archive.css → archive.css
└── if .Section == "search": + search.css → search.css
```

Each bundle: `Concat | minify | fingerprint | resources.Get`, emit one `<link rel="stylesheet" integrity="...">` per applicable bundle.

## Related Code Files

- Modify: `layouts/_partials/head.html` (CSS bundle assembly)
- Modify: `layouts/_partials/footer.html` (gate code-copy.js include on `eq .Kind "page"`)
- Modify: ~10 templates for `| default ""` cleanup (`meta.html`, `header.html`, `footer.html`, `404.html`, `nav.html`, `home/*.html`, `search/list.html`)
- Modify: `.github/workflows/pages.yml` CSS budget step (assert per-kind, not aggregate)
- Modify: `scripts/smoke-tests.sh` (assert per-kind bundle size)
- Modify: `CHANGELOG.md` Unreleased
- Read: `assets/css/*.css` (no changes — partition only)

## Implementation Steps

1. Map current CSS partials → kinds (use Hugo `.Kind` and `.Section`). Document the matrix in head.html comments.
2. Refactor `head.html` to assemble bundles via `slice` + `where` + `resources.Concat`. Keep `core.css` as the fingerprinted base. Conditional bundles get their own `<link>` tags.
3. Update SRI integrity emit to handle multiple bundles (loop over slice).
4. Move `code-copy.js` `<script>` include from `head.html`/`footer.html` to behind `{{- if eq .Kind "page" -}}`. Verify on demo site.
5. Find-and-replace `| default "..."` calls now redundant (vi.yml has all keys post-Phase-1 of v0.2.0):
   - `meta.html` lines for readingTime, wordCount
   - `404.html` for pageNotFound, backHome
   - `home/*.html` for featuredProjects, viewAll
   - `search/list.html` for search/searchSuggestion/altSearch/searchDisabled
   - List ~30 occurrences; remove only redundant defaults, keep defensive ones (e.g., `site.Title | default "tsuki"`)
6. Update CI CSS budget assertion: loop over each bundle kind, assert each ≤ 4096 bytes gz.
7. Update `scripts/smoke-tests.sh` to fetch a sample of each kind and confirm only relevant CSS is `<link>`-loaded.
8. Local build all 5 kinds + visual diff in headless browser (or screenshot via `chrome-devtools` skill).
9. CHANGELOG entry under Changed: per-kind CSS bundles, expected impact on consumers (none if they don't override head.html).

## Todo List

- [ ] CSS partial → kind matrix documented
- [ ] head.html refactor with bundle slices
- [ ] SRI integrity multi-bundle emit
- [ ] code-copy.js gated on page kind
- [ ] Redundant `| default ""` removal pass
- [ ] CI per-kind budget assertion
- [ ] Smoke test per-kind link presence assertion
- [ ] Local build + visual diff verification
- [ ] CHANGELOG entry

## Success Criteria

- [ ] core.css + home.css ≤ 4 KB gz on home page
- [ ] core.css + single.css ≤ 4 KB gz on post page
- [ ] core.css + archive.css ≤ 4 KB gz on list/term/taxonomy
- [ ] core.css + search.css ≤ 4 KB gz on search
- [ ] code-copy.js absent from home/list/search HTML
- [ ] No `| default "{vi-key}"` redundancies remain (≥25 removed)
- [ ] CI passes per-kind budget assertion

## Risk Assessment

- **Cache miss multiplication:** more bundles = more HTTP fetches per first paint per kind. Mitigation: cross-page revisits use `core.css` which is shared and fingerprinted; subsequent kinds add only one extra request.
- **SRI integrity edge case:** Hugo fingerprint+integrity calls per resource. Test on Pagefind UI page where third-party CSS loads (no SRI on third-party).
- **Visual regression:** dropping a CSS file by accident on a kind. Mitigation: smoke test `grep` for kind-specific class on each kind's HTML.

## Security Considerations

- SRI integrity preserved on all internal bundles
- No new third-party assets

## Next Steps

- Phase 3 depends on Phase 2's bundle layout (details CSS + breadcrumbs CSS + prev/next CSS slot into single.css)
- Phase 5 depends on Phase 2's freed budget

## Added in audit pass (2026-05-15)

Cheap perf wins folded in here because they touch the same `head.html` / network-emit surface as the budget rebase. Both are <10 lines each.

### A2.1 — Pagefind UI CSS preload-swap (Lighthouse P0-2)

**Source:** code-reviewer-260515-lighthouse-80-baseline-audit.md → P0-2.

**Problem:** Pagefind UI ships its own stylesheet via `<link rel="stylesheet">` which is render-blocking on the search page.

**Fix:** ~3 lines in `layouts/search/list.html`. Use preload-swap pattern:

```html
<link rel="preload" as="style" href="{{ ... pagefind-ui.css ... }}" onload="this.rel='stylesheet'">
<noscript><link rel="stylesheet" href="{{ ... pagefind-ui.css ... }}"></noscript>
```

**Why this phase:** Phase 2 owns CSS budget + load-order discipline; the Pagefind swap is the same discipline applied to the third-party stylesheet on the one page it lands.

**Files modified:**
- `layouts/search/list.html` — swap link tag

**Success criteria additions:**
- [ ] Pagefind UI CSS uses preload-swap pattern on `/search/`
- [ ] `<noscript>` fallback present (no-JS users still get styled search)

### A2.2 — Conditional preconnect to giscus.app (Lighthouse P1-5)

**Source:** code-reviewer-260515-lighthouse-80-baseline-audit.md → P1-5.

**Problem:** Giscus iframe lazy-loads from `giscus.app` post-paint; no preconnect means TLS+DNS happen on demand, hurting INP on comment-enabled posts.

**Fix:** In `layouts/_partials/head.html`, emit `<link rel="preconnect" href="https://giscus.app">` only when (a) page is a post (`.Kind == "page"`), (b) `params.comments.giscus.enable: true`, and (c) all required Giscus params present (matches Phase 1 P1-5 strict gate).

**Why this phase:** Same gate structure as P1-5 in Phase 1; same `<head>` emit logic as the per-kind CSS bundle in this phase. Single template branch.

**Files modified:**
- `layouts/_partials/head.html` — add conditional preconnect block

**Success criteria additions:**
- [ ] preconnect emits only on post pages with Giscus fully configured
- [ ] absent from home/list/search HTML even when Giscus configured
- [ ] absent from post pages when Giscus disabled or partially configured

### Effort delta

+0.2d (small additions, but verification on demo + smoke test adjustments). Phase 2 still fits in ~1d if Phase 1 work is clean. **Code comments / smoke-test names must not reference "P0-2" or "P1-5"** — describe the behavior ("Pagefind CSS preload swap"; "Giscus preconnect when comments enabled") per project rules.
