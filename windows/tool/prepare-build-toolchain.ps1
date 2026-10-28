#requires -Version 7.2
<#
Install the pinned NuGet CLI before configuring Flutter's Windows plugins.
Use -IncludeInstaller for the job that assembles the Inno Setup installer.
No administrator access, global package manager, or machine PATH changes are needed.
Downloads and installer logs stay under the task's toolchain directory.
#>
[CmdletBinding()]
param(
    [switch]$IncludeInstaller,
    [switch]$VerifyOnly,
    [string]$InstallRoot = $env:PLEZY_WINDOWS_TOOLCHAIN_ROOT
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
if (-not [Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([Runtime.InteropServices.OSPlatform]::Windows)) {
    throw 'The Windows build toolchain must be provisioned on Windows.'
}

if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
    $InstallRoot = if ($env:RUNNER_TEMP) {
        Join-Path $env:RUNNER_TEMP 'plezyng-windows-toolchain'
    } elseif ($env:LOCALAPPDATA) {
        Join-Path $env:LOCALAPPDATA 'PlezyNG\build-tools'
    } else {
        throw 'Set -InstallRoot, RUNNER_TEMP, or LOCALAPPDATA.'
    }
}
$InstallRoot = [IO.Path]::GetFullPath($InstallRoot)
if ($InstallRoot.IndexOfAny([char[]]"`r`n`"") -ge 0) {
    throw 'The toolchain directory must not contain quotes or newlines.'
}
$lock = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'build-toolchain.lock.json') -Raw | ConvertFrom-Json
if ($lock.formatVersion -ne 1) { throw 'Unsupported Windows toolchain lock format.' }
$downloadRoot = Join-Path $InstallRoot 'downloads'

function Assert-PinnedFile([string]$Path, $Pin) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Missing pinned tool: $Path" }
    $hash = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($hash -cne $Pin.sha256) { throw "SHA-256 mismatch for $Path; expected $($Pin.sha256), got $hash" }
    $signature = Get-AuthenticodeSignature -LiteralPath $Path
    if ($signature.Status -ne 'Valid' -or -not $signature.SignerCertificate) {
        throw "Invalid Authenticode signature on $Path ($($signature.Status))."
    }
    $publisher = $signature.SignerCertificate.GetNameInfo([Security.Cryptography.X509Certificates.X509NameType]::SimpleName, $false)
    if ($publisher -cne $Pin.authenticodePublisher) { throw "Unexpected publisher for $Path`: $publisher" }
}

function Get-PinnedDownload($Pin) {
    if ($Pin.sha256 -cnotmatch '^[0-9a-f]{64}$' -or $Pin.version -notmatch '^\d+\.\d+\.\d+$' -or
        $Pin.filename -notmatch '^[a-zA-Z0-9._-]+\.exe$' -or ([uri]$Pin.url).Scheme -ne 'https') {
        throw 'Malformed pinned Windows download.'
    }
    $destination = Join-Path $downloadRoot $Pin.filename
    if (-not (Test-Path -LiteralPath $destination)) {
        if ($VerifyOnly) { throw "Pinned download is missing: $destination. Run prepare-build-toolchain.ps1 first." }
        New-Item -ItemType Directory -Path $downloadRoot -Force | Out-Null
        $temporary = "$destination.partial-$([guid]::NewGuid().ToString('N')).exe"
        try {
            Invoke-WebRequest -Uri $Pin.url -OutFile $temporary -MaximumRedirection 5 -TimeoutSec 180 -MaximumRetryCount 3 -RetryIntervalSec 2
            Assert-PinnedFile $temporary $Pin
            Move-Item -LiteralPath $temporary -Destination $destination
        } catch {
            # Retain failed downloads for diagnosis; never execute unchecked bytes.
            if (Test-Path -LiteralPath $temporary) { Write-Warning "Failed download retained at $temporary" }
            throw
        }
    }
    Assert-PinnedFile $destination $Pin
    return $destination
}

function Assert-ToolVersion([string]$Path, [string]$Version) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Missing installed tool: $Path" }
    $actual = [Diagnostics.FileVersionInfo]::GetVersionInfo($Path).ProductVersion
    if ($actual -notmatch ('^' + [regex]::Escape($Version) + '(?:\D|$)')) {
        throw "Unexpected version of $Path`: $actual; expected $Version."
    }
}

