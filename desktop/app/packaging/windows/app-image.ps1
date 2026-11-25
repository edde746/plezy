# Dot-sourced by build-installer.ps1 and build-msix.ps1: the checks every Windows package makes of the app images it
# wraps, and the checked call of a native tool.
#
# An app image is `./gradlew :app-desktop:createReleaseDistributable`'s
# desktop/app/build/compose/binaries/main-release/app/Plezy: Plezy.exe (the launcher), app\ (the jars, Plezy.cfg, the
# resources: libmpv, the shaders, the licence texts About shows) and runtime\ (the linked JDK). Gradle builds it for
# the machine it runs on, so an x64 image comes from an x64 Windows host and an arm64 image from a Windows arm64 host.

# The PE machine types of the image's executables, per architecture.
$PeMachines = @{ "x64" = 0x8664; "arm64" = 0xAA64 }

function Get-PeMachine {
    param([Parameter(Mandatory)][string]$Path)

    $Bytes = [System.IO.File]::ReadAllBytes($Path)
    $Header = [BitConverter]::ToInt32($Bytes, 0x3C)
    if ($Bytes[0] -ne 0x4D -or $Bytes[1] -ne 0x5A -or [BitConverter]::ToUInt32($Bytes, $Header) -ne 0x4550) {
        throw "$Path is not a PE image"
    }
    return [BitConverter]::ToUInt16($Bytes, $Header + 4)
}

function Get-AppJarManifest {
    param([Parameter(Mandatory)][string]$AppDir)

    # The app's own jar (app-desktop's) carries Implementation-Version (version.xcconfig's MARKETING_VERSION) and
    # Plezy-Flavor (-Pplezy.flavor / PLEZY_FLAVOR) in its manifest; the app reads its flavor there.
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $Found = @{}
    foreach ($Jar in Get-ChildItem -LiteralPath (Join-Path $AppDir "app") -Filter "app-desktop*.jar") {
        $Zip = [System.IO.Compression.ZipFile]::OpenRead($Jar.FullName)
        try {
            $Entry = $Zip.GetEntry("META-INF/MANIFEST.MF")
            if (-not $Entry) { continue }
            $Reader = New-Object System.IO.StreamReader($Entry.Open())
            try { $Text = $Reader.ReadToEnd() } finally { $Reader.Dispose() }
        } finally {
            $Zip.Dispose()
        }
        $Flavor = [regex]::Match($Text, '(?m)^Plezy-Flavor: *(\S+)\r?$')
        if ($Flavor.Success) {
            $Found[$Jar.Name] = @{
                Flavor = $Flavor.Groups[1].Value
                Version = [regex]::Match($Text, '(?m)^Implementation-Version: *(\S+)\r?$').Groups[1].Value
            }
        }
    }
    if ($Found.Count -ne 1) {
        throw "Expected one app-desktop jar with a Plezy-Flavor manifest entry in $AppDir\app, found $($Found.Count)"
    }
    return @($Found.Values)[0]
}

