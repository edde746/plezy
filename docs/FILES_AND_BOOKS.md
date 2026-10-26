# Files, books and listening

Choose **Use files and books** on the sign-in screen to start with a local profile and no media server. Existing profile PINs still apply. Open **Libraries → Files and books** to connect a source or import a file. Choose which shelves a connection contributes to: **Ebooks**, **Audiobooks**, **Comics**, and **Videos** appear in the same library picker and navigation rail as existing media libraries. A discovered comic also makes its shelf available. Public libraries are linked from the Files and books screen; their loans remain separate from files you own.

The screens use PlezyNG's Mono theme, connected settings rows, cover grids, shared menus, focus controls and confirmation dialogs. Provider marks retain their official colours and proportions. Settings → Appearance → Accessibility applies across the existing app as well as these screens.

## Sources

| Source | Connection | Content and state |
| --- | --- | --- |
| Local files | Import using the system picker; desktop users can connect a folder | Imports are copied into profile-owned storage. Connected folders remain read-only. Kodi/Jellyfin `.nfo` metadata and sibling poster images enrich local video details offline. |
| OPDS 1/2 | Atom or JSON catalogue URL; optional Basic credentials | Standard direct, open-access and sample acquisitions; navigation and pagination; catalogue covers. Borrow/purchase links are never treated as files. |
| SMB2/3 | `smb://server/share`, optional account, folder, and SMB3 encryption | Read-only NAS browsing with range-based streaming on Android, iOS, macOS, Windows, Linux, and tvOS. Kodi/Jellyfin `.nfo` sidecars and sibling poster images enrich details offline. Standalone video playback can search/download subtitles through a user-configured OpenSubtitles API key. |
| FTP / FTPS | `ftp://server:21` or `ftps://server:21`, optional account, folder | Read-only passive FTP and FTPS browsing with byte-range playback (explicit TLS by default; implicit TLS on port 990). Plain FTP sends credentials and media without transport encryption; prefer FTPS on untrusted networks. |
| DLNA / UPnP | Device-description URL, such as `http://server:8200/rootDesc.xml` | Read-only ContentDirectory browsing and media streaming. Enter the device URL manually; automatic multicast discovery is not included. |
| Audiobookshelf | Server URL and the user's API token | Libraries, books, primary/secondary ebooks, multipart tracks, chapters, covers, reading/listening progress and audio bookmarks. |
| Google Drive | Hosted Google authorization | Read-only folder browsing, shared-drive items/resource keys, fresh download authorization. |
| OneDrive | Hosted Microsoft authorization | Read-only Microsoft Graph browsing and fresh download URLs. |
| Dropbox | Hosted Dropbox authorization | Metadata/content read scopes and short-lived content URLs. |
| WebDAV / Nextcloud | HTTPS endpoint, folder and optional account/app password | Read-only NAS/cloud file browsing; optional state sync to a separate existing WebDAV folder. |
| S3-compatible storage | Bucket endpoint, prefix, region and restricted access credentials | List and signed GET requests; no upload, delete or bucket-management operations. |

An indexer/organizer such as Chaptarr does not need an NG fork. Expose its organized files through a supported standard service or point Audiobookshelf/OPDS at the library. No private Chaptarr endpoint or dependency is required. S3-compatible storage is a protocol, so its row deliberately uses a generic cloud symbol rather than an AWS endorsement.

Search filters the loaded/indexed files and their title, author, narrator and series. **Scan library** walks nested folders and pages with bounds (32 levels, 10,000 folders, 100,000 entries); use **Cancel scan** in the same source menu to stop after the current request. Browse and partial cached results remain available if a provider fails. Group an audio folder when its files form one book; review/reorder the parts before listening. Format and codec support still depends on the native player and platform.

## Reading

