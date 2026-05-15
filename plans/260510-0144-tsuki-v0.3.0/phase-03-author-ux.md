---
phase: 3
title: "Author UX + Tier A parity — details, TOC narrow, en.yml, breadcrumbs, prev/next, code-copy UI, lang switcher, hreflang"
status: completed
priority: P2
effort: "2d"
dependencies: [2]
amended: 2026-05-15
completed_date: 2026-05-15
notes: "Narrow-viewport TOC <details> wrap deferred to v0.3.1 (UX ambiguity on wide + tight bundle budget)."
---

# Phase 3: Author UX + Tier A feature parity

## Overview

Three additive improvements: (1) `<details>/<summary>` markdown blocks get styled CSS in light + dark mode (opens "rich content" door without a render hook), (2) on narrow viewports the TOC wraps in a `<details open>` so mobile users don't scroll past 60 lines of nav, (3) ship a starter `i18n/en.yml` so consumers can drop in English without copying every key.

## Context Links

- Source: `plans/reports/code-reviewer-260510-0144-tsuki-v0.2.0-post-release-improvements.md` (P2-1, P2-10, P3-4)

## Requirements

- Functional: `<details>` blocks render styled (border, padding, dark-mode contrast); TOC collapses on `<64rem` viewports; `en.yml` builds clean with `defaultContentLanguage: en`
- Non-functional: CSS additions ≤ 200 B gz total in `single.css`; no JS additions

## Key Insights

- `<details>` doesn't need a Hugo render hook — Hugo passes raw HTML through (with `unsafe: true`); only CSS styling is missing
- `<details>` is also the simplest collapse mechanism for narrow-viewport TOC — no JS, accessible by default
- en.yml is documentation-as-code: signals i18n contract, lowers adoption friction for non-vi readers

## Architecture

