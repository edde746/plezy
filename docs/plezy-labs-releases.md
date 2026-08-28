# Plezy Labs releases

Plezy Labs releases are built only from the `labs` branch. Every candidate is
reconstructed from an exact published Plezy tag, followed by the Labs core and
the enabled feature overlays in `tool/labs_features.json`. Unreleased upstream
history is never merged into Labs.

## Feature overlays and backports

Normal features record immutable native commit SHAs. An ahead-of-release
feature may also record compatibility commits and a `use_native_after` upstream
commit. Reconstruction uses the compatibility backport until the official tag
contains that prerequisite, then switches to the native commits automatically.
If either form is already official, no overlay is applied. Partial adoption,
missing commits, or conflicts stop the release before publishing.

Keep every referenced feature and backport source branch available on the fork.
Branch names are labels; the immutable SHAs in the manifest select the code.
When a feature has an upstream Plezy pull request, record its URL as
`upstream_pr`; generated Labs release notes link the applied feature to that PR.

## One-time repository setup

1. Push `labs` and make it the fork's default branch so the scheduled watcher
   runs from the Labs workflow definitions.
2. Run `scripts/generate-labs-updater-key.sh`, back up the private key, and set
   the printed `LABS_SPARKLE_PRIVATE_KEY` secret and
   `LABS_UPDATE_PUBLIC_KEY` repository variable.
3. Configure the same macOS Developer ID and notarization secrets used by the
   inherited desktop build: `MACOS_CERTIFICATE_BASE64`,
   `MACOS_CERTIFICATE_PASSWORD`, `KEYCHAIN_PASSWORD`, `APPLE_ID`,
   `APPLE_APP_SPECIFIC_PASSWORD`, and `APPLE_TEAM_ID`.
4. In GitHub notification settings, select failed-workflow-only notifications.

The build deliberately fails instead of publishing unsigned macOS or unsigned
Sparkle/WinSparkle update artifacts when any required value is missing.

## Publishing

- Run **Plezy Labs** for a normal Labs change. It computes the next revision
  and updater build, then creates a draft GitHub release.
- The generated description lists the applied Labs feature overlays first and
  embeds the official Plezy release notes below them. Edit it if desired
  before publishing. The final GitHub Release description is the only
  release-notes source used by the app and native updater.
- The daily watcher runs at 8:00 AM in `America/New_York`. It can also be run
  manually. A clean new official release sync automatically publishes revision
  1; conflicts create an issue and publish nothing.

Official-to-Labs and Labs-to-official transitions are replacement installs.
Only Labs-to-Labs updates use the native updater.
