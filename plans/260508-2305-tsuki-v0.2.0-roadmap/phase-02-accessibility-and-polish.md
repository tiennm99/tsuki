---
phase: 2
title: "Accessibility & polish"
status: completed
completed_date: 2026-05-09
priority: P1
effort: "1d"
dependencies: [1]
---

# Phase 2: Accessibility & polish

## Context Links

- Audit: `plans/reports/code-reviewer-260508-2305-tsuki-v0.1.0-audit.md` — M1, M2, M3, M4, L5, N1, N2, N5
- Researcher: `plans/reports/researcher-260508-2306-hugo-theme-best-practices.md` — § 3 SEO & a11y baseline

## Overview

Close keyboard-nav and focus-visibility gaps, fix theme-toggle/giscus first-paint flash, decide categories visibility, add render hooks for safer external links and lazy images. No layout changes; CSS additions kept inside budget.

## Requirements

**Functional**
- Skip-link present and functional on every page
- All interactive elements have visible focus rings in dark + light modes
- Giscus opens with the theme already applied (no flash to default theme)
- External markdown links open with `rel="noopener noreferrer"`
- In-content images get `loading="lazy" decoding="async"`
- Categories either surface in UI or are documented as routing-only

**Non-functional**
- WCAG 2.1 AA contrast retained
- Total CSS additions < 200 B gz (skip-link + focus rings)
- No new JS bytes (giscus fix is a 1-line ordering tweak)

## Architecture

CSS-only additions in `components.css` for skip-link + `:focus-visible`. Two new render hooks (`_markup/render-link.html`, `_markup/render-image.html`). Template-level: skip-link in `baseof.html`, `id="main"` on `<main>`, generator meta change.

## Related Code Files

**Create**
- `layouts/_markup/render-link.html`
- `layouts/_markup/render-image.html`

**Modify**
- `layouts/baseof.html` — add `<a class="skip-link">`, `id="main"` on `<main>`
- `layouts/_partials/head.html:7` — drop `hugo.Version` from generator meta (N5)
- `layouts/_partials/comments.html` — restructure giscus init order
- `assets/js/giscus-theme.js` — call `send()` once on load before observer (L5)
- `assets/css/components.css` — `:focus-visible`, `.skip-link` styles
- `assets/css/home.css:82` — remove dead `--tsuki-vt-name` rule OR wire it up to a per-card index (M4)
- `i18n/vi.yml` — add `skipToContent` key
- `layouts/_partials/meta.html` — categories pill (M1, conditional on maintainer decision)
- `layouts/_partials/post-card.html` — `Lastmod` display if present (M2)

## Implementation Steps

1. **Skip-link (M3)** — add to `baseof.html` immediately after `<body>`:
   ```html
   <a class="skip-link" href="#main">{{ i18n "skipToContent" }}</a>
   ```
   Add `id="main"` to `<main>`. CSS: `.skip-link { position: absolute; left: -9999px; } .skip-link:focus { left: 1rem; top: 1rem; z-index: 100; }`.
2. **`:focus-visible` (M3)** — append to `components.css`:
   ```css
   :focus-visible { outline: 2px solid var(--tsuki-accent); outline-offset: 2px; }
   ```
