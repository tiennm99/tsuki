---
title: tsuki v0.2.0 prerelease checklist
status: pending
created: 2026-05-09
target: v0.2.0 tag + Hugo theme gallery submission
predecessor: plans/archive/260508-2305-tsuki-v0.2.0-roadmap/
---

# v0.2.0 prerelease checklist

The 7-phase v0.2.0 roadmap (`plans/archive/260508-2305-tsuki-v0.2.0-roadmap/`) is shipped to `main`. This plan captures what's left before the `v0.2.0` tag and before submitting to `themes.gohugo.io`.

Three buckets: **mechanical** (I can run autonomously), **decisions** (need maintainer judgment), **external** (network / off-machine).

## Mechanical (low-risk, ready to run)

- [ ] **Pin `wjdp/htmltest-action@master`** to a commit SHA in `.github/workflows/pages.yml`. Floating-tag is supply-chain risk flagged by Phase 7 reviewer. Look up the latest stable release (currently around `@v0.17.0` per the action's repo); pin to its SHA.
- [ ] **Fix Phase 7 plan-TODO accuracy** in `plans/archive/260508-2305-tsuki-v0.2.0-roadmap/phase-07-ci-hardening.md`. Two checkmarks claim work that was deferred — uncheck and add `(deferred)` notes:
  - `- [x] Lighthouse CI job added` → not added; Phase 7 plan note marked it optional and the CI workflow has no `lighthouse:` job
  - `- [x] docs/ci.md section added` → no separate file; CI behavior lives in `CHANGELOG.md` Unreleased section
- [ ] **Watch CI run on the latest pushed commit** (`5d73a13`). Confirm: Hugo build green, Pagefind index built, CSS budget assertion passes, smoke tests pass, htmltest passes, Pages deploy succeeds, demo at https://tiennm99.github.io/tsuki/ shows v0.2.0 features (callouts in sample post, JSON-LD on every post, related-posts aside, skip-link).
- [ ] **Run `/ck:journal`** to write a session journal entry recording the v0.2.0 cycle (audit → research → 7-phase plan → cook execution → code-review pass → commit/push → tag).
- [ ] **Tag `v0.2.0`** with annotated tag pointing to the post-CI HEAD. Release notes derive from `CHANGELOG.md` `[Unreleased]` section; promote that section to `[0.2.0]` with the tag date.

## Maintainer decisions (block specific follow-ups)

- [ ] **Q1 — Goldmark `unsafe: true`** — currently kept for compat. If no posts in your real sites use raw HTML (`<details>`, custom shortcodes, escaped footnote rendering), drop it. That fully eliminates the `profile.bio` XSS surface (audit C2 — currently documented, not closed). Quick test: `grep -r '<' content/post/*/index.md` on your live site; if no inline HTML matches, safe to disable.
- [ ] **Q3 — Audience** — solo bloggers vs teams. Decision affects whether multi-author moves out of the deferred list for v0.3.0+. No code change required for v0.2.0 either way; affects the README's audience framing.

## External / off-machine

- [ ] **Manual smoke against `gohugoBasicExample`** — clone the upstream basic example and install tsuki under both methods:
  ```bash
  git clone https://github.com/gohugoio/hugoBasicExample.git /tmp/he
  cd /tmp/he
  # path A: submodule
  git submodule add ../tsuki themes/tsuki && hugo server  # verify clean
  # path B: Hugo Module
  hugo mod init x.com/test && hugo mod get github.com/tiennm99/tsuki@v0.2.0 && hugo server
  ```
  Verify both produce a usable site. Required by `gohugoio/hugoThemes` registry CI.
- [ ] **Submit to `gohugoio/hugoThemes`** — fork the registry, add `tsuki` as a submodule pointing at the `v0.2.0` tag, follow `gohugoio/hugoThemes/CONTRIBUTING.md`, open PR. Strictly post-tag.

## Optional / nice-to-have

- [ ] Add a callout-emit assertion to `scripts/smoke-tests.sh` (Phase 4 coverage gap flagged by reviewer; e.g., `assert "callout demo" 'class="callout callout-' "$post"`)
- [ ] Add a `theme.toml` parse smoke-test in CI (`hugo --logLevel debug` would surface unparseable TOML; or use a TOML linter)

## Success criteria

- `v0.2.0` tag pushed to `origin`
- GitHub release created with notes derived from CHANGELOG
- All CI gates green on the tagged commit (build + smoke + htmltest + budget + Pages deploy)
- `themes.gohugo.io` submission PR open and CI-green

## Unresolved questions

1. Is there an internal preferred Hugo version baseline (e.g., does the project want to require ≥0.150 to use the latest blockquote alert features cleanly, or stay at 0.146 for a wider compatibility window)?
2. Should the htmltest-action pin be tracked via Dependabot (config exists for `npm`, not for GitHub Actions; could add)?
3. Is the v0.2.0 release date sensitive to anything external (e.g., aligning with a personal blog migration, public announcement)?
