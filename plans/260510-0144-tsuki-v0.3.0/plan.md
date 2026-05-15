---
title: tsuki v0.3.0 — review fixes carry, budget rebase, a11y 2.2, AI discovery, Lighthouse ≥80
status: completed
created: 2026-05-10
amended: 2026-05-15
completed_date: 2026-05-15
target: v0.3.0 tag, ~6 days effort (5d if v0.2.1 shipped + Phase 1 is no-op; +1d from audit-pass additions)
predecessor: plans/260510-0232-tsuki-v0.2.1-patch/
blockedBy: [260509-0947-v0.2.0-prerelease-checklist, 260510-0232-tsuki-v0.2.1-patch]
source_brainstorm: plans/reports/brainstorm-260510-0144-post-v0.2.0-direction.md
source_reports:
  - plans/reports/code-reviewer-260510-0144-tsuki-v0.2.0-post-release-improvements.md
  - plans/reports/researcher-260510-0144-hugo-theme-2026-evolution.md
  - plans/reports/project-manager-260510-0144-tsuki-v0.2.0-status.md
  - plans/reports/researcher-260515-tsuki-vs-stack-papermod-feature-gap.md
  - plans/reports/code-reviewer-260515-lighthouse-80-baseline-audit.md
---

# tsuki v0.3.0 plan

Carries forward the post-v0.2.0 review P1s (conditional on whether maintainer ships a v0.2.1 patch first), rebases the CSS/JS budget to free headroom, layers WCAG 2.2 AA + AI-discovery features, lands Tier A feature-parity polish (breadcrumbs, prev/next, code-copy UI, language switcher), then expands smoke-test depth to lock the surface in.

## Goal

Ship v0.3.0 with two measurable, observable outcomes:

1. **Lighthouse ≥80 on all 4 categories (Performance, Accessibility, Best Practices, SEO) — target ≥95 on Accessibility specifically — measured against exampleSite on production GitHub Pages deploy.**
2. **Feature parity with Stack/PaperMod on Tier A polish: breadcrumbs (with schema.org BreadcrumbList), prev/next post nav, code-copy button UI, language switcher UI.**

All additions respect the hard CSS ≤4 KB gz / JS ≤1 KB gz budget and the zero-build-step constraint.

## Phases

| # | Phase | Priority | Status | Depends on | Effort |
|---|---|---|---|---|---|
| 1 | [v0.2.1 carry — review P1s + CI hygiene](phase-01-v0.2.1-carry.md) | P1 | completed | v0.2.0 tagged | 1d |
| 2 | [Theme-budget rebase](phase-02-budget-rebase.md) | P1 | completed | Phase 1 | 1d |
| 3 | [Author UX + Tier A parity](phase-03-author-ux.md) | P2 | completed | Phase 2 (CSS bundle layout) | 2d |
| 4 | [WCAG 2.2 AA audit + Lighthouse ≥80 baseline](phase-04-wcag-2.2-audit.md) | P2 | completed | Phase 3 (audit covers new surface) | 1.5d |
| 5 | [AI/discovery — llm.txt + Speculation Rules](phase-05-ai-discovery.md) | P2 | completed | Phase 2 (budget headroom) | 0.5d |
| 6 | [Smoke-test expansion + Hugo CI matrix](phase-06-test-depth.md) | P1 | completed | Phases 1–5 | 0.5d |

## Sequencing

- **Phase 1 conditional:** if v0.2.1 patch ships independently, drop Phase 1 from v0.3.0 scope. Otherwise carry forward — these P1s must not ship under a "v0.3.0 features" banner without being acknowledged.
- **Phase 2 gates 3+5:** per-kind CSS bundling frees ~1.2 KB gz; without it, Phase 5 Speculation Rules + Phase 3 details CSS + Tier A parity (breadcrumbs/prev-next/code-copy) may breach the 4 KB gz budget.
- **Phases 3 + 5 may run parallel** after Phase 2 — different files, no shared CSS partial. Phase 3 grew substantially with Tier A parity additions; budget headroom from Phase 2 is critical.
- **Phase 4 last before Phase 6:** WCAG audit catches regressions from Phases 1–3 changes; Lighthouse ≥80 baseline measured against the full Phase 3 surface; Phase 6 then locks into smoke tests.
- **Phase 6 lands last:** smoke tests assert the actual shipped surface, not in-flight branches.

## Audit-pass integration map (2026-05-15)

Quick reference: where each new audit finding lands.