3. **Giscus first-paint (L5)** — in `giscus-theme.js`, run `send()` on load before MutationObserver. Verify Giscus iframe shows correct theme on first render.
4. **Categories decision (M1)** — *maintainer answers Q2 in plan.md.* If "surface": add a small pill list in `meta.html` next to tags using `.GetTerms "categories"`. If "routing-only": add a comment in `meta.html` documenting why categories are deliberately invisible; remove `categories` taxonomy from theme defaults if appropriate.
5. **Lastmod UI (M2)** — in `meta.html`, after the publish date, add `{{- with .Lastmod -}}{{- if ne (. | dateFormat "2006-01-02") ($.Date | dateFormat "2006-01-02") -}}<span class="post-meta-lastmod">{{ i18n "updatedOn" }} {{ . | time.Format ":date_long" }}</span>{{- end -}}{{- end -}}`.
6. **Dead `--tsuki-vt-name` (M4)** — *maintainer chooses:* either delete `home.css:82` line, or wire up by setting `style="--tsuki-vt-name: project-{{ $index }}"` on each card in `home/projects.html`. Default: delete (no demand evidence).
7. **render-link hook (N1)** — `_markup/render-link.html`:
   ```go-html-template
   {{- $isExternal := strings.HasPrefix .Destination "http" -}}
   <a href="{{ .Destination | safeURL }}"
      {{- with .Title }} title="{{ . }}"{{ end }}
      {{- if $isExternal }} rel="noopener noreferrer"{{ end -}}
   >{{ .Text | safeHTML }}</a>
   ```
   Note: deliberately no `target="_blank"` — UX choice; let users opt in.
8. **render-image hook (N2)** — `_markup/render-image.html`:
   ```go-html-template
   <img src="{{ .Destination | safeURL }}" alt="{{ .Text }}" loading="lazy" decoding="async"
        {{- with .Title }} title="{{ . }}"{{ end }} />
   ```
9. **Generator meta (N5)** — `head.html:7` change to `<meta name="generator" content="tsuki">`. No version disclosure.
10. **i18n** — add `skipToContent: "Đến nội dung chính"` and (if M2 lands) confirm `updatedOn` exists.
11. **Bundle size check** — gzip CSS bundle, confirm still ≤ 4200 B. Adjust if needed.
12. **CHANGELOG** — `### Added` for skip-link, render hooks, categories pill (if). `### Changed` for generator meta.

## Todo

- [x] Skip-link in `baseof.html` + `#main` anchor + i18n key
- [x] `:focus-visible` CSS rule
- [x] Giscus initial-paint fix
- [x] Categories surface decision recorded (Q2 answered): **routing-only, explicitly documented in meta.html**
- [x] Categories pill OR routing-only doc note
- [x] Lastmod UI in meta.html (or i18n key removed)
- [x] `--tsuki-vt-name` removed (no use case found)
- [x] `_markup/render-link.html` created
- [x] `_markup/render-image.html` created
- [x] Generator meta no longer leaks Hugo version
- [x] CSS bundle still ≤ 4200 B gz

## Success Criteria

- Tab through homepage from URL bar → first focusable element is skip-link
- Tab navigation through every page shows visible accent-colored ring on each interactive element in both themes
- Giscus loads visually-correct theme on first paint (no flash)
- Manually viewing source: no `Hugo X.Y.Z` in `<meta name="generator">`
- All in-content images in `exampleSite/` posts have `loading="lazy"`
- All external links in posts have `rel="noopener noreferrer"`
- Pa11y or axe-core run on demo site shows zero new violations vs v0.1.0

## Risk Assessment

- **Focus ring on dark mode** — `var(--tsuki-accent)` must contrast against dark backgrounds. Verify with WCAG contrast checker; bump accent saturation if needed.
- **render-link hook breaking same-doc anchor links** — `strings.HasPrefix .Destination "http"` correctly excludes `#anchor` and relative links. Test on a TOC-heavy post.
- **Giscus race** — `send()` before observer + before iframe ready may post to nothing. Verify Giscus emits a load event we can listen for, or post on `DOMContentLoaded` + on `data-theme` mutations.
- **Categories M1 churn** — if "surface" is chosen, post-card.html and meta.html grow; verify CSS budget.

## Security Considerations

- N5 mitigates Hugo-version-CVE-fingerprinting.
- render-link's `safeURL` preserves XSS protection on destination.

## Next Steps

→ Phase 3 (parallel) — SEO baseline lands JSON-LD + OG + Twitter on top of the cleaned `head.html`.
→ Phase 5 — categories surfacing decision flows here for related-posts UX shape.
