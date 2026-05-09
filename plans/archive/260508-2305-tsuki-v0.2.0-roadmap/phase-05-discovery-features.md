---
phase: 5
title: "Discovery features (related posts + categories)"
status: completed
completed_date: 2026-05-09
priority: P2
effort: "0.5d"
dependencies: [2, 4]
---

# Phase 5: Discovery features

## Context Links

- Researcher: `plans/reports/researcher-260508-2306-hugo-theme-best-practices.md` — § 1.2 Gap 5, § 9 Tier 2.4
- Audit: `plans/reports/code-reviewer-260508-2305-tsuki-v0.1.0-audit.md` — M1 categories visibility

## Overview

Add related-posts section to single post layout using Hugo's built-in `.Site.RegularPages.Related`. Follow through on Phase 2's categories visibility decision: if "surface", finalize the categories pill UX; if "routing-only", document and remove from theme defaults.

## Requirements

**Functional**
- Single post page shows up to 5 related posts based on shared tags + categories
- Related-posts section hidden when no relations found
- Related-posts use `post-card.html` partial (shared with home recent-posts) — no new card variant
- Categories visibility decision from Phase 2 fully landed (UI exists OR docs explain absence)

**Non-functional**
- Hugo `.Related` config tuned for vi-language post titles (no language-specific issues, but confirm)
- No JS
- Related-posts CSS reuses existing post-card styles; budget impact ~50 B for layout adjustments

## Architecture

Hugo built-in: configure `related` in `hugo.yaml` (theme defaults ship a sensible weight matrix). Single new partial `_partials/related-posts.html` consumed by `single.html`. Reuses `post-card.html`.

## Related Code Files

**Create**
- `layouts/_partials/related-posts.html`

**Modify**
- `layouts/single.html` — call `partial "related-posts.html" .` after content + comments
- `hugo.yaml` (theme defaults) — `related: { ... }` section
- `i18n/vi.yml` — add `relatedPosts` key
- `assets/css/components.css` — minor adjustments if needed
- `docs/config.md` — document `related` config + how to override
- `layouts/_partials/meta.html` — finalize categories pill (carry from Phase 2)

## Implementation Steps

1. **Hugo `related` config** — add to `hugo.yaml` (theme defaults, mirror in `exampleSite/hugo.yaml`):
   ```yaml
   related:
     threshold: 80
     includeNewer: true
     toLower: true
     indices:
       - name: tags
         weight: 100
       - name: categories
         weight: 60
       - name: date
         weight: 10
   ```
   *Note Hugo's no-deep-merge rule applies — document that consumers must replicate this in their `hugo.yaml`.*
2. **`_partials/related-posts.html`**:
   ```go-html-template
   {{- $related := first 5 (site.RegularPages.Related .) -}}
   {{- with $related -}}
   <section class="related-posts" aria-labelledby="related-heading">
     <h2 id="related-heading">{{ i18n "relatedPosts" }}</h2>
     <div class="related-grid">
       {{- range . -}}
         {{ partial "post-card.html" . }}
       {{- end -}}
     </div>
   </section>
   {{- end -}}
   ```
3. **single.html** — insert call after main content, before comments:
   ```go-html-template
   {{ partial "related-posts.html" . }}
   ```
4. **i18n** — add `relatedPosts: "Bài viết liên quan"` in `vi.yml`.
5. **CSS** — append minimal grid layout to `components.css`:
   ```css
   .related-posts { margin: 3rem 0 1rem; padding-top: 1.5rem; border-top: 1px solid var(--tsuki-border); }
   .related-grid { display: grid; gap: 1rem; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); }
   ```
6. **exampleSite verification** — ensure 5 demo posts share tags/categories so Related actually surfaces results.
7. **Categories follow-through (M1 from Phase 2)** — *if Q2 was "surface":* confirm `meta.html` shows categories pill and Phase 5 Related uses both indices. *If "routing-only":* drop `categories` from `related.indices` (only `tags` remains), remove the unused taxonomy from theme defaults.
8. **Docs** — `docs/config.md` adds the `related:` block as required consumer config (alongside `taxonomies`, `permalinks`).
9. **CSS budget check** — gzip CSS bundle. Likely now ~4.1-4.2 KB. May need to drop dead bytes elsewhere or split.
10. **CHANGELOG** — `### Added` related posts.

## Todo

- [x] `related` config in theme defaults + exampleSite (tags/categories/date weights)
- [x] `_partials/related-posts.html` created
- [x] `single.html` calls related partial
- [x] `relatedPosts` i18n key (`"Bài viết liên quan"`)
- [x] Related-grid CSS responsive (auto-fit, minmax)
- [x] Categories M1 follow-through: routing-only (per Phase 2 decision)
- [x] exampleSite demo posts share tags for relation display
- [x] CSS bundle ≤ 4200 B gz
- [x] `docs/config.md` documents `related` config + threshold tuning

## Success Criteria

- Visiting a demo post shows 2-5 related posts at the bottom, before comments
- A post with no shared tags/categories shows no Related section (no empty heading orphan)
- Related-grid wraps responsively on mobile (1 col), tablet (2 col), desktop (3+)
- Lighthouse perf score doesn't drop more than 1 point vs Phase 4 baseline

## Risk Assessment

- **Hugo `Related` performance** — O(n²) over `.Pages` for large sites. Hugo caches; for 1000+ posts a build could slow. Document threshold tuning in `docs/config.md`.
- **Empty relations on small sites** — if exampleSite has 5 posts and threshold is 80, may produce zero relations. Tune for demo or seed posts with shared `keywords` frontmatter.
- **CSS budget** — heading + grid adds ~150 B gz. Combined with Phase 4's callouts, likely the budget cliff arrives here. Be ready to drop the lowest-value rule (e.g. unused `--tsuki-vt-name` from M4 if not removed earlier).
- **Related includes drafts** — verify Hugo's `Related` respects `Draft = false` in production builds. (It does, since `RegularPages` excludes drafts.)

## Security Considerations

- No new attack surface; all data flows through Hugo's already-validated taxonomy graph.

## Next Steps

→ Phase 6 — distribution prep finalizes theme.toml + module mounts now that feature surface is stable.
