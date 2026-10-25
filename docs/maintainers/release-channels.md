# PlezyNG release channels

This is the release support boundary for the PlezyNG client and its separate relay service. A client platform or package channel is active when the manual release workflow creates the package and attaches it to a GitHub Release, or when a named publisher workflow submits that release's package.

## Release trigger and order

`.github/workflows/build.yml` runs only by manual dispatch from `main`. The requested semantic version must match `pubspec.yaml`. It builds the configured targets, generates release notes from `CHANGELOG.md`, checksums and attests the packages, and creates a draft GitHub Release. Review the draft, then publish it.

Push and pull-request CI runs checks; it does not build release packages or publish images. The only package build dispatch is **PlezyNG Release**. Publishing the draft triggers Discord, Homebrew/appcast, Chocolatey, WinGet, Snap Store, AUR, COPR, PPA, and relay-container workflows. The app-store workflow is separate and must be run manually for a published stable release.

## Client packages on GitHub Releases

| Platform | Architectures | GitHub Release assets |
| --- | --- | --- |
| Windows | x64, arm64 | Combined Inno Setup installer, per-architecture portable `.7z`, Chocolatey `.nupkg`, and versioned WinGet manifest bundle. A dual-architecture Microsoft Store `.msixbundle` is added when the Partner Center package identity is configured. |
| macOS | x64, arm64 | Universal DMG and Sparkle appcast; the Homebrew cask is updated after publication. Developer ID signing and notarization are optional. |
| Linux | x64, arm64 | Portable `.tar.gz`, Debian `.deb`, RPM `.rpm`, Arch `.pkg.tar.zst`, Flatpak bundle, and Snap package for each architecture; an x64 AppImage is also attached. |
| Android | arm64-v8a, armeabi-v7a, x86_64 | Split APK archives. A Play `.aab` and Amazon Fire TV APK are attached when the Android release key is configured. |
| iOS | arm64 | Unsigned developer `.ipa` for inspection; a signed App Store `.ipa` is also attached when Apple distribution signing and provisioning are configured. |
| tvOS | arm64 | Unsigned developer `.ipa` for inspection; a signed App Store `.ipa` is also attached when Apple distribution signing and provisioning are configured. |

Every binary/package release asset is listed in `SHA256SUMS.txt`. Build artifacts are covered by GitHub build-provenance attestations; the release checksum list and WinGet manifest bundle are attested during release assembly.

The Android APKs use the configured release key when all Android signing secrets are set. Without that keystore, the workflow falls back to its CI debug key, so those APKs support clean installs but cannot be relied on for in-place upgrades. The store-specific Android artifacts are omitted unless release signing is available. The iOS/tvOS developer IPAs are unsigned and cannot be installed as ordinary store or device builds.

