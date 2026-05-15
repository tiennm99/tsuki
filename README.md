# tsuki (月)

[![build](https://github.com/tiennm99/tsuki/actions/workflows/pages.yml/badge.svg)](https://github.com/tiennm99/tsuki/actions/workflows/pages.yml)
[![license](https://img.shields.io/github/license/tiennm99/tsuki)](LICENSE)
[![Hugo](https://img.shields.io/badge/hugo-%E2%89%A50.146-ff4088?logo=hugo)](https://gohugo.io)
[![CSS](https://img.shields.io/badge/CSS-%E2%89%A44KB%20gz-blue)](https://github.com/tiennm99/tsuki/actions/workflows/pages.yml)
[![a11y](https://img.shields.io/badge/a11y-WCAG%202.2%20AA-success)](docs/accessibility.md)

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

```bash
git submodule add https://github.com/tiennm99/tsuki.git themes/tsuki
echo 'theme: tsuki' >> hugo.yaml
```

Full installation guide (submodule, Hugo Module, Pagefind setup, required site config): [`docs/installation.md`](docs/installation.md).

`exampleSite/hugo.yaml` is a complete working example.

## Documentation

- [`docs/installation.md`](docs/installation.md) — submodule + Hugo Module + Pagefind setup
- [`docs/config.md`](docs/config.md) — full params reference
- [`docs/data-schemas.md`](docs/data-schemas.md) — `profile.yaml` + `projects.yaml`
- [`docs/customization.md`](docs/customization.md) — override layouts, tokens, fonts, callouts
- [`docs/migrating-from-stack.md`](docs/migrating-from-stack.md) — for users coming from `hugo-theme-stack`

## Search and comments

Search uses Pagefind, built post-Hugo via `npx pagefind --site public`. tsuki pins Pagefind in its own `package.json` for submodule consumers; Hugo Module consumers install Pagefind in their own site (see [`docs/installation.md`](docs/installation.md)). No runtime dependency.

Comments use Giscus. Generate config at [giscus.app](https://giscus.app) and add to `params.comments.giscus.*` to enable. Defaults to off.

## Browser support

Modern evergreen browsers. View Transitions and `:has()` are progressive enhancements; the theme remains functional without them.

## License

[Apache-2.0](LICENSE)
