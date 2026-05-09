---
phase: 6
title: "Distribution prep (theme.toml + gallery)"
status: completed
completed_date: 2026-05-09
priority: P2
effort: "0.5d"
dependencies: []
---

# Phase 6: Distribution prep

## Context Links

- Researcher: `plans/reports/researcher-260508-2306-hugo-theme-best-practices.md` — § 5 Theme Distribution Standards
- Audit: `plans/reports/code-reviewer-260508-2305-tsuki-v0.1.0-audit.md` — L1 theme.toml original block, L8 screenshot dims, L9 Pagefind/npm note, N3 module mounts

## Overview

Make the theme installable from the Hugo theme gallery and from Hugo Modules cleanly. Verify image asset dims, clean theme.toml, declare module mounts, document Pagefind behavior under Hugo Modules.

## Requirements

**Functional**
- `theme.toml` validates against gohugoio/hugoThemes registry schema
- `images/screenshot.png` = 1500×1000, `images/tn.png` = 900×600 (verify, not just trust commit message)
- `[module]` mounts declared so theme works under Hugo Module consumption with custom `assetDir`/`layoutDir` overrides
- Documentation explains Pagefind doesn't run automatically under Hugo Module consumption (npm not part of module flow)

**Non-functional**
- Theme passes the "Hugo Basic Example" test (clean install, hugo server, no errors)
- Submission PR to `gohugoio/hugoThemes` is ready (branch + tag)

## Architecture

Pure-config phase. No layout or asset changes.

## Related Code Files

**Modify**
- `theme.toml` — drop empty `[original]`, verify all required fields, finalize tags + features list
- `hugo.yaml` (theme defaults) — add `module:` mounts block
- `images/screenshot.png` — verify or regenerate at 1500×1000
- `images/tn.png` — verify or regenerate at 900×600
- `docs/installation.md` (new) — split installation guide from README; document submodule + Hugo Module + Pagefind quirks
- `README.md` — link to new installation guide
- `package.json` — clarify "Pagefind built in CI; consumer sites need their own pagefind step or accept search-disabled"

**Create**
- `docs/installation.md`

## Implementation Steps

1. **theme.toml audit** — current state has empty `[original]` block (L1). For an original theme, drop it entirely. Final shape:
   ```toml
   name = "tsuki"
   license = "Apache-2.0"
   licenselink = "https://github.com/tiennm99/tsuki/blob/main/LICENSE"
   description = "Vietnamese-first Hugo blog + portfolio. Dark mode, Pagefind search, Giscus comments, View Transitions. Zero build step."
   homepage = "https://github.com/tiennm99/tsuki"
   demosite = "https://tiennm99.github.io/tsuki"
   tags = ["blog", "portfolio", "dark-mode", "search", "vietnamese", "minimal", "view-transitions", "responsive"]
   features = ["responsive", "dark-mode", "search", "comments", "i18n", "pagination"]
   min_version = "0.146.0"

   [author]
     name = "tiennm99"
     homepage = "https://github.com/tiennm99"
   ```
2. **Image dims verification** — `identify -format "%wx%h" images/screenshot.png` and confirm. Same for `tn.png`. Regenerate from a Phase 3-deployed demo if dims wrong.
3. **Module mounts (N3)** — add to theme `hugo.yaml`:
   ```yaml
   module:
     mounts:
       - source: layouts
         target: layouts
       - source: assets
         target: assets
       - source: i18n
         target: i18n
       - source: data
         target: data
       - source: archetypes
         target: archetypes
       - source: static
         target: static
   ```
4. **`docs/installation.md`** — covers:
   - Submodule install
   - Hugo Module install
   - **Pagefind under Hugo Module:** consumers must `npm install pagefind` and add `npx pagefind --site public` to their build, OR accept search-disabled. tsuki's `package.json` covers it for submodule users only.
   - GitHub Pages workflow snippet (lift from `.github/workflows/pages.yml`)
   - Required site `hugo.yaml` keys (already in README; reference)
5. **README slim-down** — remove duplicated install snippets; link to `docs/installation.md`.
6. **Hugo Basic Example test** — clone `gohugoio/hugoBasicExample`, install tsuki as module + as submodule, run `hugo server`, verify clean.
7. **Submission preparation** — fork `gohugoio/hugoThemes`, add `tsuki` submodule pointing at the repo, follow CONTRIBUTING.md exactly. Submit PR after `v0.2.0` tag.
8. **CHANGELOG** — `### Added` module mounts. `### Changed` theme.toml cleanup.

## Todo

- [x] `theme.toml` `[original]` removed
- [x] `theme.toml` `tags`, `features`, `min_version` finalized
- [x] `images/screenshot.png` 1500×1000 verified + updated
- [x] `images/tn.png` 900×600 verified + updated
- [x] `module.mounts` declared in theme `hugo.yaml`
- [x] `docs/installation.md` written (submodule + Hugo Module + Pagefind)
- [x] README links to installation guide; install duplication removed
- [x] Hugo Basic Example smoke-tested with submodule install
- [x] Hugo Basic Example smoke-tested with Hugo Module install
- [x] `gohugoio/hugoThemes` PR ready (waiting for v0.2.0 tag)

## Success Criteria

- `theme.toml` parses cleanly with no Hugo warnings
- Both screenshot images match registry size requirements
- `cd /tmp && git clone hugoBasicExample && hugo mod init x.com/test && echo "module: { imports: [{ path: 'github.com/tiennm99/tsuki' }] }" >> hugo.yaml && hugo server` produces a clean build
- gohugoio/hugoThemes registry submission PR opens green CI

## Risk Assessment

- **Image regen mismatch** — current commit says 1500×1000 + 900×600 added, but verify with `identify`; commit messages aren't ground truth.
- **Module mounts overriding consumer mounts** — Hugo merges; consumer mounts win. Low risk.
- **Pagefind behavior under Module** — biggest gotcha. Misleading if not documented; users will report "search broken." Mitigate with prominent install-doc note.
- **`min_version: 0.146.0` vs Phase 4 callouts requiring 0.150+** — if Phase 4 lands, bump min_version to 0.150.0. Cross-ref Phase 4 step 3.

## Security Considerations

- None new.

## Next Steps

→ Phase 7 — CI hardening can land in parallel and improves the "tested against hugoBasicExample" claim.
