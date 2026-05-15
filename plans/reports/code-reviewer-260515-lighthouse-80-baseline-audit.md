# Lighthouse ≥80 baseline audit — tsuki v0.2.1

Scope: full theme at `main` (`d30f50f`). Read: README, CHANGELOG (Unreleased + v0.2.1 + v0.2.0), `layouts/baseof.html`, `layouts/_partials/{head,head/seo,footer,header,nav,meta,post-card,comments,toc,toc-enabled,search-button,related-posts}.html`, `layouts/_partials/home/{hero,projects,recent-posts}.html`, all `layouts/_markup/render-*.html`, `layouts/{single,home,list,404}.html`, `layouts/{search,post,archives,taxonomy,_default}/*.html`, all `assets/css/*.css`, all `assets/js/*.js`, `hugo.yaml`, `exampleSite/hugo.yaml`, `i18n/vi.yml`, `scripts/smoke-tests.sh`, prior audits (v0.2.0-post / v0.2.1-patch). Cross-checked against built `exampleSite/public/{index,2026/01/10/.../index,search/index}.html`, `sitemap.xml`, bundle sizes.

## TL;DR

Projected Lighthouse scores on a real production GitHub Pages deploy (`exampleSite`), median of 3 mobile runs, *no measurement performed* — static-inspection estimate:

- **Performance:** 92–98/100. Comfortable ≥80. Tiny bundles (3.96 KB gz CSS, 1.04 KB gz JS), minify on, hashed assets. LCP risk only on posts with a `cover.image` (no preload, no `fetchpriority`), but exampleSite has none so it lands in the high 90s.
- **Accessibility:** 88–93/100. Likely ≥80 but **not the ≥95 ceiling Phase 4 targets**. Three known deductions: theme-toggle button missing `aria-pressed` on initial SSR (only set in JS), small tap targets (`2rem` × `2rem` = 32px for toggle/search button is fine but pagination arrows + footer text links are <24×24 on mobile), and one `aria-label` localized to vi only (`Liên kết đến phần này` in render-heading regardless of site language).
- **Best Practices:** 95–100/100. Safe ≥80. SRI on bundles, `noopener noreferrer`, no mixed content, no deprecated APIs, console clean. Single risk: `unsafe: true` Goldmark is the consumer's problem, not Lighthouse's.
- **SEO:** 95–100/100. Safe ≥80. Sitemap, canonical, OG/Twitter, JSON-LD, viewport, lang, description all present. Only deductions are robots.txt being absent from `static/` (Hugo emits one only if configured) and `hreflang` not being emitted (theme is monolingual — but README/features list says "i18n").

**Confidence:** medium-high on Performance/Best Practices/SEO; medium on Accessibility (tap-size is the one place static inspection meaningfully misses what Lighthouse measures).

**Verdict: all four categories pass ≥80 on the demo today.** This audit identifies what would *block* the score in real-consumer configurations (cover images, English sites, dense menus) and what would push Accessibility past 95 to meet the Phase 4 success criterion.

---

## P0 — blocks ≥80 in some category

### P0-1 — Cover-image LCP unmeasured; no preload / no `fetchpriority` / no `sizes`
**Where:** `layouts/_partials/head/seo.html:10-15` (cover resolution), `layouts/single.html:4-15` (post body — no cover rendered at all), `layouts/_markup/render-image.html:1-5` (content images only)
**Why it costs points:** A `cover.image` is only used for OG/Twitter cards. It is never rendered into the page DOM as a hero. The CHANGELOG (v0.2.0) advertises `cover.image` as "the preferred OG/Twitter cover key" — fine for SEO, but a typical Hugo theme renders the cover as an LCP element. The instant a consumer adds a cover image and writes their own hero partial (or expects the theme to render it), they will paint a large image with `loading="lazy"` (per render-image.html), no preload, no `fetchpriority="high"`, no `width`/`height`. That fails LCP and CLS simultaneously and can knock Performance below 80 on slow 4G.
**Why this is P0 vs P1:** Right now exampleSite has no cover images so the demo Lighthouse number is clean — but the theme advertises a feature whose default rendering would tank the score. Consumer-facing footgun.
**Fix sketch (no build step):**
1. Render a hero cover in `single.html` (`{{ with .Params.cover.image }}<img ...>{{ end }}`) using Hugo `images.Resize` for `width`/`height`/`srcset`/`sizes`.
2. In `head.html`, when `.Params.cover.image` resolves to a local resource, emit `<link rel="preload" as="image" href="{{ . }}" fetchpriority="high">`.
3. First in-content cover gets `loading="eager" fetchpriority="high" decoding="async"`; rest stay `lazy`.
4. Document the per-post `cover.image` → above-fold rendering path in `docs/data-schemas.md`.
**Alternative (KISS):** ship a documented "to render cover, override `single.html`" note + a working snippet in `docs/customization.md`. Phase 5 of v0.3.0 doesn't cover this; Phase 3 (author UX) is the right place.

