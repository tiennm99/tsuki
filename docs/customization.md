# Customization

Hugo's lookup order means **anything in your site overrides the theme**. No fork required.

## Override layouts and partials

Drop a file with the same path under your site's `layouts/` to replace the theme version.

```
your-site/
└── layouts/
    ├── _partials/
    │   └── footer.html      # overrides themes/tsuki/layouts/_partials/footer.html
    └── single.html          # overrides themes/tsuki/layouts/single.html
```

To extend rather than replace, copy the theme partial into your site, then modify. Common overrides:

- `_partials/footer.html` — add license, build info, web ring links
- `_partials/home/hero.html` — restructure the homepage hero
- `_partials/comments.html` — swap Giscus for a different provider

## Override design tokens

Tokens are CSS custom properties on `:root` and `:where([data-theme="dark"])`. Override them in a custom stylesheet without editing the theme.

```css
/* your-site/assets/css/custom.css */
:root {
  --tsuki-accent: #cc7a3b;        /* warmer accent */
  --tsuki-font-sans: "Public Sans", system-ui, sans-serif;
  --tsuki-content-width: 48rem;   /* wider posts */
}
:where([data-theme="dark"]) {
  --tsuki-accent: #f0a070;
}
```

Append it to the bundle by overriding `_partials/head.html`. Copy the theme version, add your file:

```go-html-template
{{- $cssFiles := slice
  (resources.Get "css/tokens.css")
  (resources.Get "css/reset.css")
  ...
  (resources.Get "css/view-transitions.css")
  (resources.Get "css/custom.css")     {{/* your override, last in cascade */}}
-}}
```

## Add custom icons

Drop SVGs into `assets/icons/<name>.svg`, then reference by name:

```yaml
# data/profile.yaml
links:
  - icon: bluesky
    label: Bluesky
    url: https://bsky.app/profile/...
```

Use `currentColor` for fill/stroke so icons inherit text color in light and dark modes:

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
  <path d="..."/>
</svg>
```

## Self-host fonts

The theme stack is `"Inter", "Be Vietnam Pro", system-ui, ...`. The first two fall back to system fonts when missing. To self-host:

1. Subset Be Vietnam Pro + Inter to `vietnamese,latin` ranges.
2. Drop the woff2 files into `static/fonts/`.
3. Add `@font-face` declarations in `assets/css/custom.css` (see "Override design tokens" above).

```css
@font-face {
  font-family: "Inter";
  src: url("/fonts/Inter-VariableFont_slnt,wght.woff2") format("woff2-variations");
  font-weight: 100 900;
  font-display: swap;
}
@font-face {
  font-family: "Be Vietnam Pro";
  src: url("/fonts/BeVietnamPro-Regular.woff2") format("woff2");
  font-weight: 400;
  font-display: swap;
}
```

## Override colors per-page

Set CSS variables inline via a frontmatter `style` you wire up yourself, or use the `body_class` block from `baseof.html`:

```html
<!-- layouts/section/work.html -->
{{ define "body_class" }}list section-work{{ end }}
```

Then style `body.section-work { --tsuki-accent: #...; }` in your custom CSS.

## Disable features

Every interactive feature has a kill switch:

```yaml
params:
  search:
    enable: false           # removes search button + /search/ route
  comments:
    giscus:
      enable: false         # comments partial becomes a no-op
```

Per-post:
```yaml
toc: false
comments: false
```
