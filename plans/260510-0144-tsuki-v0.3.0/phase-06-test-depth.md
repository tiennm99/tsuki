---
phase: 6
title: "Smoke-test expansion + Hugo CI matrix"
status: completed
priority: P1
effort: "0.5d"
dependencies: [1, 2, 3, 4, 5]
completed_date: 2026-05-15
notes: "Synthetic test posts (lastmod-test, no-tags-test) and Lighthouse-CI workflow deferred to v0.3.1 (optional)."
---

# Phase 6: Smoke-test expansion + Hugo CI matrix

## Overview

Lock the v0.3.0 surface in by extending `scripts/smoke-tests.sh` with ~10 new assertions targeting branches not currently covered (callouts, JSON-LD validity, dark theme, render-hook output, code-copy class) and adding a Hugo version matrix (floor 0.146 vs current 0.154) so theme contract drift is caught early.

## Context Links

- Source: `plans/reports/code-reviewer-260510-0144-tsuki-v0.2.0-post-release-improvements.md` (P3-1, P3-2, P3-11)

## Requirements

- Functional: every new assertion catches a *specific* regression (not generic structural)
- Non-functional: total CI runtime ≤ 5 min on matrix; no flaky checks

## Key Insights

- Current 11 smoke checks are structural (header presence, generator meta, byline) — they pass even when a render hook is broken
- jq is available in GitHub Actions ubuntu-latest; can validate JSON-LD inline
- Hugo CI matrix: 0.146 (theme.toml floor) + 0.154 (current pinned). If 0.146 fails on a feature, decision: bump floor or work around
- Phase 3 demo post (`render-hooks-demo`) gives stable target for callout/details assertions

## Architecture

### Smoke-test additions

```bash
assert_callout()       # post HTML contains <div class="callout callout-note">
assert_jsonld_valid()  # extract JSON-LD with awk, pipe through jq -e empty
assert_og_image_abs()  # og:image content matches https?:// (not relative)
assert_dark_theme()    # css bundle contains [data-theme="dark"] OR prefers-color-scheme: dark
assert_render_link()   # external link has rel="noopener noreferrer", internal does not
assert_code_copy_css() # css bundle contains .code-copy class
assert_skip_link()     # already exists, verify it asserts visible focus path
assert_details()       # post HTML contains <details> with styled border in CSS
assert_llm_txt()       # exampleSite/public/llm.txt exists
assert_no_speculation_default()  # speculationrules absent in default build
assert_per_kind_css_budget()     # each kind ≤ 4096 B gz
```

### CI matrix

```yaml
strategy:
  matrix:
    hugo: ["0.146.0", "0.154.0"]
```

`pages.yml` builds + smokes + htmltests under each. Deploy step runs only on 0.154 (current).

## Related Code Files

- Modify: `scripts/smoke-tests.sh` (~10 new assertions, ~80 lines added)
- Modify: `.github/workflows/pages.yml` (matrix strategy on build + smoke + htmltest)
- Modify: `theme.toml` (decide on `min_version` per Q2 unresolved; bump if 0.146 untenable)
- Add: `exampleSite/content/post/lastmod-test.md` (synthetic post with future Lastmod ≥ 24h, exercises meta.html branch)
- Add: `exampleSite/content/post/no-tags-test.md` (synthetic post with no tags, exercises meta.html / related-posts branch)
- Modify: `CHANGELOG.md`

## Implementation Steps

