# Data schemas

The homepage portfolio is data-driven. Two YAML files in `data/`.

## `data/profile.yaml`

Powers the homepage hero and the OG image fallback.

```yaml
name: "Tien Nguyen"          # required: display name
handle: "tiennm99"            # optional: short handle (currently unused; reserved)
tagline: "Building tools, breaking things, writing it down."  # optional: under name
avatar: "img/avatar.svg"      # optional: site-relative path under static/
bio: |                        # optional: markdown, rendered with markdownify
  Software engineer based in Ho Chi Minh City. I build for the web,
  experiment with AI tooling, and write down what I learn.
links:                        # optional: array of {icon, label, url}
  - icon: github               # icon name resolves to assets/icons/<name>.svg
    label: GitHub
    url: https://github.com/tiennm99
  - icon: mail
    label: Email
    url: mailto:hi@example.com
  - icon: rss
    label: RSS
    url: /index.xml
```

Field reference:

| field   | type   | required | notes                                     |
|---------|--------|----------|-------------------------------------------|
| name    | string | yes      | falls back to `site.Title` if absent      |
| handle  | string | no       | reserved                                  |
| tagline | string | no       | rendered as `<p>` under name              |
| avatar  | string | no       | resolved with `relURL`; show `<img>` if set |
| bio     | string | no       | markdown; `markdownify` filter applied — see security note below |
| links   | array  | no       | empty list = no links section             |

Built-in icons under `assets/icons/`: `github`, `mail`, `rss`, `search`. Add your own SVGs there with `currentColor` fill.

> **Security note — `bio` rendering.** The theme requires `markup.goldmark.renderer.unsafe: true` (see [`docs/config.md`](config.md)) and pipes `bio` through `markdownify`. Any raw HTML in `bio` — including `<script>`, `<iframe>`, `onerror=` attributes — renders verbatim. Treat `data/profile.yaml` as **trusted-author input only**. Do not populate `bio` from a CMS, form, or any source you don't fully control. If you need to disable raw HTML site-wide, set `markup.goldmark.renderer.unsafe: false` in your `hugo.yaml` (you may lose footnotes and `<details>` blocks in posts that rely on them).

## `data/projects.yaml`

Powers the featured projects grid on the homepage.

```yaml
featured:
  - title: "bonsai"
    tagline: "Minimalist Hugo theme for link-in-bio."
    repo: https://github.com/tiennm99/bonsai
    demo: https://tiennm99.github.io/bonsai/
    image: "img/projects/bonsai.svg"
    tags: [hugo, theme, minimal]

  - title: "vngeoguessr"
    tagline: "GeoGuessr clone for Vietnamese locations."
    repo: https://github.com/tiennm99/vngeoguessr
    image: "img/projects/vngeoguessr.svg"
    tags: [geo, mapillary, redis]
```

Field reference (per project):

| field   | type     | required | notes                                            |
|---------|----------|----------|--------------------------------------------------|
| title   | string   | yes      | card heading                                     |
| tagline | string   | no       | one-line description under title                 |
| image   | string   | no       | site-relative; rendered 16:9 with `object-fit: cover` |
| repo    | URL      | no       | "repo →" link if present                         |
| demo    | URL      | no       | "demo →" link if present                         |
| tags    | string[] | no       | small chips below tagline                        |

The grid uses `auto-fit, minmax(16rem, 1fr)`; cards reflow on narrow viewports automatically.
