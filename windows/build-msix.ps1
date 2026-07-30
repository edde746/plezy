#!/usr/bin/env pwsh
# Windows Store (MSIX) Build Script
# Packs the per-arch Flutter Release output into one dual-architecture
# .msixbundle for Microsoft Store submission. Purely additive: the Inno Setup
# installer, the portable archives and the WinSparkle appcast are untouched.
#
# Nothing here signs the bundle. The Store re-signs after certification, and a
# package signed with any other certificate fails publisher-identity validation.

param(
    [string]$OutputDir = ".",
    [string]$Version = "1.0.0",
    [string]$X64BuildDir,
    [string]$Arm64BuildDir,
    # Write the generated AppxManifest.xml files and stop, so they can be
    # inspected without the Windows SDK or a populated Flutter build output.
    # scripts/check_windows_msix.py parses the template rather than running
    # this: root CI is Linux, where PowerShell cannot be assumed.
    [switch]$EmitManifestOnly
)

function ConvertTo-MsixVersion {
    param([Parameter(Mandatory)][string]$Version)

    # The Store reserves the fourth (revision) field, so pubspec's
    # major.minor.patch+build maps to major.minor.patch.0 and the build number
    # is dropped. Two releases differing only by build number therefore collide
    # in the Store: every submission needs a semver bump.
    $Semver = ($Version -split '\+')[0]
    if ($Semver -notmatch '^\d+\.\d+\.\d+$') {
        throw "Version must be major.minor.patch, optionally with +build metadata; got '$Version'"
    }
    return "$Semver.0"
}

function New-AppxManifest {
    param(
        [Parameter(Mandatory)][string]$MsixVersion,
        [Parameter(Mandatory)][string]$Architecture
    )

    # Copied verbatim from the reserved product's identity page in Partner
    # Center; Store validation rejects the upload if any of the three differs by
    # a single character. Together they yield package family name
    # edde746.Plezy_13q3sv6jzathm. Identity/@Name is also constrained to
    # '[-.A-Za-z0-9]+' by the schema, so it can never carry an underscore.
    $IdentityName = "edde746.Plezy"
    $Publisher = "CN=AA9C53CB-AD3C-48DA-B3E3-D1E8986D4E25"
    $PublisherDisplayName = "edde746"

    # One template for both architectures, which can therefore not drift apart;
    # ProcessorArchitecture is the only difference between them.
    #
    # Child element order is fixed by the foundation schema and makeappx
    # rejects a reordered manifest: Identity, Properties, Resources,
    # Dependencies, Capabilities, Applications. Resources sitting before
    # Dependencies is the opposite of what older Visual Studio UWP templates
    # used - do not tidy it.
    #
    # runFullTrust is restricted (hence rescap) and standard for a packaged
    # Win32 app. privateNetworkClientServer is what covers LAN media servers:
    # a full-trust package is not AppContainer-isolated, but certification
    # looks for declared network intent.
    return @"
<?xml version="1.0" encoding="utf-8"?>
<Package xmlns="http://schemas.microsoft.com/appx/manifest/foundation/windows10"
         xmlns:uap="http://schemas.microsoft.com/appx/manifest/uap/windows10"
         xmlns:rescap="http://schemas.microsoft.com/appx/manifest/foundation/windows10/restrictedcapabilities"
         IgnorableNamespaces="uap rescap">

  <Identity Name="$IdentityName"
            Publisher="$Publisher"
            Version="$MsixVersion"
            ProcessorArchitecture="$Architecture" />

  <Properties>
    <DisplayName>Plezy</DisplayName>
    <PublisherDisplayName>$PublisherDisplayName</PublisherDisplayName>
    <Logo>assets\StoreLogo.png</Logo>
  </Properties>

  <Resources>
    <Resource Language="en-us" />
  </Resources>

  <Dependencies>
    <TargetDeviceFamily Name="Windows.Desktop"
                        MinVersion="10.0.17763.0"
                        MaxVersionTested="10.0.26100.0" />
  </Dependencies>

  <Capabilities>
    <rescap:Capability Name="runFullTrust" />
    <Capability Name="internetClient" />
    <Capability Name="privateNetworkClientServer" />
  </Capabilities>

  <Applications>
    <Application Id="Plezy" Executable="plezy.exe" EntryPoint="Windows.FullTrustApplication">
      <uap:VisualElements DisplayName="Plezy"
                          Description="A modern client for Plex and Jellyfin"
                          BackgroundColor="transparent"
                          Square150x150Logo="assets\Square150x150Logo.png"
                          Square44x44Logo="assets\Square44x44Logo.png">
        <uap:DefaultTile Wide310x150Logo="assets\Wide310x150Logo.png"
                         Square310x310Logo="assets\Square310x310Logo.png" />
        <uap:SplashScreen Image="assets\SplashScreen.png" />
      </uap:VisualElements>
    </Application>
  </Applications>
</Package>
"@
}

