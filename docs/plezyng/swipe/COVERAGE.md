# Media, sources and platform coverage

Audit baseline and immutable references are in [RESEARCH.md](RESEARCH.md). This is an implementation coverage contract, not a claim of shipped swipe support. **M** means code surface observed in the initial main audit. **B** means the books/source foundation, inspected on its branch and confirmed present on final main `bea4d3f0fe8cd869e0727bbe372cae0da534b253`. **P** means proposed work. A capability must be checked for the particular profile, item, device and current entitlement, not inferred from the platform name or file extension.

## Exhaustive media mapping

| Observed kind / content | Discovery unit and useful facts | Explicit start/detail route | Important boundary |
| --- | --- | --- | --- |
| M `movie` | Movie work with available versions; runtime/remaining time, rating and language | Existing media detail / video navigation; edition/version picker when needed | Recheck codec, output, server access and offline state; preference for one quality does not mean others are unavailable |
| M `show` | Series card; identify first eligible episode or next unwatched/in-progress episode | Existing series detail and episode resolution before normal launch | Do not silently start a random later episode; show the exact selected episode and unit duration |
| M `season` | Season card only in a scoped series/season search; otherwise grouped under show | Season detail, then eligible episode | Preserve season identity and availability; missing seasons do not imply completion |
| M `episode` | Episode, usually grouped under series in mixed discovery | Existing episode navigation, respecting configured detail/play behavior | Spoiler-safe artwork/title/description policies; eligibility never reveals an inaccessible future episode |
| M `clip` | Clip or music-video item; kind and runtime | Existing video route | A clip is not automatically a trailer or sample of another work; relation must be explicit |
| M `artist` | Artist discovery, with a concrete album/track as a suggested starting point when available | Existing artist screen; explicit album/mix action if capability exists | Artist has no meaningful single runtime; never label an artist “3 min” from one arbitrary track |
| M `album` | Album/release edition; artist, tracks, total time if complete | Existing album screen/music service | Release variants stay distinct; no track flood in Anything mode |
| M `track` | Track when music-scoped, or inside a verified listening suggestion | Existing track-with-album-context route | Saving is not queueing/scrobbling/favoriting; do not replace an active queue on hover |
| M `playlist` | Playlist only when explicitly included; item count, media scope, known total | Existing playlist screen/launcher | Personal/dynamic lists can change; revalidate contents/permissions and do not treat as a single work |
| M `collection` | Collection as an optional exploration choice, not a fictitious playable leaf | Existing collection detail | Mixed collections drill down; explicit start resolves a real target |
| M `photo` | Metadata representation observed; browse/save only if a safe supported detail action exists | A functional photo viewer was not established by this audit | Exclude from consumable deck until a real viewer/capability is verified or separately built; never pass to the video launcher |
| M `folder` | Source/navigation scope rather than recommendation | Existing folder navigation | Do not recommend thousands of folders as content; traverse only user-selected/indexed scope |
| M `unknown` | Unclassified metadata | Existing safe detail if useful, otherwise no card | No guessed launch by extension or empty type; retain diagnostic capability reason without raw data |
| M live channel / program (separate from `MediaKind`) | Current program with channel, start/end and time remaining; optional upcoming scope | Existing live-TV navigation; upcoming goes to details/guide | Program identity includes server/channel/program or time interval; revalidate at start; Watch live means live, not restart/catch-up |
| M DVR recording | Recorded program as the adapter's video item | Existing recording/video route | Recording existence, completion and access are checked; never create a DVR rule on swipe |
| B `ebook` EPUB | Book edition; author, language, series order, optional estimated session/unit | Existing publication reader | Reflowable text vs fixed layout; no percent-to-audio conversion; sample state isolated |
| B `ebook` PDF | Document/book edition; pages, author/language if known | Existing PDF reader | Page count is not a reliable reading duration; scanned PDFs have no assumed accessible text |
| B `comic` CBZ / supported fixed-layout publication | Volume/issue; series and number, page count, reading direction when provided | Existing publication reader with image fit/zoom | Do not mix issue 9 into a first-issue session without disclosure; CBZ support does not imply CBR/RAR |
| B `audiobook` | Book/narration edition; author, narrator, abridgment, chapter/book duration and playback speed | `SourcePlayback` and existing source player | M4B, multipart audio and Audiobookshelf identity; filenames alone do not establish book grouping |
| B `music` from files/cloud | Known album/track grouping, or individual audio item with truthful label | Source media player, not manufactured server metadata | Generic MP3 remains music/audio unless metadata or explicit grouping establishes an audiobook |
| B `video` from files/cloud | Known film/episode/clip when metadata supports it; otherwise generic video | Source media player with source authorization lease | No fake Plex ID; extension is not proof of decoder support |
| B `folder`, `unknown` | Navigation/unclassified | Source browser / safe detail | Same non-content policy as media-server containers |
| B public-library book / loan / hold | Work plus exact available format and provider/library holding | Existing lending detail, official handoff or enabled circulation flow | Loan is not ownership; expiry/hold status and device fulfillment capability remain visible |
| M external `CatalogItem` movie/show/anime | Provider entry with exact IDs and relations, then matched library offers | `navigateToCatalogItem` / `CatalogItemDetailScreen` | Catalog art does not mean playable; anime seasons must not collapse into a parent series ID |

