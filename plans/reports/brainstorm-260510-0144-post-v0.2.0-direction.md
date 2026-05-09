---
report_type: brainstorm
status: DONE
date: 2026-05-10
inputs:
  - plans/reports/code-reviewer-260510-0144-tsuki-v0.2.0-post-release-improvements.md
  - plans/reports/researcher-260510-0144-hugo-theme-2026-evolution.md
  - plans/reports/project-manager-260510-0144-tsuki-v0.2.0-status.md
---

# Post-v0.2.0 Direction — Recommendation

## Tension stated

Reviewer found 6 "P1" items in the *post-v0.2.0* code review. Should we (a) hold the v0.2.0 tag until they're folded in, or (b) tag v0.2.0 as-is and address the new findings in a follow-up?

## Recommendation: ship v0.2.0 as-is, follow with v0.2.1 patch + v0.3.0 feature release

**Three releases, not one:**

| Release | Scope | Effort | Trigger |
|---|---|---|---|
| **v0.2.0** | mechanical prerelease blockers only — htmltest pin, CI watch, Phase 7 plan accuracy, tag, gallery submit | 0.5 day | now |
| **v0.2.1** | post-release review P1s + dead-CI cleanup | 1 day | within 1–2 weeks of v0.2.0 |
| **v0.3.0** | P2 polish + Tier-1 research items + smoke-test expansion + author UX | 4–5 days | when v0.2.0 has gallery + real-world feedback |

## Why not fold P1s into v0.2.0

1. **Severity reframe.** P1-1 (`render-link.html` `safeHTML`) is *self-XSS* — single-author theme; author writes their own posts. Reviewer's own note: *"threat model is 'I'm hurting myself'"*. Not a stored-XSS-from-untrusted-input vector. Worth fixing, not worth blocking a tag.
2. **Discovered after, not during.** v0.2.0 plan completed and signed off; review was fresh-eyes audit. Folding everything ever found shifts goalposts.
3. **Velocity matters for distribution.** Gallery submission visibility compounds; delay = stale demo, fewer downloads.
4. **v0.2.1 = 1 day.** Surgical patch: 5 P1 fixes + CI pin + dead-branch cleanup. Single commit, fast review, retag.
5. **CI gates haven't regressed.** Smoke tests + htmltest + budget assert still pass. The new findings are not regressions; they were latent.

## Why a v0.3.0 feature release after

Combines two streams that don't fit a patch:
- **From code-review:** P2-2 per-page-kind CSS bundling (frees ~1.2 KB gz headroom — needed for Tier-1 features), P3-1 smoke-test expansion, P3-4 `i18n/en.yml` skeleton.
- **From research:** WCAG 2.2 AA audit + fixes, `llm.txt` artifact, Speculation Rules opt-in, AVIF render-hook docs. Tier-1 items only.
- **From project-manager:** unblock the deferred items audience-signal can justify (lightbox, multi-author) — gather feedback first.

## Main trade-off

| Folding everything into v0.2.0 (rejected) | Three-release sequence (chosen) |
|---|---|
| Single clean release narrative | Three smaller scopes |
| Delays gallery submission ~3–5 days | Gallery submission tomorrow |
| Forces P2 budget split before stable | v0.3.0 frees budget cleanly |
| Higher risk: bigger diff = more review surface | Each release small enough to verify in one sitting |

The chosen path costs *one extra version number* in exchange for shipping something the maintainer already validated, and getting external eyes on the demo site sooner.

## v0.3.0 scope (preview — to be planned next)

Mandatory (carries P1s if v0.2.1 is skipped):
- All P1s from review (5 fixes, ~1 day)
- htmltest-action SHA pin
- Dead CI `if find` branch removed

Theme-budget rebase (enables future features):
- **P2-2** per-page-kind CSS bundling (~1.2 KB gz freed)
- **P2-3** gate `code-copy.js` on `eq .Kind "page"`
- **P2-9** drop redundant `| default ""` calls

Author UX:
- **P2-1** `<details>` styling (CSS only, opens "rich content" door)
- **P2-10** `<details>`-wrap TOC on narrow viewports
- **P3-4** `i18n/en.yml` skeleton (~40 keys translated)

Testing depth:
- **P3-1** smoke-test expansion (callout HTML, JSON-LD valid via `jq`, OG abs URL, dark-theme tokens) — 10 new assertions
- **P3-2** Hugo CI matrix (floor 0.146 + current 0.154)

Research Tier-1:
- **WCAG 2.2 AA audit pass** on exampleSite via Lighthouse — focus appearance / target size / dragging SCs
- **llm.txt** auto-generation under exampleSite (theme metadata → `/llm.txt`)
- **Speculation Rules** as opt-in via `params.prefetch` — Chromium-only, graceful fallback

Deferred to v0.4.0+ (need audience signal):
- AVIF render hook (only after cover-image feature decision)
- pa11y CI integration (after WCAG audit baseline established)
- Multi-author surface, lightbox, KaTeX/Mermaid (per v0.2.0 plan)

## Maintainer decisions still pending (do not block v0.2.0)

These were already flagged in v0.2.0 prerelease checklist; surfaced again here for v0.3.0 planning input:

1. **Goldmark `unsafe: true`** — keep or drop? Dropping eliminates the bio-XSS surface AND P1-1's blast radius. Test: `grep -r '<' content/post/*/index.md` on real sites — if no inline HTML, safe to disable.
2. **Hugo version floor** — bump `theme.toml min_version` to 0.154 (CI-tested) or stay at 0.146 (broader compat)?
3. **Audience signal** — solo bloggers vs teams? Drives multi-author / i18n priority.
4. **Demo site analytics** — opt-in privacy-respecting analytics (e.g., GoatCounter) on `tiennm99.github.io/tsuki/` to inform future feature priority? Currently flying blind.

## Success criteria (v0.3.0)

- All review P1s closed
- CSS budget ≤ 4 KB gz preserved (per-kind split MUST not increase total weight)
- Lighthouse a11y ≥ 95 on exampleSite (currently presumed but unmeasured under WCAG 2.2)
- `i18n/en.yml` complete; theme builds with `defaultContentLanguage: en` without missing-key fallbacks
- Smoke tests catch a synthetic regression in render-link / callout / JSON-LD
- gohugoThemes registry CI green on tagged version

## Unresolved questions

1. Is v0.2.1 acceptable, or does the maintainer prefer to skip it and roll P1s into v0.3.0? (Affects v0.3.0 scope size — adds ~1 day.)
2. Does the maintainer want a real `cover.image` feature in v0.3.0 (would activate AVIF research item), or stay with author-supplied static images?
3. Should `data/profile.yaml: url` be added to documented schema, or removed from `seo.html` read? (Opens a small data-schema doc decision.)
4. Is there capacity for the WCAG 2.2 AA audit pass — needs an evening with axe-devtools or Lighthouse — or defer to v0.3.1?

---

**Status:** DONE
**Summary:** Recommend three-release sequence: v0.2.0 (ship now, mechanical only), v0.2.1 patch (~1 day, P1 review fixes), v0.3.0 (~5 days, budget split + author UX + research Tier-1 + smoke depth). Rejected: folding all post-review P1s into v0.2.0 (delays gallery submission, scope creep, P1s are not v0.2.0 regressions). Output feeds /ck:plan with v0.3.0 phases.