function Write-Utf8File {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Content
    )

    # The manifest declares encoding="utf-8", and Out-File -Encoding utf8
    # writes a BOM on Windows PowerShell but not on pwsh 7. Write the bytes
    # directly so the manifest is identical whichever host runs this script.
    [System.IO.File]::WriteAllText($Path, $Content, (New-Object System.Text.UTF8Encoding($false)))
}

function Invoke-SdkTool {
    param(
        [Parameter(Mandatory)][string]$Tool,
        [Parameter(Mandatory)][string[]]$Arguments
    )

    # $ErrorActionPreference does not apply to native executables, so every SDK
    # tool call goes through this one checked invocation.
    & $Tool @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$(Split-Path -Leaf $Tool) $($Arguments -join ' ') failed with exit code $LASTEXITCODE"
    }
}

$ErrorActionPreference = "Stop"

Write-Host "Building Windows Store package..." -ForegroundColor Cyan

# Ensure we're in the project root
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
Set-Location $ProjectRoot

$ResolvedOutput = Resolve-Path $OutputDir
$MsixVersion = ConvertTo-MsixVersion -Version $Version
Write-Host "Package version: $MsixVersion" -ForegroundColor Green

# Unlike the installer's setup.iss, the manifest does not vary with which
# architectures were built, so the inspection path always emits both.
if ($EmitManifestOnly) {
    Write-Host "`nGenerating manifests only..." -ForegroundColor Cyan
    foreach ($Architecture in @("x64", "arm64")) {
        $EmittedManifest = Join-Path $ResolvedOutput "AppxManifest.$Architecture.xml"
        Write-Utf8File -Path $EmittedManifest `
            -Content (New-AppxManifest -MsixVersion $MsixVersion -Architecture $Architecture)
        Write-Host "Created: $EmittedManifest" -ForegroundColor Green
    }
    exit 0
}

# Auto-detect build dirs from default Flutter output paths if not provided
if (-not $X64BuildDir -and (Test-Path "build\windows\x64\runner\Release")) {
    $X64BuildDir = "build\windows\x64\runner\Release"
}
if (-not $Arm64BuildDir -and (Test-Path "build\windows\arm64\runner\Release")) {
    $Arm64BuildDir = "build\windows\arm64\runner\Release"
}

$BuildDirs = [ordered]@{}
if ($X64BuildDir -and (Test-Path $X64BuildDir)) { $BuildDirs["x64"] = $X64BuildDir }
if ($Arm64BuildDir -and (Test-Path $Arm64BuildDir)) { $BuildDirs["arm64"] = $Arm64BuildDir }

if ($BuildDirs.Count -eq 0) {
    Write-Error "No build directories found. Provide -X64BuildDir and/or -Arm64BuildDir, or run 'flutter build windows --release' first."
    exit 1
}

Write-Host "Architectures found:" -ForegroundColor Green
foreach ($Architecture in $BuildDirs.Keys) {
    Write-Host "  $($Architecture): $($BuildDirs[$Architecture])"
}

# Locate the SDK tools. The newest kit that actually ships both wins; older
# installed kits are frequently partial.
$SdkRoot = "C:\Program Files (x86)\Windows Kits\10\bin"
$SdkBin = $null
if (Test-Path $SdkRoot) {
    $SdkBin = Get-ChildItem $SdkRoot -Directory |
        Where-Object { $_.Name -as [version] } |
        Sort-Object { [version]$_.Name } -Descending |
        ForEach-Object { Join-Path $_.FullName "x64" } |
        Where-Object { (Test-Path (Join-Path $_ "makeappx.exe")) -and (Test-Path (Join-Path $_ "makepri.exe")) } |
        Select-Object -First 1
}
if (-not $SdkBin) {
    Write-Error "makeappx.exe and makepri.exe not found under $SdkRoot. Install the Windows 10/11 SDK, or run with -EmitManifestOnly to inspect the manifests."
    exit 1
}
$MakeAppx = Join-Path $SdkBin "makeappx.exe"
$MakePri = Join-Path $SdkBin "makepri.exe"
Write-Host "`nUsing $SdkBin" -ForegroundColor Cyan

# Stage payload, assets and manifest per architecture. The .msix packages are
# collected in a sibling directory because makeappx bundle treats every file
# under its /d directory as a package to bundle.
$StagingRoot = Join-Path $ProjectRoot "staging-msix"
$PackageDir = Join-Path $StagingRoot "packages"
if (Test-Path $StagingRoot) { Remove-Item $StagingRoot -Recurse -Force }
New-Item -ItemType Directory -Path $PackageDir -Force | Out-Null

# The resource index that makes the qualified assets resolvable. Without it the
# targetsize/altform-unplated logos are inert payload, and the shell plates the
# taskbar icon with the user's accent colour. Kept outside the staged payload so
# it is not packed. autoResourcePackage would move qualified assets out into
# resource-package indexes that a per-architecture .msix never carries, so the
# shell would stop finding them; strip that.
$PriConfig = Join-Path $StagingRoot "priconfig.xml"
Invoke-SdkTool -Tool $MakePri -Arguments @("createconfig", "/cf", $PriConfig, "/dq", "en-US", "/o")
$PriConfigXml = [xml](Get-Content $PriConfig)
$Packaging = $PriConfigXml.resources.packaging
if ($Packaging) {
    $PriConfigXml.resources.RemoveChild($Packaging) | Out-Null
    $PriConfigXml.Save($PriConfig)
}

foreach ($Architecture in $BuildDirs.Keys) {
    Write-Host "`nStaging $Architecture payload..." -ForegroundColor Cyan
    $Staging = Join-Path $StagingRoot $Architecture
    New-Item -ItemType Directory -Path $Staging -Force | Out-Null
    Copy-Item -Path "$($BuildDirs[$Architecture])\*" -Destination $Staging -Recurse
    Copy-Item -Path "windows\msix\assets" -Destination $Staging -Recurse

    Write-Utf8File -Path (Join-Path $Staging "AppxManifest.xml") `
        -Content (New-AppxManifest -MsixVersion $MsixVersion -Architecture $Architecture)

    # Indexed after the manifest is in place: makepri reads the package identity
    # from it.
    Write-Host "Indexing $Architecture resources..." -ForegroundColor Cyan
    Invoke-SdkTool -Tool $MakePri -Arguments @(
        "new", "/pr", $Staging, "/cf", $PriConfig, "/of", (Join-Path $Staging "resources.pri"), "/o"
    )

    Write-Host "Packing $Architecture..." -ForegroundColor Cyan
    Invoke-SdkTool -Tool $MakeAppx -Arguments @(
        "pack", "/d", $Staging, "/p", (Join-Path $PackageDir "plezy-$Architecture.msix"), "/o"
    )
}

$Bundle = Join-Path $ResolvedOutput "plezy-windows.msixbundle"
Write-Host "`nBundling $($BuildDirs.Count) package(s)..." -ForegroundColor Cyan
Invoke-SdkTool -Tool $MakeAppx -Arguments @(
    "bundle", "/d", $PackageDir, "/p", $Bundle, "/bv", $MsixVersion, "/o"
)

# Clean up staging
Remove-Item $StagingRoot -Recurse -Force -ErrorAction SilentlyContinue

# Summary
Write-Host "`nBuild complete!" -ForegroundColor Green
Write-Host "Architectures:    $($BuildDirs.Keys -join ', ')" -ForegroundColor White
Write-Host "Store package:    $Bundle" -ForegroundColor White
Write-Host "The Store signs this bundle during certification; it is unsigned here." -ForegroundColor White