- EPUB uses the vendored Foliate JS engine, including reflowable/fixed-layout books, contents, CFI resume, search, selection highlights/notes and embedded EPUB media-overlay read-along.
- PDF uses pdfrx with page resume, search, outlines, selection notes and native pinch/pan. PDF notes store page/text locations; they do not rewrite the PDF or paint geometric PDF annotations.
- CBZ uses the same fixed-layout engine, with natural page ordering. CBR/RAR, proprietary ebook formats and DRM removal are not provided.
- Reader preferences include app/paper/sepia/night colours, serif/sans/monospace text, font size, line/letter/word spacing, margins, alignment, columns and scrolling. Reflowable text respects the app/system text scale.
- Fixed pages have zoom in/out, actual size, fit page/width, one/two-page layouts and automatic/LTR/RTL reading direction. Pinch and drag work alongside explicit controls; Ctrl/Command +/− and 0 adjust/reset zoom, arrows pan enlarged pages, and Page Up/Down turn pages. Contents and page/chapter number entry provide non-gesture navigation.
- Screen-reader semantics remain available for textual books/PDFs and every control. Image-only comics and scanned PDFs have no invented descriptions or OCR; meaningful image descriptions depend on the publication. Platform text-to-speech can read available text; Linux uses the browser's installed speech voices.

NFS and SFTP sources are not implemented yet. DLNA requires the device-description URL; SSDP multicast discovery is not included. HDR, Dolby Vision, Atmos and specific codec output still depend on each platform's player and hardware decoder. The separate [experimental Linux Dolby Vision Profile 7 FEL work](https://github.com/snapetech-org/PlezyNG/pull/16) remains opt-in and is not integrated into normal source playback; real FEL stream, app and hardware validation is still required.

On Android, iOS, macOS and Windows, EPUB/CBZ use an embedded webview. Linux opens the same engine in the system browser, through an expiring localhost capability owned by the open PlezyNG reader. Keep that reader open; closing it or changing profile retires the bridge and removes extracted files. PDF stays inside PlezyNG on Linux. TV builds can browse sources and play audio/video; document reading is deliberately unavailable there. Browser/native accessibility and codec behavior still require physical-device checks on each release platform.

## Listening and ordinary media

The Videos shelf indexes supported video files during a source scan and opens their original bytes through PlezyNG's native player path, without manufacturing Plex items. Files can keep an offline copy. Local and SMB video details can use Kodi/Jellyfin `.nfo` metadata and local poster sidecars; a user can also manually match a standalone video against Trakt to save its online overview, poster, year, rating, genres, cast, external IDs and trailer link. Sidecar fields remain authoritative when present. Standalone playback can search/download subtitles from OpenSubtitles when a source has an API key configured. Video watch progress is profile-scoped and durable on-device. A single configured WebDAV state folder can sync progress and notes for SMB and other file sources across devices when each device uses the same source identity. SMB remains read-only. It supports multipart source-time resume, chapter navigation, adjustable speed/skips, smart rewind, a sleep timer/end-of-chapter stop, bookmarks, headphone/interruption handling, a mini-player, and audio/subtitle selection for video. It claims playback through the existing coordinator so video, music, narration and books do not overlap. Vehicle playback restrictions also apply.

Reading, listening and watching have independent progress and edition identities. Reset/finish are explicit history events. A delayed screen/player write cannot overwrite a newer revision. Remote conflicts offer a choice rather than silently choosing the furthest percentage. Audiobookshelf sync only applies to the exact compatible primary ebook/audio edition; device-local history for other editions remains useful.

## Offline, sync and privacy

Download editions explicitly from the detail screen. Completed files publish atomically after validation; interrupted HTTP transfers only append with a matching representation validator. Provider URLs are renewed on open; bearer tokens never reach the player, EPUB JavaScript, artwork cache, logs or cross-origin redirects. A session-owned localhost gateway handles streaming and range requests. Only complete, fingerprint-matching, profile-owned files count as offline.

