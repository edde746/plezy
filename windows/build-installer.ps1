#!/usr/bin/env pwsh
# Windows Installer Build Script
# Creates per-arch portable archives and a unified installer that auto-detects architecture.
# Supports single-arch (backward compat) and dual-arch builds.

param(
    [string]$OutputDir = ".",
    [string]$Version = "1.0.0",
    [string]$X64BuildDir,
    [string]$Arm64BuildDir
)

$ErrorActionPreference = "Stop"

Write-Host "Building Windows installer packages..." -ForegroundColor Cyan

# Ensure we're in the project root
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
Set-Location $ProjectRoot

$ResolvedOutput = Resolve-Path $OutputDir

# Auto-detect build dirs from default Flutter output paths if not provided
if (-not $X64BuildDir -and (Test-Path "build\windows\x64\runner\Release")) {
    $X64BuildDir = "build\windows\x64\runner\Release"
}
if (-not $Arm64BuildDir -and (Test-Path "build\windows\arm64\runner\Release")) {
    $Arm64BuildDir = "build\windows\arm64\runner\Release"
}

$HasX64 = $X64BuildDir -and (Test-Path $X64BuildDir)
$HasArm64 = $Arm64BuildDir -and (Test-Path $Arm64BuildDir)

if (-not $HasX64 -and -not $HasArm64) {
    Write-Error "No build directories found. Provide -X64BuildDir and/or -Arm64BuildDir, or run 'flutter build windows --release' first."
    exit 1
}

Write-Host "Architectures found:" -ForegroundColor Green
if ($HasX64)   { Write-Host "  x64:   $X64BuildDir" }
if ($HasArm64) { Write-Host "  arm64: $Arm64BuildDir" }

# Check for 7-Zip
Write-Host "`nChecking for 7-Zip..." -ForegroundColor Cyan
if (-not (Get-Command 7z -ErrorAction SilentlyContinue)) {
    Write-Host "7-Zip not found in PATH. Installing via Chocolatey..." -ForegroundColor Yellow

    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Error "Chocolatey is not installed. Please install it from https://chocolatey.org/install"
        exit 1
    }

    choco install 7zip -y
    refreshenv

    if (-not (Get-Command 7z -ErrorAction SilentlyContinue)) {
        Write-Error "Failed to install 7-Zip"
        exit 1
    }
}

# Create Portable Archives
if ($HasX64) {
    Write-Host "`nCreating x64 portable archive..." -ForegroundColor Cyan
    $X64Portable = Join-Path $ResolvedOutput "plezy-windows-x64-portable.7z"
    Push-Location $X64BuildDir
    try {
        if (Test-Path $X64Portable) { Remove-Item $X64Portable -Force }
        7z a -mx=9 $X64Portable *
        Write-Host "Created: $X64Portable" -ForegroundColor Green
    } finally {
        Pop-Location
    }
}

if ($HasArm64) {
    Write-Host "`nCreating arm64 portable archive..." -ForegroundColor Cyan
    $Arm64Portable = Join-Path $ResolvedOutput "plezy-windows-arm64-portable.7z"
    Push-Location $Arm64BuildDir
    try {
        if (Test-Path $Arm64Portable) { Remove-Item $Arm64Portable -Force }
        7z a -mx=9 $Arm64Portable *
        Write-Host "Created: $Arm64Portable" -ForegroundColor Green
    } finally {
        Pop-Location
    }
}

# Stage files for Inno Setup
Write-Host "`nStaging files for installer..." -ForegroundColor Cyan
$StagingDir = "staging"
if (Test-Path $StagingDir) { Remove-Item $StagingDir -Recurse -Force }

if ($HasX64) {
    $X64Staging = Join-Path $StagingDir "x64"
    New-Item -ItemType Directory -Path $X64Staging -Force | Out-Null
    Copy-Item -Path "$X64BuildDir\*" -Destination $X64Staging -Recurse
}
if ($HasArm64) {
    $Arm64Staging = Join-Path $StagingDir "arm64"
    New-Item -ItemType Directory -Path $Arm64Staging -Force | Out-Null
    Copy-Item -Path "$Arm64BuildDir\*" -Destination $Arm64Staging -Recurse
}

