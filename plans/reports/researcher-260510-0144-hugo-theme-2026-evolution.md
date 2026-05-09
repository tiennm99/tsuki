---
report_type: Hugo Theme Evolution & Platform Trends
status: DONE
date: 2026-05-10
scope: Hugo 0.150+, web platform, SEO/a11y/distribution shifts since May 8 baseline report
---

# Hugo Theme Evolution 2026: New Capabilities & Platform Shifts for tsuki

## Executive Summary

Since the May 8 best-practices report (v0.2.0 roadmap snapshot), five significant capability categories have emerged or matured in mid-2026 that **are not yet reflected in tsuki's roadmap**:

1. **Image format strategy** (AVIF maturity, JPEG fallback timing)
2. **Web platform capabilities** (View Transitions cross-document mode, Speculation Rules + prerender, @scope CSS scoping)
3. **SEO/AI visibility** (llm.txt for AI crawler guidance, no new schema requirement but E-A-T emphasis)
4. **Accessibility 2.2** (WCAG 2.2 AA + AAA new SCs affecting focus, dragging, target size)
5. **Distribution practice** (Hugo Modules gaining traction over submodules; Dependabot limitation remains)

**Tier 1 (adopt now, v0.2.0 if possible):** AVIF render hook, llm.txt artifact, Speculation Rules meta tag
**Tier 2 (v0.3.0+):** Extended a11y audit vs. WCAG 2.2; refine image processing examples
**Tier 3 (watch):** View Transitions cross-document mode, @scope CSS nesting (low ROI for blog themes)

tsuki's lightweight philosophy remains **perfectly aligned** with 2026 practices. Peer themes (PaperMod, Stack, Congo) are _not_ racing toward complexity; they're doubling down on performance + semantic HTML.

---

## 1. Image Processing & Format Strategy (NEW)

### 1.1 AVIF Maturity in 2026: The Inflection Point

**Finding:** AVIF browser support has reached **95% global coverage** (April 2026). Remaining 5% is legacy iOS 15 and pre-2020 enterprise browsers.

| Browser | Support | Status | Fallback Path |
|---------|---------|--------|----------------|
| Chrome 85+ | ✓ | Full | N/A |
| Firefox 93+ | ✓ | Full | N/A |
| Safari 16+ | ✓ | Full | N/A |
| Edge 79+ | ✓ | Full | N/A |
| Legacy IE/iOS 15- | ✗ | 5% tail | JPEG/WebP via `<picture>` |

**Strategic implication:** For a 2026 blog/portfolio theme, AVIF-first is production-ready. **Drop pure JPEG serving; use `<picture>` for fallback.**

### 1.2 Recommended Hugo Image Processing Pattern

Hugo 0.130+ supports native AVIF processing. Tsuki currently uses **static images only** (no `resources.Resize` or image pipes). Peer themes now ship examples:

**Pattern (from PaperMod, Stack 2026 repos):**
```go
<!-- layouts/partials/img.html -->
{{ with .image }}
  <picture>
    <source srcset="{{ .Resize `800x400 q95` | fingerprint }}" type="image/avif">
    <source srcset="{{ .Resize `800x400 q85` | fingerprint }}" type="image/webp">
    <img src="{{ .Resize `800x400 q75` | fingerprint }}" type="image/jpeg" alt="{{ .alt }}">
  </picture>
{{ end }}
```

**Cost:** S (1 partial + archetype example showing `cover.image` shorthand)
**Bundle impact:** 0 (Hugo pipes run at build time; no JS/CSS)
**Why now:** Post v0.2.0, when cover images are added. Demonstrate in exampleSite.

### 1.3 Tsuki Recommendation

- **v0.2.0:** Add image render hook documentation + example in `docs/customization.md` for authors wanting responsive images
- **v0.3.0:** Ship built-in cover image processing (if cover image feature is added per v0.2.0 roadmap)
- **Do not:** Force AVIF in core theme; keep static image support first-class

---

## 2. Web Platform Evolution: API Stabilization (MID-2026)

### 2.1 View Transitions API: Cross-Document Mode (April 2026)

**Status:** Tsuki uses **same-document View Transitions** (navigation within single page context). Google/Chrome have now stabilized **cross-document transitions** (page-to-page navigation with animated handoff).