Podcasts, magazines, news, sports, home videos and educational files can appear **when an enabled adapter already represents them as one of these functional kinds**. Retain the supplied label/metadata. Do not advertise separate podcast subscriptions, magazine services, sports catalogs, games or new document formats merely because SeerrNG supports them. New kinds later implement the same adapter contract and are covered by an exhaustiveness test.

## Sources and rights

| Source | Reuse | Discovery policy | Write/consumption boundary |
| --- | --- | --- | --- |
| Plex / Jellyfin / Emby | `MediaServerClient`, `MultiServerProvider`, library queries and capabilities | Authorized profile libraries, server pagination, hubs and local completion state | Reuse per-item launch/version logic; static `ServerCapabilities` is insufficient for current permissions/entitlements |
| Plex catalog / Trakt / MAL / AniList / Simkl / Seerr / MDBList | `CatalogSourcesProvider`, `CatalogSource`, existing library matcher | Only connected and enabled sources, existing Explore gate; provider attribution | No extra accounts, implicit watchlist writes or direct Seerr HTTP calls; use existing request sheet for supported movie/show requests |
| Completed media downloads | Existing download database/resolver | Current profile, complete validated playable files, no online lookup prerequisite | Incomplete/stale/deleted files never count as offline-ready; don't auto-download missing files |
| Local file/folder | B `SourceController`, source repository/adapters | Imported or explicitly indexed scope, filenames only where needed | Read-only connected folder; no recursive scan on entering swipe |
| Google Drive / OneDrive / Dropbox | B source OAuth/transport | Cached indexed metadata and bounded existing browse APIs | Existing read scopes; sample/open renews lease; discovery never asks for cloud-write permission |
| WebDAV / Nextcloud / S3-compatible | B source adapters | Explicit root/prefix and bounded index | No writes to source media; optional state sync uses its own explicitly authorized destination |
| Audiobookshelf | B adapter and publication identities | Library books/editions/chapters and compatible primary/secondary formats | Reuse exact progress authority; preview must avoid progress/bookmark mutation |
| OPDS 1/2 | B adapter | Navigation/acquisition metadata; actual sample links when provided | Sample/open-access/download/borrow/purchase relations stay distinct; no fetch of purchase or borrow URL as owned file |
| OverDrive / Libby | B `LendingService` | Hidden native candidate source while `overdriveEnabled` is false; official service handoff remains | Coming soon preserved; only approved, configured and qualified native discovery/circulation can be enabled |
| Open Library | B public-catalog integration | Clearly labelled catalog picks when explicitly included | Availability and actual borrowing/reading stay with official service; no assumption of immediate local access |
| Hoopla / regional services | B official saved links | No native recommendations unless an approved documented adapter exists | Open official service; do not scrape authenticated apps or imply API support from a logo |

