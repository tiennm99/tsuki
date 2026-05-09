# tsuki v0.1.0 Production-Readiness Audit

Date: 2026-05-08
Scope: full theme — `layouts/`, `assets/`, `i18n/`, `data/`, `exampleSite/`, `hugo.yaml`, `theme.toml`, `package.json`, `.github/`, `docs/`
Branch: main @ d88f18d

---

## Overall Assessment

Solid v0.1.0. Code is small, idiomatic Hugo 0.146+ (`_partials`, `_markup`), minimal JS, sane CSS tokens. Asset pipeline (`Concat | minify | fingerprint` with SRI) is well-formed. Vietnamese-first claims mostly hold. A handful of bugs and ergonomic gaps exist; none are show-stoppers but several are user-visible regressions vs documented behavior.

**Top concerns**
- **Documentation drift**: docs claim `params.toc.minWordCount` and `params.toc.enable` gate TOC. Code hardcodes 400 and ignores `enable`.
- **`unsafe: true` Goldmark** is documented as required. With `markdownify` of `profile.bio`, raw HTML in `data/profile.yaml` executes unescaped.
- **Tag URLs hardcoded** to `/tags/...` — breaks if site renames the taxonomy.
- **Several i18n keys referenced but missing** from `vi.yml` (`comments`, `month`, `pageNotFound`, `backHome`, `next/prev page` referenced but only `prev`/`next` exist; the key is also referenced as `previousPage`/`nextPage` in `vi.yml`).
- **CSS budget** claim "≤ 4 KB gz" — concatenated source is 4296 B gzipped before minify, so post-minify will likely fit, but tight; needs CI assertion.

---

## Critical

### C1 — Theme TOC defaults config is dead code
**File:** `hugo.yaml:34-36`, `layouts/single.html:28`, `layouts/_partials/footer.html:19`, `docs/config.md:46-48`

Theme defaults `params.toc.enable: true` and `params.toc.minWordCount: 400`. Docs say the latter "gates render".
Code uses `(gt .WordCount 400) (ne .Params.toc false)` — literal 400, no read of `site.Params.toc.minWordCount`, and `enable` is not consulted at all.

**Impact:** Setting `params.toc.enable: false` site-wide does nothing. Setting `params.toc.minWordCount: 800` does nothing. Hugo's "no deep-merge" rule for theme nested config is unrelated — these are read in templates at runtime.

**Fix:**
```go-html-template
{{- $tocCfg := site.Params.toc | default dict -}}
{{- $tocEnabled := $tocCfg.enable | default true -}}
{{- $tocMin := $tocCfg.minWordCount | default 400 -}}
{{- if and $tocEnabled (gt .WordCount $tocMin) (ne .Params.toc false) }}
  {{ partial "toc.html" . }}
{{- end }}
```
Apply same change in `layouts/_partials/footer.html:19` for the JS gate.

---

### C2 — `unsafe: true` + `markdownify` of profile.bio = stored XSS surface
**File:** `layouts/_partials/home/hero.html:15`

```go-html-template
<div class="home-hero-bio">{{ . | markdownify }}</div>
```

With `markup.goldmark.renderer.unsafe: true` (required by README/docs), any HTML in `data/profile.yaml: bio` renders verbatim — including `<script>`. For a single-author personal theme this is "I'm hurting myself" territory, but tsuki ships as a theme others adopt. A user who copies a tagline with `<img src=x onerror=...>` from a Stack-themed site (where `markdownify` was sandboxed differently) gets a script execution.

**Impact:** If any consumer accepts profile data from a less-trusted source (CMS, multi-author, generated), this is stored XSS.

**Recommendations** (pick one):
- Document explicitly that `data/profile.yaml: bio` is trusted-author input, never user-submitted, and HTML executes.
- Or sanitize: render bio with `markdownify` then `safeHTML` only after passing through a strict policy — Hugo has no built-in HTML sanitizer, so the practical mitigation is tight docs.
- Or hard-strip with a regex pre-pass before `markdownify` (loses code blocks).

At minimum: add a line to `docs/data-schemas.md` next to `bio` warning that HTML is rendered.

---

### C3 — Hardcoded `/tags/...` URLs assume taxonomy name
**File:** `layouts/_partials/meta.html:16`, `layouts/single.html:21`

