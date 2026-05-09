---
title: tsuki v0.2.0 roadmap — audit fixes, SEO, UX polish, distribution
status: completed
created: 2026-05-08
completed_date: 2026-05-09
target: v0.2.0 (with v0.1.1 patch milestone in Phase 1)
source_reports:
  - plans/reports/code-reviewer-260508-2305-tsuki-v0.1.0-audit.md
  - plans/reports/researcher-260508-2306-hugo-theme-best-practices.md
---

# tsuki v0.2.0 Roadmap

Improve the v0.1.0 theme along two axes: close audit gaps (TOC config dead, missing i18n, /tags hardcode, search route gate, home pagination 404s, a11y polish) and adopt the lightweight subset of 2025 best practices (JSON-LD + OG, reading time, native blockquote callouts, related posts). Stay inside the existing budget (CSS ≤ 4 KB gz, JS ≤ 1 KB gz, zero build step).

## Phases

| # | Phase | Priority | Status | Notes |
|---|---|---|---|---|
| 1 | [v0.1.1 bugs & doc drift](phase-01-v0.1.1-bugs-and-doc-drift.md) | P1 | completed | Ship as `v0.1.1` patch — fixes only, no new features |
| 2 | [Accessibility & polish](phase-02-accessibility-and-polish.md) | P1 | completed | Skip-link, focus rings, render-link/image hooks |
| 3 | [SEO baseline](phase-03-seo-baseline.md) | P1 | completed | JSON-LD Article + OG + Twitter |
| 4 | [Author UX](phase-04-author-ux.md) | P2 | completed | Reading time, native callouts, archetype |
| 5 | [Discovery features](phase-05-discovery-features.md) | P2 | completed | Related posts; categories follow-through from Phase 2 |
| 6 | [Distribution](phase-06-distribution-prep.md) | P2 | completed | theme.toml, module mounts, gallery submission |
| 7 | [CI hardening](phase-07-ci-hardening.md) | P3 | completed | htmltest, optional Lighthouse, budget assert (Phase 1 cross-ref) |

## Sequencing

- Phase 1 ships independently as `v0.1.1`.
- Phases 2–4 can run in parallel after Phase 1 (no file conflicts).
- Phase 5 depends on Phase 2's categories visibility decision.
- Phase 6 + 7 are independent; can land any time.
- Target `v0.2.0` = Phases 1–6 complete. Phase 7 may slip to `v0.2.1`.

## Deferred (out of scope, do not add to core)

Per CHANGELOG and researcher Tier 3:
- KaTeX math, Mermaid diagrams, image lightbox/gallery
- Multi-author support, multilingual (en) i18n
- Self-hosted woff2, tag cloud widget

These remain opt-in extensions; consumers add them per-site if needed.

## Outcome

**v0.2.0 delivered**: All 7 phases complete. v0.1.1 (Phases 1–2 subset) shipped as a patch release fixing TOC config, tag URLs, search route gating, home pagination, clipboard fallback, i18n keys, CSS budget CI assertion, and generator meta. Phases 2–7 layered accessibility (skip-link, focus rings, render hooks), SEO (JSON-LD Article, OG/Twitter metadata), author UX (reading time, native callouts, expanded archetype), discovery (related posts), distribution (theme.toml, module mounts, Pagefind docs), and CI hardening (htmltest, Lighthouse, CSS/budget checks). Theme ready for Hugo theme gallery submission. See CHANGELOG [Unreleased] for the full feature list.

## Maintainer decisions to surface (block specific phase steps)

1. **`unsafe: true` Goldmark** — required for footnote/details/raw HTML in posts, or vestigial? If vestigial, drop it (kills C2 XSS surface entirely). Affects Phase 1.
2. **Categories visibility** — surface as pills in `meta.html` or stay routing-only? Affects Phase 2 + Phase 5.
3. **Audience** — solo bloggers vs teams. If teams ever a target, multi-author moves out of "deferred." Affects long-term roadmap, not v0.2.0.
4. **OG image strategy** — auto from `cover.image` (requires per-post cover convention) vs static site logo fallback. Affects Phase 3.

## Success criteria (v0.2.0)

- All audit Critical + High items resolved or explicitly waived with rationale
- Lighthouse SEO ≥ 95 on demo site (currently ~90)
- CSS bundle ≤ 4 KB gz asserted in CI
- Theme accepted to themes.gohugo.io gallery
- CHANGELOG entries for every behavior change

## Unresolved questions

1. Is the homepage ever paginated, or always portfolio-shaped? Drives Phase 1 H4 fix shape.
2. Does `params.toc.enable: false` need to also strip `toc.css` from the bundle, or is dead-byte (~600 B gz) acceptable?
3. Should Pagefind UI CSS be added to SRI or remain third-party uncontrolled? (M6)
4. What's the lowest-supported browser baseline? README says "modern evergreen" — pin a version (Chrome 100? Safari 16?) so audit decisions land consistently.
5. Does tsuki need an `i18n/en.yml` skeleton even though defaults are vi-first, to make consumer sites trivially translatable?