Candidates from library-owned media are useful and should not be discarded merely because ReadMeABook filters already-owned books for acquisition. Plezy is a consumption client: **what you already have is the default discovery pool**. Acquisition-oriented catalog results are a separate opt-in scope.

## Device capability matrix

| Target | Input/layout | Video/music/live | Existing books and source capabilities | Release evidence |
| --- | --- | --- | --- | --- |
| Android phone/tablet | Touch, accessibility, keyboard/controller where mapped; adaptive layout | Existing native backends and supported output routes | Existing source player and embedded EPUB/CBZ, PDF readers; provider/account/codec gates | Small/large device, TalkBack, rotation, interruptions, offline |
| iPhone/iPad | Touch, VoiceOver, keyboard/pointer; safe areas and split view | Existing iOS playback/cast routes where supported | Embedded reader/PDF/source playback; existing file/provider permissions | iPhone/iPad, VoiceOver, dynamic text, audio focus and return from system auth |
| Windows | Mouse/keyboard, resizable windows, screen reader | Existing Windows player and server routes | Existing embedded reader/PDF/source playback | DPI 100/150/200%, keyboard, NVDA, narrow window, multiple displays |
| macOS | Mouse/keyboard, VoiceOver, resizable windows | Existing macOS player/output capability | Existing embedded reader/PDF/source playback | VoiceOver, full screen, keyboard, audio interruption, large text |
| Linux x64/arm64 | Mouse/keyboard, accessible semantic tree where runtime supports it | Existing Linux player; decoder/display support checked | EPUB/CBZ foundation uses system browser with owned loopback capability; PDF stays in-app | At least supported packaged desktop environments; actual screen-reader bridge evidence, browser lifecycle and Wayland/X11 where shipped |
| Android TV / Google TV / Fire TV | Existing spotlight, D-pad, remote Back and select | Existing supported video/music/live paths | Foundation supports browsing and supported audio/video; document reading is unavailable | Physical low-resource TV/stick, 720p/1080p/4K, rapid key repeats and TalkBack where provided |
| Apple TV / tvOS | Existing focus engine/spotlight and Siri Remote | Existing video/music/live paths | Browse/save books if source metadata is available; no document reader; downloads unavailable in current navigation | Physical Apple TV, VoiceOver, remote focus, foreground-only preview; no offline-download promise |
| Automotive surfaces where already built | Existing car restrictions and approved media controls | Follow `CarUxRestrictionsService`; no rich discovery interaction when prohibited | Audio handoff only where existing integrations allow | Restrictions apply before presentation/preview/start; no new vehicle app claim |
| webOS | No current PlezyNG application target | Not delivered by this feature | Not delivered | Preserve `docs/maintainers/webos-tv.md` blockers; portable domain design does not constitute a port |
| Web, consoles, watches | No verified current target in this audit | No promise | No promise | A future adapter/platform port must pass the same capability and input contracts |

“All platforms” means every existing PlezyNG application target gets the discovery flow and appropriate actions. It does not mean every platform can decode every file, read every document or use every provider. On a TV, a book can be saved/discovered while the supported audio edition can be played. A disabled action must explain a known limit or be replaced by a meaningful supported action.

## Runtime capability decision

Evaluate in order: active profile permission → allowed library/catalog source → item/edition validity → current entitlement/loan → local/remote reachability → device/output support → explicit user constraints. Classify each operation independently: discover, detail, save, sample, play/listen/read, handoff, watchlist, request, download, borrow/hold, record.

An offer has an availability state such as `available`, `offlineReady`, `checkRequired`, `unavailable`, `expired` or `unsupportedHere`, plus a safe reason and freshness. Do not overload one Boolean `isAvailable` for ownership, playability, network and rights. Show only fresh evidence as “Available now”; cached claims show “Last checked …” until revalidated. Live availability is invalid after its program boundary, regardless of cache TTL.

Automated tests must enumerate all `MediaKind` and `SourceItemKind` values plus live-TV/catalog/lending families. Each maps to a supported adapter or an explicit exclusion reason. A future enum addition must break that completeness test until its behavior is chosen.
