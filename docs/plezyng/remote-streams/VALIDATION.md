# Acceptance, qualification and regression plan

This file remains the acceptance plan for the broader design. The current PR
branch has not been validated against live provider accounts or packaged
devices. No app build or automated tests were run for this branch; source
inspection and `git diff --check` are the local review evidence only.

## Definition of done

The core feature is complete when a new cloud-only user can connect, browse,
play, seek, resume and disconnect all four core services; an existing Stremio
user can import configured add-ons and use their supported resources; all
surfaces enforce profiles and source visibility; and existing server/media
flows retain their behavior. Optional native P2P has its own actual engine and
target gates. Remaining broader native-provider contracts must be named in the
coverage register instead of hidden behind empty adapters.

For each result record: package ID, commit, application build, platform/device,
provider/adapter revision, account entitlement relevant to the test, test-media
identity without secrets, expected/actual behavior and sanitized evidence.
Separate parser/unit, integration, live-account and packaged-device evidence.

## Behavioral test matrix

| ID | Scenario | Required result |
| --- | --- | --- |
| A01 | Device code pending, slow-down, denied, expired, canceled | Correct poll interval/backoff; no late connection after cancel; usable retry |
| A02 | Real-Debrid user-bound credentials step and token rotation | Correct credentials exchanged/stored atomically; refresh is single-flight |
| A03 | AllDebrid PIN versus OAuth-shaped response | PIN parser succeeds; no invented refresh request |
| A04 | Premiumize PKCE state/verifier mismatch and business error in 200 | Reject mismatched auth; surface typed account/service failure |
| A05 | TorBox code already collected or expired | Stop polling; safe restart; token never written to logs/query history |
| A06 | Profile switches during auth/import | No credentials, account records or media delivered into the next profile |
| A07 | Lost OS key, transient vault failure, restored settings | Reconnect or retry; no plaintext fallback and no destructive credential overwrite |
| A08 | Repeated connect callback / same native account | One account per intended profile binding; deterministic reconnect |
| C01 | Two configured manifests share the same reported ID | Independent configuration, ordering, caches and removal |
| C02 | Secret in manifest path, not query | Encrypted persistence; diagnostics/export never reveal path |
| C03 | Manifest requires configuration or unsupported extra | Correct configuration/filter flow; no invented catalog request |
| C04 | Encoded path prefix, ID, search and genre extras | Correct URL construction without truncation, double encoding or parameter injection |
| C05 | Add-on offline, malformed JSON, oversized/deep response | Other providers still render; bounded resource use and specific retry |
| C06 | Add-on update requests new resources/hosts | Old grants preserved; new privilege requires user review |
| C07 | Stremio import has bad descriptor among valid ones | Valid items import; failures remain localized; remote collection untouched |
| C08 | Reimport after local reorder/disable | No duplicates; explicit merge preview preserves local intent |
| C09 | Stremio QR/social account/password fallback | Qualified linking works or clear import alternative; no browser-storage scraping |
| C10 | Unsupported NZB/archive/YouTube/external payload | Correct capability/explicit external action; never fed blindly to native decoder |
| I01 | Movie shared by server and cloud | One merged logical result with separate playable copies |
| I02 | Same title/year conflict or remake | No automatic merge without reliable ID evidence |
| I03 | Anime season, absolute numbering, specials, double episode | Distinct correct episode identities; no series-level collapse |
| I04 | Season pack, sample, padding file, missing file index | Correct metadata-based file mapping; ambiguity prompts choice |
| I05 | Partial inventory scan fails halfway | Previously known files remain; deletions wait for a complete snapshot |
| I06 | Manual match and undo | Reversible alias/metadata change; original source identity and progress retained |
| P01 | Catalog browse, search, hover, swipe and candidate sheet | No provider acquisition, unlock, local swarm or destructive mutation |
| P02 | One ready, one unknown, one unavailable source | Accurate labels; deterministic preference; unknown never displayed as confirmed cached |
| P03 | Double Play and timeout after remote POST accepted | One reconciled operation; no duplicate automatic submissions |
| P04 | Crash between create and select / app restart | Job recovered by ledger and provider reconciliation; correct file selected |
| P05 | Pre-existing user job differs in selected files | No unauthorized mutation or cleanup of that job |
| P06 | Delayed host link / uncached transfer / quota / account expiry | Distinct preparation/wait/reconnect states; correct action and cancellation |
| P07 | Native HLS/DASH redirects, segments, encryption-key URLs | Same destination/header policy at every fetch, including native engines |
| P08 | Expired link during seek / simultaneous expiry errors | One same-copy renewal; compatible position/tracks restored; bounded reopen |
| P09 | Provider file changed or deleted during renewal | No byte stitching or wrong-edition resume; explicit recovery |
| P10 | VPN/Wi-Fi/cellular switch and cast receiver egress | Leases invalidated/reacquired where required; no silent IP-limit workaround |
| P11 | Two PiP/multiview sessions on one account | Independent leases/progress and slot teardown; shared account limits respected |
| P12 | Close player or switch profile during slow resolve | Stale completion cannot open a player, write progress or resurrect UI |
| P13 | Next episode source disappears / numbering mismatch | Correct alternative or missing state; never next file by sorted position |
| P14 | Explicit source lock plus source failure | No automatic change against user intent |
| P15 | Add-on returns status/error video as HTTP stream | Known adapter failure videos excluded from progress/scrobble; unknown handling documented |
| W01 | Cloud playback plus server copy with same title | Local canonical progress updates; server is not falsely reported as playing |
| W02 | Unwatched/reset competes with delayed progress upload | Reset causality preserved; stale maximum timestamp does not win |
| W03 | Tracker offline then reconnects | Idempotent per-sink acknowledgement; no duplicate scrobble |
| W04 | Watch Together / external player / Cast | Identity-based own-access resolution; no credentials in messages; return behavior qualified |
| D01 | Download crashes, resumes, expires, runs out of space | Correct quota/reservation, same-file resume and cleanup; no completed-file corruption |
| D02 | Native task database and renewal callback | Encrypted descriptor; actual callback supports provider; no raw signed URL/headers stored |
| D03 | Remove local file / disconnect / cancel / remote delete | Distinct effects; no remote deletion through an unrelated local action |
| S01 | Public add-on resolves to private/loopback/link-local IPv4/IPv6 | Denied before socket connection; rebinding and redirects tested |
| S02 | Origin changes with Authorization/Cookie/User-Agent | Only explicitly granted compatible headers survive; account tokens never leak |
| S03 | Manifest injects code/headers/regex/XML/archive paths | No execution, header injection, XXE, unbounded regex or traversal |
| S04 | Local content gateway guessed/replayed capability | Unrelated request denied; session disposal revokes access |
| S05 | Restricted profile via Search/Home/swipe/deep link | Same visibility/PIN/rating policy; no cross-surface metadata leaks |
| S06 | Logs/crash data/export/background DB scanned | No API keys, configured URL secrets, NNTP credentials, auth codes or signed leases |
| U01 | Cloud-only first run and cold restart | Working Home/Library entry; no media-server sign-in loop |
| U02 | TV D-pad, focus return, removed selected source | All actions reachable; stable focus and Back behavior |
| U03 | RTL/CJK/long translations/200% text/reduced motion | No clipped critical action, overflowing code or inaccessible progress state |
| U04 | QR cannot be scanned / screen-reader operation | Equivalent readable code, URL, browser action and cancellation |
| U05 | One provider fails during search or Home refresh | Working rows remain usable; late results do not displace focused selection |

