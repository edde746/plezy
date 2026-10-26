# Steam library and one-tap launch

Research date: 2026-10-26. The desired interaction is **link computer/account once → browse games in PlezyNG → choose a game → play inside PlezyNG**. A linked streaming device, a Steam account identity, an owned-game list and an installed host inventory are separate capabilities.

## Evidence and confidence

| Capability | Evidence | Confidence and limit |
|---|---|---|
| Owned games with names/icons | Valve's `IPlayerService/GetOwnedGames` accepts `steamid`, a Web API key, and `include_appinfo`; visibility controls apply | High that the API exists. This does not identify which host has a game installed or grant private-library access after device PIN pairing |
| Host-specific installation/status updates | `CMsgRemoteClientAppStatus` carries app IDs, installation state, update/cloud status and shortcut metadata | High for the schema. Unknown that a Steam Link-style PIN session alone is authorized for this Steam-to-Steam control channel |
| Direct game launch in a device stream request | `CMsgRemoteDeviceStreamingRequest.gameid`, field 19 | High for the field. Requires an authenticated host, compatible request handling and an actual embedded playback engine |
| Direct launch with progress and conflict results | `CMsgRemoteClientStartStream.app_id` and response launch-task/cloud-conflict fields | High for the schema. This is a separate control path; do not confuse it with device broadcast pairing |
| Current ihslib device pairing | The pinned fork exposes host-specific secret keys and authorization callbacks | Moderate for portability: source and another project's working client exist; PlezyNG has not qualified it on hardware |
| App-specific launch through the pinned ihslib C API | The pinned request struct includes game ID and the adapter supplies it | Compiled; a loopback test verifies serialized game ID 620 and non-desktop launch. Host launch remains unverified |

The account flow now uses Steam OpenID 2.0 through PlezyNG's server OAuth proxy. Steam handles its own password and Steam Guard prompts in the browser; PlezyNG stores only the validated 17-digit Steam ID and does not receive a password, guard code, access token or refresh token. If the server is configured with `STEAM_WEB_API_KEY`, it calls `IPlayerService/GetOwnedGames` and returns only visible owned-game metadata. The key remains server-side. Without the key, identity linking still succeeds and the catalog is reported unavailable. Private profiles are never converted into empty libraries.

The imported catalog is bounded to 2,000 entries and reports truncation. A failed refresh for the same account retains the last visible catalog and marks it stale; linking a different account clears the previous account's catalog. These account-owned entries do not identify a host where a game is installed. Tapping an entry launches it only when a saved Steam computer has a matching app-ID shortcut; multiple matching computers open a chooser. The host validates the launch request. Otherwise the UI asks the user to connect a computer and add the shortcut. The API does not establish a remote-install route or a Steam-to-Steam control channel.

## Chosen architecture

Use **host inventory as the authority for “Play now.”** Account ownership supplements it; it never turns an uninstalled game into a playable shortcut. The preferred host inventory route is a verified authenticated Steam control channel. If that is unavailable to a paired device, a narrowly scoped optional host helper can read the signed-in host's Steam library manifests and expose a bounded, authenticated inventory. A helper is additional host setup, not a hidden requirement falsely presented as ordinary Steam pairing.

The helper alternative should read `libraryfolders.vdf`, installation manifests, host-local app metadata and explicitly shared non-Steam shortcuts. It must not scan unrelated files, upload the user's whole filesystem, or derive authorization from local-network presence. Pair it separately, pin its certificate, and accept only game IDs from a fresh advertised inventory. If distribution requires a helper, integrate its installer into the host setup flow and clearly label its purpose.

A second optional source can load visible account-owned games. It enriches names/icons and displays “Not installed” entries, with a separate install action only after a verified remote-install control path exists. A denied/private account library is an unavailable source, not an authoritative empty list; preserve cached entries and explain the refresh limitation.

Canonical game identity is the Steam AppID for Steam apps and a host-scoped shortcut ID for non-Steam apps. Preserve 64-bit game IDs as strings or native uint64 values; JavaScript numbers must not round them. Attach zero or more host routes to each game. Do not infer Family Sharing eligibility or bypass parental/host restrictions from an ownership list.

