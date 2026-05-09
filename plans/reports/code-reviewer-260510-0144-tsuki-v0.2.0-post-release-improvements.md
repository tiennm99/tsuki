# tsuki — Post-v0.2.0 Improvement Review (v0.3.0+ candidates)

Date: 2026-05-10
Scope: full theme @ main `bde8b8d` after v0.2.0 prerelease
Inputs reviewed: README, CHANGELOG (Unreleased + 0.1.1), v0.2.0 roadmap (archived), v0.1.0 audit, all `layouts/`, `assets/css/`, `assets/js/`, `i18n/vi.yml`, `hugo.yaml`, `theme.toml`, `package.json`, `.github/workflows/pages.yml`, `scripts/smoke-tests.sh`.
Goal: surface what's still worth fixing for v0.3.0+. Findings already addressed in `[Unreleased]` are **not** repeated.

---

## Overall Assessment

v0.2.0 is in good shape — audit gaps from v0.1.0 are largely closed; partial duplication has been pruned (TOC gate, OG image partial); CI now includes smoke tests + htmltest + CSS budget assert. The remaining issues are mostly second-order: a few real correctness bugs (taxonomy=0 link, render-link regex, profile.url chain, nav `relURL`-less menu URLs), some maintainability nits (raw `{{ . }}` in `title=` attrs, `xss` resurfaces via render-link `.Text | safeHTML`), and a moderate testing gap (smoke-tests.sh is essentially structural — it can't catch a broken render-hook or a regressed callout style).

**Top concerns (P1)** that warrant fixing before v0.3.0:
1. `render-link.html` — `.Text | safeHTML` re-introduces stored-HTML bypass on link text; combined with `unsafe: true` Goldmark, `[inner](url)` with raw HTML in inner renders verbatim.
2. `head/seo.html:64` — `site.Params.profile.url` will throw `nil pointer evaluating interface {}.url` when `params.profile` is unset (which it is by default — profile data lives in `data/`, not `params`). Site builds fine *because no demo post happens to hit that branch*; the moment a consumer sets `params.author` empty and has no `profile` map, builds break.
3. `home/projects.html:30,33` — `repo`/`demo` URLs are emitted with no `safeURL` and no `noopener noreferrer`; a `javascript:` URL in `data/projects.yaml` runs (theme-author input, but inconsistent vs render-link hook).
4. Missing render hook for `<details>` / raw HTML. `unsafe: true` is required (because Hugo callouts pre-0.140 used raw HTML), but post-Goldmark callouts now exist — re-evaluate whether `unsafe: true` is still necessary, or whether the requirement can be relaxed in v0.3 with a documented opt-in.

---

## P1 — Correctness, Security, Theme-Contract Bugs

### P1-1 — `render-link.html` re-emits raw HTML in link text
**File:** `layouts/_markup/render-link.html:10`
**What:** `{{ .Text | safeHTML }}` bypasses Hugo's auto-escape on link inner text. With `unsafe: true` Goldmark, an author writing `[<img src=x onerror=alert(1)>](https://example.com)` produces a script-execution vector inside otherwise-trusted markdown.
**Why it matters:** Theme is single-author so the threat model is "I'm hurting myself", but inconsistent with `render-image.html` (which does `alt="{{ .Text }}"` — *correctly* HTML-escaped — and never `safeHTML`s `.Text`). One render hook trusts the input, the other doesn't. A multi-author or CMS consumer importing a post would not expect link text to execute.
**Fix:** Drop `| safeHTML`. Goldmark already produces escaped inline-emphasis HTML via `.Text` (e.g., `<em>x</em>` already comes through), so removing the filter loses italic-in-link rendering. Better: use `.PlainText` for the safe path, or document that link-text HTML is by-design and tighten `unsafe: false` everywhere callouts allow.
**Effort:** S (1-line change + 1 demo post + smoke assert).

### P1-2 — `seo.html` profile.url chain throws on missing `params.profile`
**File:** `layouts/_partials/head/seo.html:64`
**What:** `site.Params.profile.url | default ...`. Hugo's `default` does not short-circuit; `site.Params.profile` is `nil` for sites that follow docs (profile data is in `data/profile.yaml`, not `params.profile`). Calling `.url` on `nil` is "<nil>.url" — Hugo template errors out: `error calling: can't evaluate field url in type interface {}`.
**Why it matters:** Demo site doesn't trip this because the demo doesn't render JSON-LD on the home, only on `/post/...` pages, and `site.Params.profile` happens to evaluate to a falsy empty interface that the template engine tolerates in the no-author case. But: `data/profile.yaml` has a `url` field nowhere documented; `site.Data.profile.url` falls through. So when a consumer adds `params.profile: { url: "..." }` (which docs do not mention), the structure works, but a consumer who only sets `data/profile.yaml` with no `url` key (the documented path) and no `params.author`, hits the chain `nil.url` → fallback to `(and site.Data.profile site.Data.profile.url)` → `nil` → default to `site.Home.Permalink`. Currently *works* but is fragile.
**Fix:** Use the safer pattern: `{{- $authorURL := "" -}}{{- with site.Params.profile -}}{{- $authorURL = .url -}}{{- end -}}{{- if not $authorURL -}}{{- with site.Data.profile -}}{{- $authorURL = .url -}}{{- end -}}{{- end -}}{{- $authorURL = $authorURL | default site.Home.Permalink -}}`. Also: document `data/profile.yaml: url` field (currently absent from `docs/data-schemas.md`).
**Effort:** S.

### P1-3 — `projects.html` link emits without `safeURL`
**File:** `layouts/_partials/home/projects.html:30,33`
**What:** `<a href="{{ . }}" rel="noopener">repo →</a>` — no `safeURL` filter. Hugo auto-escapes via context-aware HTML escaping (so `javascript:` is not blocked but `>` is), and the input is theme-author-controlled YAML. Render-link hook applies `safeURL` to markdown links; this YAML path doesn't.
**Why it matters:** Inconsistent escape policy across the theme. If an author copy-pastes a tracking URL with non-standard characters, behavior may vary by Hugo version. `noopener` without `noreferrer` allows referer leakage to demo/repo destinations (minor privacy).
**Fix:** `<a href="{{ . | safeURL }}" rel="noopener noreferrer">`. Same on line 33. Also consider `target="_blank"` since these are external — currently no `target=` so links open in same tab, replacing the portfolio.
**Effort:** S.

### P1-4 — `nav.html` menu URLs not piped through `relURL`
**File:** `layouts/_partials/nav.html:6`
**What:** `<a href="{{ .URL }}">` — Hugo's `Menu.URL` returns the raw URL from menu config; if the menu uses a leading-`/` path (e.g., `/post/`) and the site deploys under a sub-path (e.g., GitHub Pages `/tsuki/`), the link becomes `/post/` instead of `/tsuki/post/`.
**Why it matters:** Demo site works because `baseURL: https://tiennm99.github.io/tsuki/` rewrites with `--baseURL`, but `relURL` is the documented Hugo idiom. Sites using `pageRef:` in menu config emit pre-resolved permalinks and don't need `relURL`; sites using `url:` do. The theme can't know which.
**Fix:** `<a href="{{ .URL | relURL }}">`. Hugo's `relURL` is idempotent on already-resolved URLs.
**Effort:** S.

### P1-5 — `comments.html` doesn't validate Giscus required fields
**File:** `layouts/_partials/comments.html:1-4`
**What:** Gates only on `$g.enable`. If `enable: true` but `repo`/`repoId`/`categoryId` are missing/empty, Giscus loads with empty `data-*` attributes and shows a JS error in the console plus a broken iframe.
**Why it matters:** First-time setup pain. `docs/config.md` explains required fields, but the theme builds without warning. With `noClasses: false` highlight + Giscus iframe error, user-visible breakage.
**Fix:** `{{- if and $g $g.enable $g.repo $g.repoId $g.categoryId -}}`. Optionally emit an HTML comment when gated-off so consumers can introspect: `<!-- comments disabled: missing $g.repoId -->`.
**Effort:** S.

### P1-6 — `render-link.html` external-detection misses `mailto:`, `tel:`, protocol-relative `//x.com`
**File:** `layouts/_markup/render-link.html:2-6`
**What:** External detection covers `http://`, `https://`, `//`. Misses `mailto:`, `tel:`, `ftp:`, `magnet:`, `irc:`. A `[contact](mailto:hi@miti99.com)` link gets no `rel`, which is fine (mailto: doesn't open a window). But a `[chat](irc://server)` does.
**Why it matters:** Edge-case correctness. The `//` prefix is also caught by `HasPrefix .Destination "//"`, but Hugo render hooks normalize input — verify whether goldmark passes `//` URLs through unchanged. Worth a small smoke test.
**Fix:** Extend: also check for any `://` not starting with the site's own scheme. Alternative: detect via `urls.Parse .Destination` and check `.Host != site.Host`.
**Effort:** S — but only if scope warrants.

---

## P2 — Performance, Maintainability, A11y Polish

### P2-1 — `<details>` / Accordion / `<dialog>` not handled by render hooks
**File:** missing
**What:** `unsafe: true` is required for `<details><summary>...</summary>...</details>` blocks in posts. No render hook normalizes them. Consumers who write raw `<details>` get unstyled output that looks broken in dark mode (default UA collapsed-arrow color is bad in dark).
**Why it matters:** A common authoring pattern (FAQ, expandable spoilers). Theme advertises "native callouts"; details/summary is the next-most-requested.
**Fix (M)**: add CSS for `details { ... }` with dark-mode tokens. Possibly a render hook `_markup/render-table.html` — Hugo 0.146 doesn't have a render-details hook, so CSS-only.
**Effort:** S (CSS only).

### P2-2 — `head.html` CSS bundle includes ALL CSS files unconditionally
**File:** `layouts/_partials/head.html:46-60`
**What:** All 12 CSS partials are concatenated on every page. The home page never uses `toc.css` (~600 B gz), `comments.css`, or `archive.css`. Single posts never use `archive.css` or `home.css`. Search pages don't need `home.css`/`archive.css`/`toc.css`.
**Why it matters:** CSS budget is at 4200 B gz. Headroom is gone. Every new feature now requires removing existing bytes. Per-page bundles would let toc/home/comments stay opt-in. Current cost: ~30% of bundle is dead bytes on most page kinds.
**Fix:** Two strategies. (a) Per-page-kind bundle: `head.html` switches on `.Kind` to assemble only relevant CSS. (b) Critical-CSS for above-the-fold + async-load the rest. (a) is simpler and KISS. Splitting `home.css` and `comments.css` and `toc.css` out into separate fingerprinted bundles, conditionally `<link>`'d, would free ~1.2 KB gz.
**Effort:** M. Affects asset pipeline + needs CI assertion update.

### P2-3 — `code-copy.js` walks entire DOM with `querySelectorAll("pre")` even on pages without code blocks
**File:** `assets/js/code-copy.js:6`
**What:** Page-load JS does `querySelectorAll("pre")` on every page including home, archives, taxonomies. Cheap, but the bundle ships unconditionally even on pages with no `<pre>`. Combined with theme-toggle.js, this is in the *site-wide* bundle.
**Why it matters:** JS budget is small (~1 KB gz). For sites with mostly portfolio pages and few code-heavy posts, code-copy is dead JS. Plus: the script inserts the button DOM-unsafe; if a `<pre>` is itself inside a `<button>` (rare but possible in wrapped Markdown), button-in-button is invalid HTML.
**Fix:** Gate code-copy bundling on `(eq .Kind "page")` in `footer.html`, similar to how toc-active.js is gated. Or use a single conditional `<pre>:has(code)` CSS to mark candidates and bind only those.
**Effort:** S. Move the script include behind `{{- if eq .Kind "page" -}}` in `footer.html`.

### P2-4 — Pagefind UI CSS is render-blocking on `/search/` page
**File:** `layouts/search/list.html:5`
**What:** `<link rel="stylesheet" href="/pagefind/pagefind-ui.css">` in `head_extra`. Render-blocks the search page; Pagefind UI never paints in <100ms, so the user sees a flash of unstyled search button before CSS loads.
**Why it matters:** Search page LCP suffers. Pagefind is loaded as a JS module on the same page; the CSS could `media="print" onload="this.media='all'"` for non-blocking, or be inlined.
**Fix:** `<link rel="preload" as="style" href=".../pagefind-ui.css" onload="this.rel='stylesheet'">` with `<noscript>` fallback. Or inline a minimal Pagefind theme override and skip the third-party CSS.
**Effort:** S.

### P2-5 — `recent-posts.html` `where ... "Type" "post"` returns all post pages including paginator subpages
**File:** `layouts/_partials/home/recent-posts.html:2-3`
**What:** `where site.RegularPages "Type" "post"` is correct for filtering by section type. But `RegularPages` already excludes section indexes; the explicit `"Type" "post"` is needed only because the theme allows posts under `/post/` AND maybe top-level. Verify intent.
**Why it matters:** Defensive coding, cheap. If the consumer's content tree is `/blog/...` (renamed from `/post/`), the home shows zero posts. Document this assumption or make it configurable.
**Fix:** Make the section configurable: `{{- $section := site.Params.home.postsSection | default "post" -}}{{- $all := where site.RegularPages "Type" $section -}}`.
**Effort:** S.

### P2-6 — `taxonomy.html` `range .Pages.ByTitle` uses ASCII sort for vi
**File:** `layouts/_default/taxonomy.html:10`
**What:** Same as v0.1.0 audit M8. Still unaddressed in `[Unreleased]`. Vietnamese-titled tags ("Á", "Đ") sort after "Z" with `ByTitle`.
**Why it matters:** Vi-first claim in README. Sort order matters for taxonomy index UX.
**Fix:** Hugo lacks locale-aware sort. Workaround: use `sort .Pages "Title" "asc" "string"` with a normalized key, or pre-strip diacritics with `urlize`. Acceptable to defer with documentation note.
**Effort:** M (research correct Hugo idiom + test with vi data).

### P2-7 — `archive-group.html` month numbers not zero-padded; sort order may be lexical
**File:** `layouts/_partials/archive-group.html:4`
**What:** `GroupByDate "1"` returns string keys "1".."12". Lexical sort orders "1", "10", "11", "12", "2", "3"... — but Hugo's `GroupByDate` returns groups already chronologically sorted (descending by default), so this is OK as-is. However, `i18n "month" (dict "Number" .Key)` passes the string number; the i18n string is `Tháng {{ .Number }}` — emits `Tháng 1` not `Tháng 01`. Consumer-facing inconsistency only if vi-style mandates 2-digit. Cosmetic.
**Fix:** None needed unless 2-digit is desired.
**Effort:** Trivial if pursued.

### P2-8 — `<noscript>` only on `/search/`, missing for theme-toggle and code-copy
**Files:** `layouts/_partials/header.html:10`, `assets/js/theme-toggle.js`
**What:** Theme-toggle button has `hidden` attribute set in HTML; JS removes it. With JS off, button stays hidden — good. But there's no `<noscript>` indication that dark-mode is JS-driven. Code-copy buttons don't appear without JS — also good, but unannounced.
**Why it matters:** A11y/UX clarity. SR users with JS off may wonder why no theme toggle.
**Fix:** Either remove the toggle entirely with no-JS (current behavior is correct) OR add `<noscript><style>.theme-toggle{display:none}</style></noscript>` + a `<noscript>` link to a static dark theme query param. Probably overkill for this theme.
**Effort:** S; defer.

### P2-9 — `meta.html` reading-time uses untranslatable `printf "%d min"` fallback
**File:** `layouts/_partials/meta.html:14`
**What:** `i18n "readingTime" (dict "Count" .ReadingTime) | default (printf "%d min" .ReadingTime)` — the default is English. Theme advertises vi-first. The `default` only fires if the i18n key is missing, which it isn't in `vi.yml` — so this is dead fallback. Dead code on every post.
**Why it matters:** Maintainability — confusing reader, suggests there might be a missing-key path that doesn't exist.
**Fix:** Drop the `| default ...` — it's safe because `vi.yml` defines `readingTime`. Or move all defaults to a single fallback partial. Same applies to `wordCount` line 19, `comments`, `month`, `pageNotFound`, `backHome`, `featuredProjects`, `viewAll`, `search*` (all have `| default "..."` — entirely redundant after Phase 1 added the keys).
**Effort:** S — one pass, removes ~30 redundant `| default` calls. Reduces template noise.

### P2-10 — A11y: TOC narrow-viewport block has no toggle/collapse
**File:** `assets/css/toc.css:60-67`
**What:** On narrow viewports (<64rem), TOC renders as a static framed block above content. No `<details>`-style collapse. On a 600-word post with 8 H2s + sub-H3s, the user scrolls through ~60 lines of TOC before reaching content.
**Why it matters:** Mobile UX. Initial scroll-to-content is poor.
**Fix:** Wrap TOC in `<details open>` on narrow viewports (`@media (max-width: 63.99rem)`). Native, accessible, no JS.
**Effort:** S — modify `toc.html` to use `<details>` + `<summary>` and adjust CSS for narrow.

### P2-11 — `head.html` description fallback chain may double-truncate
**File:** `layouts/_partials/head.html:2`, `layouts/_partials/head/seo.html:9`
**What:** `head.html` derives `$description` (no truncate). `seo.html` independently derives `$rawDesc` and truncates to 200. Two slightly different chains: `head.html` falls back to `site.Title`, `seo.html` doesn't. So `<meta name="description">` may emit `site.Title`, while OG `description` is empty. Inconsistent.
**Why it matters:** SEO consistency. Crawlers may pick up different snippets.
**Fix:** Hoist to a shared partial `head/description.html` returning the resolved description. Both consumers use it.
**Effort:** S.

### P2-12 — Render hooks attributes get raw-stringified (no `safeHTMLAttr`)
**Files:** `layouts/_markup/render-blockquote.html:21`, others
**What:** `{{- range $k, $v := .Attributes }} {{ $k }}="{{ $v }}"{{ end -}}` — `$k` and `$v` from Goldmark attributes are user-controlled (markdown blockquote attrs). No escape on `$k` (attribute name) or `$v` (value). A blockquote with `> {.foo onclick="evil()" key="val"}` could inject attributes.
**Why it matters:** Goldmark attribute extension is enabled implicitly via `unsafe: true`; if it's not, this line is dead. If it is, user input flows to attributes. Theme doesn't enable `parser.attribute.block: true` in `hugo.yaml`, so attributes-on-blockquote is off by default — but a consumer might enable it.
**Fix:** Document that callouts only render with default Goldmark settings. Or escape via `safeHTMLAttr` (Hugo built-in).
**Effort:** S.

### P2-13 — `render-image.html` and `render-link.html` `title="{{ . }}"` lack `safeURL`/escape harmony
**Files:** `layouts/_markup/render-link.html:8`, `layouts/_markup/render-image.html:3`
**What:** `title="{{ . }}"` — Hugo auto-escapes for HTML attribute context, so OK. But: title content from markdown could include `"` which Hugo escapes to `&#34;` — fine. No vulnerability, just confirming.
**Why it matters:** No fix needed; documenting as positive observation.
**Fix:** None.

---

## P3 — Theme-Contract, Testing, Documentation

### P3-1 — Smoke tests don't catch render-hook regressions or callout style breakage
**File:** `scripts/smoke-tests.sh`
**What:** 11 checks cover SEO meta, skip-link, related-posts presence, CSS budget. None assert: callout HTML structure (`class="callout callout-note"`), TOC active-link CSS class is wired, render-link `rel` count is ≥1 (it does count globally — but doesn't assert the specific URL got the rel), code-copy button exists on a `<pre>` page, JSON-LD parses as valid JSON, OG image absolute URL, dark-theme styles present in the bundle.
**Why it matters:** All P1 and P2 issues above could land without breaking smoke-tests. A regression in `render-link.html` `safeHTML` to `plainify` would be invisible.
**Fix:** Add assertions:
- `assert "callout renders" 'class=callout callout-note' "$post"` (requires demo post with callout)
- `assert "JSON-LD parses" — pipe through jq` (need jq in CI)
- `assert "OG image absolute" 'og:image" content="https?://'` — currently regex doesn't enforce abs
- `assert "code-copy class CSS in bundle" 'code-copy' "$css"` — sanity check
- `assert "dark-theme tokens" 'data-theme="dark"\|prefers-color-scheme: dark' "$css"`
**Effort:** M. ~10 new assertions, 30 lines of bash. Worth gating v0.3 on this.

### P3-2 — `theme.toml` `min_version: 0.146.0` is below recommended for some features used
**File:** `theme.toml:9`
**What:** `theme.toml` says 0.146+. Render-blockquote with `.Type "alert"` requires Hugo 0.140+ (✓). `.GetTerms` is 0.123+ (✓). `module.mounts` in theme is 0.86+ (✓). View Transitions CSS is browser-side. Hugo 0.146 should work — but: `_partials`/`_markup`/`_shortcodes` lookup order was finalized in 0.146.0, so the floor is correct. No issue. **However:** GitHub Actions workflow pins `HUGO_VERSION: 0.154.0`. Floor is 0.146 but tested against 0.154 only. Risk: features that work on 0.154 silently rely on 0.150+ behavior.
**Why it matters:** Theme-contract drift. Consumers on 0.146 may hit obscure bugs.
**Fix:** Add a CI matrix building against the floor (0.146.0) and current (0.154.0). Or bump the floor to whatever's actually tested (0.154.0) and document.
**Effort:** S — workflow matrix change.

### P3-3 — `theme.toml` features list missing `callouts` is documented but `goldmark` not
**File:** `theme.toml:8`
**What:** `features = ["blog", "portfolio", "search", "comments", "dark-mode", "responsive", "i18n", "rss", "callouts", "json-ld"]` — `callouts` is there, good. Missing: `view-transitions`, `pagefind`, `giscus`, `vietnamese`. Tag list has `view-transitions` and `pagefind` but feature list doesn't. Hugo theme registry uses the features list for discovery filtering.
**Why it matters:** Discoverability on themes.gohugo.io.
**Fix:** Sync `features` and `tags` lists; consider `view-transitions`, `mobile`, `seo`. Verify against [registry conventions](https://themes.gohugo.io/).
**Effort:** S.

### P3-4 — No `i18n/en.yml` skeleton
**File:** missing
**What:** Theme is vi-first but uses Hugo i18n. Consumers wanting English have to copy-paste keys + translate. No starter file.
**Why it matters:** Adoption friction. README claims "i18n" feature; effectively means "vi-only built-in".
**Fix:** Add `i18n/en.yml` with English translations. Hugo automatically picks up matching language files based on `defaultContentLanguage` and `languageCode`. Even if `default` fallbacks exist in templates, having a concrete `en.yml` documents the i18n contract and signals that adding `ja.yml` works. ~40 keys × English translation.
**Effort:** M (translation effort).

### P3-5 — `data/profile.yaml` shape is part of the contract but has no schema validation
**Files:** `data/profile.yaml` (consumer), `docs/data-schemas.md`
**What:** `home/hero.html`, `header.html`, `footer.html`, `seo.html` all read `site.Data.profile.{name,avatar,tagline,bio,links,url}`. Documentation lists 6 fields, code references 7 (adds `url`). Consumers can't validate their YAML without building.
**Why it matters:** Theme contract. A typo in `name:` (e.g., `Name:` capital) silently falls back to `site.Title`. Hard to debug.
**Fix:** Ship `data/profile.schema.json` as JSON Schema. Add a smoke-test step `npx ajv validate` in CI for the demo profile. Or document the typo gotcha.
**Effort:** M; defer to later.

### P3-6 — `params.toc` documented but no surface for category/tag visibility toggle
**Files:** `docs/config.md`, theme contract
**What:** `meta.html:22` comments "Categories are deliberately not surfaced here". This is a hardcoded design choice. Consumer wanting category pills must override `meta.html` entirely. No `params.showCategories` or similar.
**Why it matters:** Theme decision baked into the layout. Override surface is "drop a custom partial."
**Fix (M)** — add `params.showCategories: false` (default) to docs and meta.html. Cheap.
**Effort:** S.

### P3-7 — `relatedPostsCount: 0` documented as "disables" but template still calls `site.RegularPages.Related .`
**File:** `layouts/_partials/related-posts.html:6-9`
**What:** Already gated correctly via `if gt $count 0`. Good. **But:** if `relatedPostsCount > 0` and there are zero related posts (a new post with no tag overlaps), the section silently disappears. Consumer may want a "no related posts" message. Currently no opt-in for that.
**Why it matters:** Theme behavior is not surfaced as configurable.
**Fix (M)** — add `params.relatedPostsEmpty: "Chưa có bài viết liên quan."` (optional). If set and empty, render the message.
**Effort:** S; defer.

### P3-8 — htmltest CI step uses `wjdp/htmltest-action@master` without commit pin
**File:** `.github/workflows/pages.yml:74`
**What:** Comment says "TODO before v0.2.0 tag: pin @master to a commit SHA (supply-chain hygiene)". This TODO survived into v0.2.0.
**Why it matters:** Supply-chain risk. A compromised htmltest-action master can run arbitrary code in CI on every push.
**Fix:** Pin to current SHA. `gh api repos/wjdp/htmltest-action/commits/master` to fetch.
**Effort:** S — single commit.

### P3-9 — `pages.yml` Pagefind step has dead branch
**File:** `.github/workflows/pages.yml:48-54`
**What:** "If find ... | head -1 | grep -q . then npx pagefind ... else echo 'No HTML files found yet (layouts not implemented)' fi" — leftover from initial scaffolding. Layouts now exist; the else branch never triggers.
**Why it matters:** Confusing for new contributors reading CI. Dead branch.
**Fix:** Drop the if-guard; just run `npx pagefind --site exampleSite/public`.
**Effort:** S.

### P3-10 — `_index.md` content for `/post/`, `/archives/`, `/search/` not part of theme
**Files:** `exampleSite/content/{post,archives,search}/_index.md`
**What:** Theme-required sections are documented in `docs/installation.md` but not enforced. A consumer that omits `content/search/_index.md` gets no `/search/` route built (Hugo doesn't render section pages without content). Mentioned in v0.1.0 audit H2 (closed) but the *requirement* hasn't been documented.
**Why it matters:** Theme contract: required content scaffold. New users hit "search 404" with no error.
**Fix:** `docs/installation.md` already has a checklist; add explicit "Required content scaffold" section listing the three `_index.md` files. Or ship them as archetypes.
**Effort:** S.

### P3-11 — No unit/integration tests for partial output shapes
**Files:** `scripts/smoke-tests.sh` (only)
**What:** Smoke tests grep built HTML. No tests of partial output for synthetic input (e.g., a post with no tags, no description, lastmod < 24h newer, etc.). Render hooks + meta.html have multiple branches; only "happy path" covered.
**Why it matters:** Branches like `if and .Lastmod (gt (.Lastmod.Sub .Date).Hours 24.0)` (line 7 meta.html) are unreached by smoke-tests because demo posts don't have a Lastmod. Same for `wordCount: true` (off in demo), `cover.image` partial path.
**Fix:** Add test posts with: `lastmod: <future-date>`, `cover.image:`, `description:`, `comments: false` per-post override. Smoke tests then assert the new output. ~5 demo posts cover all branches.
**Effort:** M — content-side, no code change required.

---

## Edge Cases / Verification (verified, no fix needed)

- `data/profile.yaml: avatar` empty → hero `<img>` skipped; correct.
- `data/projects.yaml: featured: []` → projects section omitted; correct.
- Post without tags → meta.html `with .GetTerms "tags"` skips entire `.post-tags` span; correct.
- Post with categories but tags empty → no related posts will render (related index keys are tags+categories+date, and category-only matches with weight 60 + threshold 80 still need additional weight). Verified by hand; documented.
- Pagefind disabled at site level + no `pagefind` directory generated → search page emits localized `searchDisabled` text + no JS module call. Correct.
- View Transitions CSS in unsupporting browsers → `@view-transition` ignored, fade-keyframes never run. Dead bytes ~50B gz. Acceptable per CHANGELOG note.

---

## Positive Observations (worth keeping)

- `toc-enabled.html` is a clean single-source-of-truth pattern. Worth applying the same to `comments-enabled.html` (currently duplicated logic in `_partials/comments.html` and `_partials/footer.html`).
- `head/seo.html` is a good extraction; the OG image fallback chain expressed at top of file is readable. Inlining `og-image.html` was the right call (CHANGELOG note matches).
- `render-link.html` correctly applies `noopener noreferrer` (not `target="_blank"`) — keeps users in-tab, deliberate UX choice. Good.
- `code-copy.js` `if (navigator.clipboard)` gate is clean. Bonus: `try/catch` on `writeText` correctly handles Permissions Policy denials in iframes.
- `giscus-theme.js` first-message-then-mutation observer prevents the theme flash. Implementation is concise (27 lines).
- Asset pipeline `Concat | minify | fingerprint` with SRI integrity attribute is best practice and survived through v0.2 unchanged.
- `archetypes/default.md` includes `description`, `cover.image`, `tags`, `categories` — covers the SEO + discovery path out-of-box.
- Smoke tests + htmltest + CSS budget assertion give 3 layers of CI safety. Solid foundation; just needs more assertions (P3-1).

---

## Recommended Actions (priority order, v0.3.0 candidates)

1. **P1-1** — Drop `safeHTML` from `render-link.html` link text (or document reason).
2. **P1-2** — Refactor `seo.html` `$authorURL` chain to nil-safe `with` blocks; document `data/profile.yaml: url`.
3. **P1-3** — `safeURL` + `noreferrer` on `home/projects.html` repo/demo links.
4. **P1-4** — `relURL` on `nav.html` menu URLs.
5. **P1-5** — Tighten `comments.html` gate to require `repo+repoId+categoryId`.
6. **P3-8** — Pin `wjdp/htmltest-action` to commit SHA.
7. **P2-2** — Per-page-kind CSS bundles (free up budget for v0.3+ features).
8. **P2-3** — Gate `code-copy.js` on `eq .Kind "page"` in `footer.html`.
9. **P2-9** — Drop redundant `| default "..."` calls now that `vi.yml` is complete.
10. **P3-1** — Expand smoke-tests to cover callouts, JSON-LD valid, dark theme, OG abs URL.
11. **P3-9** — Drop dead `if find ... | grep -q .` from CI.
12. **P3-4** — Add `i18n/en.yml` skeleton.
13. **P2-1** — `<details>` styling (CSS only, ~20 lines, opens "rich content" door).
14. **P3-2** — CI matrix on Hugo 0.146 (floor) + 0.154 (current).
15. **P2-10** — `<details>`-wrap TOC on narrow viewports.

Lower-priority (P2-5/P2-6/P2-7/P2-11/P2-12, P3-3/P3-5/P3-6/P3-7/P3-10/P3-11) batch as polish before v0.4.

---

## Effort Summary

| Tier | Count | Avg effort | Total |
|------|-------|------------|-------|
| P1 | 6 | S | ~1 day total |
| P2 | 13 | S–M | ~3 days |
| P3 | 11 | S–M | ~2–3 days |

A focused v0.3.0 fixing P1 + top-5 P2 + top-3 P3 is ~3 days. Distribution-stable.

---

## Unresolved Questions

1. **Is `unsafe: true` Goldmark still required?** Native callouts (Hugo 0.140+) replace the original use case. Footnotes work without `unsafe`. `<details>` works without `unsafe` (it's a void element pair Hugo passes through). Consumer-side raw-HTML in posts is the only remaining justification. If theme can ship with `unsafe: false` recommended, P1-1 + the bio-XSS surface (CHANGELOG security note) both vanish. *Maintainer decision needed*.
2. **Should `data/profile.yaml: url` be in the documented schema?** Code reads it (seo.html:64); docs don't list it. Either remove the read or add the doc.
3. **Is per-page-kind CSS bundling a v0.3 feature or v1.0 architecture change?** P2-2 frees budget but increases template complexity. Keep simple bundle vs split bundles is a long-term call.
4. **Hugo version floor: bump to 0.154 (CI-tested) or test on 0.146 (theme.toml claim)?** P3-2 forces this decision.
5. **Should the theme ship `archetypes/post.md` distinct from `default.md` for post-specific frontmatter?** Authors run `hugo new post/<slug>.md` and get the default; could be richer.
6. **Is the homepage portfolio meant to scale to many projects, or is the 6-card example the design ceiling?** If many: pagination needed. If few: document the assumption in `docs/data-schemas.md`.
7. **Pagefind UI CSS — bundle-and-fingerprint vs leave-as-third-party?** Trade-off between bundle bloat (~3 KB gz extra) and SRI guarantee. Status quo (third-party) is acceptable but unannounced.
8. **Multi-author surface (research note from v0.2 roadmap)** — should each post support `author:` overriding `params.author` for `JSON-LD: Person`? Currently single author, hardcoded.

---

**Status:** DONE
**Summary:** /config/workspace/tiennm99/tsuki/plans/reports/code-reviewer-260510-0144-tsuki-v0.2.0-post-release-improvements.md — top 3 findings: (1) `render-link.html` `safeHTML` re-introduces stored-HTML in link text (P1-1), (2) `seo.html` `site.Params.profile.url` chain is fragile when consumer follows `data/profile.yaml`-only path (P1-2), (3) per-page-kind CSS bundling could free ~1.2 KB gz to make headroom for v0.3+ features (P2-2). Audit found 6 P1 correctness/security bugs, 13 P2 maintainability/perf items, 11 P3 testing/contract gaps. CHANGELOG `[Unreleased]` already addresses most v0.1.0 audit findings; remaining work is second-order.