### P0-2 — Pagefind UI CSS is render-blocking on `/search/`
**Where:** `layouts/search/list.html:5` (`<link rel="stylesheet" href="{{ "/pagefind/pagefind-ui.css" | relURL }}">` in `head_extra`)
**Confirmed in built output:** `exampleSite/public/search/index.html` emits `<link rel=stylesheet href=/pagefind/pagefind-ui.css>` with no `media`/`onload` swap. This file is 3rd-party CSS, not part of the 3.96 KB gz bundle, and not preloaded.
**Why it costs points:** Pagefind UI CSS is ~3–4 KB gz on its own; on a cold visit it adds one render-blocking request after the theme bundle. Combined with the JS module that constructs the search UI (`scripts` block — loads `pagefind/pagefind-ui.js`), `/search/` is the single worst-LCP page on the site. Already flagged in P2-4 of the prior audit but not in v0.3.0 plan as a P0.
**Fix sketch:**
```html
<link rel="preload" as="style" href="{{ "/pagefind/pagefind-ui.css" | relURL }}" onload="this.rel='stylesheet'">
<noscript><link rel="stylesheet" href="{{ "/pagefind/pagefind-ui.css" | relURL }}"></noscript>
```
Cheaper alt: inline minimal Pagefind reset (~300B) and drop the link entirely.

