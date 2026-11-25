# Licence texts of what the apps ship

Every component an app ships has a notice in the app's About screen
(`shared/src/commonMain/kotlin/com/edde746/plezy/presentation/settings/ThirdPartyNotices.kt`), and its licence texts
go with the app: this folder holds them, and About shows them offline when a notice is opened. mpv-build's components
(mpv, FFmpeg and the libraries libmpv links) are the exception: mpv-build's artefacts carry their texts
([mpv-build's texts](#mpv-builds-texts)).

## Layout

`<group>/<folder>/<files>`: one folder per component (or per upstream repository several notices share), holding the
project's licence files with its copyright lines, unchanged, at their path in the upstream tree and at the version the
apps ship, and for Apache-2.0 its NOTICE file when it has one. A folder is named after its notice, lower case with
spaces as dashes, unless the notice names it (`ThirdPartyNotice.texts`).

Each app takes the groups `apps.json` gives it:

| Group | Apps | What |
|---|---|---|
| `common` | all | the shared core's libraries, the player's video shaders (NVIDIA Image Scaling, ArtCNN, Anime4K) |
| `compose` | Android, Windows, Linux | Compose Multiplatform, AndroidX and the JVM libraries |
| `android` | Android | the Android app's own libraries |
| `desktop` | Windows, Linux | Skiko's native library with the libraries Skia builds in, and the desktop app's JVM libraries |
| `windows` | Windows | Skia's Direct3D libraries, the bundled OpenJDK |
| `linux` | Linux | Skia's FreeType, piex and DNG SDK, JetBrains Runtime, dbus-java, the Ubuntu libraries libmpv links (in every Linux package) and the Flatpak's Noto Sans |
| `apple` | iPhone and iPad, Mac, Apple TV | SKIE, SQLiter, Stately, Sentry's Cocoa SDK |
| `macos` | Mac | Sparkle |
| `subtitle-font` | Android, the Apple apps | Go Noto Current, libass's last-resort subtitle font |

An app ships each of its groups' folders as `licenses/<folder>/` in its bundled resources: the APK's assets
(`android/app/build.gradle.kts`, next to the folders mpv-android's AAR brings), the desktop app image's
`app/resources/licenses/` (`desktop/app/build.gradle.kts`; the Flatpak also copies it to
`/app/share/licenses/com.edde746.plezy/`) and the Apple app's resources (`apple/license-texts.py`, a build phase of
`apple/project.yml`). Two groups of one app never hold the same folder.

## mpv-build's texts

Every mpv-build artefact carries the licence texts of each component linked into it, one folder per component
(`licenses/<component>/`, each file at its path in the component's source, which mpv-build collects from the sources
it built), and every app ships them as the pinned artefact has them, beside libmpv:

| App | Where | From |
|---|---|---|
| Android | the APK's and bundle's `assets/licenses/<component>/`, beside this folder's | mpv-android's AAR, whose `assets/licenses/` (with `mpv-android/` for its JNI glue) the app's assets merge |
| Windows, Linux | the app image's `app/resources/mpv/licenses/<component>/` (`lib/app/resources/…` on Linux); the Flatpak also in `/app/share/licenses/com.edde746.plezy/mpv-build/` | the libmpv artifact's `licenses/`, which `packagedResources` copies (`desktop/app/build.gradle.kts`) |
| iPhone and iPad, Apple TV, Mac | `MPVKit__MPVKit.bundle/licenses/<component>/` in the app's resources (the bundle's `Contents/Resources/licenses/` on the Mac) | MPVKit's resource bundle, which Xcode embeds |

About names mpv, FFmpeg, libass, libplacebo, dav1d, FreeType, FriBidi and HarfBuzz (where the app's libmpv links them
and no other notice stands for them), with their folder's texts, and mpv-build, whose page shows every component's.
A component's folder takes the name the platform's build gives it (the Apple package's `libdav1d`, Windows'
`freetype2`).

## Checks

- `ThirdPartyLicenseFilesTest` (`:shared:licenseTest`): each app ships the texts of every notice it lists and no others,
  every notice has texts, and the APK ships every `third_party_licenses.txt` an AAR of the Android release build
  carries (`:app-android:shippedLicenseFiles` lists them with their sha256), byte for byte. mpv-build's pinned AAR and
  the libmpv artifact of the host's desktop (Windows' on Windows, Linux's elsewhere) count among their apps' texts:
  each has a non-empty text in every component's folder, every notice's folder is among them, every folder is a
  notice's, and none of the AAR's folders is one of the Android app's own.
- Each package refuses to build without one of its texts: the Android build checks every APK and bundle for this
  folder's texts and the AAR's (`check<Variant>ApkLicenseTexts`, `check<Variant>BundleLicenseTexts`, before
  `assemble` and `bundle` finish; an AAR without texts fails them), the desktop app image's `packagedResources` fails
  on a libmpv artifact without texts, the Apple build phase checks the app's resources and MPVKit's bundle,
  `build-installer.ps1` and `build-msix.ps1` (`desktop/app/packaging/windows/app-image.ps1`) the Windows app images,
  `check-flatpak.py` the installed Flatpak, and `build-flatpak.py` refuses an
  Ubuntu library whose package's copyright file differs from the one here.

## Sources

`sources.json` names, for each folder, the notices it serves, the version shipped and where each file comes from:
a URL pinned to a tag or commit, a line range of a source file (a licence that is only a comment), or a member of a
pinned archive or Debian package. `tools/licenses.py check` (Python 3.14 or later: the Ubuntu packages are
zstd-compressed) downloads every file again and fails on any difference, a file this folder has that `sources.json`
lacks or the reverse; `tools/licenses.py update <group>/<folder>` writes what it downloads. googlesource.com answers
429 to several runs within minutes: run it again later. Builds never download: run it when a version moves (a Gradle
or Swift package update, a Compose Multiplatform update that moves Skiko, an Ubuntu library in
`.github/workflows/build.yml`), after updating the entry's version and URLs.

Where a project publishes no licence file of its own, the folder holds the nearest text it is under:
SQLite's public-domain statement (`LICENSE.md` of its source), and for Go Noto Current (and its Hangul companion on
Android) the licences of the Noto fonts it is built from: Noto Sans' `OFL.txt` and Noto CJK's `Sans/LICENSE`.
kotlinx-atomicfu's licence file is a header naming Apache-2.0, so the Apache text the header points to sits beside it
(`LICENSE-2.0.txt`, apache.org's, from the pinned apache/www-site commit).

The player's video shaders ship as GLSL files (`android/mpv/src/main/assets/shaders/`, which Android's assets, the
desktop app's resources and the Apple apps' bundles take), each with its licence as a comment at its top. NVIDIA Image
Scaling's mpv port is a gist without a licence file: its folder holds NVIDIA's MIT notice from the top of
`NVScaler.glsl` at the pinned gist revision. The shipped `NVScaler.glsl` is that revision with one change, which its
header states: its two coefficient tables are declared rgba16f rather than rgba32f (the same 32-bit float data, kept
as half floats on the GPU), as mpv's OpenGL ES renderer (Android's GPU output) has no rgba32f textures. ArtCNN's and Anime4K's folders hold their repository's `LICENSE` and the
comments whose copyright lines differ from it (ArtCNN's names a second author, Anime4K's carry later years), and for
Anime4K's downscale step, `Anime4K_AutoDownscalePre_x2.glsl`, its Unlicense dedication.

Skiko's native library (`skiko-windows-x64.dll` with `icudtl.dat`, `libskiko-linux-*.so`) links Skia and the libraries
Skia builds in: Skiko 0.150.1 (Compose Multiplatform 1.12.1's) builds on JetBrains' Skia release `m150-1f14f1166a`
(JetBrains/skia commit `1f14f1166a847cb0e148f981600bf1e3e6ca6e46`). Its `skiko/build.gradle.kts` names the Skia
archives each library links; the libraries' revisions are Skia's `DEPS` at that commit; the libraries in each
platform's binary were checked by their strings (Windows: no FreeType, piex or DNG SDK, as Skia's
`skia_use_piex = !is_win` has it). `linux/freetype/fthash.txt` is the licence comment of FreeType's `src/base/fthash.c`,
which FreeType's `ftbase.c` compiles in. A Compose Multiplatform update that moves Skiko moves these folders with it:
Skiko's `skia` version in its `skiko/gradle.properties`, that Skia commit's `DEPS`, Skiko's archive list, and the
strings of the new binaries.
