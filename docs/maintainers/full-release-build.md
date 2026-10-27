# One-command full release build

Run the release orchestrator from an authenticated `gh` session:

```sh
python3 scripts/release_all_platforms.py --version 2.25.0
```

The command coordinates the existing private JIT workflows in order. It reuses
an active native build when one exists; otherwise it verifies the current
native manifest and dispatches `snapetech-org/mpv-build` if the published
artifacts are stale or incomplete. It verifies Apple, Android, Linux, and
Windows native groups before touching PlezyNG.

After native artifacts verify, the command verifies the FFmpeg source archive
signature against FFmpeg's pinned release-key fingerprint, records its exact
SHA-256 in the Android header build, and runs
`scripts/set_native_revision.sh` for the published artifact-manifest commit.
It pushes that focused pin update to PlezyNG `main`, waits for CI on that exact
commit, creates the matching `v<version>` tag, and dispatches the all-platform
release build. The release build includes the webOS and Tizen ARM candidates by
default. Apple jobs refresh their SwiftPM mirror after the native pin changes.

The webOS candidate is built but kept out of public release assets unless the
existing artifact eligibility gate passes and the operator opts in:

```sh
python3 scripts/release_all_platforms.py --version 2.25.0 --include-webos-release
```

Tizen remains a build artifact for qualification. Store submissions remain
separate because Google, Apple, Amazon, Samsung, and LG have account, review,
signing, or device-qualification steps beyond producing the release files.

The orchestrator uses the current machine's GitHub CLI authentication only for
workflow dispatch, repository commits, and the version tag. Build, test,
package, and release jobs still use their configured private JIT runner groups;
the script has no hosted-runner option and does not store or print credentials.
It stops on a failed native group, FFmpeg signature, CI run, tag conflict, or
release build. Re-running it reuses successful native/CI/release runs and never
moves an existing tag.

The final JSON receipt is written to the printed scratch directory. Temporary
checkouts and the verified source archive are removed after the workflow run;
GitHub retains the workflow logs and release artifacts.