- `assets/css/callouts.css` (or new `assets/css/details.css` — decide based on byte budget): `details { border: 1px solid var(--tsuki-border); ... } details[open] summary::marker { ... } summary:focus-visible { outline: ... }`. Dark-mode tokens via existing `[data-theme="dark"]` cascade.
- `layouts/_partials/toc.html`: replace `<aside class="toc">` wrapper logic with conditional. Wide viewport: existing sticky aside. Narrow: `<details class="toc-collapsed" open>` containing same TOC body. CSS-only via media query on visibility, or a tiny class toggle.
- `i18n/en.yml`: mirror every key in `vi.yml`, English values. Keep vi.yml canonical (don't add new keys to en first).

## Related Code Files

- Modify: `assets/css/callouts.css` OR create `assets/css/details.css` + add to Phase 2 single.css bundle
- Modify: `layouts/_partials/toc.html` (narrow-viewport `<details>` wrap)
- Modify: `assets/css/toc.css` (narrow-viewport collapse styles)
- Create: `i18n/en.yml` (~40 keys translated)
- Modify: `docs/customization.md` (document `<details>` styling, en.yml use)
- Modify: `CHANGELOG.md` Unreleased

## Implementation Steps

1. Audit current `<details>` rendering on demo: add a sample `<details>` block to `exampleSite/content/post/render-hooks-demo/index.md`. Screenshot in light + dark.
2. Write CSS for `<details>`: border, padding, hover, `summary` cursor, `[open]` state. Test in both themes. Aim ≤ 150 B gz minified.
3. TOC narrow wrap: in `layouts/_partials/toc.html`, conditionally output `<details class="toc-narrow" open><summary>{{ i18n "tableOfContents" }}</summary>...`. Use CSS `@media (min-width: 64rem) { details.toc-narrow > summary { display: none } details.toc-narrow[open], details.toc-narrow { all: unset } }` to revert to current sticky aside on wide. Verify keyboard nav (Tab into TOC, Enter on summary).
4. Add `tableOfContents` i18n key to `vi.yml` ("Mục lục") if not present, then `en.yml`.
5. Create `i18n/en.yml` from `vi.yml` keys. ~40 keys: skipToContent, search-related (×4), comments, calloutNote/Tip/Important/Warning/Caution, readingTime, wordCount, month, pageNotFound, backHome, featuredProjects, viewAll, relatedPosts, etc. English translations: short, blog-conventional ("Skip to content", "Search", "Reading time: {{ .Count }} min").
6. Test: build demo with `defaultContentLanguage: en` (temp branch); verify no missing-key fallback paths fire.
7. Document in `docs/customization.md`: how to use `<details>`, how to customize details CSS, how to use en.yml or add a third language file.
8. CHANGELOG: Added — details styling, narrow-viewport TOC collapse, i18n/en.yml.

## Todo List

- [ ] Demo `<details>` post for visual reference
- [ ] details CSS in light + dark
- [ ] TOC narrow `<details>` wrap + responsive CSS
- [ ] tableOfContents i18n key in vi.yml + en.yml
- [ ] i18n/en.yml created with all vi.yml keys translated
- [ ] Demo build with `defaultContentLanguage: en` clean
- [ ] docs/customization.md updates
- [ ] CHANGELOG entries

## Success Criteria

- [ ] `<details>` renders with visible border + dark-mode aware in demo post
- [ ] TOC on `<64rem` viewport renders inside `<details open>`; tappable summary
- [ ] Demo site builds with `defaultContentLanguage: en`, no missing-key warnings
- [ ] CSS budget on single.css still ≤ 4 KB gz (Phase 2 cap holds)
- [ ] Keyboard nav: Tab → summary → Enter toggles, Tab continues into TOC links

## Risk Assessment

- **CSS budget pressure:** details CSS adds ~150 B gz; if Phase 2 freed less than expected, drop hover-only enhancements. Hard floor: visible border in both themes.
- **en.yml translation quality:** consumers may want different phrasing. Mitigation: keep en.yml minimal/conventional, document override path.
- **Narrow-viewport TOC interaction with View Transitions:** `<details>` open state is non-document scope; should survive same-document VT. Test on demo.

## Security Considerations

None — additive content/styling only, no new dynamic surface.

## Next Steps

- Phase 4 (WCAG audit + Lighthouse ≥80) inspects this phase's expanded keyboard + visual surface (breadcrumbs links, prev/next links, code-copy button, language switcher dropdown)
- Phase 6 smoke tests get "details renders styled", "breadcrumbs JSON-LD valid", "prev/next link rel-attrs", "code-copy class present", "lang switcher emit gated"

## Added in audit pass (2026-05-15)

Phase 3 grew significantly. Tier A feature parity (researcher report) lives here because it's all author-facing UX, not AI-discovery. Folding into Phase 3 rather than spinning up a Phase 7 because:

1. Shared CSS bundle (`single.css` already touched for `<details>`); 1 bundle pass instead of 2.
2. Shared i18n key updates with the existing en.yml work (breadcrumb labels, prev/next labels, language names).
3. Phase 4 (WCAG + Lighthouse) needs the full surface to audit at once.

Cost: Phase 3 effort 1d → 2d. Cheaper than coordinating a 7th phase.

### A3.1 — Breadcrumbs partial with BreadcrumbList schema (Tier A)

**Source:** researcher-260515-tsuki-vs-stack-papermod-feature-gap.md → Tier A item #3.

**Problem:** Stack + PaperMod ship breadcrumbs; tsuki ships none. Hurts UX clarity on deep posts + loses BreadcrumbList SEO signal.

**Fix:** New partial `layouts/_partials/breadcrumbs.html`. Gated via `params.breadcrumbs.enable` (default off — opt-in per backwards-compat rule). Emits both rendered breadcrumb trail and `BreadcrumbList` JSON-LD when enabled.

**Markup pattern:** `Home > /posts/ > {{ .Title }}` (use `.CurrentSection`, `.Parent`, `.Title`).

**Schema:** Include `BreadcrumbList` JSON-LD inline in the partial (sibling to existing Article JSON-LD in `seo.html`); compose `itemListElement` from same hierarchy.

**Files modified/created:**
- Create: `layouts/_partials/breadcrumbs.html`
- Create: `assets/css/breadcrumbs.css` (~50 B gz; add to Phase 2 `single.css` bundle)
- Modify: `layouts/_default/single.html` or relevant single layout — include partial above article header
- Modify: `docs/config.md` — document `params.breadcrumbs.enable`
- Modify: `i18n/vi.yml` + `i18n/en.yml` — add `breadcrumbHome` (vi: "Trang chủ", en: "Home")

**Success criteria additions:**
- [ ] `params.breadcrumbs.enable: true` renders trail above post title
- [ ] BreadcrumbList JSON-LD parses (jq) and matches rendered trail
- [ ] Disabled by default; absent on all kinds when flag unset
- [ ] Breadcrumb link tap targets ≥48×48 (Phase 4 verifies)

### A3.2 — Prev/Next post navigation (Tier A)

**Source:** researcher-260515 → Tier A item #4.

**Problem:** Stack/PaperMod ship prev/next; tsuki users have to bounce back to list/index.

**Fix:** New partial `layouts/_partials/prev-next.html`. Gated via `params.prevNextNav.enable` (default true — researcher recommends, zero-friction). Uses Hugo's `.PrevInSection` / `.NextInSection`.

**Markup:** `<nav class="prev-next">` with two anchors; `rel="prev"` + `rel="next"` for SEO; visible labels from i18n.

**Files modified/created:**
- Create: `layouts/_partials/prev-next.html`
- Create: `assets/css/prev-next.css` (~100 B gz; add to `single.css` bundle in Phase 2)
- Modify: `layouts/_default/single.html` — include below article body, above related-posts widget
- Modify: `docs/config.md` — document `params.prevNextNav.enable`
- Modify: `i18n/vi.yml` + `i18n/en.yml` — `prevPost` ("Bài trước"/"Previous post"), `nextPost` ("Bài tiếp"/"Next post")

**Success criteria additions:**
- [ ] Renders on post pages when prev or next exists
- [ ] Single-element rendering when only prev OR next exists (don't emit empty cell)
- [ ] `rel="prev"`/`rel="next"` correct
- [ ] Disabled when `params.prevNextNav.enable: false`

### A3.3 — Code-copy button UI polish (Tier A)

**Source:** researcher-260515 → Tier A item #1; combines with existing v0.2.x `code-copy.js` work.

**Problem:** tsuki's `code-copy.js` exists (Phase 2 gates it to post pages) but visual polish lags Stack/PaperMod — button placement, hover state, "copied!" feedback.

**Fix:** CSS polish in `assets/css/code-copy.css` (already in `single.css` bundle post-Phase-2). Add:
- Positioning: top-right of `<pre>`, ~8px offset
- Hover/focus state (visible focus ring per WCAG 2.4.13)
- "Copied!" feedback via `.code-copy[data-state="copied"]` ARIA-live region content
- Tap target ≥48×48 (Phase 4 verifies)

**JS side:** Existing `assets/js/code-copy.js` should set `aria-label` (i18n via inline data attr or `i18n` key — pick simplest), toggle `data-state`, restore after 2s. Verify `navigator.clipboard` guard exists; hide button if unavailable per unresolved Q4 recommendation.

**Files modified:**
- Modify: `assets/css/code-copy.css` — visual polish (~100 B gz add)
- Modify: `assets/js/code-copy.js` — aria-label + data-state lifecycle (verify; may already be present)
- Modify: `i18n/vi.yml` + `i18n/en.yml` — `copyCode` ("Sao chép"/"Copy"), `copiedCode` ("Đã sao chép"/"Copied!")

**Success criteria additions:**
- [ ] Button visible on `<pre>` blocks in demo post
- [ ] Hidden if `navigator.clipboard` unavailable
- [ ] Click copies + feedback fires + reverts after 2s
- [ ] Focus ring visible in both themes
- [ ] `aria-label` i18n-driven

### A3.4 — Language switcher UI (Tier A)

**Source:** researcher-260515 → Tier B item #7 (promoted because en.yml lands in this phase and switcher pairs naturally).

**Problem:** vi + en translations ship but no visible switcher. Adopters with multilingual sites can't expose the switch.

**Fix:** New partial `layouts/_partials/lang-switcher.html`. Auto-hides when `site.IsMultiLingual` is false. Renders as a small dropdown or inline list of `.AllTranslations`.

**Files modified/created:**
- Create: `layouts/_partials/lang-switcher.html`
- Create: `assets/css/lang-switcher.css` (~150 B gz; add to `core.css` bundle since header is global)
- Modify: `layouts/_partials/header.html` — include partial in nav region
- Modify: `docs/config.md` — document i18n setup + switcher behavior

**Success criteria additions:**
- [ ] Switcher hidden when only one language configured
- [ ] Switcher visible when `site.IsMultiLingual: true`
- [ ] Active language indicated (e.g., `aria-current="page"` or visual mark)
- [ ] Keyboard accessible (Tab + Enter)
- [ ] Tap target ≥48×48

### A3.5 — hreflang alternate links (Lighthouse P1-6)

**Source:** code-reviewer-260515-lighthouse-80-baseline-audit.md → P1-6.

**Problem:** Multilingual sites should emit `<link rel="alternate" hreflang="...">` per language for SEO.

**Fix:** ~6 lines in `layouts/_partials/head.html`, gated on `site.IsMultiLingual`. Loop `.AllTranslations`; emit `<link rel="alternate" hreflang="{{ .Language.Lang }}" href="{{ .Permalink }}">` for each, plus `hreflang="x-default"` pointing at the default language version.

**Files modified:**
- Modify: `layouts/_partials/head.html`

**Success criteria additions:**
- [ ] hreflang emit absent when single-language
- [ ] hreflang emit present + correct on multilingual demo (would need temp multilingual demo branch to verify; otherwise verify template logic locally)

### A3.6 — Cover-image override docs (Lighthouse P0-1)

**Source:** code-reviewer-260515 → P0-1.

**Problem:** Reviewer's P0-1 flagged either (a) default cover-image renderer with `images.Resize` srcset pipeline, or (b) documenting the override path. Decision per audit-pass: defer (a) to v0.4.0 (tied to AVIF + responsive-image work); land (b) in v0.3.0 to unblock adopters.

**Fix:** Add a "Cover images" section to `docs/customization.md`. Show how an adopter overrides `_partials/seo.html` or adds a per-post `cover` frontmatter field with their own image pipeline. Note explicit v0.4.0 promise for native srcset/AVIF support.

**Files modified:**
- Modify: `docs/customization.md`

**Success criteria additions:**
- [ ] customization.md has "Cover images" section with copy-paste override snippet
- [ ] Section notes v0.4.0 promise for built-in pipeline

### A3.7 — render-heading aria-label i18n key

**Source:** code-reviewer-260515 → noted alongside en.yml work.

**Problem:** `render-heading.html` likely uses a hard-coded English aria-label for the section-link anchor (e.g., "Link to section").

**Fix:** Audit `layouts/_markup/render-heading.html`; replace any hard-coded label with an `i18n` call. Add the matching key to both `vi.yml` and `en.yml`.

**Files modified:**
- Modify: `layouts/_markup/render-heading.html`
- Modify: `i18n/vi.yml` + `i18n/en.yml` — add `linkToSection` (vi: "Liên kết đến mục", en: "Link to section")

**Success criteria additions:**
- [ ] No hard-coded English strings in render-heading
- [ ] aria-label resolves per active language

### Effort delta

Phase 3 effort 1d → 2d. The work splits roughly:
- Day 1 (original scope): details CSS, TOC narrow, en.yml, customization docs
- Day 2 (audit-pass additions): breadcrumbs (+schema), prev/next, code-copy UI polish, lang switcher, hreflang, render-heading i18n key, cover-image docs

### Implementer notes

- Per project rules: code comments, CSS class names, file names must not reference "P0-1", "Tier A", or "A3.x" — describe the behavior ("breadcrumb partial with schema.org markup", "prev/next post navigation"). Plan artifacts stay in this document and PR description only.
- Single new `single.css` partial pass: breadcrumbs + prev/next + code-copy polish all land in the same `single.css` bundle. Verify aggregate gz size stays ≤4 KB after Phase 2 cleanup.
- Language switcher CSS lands in `core.css` (header surface) not `single.css`.
