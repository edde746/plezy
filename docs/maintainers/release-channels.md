# PlezyNG release channels

This is the release support boundary. A platform or package manager is supported only when its output is produced by the versioned release workflow and attached to that release, or when its publisher workflow submits the matching release asset.

## Release trigger

`.github/workflows/build.yml` runs only from a manual dispatch on `main`. The requested semantic version must match `pubspec.yaml`; the workflow builds every configured target, renders notes from `CHANGELOG.md`, adds checksums and attestations, and opens a draft GitHub release. Review the assets and notes, then publish the draft.

Push and pull-request CI still runs analysis and tests. It does not build release packages or publish images. Publishing a draft release starts the downstream Discord, Homebrew/appcast, Chocolatey, WinGet, and relay-container workflows.

## Client packages on GitHub Releases

| Platform | Architectures | GitHub Release assets |
| --- | --- | --- |
| Windows | x64, arm64 | Combined Inno Setup installer, per-architecture portable `.7z`, Chocolatey `.nupkg`, and versioned WinGet manifest bundle |
| macOS | x64, arm64 | DMG, Sparkle appcast; Homebrew cask metadata is updated after publication |
| Linux | x64, arm64 | Portable `.tar.gz`, Debian `.deb`, RPM `.rpm`, Arch `.pkg.tar.zst`, and Flatpak bundle for each architecture |
| Android | arm64-v8a, armeabi-v7a, x86_64 | Split APK archives; a signed universal `.aab` is included when Android signing secrets are configured |
| iOS | arm64 | Unsigned developer `.ipa` for inspection and internal tooling; it is not an App Store or device-installable release |
| tvOS | arm64 | Unsigned developer `.ipa` for inspection and internal tooling; it is not an App Store or device-installable release |

Every attached binary/package asset is listed in `SHA256SUMS.txt`. Platform build artifacts are covered by GitHub build-provenance attestations; the WinGet manifest bundle and release checksum list are attested during release assembly.

Android APKs use the stable project signing key when all Android signing secrets are configured. Without that keystore, the workflow falls back to its CI debug key, so those APKs are suitable for clean installs but cannot be relied on for in-place upgrades between releases. iOS and tvOS bundles remain unsigned developer packages until Apple distribution signing and provisioning are configured.

This project does not currently build 32-bit x86 desktop packages. Android's `armeabi-v7a` APK is the 32-bit ARM target. The Linux Flatpak is a release bundle attached to GitHub Releases, not a Flathub publication. No AppImage, Snap Store, AUR, COPR, or Launchpad PPA publisher is wired yet.

## Windows package-manager channels

- Chocolatey package ID: `plezyng`. The package is attached to every GitHub release. `publish-chocolatey.yml` validates its installer URL and SHA-256 before pushing it to Chocolatey Community Repository. It runs after a published release when `CHOCO_API_KEY` is configured; a manual run can validate a package or retry publication.
- WinGet package ID: `SnapeTech.PlezyNG`. The release contains the three versioned manifests in `plezyng-winget-manifests-<version>.zip`. `publish-winget.yml` checks the installer and manifest checksums before submitting a pull request to Microsoft's community manifest repository. That PR still goes through Microsoft's review and merge process.

The package IDs deliberately distinguish the fork from upstream, which already publishes `plezy` on Chocolatey and `edde746.Plezy` on WinGet.

## Relay containers

The container is only the Go OAuth/artifact relay in `server/`; the Flutter client is distributed through the native packages above.

After a stable GitHub release is published, `release-containers.yml` builds the relay for `linux/amd64` and `linux/arm64`, publishes version and `latest` tags to GHCR, then verifies the GHCR manifest. Docker Hub is a multi-architecture mirror enabled by `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN`. `docker.io` is Docker Hub's registry address, not an additional registry.

```text
ghcr.io/snapetech-org/plezyng-relay:<version>
ghcr.io/snapetech-org/plezyng-relay:latest
docker.io/snapetech/plezyng-relay:<version>   # when Docker Hub credentials are set
docker.io/snapetech/plezyng-relay:latest      # when Docker Hub credentials are set
```

The same workflow accepts a manual retry for an already published release. It has no `push` or `pull_request` trigger.

## Existing and gated channels

| Channel | State | Setup needed |
| --- | --- | --- |
| GitHub Releases | Active | None beyond GitHub Actions permissions |
| Homebrew cask | Active | `update-packages.yml` updates the checked-in cask and appcast branch after release publication |
| GHCR | Active | `GITHUB_TOKEN` with repository `packages: write` permission; set the first pushed package to public in GitHub Packages settings if anonymous pulls are intended |
| Docker Hub | Wired, credential-gated | `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`; create `snapetech/plezyng-relay` first if the namespace does not auto-create it |
| Chocolatey | Wired, credential-gated | `CHOCO_API_KEY`; Community Repository moderation is still required for each new package version |
| WinGet | Wired, credential-gated | `WINGET_CREATE_GITHUB_TOKEN` (GitHub classic PAT with `public_repo` scope); Microsoft's repository must review and merge each submitted version |
| Android App Bundle | Built when signed | `ANDROID_KEYSTORE_BASE64`, `ANDROID_STORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS` (also required for stable APK upgrades) |
| Android Play Store | Not wired | Google Play service account, track policy, and a signed AAB upload path |
| iOS/tvOS Store | Not wired | Apple Developer distribution certificates, per-platform provisioning profiles, and App Store Connect credentials |
| macOS Developer ID and notarization | Optional existing steps | `MACOS_CERTIFICATE_BASE64`, `MACOS_CERTIFICATE_PASSWORD`, `KEYCHAIN_PASSWORD`, `APPLE_ID`, `APPLE_APP_SPECIFIC_PASSWORD`, `APPLE_TEAM_ID` |
| Sparkle/WinSparkle updates | Optional existing steps | `SPARKLE_PRIVATE_KEY` |
| Flathub, Snap Store, AUR, COPR, Launchpad PPA | Not wired | Each requires its own account, credentials, package identity, and external review or repository setup |

No package registry secret values belong in this document. Check GitHub repository secret names before a release; as of this wiring pass, only the Discord release webhook was configured.

## Release checklist

1. Update `pubspec.yaml` and add user-facing bullets under `CHANGELOG.md` → `[Unreleased]`.
2. Commit and push the release preparation to `main`.
3. Run **PlezyNG Release** manually on `main`, with `release_tag` exactly equal to the application version.
4. Review the draft release notes, asset list, `SHA256SUMS.txt`, and available provenance attestations.
5. Publish the draft. Discord and the configured downstream package channels run from the published-release event.
6. Confirm the GHCR image has both architectures. Confirm Docker Hub, Chocolatey, and WinGet only when their credentials are configured; check Microsoft's PR status separately.