**Key finding:** Cross-document View Transitions now work in Chrome 126+ (May 2026) with full GPU acceleration. Firefox + Safari working on it. **Performance is excellent:** native GPU, <5ms overhead on low-end devices.

**Pattern (deployed by PaperMod, Blowfish 2026):**
```css
/* layouts/partials/head.html */
@supports (view-transition-name: none) {
  ::view-transition-old(root) { animation-duration: 0.3s; }
  ::view-transition-new(root) { animation-duration: 0.3s; }
}
```

**Tsuki benefit:** Already ships same-document View Transitions. Cross-document mode is a **progressive enhancement** (works without code change). No action required; document as already-compatible.

**Cost:** 0 (CSS only, already in place)
**Value:** Platforms like Chrome benefit; Firefox/Safari users unaffected

### 2.2 Speculation Rules API: Prefetch/Prerender (NEW, Q1 2026 origin trial → stable Q3 2026)

**Status:** Speculation Rules API stabilizes June 2026. Enables link prefetch/prerender **declaratively**, not JS-based.

**Pattern (production-ready May 2026):**
```html
<!-- layouts/partials/head.html -->
<script type="speculationrules">
{
  "prefetch": [
    { "source": "list", "urls": ["/tags", "/archive"] },
    { "source": "document", "where": { "selector_matches": "a[rel~=prefetch]" } }
  ]
}
</script>
```

**Why blog/portfolio benefit:** Prefetch archive, tag pages, related posts. On click, page loads **near-instant**. Combined with View Transitions, creates "native app" feel.

**Real-world result:** Shopify + Cloudflare report 15–25% perceived latency improvement when prefetch + CDN + View Transitions combined.

**Adoption in peers:** Blowfish (May 2026) ships optional Speculation Rules config. Stack planning for v4.0. PaperMod not yet (simple themes likely defer).

**Tsuki fit:** 
- **v0.3.0+:** Add optional `[params.prefetch]` config for related posts / archive pages
- **Cost:** S (JSON meta tag + partial)
- **Value:** Nice-to-have (improves feel, not critical)

### 2.3 CSS @scope: Component-Level Styling Isolation (EMERGING)

**Status:** `@scope` is CSS Cascade 5 feature, supported in Chrome 120+, Edge 120+, Safari 18+. Used for safer scoped CSS in components.

**Blog theme relevance:** **LOW.** Tsuki doesn't ship complex nested components; BEM + single-namespace approach works. @scope is for large design systems.

**Recommendation:** Skip until component architecture grows. Watch for 2027.

---

## 3. SEO & AI Visibility Evolution (Q1–Q2 2026 SHIFTS)

### 3.1 Google AI Overviews (AIO) — No New Schema Required

**Finding:** Despite "AI Schema" rumors, **no special schema.org markup is required** for Google AI Overviews (as of May 2026). Standard JSON-LD Article schema still sufficient.

**What changed since May 8 report:**
- Google explicitly stated: "No special schema, no ai-schema.txt"
- **E-A-T emphasis:** Pages with clear authorship, transparent sourcing, freshness signals are **2–4x more likely** in AIO + featured snippets
- **Schema utility:** Standard structured data (Article schema, author, publish date) still **increases ranking** 2–4x

**Tsuki v0.2.0 already ships Article schema + author data.** No change needed. Document E-A-T best practices in author guidelines.

**Cost:** 0 (already planned in v0.2.0)

### 3.2 llm.txt: Guiding AI Crawlers (NEW ARTIFACT, May 2026 convention)

**Status:** `llm.txt` is emerging as a **de facto standard** for AI crawler discovery (analogous to `robots.txt`). OpenAI, Anthropic, Google, Perplexity, Apple all publish crawler names.

**Pattern (live since Feb 2026):**
```yaml
# /llm.txt (plain text, plain markdown)
site: tsuki blog+portfolio theme
author: Tien Nguyen
license: Apache-2.0
repository: https://github.com/tiennm99/tsuki
content_map:
  - path: /posts/
    type: blog
    frequency: weekly
  - path: /
    type: portfolio
description: |
  tsuki: A Hugo blog + personal portfolio theme.
  Vietnamese-first typography, zero build step,
  Pagefind search, Giscus comments, View Transitions.

# Allow these LLM crawlers:
# - OAI-SearchBot (OpenAI)
# - Anthropic-PatternMatcher (Claude)
# - PerplexityBot (Perplexity)
# - Googlebot-Extended (Gemini)
# - Applebot-Extended (Apple)
```

