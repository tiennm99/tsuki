# Migrating from hugo-theme-stack

tsuki extracts Stack's information architecture (posts, tags, categories, archive, search, comments) and rewrites the visual layer + asset pipeline. Most posts will render unchanged. This guide covers what to delete, what to add, and where Stack-isms hide.

## What carries over

- Post frontmatter: `title`, `date`, `description`, `tags`, `categories`, `image`, `draft`
- Content path convention `content/post/YYYY/MM/DD/slug/index.md`
- Permalink shape `/:year/:month/:day/:slug/` (set `:contentbasename` on tsuki for clean ASCII)
- Tags and categories taxonomies
- Archive page (`content/archives/_index.md`)
- Giscus comment provider

## What changes

### Replace theme submodule

```bash
git submodule deinit themes/hugo-theme-stack
git rm themes/hugo-theme-stack
git submodule add https://github.com/tiennm99/tsuki themes/tsuki
```

### Update `theme:`

```yaml
theme: tsuki                       # was: hugo-theme-stack
```

### Drop these (Stack-only)

- `params.sidebar.*` — tsuki has no sidebar
- `params.widgets.*` — no widget system; portfolio is in homepage hero/projects
- `params.article.headingAnchor` — anchors render-hooked into headings unconditionally (cosmetic, opt-out is via removing the partial)
- `params.colorScheme.toggleIcon` — fixed icon
- `params.imageProcessing.*` — tsuki uses Hugo's default image processing
- `params.comments.provider` — only Giscus is supported; no Disqus / Utterances / Waline
- TypeScript build pipeline (`assets/ts/`, `tsconfig.json`) — tsuki ships ES modules directly
- SCSS pipeline (`assets/scss/`) — tsuki uses plain CSS with custom properties

### Param mapping

| Stack | tsuki | Notes |
|---|---|---|
| `params.description` | `params.description` | unchanged |
| `params.sidebar.avatar.src` | `data/profile.yaml: avatar` | now data-driven |
| `params.sidebar.subtitle` | `data/profile.yaml: tagline` | |
| `params.sidebar.emoji` | — | dropped |
| `params.menu.social[].icon` | `data/profile.yaml: links[].icon` | same icon names |
| `params.article.toc` | `params.toc.enable` + per-post `toc:` | |
| `params.search.fuse` | — | replaced by Pagefind (different config; see [config.md](config.md)) |
| `params.colorScheme.default` | system: respects `prefers-color-scheme` | toggle persists in localStorage |
| `params.dateFormat.published` | — | uses `time.Format ":date_long"` with site language |
| `params.imageProcessing.cover.enabled` | — | dropped; cover image renders as-is |

### Content frontmatter

Stack-specific fields ignored without error:

- `image` — Stack used this for sidebar cover; tsuki uses it for OG image only
- `categories[0]` weight quirks — tsuki uses Hugo defaults
- `menu`, `weight` — still respected
- `slug` — still respected

No content rewrite required for typical posts.

## Required additions

Add these to your `hugo.yaml` (tsuki defaults don't deep-merge from theme):

```yaml
pagination:
  pagerSize: 10
  path: page

permalinks:
  post: /:year/:month/:day/:contentbasename/

markup:
  goldmark:
    renderer:
      unsafe: true
    parser:
      autoHeadingIDType: github-ascii
  tableOfContents:
    startLevel: 2
    endLevel: 4
```

If your existing permalink scheme differs, **keep it** — the theme works with any permalink shape.

## Build and verify

```bash
hugo --gc --minify
```

Spot-check 5–10 posts in the rendered output. Common surprises:

- **TOC appears unexpectedly**: gated by `WordCount > 400` and `Params.toc != false`. Add `toc: false` to opt out.
- **Heading IDs changed**: switching to `autoHeadingIDType: github-ascii` produces different anchor slugs. Old `#lập-trình` becomes `#lap-trinh`. Inbound links from external sites break. Mitigate with redirects, or skip the `autoHeadingIDType` change and accept Vi diacritics in fragment URLs.
- **Search results paths**: rebuild Pagefind index (`npx pagefind --site public`); the old Fuse.js JSON index becomes dead weight.

## Dropped features (consider before migrating)

- KaTeX math (Phase 9 follow-up; available in Stack)
- Tag cloud widget (deferred)
- Image gallery shortcode (deferred)
- Any Stack-specific shortcode (`gallery`, `keyword`, `bilibili`, etc.)

If you rely on these heavily, defer the migration or wait for the follow-up release.
