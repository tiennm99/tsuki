---
phase: 4
title: "Author UX (reading time, callouts, archetype)"
status: completed
completed_date: 2026-05-09
priority: P2
effort: "0.5d"
dependencies: [1]
---

# Phase 4: Author UX

## Context Links

- Researcher: `plans/reports/researcher-260508-2306-hugo-theme-best-practices.md` — § 1.2 Gap 2, Gap 4; § 2.1 Blockquote Render Hook; § 9 Tier 1.2, 1.3; § 4.2 archetype
- Audit: `plans/reports/code-reviewer-260508-2305-tsuki-v0.1.0-audit.md` — L2 archetype description

## Overview

Three quick wins for authors: reading time + word count byline (Hugo provides out-of-box; just template + i18n), native Markdown callouts via blockquote render hook (`> [!note]`, `> [!warning]`, `> [!caution]` per Hugo 0.150+), and a richer archetype.

## Requirements

**Functional**
- Post pages show "X phút đọc" reading time and optional word count
- `> [!note]`, `> [!warning]`, `> [!caution]`, `> [!tip]`, `> [!important]` render as styled callouts
- Plain `>` blockquotes render unchanged
- Archetype includes `description`, `tags`, `categories`, `cover.image` placeholder

**Non-functional**
- Reading time uses `i18n` so en-translation is trivial
- Callouts add ≤ 400 B gz CSS
- No JS

## Architecture

Reading time = template tweak in `meta.html`. Callouts = single render hook `_markup/render-blockquote.html` matching Hugo 0.150+ alert-syntax convention. CSS for callout styles slots into `components.css` (or a new `callouts.css` if budget tight). Archetype is a single file.

## Related Code Files

**Create**
- `layouts/_markup/render-blockquote.html`
- `assets/css/callouts.css` (optional; could live in `components.css`)

**Modify**
- `layouts/_partials/meta.html` — add reading time + word count
- `i18n/vi.yml` — add `wordCount`, ensure `readingTime` plural-aware (L4)
- `archetypes/default.md` — add `description: ""`, `cover: { image: "" }`
- `assets/css/components.css` (or new `callouts.css`) — callout styles
- `assets/css/tokens.css` — add `--tsuki-callout-{note,warning,caution,tip,important}` color tokens
- `layouts/baseof.html` or asset pipeline — include `callouts.css` in concat list
- `docs/customization.md` — document callout syntax for content authors

## Implementation Steps

1. **Reading time byline** — in `meta.html`, after date:
   ```go-html-template
   {{- if gt .ReadingTime 0 -}}
   <span class="post-meta-reading">{{ i18n "readingTime" (dict "Count" .ReadingTime) }}</span>
   {{- end -}}
   {{- with site.Params.showWordCount }}{{ if . }}
   <span class="post-meta-words">{{ i18n "wordCount" (dict "Count" $.WordCount) }}</span>
   {{ end }}{{- end }}
   ```
2. **i18n keys** — convert `readingTime` to plural-aware form (vi has no plurals but go-i18n shape is consistent for future en):
   ```yaml
   - id: readingTime
     translation: "{{ .Count }} phút đọc"
   - id: wordCount
     translation: "{{ .Count }} từ"
   ```
3. **Blockquote render hook** — create `_markup/render-blockquote.html` matching Hugo's documented alert pattern:
   ```go-html-template
   {{- $type := .AttributeOrDefault "alertType" "" -}}
   {{- if $type -}}
     <blockquote class="callout callout-{{ $type | lower }}">
       <p class="callout-title">
         {{ partial "icon.html" $type }}
         {{ i18n (printf "callout%s" ($type | title)) | default ($type | title) }}
       </p>
       {{ .Text }}
     </blockquote>
   {{- else -}}
     <blockquote{{ with .Attributes }}{{ range $k, $v := . }}{{ if ne $k "alertType" }} {{ $k }}="{{ $v }}"{{ end }}{{ end }}{{ end }}>
       {{ .Text }}
     </blockquote>
   {{- end -}}
   ```
   *Verify Hugo 0.146 supports `.AttributeOrDefault` on blockquote render hooks; if not, require Hugo 0.150+ (bump `min_version` in `theme.toml`).*
