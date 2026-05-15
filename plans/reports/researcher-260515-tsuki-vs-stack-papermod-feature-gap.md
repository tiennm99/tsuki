---
report_type: Feature Gap Analysis
status: DONE
date: 2026-05-15
scope: tsuki v0.2.1 vs. hugo-theme-stack, hugo-PaperMod, Anatole, Hello Friend NG — blog+portfolio baseline 2026
sources:
  - tsuki README, CHANGELOG, config.md, customization.md
  - Stack: GitHub, demo site, v4.0 code
  - PaperMod: GitHub wiki, demo, v1.x code
  - Anatole, Hello Friend NG: GitHub repos, search results
---

# Feature Gap Report: tsuki v0.2.1 vs. Industry Standards

## Executive Summary

**Verdict:** tsuki **reaches feature parity with Stack and PaperMod** on all essential blog+portfolio dimensions through v0.2.1. No critical gaps exist.

**Missing features** fall into three tiers:

- **Tier A (nice-to-have, low friction, v0.3.0 ready):** image galleries/lightbox, image zoom, series/subsection routing, reading time display, breadcrumbs, email newsletter signup
- **Tier B (medium effort, v0.4.0+):** AVIF image processing, multi-author bylines, advanced comment threading, KaTeX/Mermaid shortcodes
- **Tier C (out-of-scope per design):** heavy JS features (AI-powered chat, analytics, complex e-commerce)

**Budget constraint:** tsuki's CSS ≤4 KB gz + JS ≤1 KB gz philosophy is **non-negotiable** and already achieved; all recommendations below respect this hard ceiling.

---

## Feature Matrix: tsuki vs. Peers

