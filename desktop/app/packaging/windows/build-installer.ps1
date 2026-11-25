#!/usr/bin/env pwsh
# The GitHub release's Windows packages, from the sideloaded app images (PLEZY_FLAVOR=sideloaded, the default) of
# `./gradlew :app-desktop:createReleaseDistributable` built on an x64 and on an arm64 Windows host:
#   plezy-windows-x64-portable.7z, plezy-windows-arm64-portable.7z   each image as it is (7-Zip, -mx=9)
#   plezy-windows-installer.exe                                       one Inno Setup 6 installer for both
#                                                                     architectures; it installs the machine's
#
#   desktop/app/packaging/windows/build-installer.ps1 -X64AppDir <image> -Arm64AppDir <image> -Version <X.Y.Z> [-OutputDir <dir>]
#   desktop/app/packaging/windows/build-installer.ps1 ... -EmitScriptOnly
# Either image may be left out for a single-architecture build. -EmitScriptOnly writes setup.iss to the output
# directory and stops, without checking the images or needing 7-Zip or Inno Setup.
#
# The installer is the one Plezy's earlier releases shipped, with their AppId: it installs over them in place (their
# Start-menu entry, their uninstall entry, their directory) and the app imports their data, which lives outside the
# install directory (%APPDATA%\com.edde746\Plezy), on its first start. It installs per user into
# %LOCALAPPDATA%\Programs\Plezy unless started with /ALLUSERS, registers plezy:// links for Plezy.exe, and starts the
# app when done unless started with /NORUN=1: the in-app updater runs it with /SILENT /SP- and the app comes back.

param(
    [string]$X64AppDir,
    [string]$Arm64AppDir,
    [Parameter(Mandatory)][string]$Version,
    [string]$OutputDir = ".",
    [switch]$EmitScriptOnly
)

