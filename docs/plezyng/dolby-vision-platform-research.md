# PlezyNG Dolby Vision research and implementation priorities

> Implementation checkpoint: the [buildout guide](../maintainers/dv-platform-buildout.md) and [Luna evidence](../maintainers/dv-engine-luna-handoff.md) supersede statements below about the absence of a real-clip run. Research routes below are not all implemented or qualified.

Assessed 26 October 2026. **Recommendation confidence: high.** Continue the shared FFmpeg/libplacebo/mpv reconstruction work, and broaden the design to support native platform playback, local reconstruction with several output adapters, and an optional companion renderer. Automatic compatibility fallback is part of the intended product behavior. Genuine Profile 7 FEL reconstruction remains the fidelity goal.

Confidence terms: **high** means a documented interface, inspected implementation, or strong architectural conclusion; **moderate** means a concrete implementation exists but PlezyNG integration or device behavior needs qualification; **low** means a plausible research route with substantial missing evidence; **unknown** identifies a specific unresolved capability. Project authors’ device reports remain attributed reports.

# Changes to the current plan

The existing experimental engine is a useful shared foundation. [mpv FEL PR 17932](https://github.com/mpv-player/mpv/pull/17932) is merged; the [opengl-next embedding RFC 18607](https://github.com/mpv-player/mpv/pull/18607) remains open. The latter is one integration adapter, not the architectural boundary for every platform. PlezyNG should be able to deliver reconstructed frames to native Apple surfaces, Android surfaces, desktop HDR swapchains, or a companion encoder without making all of those routes depend on this OpenGL embedding proposal.

The starting handoff records successful builds and synthetic rendering checks, with real-media and physical-output qualification still outstanding at that checkpoint. Luna’s current testing may advance those results. [Engine handoff](https://github.com/snapetech-org/PlezyNG/blob/main/docs/maintainers/dv-engine-luna-handoff.md). Separately, the current [webOS status](https://github.com/snapetech-org/PlezyNG/blob/main/docs/maintainers/webos-tv.md) already records PlezyNG running and playing video on the C6. The older research task to first establish a functioning webOS app should be replaced with native DV/container and raw-surface capability tests.

# New implementations worth evaluating

**Apple hybrid reconstruction — moderate confidence as a PlezyNG candidate.** [AetherEngine’s FEL implementation](https://github.com/superuser404notfound/AetherEngine/blob/e6f785a96ab68336966f8d01305d289f87b59752/docs/dolby-vision-fel.md) uses two VideoToolbox decoders, Metal composition, and 10-bit P010 output. Its author reports real-time UHD film playback on an A12 Apple TV running tvOS 27. The common code also targets iOS, iPadOS and macOS, but metadata consumption there is unmeasured. This justifies an Apple prototype now. Its bilinear enhancement upsampling and limited reference comparisons do not establish Dolby-equivalent reconstruction.

The inspected [Apple metadata bridge](https://github.com/superuser404notfound/AetherEngine/blob/e6f785a96ab68336966f8d01305d289f87b59752/Sources/AetherEngine/Video/DoviDisplayMetadata.swift) attaches an adjusted RPU through undocumented CoreVideo keys. It records a system compositor crash caused by a wrong attachment type. Invocation of that compositor path establishes a useful hook; it does not prove correct trims or final pixels. Keep this adapter isolated and disabled unless qualified for the OS/device. Apple’s documented [EDR rendering](https://developer.apple.com/videos/play/wwdc2022/10113/) supplies a separate custom-HDR presentation route.

**Amlogic hybrid reconstruction — moderate confidence for a device-specific experiment.** [djnice’s CoreELEC S5 build](https://github.com/djnice/CoreELEC-samurihl/releases), including the 13 October release, decodes both layers, composes FEL on Mali, and feeds reconstructed pixels plus identity P8.1 mapping into the existing Dolby hardware path. Reported limits include 4K24, roughly 35 ms GPU time per frame, 10-bit output with dither, and occasional color flashes. Its VICP/kernel/firmware dependencies make this a hardware-specific adapter, not an ordinary Android application feature.

**MDK 0.39 — moderate confidence as a comparison engine.** The [30 September release](https://github.com/wang-bin/mdk-sdk/releases/tag/v0.39.0) advertises single-track and separate-track FEL decoding with Metal, OpenGL/ES, Vulkan, D3D11 and D3D12 rendering. Its [HDR documentation](https://github.com/wang-bin/mdk-sdk/wiki/HDR) describes application-side processing with SDR/HDR10 display output; its use of “LLDV” should not be treated as proof of Dolby HDMI signaling. Use it to compare integration effort, speed, and output against our engine. The [SDK distribution model](https://github.com/wang-bin/mdk-sdk#license) uses a binary core and keys, so its availability does not provide a complete source-maintained replacement for our build.

**Linux TV-led output — moderate confidence on an admitted display chain.** [CB1](https://github.com/CroqueMr/libreelec-x86-DV) provides a concrete custom Kodi/LibreELEC route. Its [Master Reference contract](https://github.com/CroqueMr/libreelec-x86-DV/blob/main/CB1/docs/MASTER-REFERENCE.md) defines restricted integer reconstruction and transport. Its [CM4 qualification](https://github.com/CroqueMr/libreelec-x86-DV/blob/main/CB1/docs/CM4-QUALIFICATION.md) distinguishes metadata preserved from controls executed by an independent mapper. Adapt a small transport interface and maintain the exact driver/display allowlist; a normal Wayland HDR surface does not provide the same transport.

**Offline and companion processing — high confidence in feasibility; throughput depends on hardware.** [FelBaker](https://github.com/bbeny123/felbaker) implements CPU BL/EL/RPU composition to PQ12 through VapourSynth on desktop platforms. It is a useful reference and a route to optimized media versions. FelBaker and DoViBaker share implementation ancestry and should not be counted as two independent correctness oracles. Their short benchmark examples do not establish end-to-end real-time 4K streaming.

# Architecture

Treat each presented frame as one unit: source generation, picture identity/timestamp, raw base and enhancement surfaces, original RPU, parsed composition parameters, color description, and processing status. Pair by picture identity with explicit reorder/seek handling. Preserve raw decoded sample values until reconstruction; an enhancement layer is residual data and must not be tone-mapped or color-converted as an ordinary picture.

Separate reconstruction from display mapping and physical output. [ETSI GS CCM 001](https://www.etsi.org/deliver/etsi_gs/CCM/001_099/001/01.01.01_60/gs_ccm001v010101p.pdf) supplies composer mathematics and an informative resampling reference. It does not define every modern proprietary display-mapping behavior. An exact comparison with a stated decoded-image contract is possible even though the source compression is lossy; equality to the original uncompressed master is a different claim.

| Stage | PlezyNG-owned contract |
| --- | --- |
| Identify | Codec, profile, compatibility ID, layers, metadata version/compression, container and view layout |
| Decode | Native, hardware, software, or mixed BL/EL decoding; preserve raw samples and metadata |
| Reconstruct | CPU reference and GPU implementation; track residual availability, composition and actual presentation |
| Map | Native Dolby processing where available, independently qualified mapping, or forwarding to the sink |
| Present | Native DV, HDR10, HLG, EDR/scRGB, SDR, or an encoded companion stream |
| Select | Device, driver, surface, display chain and measured capability; re-evaluate after route changes |

The most useful hybrid is: reconstruct the enhancement contribution first, then hand a single reconstructed image to an existing native display pipeline. The mapping metadata must describe the new pixels, so the native pipeline does not apply the original reshape twice. If raw-frame re-entry is unavailable, reconstruct and encode a compatible stream. Encoding introduces its own quality and latency costs; a single-layer result can nevertheless retain the FEL contribution.

# Platform priorities

| Platform | Best route to pursue | Confidence and remaining boundary |
| --- | --- | --- |
| Linux desktop | Current engine for FEL to HDR/SDR; optional CB1-based direct-display DV output | High for architecture; moderate for the custom DV adapter; physical output requires device evidence |
| Windows | Existing gpu-next integration with upgraded engine, using D3D/Vulkan and HDR10/scRGB | High for the presentation design; native DV remains OS/OEM/driver specific |
| macOS | VideoToolbox plus Metal or libplacebo/MoltenVK; EDR output; evaluate the Apple metadata bridge separately | Moderate for local FEL; native metadata application is unqualified |
| iOS and iPadOS | Native playback for accepted sources; dual-decoder Metal experiment; EDR or companion fallback | Moderate for local composition on capable devices; thermal budget and metadata response remain device tests |
| tvOS | Aether-style dual VideoToolbox/Metal proof of concept, with separately qualified metadata handoff | Moderate; preserve audio, seeking, PiP and native-route behavior when choosing the experiment |
| Android and Google TV | Media3 native route; mixed or dual decode plus GPU composition where raw surfaces are available | Moderate and device dependent; decoder profile advertisements alone do not prove FEL |
| Fire TV | Apply the Android capability model per device; retain native accepted-profile playback and companion output | Moderate for architecture; no inherited FEL claim from the OS family |
| webOS | Use the working native media backend; qualify remuxing; add companion-reconstructed streams; investigate local surface access separately | High for the next-step choice; local full FEL remains unknown |
| Browsers | Native video when supported; compatible companion streams; WebCodecs/WebGPU experiment on selected browsers | High for the fallback design; low for broadly deployable local FEL |
| Other TVs, restricted devices and consoles | Deliver a receiver-compatible stream through an available client, or control an external renderer | Moderate in principle; deployment and supported output remain platform specific |

The Windows [DXGI metadata enum](https://learn.microsoft.com/en-us/windows/win32/api/dxgi1_5/ne-dxgi1_5-dxgi_hdr_metadata_type) exposes HDR10/HDR10+ rather than a generic arbitrary-RPU route. The newer [dovi-jellyfin experiment](https://github.com/Andy2244/dovi-jellyfin) reports P5/P8 processing through Edge and the Windows extension, with HDR10 output and FEL ignored. It is a compatibility lead, not a replacement FEL decoder. EDID overrides alone do not create missing decoding or transport capabilities.

On Android, follow the documented [HDR surface guidance](https://developer.android.com/media/grow/hdr-playback): native HDR playback should use an appropriate SurfaceView route; a TextureView path can convert to SDR. Measure raw P010 access and sustained concurrent decode separately. Media3 [1.12.0-alpha01, 21 October](https://developer.android.com/jetpack/androidx/releases/media3#1.12.0-alpha01) adds P20 configuration parsing and unsupported-profile rejection; parsing is not a new hardware decoder.

On webOS, the [rooted C5 demuxer patch](https://github.com/josippapez/dts_restore_plus/blob/main/webos25/README.md) explicitly provides BL+RPU playback and omits the FEL residual. Its firmware-specific results cannot be transferred to the C6. LG’s older [container guidance](https://forum.webostv.developer.lge.com/t/dolby-vision-video-playback-via-media-player-app/1358) makes correct MP4/TS signaling worth testing. Also test audio during DV playback: [LG acknowledged a webOS 26 HLS multichannel regression](https://forum.webostv.developer.lge.com/t/stereo-only-for-dolby-vision-video-with-multi-channel-audio-in-hls-streams/23069/36) and planned a fix; current C6 firmware behavior must be measured.

Browser research can combine demuxed RPU, two WebCodecs decoders and a WebGPU composer. [WebGPU HDR canvas](https://developer.chrome.com/blog/new-in-webgpu-129) supplies an HDR presentation primitive. It does not establish HEVC availability, untouched 10-bit residual access, or Dolby wire output. Avoid committing to this before the same composition contract passes on native backends.

# Automatic compatibility fallback

**Recommendation confidence: high.** Auto should choose the best verified route that meets the current playback budget. Use a companion result when it is available or can keep up; avoid making ordinary playback wait indefinitely for an offline bake. Preserve a fidelity preference for users willing to wait. Switching routes must flush frame and metadata state and preserve audio/subtitle timing.

| Route | What the user receives |
| --- | --- |
| Qualified native full reconstruction | Both layers and native display processing, within the qualified device contract |
| Local reconstructed FEL | Enhancement contribution retained; output may be native DV or mapped HDR/SDR |
| Companion reconstructed version | Enhancement contribution retained before re-encoding; output precision and metadata depend on the target |
| P7 to P8.1 compatibility | Base layer plus converted dynamic metadata; FEL residual discarded |
| Compatible base layer | HDR10, HLG or SDR where the source actually defines that fallback |
| Correct software conversion | A viewable HDR/SDR image when direct native interpretation is unavailable |

Show source format, layers used, output format and fallback reason in playback details. A missing or invalid enhancement frame should trigger a clearly recorded downgrade or recovery, not a false full-FEL result. P5 and other Dolby-only compatibility variants need actual color interpretation/conversion; dropping metadata is not a correct generic fallback.

# Coverage beyond Profile 7

Use the [Dolby profile specification](https://ott.dolby.com/OnDelKits/Dolby_Vision_Online_Delivery_Kit/v1/Documentation/Specs/Visio_Profiles/help_files/topics/c_dovi_profiles.html) to separate HEVC P5/P7/P8, AVC P9, AV1 P10 and HEVC/MV-HEVC P20. Include compatibility IDs and limited metadata compression in capability records. P20 stereo views are not the same concept as a P7 enhancement layer. Give legacy formats individual fixtures rather than a universal flag.

Apple’s current [HLS authoring specification](https://developer.apple.com/streaming/hls-authoring-specification-for-apple-devices.html) includes platform amendments and supplemental codec signaling for backward-compatible DV variants. Use those rules when preparing streams; an older statement that Apple accepts only P5 is too broad. Device-specific support still needs probing.

Keep [Dolby Vision 2](https://www.dolby.com/technologies/dolby-vision-2/) and IQ behavior separate from file decoding. Sink-side ambient-light, motion and display-engine behavior is not obtained merely by reconstructing FEL. Preserve understood metadata on native routes and identify unsupported extensions explicitly.

# Experiments and completion evidence

| Priority | Experiment | Evidence needed to choose the next step |
| --- | --- | --- |
| 1 | Finish the current real-FEL engine path | Decoded-layer identity, synchronized composition, independent numerical comparison and actual presented output |
| 2 | Compare MDK on the same clips and devices | Reconstructed pixel differences, frame timing, power, and the cost of preserving existing PlezyNG features |
| 3 | Apple Metal plus native/EDR output | Residual-only and metadata-only controls; test tvOS separately from iOS/iPadOS/macOS; retain OS-specific results |
| 4 | Companion HDR10/SDR optimized version | FEL contribution survives reconstruction and encoding; seekable playback on C6, Apple and browser clients |
| 5 | Companion single-layer DV | Correct identity mapping, target color/range and surviving trims; absence of double processing |
| 6 | Linux CB1 and Amlogic native transport | Reproducible source build, qualified driver/display chain, measured signal and recovery behavior |

Use three separate controls: hold BL/RPU fixed while changing EL; hold pixels fixed while changing metadata; and encode distinct frame identifiers in BL and EL while exercising seek/reorder. AetherEngine’s [pulse harness](https://github.com/superuser404notfound/AetherEngine/tree/e6f785a96ab68336966f8d01305d289f87b59752/Probes/DolbyVisionPulse) provides a useful starting design. Camera measurements can demonstrate a response, but colorimetric correctness requires more than a visible pulse or TV badge. Keep composed-pixel, metadata-response, HDMI and sustained-performance results separate.

Maintain one public-specification scalar reference and compare implementations with stated precision, chroma and resampling conventions. Internal CPU/GPU agreement only validates their shared contract. Add reference-device or authorized reference-tool comparisons for display mapping. Tests that skip unavailable real clips must remain visibly skipped.

# Building the missing pieces

**High-confidence investment:** own the frame-pairing contract, bounded metadata/parser integration, CPU reference, portable compositor interfaces, target presentation adapters, fallback policy and evidence database. Reuse established HEVC/AVC/AV1 decoders. Writing a new general video codec decoder would consume effort without opening the native display APIs that currently constrain coverage.

**Moderate-confidence experiments:** hardware BL with software EL when a second hardware session is unavailable; reconstructed frames re-entering a native display manager; cached companion encodes; and an external Linux/Amlogic renderer controlled by PlezyNG on a restricted client.

**Low-confidence or expensive routes:** distributing residual data from a server for client-side GPU composition; reproducing undocumented CM4 mapping; or implementing proprietary runtime compatibility. A runtime shim can only help if the required algorithm and its dependencies are actually available. Emulating an OS or changing EDID cannot by itself supply a missing physical display path. AI-generated enhancement is a separate image treatment, not recovered FEL data.

An [official Dolby implementation path](https://professional.dolby.com/licensing/) is worth evaluating alongside the open work. Ask specifically about an app/SDK route covering P7 FEL, portable reconstruction versus display management, reference vectors, platform coverage and runtime distribution. Availability and commercial terms are unknown. A color-grading/mastering license should not be assumed to provide a redistributable player SDK.

Keep experimental engines pinned, reproducible and reversible. Isolate undocumented attachments and device-specific drivers behind separately qualified adapters. Preserve a functioning stable/native compatibility route. Importing a project’s algorithm, SDK binary or firmware component each requires its own source and distribution review; a disclaimer does not make those dependencies interchangeable.
