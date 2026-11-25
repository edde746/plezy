#!/usr/bin/env pwsh
# The Microsoft Store package: packs the store app images (PLEZY_FLAVOR=store) of
# `./gradlew :app-desktop:createReleaseDistributable`, built on an x64 and on an arm64 Windows host, into one
# plezy-windows.msixbundle for Partner Center, an update of the Store's Plezy (product 9N5R1S1T68H7).
#
#   desktop/app/packaging/windows/build-msix.ps1 -X64AppDir <image> -Arm64AppDir <image> -Version <X.Y.Z> [-OutputDir <dir>]
#   desktop/app/packaging/windows/build-msix.ps1 -Version <X.Y.Z> -EmitManifestOnly [-OutputDir <dir>]
# Either image may be left out for a single-architecture bundle. -EmitManifestOnly writes AppxManifest.x64.xml and
# AppxManifest.arm64.xml and stops, so the manifests can be read without the Windows SDK or an app image.
#
# Nothing here signs the bundle. The Store re-signs it after certification, and a package signed with any other
# certificate fails publisher-identity validation; it cannot be installed outside the Store either, so the release
# workflow uploads it as an Actions artifact and does not attach it to the GitHub release.

param(
    [string]$X64AppDir,
    [string]$Arm64AppDir,
    [Parameter(Mandatory)][string]$Version,
    [string]$OutputDir = ".",
    [switch]$EmitManifestOnly
)

function ConvertTo-MsixVersion {
    param([Parameter(Mandatory)][string]$Version)

    # The Store reserves the fourth (revision) field: major.minor.patch becomes major.minor.patch.0, so every Store
    # submission needs a new version. Partner Center rejects a package version whose first field is 0.
    if ($Version -notmatch '^\d+\.\d+\.\d+$') {
        throw "Version must be major.minor.patch; got '$Version'"
    }
    if ($Version -match '^0+\.') {
        throw "Version $Version starts with 0, which Partner Center rejects as a package version"
    }
    return "$Version.0"
}

function New-AppxManifest {
    param(
        [Parameter(Mandatory)][string]$MsixVersion,
        [Parameter(Mandatory)][string]$Architecture
    )

    # Partner Center's product identity page is the source of these three: Store validation rejects the upload if any
    # differs by a single character. Together they make the package family name edde746.Plezy_13q3sv6jzathm.
    # Identity/@Name is limited to '[-.A-Za-z0-9]+'.
    $IdentityName = "edde746.Plezy"
    $Publisher = "CN=AA9C53CB-AD3C-48DA-B3E3-D1E8986D4E25"
    $PublisherDisplayName = "edde746"

    # One template for both architectures; ProcessorArchitecture is the only difference between them.
    #
    # The foundation schema fixes the child order and makeappx rejects any other: Identity, Properties, Resources,
    # Dependencies, Capabilities, Applications.
    #
    # runFullTrust (restricted, hence rescap) is what a packaged Win32 app runs as; the JVM, libmpv and Skiko's
    # DirectComposition need nothing from AppContainer. privateNetworkClientServer declares the local network: a
    # media server at home.
    #
    # The plezy protocol opens plezy:// links in Plezy: Windows starts Plezy.exe with the link as its one argument
    # (uap3's Parameters, "%1"), and a start while Plezy runs hands it over and exits. The app takes nothing after a
    # link, so a link holding a quote, which splits there into more arguments, can't add options.
    return @"
<?xml version="1.0" encoding="utf-8"?>
<Package xmlns="http://schemas.microsoft.com/appx/manifest/foundation/windows10"
         xmlns:uap="http://schemas.microsoft.com/appx/manifest/uap/windows10"
         xmlns:uap3="http://schemas.microsoft.com/appx/manifest/uap/windows10/3"
         xmlns:rescap="http://schemas.microsoft.com/appx/manifest/foundation/windows10/restrictedcapabilities"
         IgnorableNamespaces="uap uap3 rescap">

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
    <Application Id="Plezy" Executable="Plezy.exe" EntryPoint="Windows.FullTrustApplication">
      <uap:VisualElements DisplayName="Plezy"
                          Description="A modern client for Plex and Jellyfin"
                          BackgroundColor="transparent"
                          Square150x150Logo="assets\Square150x150Logo.png"
                          Square44x44Logo="assets\Square44x44Logo.png">
        <uap:DefaultTile Wide310x150Logo="assets\Wide310x150Logo.png"
                         Square310x310Logo="assets\Square310x310Logo.png" />
        <uap:SplashScreen Image="assets\SplashScreen.png" />
      </uap:VisualElements>
      <Extensions>
        <uap3:Extension Category="windows.protocol">
          <uap3:Protocol Name="plezy" Parameters="&quot;%1&quot;" />
        </uap3:Extension>
      </Extensions>
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

    # The manifest declares utf-8. Out-File -Encoding utf8 writes a BOM on Windows PowerShell and none on pwsh 7, so
    # write the bytes directly: the same manifest from either host.
    [System.IO.File]::WriteAllText($Path, $Content, (New-Object System.Text.UTF8Encoding($false)))
}

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = (Resolve-Path (Join-Path $ScriptDir "..\..\..\..")).Path
. (Join-Path $ScriptDir "app-image.ps1")