```go-html-template
<a href="{{ printf "/tags/%s/" (urlize $tag) | relURL }}">#{{ $tag }}</a>
```

Theme defaults declare `taxonomies: { category: categories, tag: tags }`. Hugo does not deep-merge from theme. If consumer omits or renames (e.g., `tag: tag`), this template emits broken `/tags/...` links pointing to 404s.

**Fix:** Use `Page.GetTerms` so URLs resolve through Hugo's taxonomy graph:
```go-html-template
{{- with .GetTerms "tags" }}
<span class="post-tags">
  {{- range $i, $term := . -}}
    {{- if $i }}, {{ end -}}
    <a href="{{ $term.RelPermalink }}">#{{ $term.LinkTitle }}</a>
  {{- end -}}
</span>
{{- end }}
```
This also handles vi-titled tags correctly.

---

## High

### H1 — Missing i18n keys referenced in templates
**Files:** `i18n/vi.yml`, multiple consumers

Referenced but absent from `vi.yml`:
| key | referenced in |
|---|---|
| `comments` | `_partials/comments.html:5` |
| `month` (with `Number` arg) | `_partials/archive-group.html:6` |
| `pageNotFound` | `404.html:5` |
| `backHome` | `404.html:6` |
| `featuredProjects` | `_partials/home/projects.html:4` |
| `viewAll` | `_partials/home/recent-posts.html:17` |
| `searchSuggestion` | `search/list.html:38` |
| `altSearch` | `search/list.html:37` |

All have `| default "..."` fallbacks so site builds. But CHANGELOG claims "all UI strings" in `i18n/vi.yml`.

**Fix:** add the 8 missing keys. For `month`, return a localized name from a numeric arg (`{{ .Number }}` → `Tháng 8`). Current call `{{ i18n "month" (dict "Number" .Key) }}` passes a string `.Key` (Hugo `GroupByDate "1"` returns "1".."12"), so the template just needs:
```yaml
- id: month
  translation: "Tháng {{ .Number }}"
```

Also: `vi.yml` defines `previousPage`/`nextPage` that no template uses (`pagination.html` uses `prev`/`next`). Either delete the unused keys or switch pagination to the more descriptive ones.

---

### H2 — `params.search.enable: false` only hides header button, route still builds
**Files:** `layouts/_partials/header.html:7`, `layouts/search/list.html` (no gate), `docs/customization.md:111`

`docs/customization.md` says `params.search.enable: false` "removes search button + /search/ route." The header gate exists (good); the route gate does not. `search/list.html` always renders if `content/search/_index.md` exists. CI also unconditionally runs `npx pagefind --site exampleSite/public`.

**Fix:** wrap `search/list.html` body in `{{- if site.Params.search.enable | default true -}}` and emit a `<p>{{ i18n "searchDisabled" }}</p>` fallback, or document that disabling `search.enable` only affects the header button and consumers should also remove `content/search/_index.md`.

---

### H3 — Concatenated CSS budget is on the edge
**Files:** `assets/css/*.css`

Raw concat → gzip = 4296 B (over the 4 KB claim). Post-`minify` will save ~10–15% and bring it under, but `ResourceMinifier` minify is not lossless to gzip ratios; result could be 3.5–3.9 KB gz. Without a CI assertion this can silently regress.

**Recommendation:** Add a CI step that fails if `du -b public/css/*.bundle.*.css | head -1 | awk '{...}' && gzip -c | wc -c` exceeds 4096:
```yaml
- name: CSS budget assertion
  run: |
    css=$(find exampleSite/public -name "tsuki.bundle.*.css" -print -quit)
    sz=$(gzip -9 -c "$css" | wc -c)
    echo "tsuki bundle gz: $sz B"
    test "$sz" -le 4200
```

---

### H4 — `head.html` Pagination linking is wrong on `home`
**File:** `layouts/_partials/head.html:55`

```go-html-template
{{- if or .IsHome (eq .Kind "section") (eq .Kind "taxonomy") (eq .Kind "term") }}
  {{- with .Paginator }} … {{- end }}
{{- end }}
```

`home.html` does not call `.Paginator` (and the home isn't paginated — it's a portfolio + recent post snippet). `.Paginator` on `home` returns implicit pagination for `site.RegularPages` and emits `rel=prev/next` links to non-existent `/page/2/` etc., causing 404s for crawlers and bad `<link rel="prev/next">` SEO.

