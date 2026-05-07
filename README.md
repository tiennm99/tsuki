# tsuki (月)

[![build](https://github.com/tiennm99/tsuki/actions/workflows/pages.yml/badge.svg)](https://github.com/tiennm99/tsuki/actions/workflows/pages.yml)
[![license](https://img.shields.io/github/license/tiennm99/tsuki)](LICENSE)
[![Hugo](https://img.shields.io/badge/hugo-%E2%89%A50.146-ff4088?logo=hugo)](https://gohugo.io)

A Hugo blog + personal portfolio theme. The homepage *is* the portfolio — bio, featured projects, recent posts. Posts live at `/post/`. Vietnamese-first typography, View Transitions on navigation, Pagefind search, Giscus comments.

> 月 (*tsuki*): the moon. Quiet, observed, returned to. Companion to [`bonsai`](https://github.com/tiennm99/bonsai) in the same naming family.

**→ [Live demo](https://tiennm99.github.io/tsuki/)**

## Status

`v0.1.0` — initial release. See [CHANGELOG.md](CHANGELOG.md).

## Features

- **Blog** — posts, tags, categories, year-grouped archive, paginated post list
- **Personal portfolio on the homepage** — driven by `data/profile.yaml` + `data/projects.yaml`, no separate `/portfolio` section
- **Search** — [Pagefind](https://pagefind.app), zero-runtime, indexed at build time
- **Comments** — [Giscus](https://giscus.app) (GitHub Discussions)
- **Vietnamese-first** — diacritic-safe typography, native vi date formats, ASCII heading IDs
- **Dark mode** — `prefers-color-scheme` + persistent toggle, no flash of wrong theme
- **View Transitions API** — smooth same-document navigation in supporting browsers
- **Table of contents** — auto-mounted on long posts, sticky on wide viewports, IntersectionObserver active highlight
- **No build step** — pure Hugo + browser ES modules. No SCSS, no TypeScript, no bundler in the theme
- **Light** — CSS ≤ 4 KB gz, JS ≤ 1 KB gz (excluding Pagefind UI)

## Quick start

### As a git submodule

```bash
git submodule add https://github.com/tiennm99/tsuki.git themes/tsuki
```

Add to your site's `hugo.yaml`:

```yaml
theme: tsuki
```

### As a Hugo Module

```bash
hugo mod init github.com/<you>/<your-site>
hugo mod get github.com/tiennm99/tsuki
```

Then add to `hugo.yaml`:

```yaml
module:
  imports:
    - path: github.com/tiennm99/tsuki
```

## Configuration

Add the required keys to your site's `hugo.yaml`:

```yaml
theme: tsuki
languageCode: vi
defaultContentLanguage: vi

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
      autoHeadingIDType: github-ascii
  tableOfContents:
    startLevel: 2
    endLevel: 4
```

Then drop `data/profile.yaml` and `data/projects.yaml` into your site (see [`docs/data-schemas.md`](docs/data-schemas.md)).

Hugo doesn't deep-merge nested config from themes — settings above belong in your *site* `hugo.yaml`. The `exampleSite/hugo.yaml` is a complete working example.

## Documentation

- [`docs/config.md`](docs/config.md) — full params reference
- [`docs/data-schemas.md`](docs/data-schemas.md) — `profile.yaml` + `projects.yaml`
- [`docs/customization.md`](docs/customization.md) — override layouts, tokens, fonts
- [`docs/migrating-from-stack.md`](docs/migrating-from-stack.md) — for users coming from `hugo-theme-stack`

## Search and comments

Search uses Pagefind, built in CI via `npx pagefind --site public` after Hugo. Pinned in `package.json`; bumps via Dependabot. No runtime dependency.

Comments use Giscus. Generate config at [giscus.app](https://giscus.app) and add to `params.comments.giscus.*` to enable. Defaults to off.

## Browser support

Modern evergreen browsers. View Transitions and `:has()` are progressive enhancements; the theme remains functional without them.

## License

[Apache-2.0](LICENSE)