| Finding | Source | Lands in |
|---|---|---|
| P0-1 cover-image override docs (defer renderer to v0.4.0) | Lighthouse audit | Phase 3 (docs/customization.md note) |
| P0-2 Pagefind UI CSS preload swap | Lighthouse audit | Phase 2 (search/list.html) |
| P0-3 tap-targets ≥48×48 (Lighthouse tighter than WCAG 24×24) | Lighthouse audit | Phase 4 |
| P0-4 `aria-pressed` SSR on theme-toggle | Lighthouse audit | Phase 4 (inline flash script) |
| P1-5 conditional preconnect to giscus.app | Lighthouse audit | Phase 2 (head.html) |
| P1-6 hreflang alternate links | Lighthouse audit | Phase 3 (head.html, gated on `site.IsMultiLingual`) |
| P2-8 darken `--tsuki-fg-subtle` (AA contrast) | Lighthouse audit | Phase 4 (tokens.css) |
| P2-9 pagination disabled-state contrast | Lighthouse audit | Phase 4 |
| P2-15 theme-color meta light/dark variants | Lighthouse audit | Phase 4 |
| P2-16 `<html lang>` fallback to site language | Lighthouse audit | Phase 4 |
| Tier A: breadcrumbs + BreadcrumbList schema | Feature gap | Phase 3 |
| Tier A: prev/next post nav | Feature gap | Phase 3 |
| Tier A: code-copy button UI polish | Feature gap | Phase 3 |
| Tier A: language switcher UI | Feature gap | Phase 3 (UX, not AI discovery → keep here, not Phase 5) |
| render-heading aria-label i18n key | Lighthouse audit | Phase 3 (alongside en.yml work) |
| Smoke: `aria-pressed`, giscus preconnect, tap-target CSS, Pagefind preload, theme-color | Lighthouse audit | Phase 6 |
| Optional: 4 Lighthouse runs on tag via Action | Lighthouse audit | Phase 6 (flagged nice-to-have) |

**No new phase added.** Phase 3 absorbs all Tier A polish (already covers author UX surface; adjacent work is cheaper than a new phase). Phase 3 effort grew from 1d to 2d; Phase 4 from 1d to 1.5d. Total effort: 4-5d → 6d (5d if Phase 1 is no-op).

## Constraints

- CSS ≤ 4 KB gz on **every page kind** (CI-asserted; Phase 2 makes this per-kind not aggregate)
- JS ≤ 1 KB gz site-wide (Phase 2 reduces by gating code-copy.js)
- Zero build step (pure Hugo + browser ES modules)
- Backwards compatible: sites on v0.2.0 must build on v0.3.0 without config changes (new params default off)
- Vietnamese-first (vi.yml stays canonical; en.yml is a starter, not a behavioral switch)

## Out of scope (deferred)

Explicit per researcher Tier B/C + code-reviewer deferred items (do not add to v0.3.0):

- **Image gallery, lightbox, KaTeX, Mermaid** → v0.4.0+ or never; ≤4 KB CSS budget incompatible with these
- **AVIF render hook + responsive srcset pipeline** → v0.4.0 (depends on `images.Resize` pipeline + cover-image feature scope decision)
- **Default cover-image renderer** → v0.4.0 (P0-1 decision documented as override-path only in v0.3.0; see Phase 3)
- **P2-1 SVG-logo JSON-LD issue** → defer to v0.4.0 with cover-image work (needs PNG asset path)
- **Service worker / PWA** → Lighthouse PWA audit is informational only, no project value yet
- **Multi-author bylines, RTL support, image-zoom-on-hover, scroll-to-top button** → v0.4.0+ pending demand signal
- **Disqus / Utterances comment alternatives** → v0.4.0+ if user demand; document override path
- **Custom shortcodes (tabs, columns, video)** → v0.4.0+; document pattern, ship 1-2 examples then
- **Series / subsection routing, email newsletter signup** → out-of-scope by design
- **pa11y CI integration** → v0.3.1 after WCAG 2.2 baseline established
- **Lighthouse-CI GitHub Action (4 runs on tag)** → optional in Phase 6; nice-to-have, flagged for budget cost

## Success criteria

