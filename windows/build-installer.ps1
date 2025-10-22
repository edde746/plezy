#!/usr/bin/env pwsh
# Windows Installer Build Script
# This script creates both a portable archive and an installer for the Windows build

param(
    [string]$OutputDir = ".",
    [string]$Version = "1.0.0"
)

$ErrorActionPreference = "Stop"

Write-Host "Building Windows installer packages..." -ForegroundColor Cyan

# Ensure we're in the project root
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
Set-Location $ProjectRoot

# Define paths
$BuildDir = "build\windows\x64\runner\Release"
$PortableZip = Join-Path (Resolve-Path $OutputDir) "plezy-windows-portable.zip"
$InstallerExe = Join-Path (Resolve-Path $OutputDir) "plezy-windows-installer.exe"
$SetupScript = "setup.iss"

# Check if build exists
if (-not (Test-Path $BuildDir)) {
    Write-Error "Build directory not found at $BuildDir. Please run 'flutter build windows --release' first."
    exit 1
}

Write-Host "Found build at: $BuildDir" -ForegroundColor Green

# Create Portable Archive
Write-Host "`nCreating portable archive..." -ForegroundColor Cyan
Push-Location $BuildDir
try {
    if (Test-Path $PortableZip) {
        Remove-Item $PortableZip -Force
    }
    Compress-Archive -Path * -DestinationPath $PortableZip
    Write-Host "Created: $PortableZip" -ForegroundColor Green
} finally {
    Pop-Location
}

# Create Inno Setup Script
Write-Host "`nGenerating Inno Setup script..." -ForegroundColor Cyan
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
OutputBaseFilename=plezy-windows-installer
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

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
Write-Host "`nBuilding installer with Inno Setup..." -ForegroundColor Cyan
& $InnoSetupPath $SetupScript

if ($LASTEXITCODE -ne 0) {
    Write-Error "Inno Setup compilation failed"
    exit 1
}

Write-Host "`nBuild complete!" -ForegroundColor Green
Write-Host "Portable archive: $PortableZip" -ForegroundColor White
Write-Host "Installer: $InstallerExe" -ForegroundColor White
