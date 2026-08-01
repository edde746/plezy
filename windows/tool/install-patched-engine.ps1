# Download the published flutter-plezy patched Windows engine (DirectComposition)
# and install it into the active Flutter SDK's artifact cache.
#
# Plezy requires this engine on Windows: it honors the FLUTTER_WINDOWS_DCOMP
# environment variable (set in windows/runner/main.cpp) and presents the Flutter
# UI on a topmost DirectComposition visual, so the mpv video window composites
# *beneath* the UI in a single HWND (window capture works, no transparency
# hacks). On a stock engine the flag is a no-op and compositing breaks.
#
# Used by CI (.github/workflows/build.yml) and by contributors building locally.
# Engine developers who build their own artifacts use swap-engine.ps1 instead.
#
# The flutter tool validates the engine cache by engine.stamp string only (no
# file hashing), so the swap sticks - but `flutter upgrade` /
# `flutter precache --force` silently restore the stock engine; re-run this
# afterwards. Run `flutter precache --windows` once before this script so the
# cache layout and engine.stamp exist.
#
# Usage:
#   flutter precache --windows
#   windows/tool/install-patched-engine.ps1
param(
    # Engine zip published at flutter-plezy release windows-v3.44.0+1 - x64 + arm64
    # (cache dirs windows-{x64,arm64}{,-release}). The asset name is the same across
    # tags, so a version bump only changes the tag segment of the URL.
    [string]$Url = 'https://github.com/edde746/flutter-plezy/releases/download/windows-v3.44.0+1/flutter-plezy-windows-3.44.0.zip',
    [string]$Sha256 = '8de498d28f314c33971226856bea7aa54099e08e60cd7d208cbaf04693dc8274',
    # Engine revision the artifacts were built from. Must match the SDK's
    # engine.stamp (gen_snapshot/dart in the SDK must come from the same
    # checkout), or the swapped binaries are ABI-incompatible with the build.
    [string]$ExpectedEngine = '4c525dac5ebe5971c5708ef73558ed8edcf4a362'
)

$ErrorActionPreference = 'Stop'

$flutterCmd = Get-Command flutter.bat -ErrorAction SilentlyContinue
if (-not $flutterCmd) { $flutterCmd = Get-Command flutter }
$sdkRoot = Split-Path -Parent (Split-Path -Parent $flutterCmd.Source)

$stampPath = Join-Path $sdkRoot 'bin\cache\engine.stamp'
if (-not (Test-Path $stampPath)) {
    Write-Error "engine.stamp not found at $stampPath - run 'flutter precache --windows' first"
}
$stamp = (Get-Content $stampPath -Raw).Trim()
if ($stamp -ne $ExpectedEngine) {
    Write-Error "SDK engine.stamp is $stamp but the patched engine targets $ExpectedEngine - this flutter-plezy build is for a different SDK"
}

$engineDir = Join-Path $sdkRoot 'bin\cache\artifacts\engine'
if (-not (Test-Path $engineDir)) {
    Write-Error "engine cache not found: $engineDir - run 'flutter precache --windows' first"
}

$zip = Join-Path ([System.IO.Path]::GetTempPath()) 'flutter-plezy-windows.zip'

# Invoke-WebRequest renders a per-byte progress bar in Windows PowerShell that
# makes large downloads crawl; silence it.
$ProgressPreference = 'SilentlyContinue'
Write-Output "Downloading patched engine from $Url ..."
Invoke-WebRequest -Uri $Url -OutFile $zip

$actual = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
if ($actual -ne $Sha256.ToLower()) {
    Remove-Item $zip -Force
    Write-Error "SHA256 mismatch: expected $Sha256 but got $actual"
}

# The zip holds top-level windows-x64/ (debug) and windows-x64-release/ folders;
# extracting over the engine dir swaps both cache variants in place.
Write-Output "Extracting patched engine into $engineDir ..."
Expand-Archive -Path $zip -DestinationPath $engineDir -Force
Remove-Item $zip -Force

Write-Output "Installed patched DComp engine (windows-x64, windows-x64-release)."
