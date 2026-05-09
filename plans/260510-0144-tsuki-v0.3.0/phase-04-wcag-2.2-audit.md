---
phase: 4
title: "WCAG 2.2 AA audit pass"
status: pending
priority: P2
effort: "1d"
dependencies: [3]
---

# Phase 4: WCAG 2.2 AA audit pass

## Overview

Run Lighthouse + axe-devtools against the demo exampleSite, target WCAG 2.2 AA conformance, fix findings. Focus areas per researcher report: focus appearance (SC 2.4.13), target size 24×24 minimum (SC 2.5.8), dragging movements alternative (SC 2.5.7).

## Context Links

- Source: `plans/reports/researcher-260510-0144-hugo-theme-2026-evolution.md` (Tier 1 a11y)
- W3C WCAG 2.2 SCs: 2.4.11, 2.4.12, 2.4.13 (focus), 2.5.7, 2.5.8 (target size), 3.3.7, 3.3.8 (auth) — only 2.4 + 2.5 SCs apply to this theme

## Requirements

- Functional: keyboard nav covers all interactive elements; focus is visible without ambiguity; all targets ≥ 24×24 CSS pixels
- Non-functional: Lighthouse a11y ≥ 95 on home + post pages; axe issues count = 0 (or documented intentional exceptions)

## Key Insights

- v0.2.0 added focus rings + skip-link (covers SC 2.4.11 minimum). 2.2 adds **focus appearance** (2.4.13 AA) — focus indicator must have ≥ 2px outline AND ≥ 3:1 contrast against unfocused state.
- Target size 2.5.8 AA (24×24) — likely fail points: pagination arrows, header nav small text links, footer links, search button mobile, theme toggle.
- Dragging 2.5.7 — only relevant if there's a slider/drag UI. Theme has none. Verify and document as N/A.

## Architecture

Audit-driven. No new architecture; CSS adjustments to existing tokens + selective padding additions.

## Related Code Files

- Modify: `assets/css/tokens.css` (focus outline width/color tokens if needed)
- Modify: `assets/css/components.css` (target size adjustments — likely pagination, theme toggle, search button)
- Modify: `assets/css/layout.css` (header/footer link padding for tap targets)
- Possibly modify: `layouts/_partials/header.html`, `nav.html`, `pagination.html` (semantic adjustments)
- Add: `docs/accessibility.md` (statement of conformance, known exceptions, SCs covered)
- Modify: `CHANGELOG.md`, `README.md` (a11y badge / claim)

## Implementation Steps

1. Build demo: `hugo --gc --minify -s exampleSite -d exampleSite/public`. Serve locally.
2. Run Lighthouse (CLI or DevTools) on home + post + tag list + search. Capture report.
3. Run axe-devtools (browser extension) on the same pages. Cross-reference.
4. Manual keyboard pass: Tab through entire home + post. Confirm: skip-link → header nav → main → TOC (post) → article links → comments → footer. No traps. All focus rings visible in light + dark.
5. Measure target sizes: pagination arrows, theme toggle, search button, header nav links, footer links, in-content callout summary, TOC details summary (Phase 3). Use DevTools "Inspect → Computed → bounding box". Anything `<24×24` gets `padding` or `min-width`/`min-height`.
6. Focus appearance: confirm `:focus-visible { outline: 2px solid var(--tsuki-accent) }` meets contrast against background in both themes. Adjust accent token if 3:1 contrast fails on either theme.
7. Document SC 2.5.7 (dragging) as N/A — theme has no drag UI.
8. Write `docs/accessibility.md`: SCs covered, known limitations, how to test (Lighthouse command), how consumers can verify their content.
9. Add a11y badge to README (link to `docs/accessibility.md`).
10. CHANGELOG entry under Added/Changed.

## Todo List

- [ ] Lighthouse + axe baseline reports captured
- [ ] Manual keyboard nav verified on all kinds
- [ ] Target size measurements + fixes (≥ 24×24 everywhere)
- [ ] Focus appearance contrast verified ≥ 3:1 in both themes
- [ ] docs/accessibility.md written
- [ ] README a11y badge
- [ ] CHANGELOG entries
- [ ] Lighthouse a11y ≥ 95 on home + post

## Success Criteria

- [ ] Lighthouse a11y ≥ 95 on demo home + post
- [ ] axe-devtools issue count = 0 on home + post + list + search
- [ ] All interactive targets ≥ 24×24 CSS pixels
- [ ] Focus rings visible with ≥ 3:1 contrast in light + dark
- [ ] Skip link functional (Tab once, Enter, scrolls to `<main>`)
- [ ] No keyboard traps
- [ ] docs/accessibility.md published

## Risk Assessment

- **Target size pressure on dense layouts:** pagination + footer often have small visual targets. Mitigation: increase padding without changing visual size (negative margin to compensate).
- **Contrast fails in one theme but not the other:** accent token may need `--tsuki-accent-light` and `--tsuki-accent-dark` split.
- **Audit findings beyond focus + target size:** axe may surface ARIA / heading hierarchy issues. Triage; defer non-2.2 items to v0.3.1 if scope balloons.

## Security Considerations

None.

## Next Steps

- Phase 6 smoke tests get assertions tied to a11y outputs (skip-link, focus token presence)
- v0.3.1 may add pa11y CI integration to lock baseline