1. Inventory current `scripts/smoke-tests.sh`: list 11 existing assertions, identify which Phase 1–5 changes need new coverage.
2. Add jq to CI workflow (`apt-get install -y jq` or use built-in ubuntu-latest jq).
3. Write new assertions one by one, running locally after each:
   - **callout** — grep `class="callout callout-note"` on `render-hooks-demo` page
   - **jsonld_valid** — extract `<script type="application/ld+json">...</script>` block, pipe through `jq -e empty`
   - **og_image_abs** — regex: `<meta property="og:image" content="https?://[^"]+"`
   - **dark_theme** — grep CSS bundle for `data-theme="dark"` or `(prefers-color-scheme: dark)`
   - **render_link_rel** — find a known external link in demo post, assert `rel="noopener noreferrer"` on it
   - **code_copy_css** — grep `.code-copy` in CSS bundle
   - **details** — grep `<details>` on demo post, grep CSS for `details {` rule
   - **llm.txt** — `[ -f exampleSite/public/llm.txt ]`
   - **no_speculation_default** — `! grep speculationrules exampleSite/public/index.html`
   - **per_kind_css_budget** — loop over [home, post, list, search]; for each, gzip the linked CSS bundles, sum sizes, assert ≤ 4096
4. Add synthetic test posts for branches not covered by demo content:
   - `lastmod-test.md` with `lastmod: 2099-01-01` to fire Lastmod byline
   - `no-tags-test.md` with `tags: []` to exercise empty-tags branch + no-related-posts branch
5. Update `pages.yml` with matrix on `hugo` versions. Build, smoke, htmltest in each. Deploy gated on `matrix.hugo == '0.154.0'`.
6. Run on temp branch, observe both matrix legs green. If 0.146 fails: triage. Decision per Q2: bump floor or document the 0.146 limitation.
7. CHANGELOG entry under Added: 10+ new smoke assertions + Hugo CI matrix.

## Todo List

- [ ] Inventory existing assertions
- [ ] jq added to CI environment
- [ ] callout assertion
- [ ] jsonld_valid assertion
- [ ] og_image_abs assertion
- [ ] dark_theme assertion
- [ ] render_link_rel assertion
- [ ] code_copy_css assertion
- [ ] details assertion
- [ ] llm.txt assertion
- [ ] no_speculation_default assertion
- [ ] per_kind_css_budget assertion
- [ ] lastmod-test.md synthetic post
- [ ] no-tags-test.md synthetic post
- [ ] Hugo matrix in pages.yml
- [ ] Both matrix legs green
- [ ] CHANGELOG entries

## Success Criteria

- [ ] 21 total smoke assertions (11 existing + 10 new), all pass on demo build
- [ ] CI runs Hugo 0.146 + 0.154; both legs green or theme.toml floor adjusted with rationale
- [ ] Synthetic posts exercise branches not previously covered
- [ ] CI runtime ≤ 5 min including matrix
- [ ] No flaky checks (run CI 3× to confirm)

## Risk Assessment

- **0.146 fails, 0.154 succeeds:** decision blocker per Q2. Mitigation: gather diff, decide floor bump or workaround within phase budget.
- **jq parse errors on legitimate JSON-LD:** Hugo emits unescaped quotes in some edge cases. Mitigation: pre-process with `awk` to extract block; jq operates on extracted string only.
- **CI matrix doubles minutes:** GitHub Actions free tier has limits. Mitigation: free repos have ample minutes; tsuki is OSS.
- **Synthetic test posts surface in production:** they'd appear in demo blog index. Mitigation: `headless: true` in their frontmatter so they don't list.

## Security Considerations

None — test/CI only.

## Next Steps

- v0.3.0 tag candidate post-Phase-6
- Subsequent: gohugoThemes registry CI green check (carry from v0.2.0 prereq)
- Then: tag, release notes, gallery PR

## Added in audit pass (2026-05-15)

New smoke assertions lock in the Lighthouse-audit-driven surface (Phases 2–4 additions) so regressions surface in CI rather than in the next Lighthouse run.

### A6.1 — Additional smoke assertions

**Source:** code-reviewer-260515-lighthouse-80-baseline-audit.md → Phase 6 recommendations.

Add to `scripts/smoke-tests.sh`:

