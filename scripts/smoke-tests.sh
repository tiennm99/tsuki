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

# v0.3.0 feature surface
assert "theme-color meta (light)"  'name=theme-color content="#fbfaf7"'      "$home"
assert "theme-color meta (dark)"   'name=theme-color content="#14151a"'      "$home"
assert "aria-pressed SSR"          'data-theme-toggle [^>]*aria-pressed=false|aria-pressed=false [^>]*data-theme-toggle' "$home"
assert "breadcrumbs nav on post"   'class=breadcrumbs'                       "$post"
assert "BreadcrumbList JSON-LD"    '"@type":"BreadcrumbList"'                "$post"
assert "no breadcrumbs on home"    'class=breadcrumbs'                       "$home" 0
assert "prev/next nav"             'class=prev-next'                         "$post"
assert "rel=prev on post"          'rel=prev'                                "$post"
assert "linkToSection aria-label"  'class=heading-anchor [^>]*aria-label'    "$post"
assert "no speculationrules by default"  'speculationrules'                  "$home" 0

# llm.txt artifact
if [ -f "$public_dir/llm.txt" ]; then
  echo "  ok   [llm.txt artifact present]"
else
  echo "::error::FAIL [llm.txt artifact present] expected $public_dir/llm.txt"
  fail=1
fi

# Pagefind preload-swap on search (rel=preload as=style)
if [ -f "$public_dir/search/index.html" ]; then
  assert "Pagefind preload swap" 'rel=preload as=style href=[^ >]*pagefind' "$public_dir/search/index.html"
fi

# Giscus preconnect: comments disabled in demo → must NOT emit
assert "no giscus preconnect (disabled)" 'preconnect[^>]*giscus' "$post" 0

# Per-page CSS bundle gating: home gets home.css, post does NOT
assert "home loads home.css"  'home\.min\.[0-9a-f]+\.css' "$home"
assert "post does not load home.css" 'home\.min\.[0-9a-f]+\.css' "$post" 0
assert "post loads single.css" 'tsuki\.single\.min\.[0-9a-f]+\.css' "$post"
assert "home does not load single.css" 'tsuki\.single\.min\.[0-9a-f]+\.css' "$home" 0

# code-copy.js gate: only post pages should load it
assert "post loads code-copy.js" 'code-copy\.[0-9a-f]+\.js' "$post"
assert "home does not load code-copy.js" 'code-copy\.[0-9a-f]+\.js' "$home" 0

# Per-kind CSS budget — every page kind's total stylesheet payload ≤ 4200 B gz.
# Iterate over each kind's representative HTML, extract its <link rel=stylesheet> CSS,
# sum gzipped sizes (excluding third-party like /pagefind/), assert each kind under budget.
check_kind_css_budget() {
  local label="$1" html="$2"
  [ -f "$html" ] || { echo "  skip [$label CSS budget] no HTML at $html"; return; }
  local total=0 missing=0
  while IFS= read -r href; do
    # strip query string + leading slash + baseURL prefix
    local rel="${href#/tsuki/}"
    rel="${rel#/}"
    local fpath="$public_dir/$rel"
    if [ -f "$fpath" ]; then
      local sz
      sz=$(gzip -9 -c "$fpath" | wc -c)
      total=$((total + sz))
    else
      missing=$((missing + 1))
    fi
  done < <(grep -oE 'rel=stylesheet href=[^ >]+\.css' "$html" | grep -v '/pagefind/' | sed -E 's|rel=stylesheet href=||')
  if [ "$total" -gt 4200 ]; then
    echo "::error::[$label CSS budget] ${total} B gz exceeds 4200 B"
    fail=1
  else
    echo "  ok   [$label CSS budget] ${total} B / 4200 B (${missing} third-party skipped)"
  fi
}

# Pick representative HTML per kind from the build.
list_html="$public_dir/post/index.html"
search_html="$public_dir/search/index.html"
archives_html="$public_dir/archives/index.html"

check_kind_css_budget "home"     "$home"
check_kind_css_budget "post"     "$post"
[ -f "$list_html" ]     && check_kind_css_budget "list"     "$list_html"
[ -f "$archives_html" ] && check_kind_css_budget "archives" "$archives_html"
[ -f "$search_html" ]   && check_kind_css_budget "search"   "$search_html"

echo
[ "$fail" -eq 0 ] && echo "All smoke tests passed." || echo "Smoke tests failed."
exit "$fail"