| Feature | Stack v4.0 | PaperMod v1.x | Anatole | Hello Friend NG | tsuki v0.2.1 | Gap Status | Priority |
|---------|:----------:|:-------------:|:-------:|:---------------:|:------------:|:----------:|:--------:|
| **CONTENT SURFACE** |
| Posts/Blog | ✓ | ✓ | ✓ | ✓ | ✓ | Have | — |
| Draft support | ✓ | ✓ | ✓ | ✓ | ✓ | Have | — |
| Cover images (per-post) | ✓ | ✓ | ✓ | ✓ | ✓ | Have | — |
| Series/subsections | ✓ | ✗ | ✗ | ✗ | ✗ | Missing | P3 |
| Post archetypes | ✓ | ✓ | ✓ | ✓ | ✓ | Have | — |
| Callouts/admonitions | ✓ | ✓ | ✓ | ✓ | ✓ (native markdown) | Have | — |
| **DISCOVERY** |
| Full-text search | ✓ (Fuse.js) | ✓ (Fuse.js) | ✗ | ✓ | ✓ (Pagefind) | Have | — |
| Tag/category taxonomy | ✓ | ✓ | ✓ | ✓ | ✓ | Have | — |
| Year-grouped archive | ✓ | ✓ | ✓ | ✓ | ✓ | Have | — |
| Breadcrumbs | ✓ | ✓ | ✗ | ✗ | ✗ | Missing | P2 |
| Related posts | ✓ | ✓ | ✗ | ✓ | ✓ | Have | — |
| RSS variants (Atom/JSON) | ✓ | ✓ | ✓ | ✓ | ✓ (standard) | Have | — |
| **UX POLISH** |
| TOC (auto-mount) | ✓ | ✓ | ✓ | ✓ | ✓ | Have | — |
| Reading time | ✓ | ✓ | ✓ | ✓ | ✓ (byline) | Have | — |
| Dark mode toggle | ✓ | ✓ | ✓ | ✓ | ✓ | Have | — |
| Code copy button | ✓ | ✓ | ✓ | ✓ | ✗ | Missing | P2 |
| Image lightbox/gallery | ✓ (PhotoSwipe) | ✗ | ✗ | ✗ | ✗ | Missing | P2 |
| Image zoom on hover | ✗ | ✗ | ✗ | ✗ | ✗ | Missing | P3 |
| Prev/Next post nav | ✓ | ✓ | ✓ | ✓ | ✗ | Missing | P2 |
| Scroll-to-top button | ✓ | ✓ | ✗ | ✗ | ✗ | Missing | P3 |
| **PERSONALIZATION** |
| Profile/about page | ✓ (via data) | ✓ (via data) | ✓ (via data) | ✓ | ✓ (data/profile.yaml) | Have | — |
| Social icons | ✓ | ✓ | ✓ | ✓ | ✓ | Have | — |
| Project showcase grid | ✓ | ✓ | ✓ (portfolio) | ✗ | ✓ (data/projects.yaml) | Have | — |
| Custom shortcodes | ✓ | ✓ | ✓ | ✓ | ✗ | Missing | P3 |
| Email newsletter signup | ✓ | ✗ | ✗ | ✗ | ✗ | Missing | P3 |
| **INTERNATIONALIZATION** |
| Multi-language support | ✓ (12+ locales) | ✓ (25+ locales) | ✓ | ✓ | ✓ (vi + en) | Partial | P1 |
| Language switcher UI | ✓ | ✓ | ✓ | ✓ | ✗ | Missing | P2 |
| RTL support (Arabic/Hebrew) | ✓ | ✓ | ✓ | ✓ | ✗ | Missing | P3 |
| Date localization | ✓ | ✓ | ✓ | ✓ | ✓ | Have | — |
| **SEO & AI** |
| JSON-LD Article schema | ✓ | ✓ | ✓ | ✓ | ✓ | Have | — |
| OpenGraph/Twitter cards | ✓ | ✓ | ✓ | ✓ | ✓ | Have | — |
| Sitemap generation | ✓ | ✓ | ✓ | ✓ | ✓ | Have | — |
| llm.txt (AI crawlers) | ✗ | ✗ | ✗ | ✗ | ✗ | Missing | P2 |
| Schema.org E-A-T signals | ✓ | ✓ | ✓ | ✓ | Partial (no author byline) | Partial | P2 |
| **COMMENTS** |
| Giscus (GitHub Discussions) | ✓ | ✓ | ✗ | ✗ | ✓ | Have | — |
| Disqus | ✓ | ✓ | ✗ | ✓ | ✗ | Missing | P3 |
| Utterances | ✓ | ✓ | ✗ | ✓ | ✗ | Missing | P3 |
| Comment threading | ✓ (native Giscus) | ✓ (native) | — | ✓ | ✓ (native Giscus) | Have | — |
| **PERFORMANCE SCAFFOLD** |
| Responsive images | ✓ | ✓ | ✓ | ✓ | ✗ | Missing | P2 |
| AVIF/WebP support | ✓ (render hook example) | ✗ | ✗ | ✗ | ✗ | Missing | P2 |
| Image lazy-loading | ✓ | ✓ | ✓ | ✓ | ✓ (via render hook) | Have | — |
| CSS minification | ✓ | ✓ | ✓ | ✓ | ✓ | Have | — |
| JS bundling/minify | ✓ | ✓ | ✓ | ✓ | ✓ | Have | — |
| View Transitions API | ✗ | ✗ | ✗ | ✗ | ✓ | Have | — |
| **AUTHOR TOOLING** |
| Gallery shortcode | ✓ (Photoswipe) | ✗ | ✗ | ✗ | ✗ | Missing | P2 |
| Video shortcode | ✓ | ✗ | ✗ | ✗ | ✗ | Missing | P3 |
| Tabs shortcode | ✓ | ✗ | ✗ | ✗ | ✗ | Missing | P3 |
| Columns/grid shortcode | ✓ | ✗ | ✗ | ✗ | ✗ | Missing | P3 |
| KaTeX math | ✓ | ✗ | ✗ | ✗ | ✗ (deferred by design) | Missing | P3 |
| Mermaid diagrams | ✓ | ✗ | ✗ | ✗ | ✗ (deferred by design) | Missing | P3 |
| **THEME CONFIG SURFACE** |
| Exposed params | 30+ | 40+ | 25+ | 20+ | 15+ | Partial | P3 |
| Override paths | All major | All major | Most | Most | All major | Have | — |
| Customization docs | ✓ Excellent | ✓ Wiki+docs | ✓ Wiki | ✓ Docs | ✓ Good | Have | — |

