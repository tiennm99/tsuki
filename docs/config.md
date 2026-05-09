# Configuration

Reference for `hugo.yaml` keys that tsuki reads. **All settings below are set in your *site's* `hugo.yaml`, not in the theme.** The theme ships defaults for documentation only — Hugo does not deep-merge nested config from themes.

## Required

```yaml
languageCode: vi
defaultContentLanguage: vi
theme: tsuki

pagination:
  pagerSize: 10
  path: page

taxonomies:
  category: categories
  tag: tags

permalinks:
  post: /:year/:month/:day/:contentbasename/

markup:
  goldmark:
    renderer:
      unsafe: true
    parser:
      autoHeadingIDType: github-ascii  # ASCII slugs for vi diacritics
  tableOfContents:
    startLevel: 2
    endLevel: 4

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

## Theme params

```yaml
params:
  description: "Site description used in <meta>, falls back to site.Title."
  author: "Your Name"       # used in OG + JSON-LD article author

  social:
    twitter: "yourhandle"   # adds twitter:site + twitter:creator (no @ prefix)

  og:
    fallbackImage: "img/og-default.png"  # site-wide OG/Twitter image when no per-post or profile.avatar

  search:
    enable: true            # mounts /search/ + header search button

  home:
    recentPostsCount: 5     # how many post-cards on the homepage

  toc:
    enable: true            # site-wide kill switch (per-post `toc: false` still wins)
    minWordCount: 400       # post must exceed this to render TOC

  relatedPostsCount: 3      # number of cards under each post (0 disables — section vanishes)

  comments:
    giscus:
      enable: false         # opt-in
      repo: "<owner>/<repo>"
      repoId: "R_kgDO..."
      category: "Announcements"
      categoryId: "DIC_kwDO..."
      mapping: "pathname"   # pathname | url | title | og:title
      strict: "0"
      reactionsEnabled: "1"
      inputPosition: "bottom"  # top | bottom
      theme: "preferred_color_scheme"
      lang: "vi"
```

Generate Giscus values at [giscus.app](https://giscus.app). Only `enable: true` activates the partial; missing IDs are ignored.

## Profile and projects

The homepage portfolio reads from data files, **not** `params`:

- `data/profile.yaml` — bio, avatar, links. See [data-schemas.md](data-schemas.md).
- `data/projects.yaml` — featured projects grid. See [data-schemas.md](data-schemas.md).

## Per-post frontmatter

```yaml
---
title: "Tiêu đề bài viết"
date: 2026-05-07T19:00:00+07:00
lastmod: 2026-05-08T10:00:00+07:00  # shows "Cập nhật {date}" if ≥24h newer than date
draft: false
description: "Tóm tắt 1-2 câu (dùng cho meta + post-card)."
tags: ["hugo", "viet"]
categories: ["ghi-chu"]
toc: false        # opt out of TOC for this post (default: render if WordCount > 400)
comments: false   # opt out of comments for this post (default: enabled if giscus.enable)
cover:
  image: "img/cover.jpg"  # OG/Twitter card image (preferred)
image: "img/cover.jpg"    # legacy alias for `cover.image`; either works
---
```

## Optional

```yaml
menus:
  main:
    - name: "Bài viết"
      url: /post/
      weight: 10
    - name: "Lưu trữ"
      url: /archives/
      weight: 20
    - name: "Thẻ"
      url: /tags/
      weight: 30
```

## SEO output

Tsuki emits SEO metadata in `_partials/head/seo.html` (called from `head.html`):

- **OpenGraph** — `og:title`, `og:description`, `og:url`, `og:type`, `og:site_name`, `og:locale`, `og:image`. Posts also get `article:published_time`, `article:modified_time`, `article:author`, one `article:tag` per tag.
- **Twitter Card** — `summary_large_image` with title, description, image; `twitter:site` + `twitter:creator` only when `params.social.twitter` is set.
- **JSON-LD Article schema** — emitted only on single post pages (`IsPage` + `Kind == "page"`); covers `headline`, `url`, `datePublished`, `dateModified`, `author` (Person), `publisher` (Organization), `image`, `description`, `keywords`.
- **OG image resolution** — per-post `cover.image` → per-post `image` (legacy) → `params.og.fallbackImage` → `params.profile.avatar`. The first non-empty value wins.

To override, drop `_partials/head/seo.html` (and optionally `_partials/head/og-image.html`) into your site `layouts/`.

## Why theme defaults don't merge

Hugo's config-merging strategy for nested top-level keys (markup, permalinks, pagination, `related`) is "none" by default. `params.*` *does* merge, but anything outside `params:` (including `related:`) does not. The theme ships a complete `hugo.yaml` for reference, but consumer sites must duplicate the keys above. See `exampleSite/hugo.yaml` for a working example.

## Theme contract: taxonomies and content

Two conventions the theme assumes; deviating from them produces broken links or unstyled output.

- **Taxonomy keys** — the singular keys in `taxonomies:` must be `tag` and `category`; the plural names (`tags`, `categories`) are referenced by name in templates (`.GetTerms "tags"`). Renaming the plural breaks tag rendering. Keep the defaults shown above.
- **Tag titles for Vietnamese diacritics** — `.GetTerms "tags"` returns `LinkTitle`, which falls back to the URL slug if no `_index.md` exists for that term. To display `Ghi chú` instead of `ghi-chu`, create `content/tags/ghi-chu/_index.md` with `title: "Ghi chú"`.
- **`params.search.enable: false`** — disables the search route body, header button, and Pagefind UI loader. The route page (`/search/`) still resolves; if you want it to 404 entirely, also delete `content/search/_index.md` from your site.
- **`profile.bio` is trusted-author input** — see [data-schemas.md](data-schemas.md) for the security note.