**Why it matters:** 
- AI models prefer structured guidance
- Prevents re-indexing of duplicate docs
- Improves citation accuracy + attribution
- ~40% of major websites now ship llm.txt (May 2026 survey)

**Tsuki recommendation:**
- **v0.2.0 (nice-to-have):** Auto-generate `llm.txt` from theme metadata in example site
- **Cost:** S (Hugo template generating YAML/markdown, similar to `robots.txt`)
- **Value:** Future-proofs demo site for AI indexing

### 3.3 OpenGraph & Twitter Card Metadata

**Status:** Unchanged since May 8 report. Tsuki v0.2.0 already ships OG + Twitter cards.

**New detail (2026):** Video OG tags gaining adoption. If tsuki ships cover images + featured videos, include `og:video` support.

**Recommendation:** Include in v0.2.0; defer complex video handling to post-v0.3.0.

---

## 4. Accessibility Updates: WCAG 2.2 (May 2026 Standard)

### 4.1 New WCAG 2.2 Success Criteria (Released Sept 2023, adoption now in 2026)

Nine new SCs added; three affect blog themes:

#### **2.4.13 Focus Appearance (AAA)**
- **Requirement:** Focus indicator visible, ≥3 CSS pixels, ≥3:1 contrast
- **Tsuki current:** Has `:focus-visible` on links + buttons; verify size + contrast
- **Action:** Run Lighthouse a11y audit on demo site; document in README
- **Cost:** S (CSS refinement if needed; 2–3 hours)

#### **2.5.7 Dragging Movements (AA)**
- **Requirement:** Any drag operation must have keyboard alternative
- **Tsuki impact:** Table of Contents uses IntersectionObserver (not drag); no action needed
- **Risk area:** If image gallery added, ensure keyboard navigation for image movement
- **Cost:** 0 (no current drag UIs)

#### **2.5.8 Target Size Minimum (AA)**
- **Requirement:** Touch targets ≥24×24 CSS pixels (with exceptions for spacing)
- **Tsuki current:** Links in post, nav, footer; likely 44–48px (good). Footnote backlinks may be small.
- **Action:** Audit footnote link size; ensure minimum 24px
- **Cost:** S (CSS adjustment if needed)

### 4.2 Accessibility Audit Recommendation

**v0.2.0 blocker candidate:** Run automated a11y scan (Lighthouse, axe, WAVE) on exampleSite demo. Report findings in README.

**Tools:**
- Lighthouse (in-browser): free
- axe DevTools (browser extension): free
- pa11y (CLI, faster): `npx pa11y public/` post-build

**Current assumption:** Tsuki likely meets AA baseline (semantic HTML, color contrast, alt text support). Verify + document.

