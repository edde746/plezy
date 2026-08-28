#!/usr/bin/env pwsh
# Windows Installer Build Script
# Creates per-arch portable archives and a unified installer that auto-detects architecture.
# Supports single-arch (backward compat) and dual-arch builds.

param(
    [string]$OutputDir = ".",
    [string]$Version = "1.0.0",
    [string]$X64BuildDir,
    [string]$Arm64BuildDir,
    # Write setup.iss and stop. Lets the generated script be inspected or
    # checked without 7-Zip, Inno Setup or a populated Flutter build output.
    [switch]$EmitScriptOnly
)

function New-InnoSetupScript {
    param(
        [Parameter(Mandatory)][string]$Version,
        [Parameter(Mandatory)][bool]$HasX64,
        [Parameter(Mandatory)][bool]$HasArm64
    )

    # Uninstall registry keys are named "{AppId}_is1", so the installer and the
    # elevation code below have to agree on this GUID.
    $AppGuid = '4213385e-f7be-4f2b-95f9-54082a28bb8f'

    if ($HasX64 -and $HasArm64) {
        $ArchAllowed = 'x64compatible arm64'
        $FilesSection = @'
Source: "staging\x64\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Check: IsX64
Source: "staging\arm64\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs solidbreak; Check: IsArm64
'@
    } elseif ($HasX64) {
        $ArchAllowed = 'x64compatible'
        $FilesSection = 'Source: "staging\x64\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs'
    } else {
        $ArchAllowed = 'arm64'
        $FilesSection = 'Source: "staging\arm64\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs'
    }

    return @"
#define Name "Plezy"
#define Version "$Version"
#define Publisher "RyanTheTechMan (Plezy Labs)"
#define ExeName "plezy.exe"

[Setup]
AppId={{$AppGuid}
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
; Needed for /ALLUSERS to take effect, which is how the elevated instance
; started by InitializeSetup below reaches an existing machine-wide install.
PrivilegesRequiredOverridesAllowed=commandline
ArchitecturesAllowed=$ArchAllowed
ArchitecturesInstallIn64BitMode=$ArchAllowed

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[CustomMessages]
ElevationRequired=Plezy is installed in %1, which requires administrator privileges to update.%n%nRe-run this installer using "Run as administrator", or download the latest installer from https://github.com/edde746/plezy/releases/latest

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
$FilesSection

[Icons]
Name: "{group}\{#Name}"; Filename: "{app}\{#ExeName}"
Name: "{group}\{cm:UninstallProgram,{#Name}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#Name}"; Filename: "{app}\{#ExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#ExeName}"; Description: "{cm:LaunchProgram,{#Name}}"; Flags: nowait postinstall; Check: not IsNoRun

[Code]
const
  UninstallSubkey = 'Software\Microsoft\Windows\CurrentVersion\Uninstall\{$AppGuid}_is1';
  WriteProbeName = 'plezy-write-probe.tmp';

function IsNoRun: Boolean;
begin
  Result := ExpandConstant('{param:NORUN|0}') = '1';
end;

function IsX64: Boolean;
begin
  Result := not IsArm64;
end;

{ Directory of an existing installation, or '' when none is registered.
  PrivilegesRequired=lowest pins Setup to non administrative install mode, so
  Inno's own UsePreviousAppDir lookup only ever consults HKCU. A copy that
  ended up machine-wide has to be found whichever mode registered it. }
function PreviousInstallDir: String;
var
  Dir: String;
begin
  Result := '';
  if RegQueryStringValue(HKCU, UninstallSubkey, 'Inno Setup: App Path', Dir) then
    Result := Dir
  else if RegQueryStringValue(HKLM, UninstallSubkey, 'Inno Setup: App Path', Dir) then
    Result := Dir;
end;

{ Whether this process could replace files in Path. Setup is manifested, so UAC
  file virtualization is off and a refused write really is refused. }
function PathIsWritable(const Path: String): Boolean;
var
  Dir, Probe: String;
begin
  Dir := RemoveBackslashUnlessRoot(Path);
  if not DirExists(Dir) then
    Dir := ExtractFileDir(Dir);
  if (Dir = '') or not DirExists(Dir) then begin
    { Nothing to overwrite; let Setup report any genuine failure itself. }
    Result := True;
    Exit;
  end;

  Probe := AddBackslash(Dir) + WriteProbeName;
  Result := SaveStringToFile(Probe, '', False);
  if Result then
    DeleteFile(Probe);
end;

function QuoteIfNeeded(const S: String): String;
begin
  if Pos(' ', S) > 0 then
    Result := '"' + S + '"'
  else
    Result := S;
end;

{ The documented parameters this instance was started with, minus the install
  mode and directory overrides the elevated instance is given explicitly. }
function ForwardedParams: String;
var
  I: Integer;
  P: String;
begin
  Result := '';
  for I := 1 to ParamCount do begin
    P := ParamStr(I);
    if (P <> '') and
       (CompareText(P, '/ALLUSERS') <> 0) and
       (CompareText(P, '/CURRENTUSER') <> 0) and
       (CompareText(Copy(P, 1, 5), '/DIR=') <> 0) then
      Result := Result + QuoteIfNeeded(P) + ' ';
  end;
end;

{ An installation living somewhere this user cannot write - typically
  C:\Program Files, inherited from an elevated run of an earlier installer -
  can only be updated in administrative install mode. Setup settles the install
  mode before any [Code] runs, so hand the work to a new elevated instance and
  pin it to the directory already in use. Without this the silent installer
  launched by the in-app updater fails to overwrite anything. }
function InitializeSetup: Boolean;
var
  PreviousDir, Params: String;
  ErrorCode: Integer;
begin
  Result := True;
  if IsAdminInstallMode or (ExpandConstant('{param:ELEVATED|0}') = '1') then
    Exit;

  PreviousDir := PreviousInstallDir;
  if (PreviousDir = '') or PathIsWritable(PreviousDir) then
    Exit;

  Params := ForwardedParams + '/ALLUSERS /ELEVATED=1 /DIR=' +
    QuoteIfNeeded(RemoveBackslashUnlessRoot(PreviousDir));

  { Either the elevated instance takes over, or elevation was refused and there
    is nothing this instance can usefully do. }
  Result := False;
  if ShellExec('runas', ExpandConstant('{srcexe}'), Params, '', SW_SHOW, ewNoWait, ErrorCode) then
    Exit;

  SuppressibleMsgBox(FmtMessage(CustomMessage('ElevationRequired'), [PreviousDir]),
    mbCriticalError, MB_OK, IDOK);
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  MarkerPath, PreviousDir, PreviousGroup: String;
begin
  if CurStep = ssPostInstall then
  begin
    MarkerPath := ExpandConstant('{app}\.winget');
    if ExpandConstant('{param:WINGET|0}') = '1' then
      SaveStringToFile(MarkerPath, '', False)
    else
      DeleteFile(MarkerPath);

    { A machine-wide install that took over a directory registered per-user
      leaves that user's uninstall entry and Start Menu group pointing at files
      this install now owns, listing Plezy twice in Apps & Features. }
    if IsAdminInstallMode then
    begin
      if RegQueryStringValue(HKCU, UninstallSubkey, 'Inno Setup: App Path', PreviousDir) and
         (CompareText(RemoveBackslashUnlessRoot(PreviousDir),
                      RemoveBackslashUnlessRoot(ExpandConstant('{app}'))) = 0) then
      begin
        if not RegQueryStringValue(HKCU, UninstallSubkey, 'Inno Setup: Icon Group', PreviousGroup) then
          PreviousGroup := '';
        RegDeleteKeyIncludingSubkeys(HKCU, UninstallSubkey);
        if PreviousGroup <> '' then
          DelTree(ExpandConstant('{userprograms}') + '\' + PreviousGroup, True, True, True);
      end;
    end;
  end;
end;
"@
}

$ErrorActionPreference = "Stop"

Write-Host "Building Windows installer packages..." -ForegroundColor Cyan

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
Set-Location $ProjectRoot

$ResolvedOutput = Resolve-Path $OutputDir

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

$SetupScript = "setup.iss"

if ($EmitScriptOnly) {
    $EmittedScript = Join-Path $ResolvedOutput $SetupScript
    Write-Host "`nGenerating Inno Setup script only..." -ForegroundColor Cyan
    New-InnoSetupScript -Version $Version -HasX64 ([bool]$HasX64) -HasArm64 ([bool]$HasArm64) |
        Out-File -FilePath $EmittedScript -Encoding ASCII
    Write-Host "Created: $EmittedScript" -ForegroundColor Green
    exit 0
}

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

Write-Host "`nGenerating Inno Setup script..." -ForegroundColor Cyan
New-InnoSetupScript -Version $Version -HasX64 ([bool]$HasX64) -HasArm64 ([bool]$HasArm64) |
    Out-File -FilePath $SetupScript -Encoding ASCII
Write-Host "Created: $SetupScript" -ForegroundColor Green

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

Write-Host "`nBuilding installer with Inno Setup..." -ForegroundColor Cyan
& $InnoSetupPath $SetupScript

if ($LASTEXITCODE -ne 0) {
    Write-Error "Inno Setup compilation failed"
    exit 1
}

Remove-Item $StagingDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "`nBuild complete!" -ForegroundColor Green
if ($HasX64)   { Write-Host "Portable (x64):   $X64Portable" -ForegroundColor White }
if ($HasArm64) { Write-Host "Portable (arm64): $Arm64Portable" -ForegroundColor White }
Write-Host "Installer:        $(Join-Path $ResolvedOutput 'plezy-windows-installer.exe')" -ForegroundColor White