New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
$ResolvedOutput = (Resolve-Path $OutputDir).Path
$MsixVersion = ConvertTo-MsixVersion -Version $Version
Write-Host "Package version: $MsixVersion" -ForegroundColor Green

# The manifest does not depend on the images, so the inspection path always emits both architectures.
if ($EmitManifestOnly) {
    foreach ($Architecture in @("x64", "arm64")) {
        $EmittedManifest = Join-Path $ResolvedOutput "AppxManifest.$Architecture.xml"
        Write-Utf8File -Path $EmittedManifest -Content (New-AppxManifest -MsixVersion $MsixVersion -Architecture $Architecture)
        Write-Host "Created: $EmittedManifest" -ForegroundColor Green
    }
    exit 0
}

$AppDirs = [ordered]@{}
if ($X64AppDir) { $AppDirs["x64"] = (Resolve-Path -LiteralPath $X64AppDir).Path }
if ($Arm64AppDir) { $AppDirs["arm64"] = (Resolve-Path -LiteralPath $Arm64AppDir).Path }
if ($AppDirs.Count -eq 0) {
    throw "Pass -X64AppDir and/or -Arm64AppDir: store app images from PLEZY_FLAVOR=store ./gradlew :app-desktop:createReleaseDistributable"
}
foreach ($Architecture in $AppDirs.Keys) {
    Assert-AppImage -AppDir $AppDirs[$Architecture] -Architecture $Architecture -Flavor STORE -Version $Version -ProjectRoot $ProjectRoot
}

# The newest Windows SDK that ships both tools; older installed kits are often partial.
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
    throw "makeappx.exe and makepri.exe not found under $SdkRoot. Install the Windows SDK, or run with -EmitManifestOnly."
}
$MakeAppx = Join-Path $SdkBin "makeappx.exe"
$MakePri = Join-Path $SdkBin "makepri.exe"
Write-Host "Using $SdkBin" -ForegroundColor Cyan

# The per-architecture .msix packages go to a sibling directory: makeappx bundle takes every file under /d as a
# package.
$StagingRoot = Join-Path $ResolvedOutput "staging-msix"
$PackageDir = Join-Path $StagingRoot "packages"
if (Test-Path $StagingRoot) { Remove-Item $StagingRoot -Recurse -Force }
New-Item -ItemType Directory -Path $PackageDir -Force | Out-Null

# The resource index makes the qualified assets (targetsize, altform-unplated) resolvable; without it the shell plates
# the taskbar icon with the accent colour. It stays outside the staged payload. autoResourcePackage would move the
# qualified assets into resource packages a per-architecture .msix never carries, so it is removed.
$PriConfig = Join-Path $StagingRoot "priconfig.xml"
Invoke-Tool -Tool $MakePri -Arguments @("createconfig", "/cf", $PriConfig, "/dq", "en-US", "/o")
$PriConfigXml = [xml](Get-Content $PriConfig)
$Packaging = $PriConfigXml.resources.packaging
if ($Packaging) {
    $PriConfigXml.resources.RemoveChild($Packaging) | Out-Null
    $PriConfigXml.Save($PriConfig)
}

foreach ($Architecture in $AppDirs.Keys) {
    Write-Host "Staging $Architecture..." -ForegroundColor Cyan
    $Staging = Join-Path $StagingRoot $Architecture
    New-Item -ItemType Directory -Path $Staging -Force | Out-Null
    Copy-Item -Path (Join-Path $AppDirs[$Architecture] "*") -Destination $Staging -Recurse
    Copy-Item -Path (Join-Path $ScriptDir "assets") -Destination $Staging -Recurse
    Write-Utf8File -Path (Join-Path $Staging "AppxManifest.xml") `
        -Content (New-AppxManifest -MsixVersion $MsixVersion -Architecture $Architecture)

    # After the manifest: makepri reads the package identity from it.
    Invoke-Tool -Tool $MakePri -Arguments @(
        "new", "/pr", $Staging, "/cf", $PriConfig, "/of", (Join-Path $Staging "resources.pri"), "/o"
    )
    Invoke-Tool -Tool $MakeAppx -Arguments @(
        "pack", "/d", $Staging, "/p", (Join-Path $PackageDir "plezy-$Architecture.msix"), "/o"
    )
}

$Bundle = Join-Path $ResolvedOutput "plezy-windows.msixbundle"
Invoke-Tool -Tool $MakeAppx -Arguments @("bundle", "/d", $PackageDir, "/p", $Bundle, "/bv", $MsixVersion, "/o")
Remove-Item $StagingRoot -Recurse -Force

Write-Host "Created: $Bundle ($($AppDirs.Keys -join ', ')); unsigned, the Store signs it." -ForegroundColor Green