4. **Callout CSS** — minimal: bordered box, accent stripe, title color via custom property. ≈ 350 B gz.
   ```css
   .callout { border-left: 3px solid var(--tsuki-callout); padding: .75rem 1rem; margin: 1rem 0; background: var(--tsuki-callout-bg); border-radius: .25rem; }
   .callout-title { font-weight: 600; margin: 0 0 .5rem; display: flex; gap: .375rem; }
   .callout-note { --tsuki-callout: #2563eb; --tsuki-callout-bg: #2563eb12; }
   .callout-warning { --tsuki-callout: #d97706; --tsuki-callout-bg: #d9770612; }
   .callout-caution { --tsuki-callout: #dc2626; --tsuki-callout-bg: #dc262612; }
   .callout-tip { --tsuki-callout: #16a34a; --tsuki-callout-bg: #16a34a12; }
   .callout-important { --tsuki-callout: #7c3aed; --tsuki-callout-bg: #7c3aed12; }
   ```
5. **i18n callout titles** — `vi.yml`:
   ```yaml
   - id: calloutNote
     translation: "Ghi chú"
   - id: calloutWarning
     translation: "Cảnh báo"
   - id: calloutCaution
     translation: "Thận trọng"
   - id: calloutTip
     translation: "Mẹo"
   - id: calloutImportant
     translation: "Quan trọng"
   ```
6. **Archetype** — `archetypes/default.md`:
   ```md
   ---
   title: "{{ replace .Name "-" " " | title }}"
   date: {{ .Date }}
   draft: true
   description: ""
   tags: []
   categories: []
   cover:
     image: ""
   ---
   ```
7. **exampleSite demo** — add a post showcasing all 5 callout types so users can copy-paste.
8. **Docs** — `docs/customization.md` adds a "Callouts" section with the `> [!note]` syntax.
9. **Bundle size check** — gzip CSS bundle. Should land around ~4.0-4.1 KB; acceptable. If over 4200 B, split callouts into a separate optional bundle loaded only when `> [!...]` is used (Hugo doesn't expose this gate cheaply; usually accept the 200 B).
10. **CHANGELOG** — `### Added` reading time, native callouts.

## Todo

- [x] Reading time + word count byline emitted
- [x] `readingTime`, `wordCount` i18n keys plural-aware
- [x] `_markup/render-blockquote.html` created
- [x] Hugo version compatibility verified: `min_version: 0.146.0`
- [x] Callout CSS added (5 types) in `assets/css/callouts.css`
- [x] Callout title i18n keys (5) in `i18n/vi.yml`
- [x] Archetype expanded with `description`, `cover.image`
- [x] Demo post with all 5 callouts in exampleSite
- [x] CSS bundle ≤ 4200 B gz
- [x] `docs/customization.md` callout section documented

## Success Criteria

- A post in exampleSite with `> [!note]` content renders as a styled note callout, not a plain blockquote
- Reading time displays on every post with content
- `hugo new post/foo.md` produces an archetype with all expected frontmatter fields
- Callout demo post renders correctly in light + dark modes with sufficient contrast

## Risk Assessment

- **Hugo version compat** — blockquote render hook with `alertType` attribute requires Hugo 0.140+. Audit confirms `min_version: 0.146.0` already, ✓.
- **CSS budget cliff** — ~400 B addition. May force splitting `callouts.css` out or removing dead bytes elsewhere. Run gzip test after merge.
- **Reading time accuracy** — Hugo uses 213 wpm by default; configurable via `wordsPerMinute` in `hugo.yaml`. Document in `docs/config.md` if Vietnamese reading speed differs (research suggests vi readers ~250 wpm).
- **Callout colors in dark mode** — colors above are picked for light mode; verify contrast in dark mode and add `[data-theme="dark"] .callout-{type} { … }` overrides if needed.

## Security Considerations

- Render hooks emit user content via `.Text` which Hugo treats as already-parsed safe HTML. Goldmark parses callout body the same as any blockquote — no new XSS surface.

## Next Steps

→ Phase 5 — related posts (the reading-time byline groundwork helps related-post cards display consistently).
