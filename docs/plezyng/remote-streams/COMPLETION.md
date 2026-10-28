# Native playback, scheduled preparation and canonical libraries

Implementation record: 2026-10-28, branch
`codex/debrid-stremio-integration-20261028`.

The three code gaps called out in the preceding handoff are implemented.
This record distinguishes working code and local verification from signed
target builds, live accounts and device behavior that have not been exercised.
It does not certify every acceptance case in the broader R01–R16 plan.

## Native P2P transport

`packages/plezy_torrent` embeds libtorrent 2.0.11 with Boost 1.86.0. CMake
downloads source archives with fixed SHA-256 hashes and links libtorrent
statically into the small platform shared library. No external daemon,
downloaded executable, remote proxy or magnet-launch application is required.
The full upstream license texts ship as app assets and appear in app licenses.

The versioned C ABI opens a v1 magnet, acquires metadata, selects the requested
file and supplies verified bytes. An unspecified index is accepted only when
the torrent has one unambiguous video. Metadata-only acquisition begins with
all files unwanted. The engine pauses while applying selection and renaming
all peer-provided paths to private numeric filenames. It waits for storage
acknowledgements before resuming or advertising the media length.

Reads translate the selected file's offset into torrent piece coordinates,
prioritize seek targets and bounded read-ahead, and request disk reads only
after libtorrent reports a verified piece. The defaults cap a lease at 4 GiB
including boundary-piece allowance, 64 peer connections, eight cached pieces,
and 256 KiB/s upload. Metadata rejects more than 10,000 files and pieces over
16 MiB. The app permits two active leases. Each lease owns its session and
private spool; player release, profile change and disabling native playback
close it. Stale spools are removed on subsequent use.

A Dart isolate owns the native handle and a loopback-only HTTP server. A random
192-bit capability path, GET/HEAD, exact single byte ranges, 416 responses,
bounded concurrent requests and backpressure form the player contract. The
shared player owns the lease through `ExternalPlaybackSource.onRelease`.
The existing lazy next-item resolver can acquire a native lease when enabled;
no magnet, account credential or signed remote URL is stored in queue metadata.

Native playback is off by default. Its control and explanation are nested in
the existing Cloud & add-on streaming settings. The existing stream row offers
the native action only when the backend is available and the user opted in.
A failed cloud request does not silently start peer traffic.

Supported discovery is v1 magnets, DHT, PEX and HTTP/UDP tracker hints. v2-only
torrents and HTTPS-only/private-tracker workflows are outside this transport's
current contract. Local discovery and automatic router port mapping are off.

## Packaging and OS work

| Target | Native engine integration | Preparation scheduling |
| --- | --- | --- |
| Android / Android TV | Flutter FFI plugin, NDK/CMake build, 16 KiB ELF page alignment | WorkManager network-constrained unique work plus periodic recovery; headless FlutterEngine |
| iOS | Source-built device/simulator XCFramework, vendored CocoaPod | Registered BGProcessingTask, network constraint, expiration handling and headless engine |
| macOS | Universal source-built XCFramework, vendored CocoaPod | Per-user launchd agent; same executable with hidden worker entry |
| Windows | CMake DLL included in Flutter bundled libraries | Per-user Task Scheduler task; separate worker mutex and hidden window |
| Linux | CMake shared library included in Flutter bundle | systemd user timer/service with imported graphical-session environment and hidden runner |
| tvOS | Source-built device/simulator XCFramework and explicit TV pod | Existing app-runtime recovery; no claim of unsupported general background execution |
| webOS | Engine target installed into the SDK's bundle/lib; verifier requires it | App-runtime recovery |
| Tizen | Cross-build with the existing pinned toolchain, hashed/ABI-checked staging and package requirement | App-runtime recovery |

`scripts/p2p/build_apple.py` is invoked by the existing Apple Podfiles before
pod resolution. Its cache includes native sources, build script, CMake and
Xcode versions. Android and desktop use normal Flutter plugin build hooks.
Tizen and webOS reuse their existing package pipelines and verification.

`packages/plezy_preparation` registers actual mobile OS workers. Desktop native
runners recognize `--plezy-preparation-worker` before regular UI startup.
`remote_preparation_worker.dart` loads all persisted preparation profiles with
a six-minute execution budget. It starts no normal browsing or player session.
OS task definitions contain only the executable/entry point; credentials,
profile IDs and provider URLs are read from the protected journal at execution.
Completed work removes scheduled recovery. Unsupported/unavailable schedulers
fall back to app-runtime recovery, with an explanatory cue in existing settings.

OS dispatch is discretionary, especially on iOS, and desktop jobs need the
user session. This mechanism resumes remote provider preparation; it does not
claim to keep a native torrent streaming while the OS suspends playback.

## Durable preparation ownership

SourceDatabase schema 11 adds encrypted remote-stream state and expiring job
claims. Legacy encrypted preferences migrate on first use. Updates acquire a
SQLite writer lock before reading and changing the latest snapshot, preventing
a foreground account change from being overwritten by a headless worker's
stale state. Connections use a busy timeout and WAL.