```bash
assert_aria_pressed_ssr()         # post HTML contains aria-pressed on theme-toggle button
assert_giscus_preconnect()        # post page with comments enabled has <link rel="preconnect" href="https://giscus.app">
assert_no_giscus_preconnect_home() # home HTML lacks the giscus preconnect
assert_tap_target_css()           # CSS bundle contains min-height: 2.75rem (or ≥48px equiv) on pagination/toggle classes
assert_pagefind_preload_swap()    # search page HTML contains rel="preload" as="style" + onload swap for pagefind-ui.css
assert_theme_color_meta()         # head HTML contains two <meta name="theme-color"> tags with media= attrs
assert_html_lang_not_hardcoded()  # `<html lang="vi">` only when site lang is vi; test demo build with `defaultContentLanguage: en` produces `<html lang="en">`
assert_breadcrumbs_jsonld()       # post HTML (when breadcrumbs enabled in demo) contains valid BreadcrumbList JSON-LD (jq parse)
assert_prev_next_rel()            # post HTML contains rel="prev" and/or rel="next" anchors
assert_lang_switcher_gated()      # single-language demo site: no lang switcher in header; multilingual: present
assert_hreflang_emit()            # head HTML on multilingual build contains rel="alternate" hreflang
```

**Total additions:** ~10 new assertions on top of the prior 10 in this phase, bringing total to ~30 smoke checks (was 11 baseline + 10 prior phase additions + 10 audit-pass additions).

### A6.2 — Optional: Lighthouse-CI 4 runs on tag

**Source:** code-reviewer-260515 → flagged "nice-to-have given CI cost".

Add a GitHub Action workflow `.github/workflows/lighthouse.yml` triggered on `tag` push. Runs `treosh/lighthouse-ci-action` against 4 URLs (home, sample post, sample list, /search/). Fails the tag publish if any category drops below threshold:
- Performance ≥80
- Accessibility ≥95
- Best Practices ≥80
- SEO ≥80

**Defer-or-ship decision:** add to Phase 6 but mark `optional: true`. Cost is ~3 min CI per tag (cheap on a low-tag-frequency theme repo). Recommendation: ship; the lock-in value of a CI gate on Lighthouse is high relative to the cost.

**If shipped:**
- Create: `.github/workflows/lighthouse.yml`
- Modify: `docs/accessibility.md` — note the CI gate

**If deferred to v0.3.1:**
- Add note to plan.md unresolved Q14 outcome
- Phase 6 stays as-is

### Files modified (cumulative for audit pass)

- Modify: `scripts/smoke-tests.sh` (~10 additional assertions, ~70 more lines)
- Optional: Create `.github/workflows/lighthouse.yml`
- Modify: `CHANGELOG.md` — note CI smoke expansion

### Success criteria additions

- [ ] ~30 total smoke assertions, all pass on demo build
- [ ] aria-pressed assertion catches regression of theme-toggle SSR
- [ ] giscus preconnect assertion fires on/off correctly per page kind + config
- [ ] tap-target CSS assertion catches regression on pagination/toggle
- [ ] Pagefind preload-swap pattern detected on `/search/`
- [ ] theme-color meta tag count = 2
- [ ] hreflang/lang-switcher gating verified on multilingual demo
- [ ] (Optional) Lighthouse-CI workflow fails if any score drops below threshold

### Implementer notes

- Per project rules: smoke-test function names must describe behavior, NOT cite plan/audit labels. E.g., use `assert_aria_pressed_ssr` (good) NOT `assert_P0_4_aria_pressed` (bad). Same rule for shell variables, comments, commit messages, workflow names. Plan codes (P0-X, A6.X) stay in this document only.
- Multilingual smoke assertions need a temp demo branch with a second language file populated; or a `--config exampleSite/hugo.multilang.yaml` fixture. Keep simple: a single fixture file that adds `en` as a secondary language for assertion runs, gated behind a flag in `scripts/smoke-tests.sh`.
- If Lighthouse-CI workflow is shipped: pin action SHA per project security rule (no `@v10` floating tag).
