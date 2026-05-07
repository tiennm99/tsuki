# Changelog

All notable changes to tsuki will be documented here. Format follows [Keep a Changelog](https://keepachangelog.com/), versioning follows [SemVer](https://semver.org/).

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