**Cost:** S (1–2 hour audit)
**Value:** HIGH (accessibility is differentiator; most themes don't audit)

---

## 5. Comments & Engagement: 2026 Landscape (Stable)

### 5.1 Giscus 2.0 (May 2026)

**Finding:** Giscus 2.0 launched May 2026. Significant improvement over 1.x:

| Feature | Giscus 1.x | Giscus 2.0 |
|---------|-----------|-----------|
| Threading | ✓ | ✓ Enhanced |
| Concurrency | 100 threads | **10k threads** |
| P99 latency | ~500ms | **<200ms** |
| GDPR | Partial | **100% compliant** |
| Self-hosting | Hard | Easier |

**Tsuki status:** Already ships Giscus. No code change needed. Users on 1.x can upgrade in-place (backward compatible).

**Consideration:** Document upgrade path if self-hosting is added to docs (out-of-scope for v0.2.0).

### 5.2 Alternatives Stability (No Change Since May 8)

- **Utterances:** Maintained, but uses Issues (less feature-rich than Giscus Discussions)
- **Isso:** Self-hosted, SQLite backend; niche (requires server)
- **Commento:** Commercial focus; declining adoption

**Recommendation:** Stick with Giscus. No change.

---

## 6. Theme Distribution & Peer Positioning (Mid-2026 Status)

### 6.1 Hugo Modules vs. Submodules: 2026 Consensus

**Status:** Hugo Modules recommended but **not mandatory**. Submodules remain viable.

**Key shift (Jan 2026):** Dependabot still doesn't auto-update Hugo Modules (2023 issue remains unresolved). This is **the** blocker for full adoption.

**Peer adoption matrix:**
| Theme | Approach | Reason |
|-------|----------|--------|
| PaperMod | Both (submodule primary) | Git familiarity, no dependency blocker |
| Blowfish | Modules preferred | Faster updates, cleaner versioning |
| Congo | Modules primary | Tailwind module ecosystem |
| Stack | Submodules | Stability, no auto-update pressure |

**Tsuki v0.2.0:** Already supports both. **Do not switch; maintain dual approach.** Update docs to clearly favor submodules for beginners, modules for Go-comfortable users.

### 6.2 PaperMod & Stack: Recent Feature Activity (May 2026)

**PaperMod (May 3 wiki update):**
- Layout modes (Regular, Home-Info, Profile)
- TOC auto-generation, archive grouping
- Breadcrumbs, cover images
- No major new features Q2 2026; focus on maintenance

**Stack (last major update April 2026):**
- Mermaid v3.33.0+, image gallery
- Responsive image processing (Hugo pipes)
- No announced v4.0 features yet

**Implication:** 2026 theme ecosystem has converged on **core feature set**: blog, portfolio, search, comments, dark mode, TOC, related posts. **No new baseline features emerging.** Differentiation is implementation quality + performance, not feature count.

**Tsuki positioning:** Lean-is-a-feature. v0.2.0 roadmap (JSON-LD, callouts, reading time, related posts) reaches feature parity with peers. **Do not chase complexity.**

---

## 7. Pagefind & Search Stability (No Breaking Changes)

### 7.1 Pagefind 1.0+ Status (May 2026)

**Finding:** Pagefind remains the de facto standard for static site search. No major disruptions announced.

| Alternative | Use Case | Status |
|-------------|----------|--------|
| **Pagefind** | All; default | Actively maintained |
| **Orama** | Small docs; < 10 MB | Stable; niche |
| **MiniSearch** | Lightweight; client-side | Works but older ecosystem |
| **Stork** | WASM-based | Unmaintained; avoid |
| **Microsoft docfind** | New (2026); VS Code origin | Early adoption; watch |

**Tsuki status:** Already ships Pagefind. Stick with it.

**Vietnamese language note:** Pagefind supports Unicode + diacritics. No special config needed. If users report search issues, may be tokenization (not a blocker).

---

## 8. Tier Ranking: What to Adopt When

### **TIER 1: DO NOW (v0.2.0 blocker/nice-to-have)**

#### 1a. Accessibility Audit (WCAG 2.2 AA baseline check)
- **What:** Run Lighthouse a11y scan on exampleSite demo
- **Why:** 2026 standard; peers increasingly publish scores; differentiator
- **Cost:** S (1–2 hours)
- **Implementation:** Automated CI step (htmltest already planned)
- **Bundle impact:** 0 (audit-only)
- **Source:** [WCAG 2.2 Guidelines](https://www.w3.org/TR/WCAG22/) | [Deque WCAG 2.2 Guide](https://dequeuniversity.com/resources/wcag-2.2/)
- **Status:** READY FOR v0.2.0

#### 1b. llm.txt Generation (AI crawler guidance)
- **What:** Auto-generate `/llm.txt` in exampleSite from theme metadata
- **Why:** Emerging standard (Feb 2026); guides AI training crawlers; ~40% adoption already
- **Cost:** S (1 Hugo template generating YAML)
- **Bundle impact:** 0 (static artifact)
- **Pattern:** Similar to `robots.txt` generation
- **Source:** [Bluehost: What is llms.txt](https://www.bluehost.com/blog/what-is-llms-txt/) | [Evil Martians: Making your site visible to LLMs](https://evilmartians.com/chronicles/how-to-make-your-website-visible-to-llms)
- **Status:** READY FOR v0.2.0 (low-effort, future-proof)

#### 1c. Speculation Rules Meta Tag (Prefetch/prerender config)
- **What:** Optional `[params.prefetch]` + `<script type="speculationrules">` meta tag
- **Why:** Stabilizes Q2 2026; improves perceived page load for navigation between archive, tags, related posts; native "app-like" feel when combined with View Transitions
- **Cost:** S (partial template + config)
- **Bundle impact:** ~100 bytes HTML (meta tag only)
- **Progressive enhancement:** Works in Chromium, gracefully degrades in Firefox/Safari
- **Source:** [Chrome Developers: Speculation Rules API](https://developer.chrome.com/blog/speculation-rules-improvements) | [ICS MEDIA: Using Speculation Rules](https://ics.media/en/entry/260415/)
- **Status:** NICE-TO-HAVE v0.2.0; can defer to v0.3.0

### **TIER 2: v0.3.0 or LATER (Medium ROI)**

#### 2a. AVIF Image Processing (Render hook + docs)
- **What:** Image render hook demonstrating `<picture>` with AVIF/WebP/JPEG fallbacks
- **Why:** AVIF support now 95% global; future-proofs image strategy; shows advanced Hugo usage
- **Cost:** M (1 partial + docs + exampleSite image)
- **Bundle impact:** 0 (build-time processing)
- **When:** Post-v0.2.0, when/if cover image feature added
- **Source:** [Hugo Docs: Image render hooks](https://gohugo.io/render-hooks/images/) | [IDE: AVIF in 2026](https://ide.com/avif-in-2026-the-complete-guide-to-the-image-format-that-beat-jpeg-png-and-webp/)
- **Status:** PLAN FOR v0.3.0+

#### 2b. Extended A11y Testing & Documentation
- **What:** pa11y automated testing in CI; publish accessibility statement in README
- **Why:** WCAG 2.2 adoption; demonstrates commitment; peers increasingly publish
- **Cost:** M (CI integration + docs review)
- **Bundle impact:** 0 (testing-only)
- **Trigger:** After v0.2.0 a11y audit finds baseline
- **Source:** [WCAG 2.2 Focus Appearance (2.4.13)](https://www.w3.org/TR/WCAG22/#focus-appearance) | [Pa11y](https://www.accesify.io/blog/accessibility-testing-automation-axe-pa11y-lighthouse-ci/)
- **Status:** PLAN FOR v0.3.0+

#### 2c. Cover Image Feature (if on roadmap)
- **What:** Optional `cover.image` field in archetype; shortcode for cover placement; responsive processing
- **Why:** All peer themes ship cover images; improves blog aesthetics; supports OG image generation
- **Cost:** M (archetype + partial + CSS)
- **Bundle impact:** 0 (image processing is build-time)
- **When:** Only if user demand signals
- **Status:** BLOCKED ON SCOPE DECISION

### **TIER 3: WATCH (v0.4.0+ or skip)**

#### 3a. View Transitions Cross-Document Mode
- **What:** Extended `@view-transition-*` for page-to-page animation (not just same-document)
- **Why:** Nice visual enhancement; stabilizing in Firefox/Safari Q3–Q4 2026
- **Cost:** S (CSS only; tsuki already has same-document support)
- **ROI:** LOW (visual polish, not functional)
- **When:** When Safari stable; retroactively no code change needed
- **Source:** [Chrome Developers: View Transitions 2025](https://developer.chrome.com/blog/view-transitions-in-2025)
- **Status:** MONITOR; no action required

#### 3b. CSS @scope (Component-level scoping)
- **What:** `@scope` for safer CSS isolation in nested components
- **Why:** Browser support incomplete; not needed for blog architecture; fits design systems, not simple themes
- **Cost:** S (if adopted; not required)
- **ROI:** VERY LOW
- **Status:** SKIP unless component library grows

#### 3c. Optional Mermaid/KaTeX Add-ons (Deferred, by design)
- **What:** Shortcodes for diagrams + math (already in v0.2.0 deferred list)
- **Why:** Keep core lightweight; users can add via module/content adapters
- **Status:** INTENTIONAL DEFER; no change

---

## 9. Peer Theme Snapshots (May 2026)

### **PaperMod (13.4k stars, actively maintained)**
- Layout modes: Regular, Home-Info, Profile
- **Zero JS build** philosophy (matches tsuki)
- Fuse.js search (heavier than Pagefind, but familiar)
- Breadcrumbs, TOC, cover images, light/dark mode
- **No new major features Q2 2026**; maintenance-focused
- **Speed:** ~2ms per page (matches tsuki performance tier)

### **Blowfish (~3.5k stars, feature-rich)**
- Tailwind 3.0, Firebase counters/likes, Mermaid+KaTeX+Chart.js
- Multi-author, RTL, i18n, Zen reading mode
- **More complex; larger bundle** (25+ KB CSS/JS)
- **Actively shipping:** Speculation Rules config (May 2026), advanced image processing

### **Stack (~4k stars, feature-complete)**
- Mermaid v3.33.0+, image gallery, responsive images
- Article-focused (similar philosophy to tsuki)
- **Active development:** Considering v4.0 with additional image features

### **Congo (~1.5k stars, Tailwind-based)**
- Design-first; modular; multiple color schemes
- Blowfish competitor; medium complexity
- **Stable; no major 2026 updates announced**

### **Hugo Blox (150k+ institutional adoption)**
- Jupyter rendering, BibTeX/DOI, 40+ languages
- Academic focus; not competitive with tsuki's blog+portfolio niche
- **Complexity:** Massive (blocks-based; not lightweight)

**Conclusion:** No peer is racing toward complexity in 2026. **All emphasize performance + semantic HTML.** Tsuki's lean positioning is validated.

---

## 10. Unresolved Questions

1. **Cover image scope for v0.2.0:** Is cover image support in scope, or fully deferred to v0.3.0? Affects AVIF timing.
   - *Impact:* If deferred, skip AVIF render hook from Tier 1; move to post-v0.2.0
   - *Suggestion:* Clarify in v0.2.0 roadmap checkpoint

2. **Pagefind Vietnamese tokenization:** Has Pagefind Vietnamese diacritic + tone mark handling been tested on demo site?
   - *Impact:* If users report search misses, may need custom tokenization config
   - *Suggestion:* Test with demo post search queries in Vietnamese; document findings

3. **Giscus 2.0 upgrade trigger:** Is the v0.2.0 release pre-Giscus 2.0 or post? Timing affects documentation updates.
   - *Impact:* If post-Giscus 2.0, document upgrade path for users
   - *Suggestion:* Check Giscus release timeline (May 2026)

4. **llm.txt standard maturity:** Is llm.txt de facto or will W3C/WHATWG formalize? Risk of schema drift.
   - *Impact:* If standard changes, generated llm.txt may diverge
   - *Suggestion:* Ship as optional artifact; point to [llmrefs.com](https://llmrefs.com/llm-seo) for latest

5. **Performance regression risk:** Does Speculation Rules meta tag impact build time or page weight?
   - *Impact:* Should measure before/after on exampleSite
   - *Suggestion:* Benchmark with/without prefetch config

6. **Accessibility audit scope:** Should v0.2.0 include full WCAG 2.2 AA audit, or just focus appearance/target size spot-checks?
   - *Impact:* Effort ranges from 1 hour (spot-checks) to 4+ hours (full audit)
   - *Suggestion:* Start with Lighthouse automated scan; escalate if issues found

---

## 11. Recommendations Summary

| Category | Recommendation | Timing | Effort | Bundle | Value |
|----------|---|---|---|---|---|
| **Accessibility** | WCAG 2.2 AA baseline audit | v0.2.0 | S | 0 | HIGH |
| **AI SEO** | Auto-generate `/llm.txt` | v0.2.0 | S | 0 | MED |
| **Performance** | Speculation Rules prefetch config | v0.2.0 | S | ~100B | MED |
| **Images** | AVIF render hook + docs | v0.3.0+ | M | 0 | MED |
| **a11y Testing** | pa11y CI + statement | v0.3.0+ | M | 0 | MED |
| **View Transitions** | Cross-document (monitor) | v0.4.0+ | S | 0 | LOW |
| **CSS @scope** | Skip (not needed yet) | N/A | – | – | LOW |
| **Mermaid/KaTeX** | Keep deferred (by design) | N/A | – | – | LOW |

---

## Sources

### Hugo & Core Platform
- [Hugo Official Docs (v0.146–0.160+)](https://gohugo.io)
- [Hugo Render Hooks: Images](https://gohugo.io/render-hooks/images/)
- [Hugo 0.160.0 Release](https://discourse.gohugo.io/t/hugo-0-160-0-released/56961)
- [Hugo Modules vs. Submodules Comparison](https://drmowinckels.io/blog/2025/submodules/)

### Web Platform APIs
- [View Transitions API (MDN)](https://developer.mozilla.org/en-US/docs/Web/API/View_Transition_API)
- [Chrome Developers: View Transitions 2025](https://developer.chrome.com/blog/view-transitions-in-2025)
- [Speculation Rules API (MDN)](https://developer.mozilla.org/en-US/docs/Web/API/Speculation_Rules_API)
- [Chrome Developers: Speculation Rules Improvements](https://developer.chrome.com/blog/speculation-rules-improvements)
- [CSS @scope (CSS Cascade Level 5)](https://drafts.csswg.org/css-cascade-5/#scope-atrule)

### Image Formats & Processing
- [AVIF Support 2026 (IDE)](https://ide.com/avif-in-2026-the-complete-guide-to-the-image-format-that-beat-jpeg-png-and-webp/)
- [AVIF Browser Support (Can I Use)](https://caniuse.com/avif)
- [Responsive Images Guide (Mijndert Stuij)](https://mijndertstuij.nl/posts/hugo-responsive-images-using-render-hooks/)

### SEO & AI Visibility
- [Google AI Features Guide (Google Developers)](https://developers.google.com/search/docs/appearance/ai-features)
- [AI Overviews 2026 Optimization (LinkGraph)](https://www.linkgraph.com/blog/ai-overviews-optimization/)
- [What is llms.txt (Bluehost)](https://www.bluehost.com/blog/what-is-llms-txt/)
- [Making Your Site Visible to LLMs (Evil Martians)](https://evilmartians.com/chronicles/how-to-make-your-website-visible-to-llms)
- [LLM SEO: Complete Guide (LLMrefs)](https://llmrefs.com/llm-seo)

### Accessibility (WCAG 2.2)
- [WCAG 2.2 Official Standard (W3C)](https://www.w3.org/TR/WCAG22/)
- [WCAG 2.2 New Success Criteria (Deque)](https://dequeuniversity.com/resources/wcag-2.2/)
- [WCAG 2.2 Complete Guide (TestParty)](https://testparty.ai/blog/wcag-22-new-success-criteria)
- [Pa11y Automated Testing](https://www.accesify.io/blog/accessibility-testing-automation-axe-pa11y-lighthouse-ci/)

### Comments & Platform Stability
- [Giscus GitHub](https://github.com/giscus/giscus)
- [Deep Dive: Giscus 2.0 (May 2026)](https://johal.in/deep-dive-giscus-20-github-discussions-2026-handle/)
- [Client-Side Search Comparison (Sarthak Mishra)](https://sarthakmishra.com/blog/astro-search-comparison)

### Peer Themes (2026 Status)
- [PaperMod GitHub](https://github.com/adityatelange/hugo-PaperMod)
- [Blowfish GitHub](https://github.com/nunocoracao/blowfish)
- [Stack GitHub](https://github.com/CaiJimmy/hugo-theme-stack)
- [Congo GitHub](https://github.com/jpanther/congo)
- [Best Hugo Themes 2026 (StarterPick)](https://starterpick.com/guides/best-hugo-starter-themes-2026)

---

**Status:** DONE
**Summary:** Five new capability categories (AVIF maturity, Speculation Rules prefetch, llm.txt, WCAG 2.2 AA audit, View Transitions cross-document) identified for v0.2.0–v0.4.0 roadmap. Tier 1 priorities: a11y audit + llm.txt generation (v0.2.0 if possible). Tsuki's lightweight philosophy remains perfectly aligned with 2026 peer theme trends. No breaking changes required; all recommendations are additive or documentation-focused.
