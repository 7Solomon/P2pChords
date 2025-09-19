param([Parameter(Mandatory=$true)][string]$version)

git pull --rebase
git tag -a "v$version" -m "Release v$version"
git push origin "v$version"

Write-Host "Tag v$version pushed. GitHub Actions will build APK and installer, then publish a Release."