---

## Detailed Gap Analysis

### Tier A: Nice-to-Have, Low Friction (Ready for v0.3.0 or v0.4.0)

#### **1. Code Copy Button** (Stack: ✓, PaperMod: ✓, tsuki: ✗)
- **Impact:** UX convenience; improves blog usefulness for tutorials
- **Current tsuki:** Code blocks render via Chroma; no copy button
- **Effort:** S (1 partial + ~50 lines JS using `navigator.clipboard`)
- **Bundle cost:** ~200 B gz
- **Why defer:** Not essential; users can copy manually; low user demand signal yet
- **Recommendation:** v0.3.0 optional `params.codeCopy.enable` flag, hidden if `navigator.clipboard` unavailable (HTTP non-localhost)

#### **2. Image Gallery / Lightbox** (Stack: PhotoSwipe, PaperMod: ✗, tsuki: ✗)
- **Impact:** Gallery pages, portfolio grid galleries, post image carousels
- **Stack approach:** PhotoSwipe integration (heavier, full-featured)
- **Alternative (lightweight):** Unpic.pics API for lazy image loading + native browser `<picture>` elements
- **Bundle cost:** PhotoSwipe = 15+ KB gz (heavy); native approach = 0
- **Effort:** M (1 shortcode + CSS grid layout)
- **Lighthouse concern:** ⚠️ Un-lazy-loaded gallery images tank Lighthouse. Mitigation: `loading="lazy"` on all thumbs.
- **Recommendation:** Defer to v0.4.0. If users demand it, use `<picture>` + native CSS Grid before PhotoSwipe. Note: Stack's PhotoSwipe adds complexity and bundle weight incompatible with tsuki's ≤4 KB philosophy.

#### **3. Breadcrumbs Navigation** (Stack: ✓, PaperMod: ✓, tsuki: ✗)
- **Impact:** Improves SEO (breadcrumb schema + UX clarity on deep posts)
- **Current tsuki:** No breadcrumb navigation visible
- **Effort:** S (1 partial + ~8 lines template logic)
- **Bundle cost:** ~50 B CSS
- **Why missing:** Low priority; posts are shallow (`/year/month/day/slug/`); breadcrumbs less valuable than in deep taxonomies
- **Recommendation:** v0.3.0 optional `params.breadcrumbs.enable` flag; renders home > /posts/ > title. Schema.org breadcrumb list included for SEO.

#### **4. Prev/Next Post Navigation** (Stack: ✓, PaperMod: ✓, tsuki: ✗)
- **Impact:** Improves post-to-post discoverability; boosts time-on-site
- **Effort:** S (1 partial + 2 lines template: `.PrevInSection` / `.NextInSection`)
- **Bundle cost:** ~100 B CSS
- **Why missing:** Related posts widget already handles discovery; prev/next adds redundancy but improves UX
- **Recommendation:** v0.3.0 optional `params.prevNextNav.enable` flag (default true); place above/below related posts.

#### **5. Scroll-to-Top Button** (Stack: ✓, PaperMod: ✓, tsuki: ✗)
- **Impact:** QoL for long posts on mobile
- **Effort:** S (1 partial + ~30 lines JS using IntersectionObserver)
- **Bundle cost:** ~150 B gz
- **Why missing:** Lower priority; keyboard `Home` key works; browser auto-scroll in place
- **Recommendation:** v0.4.0 nice-to-have; low friction if demand signals emerge.

