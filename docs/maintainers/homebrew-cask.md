# Homebrew Cask release preparation

The release workflow can produce a version-pinned Cask candidate for each stable macOS release. The candidate is generated only when `prepare_homebrew_cask` is enabled for a full release run.

## Release requirements

- The macOS app must be signed with a Developer ID Application certificate, notarized by Apple, stapled, and pass the workflow Gatekeeper assessment.
- Configure `MACOS_CERTIFICATE_BASE64`, `MACOS_CERTIFICATE_PASSWORD`, `KEYCHAIN_PASSWORD`, `APPLE_ID`, `APPLE_APP_SPECIFIC_PASSWORD`, and `APPLE_TEAM_ID` as repository or organization secrets. The ordinary release path stays optional-signing; the Homebrew option fails closed if any signing or notarization credential is missing.
- Dispatch the workflow against a stable `vMAJOR.MINOR.PATCH` tag with action `release` and mode `release`, then enable `prepare_homebrew_cask`.
- The run attaches `snapetech-plezyng.rb` to the draft release and attests that candidate. Publish the release before submitting or installing the Cask because Homebrew must be able to fetch the versioned DMG from the public release URL.
- Verify the published `plezy-macos.dmg` checksum matches the `sha256` in the candidate and confirm the asset URL uses the `vMAJOR.MINOR.PATCH` release tag.

## Official Homebrew submission

Use the generated Cask as `Casks/s/snapetech-plezyng.rb` in `Homebrew/homebrew-cask`. The `snapetech-` prefix distinguishes this fork from the upstream Plezy app, and the installed bundle is named `PlezyNG.app` to avoid an `/Applications/Plezy.app` collision.

Before opening a submission, review the current Homebrew Cask acceptance policy and contribution guide. New Casks must pass Gatekeeper without removing quarantine, include the required metadata and zap stanza, and pass the current audit and style checks. Homebrew may decline self-submissions that do not meet its current repository age and popularity criteria. Disclose AI assistance if the current contribution process requests it, and review all generated content yourself.

Run the checks against the generated file in a Homebrew checkout:

```sh
brew audit --cask --new Casks/s/snapetech-plezyng.rb
brew style --cask Casks/s/snapetech-plezyng.rb
```

Submit the reviewed Cask to the official `Homebrew/homebrew-cask` repository using its current contribution process. Do not submit the template or a candidate that points to a draft release.

## Generate locally

After a release build has been verified as signed and notarized, the candidate can also be rendered from the release checksum manifest:

```sh
python3 scripts/generate_homebrew_cask.py \
  --version 2.25.0 \
  --checksums artifacts/SHA256SUMS.txt \
  --output artifacts/homebrew/snapetech-plezyng.rb
```

Replace the example version with the exact stable release version. The generator requires exactly one checksum entry for `plezy-macos.dmg` and rejects prerelease or malformed versions.

## Custom tap option

For distribution before an official Homebrew Cask is accepted, commit the generated file as `Casks/snapetech-plezyng.rb` in a tap repository and document the tap install command for users. Keep the version and checksum pinned to a published release; do not use a moving `latest` DMG URL.

The old `Casks/plezy.rb` entry remains a legacy custom-tap token, but its quarantine-removal postflight has been removed; do not restore it. The pinned legacy app must pass Gatekeeper on its own. Replace the old entry with a generated, signed and notarized Cask when the first eligible release is available.
