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
```

## Theme params

```yaml
params:
  description: "Site description used in <meta>, falls back to site.Title."

  search:
    enable: true            # mounts /search/ + header search button

  home:
    recentPostsCount: 5     # how many post-cards on the homepage

  toc:
    enable: true            # gate at template level (currently informational)
    minWordCount: 400       # post must exceed this to render TOC

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
draft: false
description: "Tóm tắt 1-2 câu (dùng cho meta + post-card)."
tags: ["hugo", "viet"]
categories: ["ghi-chu"]
toc: false        # opt out of TOC for this post (default: render if WordCount > 400)
comments: false   # opt out of comments for this post (default: enabled if giscus.enable)
image: "img/cover.jpg"  # OG image override
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

## Why theme defaults don't merge

Hugo's config-merging strategy for nested keys (markup, permalinks, pagination) is "none" by default. The theme ships a complete `hugo.yaml` for reference, but consumer sites must duplicate the keys above. See `exampleSite/hugo.yaml` for a working example.
