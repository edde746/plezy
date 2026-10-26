# Dolby Vision engine handoff to Luna

Prepared 2026-10-25/26. Continue on `codex/dv-experimental-engine` in
[`snapetech-org/PlezyNG`](https://github.com/snapetech-org/PlezyNG).
The user requested this handoff to reduce token use. Read this file first; reuse
the source audit and inspect the named files before doing more broad research.

## User-authorized goal

Build bleeding-edge Dolby Vision support, including genuine Profile 7 FEL:
decode **both** base and enhancement layers, apply the FEL residual, preserve
metadata, then present through the best verified platform output. Building missing
integration ourselves and maintaining isolated experimental builds are explicitly
authorized. P7-to-P8.1 conversion that discards EL remains a separate compatibility
option. Cover Linux, Windows, Apple including iOS/tvOS, Android, and webOS wherever
technically possible. Do not equate decoding, reconstruction, HDR presentation,
native DV signaling or Dolby-reference display mapping.

The current deliverable is an isolated engine and app integration experiment,
not a finished universal decoder. Continue testing and buildout autonomously.
Use the GitHub connector for repository changes; no login or credential requests
are needed. Do not merge or ship an unqualified engine as the production default.

## Exact checkpoint

- Branch base: `502ac651da234e024970a6908a3f8988e7845e7c` (newer `main` changes
  were preserved, including Apple CI result-bundle diagnostics and changelog).
- Experimental work is in draft PR [#16](https://github.com/snapetech-org/PlezyNG/pull/16)
  on `codex/dv-experimental-engine`. Keep it draft and separate from production.
- First build: [Actions run 40269374234](https://github.com/snapetech-org/PlezyNG/actions/runs/40269374234),
  job `121398660530`, completed **failure**. Source fetch, FFmpeg/libplacebo/mpv
  compilation, feature probe and GLES `opengl-next` red-frame decode/render/readback
  all passed. 14/16 mpv tests passed. The two failures both loaded mpv's PNG fixture;
  the build had omitted the PNG decoder. The script stopped before libplacebo's
  test suite and artifact packaging. Logs: [job logs](https://github.com/snapetech-org/PlezyNG/actions/runs/40269374234).
- Commit `f6624522f29f7cc3a306031a3393a8e6a2d75d75` added the Linux app selector,
  lab, synthetic FEL vectors and compositor failure patch with `[skip ci]` to
  preserve the first run. **That failed run did not test those later additions.**
- Second engine run: [Actions run 40270407661](https://github.com/snapetech-org/PlezyNG/actions/runs/40270407661),
  job `121401804394`, completed **failure**. FFmpeg, libplacebo and mpv built;
  feature probe and GLES `opengl-next` red-frame readback passed. Six synthetic
  LINEAR_DZ vectors matched their independent expected pixels with zero reported
  error; every nonzero residual changed pixels. Invalid EL texture injection was
  rejected. mpv tests were 14/16: both failures need PNG, which FFmpeg disabled
  because `inflate_wrapper` lacked zlib under `--disable-autodetect`. All 16
  runnable libplacebo tests passed; one surfaceless test was skipped. No artifact
  was packaged.
- Follow-on local edits now add `zlib1g-dev` and `--enable-zlib`, reject FEL metadata
  without an EL frame pointer, and apply a pinned-source mpv patch that fails closed
  on missing/invalid EL, decoder setup errors, unknown/unmatched PTS, and GPU import
  errors. These edits **have not yet gone through the pinned mpv build**. Run the
  workflow on the updated tree and inspect the compile and tests before claiming
  the integration works.
- The general PR checks in [Actions run 40270533737](https://github.com/snapetech-org/PlezyNG/actions/runs/40270533737)
  are separate from the engine build; at last inspection, they were still running.
- Local checks currently pass: Python byte-compilation, 13 DV-lab tests, and the
  C++ selector test under ASan/UBSan (`detect_leaks=0` because this host blocks
  LeakSanitizer process inspection).
- No real P7 FEL sample, physical GPU/Wayland run, native DV output test, merge,
  release, system driver change, or device test has occurred. Production
  `mpv-build.lock.json` remains unchanged.

## What is written

| Files | Purpose / status |
| --- | --- |
| `tools/dv-engine/engine.lock.json` | Exact experimental sources and explicit unqualified capability labels. |
| `tools/dv-engine/Dockerfile`, `build_linux.py` | Isolated native Linux build of FFmpeg, libplacebo, standalone mpv and libmpv. OpenGL first; no Vulkan/D3D11 in this recipe. Writes source archives, provenance, checksums and feature report. Apt versions are recorded, not frozen. |
| `.github/workflows/dv-experimental.yml` | Read-only, SHA-pinned Actions; Ubuntu 24.04 x86_64 Docker build; artifacts retained 14 days. Runs on changes under `tools/dv-engine/**` on `codex/dv-experimental-*`, or manual dispatch. |
| `engine_features.c` | Compile/runtime checks for `dovi_split`, DV stream groups, enhancement-frame/NLQ interfaces and `opengl-next`. These are feature checks, not playback proof. |
| `render_smoke.c` | Writes a red PPM, decodes through libmpv, renders through `opengl-next` into an ES FBO, reads pixels back. Uses surfaceless software Mesa in CI. **Compiled and passed in engine run 40270407661.** |
| `fel_smoke.c` | Six explicit synthetic LINEAR_DZ residual vectors: zero, signs, threshold and clamping, with a half-size EL. The six vectors passed in run 40270407661. A new active-FEL-with-no-frame-pointer fault check was added afterward and still needs CI. None of these tests decode HEVC or establish all composer math. |
| `patches/libplacebo-reject-failed-fel.patch` | Rejects active FEL metadata without an EL pointer and EL sampling failures. The latter was compiled and invalid-texture fault-tested in run 40270407661; the missing-pointer guard was added afterward and still needs CI. |
| `patches/apply_mpv_fel_failclosed.py` | Exact-commit-guarded patcher for mpv pairing, required EL stream state, metadata checks, and fail-closed output on decoder, PTS, or GPU import errors. **Added after the last engine run; compilation is the next gate.** |
| `run.py` | Process-scoped engine selection; standalone tools or a matching PlezyNG app. App mode preloads the selected libmpv and requests `opengl-next`. No production engine files are overwritten. |
| `linux/runner/mpv/experimental_render_api.h`, `_test.cc` | Strict opt-in API selector. Unset/`opengl` keeps legacy; only `opengl-next` selects RFC backend; invalid values fail. Test passes. |
| `linux/runner/mpv/mpv_player.cc` | Uses selector on existing Wayland/EGL video plane, logs chosen API, fails if experimental API is unavailable. Full app build/runtime still pending. |
| `linux/runner/CMakeLists.txt`, `.github/workflows/ci.yml` | Register and build selector test in existing native reliability CI. |
| `scripts/dv_lab.py`, `scripts/test_dv_lab.py` | Bounded local ffprobe inspection and optional standalone trial. Correct profile-dependent fallback labels; EL-present is explicitly **MEL/FEL unclassified**. Never infers FEL success from process exit. 13 tests pass. |
| `docs/plezyng/dolby-vision-research{,-snapshot.json}` | Broader audited sources, platform strategy and acceptance matrix. |

## Verified source facts — do not rediscover them

Production engine: `edde746/mpv-build@582f6d6e748a87a1536bf5cdad0af97b75725ffb`;
mpv 0.41.0, FFmpeg 8.0.1, Linux libplacebo 7.360.1. Those pins predate the FEL work.
Its Linux FFmpeg BSF allowlist also omits `dovi_split`, and it builds libmpv without
the standalone CLI. Simply replacing one library or setting `vo=gpu-next` in app
config cannot fix the legacy embedded renderer.

Experimental pins:

| Component | Repository / commit |
| --- | --- |
| FFmpeg | `FFmpeg/FFmpeg@46f23be8b1976ed4c8ec85584daabcf0e57a7b9e` |
| libplacebo | `haasn/libplacebo@275f7dea27924cdd34ab2e6c20e448b6bc4fab65` (API 387) |
| mpv + embedding RFC | `kakulukia/mpv@16563d120f3260cdc0beb1b07f199818fc32dd8c` |

- [mpv #17932](https://github.com/mpv-player/mpv/pull/17932) merged FEL support
  July 1, 2026 at `99b4c12cccb4d8d3f72b41944cb6c640e2156650`. The chosen embedding
  fork was verified to contain that merge (ahead 309, behind 0).
- [mpv #18607](https://github.com/mpv-player/mpv/pull/18607) is an **open RFC**,
  not a stable released API. It exposes `MPV_RENDER_API_TYPE_OPENGL_NEXT`, string
  `opengl-next`, through the existing GL init/FBO/depth render parameters.
  Public headers are under **`include/mpv/`**, not `libmpv/`. Linux/Windows had
  no demonstrated runtime results in the inspected PR; author reported macOS.
- [#16818](https://github.com/mpv-player/mpv/pull/16818) remains draft;
  [#18343](https://github.com/mpv-player/mpv/issues/18343) is a closed Vulkan
  embedding proposal, not a released callable interface.
- FFmpeg has `libavcodec/bsf/dovi_split.c` and
  `AV_STREAM_GROUP_PARAMS_DOLBY_VISION`. libplacebo has
  `pl_frame.enhancement_layer`, `pl_dovi_metadata.nlq_active/nlq`.
- **API 387 changed pivot/NLQ units** and added `hdr_in_max`. In the current API,
  EL offset is in integer codes; BL reshape input is code / 2^bit_depth. Inspect
  `colorspace.h`, `pl_color_repr_code_scale`, `sample_el` and
  `pl_shader_decode_color_ex` when diagnosing synthetic-vector failures.
- Current mpv Vulkan builds require headers >=1.4.309; Ubuntu 24.04 distro
  headers alone do not satisfy that. Initial GL recipe deliberately avoids this.
- libplacebo `dovi=enabled` with `libdovi=disabled` supports FFmpeg-parsed metadata
  and reshaping; raw RPU parsing via libdovi is a separate feature.
- [ETSI GS CCM 001](https://www.etsi.org/deliver/etsi_gs/CCM/001_099/001/01.01.01_60/gs_ccm001v010101p.pdf)
  publicly describes composer polynomial/MMR, NLQ and filtering. This can support
  an independent numerical reference; do not invent proprietary CM4 equivalence.

## Do next, in order

1. Build the updated branch with the zlib and fail-closed patches. The pinned
   source fetch and earlier engine components compiled, but the new mpv patcher
   has not yet been compiled. Rerunning either old engine run rebuilds old source.
2. Validate source fetching, both patch applications, FFmpeg BSF availability,
   library linking, runtime loader paths, ES context creation and both upstream
   test suites. The zlib change specifically targets the two PNG fixture failures.
3. Never relax a failed pixel assertion merely to make CI green. Check input
   normalization, matrix metadata, target inference and precision first.
4. Inspect the mpv patch's compiled pairing and output paths. Keep unknown PTS,
   missing EL, invalid metadata, decoder setup failure and GPU import failure
   fail-closed. Add focused filter-level tests if the pinned build supports a
   maintainable harness.
5. Add a real, provenance-recorded P7 FEL sample test. Verify both layers decode,
   pair by timestamp/epoch and reach composition. Compare reconstructed pixels
   with a trusted reference and BL-only output. No such sample was available in
   this workspace. Synthetic vectors are not a substitute for this step.
6. Format native files with the repository toolchain and run the normal Flutter,
   Linux native/sanitizer and workflow checks. Keep PR #16 in draft while the
   sample and device gates remain open. Identify AI assistance as OpenAI Codex
   (GPT-6 Luna). `CONTRIBUTING.md` requires checks to pass before merge.
7. Test embedded playback on real Wayland/GPU hardware: FBO precision, PQ/HLG and
   range, tone-map ownership, zero-copy imports, resize/seek/flush, subtitles,
   audio sync, suspend/output changes and teardown. The launcher requires this
   branch's app selector and no already-running normal app instance.
8. Rebase the production mpv-build patches individually before treating the new
   engine as a normal replacement. TLS/HTTP, subtitles, audio, decoder fallback,
   Apple output and Android timing patches have **not** been ported here.
9. Expand adapters in the platform order below. Keep native DV signaling separate
   from FEL reconstructed to HDR10/EDR/SDR. Expose actual layers used and fallback
   reasons; never let a DV badge or advertised profile certify FEL.

Build/launch commands are in [`../../tools/dv-engine/README.md`](../../tools/dv-engine/README.md).
Focused checks:

```bash
python3 scripts/test_dv_lab.py
python3 -m py_compile tools/dv-engine/*.py
g++ -std=c++14 -Wall -Wextra -Werror -fsanitize=address,undefined \
  linux/runner/mpv/experimental_render_api_test.cc -o /tmp/plezyng-render-api-test
ASAN_OPTIONS=detect_leaks=0 /tmp/plezyng-render-api-test
```

Those checks passed locally. LeakSanitizer had to be disabled because this host
rejects its process inspection; ASan/UBSan selector execution passed. No full
native app, Flutter or engine test pass is claimed. `clang-format` was unavailable.

## Platform buildout

| Platform | Concrete route | Current confidence / boundary |
| --- | --- | --- |
| Linux | Current experiment: FFmpeg dual decode → libplacebo FEL → embedded gpu-next. Later separate native DV HDMI adapter. | High confidence in upstream source support; runtime/device qualification pending. |
| Windows | Existing child-HWND `gpu-next` makes engine replacement comparatively direct. Build D3D11/Vulkan versions and test paired hardware surfaces. Preserve black-floor and Adreno workarounds. | High feasibility for reconstructed HDR; native DV output unverified. |
| iOS/iPadOS/tvOS/macOS | Keep supported native VideoToolbox/AVFoundation paths. For FEL, dual HEVC decode into accessible CVPixelBuffers, GPU reconstruction and Metal/EDR or verified native output adapter. | Moderate feasibility; simultaneous decode surfaces, precision, thermals, PiP and output need proof. Do not promise P7 FEL from existing conversion. |
| Android/Google TV/Fire TV | Qualify actual native FEL devices; otherwise paired MediaCodec/FFmpeg frames into the GPU composer where raw surfaces are accessible. | Moderate feasibility; hardware dual decode/interop varies. `DoviConvertingTrackOutput.kt` currently converts RPU and drops EL NAL type 63. Preserve as explicit compatibility. |
| webOS | Two tracks: SDK-based app port and a separate rooted native media/composer experiment. Investigate actual raw BL/EL surface access before assuming a hardware compositor can be replaced. | Unknown local FEL viability; native decoding exists but surface/export/control access is unproven. Root access alone does not supply missing hardware capabilities. |

**webOS specifics already in this repository:** read
[`webos-tv.md`](webos-tv.md). The intended device is a rooted LG C6
OLED77C6HUP, webOS 26, firmware 43.21.79; prior QA recorded transport access, but
this session did not contact it. No PlezyNG target or IPK exists. LG's last audited
SDK is Flutter 3.38.10/Dart 3.10.9 versus app >=3.47/>=3.12. An isolated compatible
app dependency graph is possible; changing version strings does not rebuild the
webOS engine. Do not require a complete Flutter port before testing the media core.

LG publishes [Flutter plugins](https://github.com/lg-flutter-webos/plugins),
including native video playback. Source inspected at
`3a742bb86b04e261044f0864f9b1f71acf0bbad3`, especially
`packages/video_player_drm/webos/webos_player.h`: URI-driven playback/controls,
not a demonstrated raw-frame/FEL API; per-stream HTTP headers are still an app
integration issue. [chiaki-lg](https://github.com/TacticalBill/chiaki-lg) is a
native research lead: it feeds NDL hardware decode on a separate video plane with
GL overlays. That is not proof that shaders can read decoded NDL frames. The
guessed repository `openlgtv/ss4s` returned 404; follow chiaki's actual dependency
URLs rather than repeating that lookup. Reuse the existing rooted Dev Manager
profile for eventual authorized testing; keep addresses/keys out of source/CI,
and follow the existing instruction not to enable Developer Mode on that TV.

**Linux native DV HDMI follow-up:**
[`CroqueMr/libreelec-x86-DV`](https://github.com/CroqueMr/libreelec-x86-DV) at
`5e63e16df862bc3acb658f42a3c2bbb5154880e0` contains CB1, patched DRM/Kodi/LibreELEC
and reports P5/P7 MEL/FEL/P8/P10 TV-led output. Read `CB1/docs/API.md`,
`CM4-QUALIFICATION.md`, `MASTER-REFERENCE.md`, and `docs/cb1/HARDWARE.md`.
This is a concrete adapter research source, **not** ordinary Wayland HDR or a
verified PlezyNG result. API is in-process C; caller owns GPU context, frame
leases, epoch/timestamp/generation and output. CM4 mapping has explicit limits.
Do not automatically install custom kernels/drivers or claim universal HDMI DV.

Keep progress reports short and evidence-based. State what compiled, what pixels
were checked, and what device/output remains untested. The user's priority is
working full-FEL support, not another test harness presented as completion.
