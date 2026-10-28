# Pinned Windows build tools

Before configuring the Windows Flutter plugins, run:

```powershell
pwsh -File windows/tool/prepare-build-toolchain.ps1
```

The installer job additionally needs Inno Setup 6:

```powershell
pwsh -File windows/tool/prepare-build-toolchain.ps1 -IncludeInstaller
pwsh -File windows/tool/prepare-build-toolchain.ps1 -IncludeInstaller -VerifyOnly
```

The script provisions NuGet 7.9.0 and, when requested, Inno Setup 6.7.3. It
checks the committed SHA-256 and Windows Authenticode publisher before executing
either download. It never installs unversioned Chocolatey packages. The private
Windows image must already provide PowerShell 7.2+, .NET Framework, and 7-Zip.
The native compilers and Windows SDK remain image prerequisites.

GitHub Actions receives the NuGet directory through `GITHUB_PATH`, and the tool
paths through `PLEZY_NUGET_EXE`, `PLEZY_INNO_SETUP_COMPILER`, and
`PLEZY_WINDOWS_TOOLCHAIN_ROOT` in `GITHUB_ENV`. Locally, the same variables and
PATH are set for the current PowerShell process. Invoke the script with `&`
from that process if the next command is a local Flutter build.

The default directory is `RUNNER_TEMP/plezyng-windows-toolchain` in CI, or
`LOCALAPPDATA/PlezyNG/build-tools` locally. `-InstallRoot` overrides it. Inno Setup
uses a per-user installation in that directory and retains its installer log.
A receipt records all installed payload hashes; later verification rejects
changed or incomplete files. `-VerifyOnly` performs no downloads or installs.
Inno's signed executables report `0.0.0.0` in their PE version metadata. The
helper instead checks the compiler engine's version by parsing a tiny script
from standard input with `/O-`; no installer is emitted. This also verifies that
the compiler can load its engine and preprocessor. Inno's `/?` help command
intentionally exits with status 1 and does not report the engine version.
See the pinned [ISCC source](https://github.com/jrsoftware/issrc/blob/is-6_7_3/Projects/ISCC.dpr).
An incomplete installation is retained for diagnosis; use a new task directory
for a retry. Remove a task directory only after its consumers exit, preserving
its installer log if the build failed. Local developer installations are reusable.

`build-installer.ps1` verifies these prerequisites before producing archives;
its `-EmitScriptOnly` mode continues to work without Windows build tools.

To update pins, use the official NuGet distribution index and Inno Setup download
page linked in `build-toolchain.lock.json`. Verify the complete files, their
publisher signatures, and Inno's release digest/attestation before editing the
lock. Never replace expected hashes with values calculated during a build.

Validation:

```powershell
pwsh -File windows/tool/test-prepare-build-toolchain.ps1
```

The rejection tests are portable and do not install anything. A Windows private
JIT run must also execute actual provisioning, `-VerifyOnly`, and packaging to
validate the Windows trust store and installer behavior.
