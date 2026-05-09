#!/usr/bin/env bash
# tsuki theme post-build smoke tests
# Run after hugo build of exampleSite to assert key features still emit.
# Usage: scripts/smoke-tests.sh [<public-dir>]
# Default <public-dir>: exampleSite/public

set -euo pipefail

public_dir="${1:-exampleSite/public}"
fail=0

assert() {
  local label="$1" pattern="$2" file="$3" min="${4:-1}"
  local count
  count=$(grep -cE "$pattern" "$file" 2>/dev/null || true)
  if [ "$count" -lt "$min" ]; then
    echo "::error file=$file::FAIL [$label] expected ≥${min} matches of /$pattern/, got ${count}"
    fail=1
  else
    echo "  ok   [$label] ${count} match(es) in ${file##$public_dir/}"
  fi
}

[ -d "$public_dir" ] || { echo "::error::Public dir not found: $public_dir"; exit 2; }

# Pick a known leaf post (any 2026 post will do).
post=$(find "$public_dir" -name 'index.html' -path '*/2026/*' -not -path '*/page/*' | head -1 || true)
[ -n "$post" ] || { echo "::error::No demo post HTML found under $public_dir"; exit 2; }
home="$public_dir/index.html"
[ -f "$home" ] || { echo "::error::No home HTML at $home"; exit 2; }

echo "Smoke testing tsuki build:"
echo "  home: $home"
echo "  post: $post"
echo

# SEO (Phase 3)
assert "JSON-LD on post"     '<script type=application/ld\+json>'           "$post"
assert "no JSON-LD on home"  '<script type=application/ld\+json>'           "$home" 0
assert "OG image emits"      '<meta property="og:image"'                    "$post"
assert "Twitter image emits" '<meta name=twitter:image'                     "$post"
assert "OG locale emits"     '<meta property="og:locale"'                   "$post"

# Accessibility (Phase 2)
assert "skip-link present"   'class=skip-link'                              "$home"
assert "main id anchor"      '<main id=main>'                               "$home"

# Render-link hook (Phase 2): scan all post HTML for at least one external rel marker.
# Pipeline guarded — `grep -r` exits 1 on zero matches; `set -o pipefail` would kill the script.
rel_count=$({ grep -roE 'rel="noopener noreferrer"' "$public_dir" --include='index.html' || true; } | wc -l)
if [ "$rel_count" -lt 1 ]; then
  echo "::error::FAIL [render-link rel] expected ≥1 'rel=\"noopener noreferrer\"' across built HTML, got 0 — demo posts may have lost their external links"
  fail=1
else
  echo "  ok   [render-link rel] ${rel_count} match(es) across $public_dir"
fi

# Author UX (Phase 4)
assert "reading time byline" 'reading-time'                                 "$post"

# Discovery (Phase 5)
assert "related-posts aside" 'class=related-posts'                          "$post"

# CSS budget (Phase 1) — duplicates the workflow assert; included so local runs catch it too.
css=$(find "$public_dir" -name 'tsuki.bundle.*.css' -print -quit || true)
if [ -n "$css" ]; then
  sz=$(gzip -9 -c "$css" | wc -c)
  if [ "$sz" -gt 4200 ]; then
    echo "::error::CSS bundle gz ${sz} B exceeds 4200 B budget"
    fail=1
  else
    echo "  ok   [CSS budget] ${sz} B / 4200 B"
  fi
else
  echo "::error::Could not locate tsuki.bundle.*.css"
  fail=1
fi

echo
[ "$fail" -eq 0 ] && echo "All smoke tests passed." || echo "Smoke tests failed."
exit "$fail"