A foreground preparation, manual retry or background recovery must claim the
profile/job pair with a unique attempt owner. Active attempts renew their claim
every thirty seconds. Claims expire after ten minutes; release checks the owner so
an old process cannot release its successor's claim. Two recoveries at most
run concurrently. Saved Real-Debrid, AllDebrid and TorBox job IDs are reused;
resuming does not create a replacement torrent. A normal long-running provider
download does not exhaust the transient-error retry allowance. Missing jobs,
cancelled jobs, removed accounts and profile changes stop polling. Profile
deletion writes a tombstone so an already-running worker cannot resurrect its
encrypted account state or canonical records.

Idle task removal is ordered with journal writes under a SQLite transaction.
New preparations recheck OS installation; a foreground process cannot rely on
an old installation cache after another worker removes completed work.

Cancel means stopping PlezyNG's polling/retries, not deleting provider-side
content. Premiumize jobs without a reusable provider checkpoint still require
user action. Keychain lock/unreadable ciphertext remains a recoverable error;
no plaintext fallback is added.

## One persistent library card

`lib/media/canonical_library.dart` stores profile-scoped canonical cards,
typed exact aliases, source/server copies and merge redirects. The stable card
ID survives refresh and database restart. Later evidence can bridge two cards;
the older card survives and existing handles redirect to it. Contradictory
IDs in the same namespace are quarantined. Titles alone never merge records.
Copies without external IDs still have stable cards based on their locators.

Movies, shows and exact episodes have separate identity domains. Episode
matching requires the **series** external ID plus season/episode coordinates;
an episode's own IMDb/TVDB ID cannot be mistaken for its series ID. Library
indexing fetches the parent series IDs once per show. Server snapshots store
presentation and stable identifiers, not raw server payloads, bearer headers
or signed part/artwork URLs. Opening a server copy fetches its current item.

Cloud indexing, existing Home hubs, library pages and server navigation feed
the same graph. The existing Videos shelf pages canonical cards and indexes
connected server libraries incrementally. Cards reuse `MediaCard` or
`SourcePosterCard`; a copy count and focusable source sheet expose the choices.
Home's cloud rail suppresses canonical duplicates and opens the same source
sheet. Hidden libraries and the active profile remain authoritative. Removing
a cloud source removes its availability without deleting another copy's card.
Disconnected server choices cannot be launched as though they were online.

## Verification performed

| Check | Result |
| --- | --- |
| Focused Flutter tests | 65 passed: encrypted/concurrent state, independent DB connections, claims/renewal, idle cleanup, profile deletion, schema migration, canonical bridges/conflicts/restart/episode identity, ranges, provider/catalog fixtures and shared-player queue/repeat |
| Pinned native source build | libtorrent 2.0.11 / Boost 1.86 compiled and linked successfully on Linux |
| Native transfer test | Passed against a local generated fixture/seeder: metadata, single-file selection, explicit file in a multi-file torrent, non-aligned file offsets, tail-first reads, cross-piece reads, backward seeks, verified bytes, EOF and invalid inputs |
| Tizen package tests | 10 passed |
| webOS package tests | 5 passed |
| Targeted Dart analysis | No errors or warnings; one pre-existing RealDebridClient constructor-style informational lint |
| Script syntax and patch hygiene | Python compile checks and `git diff --check` pass |

Reproduce the native test with a C++17 toolchain and CMake 3.22+:

```sh
cmake -S packages/plezy_torrent/src -B build/p2p-test \
  -DCMAKE_BUILD_TYPE=Debug -DPLEZY_TORRENT_TESTS=ON
cmake --build build/p2p-test --parallel 4
ctest --test-dir build/p2p-test --output-on-failure
```

The test option restricts the reader to loopback and disables DHT so fixtures
never join public swarms. Production builds leave this option off. Test data
is generated locally; no live provider account or media catalog was used.

```sh
flutter test test/media/canonical_library_test.dart \
  test/services/remote_streams test/sources/source_database_migration_test.dart \
  test/providers/playback_state_provider_test.dart \
  test/providers/playback_state_provider_repeat_test.dart
python -m unittest discover -s scripts/tizen -p test_package.py
PLEZY_WEBOS_TEST_TMP=/tmp python -m unittest discover \
  -s tools/webos/tests -p test_package_ipk.py
```

## Release qualification still required

Build/install the signed Android, Apple, Windows and TV targets with their
actual toolchains, and exercise cold-start/termination/expiration recovery,
locked key stores, power/network constraints and task removal. Verify native
play/seek/stop and disk cleanup on each supported ABI. Validate TV focus,
screen readers, large text, real provider leases and background downloads on
devices. Existing casting/multiview and ambiguous offline queue cases retain
their broader validation requirements in IMPLEMENTATION.md and VALIDATION.md.

Confidence is high for the locally tested engine, persistence and Dart paths;
packaged platform behavior remains unqualified until those target checks run.
No Actions workflow was dispatched. Any subsequent CI/build job must use the
private ephemeral JIT runners required by AGENTS.md.
