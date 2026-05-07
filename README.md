# tsuki (月)

[![build](https://github.com/tiennm99/tsuki/actions/workflows/pages.yml/badge.svg)](https://github.com/tiennm99/tsuki/actions/workflows/pages.yml)
[![license](https://img.shields.io/github/license/tiennm99/tsuki)](LICENSE)
[![Hugo](https://img.shields.io/badge/hugo-%E2%89%A50.146-ff4088?logo=hugo)](https://gohugo.io)

A Hugo blog + personal portfolio theme. The homepage *is* the portfolio — bio, featured projects, recent posts. Posts live at `/post/`. Vietnamese-first typography, View Transitions on navigation, Pagefind search, Giscus comments.

> 月 (*tsuki*): the moon. Quiet, observed, returned to. Companion to [`bonsai`](https://github.com/tiennm99/bonsai) in the same naming family.

**→ [Live demo](https://tiennm99.github.io/tsuki/)** (after first deploy)

## Status

🚧 **Under construction** — initial scaffold. See [the implementation plan](https://github.com/tiennm99/miti99/tree/main/plans) for what's coming.

## Features

- **Blog** — posts, tags, categories, year-grouped archive
- **Personal portfolio on the homepage** — driven by `data/profile.yaml` + `data/projects.yaml`, no separate `/portfolio` section
- **Search** — [Pagefind](https://pagefind.app), zero-runtime, indexed at build time
- **Comments** — [Giscus](https://giscus.app) (GitHub Discussions)
- **Vietnamese-first** — diacritic-safe typography, native vi date formats, Be Vietnam Pro fallback
- **Dark mode** — `prefers-color-scheme` + persistent toggle, no flash of wrong theme
- **View Transitions API** — smooth same-document navigation in supporting browsers
- **No build step** — pure Hugo + browser ES modules. No SCSS, no TypeScript, no bundler in the theme.
- **Light** — target ≤ 15 KB CSS gzipped, ≤ 8 KB JS gzipped (excluding Pagefind UI)

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

Documented in [`docs/config.md`](docs/config.md) (coming soon). For now, see `exampleSite/hugo.yaml` and `exampleSite/data/`.

## License

[Apache-2.0](LICENSE)
