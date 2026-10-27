# Client-side Dolby Vision compatibility playback

## Implemented behavior

The TV need not understand Dolby Vision when the client reconstructs/reshapes
the source and renders ordinary HDR or SDR. Output color conversion is separate
from FEL reconstruction. No downloaded LUT or precomputed per-movie map is
required. HDR-to-SDR still requires tone and gamut mapping.

| Input | Compatible base | Client processing |
| --- | --- | --- |
| P5 | None | Preserve RPU, reshape and convert color representation before HDR/SDR rendering. Never treat bare P5 HEVC as HDR10. |
| P7 MEL/FEL | HDR10 | Base-layer playback is valid compatibility output. Full FEL requires synchronized BL/EL decoding and composition before output mapping. |
| P8.1 | HDR10 | Native compatible base, or DV reshaping where available; map to the output. |
| P8 with compatibility ID 2 | SDR | Preserve the inspected SDR base semantics. |
| P8.4 | HLG | Native HLG or color conversion to PQ/SDR; do not relabel HLG as PQ. |

### Android app

The existing **Disable Dolby Vision** and **HDR-to-SDR conversion** preferences
are used; there is no additional settings panel.

- mpv now excludes native P5 DV decoding when DV output is disabled. Such a
  decoder could otherwise re-engage DV on a DV-capable TV despite the setting.
  P5 takes software decoding plus `gpu-next` reshaping, retaining RPU metadata.
- Software P5 fallback uses the reshaping renderer under every supported
  conversion mode, including explicit P7/native modes. Those modes cannot make
  software-decoded P5 a compatible base layer.
- Live DV preference changes re-run the same decoder/renderer policy as the
  preloaded hook. The existing hardware-decoding hold and video-plane arbiter
  manage the transition and restoration on later files.
- ExoPlayer now acts on the output preferences previously only queued for a
  hypothetical future fallback. A DV format with DV disabled, or HDR on an SDR
  display with player conversion selected, requests the existing in-app mpv
  handoff. The property is queued before handoff and replayed into the new core.
  Existing media-generation, seek-position, headers, pause state, and track
  restoration machinery owns the transition.
- Compatible P7/P8 HEVC base layers stay on ExoPlayer where native output meets
  the preference. Automatic/device HDR mapping is preserved; no blanket move
  of all HDR content to expensive software rendering is introduced.

P5 software decoding can be slower than native DV on low-power devices. There is
no safe wrong-color fallback for P5. A different available rendition is needed
when the client cannot decode and reshape it at playback speed.

### Experimental engine: real-time output targets

The existing isolated Linux engine now packages `output_target.py` alongside
`run.py`. Rebuild/repackage an older artifact before using the new launcher.

```sh
python3 tools/dv-engine/run.py --engine /path/to/engine --target auto -- /media/movie.mkv
python3 tools/dv-engine/run.py --engine /path/to/engine --target sdr -- /media/movie.mkv
python3 tools/dv-engine/run.py --engine /path/to/engine --target hdr10 --peak-nits 600 -- /media/movie.mkv
```

This is playback rendering, not the offline companion encoder. `auto` negotiates
through mpv's graphics context. SDR requests BT.709/sRGB with an explicit 100-nit
target (overridable), setting both `target-peak` and `sdr-peak`. HDR10 requests
BT.2020/PQ; only request it on an output already known to support HDR. Without a
peak override, the sink owns HDR display mapping. GPU peak detection supplies
dynamic brightness analysis where supported.

Managed targets do not load user mpv configuration, filters, profiles or LUTs
that could silently override the conversion. Ordinary launcher mode remains
available for custom experiments. Media arguments are passed directly to
`execve`; they are never shell-expanded. `--target` is rejected with `--app`:
the embedded app's surface negotiation owns those properties, and setting only
the renderer half could pair PQ pixels with an SDR surface.

Original DV RPU and the existing FEL engine graph are preserved. This change
does not add a profile rewrite, discard EL, or claim a new FEL reconstruction
algorithm. A missing/failed FEL layer remains subject to the engine's existing
failure handling.

### Portable route contract

`route_policy.py` accepts `display_outputs` in the report and `--target
auto|hdr10|sdr`. Adapter output must match both the current display and any
explicit target. Old reports without display constraints retain their existing
contract; production callers must provide current output capabilities.

The new `tone-map` adapter requires an inspected compatible base and explicit
`color_conversion` evidence. `reshape` requires P5/P7/P8 plus RPU presence. P5
is rejected as a base even if a caller incorrectly labels it HDR10. P8
compatibility IDs are cross-checked. P7 base/reshape/tone-map paths report
discarded enhancement; only the existing independent FEL evidence contract can
claim reconstruction. A qualified FEL adapter may output SDR without claiming
physical DV signaling. Failed/stale adapters remain ineligible.

## Platform boundaries

| Path | State after this change |
| --- | --- |
| Android mpv/ExoPlayer | Output-preference and P5 fallback changes are connected to the app. Device transition/throughput qualification remains required. |
| Windows | Existing `gpu-next` automatic HDR/SDR output retained, including Adreno safeguards. No new FEL hardware adapter. |
| Linux production app | Existing Wayland HDR/SDR surface negotiation retained. Legacy OpenGL embedding is not promoted to a P5/FEL-capable renderer. |
| Linux experimental app | Existing opt-in `opengl-next`/FEL integration retained. Standalone launcher gains explicit output targets. |
| Apple | Existing native output path and separate experimental host retained. No production integration of the experimental dual-layer engine is claimed. |
| webOS | Existing native/compatible-base support retained. No portable GPU composer exposed by this change. |

The portable selector is still a tool/adapter contract, not a replacement for
all native app policies. Universal full-FEL playback is not complete: Apple
production integration, Windows FEL integration, and Android/webOS reconstruction
adapters remain actual engineering work, not merely a checkbox for device tests.

## Validation

Local validation for this change: 44 compiled Kotlin policy tests and 24 Python
route/output tests passed. Kotlin tests exercise real policy classes with JUnit,
not translated replicas. Full Android core/plugin compilation and device video
playback were not run locally. No HDR/FEL pixel accuracy or throughput result is
inferred from policy tests. Existing private-JIT CI is the integration check.

Device qualification should cover P5/P7 MEL/P7 FEL/P8.1/P8.4 on DV, HDR10-only,
HLG, and SDR outputs; repeated seek and pause; preference changes while playing;
P5-to-SDR-to-P5 playlists; ExoPlayer handoff; missing RPU; renderer refusal;
FEL residual controls; subtitles; audio sync; and long-run thermal behavior.
Use independent output captures and a residual-bearing FEL control to establish
image correctness. A source profile, requested option, or TV DV badge alone is
not that evidence.

Primary references: [libplacebo](https://github.com/haasn/libplacebo),
[mpv output and tone-mapping options](https://mpv.io/manual/stable/), and
[Dolby profile compatibility](https://ott.dolby.com/OnDelKits/Dolby_Vision_Online_Delivery_Kit/v1/Documentation/Specs/Visio_Profiles/help_files/topics/c_dovi_profiles_public.html).