- All 5 review P1s closed (or acknowledged as already shipped in v0.2.1)
- CSS ≤ 4 KB gz on home / single / list / taxonomy / search kinds individually
- **Lighthouse Performance ≥ 80** on home + post (production GitHub Pages)
- **Lighthouse Accessibility ≥ 95** on home + post + list + search (WCAG 2.2 AA)
- **Lighthouse Best Practices ≥ 80** on home + post
- **Lighthouse SEO ≥ 80** on home + post
- Tier A feature parity vs Stack/PaperMod: breadcrumbs (+BreadcrumbList schema), prev/next post nav, code-copy button UI, language switcher UI all gated and documented
- `i18n/en.yml` complete (~40 keys); theme builds with `defaultContentLanguage: en` without missing-key fallbacks
- `<html lang>` resolves from `site.Language.Lang | default "en"` (no hard-coded "vi")
- `hreflang` alternate links emit in `<head>` on multilingual sites
- `theme-color` meta with light/dark variants
- `aria-pressed` SSR-rendered on theme-toggle (set in inline flash script before paint)
- `--tsuki-fg-subtle` passes WCAG AA contrast (≥4.5:1 against bg) in both themes
- Pagefind UI CSS loaded preload-swap (not render-blocking)
- Conditional `preconnect` to giscus.app on comment-enabled post pages
- `/llm.txt` artifact present in exampleSite build output
- Speculation Rules emit when `params.prefetch.enable: true`, absent otherwise
- Smoke tests assert: callout HTML, JSON-LD parses (jq), OG image absolute URL, dark-theme tokens, render-link rel-on-specific-link, code-copy class in CSS bundle, aria-pressed on toggle, giscus preconnect when enabled, tap-target CSS values, Pagefind preload-swap, theme-color meta
- CI matrix green on Hugo 0.146 (floor) + 0.154 (current)
- gohugoThemes registry CI green on tagged commit (carry-forward from v0.2.0 prereq)

## Unresolved questions (maintainer decisions, do not block planning)

Reconciled from researcher (feature gap) + code-reviewer (Lighthouse audit) + prior plan. Deduplicated, grouped thematically.

### A. Scope boundaries

1. **Cover-image feature scope** — defer entirely to v0.4.0 (current plan recommendation) or ship minimal render-hook in v0.3.0 Phase 2? Drives AVIF + responsive srcset + P2-1 SVG-logo JSON-LD timing. *Recommendation: defer; document override path in customization.md per Phase 3.*
2. **v0.2.1 patch** — ship it, or fold its scope into v0.3.0 Phase 1? If folded, drop the "conditional" framing on Phase 1.
3. **Language switcher routing** — must Phase 3 ship the switcher UI, or can en.yml + hreflang land alone with switcher slipping to v0.4.0? *Recommendation: ship in Phase 3 since en.yml is half the value; switcher is small (~200 B CSS + ~100 B JS).*
4. **Code-copy button accessibility** — hide when `navigator.clipboard` unavailable (HTTP non-localhost), or always show with fallback UI? *Recommendation: hide; smaller bundle, fewer states.*
5. **Breadcrumbs schema** — auto-emit `BreadcrumbList` JSON-LD or markup-only? *Recommendation: schema-on; SEO win is the whole point.*

### B. Config + compat

6. **Goldmark `unsafe: true`** — keep (consumer raw-HTML compat) or drop (eliminates bio-XSS surface + reduces P1-1 blast radius)? Test on real sites: `grep -r '<' content/post/*/index.md`. Affects Phase 1 fix shape.
7. **Hugo version floor** — bump `theme.toml min_version` to 0.154 (CI-tested, narrower compat) or keep 0.146 (broader compat, untested)? Affects Phase 6 CI matrix decision.
8. **`data/profile.yaml: url`** — add to documented schema (Phase 1 P1-2 fix), or remove the read in `seo.html`? Schema vs. minimalism trade-off.
9. **`en.yml` as canonical baseline?** — Phase 3 ships en.yml as a starter; should it become canonical (English-first) with vi.yml as overlay, or stay Vietnamese-first? *Recommendation: stay vi-canonical for v0.3.0; revisit if audience signal shifts.*

### C. Visual / token decisions (impact: light-mode visual diff)

10. **`--tsuki-fg-subtle` light-mode value** — currently #888 (3.54:1, fails AA). P2-8 recommends #6b6b6b (~5:1). Confirm visual acceptable, then mirror to dark-mode equivalent. *Recommendation: ship #6b6b6b, document in CHANGELOG under "Changed (visual diff)".*
11. **`<html lang>` default fallback** — replace hard-coded "vi" with `site.Language.Lang | default "en"`. Site-level config wins anyway; this only changes the fallback when `Site.Language.Lang` is empty. *Recommendation: "en" — more sensible default for a theme.*

### D. Operations / observability

12. **Audience signal** — solo bloggers vs teams? Drives whether multi-author / multi-language i18n moves out of deferred for v0.4.0. No code change for v0.3.0.
13. **Demo site analytics** — opt-in privacy-respecting analytics on `tiennm99.github.io/tsuki/` (e.g., GoatCounter)? Currently flying blind on which features get used. Affects v0.3.0+ feature prioritization.
14. **Lighthouse CI in pages.yml** — add 4-run Lighthouse Action on tag commits (home/post/list/search)? Cost: ~3 min CI per tag. *Phase 6 A6.2 leans toward shipping; if maintainer wants minimal CI cost, defer to v0.3.1. Either choice unblocks v0.3.0 tag.*
15. **Stack/PaperMod future drift** — are competitors planning AI chat / embedded analytics that would justify expanding tsuki's shortcode ecosystem? Inform v0.4.0+ roadmap, not v0.3.0.