function Assert-AppImage {
    param(
        [Parameter(Mandatory)][string]$AppDir,
        [Parameter(Mandatory)][ValidateSet("x64", "arm64")][string]$Architecture,
        # The BuildFlavor the package is for: SIDELOADED (installer, portables) or STORE (MSIX).
        [Parameter(Mandatory)][ValidateSet("SIDELOADED", "STORE")][string]$Flavor,
        [Parameter(Mandatory)][string]$Version,
        [Parameter(Mandatory)][string]$ProjectRoot
    )

    foreach ($Required in @("Plezy.exe", "app\Plezy.cfg", "runtime\bin\server\jvm.dll")) {
        if (-not (Test-Path -LiteralPath (Join-Path $AppDir $Required) -PathType Leaf)) {
            throw "Incomplete $Architecture app image: $AppDir has no $Required"
        }
    }
    $Libmpv = @(Get-ChildItem -LiteralPath (Join-Path $AppDir "app\resources\mpv") -Recurse -Filter "libmpv-2.dll")
    if ($Libmpv.Count -ne 1) {
        throw "Incomplete $Architecture app image: expected one libmpv-2.dll in app\resources\mpv, found $($Libmpv.Count)"
    }

    # No debug symbols or link by-products ship: no *.pdb (native symbols go to the crash server from the build, never
    # to users) and no *.lib or *.exp (the import library and export file a DLL's link leaves beside it). The linked
    # runtime's lib\jvm.lib and lib\jawt.lib are the JDK's own import libraries, which jlink copies from the java.base
    # and java.desktop modules: nothing loads them at run time, and they are part of the runtime as the JDK ships it.
    # The licence folders hold texts whatever their names (libiconv's COPYING.LIB is the LGPL).
    $JdkImportLibraries = @("runtime\lib\jvm.lib", "runtime\lib\jawt.lib")
    $Root = (Resolve-Path -LiteralPath $AppDir).Path.TrimEnd("\")
    $Forbidden = @(Get-ChildItem -LiteralPath $Root -Recurse -File |
        Where-Object { $_.Extension -in @(".pdb", ".lib", ".exp") } |
        ForEach-Object { $_.FullName.Substring($Root.Length + 1) } |
        Where-Object { $JdkImportLibraries -notcontains $_ -and $_ -notmatch '^app\\resources\\(mpv\\)?licenses\\' })
    if ($Forbidden.Count -gt 0) {
        throw "The $Architecture app image carries debug or link files that never ship: $($Forbidden -join ', ')"
    }

    # The launcher, the JVM and libmpv must all be built for the package's architecture: the installer picks the image
    # by the machine's, and the Store serves each package to its own.
    foreach ($Binary in @((Join-Path $AppDir "Plezy.exe"), (Join-Path $AppDir "runtime\bin\server\jvm.dll"), $Libmpv[0].FullName)) {
        $Machine = Get-PeMachine -Path $Binary
        if ($Machine -ne $PeMachines[$Architecture]) {
            throw ("$Binary is built for PE machine 0x{0:X4}, not {1} (0x{2:X4})" -f $Machine, $Architecture, $PeMachines[$Architecture])
        }
    }

    $Manifest = Get-AppJarManifest -AppDir $AppDir
    if ($Manifest.Flavor -ne $Flavor) {
        throw "The $Architecture app image is the $($Manifest.Flavor) build; this package needs $Flavor (PLEZY_FLAVOR=$($Flavor.ToLower()))"
    }
    if ($Manifest.Version -ne $Version) {
        throw "The $Architecture app image is version $($Manifest.Version), not $Version"
    }

    # The licence texts About shows: the windows groups of the repository's licenses/ (licenses\apps.json) in
    # app\resources\licenses, and libmpv's own (its artifact's licenses\, which Gradle copies whole and refuses to
    # package empty) in app\resources\mpv\licenses.
    $LicensesDir = Join-Path $ProjectRoot "licenses"
    $Texts = foreach ($Group in (Get-Content -Raw -LiteralPath (Join-Path $LicensesDir "apps.json") | ConvertFrom-Json).windows) {
        $Root = (Resolve-Path (Join-Path $LicensesDir $Group)).Path
        Get-ChildItem -LiteralPath $Root -Recurse -File | ForEach-Object { $_.FullName.Substring($Root.Length + 1) }
    }
    if (-not $Texts) {
        throw "No licence texts in licenses\apps.json's windows groups"
    }
    foreach ($Text in $Texts) {
        if (-not (Test-Path -LiteralPath (Join-Path $AppDir "app\resources\licenses\$Text") -PathType Leaf)) {
            throw "Incomplete $Architecture app image: no licence text app\resources\licenses\$Text"
        }
    }
    $MpvLicenses = Join-Path $AppDir "app\resources\mpv\licenses"
    if (-not (Test-Path -LiteralPath $MpvLicenses -PathType Container) -or
        -not (Get-ChildItem -LiteralPath $MpvLicenses -Recurse -File | Where-Object { $_.Length -gt 0 })) {
        throw "Incomplete $Architecture app image: no licence texts of libmpv in app\resources\mpv\licenses"
    }
    Write-Host "$Architecture app image: $Flavor $Version, $($Texts.Count) licence texts" -ForegroundColor Green
}

function Invoke-Tool {
    param(
        [Parameter(Mandatory)][string]$Tool,
        [Parameter(Mandatory)][string[]]$Arguments
    )

    # $ErrorActionPreference does not apply to native executables: every tool call goes through this check.
    & $Tool @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$(Split-Path -Leaf $Tool) $($Arguments -join ' ') failed with exit code $LASTEXITCODE"
    }
}
