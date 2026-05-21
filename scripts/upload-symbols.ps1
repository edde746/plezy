#!/usr/bin/env pwsh
# Usage: upload-symbols.ps1 <platform> [source-root]
# Env: SENTRY_AUTH_TOKEN or BUGS_ADMIN_TOKEN (required unless BUGS_UPLOAD_DRY_RUN is set)
#      SENTRY_URL or BUGS_URL (default https://bugs.plezy.app)
# Platforms: windows-x64 | windows-arm64
param(
    [Parameter(Mandatory = $true)]
    [string]$Platform,
    [string]$SourceRoot
)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$Root = Split-Path -Parent $ScriptDir
Set-Location $Root

if ([string]::IsNullOrEmpty($SourceRoot)) {
    $SearchRoot = $Root
}
elseif ([System.IO.Path]::IsPathRooted($SourceRoot)) {
    $SearchRoot = $SourceRoot
}
else {
    $SearchRoot = [System.IO.Path]::GetFullPath((Join-Path $Root $SourceRoot))
}

$BuildRoot = Join-Path $SearchRoot 'build'
$SymbolRoot = Join-Path (Join-Path $SearchRoot 'debug-info') $Platform
$DryRun = -not [string]::IsNullOrEmpty($env:BUGS_UPLOAD_DRY_RUN)

$SearchRoots = [System.Collections.Generic.List[string]]::new()
function Add-ExistingRoot([string]$Path) {
    if (Test-Path -Path $Path -PathType Container) {
        $SearchRoots.Add($Path)
    }
}

Add-ExistingRoot $SymbolRoot

switch ($Platform) {
    { $_ -eq 'windows-x64' -or $_ -eq 'windows-arm64' } {
        Add-ExistingRoot (Join-Path $BuildRoot 'windows')
    }
    default {
        Write-Error "unknown platform: $Platform"
        exit 2
    }
}

function Has-SymbolFile {
    foreach ($RootPath in $SearchRoots) {
        $First = Get-ChildItem -Path $RootPath -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($null -ne $First) {
            return $true
        }
    }
    return $false
}

if (-not (Has-SymbolFile)) {
    Write-Error "no symbols found for platform $Platform"
    exit 3
}

if ([string]::IsNullOrEmpty($env:SENTRY_URL)) {
    $env:SENTRY_URL = if ([string]::IsNullOrEmpty($env:BUGS_URL)) { 'https://bugs.plezy.app' } else { $env:BUGS_URL }
}

if ([string]::IsNullOrEmpty($env:SENTRY_RELEASE)) {
    $env:SENTRY_RELEASE = "vibe@$(git rev-parse --short HEAD)"
}

if ([string]::IsNullOrEmpty($env:SENTRY_LOG_LEVEL)) {
    $env:SENTRY_LOG_LEVEL = 'info'
}

if ([string]::IsNullOrEmpty($env:SENTRY_AUTH_TOKEN) -and -not [string]::IsNullOrEmpty($env:BUGS_ADMIN_TOKEN)) {
    $env:SENTRY_AUTH_TOKEN = $env:BUGS_ADMIN_TOKEN
}

if (-not $DryRun -and [string]::IsNullOrEmpty($env:SENTRY_AUTH_TOKEN)) {
    Write-Error 'SENTRY_AUTH_TOKEN or BUGS_ADMIN_TOKEN env var required'
    exit 1
}

$DartSymbolMapPath = $env:SENTRY_DART_SYMBOL_MAP_PATH
if ([string]::IsNullOrEmpty($DartSymbolMapPath)) {
    $Candidates = @(
        (Join-Path $SymbolRoot 'obfuscation.map.json'),
        (Join-Path (Join-Path $BuildRoot 'app\obfuscation') "$Platform.map.json"),
        (Join-Path (Join-Path $BuildRoot 'app') 'obfuscation.map.json')
    )

    foreach ($Candidate in $Candidates) {
        if (Test-Path -Path $Candidate -PathType Leaf) {
            $DartSymbolMapPath = $Candidate
            break
        }
    }
}

$PluginArgs = @(
    "--sentry-define=release=$($env:SENTRY_RELEASE)",
    "--sentry-define=url=$($env:SENTRY_URL)",
    "--sentry-define=build_path=$BuildRoot"
)

if (-not [string]::IsNullOrEmpty($env:SENTRY_DIST)) {
    $PluginArgs += "--sentry-define=dist=$($env:SENTRY_DIST)"
}

if (Test-Path -Path $SymbolRoot -PathType Container) {
    $PluginArgs += "--sentry-define=symbols_path=$SymbolRoot"
}

if (-not [string]::IsNullOrEmpty($DartSymbolMapPath)) {
    $PluginArgs += "--sentry-define=dart_symbol_map_path=$DartSymbolMapPath"
}

if ($DryRun) {
    Write-Host "dry-run: would upload symbols for $Platform"
    Write-Host "dry-run: release=$($env:SENTRY_RELEASE)"
    Write-Host "dry-run: dist=$($env:SENTRY_DIST)"
    Write-Host "dry-run: source_root=$SearchRoot"
    Write-Host "dry-run: build_path=$BuildRoot"
    Write-Host "dry-run: symbols_path=$SymbolRoot"
    Write-Host "dry-run: dart_symbol_map_path=$DartSymbolMapPath"
    foreach ($RootPath in $SearchRoots) {
        Get-ChildItem -Path $RootPath -File -Recurse -ErrorAction SilentlyContinue | ForEach-Object { Write-Host $_.FullName }
    }
    exit 0
}

Write-Host "uploading symbols for $Platform release $($env:SENTRY_RELEASE) dist $($env:SENTRY_DIST)"
& dart run sentry_dart_plugin @PluginArgs
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
