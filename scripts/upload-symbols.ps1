#!/usr/bin/env pwsh
# Usage: upload-symbols.ps1 <platform> [source-root]
# Env: BUGS_ADMIN_TOKEN (required unless BUGS_UPLOAD_DRY_RUN is set), BUGS_URL (default https://bugs.plezy.app)
# Platforms: windows-x64 | windows-arm64
param(
    [Parameter(Mandatory = $true)]
    [string]$Platform,
    [string]$SourceRoot
)

$ErrorActionPreference = 'Stop'

$Token = $env:BUGS_ADMIN_TOKEN
$DryRun = -not [string]::IsNullOrEmpty($env:BUGS_UPLOAD_DRY_RUN)
if (-not $DryRun -and [string]::IsNullOrEmpty($Token)) {
    Write-Error 'BUGS_ADMIN_TOKEN env var required'
    exit 1
}

$Url = if ([string]::IsNullOrEmpty($env:BUGS_URL)) { 'https://bugs.plezy.app' } else { $env:BUGS_URL }

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
    $SearchRoot = Join-Path $Root $SourceRoot
}

$Release = "plezy@$(git rev-parse --short HEAD)"
$Stage = New-Item -ItemType Directory -Path ([System.IO.Path]::GetTempPath()) -Name ([System.IO.Path]::GetRandomFileName()) -Force
$Zip = $null

try {
    $DebugInfoDir = Join-Path $SearchRoot "debug-info\$Platform"
    if (Test-Path $DebugInfoDir) {
        Copy-Item -Path "$DebugInfoDir\*" -Destination $Stage -Recurse -Force
    }

    switch ($Platform) {
        { $_ -eq 'windows-x64' -or $_ -eq 'windows-arm64' } {
            $Arch = $Platform -replace '^windows-', ''
            $PdbRoot = Join-Path $SearchRoot "build\windows\$Arch\runner\Release"
            if (Test-Path $PdbRoot) {
                Get-ChildItem -Path $PdbRoot -Filter '*.pdb' -Recurse | ForEach-Object {
                    Copy-Item $_.FullName -Destination $Stage -Force
                }
            }
        }
        default {
            Write-Error "unknown platform: $Platform"
            exit 2
        }
    }

    $Files = Get-ChildItem -Path $Stage -File -Recurse
    if (-not $Files) {
        Write-Error "no symbols found for platform $Platform"
        exit 3
    }

    if ($DryRun) {
        Write-Host "dry-run: would upload $($Files.Count) symbol file(s) for $Platform release $Release"
        $Files | ForEach-Object { Write-Host "dry-run: $_" }
        return
    }

    $Zip = Join-Path ([System.IO.Path]::GetTempPath()) "symbols-$([System.IO.Path]::GetRandomFileName()).zip"
    Compress-Archive -Path (Join-Path $Stage '*') -DestinationPath $Zip -Force

    $Headers = @{ 'Authorization' = "Bearer $Token" }
    $Form = @{
        file    = Get-Item $Zip
        release = $Release
    }

    Invoke-RestMethod -Method Post -Uri "$Url/api/0/projects/plezy/plezy/files/dsyms/" `
        -Headers $Headers -Form $Form
}
finally {
    Remove-Item -Path $Stage -Recurse -Force -ErrorAction SilentlyContinue
    if ($Zip -and (Test-Path $Zip)) {
        Remove-Item -Path $Zip -Force -ErrorAction SilentlyContinue
    }
}
