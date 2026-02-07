#!/usr/bin/env pwsh
# Windows ARM64 Installer Build Script
# This script creates both a portable archive and an installer for the Windows ARM64 build

param(
    [string]$OutputDir = ".",
    [string]$Version = "1.0.0"
)

$ErrorActionPreference = "Stop"

Write-Host "Building Windows ARM64 installer packages..." -ForegroundColor Cyan

# Ensure we're in the project root
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
Set-Location $ProjectRoot

# Define paths - ARM64 builds go to arm64 directory
$BuildDir = "build\windows\arm64\runner\Release"
$PortableZip = Join-Path (Resolve-Path $OutputDir) "plezy-windows-arm64-portable.7z"
$InstallerExe = Join-Path (Resolve-Path $OutputDir) "plezy-windows-arm64-installer.exe"
$SetupScript = "setup-arm64.iss"

# Check if build exists
if (-not (Test-Path $BuildDir)) {
    Write-Error "Build directory not found at $BuildDir. Please run 'flutter build windows --release --target-arch=arm64' first."
    exit 1
}

Write-Host "Found ARM64 build at: $BuildDir" -ForegroundColor Green

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

# Create Portable Archive
Write-Host "`nCreating ARM64 portable archive..." -ForegroundColor Cyan
Push-Location $BuildDir
try {
    if (Test-Path $PortableZip) {
        Remove-Item $PortableZip -Force
    }
    7z a -mx=9 $PortableZip *
    Write-Host "Created: $PortableZip" -ForegroundColor Green
} finally {
    Pop-Location
}

# Create Inno Setup Script for ARM64
Write-Host "`nGenerating Inno Setup script for ARM64..." -ForegroundColor Cyan
@"
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
OutputBaseFilename=plezy-windows-arm64-installer
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
; ARM64-specific architecture settings
ArchitecturesAllowed=arm64
ArchitecturesInstallIn64BitMode=arm64

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "build\windows\arm64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#Name}"; Filename: "{app}\{#ExeName}"
Name: "{group}\{cm:UninstallProgram,{#Name}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#Name}"; Filename: "{app}\{#ExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#ExeName}"; Description: "{cm:LaunchProgram,{#Name}}"; Flags: nowait postinstall skipifsilent
"@ | Out-File -FilePath $SetupScript -Encoding ASCII

Write-Host "Created: $SetupScript" -ForegroundColor Green

# Check for Inno Setup
Write-Host "`nChecking for Inno Setup..." -ForegroundColor Cyan
$InnoSetupPath = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"

if (-not (Test-Path $InnoSetupPath)) {
    Write-Host "Inno Setup not found. Installing via Chocolatey..." -ForegroundColor Yellow

    # Check if choco is available
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
Write-Host "`nBuilding ARM64 installer with Inno Setup..." -ForegroundColor Cyan
& $InnoSetupPath $SetupScript

if ($LASTEXITCODE -ne 0) {
    Write-Error "Inno Setup compilation failed"
    exit 1
}

Write-Host "`nARM64 build complete!" -ForegroundColor Green
Write-Host "Portable archive: $PortableZip" -ForegroundColor White
Write-Host "Installer: $InstallerExe" -ForegroundColor White