### P0-3 — Tap target sizing on pagination, footer links, theme-toggle/search-button on mobile
**Where:** `assets/css/components.css:155-172` (pagination), `assets/css/layout.css:68-81` (footer), `assets/css/layout.css:45-56` + `assets/css/search.css:10-25` (`.theme-toggle` + `.search-button` = `2rem × 2rem` = 32×32 — under WCAG 2.5.8 AA threshold of **24×24** so passes 2.5.8 minimum but **fails 2.5.5 AAA** and Lighthouse "Tap targets" audit which uses **48×48 px**)
**Why it costs Lighthouse points:** Lighthouse mobile audit specifically measures "Tap targets are sized appropriately" against a 48×48 CSS-px threshold (not WCAG's 24×24). At 32×32, every interactive icon in the header fails. Pagination `<a>` is `padding: 0.25rem 0.75rem; min-width: 2rem;` → ~32×28 on mobile. Multiple failed targets each cost ~5 points. Phase 4 of v0.3.0 plans for WCAG 2.5.8 (24×24) but **not** Lighthouse's stricter 48×48 — flag this delta.
**Fix sketch:** Bump theme-toggle/search-button to `min-width:2.5rem; min-height:2.5rem` (40×40, still smaller than 48 but improves). For 48×48, use `padding: 0.5rem` and `min-width:3rem; min-height:3rem`. Pagination needs `padding: 0.5rem 0.75rem` and `min-height:2.75rem`. Footer link area can use `padding-block: 0.25rem` to expand hit zone without resizing visible text.

### P0-4 — Theme-toggle `aria-pressed` is set only in JS, not in HTML
**Where:** `layouts/_partials/header.html:10` (button has `aria-label` but no initial `aria-pressed`); `assets/js/theme-toggle.js:14,20` (sets `aria-pressed` after JS runs)
**Why it costs Lighthouse a11y points:** Lighthouse axe rule `button-name` + ARIA validation checks for `aria-pressed` consistency on toggle buttons that announce state. With JS disabled, the button is `hidden` (good), but Lighthouse runs with JS enabled, sees `aria-label="Đổi giao diện"` (only vi, no `aria-pressed`, no `role="switch"` either). On first paint *before* JS finishes parsing the module, screen readers see a button with no pressed state. Tooling counts this as "ARIA toggle button missing aria-pressed" → −5 to −10 a11y points.
**Fix sketch:** Render initial `aria-pressed` in the template based on a flash-prevention readable signal. Cleanest: inline the theme-flash script and set `aria-pressed` directly:
```html
<button … data-theme-toggle aria-pressed="false" hidden>…</button>
```
Then have the inline `<script>` in `head.html:13-22` also update `aria-pressed` *before* body paints. This is also the right place to set `data-theme="dark"` for SSR. Currently the inline script only sets `data-theme`, not `aria-pressed`.

### P0-5 — `i18n/en.yml` missing; English-default sites will paint vi strings
**Where:** `i18n/vi.yml` (only file); `layouts/_markup/render-heading.html:4` (`aria-label="Liên kết đến phần này"` hardcoded vi); `layouts/_partials/footer.html:7` (`{{ i18n "poweredBy" | default "Powered by" }}`)
**Why it costs Lighthouse points:** A consumer site with `defaultContentLanguage: en` and `languageCode: en` will get:
- `<html lang="en">` correct
- All `i18n "x" | default "English fallback"` calls fall to the default text (mixed quality, some still vi e.g. `i18n "search" | default "Tìm kiếm"` in `search-button.html:1` falls back to **vi** — see also `archives/list.html:14`, `search/list.html:11`, many spots)
- `render-heading.html:4` hardcodes `aria-label="Liên kết đến phần này"` regardless of site language — Lighthouse a11y axe rule `lang` flags content text inconsistent with `<html lang>`.
**Why this is P0:** Already in Phase 3 of v0.3.0 — but the heading-anchor hardcoded vi is *not* fixed by adding `en.yml`, it requires a template change. Without en.yml + render-heading.html i18n, an English site fails Lighthouse a11y because language attribute / content mismatch.
**Fix sketch:**
1. Ship `i18n/en.yml` with all 40 keys (already on Phase 3 todo).
2. Move `aria-label` in `render-heading.html` to `{{ i18n "headingAnchor" | default "Anchor link" }}` and add the key to both bundles.
3. Audit all `| default "vi string"` and either drop (now key exists) or convert to language-neutral. P2-9 in prior audit lists the pass.

---

## P1 — improves score but doesn't block ≥80

### P1-1 — Inline theme-flash script is render-blocking but not SRI-protected
**Where:** `layouts/_partials/head.html:13-22`
**Why:** The 9-line inline `<script>` runs synchronously before paint. Total cost ~200B uncompressed inline; not large but every Lighthouse "minimize render-blocking" audit gives full credit only when no synchronous JS appears in `<head>`. The pattern is correct (necessary for no-flash dark mode), so the *fix* is acknowledgment, not removal. Worth noting: the inline script has no nonce/SRI — if a consumer adds a strict CSP, this script breaks. Document the CSP requirement.
**Fix:** Add `nonce="{{ .CSPNonce }}"` placeholder + documentation. No code change urgent.

### P1-2 — `home-hero-avatar` and `project-card-image` lack `srcset` / responsive sizes
**Where:** `layouts/_partials/home/hero.html:5` (avatar 120×120 explicit, good — but only one size), `layouts/_partials/home/projects.html:13` (no width/height, no srcset)
**Why:** Lighthouse "Properly size images" audit fires when an image's intrinsic size is materially larger than its display size. Avatar SVG is fine; project images at 16:9 aspect ratio crop with `object-fit:cover` — if a consumer ships a 2000×1500 JPG it loses points.
**Fix:** Use Hugo `.Resources.GetMatch` + `.Resize` to generate `srcset` for project images. Requires moving `data/projects.yaml` images to page resources or doing `images.Resize` on `resources.Get` results. Bigger refactor — defer to v0.4 with cover-image work (P0-1).

### P1-3 — `project-card-image` `<img>` missing explicit `width`/`height` → CLS risk
**Where:** `layouts/_partials/home/projects.html:13` (`<img src="..." alt="..." loading="lazy" decoding="async">` — no `width`/`height`)
**Why:** The `aspect-ratio: 16/9` on `.project-card-image` reserves space, so CLS is currently 0 on demo. But: if a consumer's image's intrinsic aspect ratio differs from 16:9, `object-fit: cover` masks it but Lighthouse's CLS metric also penalizes lack of dimensional hints on `<img>`.
**Fix:** Add `width="640" height="360"` (canonical 16:9) hint to the `<img>`. Trivial.

### P1-4 — Site-wide JS bundle (theme-toggle + code-copy) loaded on every page kind
**Where:** `layouts/_partials/footer.html:13-18`
**Why:** 1.04 KB gz across the board. Lighthouse penalizes unused JS. `code-copy.js` is dead bytes on home/list/taxonomy/search (no `<pre>` blocks). This is **P2-3 in the prior audit** + already on v0.3.0 Phase 2 todo. Mentioning here for completeness: gating saves ~500B gz from home Lighthouse measurement.
**Fix:** Already planned (Phase 2 budget rebase). No additional action.

### P1-5 — No `<link rel="preconnect">` / `<link rel="dns-prefetch">` for Giscus / Pagefind worker
**Where:** `layouts/_partials/comments.html:7` (Giscus loaded async, but no preconnect to `giscus.app`); search Pagefind worker loaded lazily
**Why:** When comments enabled, the first paint waits on Giscus iframe DNS + TLS handshake. Adding `<link rel="preconnect" href="https://giscus.app" crossorigin>` in `head.html` (conditional on Giscus enable + post-kind) saves 200–500ms on third-party connect.
**Fix sketch:**
```html
{{- $g := site.Params.comments.giscus -}}
{{- if and (eq .Kind "page") $g $g.enable $g.repo $g.repoId $g.categoryId (ne .Params.comments false) }}
<link rel="preconnect" href="https://giscus.app" crossorigin>
{{- end }}
```

### P1-6 — `hreflang` alternate links not emitted; README/features advertise "i18n"
**Where:** `layouts/_partials/head.html` (no `<link rel="alternate" hreflang="...">` block); `theme.toml` lists `i18n` as a feature tag
**Why:** Lighthouse SEO checks for `hreflang` on multilingual sites. tsuki is single-language by default (vi only) but documentation claims i18n. A consumer running `languages: {vi: {...}, en: {...}}` gets pages built but no `hreflang` linking — Lighthouse SEO drops 2–4 points on each language root.
**Fix sketch:** Add to `head.html`:
```html
{{- if site.Home.AllTranslations }}
{{- range .AllTranslations }}
<link rel="alternate" hreflang="{{ .Language.Lang }}" href="{{ .Permalink }}">
{{- end }}
<link rel="alternate" hreflang="x-default" href="{{ site.Home.Permalink }}">
{{- end }}
```
Cheap, conditional, no penalty when not used.

### P1-7 — `og:locale:alternate` missing for multi-language
**Where:** `layouts/_partials/head/seo.html:28-30`
**Why:** Same as P1-6 — supplementary; only emits one `og:locale`. OpenGraph spec supports `og:locale:alternate`.
**Fix:** Append `og:locale:alternate` per translation when present.

### P1-8 — `<noscript>` style block missing for theme-toggle / code-copy / pagefind UI
**Where:** none — entire theme has only one `<noscript>` (`layouts/search/list.html:18`)
**Why:** Lighthouse a11y axe rule `landmark-no-duplicate-banner` and similar don't fire, but the audit "Page contains a meta description" / "Document has a valid hreflang" / etc. — fine. Practical impact: SR users with JS off see "◐" toggle button after `hidden` is removed by JS. Currently the button stays `hidden`. Edge case.
**Fix:** None blocking. Document in `docs/accessibility.md` (Phase 4 has it).

### P1-9 — Service worker / PWA not present
**Why:** Lighthouse PWA audit is informational, doesn't count toward Performance/Accessibility/Best-Practices/SEO. **Skip.** Documenting for completeness.

### P1-10 — `head.html` description fallback chain differs from `head/seo.html`
**Where:** `head.html:2` falls back to `site.Title`; `head/seo.html:7-9` falls back to nothing (only truncates if present)
**Why (SEO):** Already P2-11 in prior audit. `<meta name="description">` may emit `site.Title` while `og:description` is missing. Lighthouse SEO checks for `meta description` presence — passes. Cosmetic inconsistency only. Won't move score.
**Fix:** Hoist to shared partial. Phase 2 (budget rebase) is a good landing spot.

### P1-11 — Pagefind worker JS lacks SRI / `crossorigin` matching theme bundle
**Where:** `layouts/search/list.html:28-49`
**Why:** Third-party Pagefind UI script (inline import) has no integrity. CSP "strict-dynamic" friendly but a `<script type="module">` with dynamic `import` defeats SRI anyway. Best-practices audit doesn't penalize. **Skip** — no fix.

### P1-12 — `<title>` truncation absent
**Where:** `layouts/_partials/head.html:1` (`{{- $title := cond .IsHome site.Title (printf "%s · %s" .Title site.Title) -}}` — no length cap)
**Why:** Long post titles ("My very long post title about etc..." × site.Title) can exceed Google SERP truncation (~60 chars). Lighthouse SEO doesn't check; SEO tools do.
**Fix:** Optional `truncate 60` on the composed title for non-home pages. Not blocking ≥80.

---

## P2 — polish / future

### P2-1 — JSON-LD `image` and `publisher.logo` reuse the avatar SVG
**Where:** `layouts/_partials/head/seo.html:71,83`
Built output (`2026/01/10/ke-hoach-dau-nam/index.html`) confirms `publisher.logo.url` = avatar.svg. Google Structured Data Testing Tool requires logo to be PNG/JPG; SVG is rejected by some validators. Lighthouse SEO doesn't validate JSON-LD content, only presence. Won't move Lighthouse score but breaks Search Console rich-result eligibility. Add a `params.og.logoImage` distinct from avatar.

### P2-2 — `:where()` + `:has()` + View Transitions are progressive; no Modernizr / fallback class
**Where:** `assets/css/view-transitions.css:3` (`@view-transition`), various uses of `:where()` in tokens.css
**Why:** Lighthouse Best Practices audit "CSS has invalid syntax" — both `@view-transition` and `:where()` are post-CR. Modern browsers parse cleanly; older browsers silently ignore. Not a deduction. **Skip.**

### P2-3 — `min-height: 100vh` on `body` causes mobile-iOS overscroll issues
**Where:** `assets/css/reset.css:8`
**Why:** Cosmetic on iOS Safari URL bar. Lighthouse doesn't check. Modern alternative is `min-height: 100dvh`. **Trivial fix.**

### P2-4 — Avatar `<img>` background is `var(--tsuki-code-bg)` — visible empty disk during SVG load
**Where:** `assets/css/home.css:15` + `layouts/_partials/home/hero.html:5`
**Why:** A circular div with bg color in case SVG never paints. Not a CLS issue since width/height are set. Cosmetic.

### P2-5 — `code-copy.js` runs `querySelectorAll("pre")` synchronously at module top
**Where:** `assets/js/code-copy.js:6`
**Why:** Module is loaded with `defer` semantics (via `type=module`). Runs after DOMContentLoaded. No DOM-mutation main-thread block. Lighthouse "main-thread work" minimal. Already noted in P2-3 of prior audit.

### P2-6 — `IntersectionObserver` in `toc-active.js` runs even on posts under threshold
**Where:** Already gated by `partial "toc-enabled.html"` in `footer.html:19-22`. Verified clean.

### P2-7 — `Cache-Control` headers are not under theme control
**Why:** GitHub Pages default. tsuki ships hashed bundles, so consumer caching is achievable via consumer's hosting config. Document in `docs/deployment-guide.md` if not already. Out of theme scope.

### P2-8 — Color contrast: `--tsuki-fg-subtle: #888` on `--tsuki-bg: #fbfaf7` (light) and `#777` on `#14151a` (dark)
**Where:** `assets/css/tokens.css:6,53`
**Static contrast check:**
- Light: `#888` on `#fbfaf7` ≈ 3.54:1 — **fails WCAG AA 4.5:1 for body text**, passes 3:1 for large text (≥18pt or 14pt bold).
- Dark: `#777` on `#14151a` ≈ 4.7:1 — passes 4.5:1 for body text.
- `--tsuki-fg-muted: #666` on `#fbfaf7` ≈ 5.7:1 — passes.
- `--tsuki-fg-muted: #a0a0a0` on `#14151a` ≈ 7.6:1 — passes.

The `fg-subtle` token is used for `post-card-date`, `pagination .disabled`, `archive-post-date`, `heading-anchor`, `term-count`, all rendered at `--tsuki-fs-sm` (15px). 15px is below the 18pt/24px large-text threshold. **Light-mode `fg-subtle` fails WCAG AA.** Lighthouse axe contrast rule will flag every page card date → −10 to −20 a11y points.

**Fix:** Darken `--tsuki-fg-subtle` from `#888` to `#717171` (4.5:1) or `#6b6b6b` (5:1). Test against dark mode (`#777` is fine but if both must move in unison, dark gets `#9a9a9a`).

### P2-9 — `.pagination .disabled { opacity: 0.5 }` compounds existing low contrast
**Where:** `assets/css/components.css:170`
**Why:** Disabled pagination links use `--tsuki-fg-subtle` (~3.5:1 light) × `opacity:0.5` = effective 1.5–2:1. Even WCAG AAA disabled-state exemption may not apply if Lighthouse axe treats it as text. Likely flagged.
**Fix:** Use `--tsuki-fg-muted` (#666) for disabled state — better contrast even at 0.5 opacity. Or use `pointer-events:none; cursor:not-allowed;` without opacity.

### P2-10 — `.callout` text uses `var(--tsuki-fg)` on `var(--tsuki-callout-bg)` light tint (e.g., `#2563eb14` = 8% blue)
**Where:** `assets/css/callouts.css:9,22-26`
**Why:** `#2563eb14` overlay on `--tsuki-bg: #fbfaf7` = pale blue ≈ `#e9eef9`. Body text `#1a1a1a` on `#e9eef9` ≈ 14.8:1 — fine. Title color `var(--tsuki-callout)` = `#2563eb` on the tint ≈ 5.7:1 — passes.
Dark mode: `#6ea1ff1f` overlay on `#14151a` = `#1d2434` — title `#6ea1ff` on `#1d2434` ≈ 7.4:1. Fine. **No issue.**

### P2-11 — `.callout-warning` title `#d97706` on light tint
**Where:** `assets/css/callouts.css:25`
`#d97706` (amber) on `#fbf6ef` (#d97706 + 8% on bg) ≈ 3.2:1 — **fails 4.5:1 AA for body text but is title-only**. Lighthouse axe checks all text. Could trip on bold-but-small title text. Test with axe.
**Fix:** Bump title to `#b45309` (3.8:1) for light mode or move title to body color and rely on color only on the border.

### P2-12 — `.theme-toggle` button-shape relies on `border-radius:999px` + 32px square — focus ring `outline-offset:2px` overflows into adjacent search button on narrow viewports
**Where:** `assets/css/components.css:4-7` + `assets/css/layout.css:45-56` + `assets/css/search.css:5-8` (`gap: var(--tsuki-space-2)` = 8px)
**Why:** Two adjacent circular buttons at 8px gap with 2px outline + 2px offset → ring touches sibling. Visual bug, not Lighthouse impact.

### P2-13 — `<details>` rendering unstyled (callouts replace one use case; raw `<details>` still common)
Already P2-1 in prior audit; v0.3.0 Phase 3 covers.

### P2-14 — `og:image` `width` / `height` not declared
**Where:** `layouts/_partials/head/seo.html:32`
**Why:** Twitter/Facebook clip aggressively without dims. Not Lighthouse SEO — SEO of social previews. Minor.

### P2-15 — `meta name="theme-color"` not emitted
**Where:** `head.html` does not emit `<meta name="theme-color">`.
**Why:** Chrome on Android colors the URL bar with this. Light + dark variants supported via `media`. Cosmetic; not Lighthouse-scored. Adds polish.
**Fix:**
```html
<meta name="theme-color" content="#fbfaf7" media="(prefers-color-scheme: light)">
<meta name="theme-color" content="#14151a" media="(prefers-color-scheme: dark)">
```

### P2-16 — `<html>` `lang` attribute hardcoded fallback to `vi`
**Where:** `layouts/baseof.html:2` (`lang="{{ site.LanguageCode | default "vi" }}"`)
**Why:** If consumer sets `languageCode: en-US` and `defaultContentLanguage: en`, `<html lang="en-US">` — fine. If they forget `languageCode`, it falls to `vi` — Lighthouse a11y `html-has-lang` passes but Lighthouse SEO `html-lang-valid` may flag mismatch with content. Defensive.
**Fix:** Use `site.Language.LanguageCode | default site.Language.Lang | default "en"`. Drop the vi default — site should set its own language.

### P2-17 — Skip-link `inset-block-start: -3rem` may not be enough on dynamic header heights
**Where:** `assets/css/components.css:11`
**Why:** If header wraps to 2+ lines on mobile, `-3rem` may not fully hide. Cosmetic. Use `transform: translateY(-200%)`.

### P2-18 — `gohugoThemes` registry CI not yet green (per v0.3.0 plan note)
Out of Lighthouse scope, mentioned for tracking.

---

## Already addressed (do not duplicate)

The following are already shipped in v0.2.0 / v0.2.1 (verified against current code):

- ✅ **Visible focus rings** (`assets/css/components.css:4-7`) — `:focus-visible { outline: 2px solid var(--tsuki-accent) }`. Note: P0-3 / P2-8 above may push focus contrast below 3:1 in light mode (accent `#4a6fa5` on bg `#fbfaf7` ≈ 5.3:1 — passes 3:1 SC 2.4.13 but only just).
- ✅ **Skip-link** (`layouts/baseof.html:8`, `components.css:8-20`).
- ✅ **`<main id="main">` landmark** (`baseof.html:10`).
- ✅ **Render-image `loading="lazy" decoding="async"`** (`render-image.html:2`).
- ✅ **Render-link `rel="noopener noreferrer"` for external** (`render-link.html:7-10`).
- ✅ **Project links `safeURL` + `noopener noreferrer` + `target=_blank`** (`home/projects.html:30,33`).
- ✅ **JSON-LD Article schema** with full author/publisher/keywords/image/datePublished/dateModified (`head/seo.html:62-87`, validated in built post).
- ✅ **OG + Twitter Cards** with locale, article:author, article:tag, rune-safe 200-char truncate.
- ✅ **Canonical URL** (`head.html:10`).
- ✅ **Viewport meta** (`head.html:5`).
- ✅ **`<html lang>`** (`baseof.html:2`).
- ✅ **Sitemap + RSS** (built `exampleSite/public/sitemap.xml` + `index.xml` confirmed).
- ✅ **No mixed content** (`grep -c 'http://'` on built home + post = 0).
- ✅ **SRI integrity + crossorigin** on CSS + JS bundles (`head.html:62`, `footer.html:18,21,26`).
- ✅ **Hugo generator stripped** (`<meta name=generator content="tsuki">`, no Hugo version).
- ✅ **CSS budget 3962/4200 B gz** (verified via gzip on built bundle).
- ✅ **`prefers-reduced-motion` honored** (`reset.css:35-42`, `view-transitions.css:15-18`).
- ✅ **Pagination paginated-kind gate** (`head.html:33-40`, `pagination.html:2`).
- ✅ **`hidden` attribute** on theme-toggle pre-JS (`header.html:10`) — good no-JS UX.
- ✅ **Comments gate requires repo + repoId + categoryId** (`comments.html:2`).
- ✅ **`seo.html` `$authorURL` chain nil-safe** (`head/seo.html:64-67`).
- ✅ **`nav.html` `relURL`** (`nav.html:6`).
- ✅ **htmltest pinned to commit SHA** (`.github/workflows/pages.yml:69`).
- ✅ **Smoke tests for JSON-LD / OG / skip-link / main-id / render-link rel / CSS budget** (`scripts/smoke-tests.sh`).

---

## Covered by v0.3.0 plan (do not re-fix; flag if reordering needed)

- **Per-page-kind CSS bundles** — Phase 2 (covers P1-4 site-wide JS gating too).
- **`i18n/en.yml`** — Phase 3 (covers P0-5 partially; **add render-heading.html `aria-label` i18n** to Phase 3 todo).
- **`<details>` styling + TOC narrow-viewport collapse** — Phase 3.
- **WCAG 2.2 AA pass** including focus appearance + tap targets ≥24×24 — Phase 4 (**bump tap target threshold to Lighthouse's 48×48 to cover P0-3; flag P2-8 contrast on `fg-subtle` for token adjustment**).
- **llm.txt + Speculation Rules** — Phase 5 (Speculation Rules will help LCP on internal nav and contribute to Performance score; opt-in is correct).
- **Smoke-test expansion + Hugo CI matrix** — Phase 6.

---

## Recommended scope additions for v0.3.0

Two findings above are scope-adjacent enough they should fold into existing phases rather than being deferred:

1. **Add P0-1 (cover-image LCP) as a Phase 3 sub-task or new Phase 3.5.** Currently no phase touches `single.html` rendering of cover. Either (a) document override path in `docs/customization.md` + warn that default doesn't render cover (cheap), or (b) ship a default cover renderer in `single.html` with preload + `fetchpriority="high"`. Recommend (a) for v0.3.0, (b) for v0.4.0 alongside `images.Resize`/`srcset` pipeline.

2. **Add P0-2 (Pagefind UI CSS preload swap) to Phase 5 or Phase 2.** Trivial change (~3 lines in `search/list.html`), zero CSS impact. Drop in Phase 2 (budget rebase already touches search.css).

3. **Add P0-3 (Lighthouse 48×48 tap targets) as a Phase 4 success criterion.** Phase 4 currently targets WCAG 24×24; Lighthouse uses 48×48. Update Phase 4 success criteria to "≥48×48 on theme-toggle / search-button / pagination / footer links" — or explicitly accept Lighthouse a11y of 90-94 (still ≥80) as the bound.

4. **Add P0-4 (theme-toggle `aria-pressed` in HTML) to Phase 4.** Single-line change; needs inline-script update too. ~3 lines total.

5. **Add P1-5 (preconnect to giscus.app) to Phase 2.** Conditional emit alongside other head logic.

6. **Add P1-6 (`hreflang` alternate links) to Phase 3 or 5.** ~6 lines in `head.html`. Cheap. Without it the theme cannot honestly claim "i18n" as a feature in `theme.toml`.

7. **Add P2-8 (color contrast `fg-subtle` in light mode) to Phase 4.** Token adjustment, one-line change in `tokens.css`. Critical because every post-card date and pagination disabled state is affected — this alone could be a 10-point a11y hit.

**Phase 4 (WCAG 2.2 AA audit) is the keystone phase for Lighthouse a11y ≥95.** It already targets 95; the three additions above (P0-3 thresholds, P0-4 toggle ARIA, P2-8 contrast token) are the deltas between "WCAG 2.2 AA" and "Lighthouse a11y ≥95". They're sub-task adjustments, not new phases.

---

## Confidence + caveats

- **Bundle sizes are real**: 3.96 KB gz CSS / 1.04 KB gz JS (measured from `exampleSite/public/`). Performance numbers will be high.
- **Color contrast is computed**, not eyeballed: light-mode `fg-subtle: #888` on `bg: #fbfaf7` is 3.54:1 — **inspect on axe-devtools to confirm**.
- **Tap-size delta** (WCAG 24×24 vs Lighthouse 48×48) is the most likely place this audit underestimates: actual measurement may show pagination + theme-toggle as fail. Worth running Lighthouse-mobile against the demo before committing to a tap-size scope decision in Phase 4.
- **JSON-LD is valid** (parsed mentally against schema.org Article spec from built output) — Lighthouse SEO will count this positively. Note SVG logo is a Google rich-result rejection risk (P2-1), not a Lighthouse deduction.
- **No CSP, no analytics, no third-party fonts** — Performance ceiling is high.
- **Cover-image LCP** is the single biggest blind spot in this audit because exampleSite has no covers. If a consumer's site is what gets measured for the README claim, P0-1 is the difference between Performance 95 and Performance 75.

---

## Unresolved questions

1. **Which `exampleSite` configuration is the canonical Lighthouse target?** If the README ever claims "≥80 Lighthouse", which page kinds and configurations is the claim scoped to? Home only, or home + a post + list + search? Suggest documenting in `docs/accessibility.md` + adding 4 Lighthouse runs to CI on tag (Phase 6 candidate).
2. **Cover-image rendering — theme or consumer responsibility?** Phase 3 (author UX) is the right place to decide. If theme renders cover, what's the default size and aspect ratio? If consumer renders, how do we document `cover.image` is OG-only by default?
3. **`og:image` resolution chain emits SVG avatar** when no cover is set; Google rich-result requires PNG/JPG. Worth shipping a default PNG asset alongside the SVG, or documenting that consumers ship their own PNG? Affects P2-1.
4. **Tap-size target: WCAG 24×24 or Lighthouse 48×48?** Phase 4 currently aims at WCAG. Tightening to 48×48 may change pagination + theme-toggle visual design materially. Maintainer decision before Phase 4 begins.
5. **Is `aria-pressed` on theme-toggle the right ARIA pattern, or `role="switch"` with `aria-checked`?** Both are valid; `switch` is more semantic for binary state. Affects P0-4 fix shape.
6. **Should the demo site enable Speculation Rules** so the README Performance claim includes the prefetch benefit, or stay opt-in and claim a lower Performance number? Affects Phase 5 demo config.
7. **`hreflang` emit even when site is single-language** — harmless (empty range, no output) but adds template noise. Or gate on `site.IsMultiLingual`? Pick one.
8. **Color contrast change to `--tsuki-fg-subtle`** would affect every site visually (dates appear darker). Acceptable design trade-off, or token requires a new variant (`--tsuki-fg-faint` for non-text decorations vs `--tsuki-fg-subtle` for accessible text)?
