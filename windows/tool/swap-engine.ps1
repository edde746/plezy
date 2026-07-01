# Swap the flutter-plezy custom Windows engine into the Flutter SDK's artifact
# cache (or restore stock). See flutter-plezy's README for how the artifacts
# are built.
#
# The flutter tool validates the cache by stamp STRING only (no file hashing),
# so swapped files stick - but `flutter upgrade` / `flutter precache --force`
# silently restore stock; re-run this script afterwards.
#
# Usage:
#   swap-engine.ps1 -Mode debug   -Zip C:\path\to\windows-x64-flutter.zip
#   swap-engine.ps1 -Mode release -Zip ...
#   swap-engine.ps1 -Mode debug -Restore
param(
    [ValidateSet('debug', 'release')][string]$Mode = 'debug',
    [string]$Zip,
    [switch]$Restore,
    # Engine revision these artifacts were built from. Guards against swapping
    # into a mismatched SDK (gen_snapshot/dart must come from the same checkout).
    [string]$ExpectedEngine = '4c525dac5ebe5971c5708ef73558ed8edcf4a362'
)

$ErrorActionPreference = 'Stop'

$flutterCmd = Get-Command flutter.bat -ErrorAction SilentlyContinue
if (-not $flutterCmd) { $flutterCmd = Get-Command flutter }
$sdkRoot = Split-Path -Parent (Split-Path -Parent $flutterCmd.Source)

$stamp = (Get-Content (Join-Path $sdkRoot 'bin\cache\engine.stamp') -Raw).Trim()
if ($stamp -ne $ExpectedEngine) {
    Write-Error "SDK engine.stamp is $stamp but artifacts target $ExpectedEngine - rebuild flutter-plezy for this SDK first"
}

$cacheDir = if ($Mode -eq 'debug') { 'windows-x64' } else { 'windows-x64-release' }
$target = Join-Path $sdkRoot "bin\cache\artifacts\engine\$cacheDir"
if (-not (Test-Path $target)) { Write-Error "cache dir not found: $target (run 'flutter precache --windows')" }
$backup = "$target.stock-backup"

if ($Restore) {
    if (-not (Test-Path $backup)) { Write-Error "no backup at $backup - nothing to restore" }
    Get-ChildItem $backup -File | ForEach-Object { Copy-Item $_.FullName $target -Force }
    Write-Output "restored stock engine into $target"
    return
}

if (-not $Zip -or -not (Test-Path $Zip)) { Write-Error "pass -Zip <windows-x64-flutter.zip> (from flutter-plezy out\<v>\host_*\zip_archives\ or a Release)" }

# One-time backup of the stock files we are about to overwrite.
if (-not (Test-Path $backup)) {
    New-Item -ItemType Directory $backup | Out-Null
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $entries = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path $Zip)).Entries | ForEach-Object { $_.FullName }
    foreach ($name in $entries) {
        $orig = Join-Path $target $name
        if (Test-Path $orig) { Copy-Item $orig $backup -Force }
    }
    Write-Output "stock files backed up to $backup"
}

Expand-Archive $Zip -DestinationPath $target -Force
Write-Output "swapped $(Split-Path $Zip -Leaf) into $target"
Write-Output "NOTE: re-run after 'flutter upgrade' or 'flutter precache --force'."