**Fix:** drop `.IsHome` from the gate, or check `if gt .Paginator.TotalPages 1` (which covers all kinds correctly).

---

### H5 — Code-copy script attaches to all `<pre>` regardless of code presence
**File:** `assets/js/code-copy.js:5-6`

`for (const pre of document.querySelectorAll("pre"))`: matches every `<pre>` on the page including non-Hugo-highlight ones in render-hook output. The `if (!code) continue` guards a missing `<code>`, but a `<pre>` containing `<code>` rendered for non-code purposes (e.g., ASCII art) gets a "Sao chép" button. Minor but fixable.

Also: `navigator.clipboard` is unavailable on `http://` non-localhost. The theme falls back gracefully (`FAILED` text), but no explanation appears. Add `if (!navigator.clipboard) return;` before `pre.appendChild(btn)` so users on HTTP don't see broken-looking buttons.

---

### H6 — `comments.html` script tag uses `defer` semantics inconsistently
**File:** `layouts/_partials/comments.html:7-21`

The `<script>` is rendered inline in the `comments` section. With `async`, Giscus loads independently of the `<script>` element's DOM position, but Giscus expects the parent element to be in the DOM at parse time — placing the `<script>` *after* the `<div class="giscus">` is correct. However: the `data-strict="0"` etc. are emitted as quoted strings. Giscus accepts `0`/`1` as strings, so this works; but if a user types `strict: false` (yaml bool), Hugo emits `false`, which Giscus treats as truthy. Document the type expected.

Also missing: `referrerpolicy="no-referrer-when-downgrade"` and `loading="lazy"` is set via `data-loading` (correct), but the `<iframe>` Giscus injects gets sandboxed by Giscus itself, not by the theme. Acceptable.

---

### H7 — IntersectionObserver TOC: encoded headings can mismatch
**File:** `assets/js/toc-active.js:5`

```js
const id = decodeURIComponent(a.getAttribute("href").slice(1));
```
With `autoHeadingIDType: github-ascii`, IDs are pure ASCII so `decodeURIComponent` is a no-op. But heading IDs in Hugo's TOC are URL-encoded if non-ASCII — and `headings.querySelectorAll(...[id])` in the same script uses `h.id` (the raw DOM id, *not* URL-encoded). If a user disables `autoHeadingIDType: github-ascii` (config docs say it's "recommended", not required), the link `href="#%C3%A1"` decodes to `"á"` but `h.id === "á"` matches — *good*. So this code is correct under both modes. Keep the `decodeURIComponent` call. No fix needed; documenting reasoning here for posterity.

---

### H8 — `home/recent-posts.html` runs the same query twice
**File:** `layouts/_partials/home/recent-posts.html:2,15`

```go-html-template
{{- $posts := first $count (where (where site.RegularPages "Type" "post") "Draft" false) -}}
…
{{- if gt (len (where (where site.RegularPages "Type" "post") "Draft" false)) $count }}
```

Hugo evaluates `where` twice. Negligible build-time cost on small sites, but smelly. Bind once:
```go-html-template
{{- $all := where (where site.RegularPages "Type" "post") "Draft" false -}}
{{- $posts := first $count $all -}}
```
Also: `Draft` filtering is redundant because `--buildDrafts` is the master switch and `site.RegularPages` already excludes drafts in normal builds. Drop `"Draft" false` unless explicitly supporting `--buildDrafts` while still hiding drafts from home (uncommon).

---

## Medium

### M1 — Categories never surface to readers
**Files:** `layouts/_partials/meta.html`, `layouts/_partials/post-card.html`, `layouts/single.html`

Posts use `categories` in frontmatter. The theme lists `categories` taxonomy but the meta partial only shows `tags`. There is no per-post category badge, no category-list partial, no sidebar.

If categories are intentionally invisible (only for routing under `/categories/<slug>/`), document it. Otherwise add a small "📂 ghi-chu" pill alongside tags in `meta.html`.

---

### M2 — No `Lastmod` surfaced on the post page
**File:** `layouts/_partials/meta.html`, `layouts/single.html`

`head.html:36` emits `article:modified_time`, good. But the visible post body never shows "Cập nhật ngày X" even though `i18n/vi.yml` defines `updatedOn`. Either remove the unused key or add a `{{ with .Lastmod }}…{{ end }}` block in `meta.html`.

