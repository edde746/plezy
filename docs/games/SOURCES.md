# Games research sources

Research checked 2026-10-26. Upstream implementation details may change; native source pins live in `games-native.lock.json`.

| Question | Primary source | What it establishes |
|---|---|---|
| Embedded GameStream engine | [Moonlight Android source](https://github.com/moonlight-stream/moonlight-android/tree/b48494cb96bff23d8886c4775cc4f39a1075495d) | Real pairing, app list, native session, decode/input/touch implementation and GPL license |
| Host pairing and variants | [Sunshine documentation](https://docs.lizardbyte.dev/projects/sunshine/latest/) and [source](https://github.com/LizardByte/Sunshine) | Host setup, approval and GameStream-compatible host behavior |
| New Steam beta | [Valve Pyrowave announcement](https://steamcommunity.com/groups/homestream/discussions/0/564794422009744473/) | Pyrowave is a beta codec, with platform/build requirements and explicit enablement |
| Pyrowave implementation | [Pinned source](https://github.com/Themaister/pyrowave/tree/79a3232a2199281f33f7a2e2659fc4fac62b022a) and [Metal notes](https://github.com/Themaister/pyrowave/blob/79a3232a2199281f33f7a2e2659fc4fac62b022a/metal/README.md) | MIT license, unstable C API, Vulkan implementation and qualifications on the Metal port |
| Steam Link SDK scope | [Valve Steam Link SDK](https://github.com/ValveSoftware/steamlink-sdk) | Builds apps for the Steam Link hardware; not a general streaming-client SDK |
| Steamworks API scope | [ISteamRemotePlay](https://partner.steamgames.com/doc/api/ISteamRemotePlay) | Game-side Remote Play session API |
| Independent Steam client | [ihslib upstream](https://github.com/mariotaku/ihslib) and [pinned current-auth fork](https://github.com/scaronni/ihslib/tree/04688d19951c68bedc4370234cc1752043632cb3) | Discovery/authorization/streaming library and current handshake, game-ID launch, HID and tracked-frame implementation used by the adapter |
| Working integration evidence | [Steam-Link-PS5 source](https://github.com/jmelovich/Steam-Link-PS5) | Developer-reported conventional-codec playback; useful implementation evidence, not certification of our port |
| Owned Steam games | [IPlayerService GetOwnedGames](https://partner.steamgames.com/doc/webapi/IPlayerService#GetOwnedGames) | Key/account/visibility requirements; ownership is distinct from installed host inventory |
| Device launch, host inventory and codec fields | [Observed Steam protobuf definitions](https://github.com/SteamTracking/Protobufs/tree/master/steam) | Wire-format evidence to validate against actual hosts, not a supported public API promise |
| UI alignment | [plezyng.app design-parity discussion document](https://github.com/snapetech-org/plezyng.app/blob/main/docs/design-parity.md) and PlezyNG's existing media grid/focus components | Artwork-forward card grids and TV focus consistency; concept imagery is not a shipped app screenshot |

The feasibility judgments and delivery ordering are engineering inferences from these sources. Platform parity, private Steam library access and compatibility with every historical host remain testable work, not assumptions.

## Additional verification

- [Pyrowave bitstream v1](https://github.com/Themaister/pyrowave/blob/79a3232a2199281f33f7a2e2659fc4fac62b022a/bitstream/bitstream.md) and the pinned `pyrowave_decoder.cpp`: `push_packet` iterates over multiple codec packets in a buffer. A separate API call for every block is not required. This does not establish Steam transport framing or GPU presentation compatibility.
- [Aurora Android](https://github.com/Koloses/aurora-android) and [Solarflare](https://github.com/Koloses/Solarflare) demonstrate an independent GameStream/Pyrowave route. Their transport and codec forks must not be assumed compatible with Valve's Steam route. They are research references, not bundled engines in this change.
- [Valve's current Steam Link distribution](https://repo.steampowered.com/steamlink/latest/) lists build 1.4.3.323. Its presence is not an embeddable-client SDK or redistribution grant; PlezyNG uses source-built independent libraries.

The exact IHS runtime pin now includes game-ID serialization and current/legacy authorization support upstream. The former preparation-only game-ID patch has been removed. The portable adapter is compiled and regression-tested; no real Steam host or GPU was available for interoperability qualification.
