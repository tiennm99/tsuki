# Accessibility

tsuki targets **WCAG 2.2 AA** conformance with **Lighthouse Accessibility ≥ 95** on every page kind. This document records what's covered, what's deferred, and how to measure on your own site.

## Conformance summary

| Area | Status | Notes |
|------|--------|-------|
| Skip link | ✅ Shipped | First focusable; jumps to `<main id="main">` |
| Landmark roles | ✅ Shipped | `<header>`, `<nav>`, `<main>`, `<aside>`, `<footer>` |
| Visible focus rings | ✅ Shipped | `:focus-visible` with 2px outline + accent colour |
| `<html lang>` correctness | ✅ Shipped | Resolves from `site.Language.Lang`; falls back to `"en"` |
| `aria-pressed` on toggle | ✅ Shipped | SSR-rendered before paint |
| `<meta name="theme-color">` | ✅ Shipped | Light + dark variants |
| Heading anchor i18n | ✅ Shipped | `aria-label` uses `linkToSection` i18n key |
| Reduced motion | ✅ Shipped | View Transitions + animations honour `prefers-reduced-motion` |
| Colour contrast (text) | ✅ Shipped | All body text ≥ 4.5:1 in both themes; `--tsuki-fg-subtle` darkened to `#6b6b6b` (light) for AA compliance |
| Pagination disabled-state contrast | ✅ Shipped | Uses `--tsuki-fg-muted` + `cursor: not-allowed`; no `opacity` compound |
| Tap targets ≥ 40×40 | ✅ Shipped | Header toggle/search-button 2.5rem; pagination 2.75rem; footer links padded |
| Tap targets ≥ 48×48 (strict Lighthouse) | ⚠️ Partial | Header buttons at 40×40 (2.5rem); Lighthouse may flag, score remains ≥ 80 |
| Forms (search) | ✅ Shipped | Pagefind UI ships its own label semantics |
| `<details>` keyboard support | ✅ Native | Tab → Enter to toggle |
| Drag operations (SC 2.5.7) | ✅ N/A | Theme has no drag UI |

## Measuring on your site

Use the latest Chrome DevTools or `lighthouse` CLI:

```bash
npx lighthouse https://your-site.example.com/ \
  --only-categories=accessibility,performance,best-practices,seo \
  --form-factor=mobile --throttling-method=simulate \
  --output=html --output-path=./lh.html
```

Run against **production** (a live URL), not a localhost build — service workers, caching, TLS, and font loading all affect scores.

## Project baseline

Measured on `https://tiennm99.github.io/tsuki/` (mobile profile, median of 3 runs). Update these when the build changes materially.

| Page kind | Performance | A11y | Best Practices | SEO |
|-----------|------------:|-----:|---------------:|----:|
| Home (`/`) | TBD | TBD | TBD | TBD |
| Post | TBD | TBD | TBD | TBD |
| List (`/post/`) | TBD | TBD | TBD | TBD |
| Search (`/search/`) | TBD | TBD | TBD | TBD |

Targets: Performance ≥ 80, Accessibility ≥ 95, Best Practices ≥ 80, SEO ≥ 80.

## Known limitations

- **Tap targets on the header buttons** — theme-toggle and search-button are 40×40 px (2.5rem). The Lighthouse "Tap targets are sized appropriately" audit measures against 48×48 px and may flag these. Visual design tradeoff; bump to 3rem to silence the audit at the cost of a larger header footprint.
- **`prefers-color-scheme: no-preference`** is treated as light. There is no third "auto" state in the toggle UI — click cycles light ↔ dark only.
- **Goldmark `unsafe: true`** is the default — your content controls what HTML renders. Untrusted authorship surfaces should override `markup.goldmark.renderer.unsafe: false`.
- **Pagefind UI** ships its own CSS and ARIA semantics. tsuki maps colour tokens but does not override Pagefind's structure.

## Reporting accessibility regressions

Open an issue at [tiennm99/tsuki](https://github.com/tiennm99/tsuki/issues) with the WCAG 2.2 SC reference and a reproduction URL. Patches welcome.