---

### M3 — No skip-link, focus rings, or `prefers-reduced-motion` on `transition`
**Files:** `assets/css/reset.css:35-42`, `layouts/baseof.html`

- No `<a class="skip-link" href="#main">` in `baseof.html`. Vi keyboard users (and screen-reader users) jump through full nav on every page.
- `.theme-toggle:focus-visible`, `.search-button:focus-visible`, `.site-nav a:focus-visible`, etc. lack explicit focus styles — they rely on UA defaults, which dark-mode often makes invisible (browser default is `outline: 1px solid -webkit-focus-ring-color` blue against `#14151a` is only marginal).
- `reset.css:35-42` covers reduced motion for `animation`/`transition`/`scroll-behavior` but `view-transitions.css` *also* handles it. The `!important` overrides win, so view-transitions get nuked too. That's likely the intent; document in CHANGELOG.

**Fix:** Add to `components.css` or `reset.css`:
```css
:focus-visible {
  outline: 2px solid var(--tsuki-accent);
  outline-offset: 2px;
}
```
And add in `baseof.html`:
```html
<a class="skip-link" href="#main">{{ i18n "skipToContent" | default "Đến nội dung chính" }}</a>
```
plus `id="main"` on `<main>`.

---

### M4 — `tsuki-vt-name` CSS variable references nothing that sets it
**File:** `assets/css/home.css:82`

```css
.project-card { view-transition-name: var(--tsuki-vt-name, none); }
```

The fallback `none` makes this a no-op. Nothing in templates sets `--tsuki-vt-name` per-card, so cards have *all* `view-transition-name: none`. Either:
- Set `--tsuki-vt-name: project-{{ printf "%d" $index }}` per card via inline `style=""` (hugo loop), enabling card-morph transitions across navigations.
- Or remove the dead declaration. Currently it advertises a feature that doesn't exist.

---

### M5 — Theme flash prevention script is non-blocking but works
**File:** `layouts/_partials/head.html:13-23`

The IIFE before `<body>` reads `localStorage` and sets `data-theme`. Good. Three subtle issues:
1. **Layout-shift risk**: if `localStorage` access throws (Safari ITP private mode), the catch is silent — root stays without `data-theme`, dark-mode kicks in via `prefers-color-scheme: dark` rule. Then `theme-toggle.js` (deferred module) reads stored=null and assumes match-media. Outcome: correct theme on first paint; toggle button starts in "match prefers" state. Verify this is intended.
2. The `<script>` is *inline* but the `<link rel="stylesheet">` for the bundled CSS is loaded after it. `<link rel="stylesheet">` blocks rendering, so the `data-theme="..."` attribute is set before the stylesheet evaluates. ✓ no FOUC for the toggle.
3. Storage key `tsuki-theme` is shared across sites mounting the theme on the same origin. For a single-domain blog this is fine. Consider scoping (low priority).

---

### M6 — Pagefind CSS loaded outside the bundle defeats SRI on that asset
**File:** `layouts/search/list.html:4`

```html
<link rel="stylesheet" href="{{ "/pagefind/pagefind-ui.css" | relURL }}">
```

