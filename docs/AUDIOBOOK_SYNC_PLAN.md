# Audiobook client improvements and encrypted state sync

## Product readout

There is no reliable public dataset that ranks audiobook feature requests across every client. This is a qualitative synthesis of the feature sets users are taught to expect, first-party help pages, self-hosted client catalogs, and public feature requests. The strongest recurring needs cluster around a dependable player, a safe resume point, and library continuity:

| User need | Why it keeps appearing | PlezyNG direction |
| --- | --- | --- |
| Resume accurately across files, devices and offline periods | Multipart books, interruptions, explicit rewinds and completion resets make a single percentage inadequate. Cross-device progress is a recurring request in audiobook clients. | Persist book and file-relative cursors, edition identity, completion and reading/listening mode separately; sync with causal versions. |
| Navigate and control listening without hunting through menus | Chapters, track navigation, short skips, speed changes and hardware/lock-screen controls are core player expectations. | Chapter/book timeline, previous/next chapter, configurable skip lengths, speed presets/custom speed and native media controls. |
| Stop reliably at a useful point | A duration-based timer is not enough for listeners who want to finish a chapter or extend the timer after waking. | Timed sleep, chapter/track-count sleep, visible time remaining, extend and clear. |
| Save and return to meaningful passages | Bookmarks and short notes are useful for references, quotes and returning to a particular part. | Tombstoned bookmark records retain a multipart file cursor and synchronize with notes. |
| Find the next book quickly | Readers expect shelves, unfinished/finished filtering, meaningful sorting and offline access. | Persisted sort/status controls complement existing shelves, downloads and offline library. |
| Recover gracefully from provider outages and concurrent listening | Silent last-write-wins can discard a rewind or move a live player unexpectedly. | Durable offline-first writes, immutable encrypted generations, explicit conflicts and active-player deferral. |

