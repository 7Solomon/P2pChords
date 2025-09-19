param([Parameter(Mandatory=$true)][string]$version)

$tag = "v$version"

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
  Write-Error "GitHub CLI not found. Install: winget install GitHub.cli"
  exit 1
}

# Delete GitHub Release (ignore if missing)
gh release delete $tag -y 2>$null

# Delete remote tag (ignore if missing)
git push origin :refs/tags/$tag 2>$null

# Delete local tag (ignore if missing)
git tag -d $tag 2>$null

Write-Host "Deleted release and tag $tag."