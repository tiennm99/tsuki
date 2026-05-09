---
title: tsuki v0.2.1 — patch release for post-v0.2.0 review P1s
status: code-complete
created: 2026-05-10
target: v0.2.1 tag, ~1d effort
implementation_landed: 2026-05-10
review_score: 9.7/10
validation: "11/11 smoke tests, CSS budget 3962/4200, Hugo 0.154 build clean"
predecessor: plans/260509-0947-v0.2.0-prerelease-checklist/
blockedBy: [260509-0947-v0.2.0-prerelease-checklist]
blocks: [260510-0144-tsuki-v0.3.0]
source_brainstorm: plans/reports/brainstorm-260510-0144-post-v0.2.0-direction.md
source_review: plans/reports/code-reviewer-260510-0144-tsuki-v0.2.0-post-release-improvements.md
---

# tsuki v0.2.1 patch

Surgical patch closing 5 P1 correctness/security findings from the post-v0.2.0 fresh-eyes review, plus 2 CI hygiene items. ~1 day. No new features.

If shipped, marks v0.3.0 Phase 1 (`260510-0144-tsuki-v0.3.0/phase-01-v0.2.1-carry.md`) as completed.

## Scope

Identical to v0.3.0 Phase 1. See that phase file for detailed implementation steps, todo list, and success criteria. This plan exists to track v0.2.1 as its own release deliverable; do not duplicate the content.

**Reference:** `plans/260510-0144-tsuki-v0.3.0/phase-01-v0.2.1-carry.md`

## Workflow

1. Branch from `main` post v0.2.0 tag: `git checkout -b release/v0.2.1`
2. Apply fixes per Phase 1 implementation steps 1–9
3. Local build + smoke test verification
4. PR → main → merge
5. Tag `v0.2.1` annotated, release notes from CHANGELOG `[Unreleased]` (promote to `[0.2.1]`)
6. Mark v0.3.0 Phase 1 completed in `260510-0144-tsuki-v0.3.0/plan.md`

## Success criteria

- All 5 P1 fixes shipped (P1-1..P1-5 from review report)
- htmltest-action pinned to commit SHA
- Dead `if find` Pagefind branch removed
- CI green on tagged commit
- gohugoThemes registry submission unaffected (v0.2.0 PR continues to track v0.2.0 tag; v0.2.1 follows separately)

## Unresolved questions

1. Goldmark `unsafe: true` keep or drop — affects P1-1 fix shape. Defer per maintainer call; Phase 1 currently uses option B (drop `safeHTML` from link text, keep `unsafe: true`).
2. `data/profile.yaml: url` — document or remove. Defer; current Phase 1 plan documents it.