There is no 32-bit x86 desktop package. Android `armeabi-v7a` is the 32-bit ARM target. The Flatpak files are bundles attached to GitHub Releases, not a Flathub publication. The `.msixbundle` is for [Partner Center submission](https://learn.microsoft.com/en-us/windows/apps/publish/); Microsoft signs the package after certification. It is not emitted until the fork's Store package identity is configured. Its version is `<major>.<minor>.<patch>.0`, so each Store release must increment the semantic version; Microsoft reserves the fourth field.

## Fork identity and compatibility

The Android application ID, Apple bundle IDs, Flatpak ID, and Linux desktop entry use `org.snapetech.plezyng`. The tvOS Top Shelf extension uses `org.snapetech.plezyng.TopShelfExtension` and the app group is `group.org.snapetech.plezyng`. This keeps new packages separate from upstream Plezy's store identities. The internal Android Kotlin namespace remains `com.edde746.plezy`.

Changing the install IDs means an install signed under upstream's identity cannot be updated by PlezyNG. Store users need PlezyNG's own listings and signing keys. The existing `plezy://` deep-link scheme remains in place.

## Package managers and stores

| Channel | State | How it works |
| --- | --- | --- |
| GitHub Releases | Active | Manual `PlezyNG Release` workflow builds and attaches packages. |
| Homebrew | Active | `update-packages.yml` updates the fork's cask and appcast after a published release. |
| WinGet | Wired, credential-gated | `publish-winget.yml` submits fork-specific manifests as a pull request. Microsoft review and merge are still required. |
| Chocolatey | Wired, credential-gated | `publish-chocolatey.yml` publishes the fork-specific package after a release. Chocolatey moderation may be required. |
| Microsoft Store | Package prepared, listing identity required | Set the repository variables below to build `plezyng-windows.msixbundle`; submit it through PlezyNG's Partner Center listing. The optional signed Inno Setup installer is also retained for manual EXE/MSI listing workflows. No automated Partner Center submission is configured. |
| Google Play | Wired, credential-gated | `publish-app-stores.yml` uploads the signed AAB to the selected track. It defaults to `internal` and `draft`; review and promotion happen in Play Console. |
| Amazon Appstore / Fire TV | Wired, credential-gated | The same manual workflow uploads the signed APK to Amazon. The upload is left pending review in the Appstore Console. |
| Apple App Store (iOS) | Wired, credential-gated | The manual workflow uploads the signed IPA to App Store Connect without submitting it to App Review. |
| Apple App Store (tvOS) | Wired, credential-gated | The manual workflow uploads the signed tvOS IPA to App Store Connect without submitting it to App Review. |
| Mac App Store | Not a Plezy upstream channel | Plezy distributes macOS through a direct DMG and Homebrew. |
| Snap Store | Wired, credential-gated | `publish-snap.yml` uploads the matching architecture package to `stable` after a published release. The Snap name must be registered, and `SNAPCRAFT_STORE_CREDENTIALS` must be scoped to that name. Manual dispatch can publish an existing release to `edge`, `beta`, `candidate`, or `stable`. |
| AUR | Wired, package and credential-gated | `publish-aur.yml` updates the binary package recipe after a published release. Register the selected package name first, then set `AUR_PACKAGE_NAME` and `AUR_SSH_KEY`. |
| Fedora COPR | Wired, project and credential-gated | `publish-copr.yml` builds an SRPM from the checked release bundles and submits it to `COPR_PROJECT`. The COPR project must include x86_64 and aarch64 chroots. |
| Launchpad PPA | Wired, archive and credential-gated | `publish-ppa.yml` signs and uploads source packages for Jammy and Noble after a published release. Set `LAUNCHPAD_PPA` and a Launchpad-registered `GPG_PRIVATE_KEY`. |
| Flathub | Not submitted | The attached Flatpak bundles use the prebuilt Linux bundle. Flathub requires its own source-built manifest submission and reviewer approval; it is not an automatic upload channel. |

The app-store workflow only accepts an already-published stable GitHub Release and does not build packages. Run it from `main`, select the release tag, then choose a target channel. Create PlezyNG's own app records/listings and reserve the fork bundle IDs before enabling these uploads; the workflow sends binaries only, with no listing metadata, screenshots, or review submission. There are no PlezyNG store listings yet; store packages appear only after the required signing credentials are configured.

The upstream [Plezy download guide](https://github.com/edde746/plezy#download) also lists Arch, Fedora/RHEL, Nix, and aerynOS channels. PlezyNG now publishes to AUR, COPR, and Launchpad PPA when their accounts are configured. Nix and aerynOS remain community-maintained package channels; Flatpak remains a GitHub bundle until a source-built Flathub submission is accepted.

## Required configuration

All credentials belong in GitHub Actions secrets or variables. Never put secret values in this document.

For iOS, the base64 export-options plist must declare `method` as `app-store-connect`, the matching `teamID`, and a `provisioningProfiles` entry for `org.snapetech.plezyng`. For tvOS, the plist also needs `org.snapetech.plezyng.TopShelfExtension`; the base64 profiles ZIP must contain provisioning profiles for both IDs. The App Store Connect `.p8` key is supplied as the raw PEM value in `APPLE_API_PRIVATE_KEY`. The MSIX identity values must match the package identity Microsoft assigns to the PlezyNG Partner Center listing.

| Channel | Secret names / repository variables |
| --- | --- |
| Android release signing (APKs, Play AAB, Amazon APK) | `ANDROID_KEYSTORE_BASE64`, `ANDROID_STORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS` |
| Google Play submission | `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` |
| Amazon Appstore submission | `AMAZON_APPSTORE_CLIENT_ID`, `AMAZON_APPSTORE_CLIENT_SECRET` |
| iOS App Store signing | `APPLE_DISTRIBUTION_CERTIFICATE_BASE64`, `APPLE_CERTIFICATE_PASSWORD`, `APPLE_TEAM_ID`, `IOS_PROVISIONING_PROFILE_BASE64`, `IOS_EXPORT_OPTIONS_PLIST_BASE64` |
| tvOS App Store signing | `APPLE_DISTRIBUTION_CERTIFICATE_BASE64`, `APPLE_CERTIFICATE_PASSWORD`, `APPLE_TEAM_ID`, `TVOS_PROVISIONING_PROFILES_ZIP_BASE64`, `TVOS_EXPORT_OPTIONS_PLIST_BASE64` |
| App Store Connect submission | `APPLE_API_KEY_ID`, `APPLE_API_ISSUER_ID`, `APPLE_API_PRIVATE_KEY` |
| Microsoft Store EXE installer signing | `WINDOWS_SIGNING_CERTIFICATE_BASE64`, `WINDOWS_SIGNING_CERTIFICATE_PASSWORD` |
| Microsoft Store MSIX bundle identity | Repository variables `MSSTORE_PACKAGE_NAME`, `MSSTORE_PUBLISHER`, and `MSSTORE_PUBLISHER_DISPLAY_NAME`, copied exactly from PlezyNG's Partner Center app identity |
| macOS Developer ID signing/notarization | `MACOS_CERTIFICATE_BASE64`, `MACOS_CERTIFICATE_PASSWORD`, `KEYCHAIN_PASSWORD`, `APPLE_ID`, `APPLE_APP_SPECIFIC_PASSWORD`, `APPLE_TEAM_ID` |
| Sparkle / WinSparkle update signatures | `SPARKLE_PRIVATE_KEY` |
| Chocolatey | `CHOCO_API_KEY` |
| WinGet | `WINGET_CREATE_GITHUB_TOKEN` (classic GitHub PAT with `public_repo` scope) |
| Snap Store | `SNAPCRAFT_STORE_CREDENTIALS` (exported Snapcraft credentials scoped to the registered PlezyNG snap and required channels) |
| AUR | `AUR_SSH_KEY` |
| Fedora COPR | `COPR_LOGIN`, `COPR_USERNAME`, `COPR_TOKEN`; repository variable `COPR_PROJECT` |
| Launchpad PPA | `GPG_PRIVATE_KEY`; repository variable `LAUNCHPAD_PPA` in `ppa:<owner>/<archive>` format |
| Relay Docker Hub mirror | `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN` |

GHCR uses the workflow's `GITHUB_TOKEN`; make the first package public in GitHub Packages settings if anonymous pulls are intended. The Discord publisher uses `DISCORD_RELEASE_WEBHOOK`. At the 2026-10-25 settings check, that was the only configured Actions secret and there were no repository variables; add the channel-specific values above before expecting publisher workflows to submit packages.

## Relay containers

The container is only the Go OAuth/artifact relay in `server/`; it is not the Flutter client. After a stable GitHub Release is published, `release-containers.yml` builds `linux/amd64` and `linux/arm64` and publishes version and `latest` tags to GHCR. Docker Hub is a multi-architecture mirror when its credentials are configured. `docker.io` is Docker Hub's registry address, not another registry.

```text
ghcr.io/snapetech-org/plezyng-relay:<version>
ghcr.io/snapetech-org/plezyng-relay:latest
docker.io/snapetech/plezyng-relay:<version>   # when Docker Hub credentials are set
docker.io/snapetech/plezyng-relay:latest      # when Docker Hub credentials are set
```

## Release checklist

1. Update `pubspec.yaml` and add user-facing bullets under `CHANGELOG.md` → `[Unreleased]`.
2. Commit and push the release preparation to `main`.
3. Run **PlezyNG Release** manually from `main`, with `release_tag` exactly equal to the application version.
4. Review the draft notes, package list, `SHA256SUMS.txt`, and provenance attestations.
5. Publish the draft. Discord and configured downstream package channels run from the published-release event.
6. To update a mobile store, run **Publish PlezyNG store builds** manually from `main` after the stable GitHub Release is published, then finish review/promotion in the store console.
7. Submit a configured MSIX bundle manually through Partner Center. Confirm GHCR has both architectures; check Docker Hub, Chocolatey, and WinGet only when their credentials are configured, and track Microsoft's WinGet pull request separately.