These needs are supported by current Apple Books help, BookPlayer's feature list, Audiobookshelf's community-client catalog and public issues for manual sync and sleep behavior. They are signals of expected workflows, not a measured popularity ranking: [Apple Books playback help](https://support.apple.com/en-ca/guide/iphone/iphac1971248/ios), [BookPlayer feature list](https://apps.apple.com/us/app/bookplayer/id1138219998), [Audiobookshelf community clients](https://audiobookshelf.org/docs/documentation/community/community-apps/), [manual sync request](https://github.com/advplyr/audiobookshelf-app/issues/1076), [auto-sleep request](https://github.com/advplyr/audiobookshelf-app/issues/260), [two-way progress sync request](https://github.com/TortugaPower/BookPlayer/issues/1423).

## Scope delivered in this change

This branch turns those repeated needs into usable app behavior and introduces encrypted cross-device read/listen state using storage the user has already attached.

### Audiobook experience

- Player timeline can show the whole book or the current chapter, with chapter and book remaining time adjusted for speed.
- Multipart progress retains both book offset and part index/part-relative offset. Chapter navigation falls back to part navigation when durations are incomplete.
- Playback supports configurable short skips, speed presets through 4×, a validated custom rate, smart rewind, direct time entry and undo-seek.
- Sleep supports a duration, end of chapter/track, the next 2/3/5 chapters/tracks, custom duration, five-minute extension and a visible timer countdown.
- Bookmarks and notes retain the exact part-relative cursor for multipart books and can be opened at that cursor.
- Sort by title, author, narrator, series or recent activity; filter new, in-progress and finished; preferences persist per shelf/source.
- Playback settings can be saved for one edition or used as defaults.

### Encrypted read-state sync

- Optional profile-scoped sync for reading, listening and watching progress, completion state, bookmarks and notes.
- Storage locations are scoped to app data or an explicitly selected folder/prefix:

| Attached source | State location | Write boundary |
| --- | --- | --- |
| Google Drive | `appDataFolder` | PlezyNG app data only |
| OneDrive | App `approot` | PlezyNG application folder only |
| Dropbox | `/PlezyNG Sync` | Dedicated folder only |
| WebDAV/Nextcloud | Selected existing folder | Contained under the configured source root |
| S3-compatible storage | Selected dedicated prefix | Contained under the configured bucket root and prefix |

- Files contain AES-256-GCM ciphertext. A random 256-bit sync code is the key and is never sent to the provider. Each immutable generation is authenticated against its filename. Names contain only a format version, a hash-derived namespace, a random device ID and a sequence number.
- Local state is saved before network access. Pull/merge/apply/publish is retriable; writes use a new name and never replace a generation. Each device keeps its latest generation and a recovery copy. Cleanup only removes older files belonging to that device after a successful publish.
- A multi-value causal register uses per-device vector clocks. A causal edit supersedes the values it has observed; concurrent edits remain a conflict. Wall-clock timestamps and maximum percentage never choose a winner. Users can select a version to resolve it.
- The synchronizer never seeks underneath active playback. A deferred remote value remains concurrent until the local player releases its cursor, so playback progress made meanwhile is not lost.
- Provider OAuth scopes are upgraded only when sync is enabled. The content browsers remain read-only; the sync writer operates only in the provider-specific app area or chosen contained folder/prefix. Tokens remain in the local credential vault.
- Sync runs when configured, at profile activation, after local progress changes, and on a periodic retry. A failed network sync leaves the local database usable and dirty state durable.

## State identity and conflict model

Each publication record is keyed by a digest of publication identity, edition fingerprint and mode. Provider-backed publication identity uses the source kind, provider object ID and shared-drive identity when present; local source identity uses its configured root. Edition fingerprints include file IDs, names, revisions and sizes, so a replaced/reordered edition is retained in the cloud document but is not applied to a different edition. `syncLibrary` can provide a stable library identity for a source that needs one.

Reading, listening and watching are separate progress modes. EPUB locators preserve CFI/page/fraction; audio/video preserve book offset, file index, file-relative offset, speed, fraction and completion. Bookmarks have stable IDs and deletion tombstones, so a stale device cannot resurrect a deleted bookmark. Older annotations without file cursors continue to decode.

During import, the sync record is validated before it reaches SQLite. Progress with an incompatible edition stays in the encrypted document and does not become a misleading local resume point. A conflict is shown with its originating device prefix and a concise position/note; selecting a version creates a new causal edit. A remote progress record for the active key waits until playback is paused/released.

## Storage and failure rules

1. Save the current local snapshots and causal basis in the profile database before contacting storage.
2. List only files in this code's namespace. Validate provider origin, filename shape, pagination, document bounds and encrypted envelope.
3. Read the newest generation for each device, decrypt and authenticate it, then merge causal records.
4. Import compatible non-conflicting records transactionally. Keep conflicts and edits deferred by active playback visible.
5. If the merged document changed, create a new immutable generation. Only after creation succeeds update the published digest and acknowledge the exact local revisions/payloads represented.
6. Keep one prior generation for recovery. Best-effort cleanup is restricted to older generations from the current device. Cleanup failure does not roll back a committed generation.

If a cloud request fails, local state remains intact and pending. If a generation is corrupt or the code is wrong, stop before publishing over it. If a device goes offline and edits concurrently, keep both values until the user chooses. If the sync code is lost, encrypted remote state is not recoverable; users should store it in a password manager. Disabling sync removes the local sync configuration but preserves local history and does not delete remote files.

Bounded input: 4 MiB plaintext sync document, 20,000 records, at most 128 concurrent values per record, 128 devices, 2,048 listed generations and bounded provider pagination. Book content, cover files, account tokens and profile identifiers are not part of the sync payload.

## Follow-up roadmap

These are the next useful additions, not prerequisites for the current delivered scope:

| Priority | Candidate | Why / engineering approach |
| --- | --- | --- |
| P1 | Queue and series-aware continuous play | Persist an explicit queue/order and play-next intent, independently from source directory order. Keep queue identity profile-scoped and allow removing unavailable items without changing progress. |
| P1 | Automatic sleep schedule and gradual fade | Add opt-in local schedule, platform lifecycle handling and a short gain ramp; persist schedule settings per profile and test timer behavior through pause/background/resume. |
| P1 | Better conflict history and recovery UI | Show last sync/device, current local-vs-remote cursor and a preview before choosing; add restore-from-previous-generation only after validating the whole document. |
| P2 | Car/headset action mapping and screen-reader polish | Expose app preferences for skip actions and verify native controls, chapter labels and VoiceOver/TalkBack semantics on real devices. |
| P2 | Download rules and per-source offline policies | Add Wi-Fi-only, keep-last-N and delete-after-finished policy without deleting originals or partial downloads. |
| P2 | Auto-skip intro/outro and listening statistics | Store optional per-edition skip ranges and opt-in session summaries separately from resume state. |
| P3 | Subtitle/transcript display and synchronized text | Pair only explicit sidecar transcripts/subtitles with a book; never infer a transcript or upload media. |

Use existing provider/server APIs when available; avoid a hosted account or relay just to sync state. Keep sync payload versioned and encrypted if more state is added.

## Engineering map

| Concern | Implementation |
| --- | --- |
| User controls and browse preferences | `lib/screens/sources/source_player_screen.dart`, `lib/screens/sources/source_sync_screen.dart`, `lib/screens/sources/sources_screen.dart` |
| Player behavior and lifecycle | `lib/sources/source_playback.dart`, `lib/sources/listening_tools.dart`, `lib/sources/publication_library.dart` |
| Durable local state and outbox | `lib/sources/source_database.dart`, `lib/sources/source_models.dart` |
| Causal merge, identity, encryption | `lib/sources/sync/sync_document.dart`, `lib/sources/sync/publication_sync.dart` |
| Provider file storage and OAuth writes | `lib/sources/sync/sync_store.dart`, `lib/sources/source_oauth.dart`, provider adapters under `lib/sources/adapters/` |
| Regression coverage | `test/sources/sync/`, `test/sources/source_playback_test.dart`, and existing source reader/player tests |

## Verification boundaries

Mocks exercise provider REST responses and auth refresh, and in-memory stores exercise cross-device merge, conflict resolution, corrupt generations, tombstones, active-player deferral, retries and cleanup ownership. These tests do not authenticate against real Google/Microsoft/Dropbox accounts, validate a customer's WebDAV/S3 configuration, or prove OS background-audio and vehicle behavior. Platform CI and physical-device/provider-account smoke testing remain release acceptance tasks.

## Local verification

- `flutter test test/sources`: 78 passed; two browser-engine tests skipped because `PLEZY_CHROME_PATH` is not configured.
- `flutter test test/focus/focusable_slider_test.dart`: 3 passed.
- `flutter analyze --fatal-infos`: passed with no issues.
- `python3 scripts/checks/clean_translations.py --check --strict`: passed across 20 locales, with zero unused keys.
- `git diff --check`: passed.
- `scripts/codegen.sh`: completed on the integrated tree to regenerate localization outputs, including the latest Google Drive source label; analysis and source tests then passed.
