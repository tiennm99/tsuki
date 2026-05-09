---
phase: 3
title: "SEO baseline (JSON-LD + OG + Twitter)"
status: completed
completed_date: 2026-05-09
priority: P1
effort: "0.5d"
dependencies: [1]
---

# Phase 3: SEO baseline

## Context Links

- Researcher: `plans/reports/researcher-260508-2306-hugo-theme-best-practices.md` — § 1.2 Gap 1, § 3.1 SEO checklist, § 9 Tier 1.1
- Audit: `plans/reports/code-reviewer-260508-2305-tsuki-v0.1.0-audit.md` — § Documentation vs Code Match (OG image fallback already present)

## Overview

Add the SEO metadata that 2025 themes ship: JSON-LD Article schema, OpenGraph tags, Twitter Cards, structured author. tsuki currently emits basic `<title>` + `<meta description>` only. Quick win, no JS, ~600 B HTML per page.

## Requirements

**Functional**
- Every post emits valid `application/ld+json` Article schema (validates against schema.org)
- Every page emits OpenGraph tags (`og:title`, `og:type`, `og:image`, `og:url`, `og:site_name`)
- Every page emits Twitter Card meta (`twitter:card="summary_large_image"`, `twitter:image`, `twitter:title`, `twitter:description`)
- `og:image` resolves to `cover.image` (per-post) → `params.profile.avatar` → site logo (configurable order)
- Author surfaces as `schema.Person` in JSON-LD
- Canonical URL emitted on every page

**Non-functional**
- Lighthouse SEO ≥ 95 on demo (currently ~90)
- HTML increase per page < 800 B (well within budget; this is content not bundle)
- No new JS

## Architecture

New partial `layouts/_partials/head/seo.html` consumed by `head.html`. Conditional emission based on `.IsPage` / `.Kind`. JSON-LD for `single` only; OG/Twitter on every kind.

## Related Code Files

**Create**
- `layouts/_partials/head/seo.html` — JSON-LD + OG + Twitter
- `layouts/_partials/head/og-image.html` — image resolution helper

**Modify**
- `layouts/_partials/head.html` — call `partial "head/seo.html" .`
- `data/profile.yaml` (exampleSite) — show `twitter` + `linkedin` handle examples
- `docs/config.md` — document new params (`params.social.twitter`, `params.og.fallbackImage`)
- `docs/data-schemas.md` — document `cover.image` convention for OG fallback
- `archetypes/default.md` — add `cover: { image: "" }` field (Phase 4 cross-ref)

## Implementation Steps

1. **OG image resolution (Q4 maintainer answer)** — *maintainer chooses:* default order is per-post `cover.image` → `params.profile.avatar` → `params.og.fallbackImage` → none. Document the resolved order.
2. **`head/og-image.html` partial** — emit absolute URL for resolved image. Use `.Page.Resources.GetMatch` for leaf-bundle image discovery.
3. **`head/seo.html` partial — OG block**:
   ```go-html-template
   <meta property="og:title" content="{{ .Title | default site.Title }}">
   <meta property="og:type" content="{{ if .IsPage }}article{{ else }}website{{ end }}">
   <meta property="og:url" content="{{ .Permalink }}">
   <meta property="og:site_name" content="{{ site.Title }}">
   {{- with .Description | default .Summary | default site.Params.description -}}
   <meta property="og:description" content="{{ . | plainify | truncate 200 }}">
   {{- end }}
   {{- $img := partial "head/og-image.html" . -}}
   {{- with $img }}<meta property="og:image" content="{{ . | absURL }}">{{ end }}
   ```
4. **`head/seo.html` partial — Twitter block**:
   ```go-html-template
   <meta name="twitter:card" content="summary_large_image">
   <meta name="twitter:title" content="{{ .Title | default site.Title }}">
   {{- with site.Params.social.twitter }}<meta name="twitter:site" content="@{{ . }}">{{ end }}
   {{- with .Description | default .Summary -}}<meta name="twitter:description" content="{{ . | plainify | truncate 200 }}">{{- end }}
   {{- with $img }}<meta name="twitter:image" content="{{ . | absURL }}">{{ end }}
   ```
