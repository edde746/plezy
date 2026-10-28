# Branch consolidation — 2026-10-27

This integration combines the seven open pull requests (#25, #28, #31, #32,
#33, #35, #36) and the remaining unpublished branch work. The original repository
had 79 branches, including `main`; no `master` branch existed. A Tizen TV
branch and PR #37 appeared during final verification and were also integrated, bringing
the reviewed inventory to 80 branches. Every recorded
branch head remains reachable through the consolidation commit's parents. Removing
a branch name therefore does not remove its original commits or prevent recovery.

## Resolution decisions

- Retain durable downloads, quotas, shared-library pairing and identity migration,
  sync compaction/recovery, NFS read-ahead, comic streaming and native-reader work.
- Combine Games/Steam catalog, account-linking, native controls, remote play and
  workspace ownership changes. Port accessibility fixes onto the shared Steam view
  instead of restoring the superseded full-activity implementation.
- Combine the Dolby Vision compatibility and experimental FEL changes; retain
  capability checks and distinguish an active filter graph from qualified output.
- Retain the newly published experimental Tizen TV port, native media plugins,
  conservative server profiles and signed-TPK tooling. Preserve the DV compatibility
  and workspace changes in overlapping factories, settings and Plex negotiation.
- Retain the current private JIT runner routing. Discard older hosted-runner and
  automatic PR/push trigger changes. Keep the latest main build-only action and
  webOS validation/redistribution gates together. CI, native validation and CodeQL
  remain manually dispatched; existing release-published package jobs are retained.
- Keep the current comic-inclusive product artwork and branding. Merge individual
  UI focus, accessibility, text-scaling and navigation fixes, resolving overlapping
  implementations rather than replacing entire feature files.
- Regenerate Slang translations and Flutter plugin registration from the integrated
  inputs. Existing translated text is preserved; new untranslated strings use the
  existing English fallback.

## Integration repairs

Tests exposed an invalid FTS5 delete command in the library cache. Schema 9 rebuilds
only that derived index, preserves source entries, and repairs update/delete
triggers. A regression test upgrades a real schema-8 database and verifies data,
search updates and deletion. Delivery-only `streamOnly` flags no longer change
content fingerprints, preserving reading progress and cached editions. Cloud-sync
publication keeps independent provider writes pending until their own acknowledgement.

Additional repairs cover duplicate declarations, outdated Dart/Flutter APIs,
workspace accessibility semantics, native Steam button sizing and control visibility,
runner matrix routing, build/release guards, and fixtures for merged functionality.

## Validation

- Flutter: 312 tests passed, 3 explicitly skipped, covering Games, Multiview, Sources,
  sync, downloads, database migration, DV playback, player channels, settings,
  performance statistics and video volume.
- Flutter analysis: no errors or warnings; 53 informational lints remain, including
  existing vendored-package diagnostics.
- Python guard suite: 194 existing tests passed across the initial run and targeted
  reruns; the current build-workflow suite passes all 15 tests, including the added
  build-only release guard.
- Dolby Vision tooling: 103 Python tests passed; 45 native Kotlin/JUnit policy tests
  passed; the C++ render API smoke test compiled and passed.
- Native Steam: all Java sources compiled against the Android SDK with generated
  resources from the actual XML resource files.
- WebOS packaging/release tests: 16 passed. Comic layout Node tests: 5 passed.
- Go server and health-check packages: `go test ./...` passed with Go 1.27.3.
- Tizen integration: 35 host/playback regression tests, 3 Tizen-defined platform/Plex
  tests, and 7 packaging tests passed.
- Git whitespace/conflict-marker checks passed.

This does not claim device/NAS/pixel qualification or a complete release build.
The Steam connected-experience strings with no reviewed translation are listed in
`lib/i18n/english_fallbacks.json`; Slang uses the English source at runtime and the
localization gate reports the fallback debt. Missing strings outside that list
still fail validation. Language review remains outstanding. No release or platform
build was dispatched as part of code integration.

## Recovery inventory

The adjacent JSON manifest records exact branch heads. To recover a branch later,
create a new branch at its recorded SHA; no force push or file reconstruction is
needed. Branch deletion must check that its current head still matches this manifest
and is an ancestor of the published main. Changed or newly created branches must
be reviewed again rather than deleted automatically.

| Branch | Preserved head | Disposition |
| --- | --- | --- |
| `audit/books-audiobook-focus-20261026` | `bc78eb957b5df633892e8cc954e6b4b60ac2a161` | History retained; remove branch name |
| `audit/books-cloud-source-icons-20261026` | `5bf49ce15c1940d02a57404dba09bc245ddee3c8` | History retained; remove branch name |
| `audit/books-public-lending-focus-20261026` | `93bc073741025e3984ea7f44d7fdd5642d169932` | History retained; remove branch name |
| `audit/comic-pr25-ux-remediation-20261026` | `08031f36f98d649a7edc6088db75d1a9403d5f8f` | History retained; remove branch name |
| `audit/comics-feature-audit-20261026` | `5d2fe21fa067747789b76f3d0f65a659b65bc148` | History retained; remove branch name |
| `audit/dv-ui-polish-20261026` | `b9cc1fe815af2b794c89c65effafea981651f5d6` | History retained; remove branch name |
| `audit/fork-ux-polish-followup-20261026` | `2e1d9dbc7550cb721a1b7cfaf3e600e910732ead` | History retained; remove branch name |
| `audit/games-native-touch-ux-20261026` | `435e4f1bd63a48293e9a0dfc7251f7397ed65ac7` | History retained; remove branch name |
| `audit/games-pr28-focus-20261026` | `b1a4994fbcc003add14f98476f656046ac60e476` | History retained; remove branch name |
| `audit/games-pr28-ui-followup-20261026` | `2156ab870680456007dcc3e615f297f9fea269a2` | History retained; remove branch name |
| `audit/global-access-ux-20261026` | `42629947f1d57f29f320c59a964fda1d005a6c20` | History retained; remove branch name |
| `audit/login-settings-nav-polish-20261026` | `ae0861ce1f8667c760de5b983954a161c6e3488a` | History retained; remove branch name |
| `audit/login-site-art-copy-20261026` | `072406c3bf89c53381e566f362b8c5ee473c8f88` | History retained; remove branch name |
| `audit/nonpip-ui-followup-20261026` | `621562b0820554e5833ac2a36bdba709cd88f4cf` | History retained; remove branch name |
| `audit/pr31-50ce-ux-20261026` | `d14935b2183d530e2a0eda34f4dbb903a972a249` | History retained; remove branch name |
| `audit/pr31-85c1-ux-20261026` | `ba245b5a50900448bc9bf35315446111515a6138` | History retained; remove branch name |
| `audit/pr31-ff9d-ux-20261026` | `799b2a9c330c618a77a439da73206e3dc17c6d3c` | History retained; remove branch name |
| `audit/pr31-head-5b1361a6-ux-20261026` | `e00ff637eff6745b4c3b37f161e651c88ffc557b` | History retained; remove branch name |
| `audit/pr31-integrated-ux-5b1361a6-20261026` | `ddd766cebd0f8566ae909afd6d5975f81a7e0963` | History retained; remove branch name |
| `audit/pr31-profile-ui-fixes-20261026` | `8a81dfe35f29faa8985aa82815dcded6175aa132` | History retained; remove branch name |
| `audit/pr31-source-nfs-ux-ffd0668-20261026` | `8291cce5fef4016c11d2c498f0e996e83c82569f` | History retained; remove branch name |
| `audit/pr31-ui-focus-371a16-20261026` | `24cfd157e4eb57e48e3a45c12e79c509d2f9e453` | History retained; remove branch name |
| `audit/pr31-ui-focus-20261026` | `f6b3ea08307bc614368371f2f20f76de15059d33` | History retained; remove branch name |
| `audit/pr31-ux-214382-20261026` | `d843eaf9160f4f2b8c7dff82bc9168c9ed2f1991` | History retained; remove branch name |
| `audit/ux-find-next-focus-fix-20261026` | `d6402a5e820c345d14bf76eedba7cded43f9e021` | History retained; remove branch name |
| `audit/ux-polish-comics-followup-20261026` | `04be7a23d0280ae89e90366ebaa334a09a99322d` | History retained; remove branch name |
| `audit/ux-polish-comics-pr25-20261026` | `a4c646dade4a8b7520080a16f6ac25c745e3abf1` | History retained; remove branch name |
| `audit/ux-polish-dv-player-20261026` | `6d1bbf8f2c8336c14b671d054a77c4cc5d8b9d37` | History retained; remove branch name |
| `audit/ux-polish-games-pr28-20261026` | `85c95f738ba15b4703d9d83a1b32ebd5e4af36ec` | History retained; remove branch name |
| `audit/ux-polish-games-tv-text-input-20261026` | `227e1fffdee737910bfba6527d6ff5971e7a22b6` | History retained; remove branch name |
| `audit/ux-polish-global-20261026` | `15f2099391f1c6a1b2e3692f4376572d2eca9a9e` | History retained; remove branch name |
| `audit/ux-polish-interactions-20261026` | `5bd70156dd810bf8e021ddf51c2957c092f428e9` | History retained; remove branch name |
| `audit/ux-polish-lending-20261026` | `8bb37d3e66f800fe5874b3a3b51502a04dd5c74d` | History retained; remove branch name |
| `audit/ux-polish-merged-media-20261026` | `e377276fc77d7c8d977d9d3df38310e58daa9567` | History retained; remove branch name |
| `audit/ux-polish-mobile-nav-overflow-20261026` | `a43dc42674b1534f1451d63faab3c99c0fe745dc` | History retained; remove branch name |
| `audit/ux-polish-multiview-followup-20261026` | `a297e1298a928efc1d66acc290d7ab6da3f57533` | History retained; remove branch name |
| `audit/ux-polish-multiview-pr32-live-20261026` | `39095cb3c407f3b0b52e3013affaa7ee4bfce57e` | History retained; remove branch name |
| `audit/ux-polish-pr32-multiview-final-20261026` | `16993ddda1e6610a12b0f291baa267d9a4fa3fae` | History retained; remove branch name |
| `audit/ux-polish-pr32-platform-20261026` | `0f8eedaa642883fba2751cc95f61e61c46b17fac` | History retained; remove branch name |
| `audit/ux-polish-remaining-20261026` | `656aa9e6c630e956dbca93ada515e6211e8fd232` | History retained; remove branch name |
| `audit/ux-polish-settings-preroll-20261026` | `b2808ac03ffb65056409fc3ee51c55d61567959b` | History retained; remove branch name |
| `audit/ux-polish-steam-touch-pr32-20261026` | `1c91c62762b3f480e6d5074a6d7ce04fae1bd6e9` | History retained; remove branch name |
| `audit/ux-polish-swipe-followup-20261026` | `479f5860ff3d65a807399b60a0bd5b3dbb72e979` | History retained; remove branch name |
| `audit/webos-login-focus-20261026` | `a640ed21237153ea3c82b9d2c70895c5538b0def` | History retained; remove branch name |
| `codex/audiobook-cloud-sync-20261026` | `189feda40be1a6df69cbd77388957aebf5473ec3` | History retained; remove branch name |
| `codex/audiobook-cloud-sync-complete-20261026` | `91885019f044e5d606e07f48a57a3c1f711d2430` | History retained; remove branch name |
| `codex/audit-remediation-20261026` | `4d801c26b4ddec93afae167bd8250010d67fb9b0` | History retained; remove branch name |
| `codex/books-cloud-sources-20261026` | `d2fec8fd3aec321a627ced7ec25bc33533d275a2` | History retained; remove branch name |
| `codex/ci-pin-swift-collections` | `c2aec4e3dde439a4865cade9456cc5a93b237bfd` | History retained; remove branch name |
| `codex/comic-expansion-20261026` | `e5376b41058347c1e10fd5c3db4eb5c85a03ab23` | History retained; remove branch name |
| `codex/comic-reader-display-20261026` | `4ac31e0edd1431139ae62fd3b7a91ca010836dd5` | History retained; remove branch name |
| `codex/comprehensive-localization-20261026` | `417cd294fe74271b3a536108d03f21e7e304d603` | History retained; remove branch name |
| `codex/cross-media-swipe-plan-20261025` | `6a9ec0297caae2d967b792e7bf2b9d249976f345` | History retained; remove branch name |
| `codex/dv-all-platforms-20261026` | `e1333813e2a2e95130da6df446896b2cf0f8d274` | History retained; remove branch name |
| `codex/dv-client-conversion-20261026` | `a7dabeb535812e57fe1fe053bb7c574ec5b549a2` | History retained; remove branch name |
| `codex/dv-experimental-engine` | `f3ed70a69a4c59addf7ddce5c0104995ab31888e` | History retained; remove branch name |
| `codex/dv-fel-graph-qual-20261026` | `552af300eee0754698fb123b5e193428528f1c7f` | History retained; remove branch name |
| `codex/dv-platform-20261026` | `7bb3a2b88d8fd0576f93b5545d16765a27247ece` | History retained; remove branch name |
| `codex/fix-trial-tests` | `3e088fce817ae7fc6c23d5b735e8354987f61cc3` | History retained; remove branch name |
| `codex/games-embedded-grid-20261026` | `741397ea8afd80a0e5bef297303a34e534d75661` | History retained; remove branch name |
| `codex/infuse-smb-video-20261026` | `2012ba8110a7f8b9ed10ac3724f58fa2e0e14d46` | History retained; remove branch name |
| `codex/localization-source-qa-20261026` | `c93850d623d9339dd4640e52d78d0650905d06ef` | History retained; remove branch name |
| `codex/login-background-site-art-20261026` | `af18fc54e4657a1c1acb56cbebfba995b2ad20cb` | History retained; remove branch name |
| `codex/multiview-workspace-20261026` | `8d46150b4c3c6a21e821da262004d1f2aa45de2c` | History retained; remove branch name |
| `codex/packer-windows-jit-labels-20261026` | `b297e466ec3cbff2769eb258361d1b9506c84907` | History retained; remove branch name |
| `codex/plezyng-ng-brand-assets-20261026` | `8875a9b530dd7c95139e8553bcc07691e199bfc9` | History retained; remove branch name |
| `codex/plezyng-private-codeql-20261026` | `9665961ec0e8d7d5fef2ec214d935e4c0c53541c` | History retained; remove branch name |
| `codex/plezyng-shared-jit-20261026` | `ca20244683feba49b92e7ff7a80934b84fba1bd9` | History retained; remove branch name |
| `codex/plezyng-swipe-impl-20261026` | `c2ceaa4e87f5aa8af7a8400f2cd33c081cc1041f` | History retained; remove branch name |
| `codex/plezyng-webos-release-integration-20261026` | `a71d3468405fe0bf90879ff3ccee9d081e8b0679` | History retained; remove branch name |
| `codex/swipe-screen-guidance-20261026` | `56ba4ccba8bf803d14bdf79f6bae26dbf4960d2e` | History retained; remove branch name |
| `codex/webos-release-tooling-20261026` | `47bf1c9c21dafda22c980870752584bc06919035` | History retained; remove branch name |
| `codex/webos-runtime-fix-20261025` | `3f3e111b6703aacc4dc9fb97185df5cdfb39b29d` | History retained; remove branch name |
| `codex/webos-sdk-release-20261026` | `9a5b56158566ed9c68ca32438227480c848e060a` | History retained; remove branch name |
| `dependabot/github_actions/ruby/setup-ruby-1.331.0` | `7265a6f84a1c631e4664dcc6a420eba92df62bcd` | History retained; remove branch name |
| `fix/ios-audio-order-test-nullability` | `98867e2fc1d6fe7649f0fe9bff735c7690b3762c` | History retained; remove branch name |
| `main` | `08cda8192c6ba876e29bbc5a0aff8fb2339defb2` | Keep |
| `review/pr28-games-ux-fixes-20261026` | `1f3a9ba4f87e6be49c48fe0098be520281922f29` | History retained; remove branch name |
| `review/pr32-input-ownership-20261026` | `710fe9f10077328dff8fb4bfb0f86379680037ee` | History retained; remove branch name |
| `codex/tizen-tv-20261026` | `67449a7a5ae59bcd5c43b1f47f70d5cffef7725b` | History retained; remove branch name |

## Branch-name cleanup

The integration is published at `0a56d1c9843e7bda8bac036a0190cc14a0ca9d04`.
GitHub marked all eight reviewed PRs merged. The connector does not expose branch
deletion, and the temporary private cleanup workflow produced no Actions run;
manual-only CI was restored exactly. No branch-name deletion was claimed.

The guarded cleanup helper is ready for an authenticated Git environment:

```sh
python3 scripts/maintainers/cleanup_consolidated_branches.py
python3 scripts/maintainers/cleanup_consolidated_branches.py --apply
```

The first command previews. The second deletes only recorded heads still matching
the inventory and proven ancestors of the integration commit. It rejects new or
changed work, preserves `main`/`master`, and uses an atomic push with an exact-SHA
lease for every deletion. Ten unit tests cover these safety conditions. The helper
reads the manifest from the current remote main, so a stale local copy cannot
silently authorize different deletions.
