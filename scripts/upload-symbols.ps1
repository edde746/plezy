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
    & dart run scripts/upload_symbols.dart $Platform
}
else {
    & dart run scripts/upload_symbols.dart $Platform $SourceRoot
}
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