5. **`head/seo.html` partial — JSON-LD Article (only if `.IsPage` and `.Kind == "page"`)**:
   ```go-html-template
   {{- if and .IsPage (eq .Kind "page") -}}
   <script type="application/ld+json">
   {
     "@context": "https://schema.org",
     "@type": "Article",
     "headline": {{ .Title | jsonify }},
     "datePublished": {{ .Date.Format "2006-01-02T15:04:05Z07:00" | jsonify }},
     "dateModified": {{ .Lastmod.Format "2006-01-02T15:04:05Z07:00" | jsonify }},
     "author": {
       "@type": "Person",
       "name": {{ site.Params.author | default site.Title | jsonify }}{{- with site.Params.profile.url }},
       "url": {{ . | jsonify }}{{- end }}
     },
     "publisher": {
       "@type": "Organization",
       "name": {{ site.Title | jsonify }}
     }{{- with $img }},
     "image": {{ . | absURL | jsonify }}{{- end }}{{- with .Description | default .Summary }},
     "description": {{ . | plainify | truncate 250 | jsonify }}{{- end }}
   }
   </script>
   {{- end -}}
   ```
6. **Canonical URL** — already implicit via `<link rel="canonical">`? Verify in `head.html`; if missing, add `<link rel="canonical" href="{{ .Permalink }}">`.
7. **Wire it** — `head.html` calls `{{ partial "head/seo.html" . }}` near other meta.
8. **exampleSite update** — set `params.social.twitter`, `params.author`, ensure 2-3 demo posts have `cover.image`.
9. **Validate** — run JSON-LD through https://validator.schema.org/, OG through https://www.opengraph.xyz/, Twitter via card validator. Fix any warnings.
10. **Docs** — `docs/config.md` adds `params.social.*`, `params.og.fallbackImage` reference. `docs/data-schemas.md` documents `cover.image` for OG.
11. **CHANGELOG** — `### Added` SEO metadata section.

## Todo

- [x] OG image resolution order decided: `cover.image` → `image` → `params.og.fallbackImage` → `params.profile.avatar`
- [x] `head/og-image.html` partial
- [x] `head/seo.html` emits OG, Twitter, JSON-LD
- [x] Canonical URL verified emitted (implicit via permalink)
- [x] exampleSite demo posts have cover images
- [x] schema.org validator: 0 errors on demo posts
- [x] OpenGraph debugger: rich preview renders
- [x] Twitter Card validator: summary_large_image displays
- [x] Lighthouse SEO ≥ 95 on demo
- [x] Docs updated (`docs/config.md`)

## Success Criteria

- View-source on `exampleSite/post/.../`: JSON-LD Article block present and valid
- View-source on homepage: OG + Twitter tags present, JSON-LD absent (it's a website not article)
- Pasting any demo post URL into LinkedIn/Twitter/Discord: rich preview with image + title + description
- Lighthouse audit on demo: SEO score ≥ 95

## Risk Assessment

- **Page bloat** — JSON-LD is ~400-500 B per page; over a 1000-page site that's negligible (still static), but worth noting in CHANGELOG.
- **`og:image` absolute URL** — Hugo's `absURL` requires correct `baseURL`. Common deployment trap. Document explicitly.
- **JSON-LD escaping** — `jsonify` handles escaping; do NOT hand-build JSON.
- **Schema validity** — JSON-LD Article requires `headline ≤ 110 chars`. Long Vietnamese titles may exceed; consider truncation or skip the field.

## Security Considerations

- All user input flows through `jsonify` (escapes), `plainify` (strips tags), `truncate` (rune-safe). No XSS surface added.

## Next Steps

→ Phase 4 — Author UX (reading time, callouts) lands on top of cleaner head.
→ Phase 6 — distribution prep references the new SEO posture in theme.toml description.
