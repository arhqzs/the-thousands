# =====================================================================
#  Publish the current www/ to the live GitHub Pages site.
#  GitHub Pages serves the docs/ folder of the main branch, so this
#  copies www/ -> docs/, commits, and pushes. Live ~1 min later at:
#      https://arhqzs.github.io/the-thousands/
# =====================================================================
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot; if (-not $root) { $root = (Get-Location).Path }

Copy-Item "$root\www\*" "$root\docs\" -Recurse -Force
if (-not (Test-Path "$root\docs\.nojekyll")) { New-Item -ItemType File "$root\docs\.nojekyll" | Out-Null }

git -C $root add docs
if (git -C $root status --porcelain docs) {
  git -C $root commit -m "Update live web build"
  git -C $root push
  Write-Host "Pushed. Live in ~1 minute at https://arhqzs.github.io/the-thousands/"
} else {
  Write-Host "docs/ already matches www/ - nothing to publish."
}
