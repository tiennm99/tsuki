---
phase: 6
title: "Smoke-test expansion + Hugo CI matrix"
status: pending
priority: P1
effort: "0.5d"
dependencies: [1, 2, 3, 4, 5]
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
