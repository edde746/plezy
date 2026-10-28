# Research and design decisions

Sources checked 2026-10-27. Use primary documentation, author repositories/papers,
and original measurement methodology. A vendor's description establishes what it
claims or exposes, not that PlezyNG has achieved the same quality. No benchmark or
TV comparison has been run for this PR.

## 1. Primary sources

| ID | Source | Evidence and use in this plan |
| --- | --- | --- |
| R01 | [mpv stable reference manual](https://mpv.io/manual/stable/) | `interpolation`/`tscale` perform temporal filtering, only on `gpu`, `gpu-next` and `libmpv` VOs. Interpolation needs display-sync mode and may need decoder look-ahead configured before source open. `display-vdrop` can toggle thresholded interpolation around small rate differences; `-1` disables that threshold logic. |
| R02 | [FFmpeg filter documentation](https://ffmpeg.org/ffmpeg-filters.html#minterpolate) | `minterpolate` exposes motion-compensated, blend and duplicate modes, rational output FPS and scene handling. It is the current PlezyNG MCI path and a reference for the shipped motion-compensation controls. |
| R03 | [libplacebo renderer/frame queue](https://libplacebo.org/renderer/) and [options](https://libplacebo.org/options/) | Frame metadata, GPU textures, queueing, scaling/colour and temporal mixing infrastructure. Its mixing API is not proof of a motion-estimation engine. |
| R04 | [RIFE paper, ECCV 2022](https://arxiv.org/abs/2011.06294) | Learned intermediate-flow estimation supports arbitrary-timestep interpolation. Supports the proposed neural design; published benchmark results do not predict our 4K HDR playback throughput. |
| R05 | [Practical-RIFE author repository](https://github.com/hzwer/Practical-RIFE) | Lists 4.25 and lite candidates, models and inference code; explicitly assigns linked trained models the project's MIT license. Evaluate/pin exact exports and weights; model number alone is not compatibility. |
| R06 | [rife-ncnn-vulkan](https://github.com/nihui/rife-ncnn-vulkan) and [license](https://github.com/nihui/rife-ncnn-vulkan/blob/master/LICENSE) | Native ncnn/Vulkan implementation and cross-vendor desktop executables demonstrate a portable route. The image-sequence CLI is not our player integration and older graphs do not automatically accept newer models. |
| R07 | [SVP RIFE documentation](https://www.svp-team.com/docs/rife-ai/) | Runtime options and substantial example GPU requirements for 4K interpolation. Treat requirements as that implementation's estimates, not an app benchmark or a guarantee about our hardware. |
| R08 | [SVP frame-rate profiles](https://www.svp-team.com/wiki/Manual:FRC) | Separate target rate, performance selection, film/animation handling, artifact suppression and profiles. Informs control categories; do not copy settings numerically or bundle SVP components without their own terms. |
| R09 | [Samsung motion smoothing support](https://www.samsung.com/us/support/answer/ANS10006969/) | Documents Auto/Custom, blur/judder controls and LED Clear Motion; explicitly discusses soap-opera appearance. Useful UI/comparison context, not a technical definition that collapses all motion defects together. |
| R10 | [LG clarity/TruMotion guide](https://kr.eguide.lgappstv.com/manual/w24/global/Contents/settings/picture/clarity_k_u_b_e_c_a_t_j/eng/w24__settings__picture__clarity_k_u_b_e_c_a_t_j__eng.html) | Documents cinematic/natural/smooth options and manual controls. Model-specific examples for setup and fair comparisons; not proprietary algorithms to reproduce. |
| R11 | [Pixelworks/TrueCut motion-grading white paper](https://truecutmotion.com/wp-content/uploads/2024/02/3-TrueCut_Motion_WhitePaper.pdf) | Describes separately controlling motion appearance/blur in authored workflows. Supports treating appearance as an independent axis; does not establish an available runtime library or prove automatic film-intent recovery. |
| R12 | [Android frame-rate API](https://developer.android.com/media/optimize/performance/frame-rate) | Apps request cadence; the OS can decline. Exact rate values and presentation timestamps matter. Probe observed output and retain graceful fallback. |
| R13 | [Apple AVSampleBufferDisplayLayer](https://developer.apple.com/documentation/avfoundation/avsamplebufferdisplaylayer), [HDR with Dolby Vision](https://developer.apple.com/av-foundation/Incorporating-HDR-video-with-Dolby-Vision-into-your-apps.pdf), [Metal HDR](https://developer.apple.com/documentation/metal/hdr-content) | Sample-buffer presentation, colour/metadata requirements and HDR GPU rendering are separate contracts. Does not promise that edited frames retain original DV semantics. |
| R14 | [webOS 26 audio/video specifications](https://webostv.developer.lge.com/develop/specifications/video-audio-260) | Codec/resolution/frame-rate limits are device/runtime-specific. Advertised panel/HDMI capabilities are not third-party decoded-frame APIs. |
| R15 | [NAFNet author repository](https://github.com/megvii-research/NAFNet), [GoPro model documentation](https://github.com/megvii-research/NAFNet/blob/main/docs/GoPro.md), [license](https://github.com/megvii-research/NAFNet/blob/main/LICENSE) | Image deblurring model candidate and evaluation/export starting point. Single-image quality does not establish temporal consistency, real-time video or HDR suitability; inherited component notices remain relevant. |
| R16 | [OpenCV NAFNet model/demo](https://github.com/opencv/opencv_zoo/tree/main/models/deblurring_nafnet) | Documents a native/demo/export route and directory licensing. Use as conversion/reference evidence; verify exact graph/weights before packaging and do not depend on a demo's “latest” libraries in production. |
| R17 | [VIDUE CVPR 2023 paper](https://openaccess.thecvf.com/content/CVPR2023/papers/Shang_Joint_Video_Multi-Frame_Interpolation_and_Deblurring_Under_Unknown_Exposure_Time_CVPR_2023_paper.pdf) and [author implementation](https://github.com/shangwei5/VIDUE) | Joint deblurring/interpolation with unknown exposure is a relevant offline comparison. Its demonstrated multi-frame reconstruction is not proof of arbitrary-rate, HDR or real-time player support. |
| R18 | [Blurry Video Frame Interpolation, CVPR 2020](https://openaccess.thecvf.com/content_CVPR_2020/html/Shen_Blurry_Video_Frame_Interpolation_CVPR_2020_paper.html) | Research explicitly distinguishes frame interpolation and source deblurring; supports separate qualification instead of assuming more frames remove captured blur. |
| R19 | [RTINGS original stutter test methodology](https://www.rtings.com/tv/tests/motion/stutter) | Original high-speed measurements and discussion of frame hold, judder and interpolation. Use the measurement distinction, not product rankings as proof of our results. |
| R20 | [AMD FidelityFX frame interpolation documentation](https://gpuopen.com/manuals/fidelityfx_sdk/techniques/frame-interpolation/) | Game-oriented interpolation uses additional resources such as depth/motion data. An encoded movie is not automatically compatible with that integration contract. |
| R21 | [SVPlayer product/manual page](https://www.svp-team.com/wiki/SVPlayer) | A mobile player integrates SVP motion estimation/compensation, target rates and flexible controls; it also documents substantial CPU and battery demands and optional desktop offload. |
| R22 | [madVR Envy MotionAI user guide](https://madvrenvy.com/wp-content/uploads/madVR-Envy-MotionAI-User-Guide.pdf) | Describes output-rate selection, model/strength/blur profiles and instant/split-screen comparisons, and says evaluators should disable TV interpolation. This dedicated processor is not a reusable app SDK. |
| R23 | [Kodi video settings](https://kodi.wiki/view/Settings/Player/Videos) | Separates display-rate matching from playback-to-display sync and notes the audio-passthrough tradeoff. This is cadence correction, not motion-compensated frame creation. |
| R24 | [Android frame-rate guide](https://developer.android.com/media/optimize/performance/frame-rate) and [Surface.setFrameRate](https://developer.android.com/reference/android/view/Surface#setFrameRate(float,int,int)) | The app communicates intended source cadence; Android arbitrates display mode. The API does not make an app produce interpolated frames or guarantee a mode change. |
| R25 | [Apple AVDisplayManager guide](https://developer.apple.com/videos/play/tech-talks/503/) and [AVDisplayCriteria](https://developer.apple.com/documentation/avfoundation/avdisplaycriteria) | tvOS display matching is a system-mode negotiation with user-setting and display-capability gates; it does not add intermediate motion samples. |
| R26 | [FFmpeg `vf_minterpolate.c`](https://github.com/FFmpeg/FFmpeg/blob/master/libavfilter/vf_minterpolate.c) | The implementation defines duplicate, blend and motion-compensated modes; output rate, motion-estimation method, block mode, variable-block refinement and scene-change sensitivity are configurable. PlezyNG uses this implementation for its current FFmpeg motion-compensated path. |
| R27 | [mpv video filters manual](https://mpv.io/manual/master/#video-filters) | mpv video filters can use the `lavfi` bridge, carry runtime labels, and be added or removed dynamically. The manual warns the bridge may not validate parameters until use, so activation must be fallible and retain a fallback. |

## 2. Reference implementation comparison

| Approach | What it does well | What it cannot establish |
| --- | --- | --- |
| mpv temporal blend (implemented engine) | Display-synchronous temporal convolution; tunable kernels and threshold; compact renderer path. | It does not estimate object motion, generate correct occlusion boundaries or restore exposure detail. Kernel choice trades blending against softness or ringing. |
| FFmpeg `minterpolate` (implemented path) | Block-based motion estimation and compensation; selectable output rate and search effort; scene-change detection; runtime filter removal and temporal-blend fallback. | CPU and pixel-format conversion costs can dominate; occlusions and cuts can warp or ghost; no PlezyNG build or TV is qualified. It is not neural RIFE or a proprietary TV model. |
| SVP / SVPlayer | Motion-vector search and motion-compensated synthesis; target-rate and interpolation-ratio choices; adaptive per-frame modes based on vector confidence; masking and explicit scene-change handling. SVPlayer brings this to Android/iOS and documents desktop offload. | CPU/GPU load, power use and artifacts rise with stronger motion search and more generated frames. Vendor requirements are SVP estimates, not PlezyNG benchmarks or universal thresholds. |
| RIFE through SVP | Learned intermediate-flow synthesis with selectable model/backend/device, scene-change threshold and model/performance tradeoffs. | SVP documents high real-time GPU demands at 1080p/4K. An offline or desktop result does not prove sustained mobile/TV playback. |
| madVR Envy MotionAI | Dedicated GPU processor exposes output-rate, model, strength and blur profiles, quick/split-screen A/B comparison, and fast profile switching. Its guide treats film appearance as a separate user choice. | It is a proprietary external processor; its vendor claims are not independent proof. Its configuration does not give PlezyNG decoded-frame access or panel scanout. |
| Kodi and platform refresh matching | Requests source-compatible display cadence and provides playback/display sync choices. This removes avoidable pulldown judder on compatible displays without synthesizing object motion. | The OS can decline mode requests; matched cadence does not add unique motion positions. Audio passthrough can limit sync correction. |

### PlezyNG coverage and gaps

| Capability | Current PR coverage | Next engineering step |
| --- | --- | --- |
| Native-rate display matching | Temporal blend keeps existing behavior. Android mpv MCI suppresses source-rate matching and requests its selected generated cadence at first frame; resolution matching remains available. Other routes do not yet share a generated-rate coordinator. | Unify rational output-rate negotiation across Android, Windows, Apple and external displays while honoring HDR, resolution, user choice and panel capability. |
| Low-cost cadence blending | Implemented with mpv display sync, temporal interpolation, selectable kernels and threshold. Spatial shaders remain independent. Custom kernel/threshold share the profile's global/library/title scope, resolved before each media source opens so the decoder can prepare its surface pool. | Measure actual output cadence, drops, audio drift and per-device costs; add a safe mode fallback. |
| In-player comparison | Quick A/B switch temporarily bypasses the active motion filter and leaves display sync, scaling and audio configuration active. | Add split-screen comparison only if the renderer can preserve the same source time and color pipeline on both sides. |
| Motion-compensated synthesis | FFmpeg `minterpolate` on mpv's labelled `lavfi` video-filter path; selectable output FPS/search effort; filter activation fallback. | Validate every shipped mpv/FFmpeg artifact and frame format; measure deadlines and A/V sync; then build the native bounded queue, scene/cut/occlusion handling, classical engine and optional licensed neural engine. |
| Restraint and artifact policy | Temporal profiles map to kernels. In MCI mode, generated rate controls motion strength and search effort controls processing cost. The current controls use discrete targets; confidence-aware, scene-specific motion-strength adjustment is a future enhancement. | Add confidence-aware strength and generated-frame-ratio controls, scene/cut/occlusion analysis, and animation/film/fast-action policies. |
| Hardware adaptation | Renderer route is checked; decoder look-ahead is bounded; displayed rate is labeled renderer-reported; a runtime guard responds to late-vsync and dropped-frame counters. | Probe sustained GPU/decoder/memory/battery headroom, count generated frames and deadlines, and reduce processing before playback deadlines are missed. |
| Blur and scaling | Existing spatial shader controls stay independent. No deblur or BFI is implemented. | Evaluate restoration as a separate experimental SDR path and qualify it with interpolation, scaler and color stages. Software BFI remains panel/output-specific and limited by brightness/flicker. |

## 3. Decisions and rejected shortcuts

| Option | Decision | Reason / confidence |
| --- | --- | --- |
| Correct pacing/refresh/IVTC first | Required on all eligible backends | Removes avoidable uneven timing before expensive reconstruction; high |
| Classical motion-compensated reconstruction | Required efficiency/reference engine | Broad native implementation path and explicit uncertainty; moderate in quality/performance until tested |
| RIFE-family native inference | Selected primary neural candidate | Practical models, arbitrary-time research and existing portable implementation; moderate |
| NAFNet source deblur | Implement experimental SDR adapter and quality gate | Concrete available model; temporal/HDR behavior needs additional engineering; moderate for limited SDR, unknown for general film |
| VIDUE joint method | Offline comparison with a specified promotion gate | Could avoid cascading restoration/interpolation errors, but production cost/contracts are unproven; low for near-term default |
| Cinema timing curve / lower distinct cadence | Controlled experiment with film-look gate | Makes smoothness semantics explicit without pixel crossfades; perceived improvement unknown |
| Sharpening branded as deblur | Reject | Edge contrast does not recover exposure detail; high |
| Repeating frames branded as 120 fps reconstruction | Reject | Does not create extra motion positions; high |
| mpv interpolation flag alone | Keep as a low-cost cadence fallback; reject it as the motion-compensated implementation | Temporal mixing is not motion reconstruction; high |
| Per-object independent time warping as default | Reject initially | Risks broken occlusions/contact and inconsistent temporal appearance; moderate |
| Full AI restoration in every preset | Reject | Changes grain/detail and risks hallucination/flicker/colour damage; moderate |
| FSR/DLSS game frame generation dropped into movie playback | Reject as a shortcut | Movies lack the expected engine buffers/contracts; a separate adaptation would need qualification; high |
| Event-camera reconstruction papers as movie solution | Reject for this media input | Ordinary encoded films do not contain the additional sensor event data; high |
| Software black frames as a universal blur fix | Exclude from release presets | App cannot generally control scanout emission; sacrifices output samples/brightness and may flicker; high |
| Precomputed/companion stream | Optional constrained-device route | Useful when local compute/frame access is unavailable, but introduces encode/storage/latency and cannot bypass output caps; high in concept |
| “No soap opera effect” from better AI alone | Reject as a guarantee | Temporal appearance itself changes even with perfect reconstruction; high |

## 4. Novelty and success criteria

Frame interpolation, deblurring, adaptive quality and motion grading all have
prior implementations. This plan does not claim a new invention, patent novelty,
or compatibility with a proprietary motion-grading format. Its opportunity is a
well-integrated, cross-platform, colour-correct, measurable player experience with
better tuned tradeoffs and accurate capability handling.

The proposed restrained curve is our implementation hypothesis. Its mathematical
properties can be tested before playback; its perceptual value cannot be inferred
from those properties. It must compete with simpler alternatives in the same study.
Likewise, model selection is based on held-out motion/artifact/colour/performance
results, not labels such as AI, latest, flagship or ultra.

## 5. Evidence not obtained during planning

No physical TV comparison, GPU inference benchmark, restored-video quality test,
native SDK decoded-frame probe, model download/hash verification, packaged build,
or native-DV-generated-frame validation was performed. The implementation packages
specify exactly where these occur. Their current confidence remains unknown; the
code/source inspection and documented API distinctions are the planning evidence.
