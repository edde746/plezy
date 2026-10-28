# PlezyNG audiobook improvements and cloud state sync — recovery checkpoint

Status: historical recovery checkpoint from 2026-10-26. The reconstructed bundle has not been reconciled against current main or validated as a complete change.

Current-state note: this checkpoint was written against an older `main` snapshot. Current `main` includes the file/book foundation and a base encrypted progress-sync implementation. The recovered refinements below may overlap or conflict with that implementation; preserve the original current implementation and review every transformation before applying anything.

The execution environment disconnected during implementation and became unavailable. The GitHub connector remained available. This document and the recovery bundle preserve the authored changes without pretending that unavailable working files or unfinished tests were merged.

## Research and prioritization

Confidence is high that the following requests recur across audiobook communities and established clients. Confidence in their exact relative popularity is moderate: the sources are qualitative, not a representative survey. The order below is an engineering priority based on data-loss impact, frequency of use and implementation fit.

| Priority | Recurring request | PlezyNG behavior |
|---|---|---|
| 1 | Reliable resume across devices, including downloaded books | Pull before opening/resuming; durable local changes; explicit concurrent-progress choice |
| 2 | Reliable offline listening | Reuse complete, fingerprint-matched profile-owned downloads and multipart resume |
| 3 | Chapter navigation and useful remaining time | Separate chapter/book views; speed-adjusted remaining time; unknown totals shown honestly |
| 4 | Flexible playback speed | Existing pitch-preserving backend, presets plus custom 0.25–4× input; retain per-book speed |
| 5 | Sleep timer that stops in the right place | Custom minutes, one/multiple chapters, add five minutes, prevent boundary auto-advance |
| 6 | Smart rewind after an interruption | Existing pause rewind; extend to reopening with bounded, source-time rewind |
| 7 | Recover from accidental scrubbing | Undo last seek, explicit go-to-time, retain existing durable history |
| 8 | Bookmarks and notes | Existing editor and list; encrypted synchronization including deletion tombstones |
| 9 | Multi-file books treated as one book | Existing natural grouping; fix unknown-duration chapter navigation; retain explicit file cursor |
| 10 | Library organization | Author/narrator/series/recent sorting; not-started/in-progress/finished filtering |
| 11 | Headphones, lock-screen and background playback | Reuse existing media-control routing, interruption handling and playback coordinator |
| 12 | Reading alongside listening | Preserve independent ebook and audio states; existing EPUB media overlays where authored alignment exists |
| 13 | Accessibility | Existing theme, focus widgets, semantics, scalable layouts, localized labels, reduced-motion behavior |
| 14 | Ownership and privacy | User-selected storage, opt-in write scopes, encrypted notes/state, no Plezy-hosted account requirement |

