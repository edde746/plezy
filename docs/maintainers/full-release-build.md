# One-command PlezyNG 3.0.0 release

After the native, Apple, Linux/Android, Windows, webOS, and Tizen private-JIT
routes pass their current-revision canaries, run the complete release from an
authenticated `gh` session:

```sh
python3 scripts/release_all_platforms.py --version 3.0.0 --publish \
  --scratch /mnt/disks/gamespool0/plezyng-release-3.0.0-20261027
```

The command coordinates the existing private JIT workflows in order. It reuses
an active native build when one exists; otherwise it verifies the current
native manifest and dispatches `snapetech-org/mpv-build` if the published
artifacts are stale or incomplete. It verifies Apple, Android, Linux, and
Windows native groups before touching PlezyNG.

When a completed native run has failed platforms, the orchestrator can recover
other groups whose publishing jobs succeeded. It checks the manifest artifact's
GitHub digest, the current source content keys, and every published asset's
checksum before recording that group on native `main`. Only manifests from an
explicit private build of an ancestor of current `main` are eligible. The next
native build then rebuilds only the groups still stale. A partial recovery never
updates PlezyNG's pins or bypasses the final all-platform verification.

Android CI, release, and embedded-engine workflows share
`scripts/prepare_android_sdk.py`. It configures Java and Gradle proxy settings
before SDK setup, reads every checked-in Android module's SDK/NDK/CMake pins,
installs those exact packages, and checks the installed tools. This includes
Steam's CMake 3.22.1 alongside the app/libass CMake 4.1.2. A fresh runner must
not depend on Gradle silently downloading missing toolchains during compilation.

After native artifacts verify, the command verifies the FFmpeg source archive
signature against FFmpeg's pinned release-key fingerprint, records its exact
SHA-256 in the Android header build, and runs
`scripts/set_native_revision.sh` for the published artifact-manifest commit.
It pushes that focused pin update to PlezyNG `main`, waits for CI on that exact
commit, creates the matching `v<version>` tag, and dispatches the all-platform
release build. The release build compiles the webOS and Tizen ARM candidates by
default. The validated Tizen tester package and its re-signing handoff are
attached to the versioned release. The webOS IPK remains excluded from public
release assets until the existing artifact eligibility gate passes and the
operator opts in. Apple jobs refresh their SwiftPM mirror after the native pin
changes.
Before publication, the orchestrator checks that every required release asset
exists. `--publish` then promotes the GitHub draft and sequentially dispatches
the configured store, package, container, appcast, and Discord workflows. It
reuses successful channel runs and stops on a prior failed run rather than
repeating an external side effect blindly.

The webOS candidate is built but kept out of public release assets unless the
existing artifact eligibility gate passes and the operator opts in:

```sh
python3 scripts/release_all_platforms.py --version 3.0.0 --include-webos-release --publish \
  --scratch /mnt/disks/gamespool0/plezyng-release-3.0.0-20261027
```

Tizen remains a tester artifact for qualification; Seller Office signing and
submission are not configured. App Store Connect and Amazon uploads do not
submit builds for review. Google Play is sent to the internal draft track.
Microsoft Store, Samsung Seller Office, macOS Developer ID signing, Windows
Authenticode signing, and LG public IPK publication remain gated on their
missing identities, profiles, credentials, or artifact approvals.

The orchestrator uses the current machine's GitHub CLI authentication only for
workflow dispatch, repository commits, and the version tag. Build, test,
package, and release jobs still use their configured private JIT runner groups;
the script has no hosted-runner option and does not store or print credentials.
It stops on a failed native group, FFmpeg signature, CI run, tag conflict, or
release build. Re-running it reuses successful native/CI/release runs and never
moves an existing tag.

The final JSON receipt is written to the printed scratch directory. Temporary
checkouts and the verified source archive are removed after the workflow run;
GitHub retains the workflow logs and release artifacts. The scratch directory
and its receipt remain for review and should be cleaned only after the release
has completed and its outputs have been transferred or retained deliberately.
