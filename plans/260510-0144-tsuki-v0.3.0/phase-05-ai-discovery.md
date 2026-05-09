---
phase: 5
title: "AI/discovery — llm.txt + Speculation Rules"
status: pending
priority: P2
effort: "0.5d"
dependencies: [2]
---

# Phase 5: AI/discovery

## Overview

Two additive 2026-platform features: (1) auto-generated `/llm.txt` artifact in exampleSite to guide AI crawler indexing per the emerging llmstxt.org spec; (2) optional Speculation Rules opt-in via `params.prefetch.enable` for Chromium-based prefetch/prerender of internal links.

## Context Links

- Source: `plans/reports/researcher-260510-0144-hugo-theme-2026-evolution.md` (Tier 1: llm.txt, Speculation Rules)
- Spec: https://llmstxt.org (llm.txt format)
- Spec: https://wicg.github.io/nav-speculation/speculation-rules.html

## Requirements

- Functional: `exampleSite/public/llm.txt` exists post-build with theme metadata; Speculation Rules emit only when `params.prefetch.enable: true`
- Non-functional: zero JS additions; no CSS additions; backwards compatible (both off by default)

## Key Insights

- llm.txt is a static text file derived from `data/profile.yaml` + theme metadata + recent posts. Hugo can generate it via custom output format.
- Speculation Rules ship as `<script type="speculationrules">{...}</script>` in `<head>`. Chromium-only. Graceful no-op on Safari/Firefox.
- Both features should be **opt-in** to respect users on metered connections / privacy-conscious AI policy.

## Architecture

### llm.txt
- Add `[outputFormats.LlmTxt]` + `[mediaTypes."text/plain"]` to demo `hugo.yaml`
- Add `outputs.home: ["HTML", "RSS", "LlmTxt"]` to demo `hugo.yaml`
- Create `layouts/index.llmtxt.txt` — Hugo template emitting plain text per llmstxt.org spec
- Theme exposes default; site can override with own `index.llmtxt.txt`

### Speculation Rules
- Gated in `head.html`: `{{ with site.Params.prefetch }}{{ if .enable }}<script type="speculationrules">{...JSON...}</script>{{ end }}{{ end }}`
- Default JSON: `{"prefetch":[{"source":"document","where":{"and":[{"href_matches":"/*"},{"not":{"href_matches":"/search/*"}}]},"eagerness":"moderate"}]}`
- Allow override via `params.prefetch.rules` (raw JSON string consumer can inject)

## Related Code Files

- Create: `layouts/index.llmtxt.txt` (in theme, optional override)
- Modify: `exampleSite/hugo.yaml` (output format + outputs.home)
- Modify: `layouts/_partials/head.html` (Speculation Rules emit gate)
- Modify: `docs/config.md` (document `params.prefetch.{enable,rules}`)
- Modify: `docs/customization.md` (document llm.txt override path)
- Modify: `CHANGELOG.md`
- Modify: `scripts/smoke-tests.sh` (assert llm.txt present + speculationrules script absent by default)

## Implementation Steps

1. Define output format in demo `hugo.yaml`:
   ```yaml
   outputFormats:
     LlmTxt:
       mediaType: "text/plain"
       baseName: "llm"
       isPlainText: true
   outputs:
     home: ["HTML", "RSS", "LlmTxt"]
   ```
2. Write `layouts/index.llmtxt.txt`:
   - `# {{ site.Title }}` + tagline from `data/profile.yaml`
   - `> {{ .Site.Params.description }}`
   - `## About` block from `data/profile.yaml: bio`
   - `## Recent posts` — top 10 `site.RegularPages | first 10`, each as `- [{{ .Title }}]({{ .Permalink }}): {{ .Description | default .Summary | plainify }}`
   - `## Projects` from `data/projects.yaml`
3. Build demo, confirm `exampleSite/public/llm.txt` exists and is valid plain text.
4. Add Speculation Rules emit in `head.html` gated on `params.prefetch.enable`. Write minimal default JSON + allow `params.prefetch.rules` raw string override.
5. Add `params.prefetch` block to `docs/config.md` with example + browser-support note.
6. Local test: enable in demo `hugo.yaml`, confirm `<script type="speculationrules">` in HTML. Disable, confirm absent.
7. Smoke test additions: assert `exampleSite/public/llm.txt` exists; assert NO `speculationrules` in default demo build (since opt-in).
8. CHANGELOG: Added — llm.txt output format, Speculation Rules opt-in.

## Todo List

- [ ] Output format declared in demo hugo.yaml
- [ ] layouts/index.llmtxt.txt template written
- [ ] Demo build emits valid /llm.txt
- [ ] Speculation Rules gated emit in head.html
- [ ] params.prefetch documented in config.md
- [ ] llm.txt override documented in customization.md
- [ ] Smoke test assertions added
- [ ] CHANGELOG entries

## Success Criteria

- [ ] `curl https://tiennm99.github.io/tsuki/llm.txt` returns 200 + valid text on next deploy
- [ ] `<script type="speculationrules">` absent from default build
- [ ] `<script type="speculationrules">` present when `params.prefetch.enable: true` set in demo
- [ ] No CSS or JS bundle increase
- [ ] Documentation describes consumer override paths

## Risk Assessment

- **llm.txt spec churn:** llmstxt.org is unstable as of 2026. Mitigation: stay close to the minimal sketch; consumers with strong preferences can override `index.llmtxt.txt`.
- **Speculation Rules misfire:** prefetch on metered networks. Mitigation: opt-in default off; document responsibly.
- **AI policy concerns:** maintainers may not want their content easily indexed by AI. Mitigation: llm.txt is standard *guidance*, not directive; consumers can write their own block list.

## Security Considerations

- llm.txt exposes only already-public content (titles, summaries)
- Speculation Rules use `eagerness: moderate` (not `eager`) to balance perf vs bandwidth

## Next Steps

- Phase 6 smoke tests assert both features behave per gate