No `integrity=`. Pagefind ships its own CSS; not part of the asset pipeline. Fine — but document that Pagefind UI CSS is third-party and not budget-counted. Consider Subresource Integrity once Pagefind starts shipping a stable hash (currently they don't).

---

### M7 — `home.html` calls partials unconditionally; partials guard themselves
**File:** `layouts/home.html:4-6`

`home/projects.html` does `{{- with site.Data.projects.featured -}}` — if no `data/projects.yaml`, the section silently vanishes. Same for `hero.html`. Acceptable. Document that an empty `data/profile.yaml` and `data/projects.yaml` is valid and produces a near-empty homepage.

Edge case: `data/projects.yaml` exists but has no `featured` key → `with` is falsy → empty grid. Good.
Edge case: `featured: []` → `with []` is falsy → no `<h2>` heading orphan. Good.

---

### M8 — `range .Pages.ByTitle` in taxonomy.html ignores Title casing for vi
**File:** `layouts/_default/taxonomy.html:10`

`ByTitle` sorts ASCII-first; "Áo" comes after "Zip" in default Go locale. For a vi-first theme, sort by `.Title` with a normalized key. Hugo doesn't expose locale-aware sort directly — workaround:
```go-html-template
{{- range .Pages.ByParam "title" }}…
```
or manually `urlize` to a normalized key. Lowest priority, but Vi authors will notice "Á-bài" sorted weirdly.

---

### M9 — `archive-group.html` `GroupByDate "1"` is month number; date "02/01" is day/month
**File:** `layouts/_partials/archive-group.html:4,10`

`GroupByDate "1"` → numeric month ("1".."12"). The post date `02/01` (DD/MM) correctly emits Vietnamese order. But **rounded to "08"** (zero-pad) when rendered as `{{ .Date.Format "02/01" }}` (Go time.Format). Verify intent: dates show DD/MM, archive month heading is `Tháng 1`..`Tháng 12`. If a Vi reader expects `Tháng 01`, the i18n month string handles it. ✓

---

## Low

### L1 — `theme.toml: original.author = ""` clutters Hugo theme directory listing
**File:** `theme.toml:15-18`

If tsuki isn't a fork, drop the `[original]` block. Hugo's themes registry treats empty `original.author` as malformed.

---

### L2 — `archetypes/default.md` doesn't include `description`
**File:** `archetypes/default.md`

`description` is referenced in `head.html` for OG meta. Adding it to the archetype reduces "missing description" surprises:
```md
---
title: "{{ replace .Name "-" " " | title }}"
date: {{ .Date }}
draft: true
description: ""
tags: []
categories: []
---
```

### L3 — `post-card.html`: `.Summary | plainify | truncate 180` — order matters
**File:** `layouts/_partials/post-card.html:11-13`

`plainify` then `truncate` is correct but truncation can land mid-Vietnamese diacritic if the byte cursor splits a multi-byte rune. Hugo's `truncate` is rune-safe (Go strings), so no corruption. Just confirming.

### L4 — `i18n/vi.yml` mixes shapes
**File:** `i18n/vi.yml`

`readingTime` uses Go-template `{{ .Count }}` interpolation. Other strings are plain. Hugo i18n uses go-i18n v1 syntax — both forms valid, but inconsistent. Consider unifying to plural-aware:
```yaml
- id: readingTime
  one: "1 phút đọc"
  other: "{{ .Count }} phút đọc"
```
Vietnamese has no grammatical plural so cosmetic only.

### L5 — `comments.html` Giscus theme attribute uses `data-theme="preferred_color_scheme"` default
**File:** `layouts/_partials/comments.html:17`

Combined with `giscus-theme.js` which posts `setConfig: { theme: "light"|"dark" }`, the iframe's initial render uses `preferred_color_scheme`, then the script overrides on `data-theme` mutation. There's a flash on first paint where Giscus renders its default theme, then toggles. Lowest-priority cosmetic.

**Fix:** initial-call `send()` once on page load so Giscus opens already-themed:
```js
send();
new MutationObserver(send).observe(...);
```
Currently the Observer only fires on mutation, never on initial state.

### L6 — `code-copy.js` button label hardcoded vi strings
**File:** `assets/js/code-copy.js:1-3`

`COPY = "Sao chép"`, etc. Should match `i18n/vi.yml` for future en support. Inject from data attribute set by template:
```html
<pre data-copy-label="{{ i18n "copy" }}" data-copied-label="{{ i18n "copied" }}">
```
Or accept this is vi-first and don't surface the strings to i18n.

### L7 — `code-copy.js`: tabindex/keyboard for the button
**File:** `assets/js/code-copy.js`

Button has no `tabindex` attribute (defaults to `0` for `<button>`, ✓), but no `aria-live` region for the "Đã chép" feedback. SR users won't hear confirmation. Add `aria-live="polite"` to the button or to a sibling span.

### L8 — `images/screenshot.png` and `images/tn.png` not referenced anywhere
**File:** `images/*.png`

Hugo themes registry expects `images/screenshot.png` (1500×1000) and `images/tn.png` (900×600). Verify dims match. Most recent commit message says they were added; confirm in registry standards (`https://themes.gohugo.io/`).

### L9 — `package.json` `private: true` blocks `npm publish` but pagefind is a dev dep that ought to be `dependencies` (or `peerDependencies`?) for Hugo Module consumers
**File:** `package.json`

If a user adopts tsuki as a Hugo Module, they don't get Pagefind from the theme's `package.json` — Hugo Modules don't run npm. Document: "Pagefind is built in CI; consumer sites need their own `npm install pagefind` or just `npx pagefind` step." Currently undocumented.

---

## Nice-to-have

### N1 — Add a `_markup/render-link.html` for safer external links
Auto-detect external URLs and add `rel="noopener noreferrer" target="_blank"` (or ditto without `_blank` — UX preference).

### N2 — Add `_markup/render-image.html` to enforce `loading="lazy" decoding="async"`
All in-content images currently rely on goldmark default (no lazy attrs).

### N3 — `Hugo Module` mounts not declared in `theme.toml`
For Hugo Module consumers, declare `[module]` mounts in `hugo.yaml`-or-`config.yaml` so themes mount cleanly:
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
Without it, default mounts work but hand-overrides break (rare).

### N4 — RSS limit on home pagination: site builds `<link rel="prev">` from `.Paginator` even if homepage isn't a paginated kind. Already covered in H4.

### N5 — Privacy: meta `generator` exposes Hugo version
**File:** `layouts/_partials/head.html:7`

`<meta name="generator" content="Hugo {{ hugo.Version }} + tsuki">` lets attackers know Hugo version → CVE matching. Drop `hugo.Version` and emit just `tsuki @ v0.1.0`, or skip the meta entirely. Defense in depth.

### N6 — `view-transitions.css` doesn't fall back gracefully when CSS chain breaks
The `@view-transition` rule is unsupported in Firefox/Safari ≤17. Browsers ignore it (good). The `@keyframes tsuki-fade-out/in` are emitted regardless and only used by view-transition pseudo-elements, so dead bytes in unsupporting browsers. Trade-off: 50 B for forward-compat.

### N7 — Self-host woff2 fonts deferred — no `font-display: swap` set on the system fallback chain
Adding `font-display: swap` is irrelevant when no `@font-face` is declared — but document this in `customization.md` so first-time self-hosters know.

---

## Edge Cases / Verification Notes

- **Empty `data/profile.yaml`**: `home/hero.html` `with $profile` skips the whole hero. Site title shows in header instead. ✓
- **Missing thumbnails**: `home/projects.html` `with $project.image` skips the image div. ✓
- **Posts without word counts** (e.g., front-matter-only): `gt .WordCount 400` is `false`, TOC suppressed, `meta.html` shows `0 phút` if `gt .ReadingTime 0` guard somehow fails — the guard is `gt 0`, so `0 → false → no render`. ✓
- **Browser without View Transitions**: `@view-transition` rule ignored; no fallback animation, just instant nav. ✓ matches docs.
- **Browser without `:has()`**: codebase doesn't use `:has()` anywhere I could find. Search confirms zero hits. README mentions `:has()` as progressive enhancement — code doesn't actually use it. Either add a usage or drop the claim.
- **Browser without IntersectionObserver**: `toc-active.js` will throw `ReferenceError` on `new IntersectionObserver(...)`. Old browsers (IE11, pre-Chrome 51) error out. Modern evergreen support is universal. Theme.toml says "Modern evergreen browsers" — acceptable.
- **No JS at all**: theme toggle button `hidden` attribute remains (button never reveals). ✓ progressive enhancement. Code-copy disabled. ✓ TOC active highlighting disabled but TOC still renders. ✓ Search disabled with `<noscript>` fallback. ✓

---

## Documentation vs Code Match

| Doc claim | Code behavior | Match |
|---|---|---|
| `params.toc.minWordCount` gates render | hardcoded 400 | ✗ (C1) |
| `params.toc.enable` site-wide kill-switch | not consulted | ✗ (C1) |
| "all UI strings in `i18n/vi.yml`" | 8 keys missing | ✗ (H1) |
| `params.search.enable: false` removes route | only header button hidden | ✗ (H2) |
| "CSS bundle ≤ 4 KB gz, JS ≤ 1 KB gz" | pre-minify gz: 4296 B / 660 B; post-minify likely under | ⚠ (H3) |
| `:has()` progressive enhancement | not used in CSS | ⚠ (no harm but misleading) |
| OG image fallback to `profile.avatar` | `head.html:3` → ✓ | ✓ |
| `data-pagefind-body` on post content | `single.html:13` → ✓ | ✓ |
| Theme flash prevention | inline IIFE before stylesheet → ✓ | ✓ |
| ASCII heading IDs via `autoHeadingIDType: github-ascii` | configured | ✓ |
| `permalinks: post: /:year/:month/:day/:contentbasename/` | configured + matches content paths | ✓ |
| Both submodule and Hugo Module flow | submodule ✓; Module flow undocumented mounts | ⚠ (N3) |

---

## Positive Observations

- Excellent restraint on JS surface area — 4 modules, total ~1 KB gz, each module a single responsibility.
- Asset pipeline `Concat | minify | fingerprint` with SRI integrity attribute on `<link>` and `<script>`: best practice.
- Inline theme-flash-prevention script kept tight (no markdownify, no template variables that could break SRI on the bundle).
- Body-class block via `{{ define "body_class" }}` is clean composition; lets per-page CSS hooks like `body.post .toc { … }` work without JS.
- `aria-current="page"` on nav, `aria-current="true"` on active TOC link: correct.
- `<noscript>` fallback on the search page.
- Render-heading hook is minimal and accessible (anchor has `aria-label`).
- Content-Security-Policy compatible (no inline `style=""`, only one inline `<script>` with constant content the CSP can hash).
- `.gitignore` covers Pagefind generated content + `node_modules`. Good.
- Dependabot config is sensible.
- View-transition `prefers-reduced-motion` honored at the *animation* level, not blanket-disabled.

---

## Recommended Actions (priority order)

1. **C1** — Fix TOC gating to honor `site.Params.toc.{enable,minWordCount}`. Short PR, high doc/behavior gap.
2. **H1** — Add 8 missing i18n keys.
3. **C3** — Switch tag URLs to `Page.GetTerms`.
4. **H2** — Gate `search/list.html` body on `params.search.enable` or update docs.
5. **H4** — Drop `.IsHome` from pagination link emission in `head.html`.
6. **C2** — Document HTML execution in `profile.bio` markdown.
7. **M3** — Add `:focus-visible { outline … }` and skip-link.
8. **M1/M2** — Decide on category surfacing and `Lastmod` display; remove unused i18n keys.
9. **H3** — Add CSS budget assertion to CI.
10. **L5** — `giscus-theme.js`: call `send()` once on load.

Lower-priority items (N1–N7, L1–L9, M4–M9) batch as polish before v0.2.

---

## Unresolved Questions

1. Is the `unsafe: true` Goldmark requirement specifically for embedded HTML in posts (e.g., `<details>`, custom div for callouts), or just for footnote rendering? If the former, document examples; if the latter, switching to `unsafe: false` removes both the XSS surface (C2) and the documentation burden.
2. Should `params.toc.enable: false` also strip the bundled TOC CSS? Current pipeline always concats `toc.css` (~1.5 KB raw, ~600 B gz). For sites that disable TOC, this is dead bytes. Option: split TOC into separate bundle, conditionally loaded.
3. Is the homepage intended to ever paginate (more recent posts beyond `recentPostsCount`)? If no, H4's fix is to drop the `.IsHome` branch entirely. If yes, the home `home.html` template must call `.Paginator.Pages` somewhere.
4. Are categories deliberately invisible to readers (M1)? If yes, drop the `categories` taxonomy from theme defaults and add a CHANGELOG note.
5. Hugo theme registry submission planned? `theme.toml` has empty `[original]` block (L1) and `screenshot.png`/`tn.png` need verification against registry size requirements.
6. What's the expected `--baseURL` story for sites that don't deploy under `/tsuki/` (i.e., root deploys)? `relURL` handles it; verify with a test deploy at root.
7. Is Vietnamese the only locale planned, or is `i18n/en.yml` intended (currently only `vi.yml`)? Half the i18n keys have English `default` fallbacks suggesting eventual en.yml.

---

**Status:** DONE
**Summary:** Reviewed full v0.1.0 surface. 3 critical (TOC config dead, XSS-via-bio docs, hardcoded /tags URL), 8 high, 9 medium, 9 low, 7 nice-to-have. Code is clean and idiomatic; main gaps are doc/code drift and a few accessibility polish items.
**Concerns:** None blocking. Recommend fixing C1, H1, H2, H4, and adding skip-link before promoting v0.1.0 widely. Items C2, M1, M2 deserve a maintainer decision (security policy + UX intent) before code change.