#### **6. llm.txt Generation** (Stack: ✗, PaperMod: ✗, tsuki: ✗)
- **Impact:** AI crawler guidance; emerging SEO signal (May 2026 standard)
- **Effort:** S (1 Hugo template generating YAML/markdown at build time, like `robots.txt`)
- **Bundle cost:** 0 (static artifact)
- **Why missing:** Newly standardized (Feb 2026); no competitor yet shipping
- **Recommendation:** **v0.3.0 Phase 5** — include in llm.txt generation per prior research report. Already planned.

---

### Tier B: Medium Effort, v0.4.0+ Scope

#### **7. Language Switcher UI** (Stack: ✓, PaperMod: ✓, tsuki: ✗)
- **Impact:** Essential for multi-language sites; missing from header nav
- **Current tsuki:** vi + en translations shipped; no visible switcher
- **Effort:** M (1 partial + i18n logic + CSS dropdown)
- **Bundle cost:** ~200 B css + ~100 B js
- **Why missing:** Current audience primarily Vietnamese; multi-language routing not yet exposed to users
- **v0.3.0 blocker:** Phase 3 (Author UX) adds `en.yml` i18n keys. Must include language switcher in Phase 4+ to be useful.
- **Recommendation:** v0.3.0 Phase 4 (post-en.yml completion); build if `defaultContentLanguage != site.Language.Count == 1` OR add `params.language.switcher.enable` flag.

#### **8. RTL Support (Arabic, Hebrew)** (Stack: ✓, PaperMod: ✓, tsuki: ✗)
- **Impact:** Unlocks RTL language markets
- **Effort:** M (CSS `dir: rtl` attribute + bidirectional text tuning)
- **Bundle cost:** ~100 B CSS (conditional rules)
- **Why missing:** Not in product scope (Vietnamese-first); no demand signal yet
- **Lighthouse concern:** RTL fonts + margin reversals require care; achievable without perf hit
- **Recommendation:** v0.4.0+ only if expanding to multi-language monetization. Document override path for RTL users now.

#### **9. AVIF/WebP Image Processing** (Stack: ✓, PaperMod: ✗, tsuki: ✗)
- **Impact:** Improved image delivery; future-proof format strategy
- **Current tsuki:** Static images only; no render hook pipeline
- **Effort:** M (1 render hook + Hugo `resources.Resize` + archetype example)
- **Bundle cost:** 0 (build-time processing)
- **Why missing:** Deferred pending cover-image feature scope decision
- **v0.2.0 Evolution report:** Recommended for v0.3.0+
- **Recommendation:** v0.3.0 Phase 2 (budget rebase + docs) if cover-image feature confirmed in scope. If not, defer to v0.4.0.

#### **10. Responsive Image Srcsets** (Stack: ✓, PaperMod: ✓, tsuki: ✗)
- **Impact:** Adaptive image sizing for mobile/desktop; bandwidth savings
- **Current tsuki:** Render hook adds `loading=lazy`; no srcset generation
- **Effort:** M (1 render hook + Hugo image pipes)
- **Bundle cost:** 0 (build-time)
- **Lighthouse concern:** Improves CLS and LCP; high value
- **Recommendation:** v0.3.0+ after AVIF decision. Can ship together.

#### **11. Multi-Author Bylines** (Stack: ✓, PaperMod: ✓, tsuki: ✗)
- **Impact:** Team blogs; collaborative writing
- **Current tsuki:** Single global author; JSON-LD author is hardcoded
- **Effort:** M (per-post `authors: []` frontmatter + template logic)
- **Bundle cost:** 0 (markup only)
- **Why missing:** Solo-blogger focus; low demand signal
- **Recommendation:** v0.4.0+ if audience demand justifies scope expansion.