function New-InnoSetupScript {
    param(
        [Parameter(Mandatory)][string]$Version,
        # Architecture (x64, arm64) to app image directory.
        [Parameter(Mandatory)][System.Collections.Specialized.OrderedDictionary]$AppDirs
    )

    # Uninstall registry keys are named "{AppId}_is1", so the installer and the elevation code below have to agree on
    # this GUID. It is the earlier releases' AppId: the same installed app.
    $AppGuid = '4213385e-f7be-4f2b-95f9-54082a28bb8f'

    if ($AppDirs.Count -eq 2) {
        $ArchAllowed = 'x64compatible arm64'
        $FilesSection = @"
Source: "$($AppDirs['x64'])\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Check: IsX64
Source: "$($AppDirs['arm64'])\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs solidbreak; Check: IsArm64
"@
    } elseif ($AppDirs.Contains('x64')) {
        $ArchAllowed = 'x64compatible'
        $FilesSection = "Source: ""$($AppDirs['x64'])\*""; DestDir: ""{app}""; Flags: ignoreversion recursesubdirs createallsubdirs"
    } else {
        $ArchAllowed = 'arm64'
        $FilesSection = "Source: ""$($AppDirs['arm64'])\*""; DestDir: ""{app}""; Flags: ignoreversion recursesubdirs createallsubdirs"
    }

    # [InstallDelete] runs before the files are copied. app\ and runtime\ are replaced whole, so no jar or runtime file
    # of an earlier version stays behind. The rest is what the earlier releases installed beside
    # plezy.exe, which this app doesn't use; their data is elsewhere and is never touched.
    #
    # [Registry]: HKA is HKCU\Software\Classes in a per-user install and HKLM\Software\Classes in a machine-wide one.
    # Windows starts Plezy.exe with the link as its one argument ("%1"); the app takes nothing after a link, and a
    # start while Plezy runs hands its link over and exits.
    #
    # [Run] has no skipifsilent: the in-app updater's /SILENT /SP- install starts the app again.
    return @"
#define Name "Plezy"
#define Version "$Version"
#define Publisher "edde746"
#define ExeName "Plezy.exe"

[Setup]
AppId={{$AppGuid}
AppName={#Name}
AppVersion={#Version}
; The installer's own file version; without it the file shows none.
VersionInfoVersion={#Version}
AppPublisher={#Publisher}
DefaultDirName={autopf}\{#Name}
DefaultGroupName={#Name}
AllowNoIcons=yes
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

[InstallDelete]
Type: filesandordirs; Name: "{app}\app"
Type: filesandordirs; Name: "{app}\runtime"
Type: filesandordirs; Name: "{app}\data"
Type: files; Name: "{app}\auto_updater_windows_plugin.dll"
Type: files; Name: "{app}\concrt140.dll"
Type: files; Name: "{app}\connectivity_plus_plugin.dll"
Type: files; Name: "{app}\dartjni.dll"
Type: files; Name: "{app}\flutter_windows.dll"
Type: files; Name: "{app}\libmpv-2.dll"
Type: files; Name: "{app}\msvcp140.dll"
Type: files; Name: "{app}\msvcp140_1.dll"
Type: files; Name: "{app}\msvcp140_2.dll"
Type: files; Name: "{app}\msvcp140_atomic_wait.dll"
Type: files; Name: "{app}\msvcp140_codecvt_ids.dll"
Type: files; Name: "{app}\os_media_controls_plugin.dll"
Type: files; Name: "{app}\screen_retriever_windows_plugin.dll"
Type: files; Name: "{app}\sentry.dll"
Type: files; Name: "{app}\sqlite3.dll"
Type: files; Name: "{app}\universal_gamepad_plugin.dll"
Type: files; Name: "{app}\url_launcher_windows_plugin.dll"
Type: files; Name: "{app}\vcruntime140.dll"
Type: files; Name: "{app}\vcruntime140_1.dll"
Type: files; Name: "{app}\vulkan-1.dll"
Type: files; Name: "{app}\VulkanRT-License.txt"
Type: files; Name: "{app}\window_manager_plugin.dll"
Type: files; Name: "{app}\WinSparkle.dll"

[Files]
$FilesSection

[Registry]
Root: HKA; Subkey: "Software\Classes\plezy"; ValueType: string; ValueName: ""; ValueData: "URL:Plezy"; Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Classes\plezy"; ValueType: string; ValueName: "URL Protocol"; ValueData: ""
Root: HKA; Subkey: "Software\Classes\plezy\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: """{app}\{#ExeName}"",0"
Root: HKA; Subkey: "Software\Classes\plezy\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#ExeName}"" ""%1"""

[Icons]
Name: "{group}\{#Name}"; Filename: "{app}\{#ExeName}"
Name: "{group}\{cm:UninstallProgram,{#Name}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#Name}"; Filename: "{app}\{#ExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#ExeName}"; Description: "{cm:LaunchProgram,{#Name}}"; Flags: nowait postinstall; Check: not IsNoRun

[UninstallDelete]
Type: files; Name: "{app}\.winget"

[Code]
const
  UninstallSubkey = 'Software\Microsoft\Windows\CurrentVersion\Uninstall\{$AppGuid}_is1';
  ProtocolSubkey = 'Software\Classes\plezy';
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
      leaves that user's uninstall entry, Start Menu group and plezy:// link
      registration pointing at files this install now owns, listing Plezy twice
      in Apps & Features. }
    if IsAdminInstallMode then
    begin
      if RegQueryStringValue(HKCU, UninstallSubkey, 'Inno Setup: App Path', PreviousDir) and
         (CompareText(RemoveBackslashUnlessRoot(PreviousDir),
                      RemoveBackslashUnlessRoot(ExpandConstant('{app}'))) = 0) then
      begin
        if not RegQueryStringValue(HKCU, UninstallSubkey, 'Inno Setup: Icon Group', PreviousGroup) then
          PreviousGroup := '';
        RegDeleteKeyIncludingSubkeys(HKCU, UninstallSubkey);
        RegDeleteKeyIncludingSubkeys(HKCU, ProtocolSubkey);
        if PreviousGroup <> '' then
          DelTree(ExpandConstant('{userprograms}') + '\' + PreviousGroup, True, True, True);
      end;
    end;
  end;
end;
"@
}

function Find-Tool {
    param(
        [Parameter(Mandatory)][string]$Command,
        [Parameter(Mandatory)][string[]]$Paths,
        [Parameter(Mandatory)][string]$ChocoPackage
    )

    # PATH, then the installer's default locations, then Chocolatey (preinstalled on GitHub's Windows runners).
    $Found = Get-Command $Command -ErrorAction SilentlyContinue
    if ($Found) { return $Found.Source }
    foreach ($Path in $Paths) {
        if (Test-Path -LiteralPath $Path -PathType Leaf) { return $Path }
    }
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        throw "$Command not found in PATH or at $($Paths -join ', '), and Chocolatey is not installed to install $ChocoPackage"
    }
    Write-Host "Installing $ChocoPackage with Chocolatey..." -ForegroundColor Yellow
    Invoke-Tool -Tool "choco" -Arguments @("install", $ChocoPackage, "-y")
    foreach ($Path in $Paths) {
        if (Test-Path -LiteralPath $Path -PathType Leaf) { return $Path }
    }
    throw "$ChocoPackage installed, but $Command is not at $($Paths -join ', ')"
}

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = (Resolve-Path (Join-Path $ScriptDir "..\..\..\..")).Path
. (Join-Path $ScriptDir "app-image.ps1")

if ($Version -notmatch '^\d+\.\d+\.\d+$') {
    throw "Version must be major.minor.patch; got '$Version'"
}
$AppDirs = [ordered]@{}
if ($X64AppDir) { $AppDirs["x64"] = (Resolve-Path -LiteralPath $X64AppDir).Path }
if ($Arm64AppDir) { $AppDirs["arm64"] = (Resolve-Path -LiteralPath $Arm64AppDir).Path }
if ($AppDirs.Count -eq 0) {
    throw "Pass -X64AppDir and/or -Arm64AppDir: app images from ./gradlew :app-desktop:createReleaseDistributable"
}
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
$ResolvedOutput = (Resolve-Path $OutputDir).Path
$SetupScript = Join-Path $ResolvedOutput "setup.iss"
# UTF-8 with a BOM, which is how Inno Setup recognises a UTF-8 script.
$Utf8Bom = New-Object System.Text.UTF8Encoding($true)

if ($EmitScriptOnly) {
    [System.IO.File]::WriteAllText($SetupScript, (New-InnoSetupScript -Version $Version -AppDirs $AppDirs), $Utf8Bom)
    Write-Host "Created: $SetupScript" -ForegroundColor Green
    exit 0
}

foreach ($Architecture in $AppDirs.Keys) {
    Assert-AppImage -AppDir $AppDirs[$Architecture] -Architecture $Architecture -Flavor SIDELOADED -Version $Version -ProjectRoot $ProjectRoot
}

$SevenZip = Find-Tool -Command "7z" -Paths @("C:\Program Files\7-Zip\7z.exe") -ChocoPackage "7zip"
$Iscc = Find-Tool -Command "ISCC" -Paths @(
    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
    (Join-Path $env:LOCALAPPDATA "Programs\Inno Setup 6\ISCC.exe")
) -ChocoPackage "innosetup"

foreach ($Architecture in $AppDirs.Keys) {
    $Portable = Join-Path $ResolvedOutput "plezy-windows-$Architecture-portable.7z"
    if (Test-Path -LiteralPath $Portable) { Remove-Item -LiteralPath $Portable -Force }
    Push-Location -LiteralPath $AppDirs[$Architecture]
    try {
        Invoke-Tool -Tool $SevenZip -Arguments @("a", "-mx=9", $Portable, "*")
    } finally {
        Pop-Location
    }
    Write-Host "Created: $Portable" -ForegroundColor Green
}

[System.IO.File]::WriteAllText($SetupScript, (New-InnoSetupScript -Version $Version -AppDirs $AppDirs), $Utf8Bom)
Invoke-Tool -Tool $Iscc -Arguments @("/Q", "/O$ResolvedOutput", $SetupScript)
Remove-Item -LiteralPath $SetupScript -Force
Write-Host "Created: $(Join-Path $ResolvedOutput 'plezy-windows-installer.exe') ($($AppDirs.Keys -join ', '))" -ForegroundColor Green
