# Native Silo backend

Plezy talks to Silo through Silo's own `/api/v2` API. It does not use the
Jellyfin compatibility listener (`:8096`). The code lives in `lib/services/silo/`.

| File | Purpose |
| --- | --- |
| `silo_api.dart` | HTTP client: tokens, single-flight refresh, bounded retries, problem+json errors, same-origin checks |
| `silo_auth_service.dart` | Address probe, password sign-in, profiles and PIN check, server-side revocation |
| `silo_client.dart` | `MediaServerClient` implementation: browse, search, hubs, playback negotiation |
| `silo_playback.dart` | Capability snapshot, start body, plan parsing, tracks and subtitles, sequenced progress and stop reporter |
| `silo_mappers.dart` | Silo JSON to `MediaItem`, `MediaLibrary` and hubs |
| `silo_api_cache.dart` | Offline metadata cache, scoped per server and profile |
| `../../screens/settings/add_silo_screen.dart` | Add-server flow |

## Contracts used

These contracts come from the Granary compatibility notes (`granary/silo-api.md`).

- **Login and refresh:** `POST /auth/login` and `POST /auth/refresh`. Refresh rotates the refresh token, and the new pair is persisted straight away through `ConnectionRegistry.upsert`.
- **Logout:** `POST /auth/logout` runs when a connection is removed. Local credentials are deleted first, so an unreachable server never leaves tokens on disk.
- **Profiles:** `GET /profiles` and `POST /profiles/{id}/verify-pin`. Every profile-scoped call sends `X-Profile-Id` (and `X-Profile-Token` when the profile has a PIN).
- **Playback:** protocol v3.
  - Capabilities are fetched with `installation_id`.
  - `POST /playback/sessions` starts a session. It retries once on `installation_changed`.
  - Progress goes to `POST .../progress`. It is sequenced and runs in order per session.
  - `DELETE .../sessions/{id}` stops the session, with a `stop_id` body.
  - The server decides completion (90%).
- **Media requests:** bearer and profile headers go to mpv as `http-header-fields`, and only for same-origin URLs.

## Security

- Access, refresh and profile tokens are encrypted by `CredentialVault`, the same as Jellyfin tokens.
- HTTPS is tried first, and a TLS failure is reported rather than downgraded.
- Plain HTTP is offered automatically only for local hosts: private ranges, `.local`, `.lan` and single-label names. A public `http://` address needs explicit confirmation.
- Tokens are never sent cross-origin and never logged.

## Not supported yet

- Downloads and offline playback
- External players
- Music
- Playlists, and editing collections
- Live TV
- Favourites and ratings
- Server-side account preferences
- Companion remote
- Seek re-anchoring on copy-remux sessions: seeking far into a remux restarts the session at the new position
- Translations: new strings exist in English only; the other locales fall back to it