# Generate Inno Setup Script
Write-Host "`nGenerating Inno Setup script..." -ForegroundColor Cyan
$SetupScript = "setup.iss"
$DualArch = $HasX64 -and $HasArm64

if ($DualArch) {
    # Dual-arch unified installer with architecture detection
    $IssContent = @"
#define Name "Plezy"
#define Version "$Version"
#define Publisher "edde746"
#define ExeName "plezy.exe"

[Setup]
AppId={{4213385e-f7be-4f2b-95f9-54082a28bb8f}
AppName={#Name}
AppVersion={#Version}
AppPublisher={#Publisher}
DefaultDirName={autopf}\{#Name}
DefaultGroupName={#Name}
AllowNoIcons=yes
OutputDir=.
OutputBaseFilename=plezy-windows-installer
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible arm64
ArchitecturesInstallIn64BitMode=x64compatible arm64

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "staging\x64\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Check: IsX64
Source: "staging\arm64\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs solidbreak; Check: IsArm64

[Icons]
Name: "{group}\{#Name}"; Filename: "{app}\{#ExeName}"
Name: "{group}\{cm:UninstallProgram,{#Name}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#Name}"; Filename: "{app}\{#ExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#ExeName}"; Description: "{cm:LaunchProgram,{#Name}}"; Flags: nowait postinstall

[Code]
function IsX64: Boolean;
begin
  Result := not IsArm64;
end;
"@
} else {
    # Single-arch installer (backward compatible, no Check: functions needed)
    if ($HasX64) {
        $ArchAllowed = "x64compatible"
        $StagingSource = "staging\x64\*"
    } else {
        $ArchAllowed = "arm64"
        $StagingSource = "staging\arm64\*"
    }

    $IssContent = @"
#define Name "Plezy"
#define Version "$Version"
#define Publisher "edde746"
#define ExeName "plezy.exe"

[Setup]
AppId={{4213385e-f7be-4f2b-95f9-54082a28bb8f}
AppName={#Name}
AppVersion={#Version}
AppPublisher={#Publisher}
DefaultDirName={autopf}\{#Name}
DefaultGroupName={#Name}
AllowNoIcons=yes
OutputDir=.
OutputBaseFilename=plezy-windows-installer
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=$ArchAllowed
ArchitecturesInstallIn64BitMode=$ArchAllowed

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "$StagingSource"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#Name}"; Filename: "{app}\{#ExeName}"
Name: "{group}\{cm:UninstallProgram,{#Name}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#Name}"; Filename: "{app}\{#ExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#ExeName}"; Description: "{cm:LaunchProgram,{#Name}}"; Flags: nowait postinstall
"@
}

$IssContent | Out-File -FilePath $SetupScript -Encoding ASCII
Write-Host "Created: $SetupScript" -ForegroundColor Green

# Check for Inno Setup
Write-Host "`nChecking for Inno Setup..." -ForegroundColor Cyan
$InnoSetupPath = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"

if (-not (Test-Path $InnoSetupPath)) {
    Write-Host "Inno Setup not found. Installing via Chocolatey..." -ForegroundColor Yellow

    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Error "Chocolatey is not installed. Please install it from https://chocolatey.org/install"
        exit 1
    }

    choco install innosetup -y

    if (-not (Test-Path $InnoSetupPath)) {
        Write-Error "Failed to install Inno Setup"
        exit 1
    }
}

# Build Installer
Write-Host "`nBuilding installer with Inno Setup..." -ForegroundColor Cyan
& $InnoSetupPath $SetupScript

if ($LASTEXITCODE -ne 0) {
    Write-Error "Inno Setup compilation failed"
    exit 1
}

# Clean up staging
Remove-Item $StagingDir -Recurse -Force -ErrorAction SilentlyContinue

# Summary
Write-Host "`nBuild complete!" -ForegroundColor Green
if ($HasX64)   { Write-Host "Portable (x64):   $X64Portable" -ForegroundColor White }
if ($HasArm64) { Write-Host "Portable (arm64): $Arm64Portable" -ForegroundColor White }
Write-Host "Installer:        $(Join-Path $ResolvedOutput 'plezy-windows-installer.exe')" -ForegroundColor White