## P2P-specific qualification

Use a controlled swarm with known media, checksums, a slow peer, a dropped peer
and deliberate corrupted pieces. No internet swarm is needed for deterministic
tests. Verify v1/v2 support only for formats the chosen engine actually provides.

| Scenario | Required evidence |
| --- | --- |
| Metadata-only magnet | Bounded wait and accurate failure; no bogus file size/ready state |
| Seeking before sequential download completes | Deadline priority moves to requested range; verified bytes only |
| Container index at end of file | Necessary index pieces prioritized; native decoder can seek |
| Cross-file piece boundary and torrent padding | Correct selected-file offsets and no adjacent-file disclosure |
| Malicious metadata/path/symlink | Contained storage and parser resource bounds |
| Low disk and sparse allocation | Physical reserve honored; rollback releases quota |
| Sleep/network changes/engine crash | Controlled teardown or recovery with stale callbacks rejected |
| Private torrent / unknown privacy | No unauthorized DHT/PEX; no inference from hash alone |
| Stop playback with seeding disabled | No continuing peer traffic after documented shutdown grace |
| Profile switch with two slots | Both old-profile sessions revoked; new profile cannot access their bytes |

Record native library revision, license notices, compile options and target ABI.
Run the engine's meaningful memory/thread/undefined-behavior checks where
available. A loopback HTTP fixture alone does not qualify torrent networking.