Progress/notes are durable locally. Sync coalesces recent changes and retries pending state when the owning profile is active. A single configured WebDAV state folder can sync progress and notes for WebDAV, SMB, and other file sources across devices; it uses per-source/per-edition files and strong ETags/conditional writes. Configure the same SMB endpoint and root on each device. For other sources, keep the source name, endpoint, and root consistent too. When multiple WebDAV state folders are configured, cross-source sync stays local until the target is unambiguous. The user chooses a separate existing folder. It never changes media files. Audiobookshelf progress/bookmarks use its existing APIs. Cloud-drive accounts are read-only and do not receive hidden state files.

Disconnect removes credentials and keeps local history/completed downloads. Deleting a profile removes its source/lending credentials, state and managed publication files. Switching or locking a profile retires readers, authorization attempts, downloads, stream capabilities and audio sessions. Credentials use the existing CredentialVault, separate from public source configuration.

## Cloud app registration

A released app normally supplies public OAuth client IDs. Users sign into the provider's own browser/SDK screen; PlezyNG never collects Google/Microsoft/Dropbox passwords. Advanced **App registration** fields support a maintainer or self-built client. Developer approvals, provider verification, redirect registration and platform entitlements must be completed for the actual release identity.

- Google: enable Drive API and configure the OAuth consent screen. The app reads existing folders, so `drive.readonly` is used; complete Google's required verification for distributing an app with that scope. Register Android package/signing certificates and an iOS client/bundle. Android uses Google Sign-In's configured web/server client ID. iOS additionally needs the reversed client ID in `CFBundleURLTypes` and the matching native registration. Desktop uses an installed-app client with a loopback redirect and PKCE. Its client-secret field is an installed-app credential, not a confidential web-server secret.
- Microsoft: register a public client in Microsoft Entra supporting the intended account types. Delegated scopes are `Files.Read offline_access`. Register the desktop loopback callback and mobile custom scheme below; do not add a confidential client secret to the app.
- Dropbox: register the appropriate scoped app, enable `files.metadata.read` and `files.content.read`, register redirects and request production access as required. The user authorizes the app; refresh tokens are encrypted locally.

Public build definitions: `GOOGLE_DRIVE_DESKTOP_CLIENT_ID`, `GOOGLE_DRIVE_IOS_CLIENT_ID`, `GOOGLE_DRIVE_SERVER_CLIENT_ID`, `ONEDRIVE_CLIENT_ID`, `DROPBOX_CLIENT_ID`. Desktop callback: `http://127.0.0.1:53682/oauth/callback` for Microsoft/Dropbox; Google uses an ephemeral loopback port. Mobile Microsoft/Dropbox callback: `plezyng-source://oauth/callback` (registered in Android/iOS manifests). Follow each provider's current registration rules for the platform. Never put OverDrive or other confidential developer secrets in `--dart-define`.

Official references: [Google Drive authorization](https://developers.google.com/workspace/drive/api/guides/api-specific-auth), [Microsoft native OAuth](https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-auth-code-flow), [Dropbox OAuth](https://developers.dropbox.com/oauth-guide). Asset provenance and usage notices are in `assets/provider_marks/` and the app's Licenses screen. The webview wrapper's Linux-only manifest adjustment is documented in `packages/flutter_inappwebview/PLEZY_PATCH.md`.

## Verification

`flutter test test/sources test/lending test/widgets/app_accessibility_test.dart` exercises adapters, profile/state revision rules, download recovery, archive rejection, library circulation boundaries, multipart playback and theme/screen behavior. The real-engine test additionally needs Node with Playwright and `PLEZY_CHROME_PATH`; set `PLEZY_PLAYWRIGHT_PATH` if Playwright is installed outside Node's normal module search. It renders an EPUB and CBZ in an actual browser, exercising CFI/search/sanitization and comic zoom/RTL/navigation. Set `PLEZY_READER_SCREENSHOT` to an output PNG to inspect the result. Physical VoiceOver/TalkBack/NVDA, TV remote, provider-account and DRM fulfillment checks remain release acceptance work, not a claim made by the unit tests.