function Publish-Environment([string]$Name, [string]$Value) {
    if ($Value.IndexOfAny([char[]]"`r`n") -ge 0) { throw 'Invalid environment value.' }
    [Environment]::SetEnvironmentVariable($Name, $Value, 'Process')
    if ($env:GITHUB_ENV) { [IO.File]::AppendAllText($env:GITHUB_ENV, "$Name=$Value`n", [Text.UTF8Encoding]::new($false)) }
}

$nugetDirectory = Join-Path $InstallRoot "nuget\$($lock.nuget.version)"
$nuget = Join-Path $nugetDirectory 'nuget.exe'
if (-not (Test-Path -LiteralPath $nuget)) {
    if ($VerifyOnly) { throw "NuGet is missing. Run windows/tool/prepare-build-toolchain.ps1 before building." }
    $archive = Get-PinnedDownload $lock.nuget
    New-Item -ItemType Directory -Path $nugetDirectory -Force | Out-Null
    Copy-Item -LiteralPath $archive -Destination $nuget
}
Assert-PinnedFile $nuget $lock.nuget
Assert-ToolVersion $nuget $lock.nuget.version
Publish-Environment 'PLEZY_WINDOWS_TOOLCHAIN_ROOT' $InstallRoot
Publish-Environment 'PLEZY_NUGET_EXE' $nuget
if (($env:PATH -split ';') -notcontains $nugetDirectory) { $env:PATH = "$nugetDirectory;$env:PATH" }
if ($env:GITHUB_PATH) { [IO.File]::AppendAllText($env:GITHUB_PATH, "$nugetDirectory`n", [Text.UTF8Encoding]::new($false)) }
Write-Host "Verified NuGet $($lock.nuget.version): $nuget"

if ($IncludeInstaller) {
    $innoRoot = Join-Path $InstallRoot "inno-setup\$($lock.innoSetup.version)"
    $compiler = Join-Path $innoRoot 'ISCC.exe'
    $receiptPath = Join-Path $innoRoot 'plezyng-installation.json'
    if (-not (Test-Path -LiteralPath $receiptPath -PathType Leaf)) {
        if ($VerifyOnly) { throw 'Inno Setup is missing. Run prepare-build-toolchain.ps1 -IncludeInstaller first.' }
        if (Test-Path -LiteralPath $innoRoot) { throw "Unverified installation directory already exists: $innoRoot. Preserve it for diagnosis and use a fresh -InstallRoot." }
        $installer = Get-PinnedDownload $lock.innoSetup
        $log = Join-Path $InstallRoot "inno-setup-$($lock.innoSetup.version).log"
        $arguments = '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /CURRENTUSER /NOICONS /DIR="{0}" /LOG="{1}"' -f $innoRoot, $log
        $process = Start-Process -FilePath $installer -ArgumentList $arguments -Wait -PassThru
        if ($process.ExitCode -ne 0) { throw "Inno Setup installation failed ($($process.ExitCode)); see $log" }
        Assert-ToolVersion $compiler $lock.innoSetup.version
        $files = @(Get-ChildItem -LiteralPath $innoRoot -File -Recurse | ForEach-Object {
            [ordered]@{ path = [IO.Path]::GetRelativePath($innoRoot, $_.FullName); sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant() }
        })
        [ordered]@{ version = $lock.innoSetup.version; installerSha256 = $lock.innoSetup.sha256; files = $files } |
            ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $receiptPath -Encoding utf8NoBOM
    }
    $receipt = Get-Content -LiteralPath $receiptPath -Raw | ConvertFrom-Json
    if ($receipt.version -cne $lock.innoSetup.version -or $receipt.installerSha256 -cne $lock.innoSetup.sha256 -or
        @($receipt.files).Count -eq 0 -or 'ISCC.exe' -cnotin @($receipt.files.path)) {
        throw 'The Inno Setup installation receipt does not match the pinned installer.'
    }
    foreach ($file in $receipt.files) {
        $path = [IO.Path]::GetFullPath((Join-Path $innoRoot $file.path))
        if (-not $path.StartsWith($innoRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
            throw 'Invalid installed-file path in the Inno Setup receipt.'
        }
        if (-not (Test-Path -LiteralPath $path -PathType Leaf) -or
            (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() -cne $file.sha256) {
            throw "The installed Inno Setup payload changed: $path"
        }
    }
    Assert-ToolVersion $compiler $lock.innoSetup.version
    Publish-Environment 'PLEZY_INNO_SETUP_COMPILER' $compiler
    Write-Host "Verified Inno Setup $($lock.innoSetup.version): $compiler"
}
