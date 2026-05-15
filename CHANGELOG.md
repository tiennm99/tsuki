# Changelog

All notable changes to tsuki will be documented here. Format follows [Keep a Changelog](https://keepachangelog.com/), versioning follows [SemVer](https://semver.org/).

## [Unreleased] — v0.3.0

Feature-parity round + Lighthouse ≥80 baseline. Six phases per `plans/260510-0144-tsuki-v0.3.0/`. Net: tsuki now ships breadcrumbs, prev/next post navigation, language switcher UI, llm.txt, English i18n bundle, and per-page-kind CSS bundles, while maintaining the ≤4 KB gz / page-kind / ≤1 KB gz JS hard caps.

### Added

- **Per-page-kind CSS bundles** — `head.html` now assembles separate bundles per page kind. `core.css` (tokens + reset + typography + layout + components + view-transitions) loads everywhere; `home.css` only on home; `single.css` (toc + callouts + comments + single-extras) only on posts; `archive.css` only under `/archives/`; `search.css` only on `/search/`. Frees ~1 KB gz from non-post pages and unlocks Phase 3 feature growth without breaching budget.
- **`code-copy.js` gated to post pages** — separate `<script type=module>` emit on `eq .Kind "page"`; home/list/search no longer load the dead 0.5 KB gz.
- **Pagefind UI CSS preload-swap** — `/search/` now `<link rel="preload" as="style" ... onload>` the third-party stylesheet with `<noscript>` fallback. No longer render-blocking.
- **Giscus preconnect** — `<link rel="preconnect" href="https://giscus.app">` emitted only on post pages with comments fully configured. Shaves third-party DNS+TLS handshake.
- **Breadcrumbs partial** (`_partials/breadcrumbs.html`) — opt-in via `params.breadcrumbs.enable`. Renders Home › Section › Page trail above the post header and emits matching `BreadcrumbList` JSON-LD for SEO. Off by default; demo enables it.
- **Prev/next post navigation** (`_partials/prev-next.html`) — opt-in via `params.prevNextNav.enable` (default true). Two-card layout below the post, `rel="prev"` / `rel="next"` for SEO. Renders single-cell when only one neighbour exists.
- **Language switcher UI** (`_partials/lang-switcher.html`) — auto-emits when `hugo.IsMultilingual` is true; renders nothing on single-language sites. Marks active language with `aria-current="page"`.
- **`hreflang` alternate links** — `<link rel="alternate" hreflang="...">` per `.AllTranslations` + `x-default`, gated on `hugo.IsMultilingual`.
- **`i18n/en.yml`** — full English starter (~50 keys) mirroring `vi.yml`. Theme builds with `defaultContentLanguage: en` without missing-key fallbacks.
- **`linkToSection` i18n key** + **`breadcrumb`, `breadcrumbHome`, `prevPost`, `nextPost`, `copyCode`, `copiedCode`** keys added to both bundles.
- **`<meta name="theme-color">`** — two variants for light/dark `(prefers-color-scheme)`. Mobile browsers theme their chrome to match the site.
- **`aria-pressed` SSR** on theme-toggle — rendered in HTML before paint so axe/Lighthouse never see a missing-state toggle button.
- **`<details>` styling** in `single-extras.css` — markdown collapse blocks now render with border + padding + dark-mode awareness.
- **`/llm.txt` output format** — custom Hugo output format on the home; emits a plain-text summary of site + bio + recent posts + projects per [llmstxt.org](https://llmstxt.org). Builds automatically; consumers can override `layouts/index.llmtxt.txt`.
- **Speculation Rules opt-in** — `<script type="speculationrules">` emitted when `params.prefetch.enable: true`. Default rules prefetch internal links with `moderate` eagerness, excluding `/search/*`. Override with `params.prefetch.rules` raw JSON.
- **`docs/accessibility.md`** — WCAG 2.2 AA conformance statement, known limitations, Lighthouse measurement instructions, baseline table (TBD entries to fill on next production deploy).
- **README a11y badge** linking to `docs/accessibility.md`.
- **Hugo CI matrix** — `pages.yml` builds + smoke-tests on Hugo 0.146 (theme.toml floor) and 0.154 (pinned current). Deploy uploads only the current version.
- **15+ new smoke-test assertions** in `scripts/smoke-tests.sh` covering: theme-color meta, aria-pressed SSR, breadcrumbs + BreadcrumbList JSON-LD, prev/next nav with rel attrs, heading-anchor aria-label i18n, llm.txt presence, Speculation Rules absence by default, Pagefind preload-swap, Giscus-preconnect gating, per-page-kind CSS bundle routing, code-copy.js gating. Total checks: 32 (was 11).

### Changed

- **`--tsuki-fg-subtle`** light-mode darkened from `#888` to `#6b6b6b` for WCAG AA contrast (`#888` was 3.54:1 against `#fbfaf7`; fails 4.5:1 body-text threshold). Affects post-card date, pagination disabled state, heading anchor — they now render slightly darker. Dark-mode `#777` unchanged (passes at 4.7:1). Visual diff is subtle; consumers theming the token are unaffected.
- **Pagination disabled state** uses `--tsuki-fg-muted` + `cursor: not-allowed`. Dropped the `opacity: 0.5` compound that double-dimmed text below contrast.
- **Tap targets enlarged** — header theme-toggle + search-button bumped from `2rem` (32px) to `2.5rem` (40px); pagination links use `min-width: 2.75rem; min-height: 2.75rem` (44px); footer links get `padding-block`. Closer to Lighthouse's 48×48 audit target. Header buttons may still trip the strict 48px check; documented in `docs/accessibility.md`.
- **`<html lang>`** fallback chain — was hard-coded `"vi"`; now `site.Language.LanguageCode | default site.Language.Lang | default "en"`. English-default sites no longer paint `lang="vi"`.
- **`render-heading.html` `aria-label`** moved from hard-coded vi to `i18n "linkToSection"` (defaults to "Link to section" when key missing).
- **`code-copy.js`** reads `data-copy-code` / `data-copied-code` from `<html>` (set by `baseof.html` via `i18n` resolution). Adds `data-state="copied"` for CSS styling polish.
- **`scripts/smoke-tests.sh`** asserts per-kind CSS budget (each page kind ≤ 4200 B gz) instead of aggregate. CI workflow drops the now-redundant standalone budget step.

### Fixed

- **CI htmltest URLSwap** — `.htmltest.yml` now strips the `/tsuki/` baseURL prefix so internal-link checks resolve against `exampleSite/public/`. Was failing on every CI run since v0.2.0; deploys did not propagate until this fix. No theme-side change.

### Deferred to v0.3.1

- Narrow-viewport TOC `<details>` collapse (UX ambiguity on wide-viewport summary toggle + CSS budget pressure)
- Synthetic test posts for branch coverage (`lastmod-test.md`, `no-tags-test.md`)
- Optional Lighthouse-CI workflow (manual measurement for now via `docs/accessibility.md`)
- Default cover-image renderer pipeline (`images.Resize` + srcset/AVIF) — see `docs/customization.md` for override snippet; built-in support targeted for v0.4.0

## [0.2.1] — 2026-05-10

Patch release. Closes 5 P1 correctness/security findings from the post-v0.2.0 review plus 2 CI hygiene items. No new features.

### Security

- **Render-link no longer trusts inline HTML in link text** — `layouts/_markup/render-link.html` dropped `| safeHTML` on `.Text`. With Goldmark `unsafe: true`, the prior pipeline allowed `[<img onerror=...>](url)` inner-text to execute. Side effect: italic/emphasis-in-link (`[*x*](url)`) now renders as plain text rather than `<em>`. Restore by overriding the render hook if needed. Self-XSS in single-author themes; consistency fix vs `render-image.html`.
- **Project links sanitize URL + add `noreferrer`** — `layouts/_partials/home/projects.html` pipes `repo`/`demo` URLs through `safeURL` and emits `rel="noopener noreferrer" target="_blank"`. Closes inconsistency with the `render-link` policy and prevents referer leakage to project destinations.
- **Comments gate tightened** — `layouts/_partials/comments.html` now requires `repo`, `repoId`, AND `categoryId` in addition to `enable`. Prevents broken Giscus iframes when partially configured.
- **htmltest GitHub Action pinned to commit SHA** — `.github/workflows/pages.yml` no longer tracks `wjdp/htmltest-action@master`; pinned to `31be84a` for supply-chain hygiene.

### Fixed

- **`seo.html` `$authorURL` chain hardened** — refactored fragile `site.Params.profile.url | default ...` chain into nil-safe `with` blocks. Site builds no longer risk `nil.url` template error when consumers follow the documented `data/profile.yaml`-only configuration.
- **Header navigation respects sub-path deploys** — `layouts/_partials/nav.html` pipes `Menu.URL` through `relURL`. Sites deploying under a sub-path (e.g., GitHub Pages `/repo/`) with `url:`-form menu entries now route correctly.
- **CI Pagefind step simplified** — `.github/workflows/pages.yml` dropped the dead `if find ... | head -1 | grep -q .` guard. Layouts exist; the else branch never triggered.

## [0.2.0] — 2026-05-09

SEO baseline, accessibility polish, author UX, discovery, distribution prep, CI hardening. See [v0.2.0 tag](https://github.com/tiennm99/tsuki/releases/tag/v0.2.0) for highlights.

### Changed

- **TOC gate consolidated** to `_partials/toc-enabled.html` — single source for the `params.toc.{enable,minWordCount}` + per-page `toc: false` predicate, called from `single.html` (TOC partial) and `_partials/footer.html` (toc-active.js loader). Was duplicated 6-line logic in two sites; now one partial. No behavior change.
- **`_partials/head/og-image.html` inlined into `head/seo.html`** — single-call partial removed; the OG image fallback chain (`cover.image` → `image` → `params.og.fallbackImage` → `data/profile.yaml: avatar`) is now expressed once at the top of `seo.html`. Override surface unchanged: replace `head/seo.html` to customize.

### Removed

- **Six unused i18n keys** — `postedOn`, `tags`, `categories`, `archive`, `noResults`, `copyright` were defined in `vi.yml` but never referenced by any template. Dropped along with one accidental duplicate of the callout title block. `vi.yml` reorganized into thematic groups (search/feeds/UI/callouts).

### Added

- **CI smoke tests** (`scripts/smoke-tests.sh`) run after Hugo build — assert JSON-LD on post / not on home, OG/Twitter image emit, skip-link + `<main id="main">`, render-link rel marker, reading-time byline, related-posts aside, CSS budget. 11 checks, fails the workflow on regression. Local-runnable: `./scripts/smoke-tests.sh`.
- **htmltest** (`.htmltest.yml` + GitHub Action) runs after smoke tests — catches broken internal links, missing alt attributes, malformed HTML5 in the demo build. External link checking disabled (network flake).
- **CSS budget badge** in README.
- **Hugo Module mounts** declared in `hugo.yaml` — explicit `module.mounts` list ensures the theme works under Hugo Module consumption with custom site `assetDir`/`layoutDir` overrides.
- **`docs/installation.md`** — single source for submodule + Hugo Module install, Pagefind setup quirks under each, required site-config minimum, post-install verification checklist. README's install section now links here.
- **Related posts** under every single post — `_partials/related-posts.html` uses Hugo's built-in `.Related` index keyed by tags + categories + date, weighted 100/60/10. Section silently disappears when no relations exist. Default 3 cards; tune via `params.relatedPostsCount`. Reuses the existing `post-card.html` partial. Requires `related:` config in site `hugo.yaml` (Hugo no-deep-merge rule); documented in `docs/config.md`.
- **`relatedPosts` i18n key** (`Bài viết liên quan`).
- **Markdown callouts** — `> [!note]`, `> [!tip]`, `> [!important]`, `> [!warning]`, `> [!caution]` render as styled callouts via `_markup/render-blockquote.html`. Five color tokens, light + dark mode tuned. Plain blockquotes pass through unchanged. Titles localize through new `i18n/vi.yml` keys (`calloutNote` etc.); override per-callout with `> [!note] Custom title`. CSS lives in dedicated `assets/css/callouts.css` bundled into the main pipeline.
- **`assets/css/callouts.css`** — added to the concat order in `head.html`.
- **Optional word-count byline** — gated on `params.showWordCount: true` (default off). New `wordCount` i18n key (`{{ .Count }} từ`).
- **Archetype expansion** — `archetypes/default.md` now includes `description`, `cover.image`, and pre-populated `tags`/`categories` placeholders.
- **JSON-LD Article schema** on every post page — `headline`, `datePublished`, `dateModified`, `author` (Person), `publisher` (Organization), `image`, `description`, `keywords`. Emits only when `IsPage && Kind == "page"`; passes `validator.schema.org` for the demo posts.
- **OG/Twitter improvements** — `og:locale` from site language, `article:author`, one `article:tag` per post tag, `twitter:site` + `twitter:creator` from new `params.social.twitter`, OG/Twitter description capped at 200 chars (Twitter limit) via rune-safe `truncate`.
- **`_partials/head/seo.html`** + **`_partials/head/og-image.html`** — extracted from `head.html` for cleaner per-site overrides; OG image resolves through `cover.image` → `image` → `params.og.fallbackImage` → `params.profile.avatar`.
- **`params.author`, `params.social.twitter`, `params.og.fallbackImage`** documented in `docs/config.md`.
- **`cover.image` per-post frontmatter** as the preferred OG/Twitter cover key (legacy `image` still works).
- **Skip-link** — first focusable element on every page; jumps to `<main id="main">` (a11y M3).
- **Visible focus rings** — `:focus-visible { outline: 2px solid var(--tsuki-accent) }` site-wide; previously relied on browser defaults that disappeared in dark mode (a11y M3).
- **`Lastmod` byline** — post meta shows "Cập nhật {date}" when modified date is at least 24 h newer than publish date (audit M2).
- **`_markup/render-link.html`** — external markdown links automatically get `rel="noopener noreferrer"` (audit N1).
- **`_markup/render-image.html`** — in-content markdown images automatically get `loading="lazy" decoding="async"` (audit N2).
- **`skipToContent` i18n key.**
- **Theme-contract notes** in `docs/config.md` documenting taxonomy plural names, Vi tag title bundles, and the full effect of `params.search.enable: false` (forward-looking concerns from the v0.1.1 review).

### Fixed

- **Site title in header + copyright in footer now read from `data/profile.yaml: name`** (previously read from non-existent `params.profile.name`, silently falling back to `site.Title`). Sites with `data/profile.yaml: name` set will see the correct name appear in `<header>` and footer for the first time.

### Changed

- **`<meta name="generator">`** no longer leaks Hugo version — emits `tsuki` only (audit N5).
- **Giscus iframe theme sync** posts the current theme as soon as the iframe is ready, eliminating the brief flash to the default theme on first paint (audit L5).
- **Categories are explicitly routing-only** — `categories` taxonomy still routes under `/categories/<slug>/` but does not surface in post meta. Documented inline in `meta.html`.

### Removed

- **`view-transition-name: var(--tsuki-vt-name, none)`** on `.project-card` — dead declaration; nothing set the variable. Removed pending a future card-morph implementation (audit M4).
- **Empty `[original]` block** dropped from `theme.toml` — tsuki is an original theme, not a fork; the empty fields tripped the Hugo theme registry's malformed-frontmatter check (audit L1).

## [0.1.1] — 2026-05-08

Patch release. Audit fixes and documentation/code drift. No new features.

### Fixed

- **TOC config now honors `params.toc.{enable,minWordCount}`** — previously `single.html` and `footer.html` hardcoded a 400-word threshold and ignored the `enable` flag (audit C1).
- **Tag URLs survive taxonomy renames** — `meta.html` and `single.html` now use `.GetTerms "tags"` + `RelPermalink` instead of hardcoded `/tags/...` (audit C3).
- **`params.search.enable: false` removes the route**, not just the header button. `search/list.html` is now gated; disabled sites get a localized fallback message (audit H2).
- **Home page no longer emits dead `<link rel=prev/next>`** to non-existent paginated URLs. Pagination links emit only on paginated kinds with `>1` page (audit H4).
- **Code-copy buttons hidden when `navigator.clipboard` unavailable** (HTTP non-localhost) — no orphan "Lỗi" buttons on insecure-origin previews (audit H5).
- **`recent-posts.html` query bound once** instead of evaluated twice (audit H8). `Draft` filter dropped (already excluded by `RegularPages`).
- **Seven i18n keys added** to `vi.yml`: six audit-flagged keys (`comments`, `month`, `pageNotFound`, `backHome`, `searchSuggestion`, `altSearch`) plus `searchDisabled` for the new search-disabled fallback (audit H1).

### Changed

- **CI asserts CSS budget ≤ 4200 B gz** on every push. Build fails if the fingerprinted bundle grows beyond the documented limit (audit H3).
- **Removed unused `previousPage`/`nextPage` i18n keys.** Pagination has always used `prev`/`next`.
- **`docs/data-schemas.md`** documents the security implication of `markup.goldmark.renderer.unsafe: true` + `markdownify` on `profile.bio`. Treat `data/profile.yaml` as trusted-author input (audit C2 — documentation path).

[0.1.1]: https://github.com/tiennm99/tsuki/releases/tag/v0.1.1

## [0.1.0] — 2026-05-07

Initial public release.

### Added

- **Layouts** — `baseof`, `home` (hero + projects + recent), `single`, `list`, `archives`, `taxonomy/term`, `_default/taxonomy`, `post/list`, `search/list`, `404`
- **Partials** — `head`, `header`, `footer`, `nav`, `meta`, `post-card`, `pagination`, `archive-group`, `toc`, `comments`, `search-button`, `icon`, `home/{hero,projects,recent-posts}`
- **Render hooks** — `_markup/render-heading.html` for cosmetic anchor links
- **Asset pipeline** — `resources.Concat | minify | fingerprint`. No SCSS, no PostCSS, no Node bundler. CSS bundle ≤ 4 KB gz, JS ≤ 1 KB gz
- **Vietnamese-first** — `time.Format ":date_long"` localized dates, `autoHeadingIDType: github-ascii` for clean URL fragments, line-height tuned for diacritic clearance
- **Dark mode** — CSS custom properties, `prefers-color-scheme` default, persistent toggle via `data-theme` + `localStorage`, no flash on first paint
- **View Transitions API** — `@view-transition: navigation auto` on supported browsers, motion-safe `@keyframes`, falls back to instant nav
- **Table of contents** — sticky on wide viewports, framed block on narrow, IntersectionObserver-driven active heading; gated by `WordCount > 400` and `Params.toc != false`
- **Search** — Pagefind, indexed at build time in CI, UI mounted at `/search/` with full Vi i18n
- **Comments** — Giscus, opt-in via `params.comments.giscus.enable`, theme-sync via `MutationObserver` on `data-theme`
- **i18n** — `i18n/vi.yml` with all UI strings (search, pagination, archive, comments, theme toggle)
- **CI** — `.github/workflows/pages.yml` runs Hugo + Pagefind + uploads to GitHub Pages; `npm ci` resolves Pagefind from `package.json` lockfile (Dependabot-friendly)
- **ExampleSite** — 5 vi-language demo posts, 4 featured projects, profile data, archive, search, all routes verified

### Configuration notes

- Hugo 0.146+ required (uses `_partials`, `_markup`, `_shortcodes` convention).
- Theme defaults are documentation only — Hugo does not deep-merge nested config (`pagination`, `permalinks`, `taxonomies`, `markup`) from themes. Consumer sites must set these in their own `hugo.yaml`. See [`docs/config.md`](docs/config.md).
- Permalink token `:contentbasename` recommended for clean ASCII URLs from leaf bundles.

### Deferred to post-0.1.0

- Self-hosted Be Vietnam Pro / Inter woff2 files (system fonts work fine; user adds woff2 via `static/fonts/` if desired)
- KaTeX math support
- Tag cloud widget
- Image gallery shortcode

[0.1.0]: https://github.com/tiennm99/tsuki/releases/tag/v0.1.0


