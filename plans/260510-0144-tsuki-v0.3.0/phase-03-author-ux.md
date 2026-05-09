---
phase: 3
title: "Author UX — details + TOC narrow + en.yml"
status: pending
priority: P2
effort: "1d"
dependencies: [2]
---

# Phase 3: Author UX

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

- Phase 4 (WCAG audit) inspects this phase's new keyboard surfaces
- Phase 6 smoke tests get a "details renders styled" assertion