```mermaid
flowchart TD
  Account["Visible account library"] --> Catalog["Canonical game catalog"]
  Host["Authenticated host inventory"] --> Catalog
  Catalog --> Tap["Choose a game"]
  Tap --> Route{"Ready host route?"}
  Route -->|One| Start["Authenticated game-ID request"]
  Route -->|Several| Picker["Remembered host or host chooser"]
  Picker --> Start
  Route -->|None| Explain["Offline, unavailable or not installed"]
  Start --> Result{"Host response"}
  Result -->|Ready| Stream["Embedded stream"]
  Result -->|Needs action| Prompt["Host approval or conflict choice"]
  Prompt --> Start
```

## One-tap behavior

- Show the saved library immediately; refresh host state in the background.
- For one available compatible host, start directly. With several, prefer the user's remembered host if still ready; otherwise show a compact chooser.
- Wake only a host with a known, user-configured MAC and Wake-on-LAN support. Wait for an actual host response with a deadline. A sent magic packet is not proof that the host woke.
- Send the selected game ID through the authenticated native transport. Negotiate codec, audio and input; mount the native session inside PlezyNG.
- Preserve host launch states such as updating, screen locked, busy, parental approval, cloud-save conflict, EULA or launch-option choice. “One tap” must not silently accept agreements or choose between conflicting saves.
- Track recent launch only after a native launch request is accepted. Display actual session connection state separately. Cancellation must stop connection work without launching later from a stale callback.

## Concrete work in this change

The profile-scoped library, favorites, recent launches, native `games(host)` boundary and game-ID launch arguments are implemented. The Android GameStream adapter fills the grid from a paired host's real app list and artwork.

The experimental Android Steam adapter now performs device PIN pairing and saves a host-specific secret with Android Keystore encryption. The embedded stream supports a Steam Library/Big Picture card (game ID zero) and manually added game-ID shortcuts. It sends direct game IDs through the upstream request API and uses an in-process player. Refresh preserves these shortcuts. Neither device pairing nor the Big Picture card is described as an imported account catalog.

**Steam account identity and visible owned-game catalog import are implemented.** The browser flow is Steam OpenID, with signed assertion verification and one-use state. A deployment may supply a server-owned `STEAM_WEB_API_KEY` through `server/docker-compose.yml`; no key is embedded in the client or required from each user. The Steam Web API only returns visible account details, so private libraries remain unavailable instead of appearing empty. Catalog rows are cached per profile, bounded to 2,000, account switches discard the prior catalog, and failed refreshes mark a retained catalog stale.

Account import is display-only. The existing Steam device pairing and Big Picture session remain the in-app playback path; the account catalog does not prove host installation or authorize game launch. Steam Guard challenges, when Steam requires them, stay on Steam's browser page. This does not implement account-authenticated internet rendezvous, private inventory access or remote installation.

The former game-ID preparation patch is unnecessary at the current runtime pin and has been removed. The native loopback regression test verifies that selecting a game serializes its ID without setting `stream_desktop`; this does not prove acceptance by every Steam host.

## Acceptance tests before enabling Steam library playback

1. Public and private game details; Family Sharing eligibility; free titles; non-Steam shortcuts.
2. Same game on two hosts; host rename/IP change; account switch; profile switch mid-refresh; revoked device key.
3. Large library, missing artwork, partial/delta update, offline refresh and stale cached inventory.
4. Installed/uninstalled/updating/borrowed/busy/locked states; game-ID launch to the selected host.
5. Legacy and current PIN exchanges; current Steam stable and beta; host changes a codec or requests unsupported input.
6. Cloud-save conflict, EULA, parental lock and launch-option prompts without automatic acceptance.
7. Exactly one stream per tap; cancellation before handshake, during launch and after native surface creation.
8. Conventional-codec fallback when Pyrowave is unavailable, without losing selected game or host.

## Sources

- [Valve IPlayerService documentation](https://partner.steamgames.com/doc/webapi/IPlayerService#GetOwnedGames)
- [Valve authentication overview](https://partner.steamgames.com/doc/features/auth)
- [Observed device discovery/stream request schema](https://github.com/SteamTracking/Protobufs/blob/master/steam/steammessages_remoteclient_discovery.proto)
- [Observed remote-client inventory and launch schema](https://github.com/SteamTracking/Protobufs/blob/master/steam/steammessages_remoteclient.proto)
- [Pinned ihslib client API](https://github.com/scaronni/ihslib/blob/04688d19951c68bedc4370234cc1752043632cb3/include/ihslib/client.h)
- [Pinned ihslib stream request serializer](https://github.com/scaronni/ihslib/blob/04688d19951c68bedc4370234cc1752043632cb3/src/client/streaming.c)

The observed protobuf repositories are implementation evidence, not a Valve guarantee of a supported public API.
