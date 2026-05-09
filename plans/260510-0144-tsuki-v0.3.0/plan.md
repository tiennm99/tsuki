---
title: tsuki v0.3.0 — review fixes carry, budget rebase, a11y 2.2, AI discovery
status: pending
created: 2026-05-10
target: v0.3.0 tag, ~5 days effort (4d if v0.2.1 ships first and Phase 1 becomes no-op)
predecessor: plans/260510-0232-tsuki-v0.2.1-patch/
blockedBy: [260509-0947-v0.2.0-prerelease-checklist, 260510-0232-tsuki-v0.2.1-patch]
source_brainstorm: plans/reports/brainstorm-260510-0144-post-v0.2.0-direction.md
source_reports:
  - plans/reports/code-reviewer-260510-0144-tsuki-v0.2.0-post-release-improvements.md
  - plans/reports/researcher-260510-0144-hugo-theme-2026-evolution.md
  - plans/reports/project-manager-260510-0144-tsuki-v0.2.0-status.md
---

# tsuki v0.3.0 plan

Carries forward the post-v0.2.0 review P1s (conditional on whether maintainer ships a v0.2.1 patch first), rebases the CSS/JS budget to free headroom, layers WCAG 2.2 AA + AI-discovery features, then expands smoke-test depth to lock the surface in.

## Phases

| # | Phase | Priority | Status | Depends on | Effort |
|---|---|---|---|---|---|
| 1 | [v0.2.1 carry — review P1s + CI hygiene](phase-01-v0.2.1-carry.md) | P1 | completed | v0.2.0 tagged | 1d |
| 2 | [Theme-budget rebase](phase-02-budget-rebase.md) | P1 | pending | Phase 1 | 1d |
| 3 | [Author UX — details + TOC narrow + en.yml](phase-03-author-ux.md) | P2 | pending | Phase 2 (CSS bundle layout) | 1d |
| 4 | [WCAG 2.2 AA audit pass](phase-04-wcag-2.2-audit.md) | P2 | pending | Phase 3 (audit covers new surface) | 1d |
| 5 | [AI/discovery — llm.txt + Speculation Rules](phase-05-ai-discovery.md) | P2 | pending | Phase 2 (budget headroom) | 0.5d |
| 6 | [Smoke-test expansion + Hugo CI matrix](phase-06-test-depth.md) | P1 | pending | Phases 1–5 | 0.5d |

## Sequencing

- **Phase 1 conditional:** if v0.2.1 patch ships independently, drop Phase 1 from v0.3.0 scope. Otherwise carry forward — these P1s must not ship under a "v0.3.0 features" banner without being acknowledged.
- **Phase 2 gates 3+5:** per-kind CSS bundling frees ~1.2 KB gz; without it, Phase 5 Speculation Rules + Phase 3 details CSS may breach the 4 KB gz budget.
- **Phases 3 + 5 may run parallel** after Phase 2 — different files, no shared CSS partial.
- **Phase 4 last before Phase 6:** WCAG audit catches regressions from Phases 1–3 changes; Phase 6 then locks them into smoke tests.
- **Phase 6 lands last:** smoke tests assert the actual shipped surface, not in-flight branches.

## Constraints

- CSS ≤ 4 KB gz on **every page kind** (CI-asserted; Phase 2 makes this per-kind not aggregate)
- JS ≤ 1 KB gz site-wide (Phase 2 reduces by gating code-copy.js)
- Zero build step (pure Hugo + browser ES modules)
- Backwards compatible: sites on v0.2.0 must build on v0.3.0 without config changes (new params default off)
- Vietnamese-first (vi.yml stays canonical; en.yml is a starter, not a behavioral switch)

## Out of scope (deferred)

- AVIF render hook → waits on cover-image feature decision (v0.4.0+)
- pa11y CI integration → after WCAG 2.2 baseline established (v0.3.1)
- Multi-author surface, lightbox, KaTeX, Mermaid → per v0.2.0 deferred list
- Cover image processing pipeline → tied to AVIF decision

## Success criteria

- All 5 review P1s closed (or acknowledged as already shipped in v0.2.1)
- CSS ≤ 4 KB gz on home / single / list / taxonomy / search kinds individually
- Lighthouse a11y ≥ 95 on exampleSite under WCAG 2.2 AA
- `i18n/en.yml` complete (~40 keys); theme builds with `defaultContentLanguage: en` without missing-key fallbacks
- `/llm.txt` artifact present in exampleSite build output
- Speculation Rules emit when `params.prefetch.enable: true`, absent otherwise
- Smoke tests assert: callout HTML, JSON-LD parses (jq), OG image absolute URL, dark-theme tokens, render-link rel-on-specific-link, code-copy class in CSS bundle
- CI matrix green on Hugo 0.146 (floor) + 0.154 (current)
- gohugoThemes registry CI green on tagged commit (carry-forward from v0.2.0 prereq)

## Unresolved questions (maintainer decisions, do not block planning)

1. **Goldmark `unsafe: true`** — keep (consumer raw-HTML compat) or drop (eliminates bio-XSS surface + reduces P1-1 blast radius)? Test on real sites: `grep -r '<' content/post/*/index.md`. Affects Phase 1 fix shape.
2. **Hugo version floor** — bump `theme.toml min_version` to 0.154 (CI-tested, narrower compat) or keep 0.146 (broader compat, untested)? Affects Phase 6 CI matrix decision.
3. **Audience signal** — solo bloggers vs teams? Drives whether multi-author / multi-language i18n moves out of deferred for v0.4.0. No code change for v0.3.0.
4. **Demo site analytics** — opt-in privacy-respecting analytics on `tiennm99.github.io/tsuki/` (e.g., GoatCounter)? Currently flying blind on which features get used. Affects v0.3.0+ feature prioritization, not v0.3.0 scope itself.
5. **v0.2.1 patch** — ship it, or fold its scope into v0.3.0 Phase 1? If folded, drop the "conditional" framing on Phase 1.
6. **`data/profile.yaml: url`** — add to documented schema (Phase 1 P1-2 fix), or remove the read in `seo.html`? Schema vs. minimalism trade-off.