Evidence:
- [Community must-have discussion](https://www.reddit.com/r/audiobooks/comments/1fiotlq/what_are_your_must_haves_in_an_audiobook_app/) repeatedly asks for smart rewind, chapter/book progress, sleep behavior, bookmarks/notes and flexible skips.
- [BookPlayer](https://github.com/TortugaPower/BookPlayer) and its [ideas board](https://github.com/TortugaPower/BookPlayer/discussions/categories/ideas) establish import, offline playback, chapter handling, bookmarks, speed, cloud access and synchronization as recurring concerns.
- [Prologue](https://prologue.audio/) groups offline libraries, series, notes, per-book settings, sleep timers and smart rewind as central product features.
- Audiobookshelf reports [#1161](https://github.com/advplyr/audiobookshelf-app/issues/1161), [#808](https://github.com/advplyr/audiobookshelf-app/issues/808) and [#1338](https://github.com/advplyr/audiobookshelf-app/issues/1338) show the practical failure: returning to a device reasserts an old cursor and overwrites newer listening.

Adjacent requests need separate implementation and qualification: native watch clients, platform vehicle browsing, voice boost/EQ/silence removal, listening statistics/goals, cross-book queues, and automatic alignment between unrelated audio/text editions. They are not claimed as delivered by this checkpoint. EPUB overlays with authored timing are materially different from guessing an audiobook timestamp from an ebook percentage.

## Existing repository state and dependency

Remote default branch was main, last verified at 1b12fd8bb2182a67a58aa8eb949c01006d8fbc31. Its tree did not yet contain lib/sources or lib/screens/sources.

A separate working checkout contained the pending file/book foundation:
- checkout: /workspace/scratch/a17eead18365/PlezyNG
- branch at inspection: codex/books-cloud-sources-20261026
- base commit at inspection: d17a75704315032ddde7aa3ca6002a0cd2ddd634
- substantial staged source, reader, cloud, lending, accessibility and localization changes

That checkout was never modified by this task. An isolated snapshot was created at /workspace/scratch/1ff25b116951/PlezyNG. The implementation was developed there against the foundation's existing SourceController, SourceRepository, SourcePlayback, source adapters and reader screens.

The source foundation referenced here is now present on current main. The reconstructed transformations still require a fresh context check and full code review before use. Do not copy the older foundation snapshot over current main or apply this bundle in this checkout.

## Product flow

1. Add the cloud account normally through Files & books.
2. Open Reading & listening sync from the shelf or book toolbar.
3. Choose an attached Google Drive, OneDrive, Dropbox, WebDAV or S3 source.
4. Create a private sync code on the first device. Enter the same code on the other devices using the same storage account.
5. For WebDAV, choose an existing folder inside the selected source. For S3, choose a dedicated prefix.
6. Enable sync. OAuth providers request the additional write permission at this point.
7. Show last successful sync, safe failure text and unresolved conflicts.
8. Resolve concurrent positions by selecting a concrete candidate. Never silently select the largest percentage or latest device timestamp.
9. Turning sync off preserves local history and remote state.

Use a different sync code for each person/profile. The code is a random encryption key, not a password or OAuth token. It must be stored through CredentialVault-backed private preferences. Do not log it, send it to OS media metadata or include it in diagnostics.

The UI follows Plezy's current monochrome theme, normal settings rows, shared menus, focus surfaces and tooltips. It does not introduce a new dashboard visual style.

## State model

Reading and listening are independent. Each progress record includes:
- stable provider identity, publication ID, exact edition fingerprint and mode;
- source-time position and explicit file index/file-relative position for multipart audio;
- EPUB CFI/href or page-based reading locator;
- completion flag, fraction and playback speed.

Do not replicate connection UUIDs or profile UUIDs as cross-device identity. They are installation-specific. Provider object IDs and origin distinguish publications. Exact edition fingerprints prevent assigning an old timestamp to replaced media or a reordered multipart sequence.

The initial implementation requires the same provider edition on both devices. Independently imported local copies, changed file timestamps, provider migrations, alternate encodings and alternate ebook editions are not automatically matched. They need a later verified identity/linking workflow; title matching alone is insufficient.

Annotations are separate records with stable IDs and deletion tombstones. Tombstones remain part of replicated state so an offline device cannot recreate an intentionally deleted bookmark.

## Causal merge protocol

A multi-value register per progress/annotation record carries a bounded version vector.

- A causally newer value supersedes an older value.
- Independent edits remain concurrent.
- Reset, rewind and mark-unfinished are real edits, not progress regressions to discard.
- Identical vectors carrying different data are corruption.
- The user resolves concurrent values with a new edit whose context includes every candidate.
- Device wall clocks are display metadata, never the ordering rule.
- Merge must be commutative, associative and idempotent.

A subtle invariant: a downloaded value that was deferred because the reader/player is active is not yet part of that reader's local basis. Continued playback must remain concurrent with that remote value. Otherwise a background pull could silently authorize overwriting the unseen position.

Local changes are captured into the durable sync cache before network I/O. Changes arriving during network I/O are captured again against the pre-pull basis. Applying imported rows and recording the observed hash/basis happen in one SQLite transaction.

Active progress keys are held by the reader/player so background sync cannot seek underneath them. A paused player releases its key for a resume refresh, adopts the current revision/cursor, then reacquires ownership. Existing repository revision checks still reject delayed writes from stale screens.

## Remote layout and encryption

Each device publishes an immutable generation containing the merged state:

plezyng-state-v1-{namespace24}-{device32}-{sequence16}.json

- namespace: truncated SHA-256 of the random 256-bit join key.
- device: random installation/profile actor ID, independent of OAuth account identity.
- sequence: durable monotonically increasing generation.
- payload: versioned AES-256-GCM envelope; fresh random nonce; filename is authenticated associated data.
- book titles, notes and progress are inside the ciphertext.
- audio, ebooks, provider credentials and passwords are not uploaded.

Immutable generations avoid shared-file read/modify/write races and make interrupted uploads recoverable. A new device merges the newest authenticated generation from each actor. A publisher may prune only its own older generations after a successful upload, keeping the preceding generation as a recovery copy.

A corrupt or unsupported newest generation stops publication; it is not silently replaced with an empty document. Limits include 128 actors, 20,000 registers, 4 MiB plaintext, 6 MiB envelope, 2,048 listed state files and bounded pagination.

Encryption protects stored state confidentiality and detects modification. It is not a remote deletion detector or an anti-rollback guarantee against a storage owner who removes generations. Users retain normal provider access and backup controls.

## Provider contracts

| Provider | Storage | Additional scope/permission | API behavior |
|---|---|---|---|
| Google Drive | appDataFolder | drive.appdata alongside existing read scope | Enumerate app data; immutable multipart create; read exact listed IDs; prune owned generations |
| OneDrive | special/approot | Files.ReadWrite.AppFolder alongside Files.Read/offline_access | List app folder; upload unique content path; follow content redirects without forwarding bearer credentials cross-origin |
| Dropbox | /PlezyNG Sync | files.content.write alongside existing read/metadata scopes | Paginated listing; create-only upload with autorename false; exact listed IDs for read/delete |
| WebDAV/Nextcloud | user-selected existing contained folder | Existing account must allow writes there | Depth-1 PROPFIND; contained paths; create-only PUT; exact owned-generation delete |
| S3-compatible | dedicated prefix below configured root | List/Get/Put/Delete limited to prefix | SigV4 signs the actual method; paginated ListObjectsV2; immutable PUT and owned-generation DELETE |

Provider references:
- [Drive app data and authorization](https://developers.google.com/workspace/drive/api/guides/appdata)
- [OneDrive app-folder permission and endpoints](https://learn.microsoft.com/en-us/graph/onedrive-sharepoint-appfolder)
- [Dropbox official files API specification](https://github.com/dropbox/dropbox-api-spec/blob/main/files.stone)
- [AWS SigV4 query authentication](https://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-query-string-auth.html)

Do not broaden an app-folder scope to whole-drive write access when a provider returns an error. Show the error and support reconnect. Enabling sync is the explicit point for additional OAuth consent; ordinary media-source access remains read-only.

Cloud sync is the single progress authority while enabled. Existing Audiobookshelf/WebDAV server-state synchronization remains separate and resumes when cloud sync is disabled. Do not create a bidirectional server/cloud echo loop without a distinct authority/bridge design.

## Authored implementation

The recovery bundle contains:
- SyncDocument and SyncCipher.
- ProviderSyncStore for all five storage providers.
- PublicationSync with local capture, transactionally applied imports, active-cursor deferral, conflict selection and generation retention.
- SourceSyncScreen and English Slang strings.
- Library ordering/filter helper and time parser.
- SourceController/OAuth/S3/reader/player/screen integration transformations.
- Six register/encryption tests and fourteen two-repository replication tests.

Before the environment loss, the isolated working tree also contained fine speed/time dialogs, chapter/book timing, multi-chapter/custom sleep controls, seek undo, per-book/default listening controls, library sort/filter UI and paused-player progress refresh. These edits are reconstructed in the bundle from the issued edit commands. Generated localization files are intentionally regenerated after recovery.

The bundle is a reconstruction, not a byte-for-byte archive of the unavailable checkout. Minor defensive edits added during reconstruction have not been analyzed or tested. Treat it as draft code requiring application, review and verification.

## Verification actually observed

- An intermediate full flutter analyze completed with zero errors/warnings and eight style infos.
- A later full flutter analyze completed with zero errors/warnings and three brace-style infos.
- Style-fix commands were issued. No clean final analysis was observed.
- Dependencies resolved offline.
- The first test attempts were blocked by missing package_graph.json, then missing clang on PATH.
- The existing native compiler at /workspace/scratch/a17eead18365/native-runtime/usr/bin was placed on PATH.
- The next run showed five passing register/encryption tests and the sixth test starting.
- No complete test-suite result was observed. Do not report 20 passing tests.
- No native release build, live provider account test or device qualification was performed.

## Required completion work

1. Recover/land the source foundation while preserving newer default-branch changes.
2. Prefer the original isolated checkout if it becomes accessible; compare it with this reconstruction.
3. Apply the bundle in check-only mode, resolve changed-context failures deliberately, then apply in an isolated checkout.
4. Regenerate Slang files; format changed Dart; run full analysis.
5. Complete the 20 authored sync tests, then add mocked protocol tests for each provider, pagination, duplicate Drive names, missing Dropbox folder, 401 refresh, OneDrive cross-origin content redirects, WebDAV path escape, S3 signed methods and cancellation.
6. Finish exact-event acknowledgement after successful cloud publication. Progress events are bounded by the existing repository, but pending annotation events need coalescing/acknowledgement so repeated edits cannot grow indefinitely.
7. Add an explicit reconnect action and test denied/revoked additional OAuth scopes. Read/create/delete calls need a bounded 401 refresh path, matching existing OAuth API requests.
8. Validate recovery after restored/copied local databases. A duplicated actor identity must be detected/rotated or rejected; never permit two installations to overwrite an identical immutable generation name.
9. Tighten schema-to-record-key validation, publication mapping ambiguity handling and all numeric/locator bounds.
10. Exercise sleep expiry and completion in both event orders, unknown-duration previous/next navigation, seek undo across parts, paused-player remote reset, keyboard/D-pad control and large/RTL text.
11. Finish file-relative bookmarks and preservation of significant seek/sleep history separately from frequent position ticks. The command for that final slice failed before process creation, so those edits are NOT included as completed work.
12. Test UI setup/disable/reconnect/conflict flows, profile switching/deletion during every await, and no-current-profile construction.
13. Run the existing source, reader, lending, accessibility and playback regression suites; run required code-generation/CI checks.
14. Perform live account and physical device acceptance before a release claim.
15. Commit the verified application changes, push, open/update the implementation PR and merge into main once required checks pass.

## Acceptance examples

- Phone at 2:38, desktop advances to 5:07, phone resumes at 5:07 rather than publishing 2:38.
- Phone offline advances while desktop independently rewinds: both candidates remain until chosen.
- User deliberately restarts a finished book: zero wins causally; maximum percentage is not used.
- Reading at an EPUB CFI and listening at 00:42:00 coexist.
- Deleted bookmark remains deleted when a previously offline device returns.
- Cloud account removal or profile lock during upload cannot write into another profile.
- Failure after upload but before acknowledgement leaves a recoverable generation and durable local work.
- Sleep at the end of a multipart chapter never starts the next part, regardless of native event order.
