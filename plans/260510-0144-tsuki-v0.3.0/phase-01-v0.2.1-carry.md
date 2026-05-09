---
phase: 1
title: "v0.2.1 carry — review P1s + CI hygiene"
status: completed
priority: P1
effort: "1d"
dependencies: []
completed_date: 2026-05-10
notes: "All 7 fixes shipped on main pre-tag. v0.2.1 plan owns the tag deliverable."
---

# Phase 1: v0.2.1 carry — review P1s + CI hygiene

## Overview

Conditional phase: if maintainer ships v0.2.1 patch independently, this phase becomes a no-op. Otherwise carries the 5 review P1s + 2 CI hygiene items into v0.3.0 so they don't ship hidden under a "features" banner.

## Context Links

- Source: `plans/reports/code-reviewer-260510-0144-tsuki-v0.2.0-post-release-improvements.md` (P1-1..P1-5, P3-8, P3-9)
- Brainstorm: `plans/reports/brainstorm-260510-0144-post-v0.2.0-direction.md`

## Requirements

- Functional: each P1 fix preserves existing demo-site rendering
- Non-functional: smoke tests + htmltest still green; CSS/JS budget unchanged

## Key Insights

- P1-1 (`render-link.html` `safeHTML`) is self-XSS in single-author theme — fix is consistency, not crit-sec
- P1-2 (`seo.html` profile.url chain) is fragile but currently works; refactor for nil-safety
- htmltest-action floating-tag is supply-chain risk flagged in v0.2.0 prerelease checklist

## Architecture

Surgical edits, no structural changes. Each fix is 1–5 lines.

## Related Code Files

- Modify: `layouts/_markup/render-link.html` (P1-1, P1-6)
- Modify: `layouts/_partials/head/seo.html` (P1-2)
- Modify: `layouts/_partials/home/projects.html` (P1-3)
- Modify: `layouts/_partials/nav.html` (P1-4)
- Modify: `layouts/_partials/comments.html` (P1-5)
- Modify: `.github/workflows/pages.yml` (P3-8 SHA pin, P3-9 dead branch)
- Modify: `docs/data-schemas.md` (document `data/profile.yaml: url` if kept — see plan.md unresolved Q6)
- Modify: `CHANGELOG.md` (Unreleased → 0.3.0 entries)

## Implementation Steps

1. **P1-1** — `render-link.html:10`: drop `| safeHTML` from `{{ .Text | safeHTML }}`. Verify italic/emphasis-in-link still renders (Goldmark emits already-escaped inline HTML via `.Text`). Add demo post `exampleSite/content/post/render-hooks-demo/index.md` with `[*emphasis*](https://example.com)` to confirm.
2. **P1-2** — `seo.html:64`: replace fragile `site.Params.profile.url | default ...` chain with nil-safe `with` blocks resolving `$authorURL` from `site.Params.profile.url`, then `site.Data.profile.url`, then `site.Home.Permalink`.
3. **P1-3** — `projects.html:30,33`: pipe both `repo` and `demo` URLs through `safeURL`; add `noreferrer` to `rel`. Optional `target="_blank"` for external nav (decision: yes, external project links should open new tab).
4. **P1-4** — `nav.html:6`: pipe `.URL` through `relURL`. Idempotent on already-resolved permalinks; fixes sub-path deploys.
5. **P1-5** — `comments.html:1-4`: change gate to `{{- if and $g $g.enable $g.repo $g.repoId $g.categoryId -}}`. Add HTML comment when gated-off for debug visibility.
6. **P3-8** — `.github/workflows/pages.yml:74`: replace `wjdp/htmltest-action@master` with commit SHA. Fetch via `gh api repos/wjdp/htmltest-action/commits/master | jq -r .sha`. Add comment with date + tag for future audit.
7. **P3-9** — `.github/workflows/pages.yml:48-54`: drop dead `if find ... | head -1 | grep -q . then ... else ... fi` guard around Pagefind. Just run `npx pagefind --site exampleSite/public`.
8. Run `hugo --gc --minify -s exampleSite -d exampleSite/public` locally + `./scripts/smoke-tests.sh` to confirm no regression.
9. Update CHANGELOG with each fix in `[Unreleased]` `### Fixed` block.

## Todo List

- [ ] P1-1 render-link.html safeHTML drop + demo post
- [ ] P1-2 seo.html $authorURL nil-safe refactor
- [ ] P1-3 projects.html safeURL + noreferrer + target=_blank
- [ ] P1-4 nav.html .URL relURL pipe
- [ ] P1-5 comments.html stricter gate
- [ ] P3-8 htmltest-action SHA pin
- [ ] P3-9 drop dead Pagefind branch
- [ ] Local build + smoke test verification
- [ ] CHANGELOG entries

## Success Criteria

- [ ] All 5 P1 fixes applied, demo site builds clean
- [ ] htmltest CI step uses pinned SHA (no `@master`)
- [ ] No `if find` dead branch in pages.yml
- [ ] Smoke tests still pass (no new failures)
- [ ] CHANGELOG entries written

## Risk Assessment

- **P1-1 risk:** Dropping `safeHTML` may break a hidden author-side use case. Mitigation: search `exampleSite` for any link-text-with-HTML; if found, document the change in CHANGELOG.
- **P1-2 risk:** Refactor introduces new template error if Hugo idiom drifts. Mitigation: test demo build locally before pushing.
- **P3-8 risk:** SHA pin requires periodic refresh. Mitigation: add Dependabot config for GitHub Actions in v0.3.1 (out of v0.3.0 scope).

## Security Considerations

- P1-1, P1-3 reduce stored-HTML/URL surface
- P3-8 closes supply-chain attack vector via floating master tag

## Next Steps

- Phase 2 depends on Phase 1 completion (clean baseline before structural CSS bundle changes)
- If maintainer ships v0.2.1 first → mark this phase `completed` and skip