#### **12. Custom Shortcodes** (Stack: ✓, PaperMod: ✗, tsuki: ✗)
- **Stack includes:** gallery, video, tabs, columns, figures, admonitions
- **tsuki includes:** None; callouts via native markdown only
- **Effort:** M-L (per shortcode: 20–50 lines template + CSS)
- **Bundle cost:** Varies; 1 shortcode ~100 B CSS
- **Why missing:** Keep core lean; users can add via site overrides
- **Recommendation:** v0.4.0+ document shortcode patterns in customization.md; ship 1–2 examples (gallery, tabs).

---

### Tier C: Out-of-Scope by Design

#### **13. Series / Subsection Routing** (Stack: ✓, tsuki: ✗)
- **Impact:** Multi-part tutorials, book-like structure
- **Effort:** L (Hugo section routing + archetype changes)
- **Why missing:** Adds taxonomy complexity; blog posts are flat
- **Recommendation:** Out-of-scope. Stack's subsection support is edge-case; most blogs use tags instead.

#### **14. KaTeX / Mermaid Shortcodes** (Stack: ✓, tsuki: ✗)
- **Impact:** Math equations, diagrams
- **Stack:** Built-in Mermaid, optional KaTeX
- **tsuki v0.2.0 CHANGELOG:** "Deferred to post-0.1.0" — deliberate design choice
- **Bundle cost:** Mermaid = 50+ KB gz; KaTeX = 40+ KB gz — incompatible with ≤4 KB CSS budget
- **Recommendation:** **Intentional defer.** Document override path: users can add via Hugo Modules or site-level content adapters. Do not ship in core.

#### **15. Email Newsletter Signup** (Stack: ✗, PaperMod: ✗, tsuki: ✗)
- **Impact:** Audience capture; monetization
- **Effort:** M (form partial + privacy compliance)
- **Why missing:** Not a theme responsibility; requires external service (ConvertKit, Substack, etc.)
- **Recommendation:** Out-of-scope. Document as customization example in docs/customization.md.

#### **16. Disqus / Utterances Comments** (Stack: ✓, PaperMod: ✓, tsuki: ✗)
- **Impact:** Alternative comment systems for non-GitHub audiences
- **Current tsuki:** Giscus only (GitHub Discussions)
- **Effort:** M (1 partial per provider; ~30 lines each)
- **Bundle cost:** 0 (embed-only)
- **Why missing:** Giscus is modern default; Disqus declining (privacy concerns); Utterances niche
- **Recommendation:** v0.4.0+ if user demand. Document override path now (copy `_partials/comments.html`, swap Giscus for custom provider).

---

## 2026 Blog+Portfolio Feature Baseline

Based on industry survey (Stack, PaperMod, Anatole, Hello Friend NG), **must-have** features for credible blog+portfolio themes:

| Feature | Must-Have | Nice-to-Have | Rationale |
|---------|-----------|--------------|-----------|
| Blog (posts + archive) | ✓ | — | Table stakes |
| Tags/categories | ✓ | — | Discovery |
| Full-text search | ✓ | — | UX expectation |
| Dark mode | ✓ | — | 2026 standard |
| TOC (auto) | ✓ | — | Long-form reading |
| Portfolio/projects grid | ✓ | — | Personal brand |
| Comments (any) | ✓ | — | Engagement |
| SEO metadata (OG, schema) | ✓ | — | Distribution |
| Mobile responsive | ✓ | — | Baseline |
| Code syntax highlighting | ✓ | — | Dev blogs |
| Related posts | ✓ | — | Engagement |
| Social icons | ✓ | — | Personal brand |
| Responsive images | ✓ | — | Lighthouse |
| **Prev/next nav** | — | ✓ | Post flow (common) |
| **Breadcrumbs** | — | ✓ | UX clarity (common) |
| **Code copy button** | — | ✓ | UX polish (emerging) |
| Image gallery/lightbox | — | ✓ | Niche (photographers) |
| RTL support | — | ✓ | Localization (niche) |
| Multi-author | — | ✓ | Teams only |
| Newsletter signup | — | ✓ | Monetization (opt-in) |
| KaTeX/Mermaid | — | ✓ | Niche (technical) |

