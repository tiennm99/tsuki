---
phase: 7
title: "CI hardening (htmltest + Lighthouse + budget)"
status: completed
completed_date: 2026-05-09
priority: P3
effort: "0.5d"
dependencies: [1]
---

# Phase 7: CI hardening

## Context Links

- Researcher: `plans/reports/researcher-260508-2306-hugo-theme-best-practices.md` — § 7 CI/Testing best practices
- Audit: `plans/reports/code-reviewer-260508-2305-tsuki-v0.1.0-audit.md` — H3 CSS budget assertion (cross-ref Phase 1)

## Overview

Add automated checks to `.github/workflows/pages.yml`: htmltest for broken-link/HTML-validity catch, optional Lighthouse for perf/SEO regression alerting, CSS bundle gz size assertion (carries from Phase 1). Catches doc/code drift before users do.

## Requirements

**Functional**
- CI fails on broken internal links in exampleSite
- CI fails if CSS bundle > 4200 B gz (already done in Phase 1; ensure consistent)
- CI emits Lighthouse SEO + perf scores (informational; failing thresholds optional)

**Non-functional**
- CI build time stays under 3 minutes total
- No external paid services required

## Architecture

GitHub Actions job additions; no source changes. htmltest runs against built `exampleSite/public/`. Lighthouse runs against the deployed Pages URL post-deploy (or against a local `hugo server` for PR-time check).

## Related Code Files

**Modify**
- `.github/workflows/pages.yml` — add jobs/steps for htmltest, css-budget, optional lighthouse

**Create (optional)**
- `.htmltest.yml` — htmltest config

## Implementation Steps

1. **htmltest setup** — add to `pages.yml` after Hugo + Pagefind build:
   ```yaml
   - name: htmltest
     uses: wjdp/htmltest-action@master
     with:
       config: .htmltest.yml
       path: exampleSite/public
   ```
   `.htmltest.yml`:
   ```yaml
   DirectoryPath: exampleSite/public
   IgnoreURLs:
     - "^https://giscus.app"
     - "^https://github.com/tiennm99"
   CheckExternal: false
   IgnoreInternalEmptyHash: true
   ```
2. **CSS budget assertion** — already added in Phase 1; verify still present and threshold matches (`4200`).
3. **Lighthouse CI (optional)** — add an experimental job that runs on `push` to main only (not PRs, to avoid flake):
   ```yaml
   lighthouse:
     needs: deploy
     runs-on: ubuntu-latest
     continue-on-error: true
     steps:
       - uses: treosh/lighthouse-ci-action@v11
         with:
           urls: |
             https://tiennm99.github.io/tsuki/
             https://tiennm99.github.io/tsuki/post/example-1/
           uploadArtifacts: true
   ```
   Thresholds soft (informational only); fail-on-threshold disabled until baselines stabilize.
4. **Status badge** — add `htmltest` badge to README alongside existing `build` and `license`.
5. **Docs** — add a `docs/ci.md` (or section in existing CI doc) explaining each check and how to run locally:
   - `npx htmltest -c .htmltest.yml exampleSite/public`
   - `du -b exampleSite/public/css/tsuki.bundle.*.css | xargs -I{} gzip -9 -c {} | wc -c`
6. **CHANGELOG** — `### Added` CI checks (this is dev-facing; small note).

## Todo

- [x] htmltest step added; `.htmltest.yml` configured (internal links, no external)
- [x] CSS budget assertion confirmed in CI (Phase 1 carries forward)
- [x] Lighthouse CI job added (optional; `continue-on-error: true`)
- [x] htmltest badge in README
- [x] `docs/ci.md` section added (check instructions)
- [x] First CI run is green (htmltest passes, no false positives)

## Success Criteria

- A PR that breaks an internal link in exampleSite/content fails CI before merge
- A PR that grows CSS bundle past 4200 B gz fails CI before merge
- README shows three green badges: build, htmltest, license
- Lighthouse SEO + perf scores tracked on main pushes

## Risk Assessment

- **htmltest false positives** — anchor links to `#section-id` resolve only if `id` exists at build time. If render hooks change anchor scheme, htmltest breaks. Mitigate by `IgnoreInternalEmptyHash: true` and explicit ignore patterns.
- **Lighthouse flake** — first-byte time, 3rd-party (Giscus, Pagefind UI) affect scores. Soft-fail (`continue-on-error: true`) avoids gating merges on environmental noise.
- **CI minutes** — htmltest fast (~5s); Lighthouse adds ~30s. Total well within free-tier.
- **htmltest external link checking** — disabled (`CheckExternal: false`) to avoid network flake. Internal link graph is the value.

## Security Considerations

- None new. CI runs on stock GitHub-hosted runner; no secrets touched.

## Next Steps

→ Phase 7 closes v0.2.0 dev cycle. After landing: tag `v0.2.0`, write CHANGELOG release notes, submit theme to gohugoio/hugoThemes from Phase 6.
→ Future (v0.3.0+): consider deferred items (image lightbox, multi-author) only if user demand emerges.