## Platform coverage

These are planned validation routes, not claims of shipped support.

| Target | Core HTTP/cloud checks | Additional checks |
| --- | --- | --- |
| Windows/Linux/macOS | Device/browser auth, secure persistence, all supported media protocols, expiry/seek | Packaged native libraries, credential-store availability, tray/sleep lifecycle, optional P2P |
| Android phone/tablet | Browser return, QR option, lifecycle, subtitles, background/resume | Metered policy, actual downloader secure callback, PiP and casting |
| Android TV | QR/code, D-pad, large-screen layouts and cold start | Hardware decode capability, next episode, limited storage, P2P only if separately built |
| iOS | System browser/PKCE return, secure vault, foreground streaming and expiry | Background task rules, PiP, Cast, encrypted downloads, native entitlements |
| tvOS | QR/code, remote focus, vault, cloud queue without local Downloads tab | App suspension, eviction/reconnect, decoder slots, signed native package |
| webOS | QR, secure-storage result, TLS, player URL/header/range handling | Actual IPK/TV, remote keys, limited memory, no assumed desktop-native features |
| Tizen | QR, secure-storage result, TLS, player URL/header/range handling | Actual TPK/TV, player profile, remote keys, no assumed desktop-native features |
| Browser if later shipped | CORS and permitted protocol/credential handling | Separate media capabilities and secure persistence; no assumed native engine |

## Performance targets and measurements

Confidence: low until measured. These are initial engineering budgets on a
representative midrange client and a deterministic test server:

- Cached first useful browse content within 200 ms of the screen being ready;
  network-backed first page within 2 s on a healthy provider/test link.
- Search produces local/cached results without waiting for remote sources;
  network candidate discovery ends at the configured interactive deadline.
- Ready remote playback reaches first frame within 3 s in the controlled
  fixture; record DNS/auth/resolve/open/first-frame separately on real services.
- Remote metadata work adds at most 32 MiB steady-state cache budget and does
  not retain all cloud pages or stream candidates across navigation.
- No new provider-dependent work on every video frame; idle screens and
  suspended apps generate no polling except a specifically supported task.
- Measure UI frame times on TV and low-memory devices, requests per action,
  transferred bytes, peak memory, cache hits, startup and seek percentiles.

Use fake time and fault injection for budgets/backoff. Benchmark at least warm
and cold cache, 1/10/50 add-on installations, 10,000 cloud entries, a slow
provider and a rate-limited account. Record results; tune defaults without
weakening provider rate limits or changing truthful availability states.

## Regression commands and evidence

Use the repository's pinned Flutter toolchain and existing local scripts.
Run analyzer and relevant tests for the changed areas, then the existing
catalog, source, profile, playback, download, tracker and localization checks
affected by integration. Reuse tests such as `test/providers/catalog_sources_provider_test.dart`,
`test/models/catalog_item_test.dart`, `test/screens/catalog_item_detail_screen_test.dart`,
`test/sources/source_playback_test.dart`, `test/sources/source_state_test.dart`,
`test/sources/source_database_migration_test.dart`, and
`test/sources/content_access_gateway_test.dart` as regression anchors.
Add new behavior tests for the matrix above instead of tests that just mirror
new class constructors. Use packaged-target smoke tests for native behavior.

The current implementation still needs the behavioral matrix below, plus
link/path, Markdown structure, source attribution and diff-scope review for
these design documents. Do not launch CI or change workflow triggers for this
branch.