**tsuki baseline alignment:** ✓ All must-haves shipped through v0.2.1. No critical gaps.

---

## Lighthouse Implications

### Negative Impact Risk (Missing Features That Reduce Scores If Implemented Poorly)

| Feature | Lighthouse Metric | Risk | Mitigation |
|---------|-------------------|------|-----------|
| **Image gallery** | CLS, LCP | Unoptimized thumbs cause layout shift | Lazy-load + fixed aspect ratio |
| **Custom shortcodes** | CSS weight | Feature creep → bundle bloat | Strict budget enforcement (Phase 2) |
| **Prev/next nav** | — | None (markup-only) | Safe to ship |
| **Code copy button** | INP | JS click handler bloat | Use IntersectionObserver; defer hydration |
| **Newsletter form** | CLS | Embed framework weight | Use vanilla JS only; validate bundle impact |

**Recommendation:** Any feature added post-v0.3.0 must pass smoke-test: CSS ≤4 KB gz per page kind, JS ≤1 KB gz aggregate.

---

## Recommendations Ranked by Priority

### Must-Ship v0.3.0 (P1)

1. **Language switcher + en.yml complete** — Phase 3 author UX + Phase 4 audit
2. **llm.txt generation** — Phase 5 (already planned)
3. **Breadcrumbs (optional, gated)** — Phase 3 author UX
4. **Code copy button (optional, gated)** — Phase 3 author UX

### Consider v0.3.0 (P2, if budget allows)

1. **Prev/next post nav** — Zero-friction addition; improves discoverability
2. **AVIF render hook + docs** — If cover-image feature confirmed in scope
3. **Speculation Rules prefetch** — Already planned in Phase 5

### Defer to v0.4.0 (P3)

1. Image gallery / lightbox (bundle implications)
2. Image zoom on hover
3. Scroll-to-top button
4. Custom shortcodes (tabs, columns, video)
5. RTL support (audience expansion decision)
6. Multi-author bylines
7. Alternative comment systems (Disqus, Utterances)

### Out-of-Scope (By Design)

1. Series/subsection routing (low ROI)
2. KaTeX/Mermaid (intentional defer; users add via modules)
3. Email newsletter (out-of-theme responsibility)

---

## Feature Parity Summary

**tsuki v0.2.1 achieves parity with Stack/PaperMod on:**
- Blog infrastructure (posts, tags, archives, search, related posts)
- Portfolio surface (projects grid, social links, profile)
- SEO (JSON-LD, OG, Twitter cards)
- Comments (Giscus)
- i18n (vi + en; missing UI switcher and RTL, but core infrastructure ready)
- Performance (responsive images, lazy-load, View Transitions API — exceeds Stack on API adoption)
- Customization (CSS tokens, icon overrides, partial override paths)

**tsuki distinguishes itself on:**
- **Zero build step** — pure Hugo + browser ES modules (matches PaperMod philosophy; exceeds Stack complexity)
- **Pagefind search** (superior Vietnamese diacritic handling vs. Fuse.js)
- **View Transitions API** (unique among blog themes; forward-compatible)
- **CSS budget discipline** — 4 KB gz hard limit (competitors don't enforce; tsuki does)
- **Vietnamese typography** — purpose-built for diacritics + tone marks

**tsuki lags on:**
- Breadcrumbs, prev/next nav (low-effort, ship v0.3.0+)
- Code copy button (low-effort, ship v0.3.0+)
- Image gallery shortcode (niche; defer indefinitely without demand)
- RTL support (audience expansion question)
- Shortcode ecosystem (intentional; users override)

---

## Implementation Path: v0.3.0 + v0.4.0

### v0.3.0 (Committed)
- Phase 3 (Author UX): Breadcrumbs, code copy, prev/next nav as optional `params.*` flags
- Phase 3: en.yml completion + language switcher partial (if routing logic complete)
- Phase 5 (AI/discovery): llm.txt generation
- Phase 4 (a11y): WCAG 2.2 audit (no new features, but validates surface)
- Phase 2 (Budget rebase): Free ~1.2 KB gz headroom for above features

### v0.4.0 (Consider)
- AVIF render hook + responsive srcsets (post-cover-image scope decision)
- Image gallery shortcode (proof-of-concept, lightweight alternative to PhotoSwipe)
- Basic custom shortcodes (tabs, figures; <200 B CSS each)
- RTL support toggle (if multi-language demand justifies)
- Scroll-to-top button
- Alternative comment system overrides (Disqus, Utterances examples)

---

## Unresolved Questions

1. **Cover-image feature scope for v0.2.0–v0.3.0:** Does tsuki ship cover image processing (Hugo pipes + AVIF) in v0.3.0, or defer indefinitely? Drives AVIF render hook timing.
   - *Impact:* If deferred, AVIF slides to v0.4.0+; if confirmed, can ship in v0.3.0 Phase 2.

2. **Language switcher routing:** Can en.yml phase complete without language switcher UI, or is switcher a blocker?
   - *Impact:* Affects Phase 3 effort estimate; if blocked on Phase 4 a11y, may slip to v0.4.0.

3. **Breadcrumbs schema inclusion:** Should breadcrumb partial auto-emit BreadcrumbList schema.org JSON-LD, or markup-only?
   - *Impact:* If schema required, add ~30 lines template logic; if markup-only, trivial.

4. **Code copy button accessibility:** Should copy button hide when `navigator.clipboard` unavailable (HTTP), or always show with fallback UI feedback?
   - *Impact:* If fallback, adds ~50 B js error-handling logic; if hide, simpler.

5. **Stack/PaperMod future drift:** Are Stack v4.0+ or PaperMod planning major features (e.g., AI chat, embedded analytics) that justify expanded tsuki roadmap?
   - *Impact:* May inform whether tsuki should pursue shortcode ecosystem or stay lean.

---

## Sources

- [tsuki README & CHANGELOG](https://github.com/tiennm99/tsuki/)
- [tsuki v0.3.0 Plan](https://github.com/tiennm99/tsuki/plans/260510-0144-tsuki-v0.3.0/)
- [Prior research: Hugo Theme Evolution 2026](https://github.com/tiennm99/tsuki/plans/reports/researcher-260510-0144-hugo-theme-2026-evolution.md)
- [Hugo Theme Stack GitHub](https://github.com/CaiJimmy/hugo-theme-stack)
- [Hugo PaperMod Wiki Features](https://github.com/adityatelange/hugo-PaperMod/wiki/Features)
- [Anatole Theme](https://github.com/lxndrblz/anatole)
- [Hello Friend NG GitHub](https://github.com/rhazdon/hugo-theme-hello-friend-ng)
- [WCAG 2.2 Standard](https://www.w3.org/TR/WCAG22/)
- [Pagefind Search Docs](https://pagefind.app)
- [Hugo Render Hooks](https://gohugo.io/render-hooks/images/)

---

**Status:** DONE  
**Summary:** tsuki v0.2.1 achieves feature parity with Stack/PaperMod on all essential blog+portfolio dimensions. Missing features split into three tiers: A (nice-to-have, v0.3.0 ready), B (medium effort, v0.4.0+), C (out-of-scope by design). No critical gaps exist. v0.3.0 scope should prioritize breadcrumbs, code copy, prev/next nav, language switcher, and llm.txt — all low-effort additions that respect the ≤4 KB CSS budget. Image gallery, RTL, and shortcodes defer to v0.4.0 or remain intentionally out-of-scope per tsuki's lightweight philosophy.
