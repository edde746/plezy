# Risks and technical gates

Audit date: 2026-09-28. Decision: **CONDITIONAL GO** for an API19/ARMv7 Plezy fork. No Android APK was built or run in this audit. The user has already proved that the GKUI USB installer accepts a conventional old ARMv7 Plex APK; do not repeat that generic feasibility question.

The first implementation result must be a small signed shell, not a completed application. The three largest risks are **vendor Flutter/decoder execution**, **secure networking across separate transports**, and **Plex conversion/timebase correctness within low memory**.

Confidence below refers to the available evidence, not a probability of success. **UNKNOWN** means an unperformed build/device/server experiment. A gate failure should stop dependent feature work, not erase already useful Plezy code or automatically trigger a native rewrite.

## Evidence already collected

| Check | Result | What it does not prove |
| --- | --- | --- |
| Historical base comparison | All eight required tags inspected;1.8.1 is last pre-custom-native-player release;1.9 Android explicitly min26 | 1.8.1's original dependencies run on API19 |
| Flutter source + local runtime |3.19.6/Dart3.3.4 verified; official removal starts3.22; old Flutter Android minimum19 | GKUI GPU/vendor ROM compatibility |
| Dart parser |145 unchanged base Dart files parse on3.3.4 | Framework/plugin APIs type-check |
| Pub resolution |146 packages resolve with historical pins; two transitive incompatibilities reproduced and avoided | Android assembly, native loading or security certification |
| Analyzer |Concrete old-framework and fork-player API errors identified | All errors already fixed; they are not |
| mpv binary inspection |Public v1.1.7 ARMv7 ELF files target21; old/fork payloads unavailable | Every historical mpv build is impossible on19 |
| Public network probe |Host OpenSSL validated TLS1.2 to plex.tv and clients.plex.tv, with different issuer chains | GKUI roots/clock or native media TLS validates; PIN/resources/PMS were not authenticated |
| Physical observations from user |Old official Plex installs/launches; modern Plex/Plezy parsing fails; old Plex cannot contact plex.tv | Exact causes of parse or connection failures |

Source references and artifact hashes are in [PORTING_PLAN.md](PORTING_PLAN.md), [DEPENDENCY_MATRIX.md](DEPENDENCY_MATRIX.md) and [BACKPORT_CANDIDATES.md](BACKPORT_CANDIDATES.md).

## Gate A — Can the Flutter engine execute on GKUI?

- **Evidence/confidence:** High confidence in declared API19 support for stable3.19.6; actual GKUI renderer/engine startup **UNKNOWN**. Flutter3.22's API19 removal is documented; keep engine/framework paired.
- **Smallest experiment:** M0 Flutter-only GKUI entry point with adapted Plezy monochrome theme, landscape poster placeholders, navigation and on-screen build/Android/ABI/memory/clock diagnostics. No player, networking or desktop plugins. USB-install a release ARMv7 standalone APK with v1 signing.
- **Pass:** Installs, launches from ordinary launcher, displays text/images and accepts touch; cold relaunch and sleep/wake work without persistent black screen/crash. Record version/SHA and a photo of diagnostics. Do not require ADB.
- **Fallback:** Verify package/signature first (Gate I); then compare minimal stock3.19.6 shell with adapted theme. Test reduced animation and renderer configuration only when supported by the pinned SDK; a temporary software-rendering diagnostic can distinguish GPU initialization failure but is not a video-performance solution. An older supported Flutter engine is a bounded comparison only if3.19.6 has a concrete vendor regression.
- **Stop condition:** Reproducible minimal-engine crash after package issues and configuration alternatives are ruled out. Record exact artifact, visible symptoms and attempted workarounds. Request direction before abandoning Flutter; Plex services/models could still be retained as protocol reference, but a native UI would be a material scope change.

## Gate B — Can the Plezy source compile with Dart3.3.4/Flutter3.19.6?

- **Evidence/confidence:** Medium-high. Base syntax parses; source analysis identifies bounded framework API substitutions, absent desktop integrations and media-kit fork APIs. No essential unbackportable language feature demonstrated.
- **Experiment:** Compile only the M0 entry point, then progressively include theme/auth/browsing. Replace withValues, modern ColorScheme/state/theme APIs, RadioGroup, menuPadding and PopScope callback. Isolate desktop/OS control imports. Keep generated models/translations until matched codegen is needed.
- **Pass:** Scoped analyzer and widget tests pass for each integrated milestone; eventually the full shipped GKUI source graph is warning-reviewed and error-free. Generated JSON round trips and translations are tested. No `dynamic` blanket or analyzer exclusion hides code that is shipped.
- **Fallback:** Small compatibility facades and fixed subtitle styling; remove nonessential features and corresponding dependencies. Do not downgrade the whole UI to another project or import modern upstream screens.
- **UNKNOWN:** Final adaptation effort and full graph compile. Resolve with the first incremental build, not more tag speculation.

## Gate C — Can the dependency and Android build graph target19 coherently?

- **Evidence/confidence:** Medium. Pub probe passes; selected Java plugins declare19 or below. Toolchain proposal: Flutter3.19.6/Dart3.3.4, JDK17.0.10+7, AGP8.3.2/Gradle8.4/Kotlin1.9.22, compile/target34, build-tools34.0.0, min19. This exact Android tuple has **not** been assembled here.
- **Experiment:** Start with Flutter-only pubspec and build M0. Introduce one native plugin family at a time using exact matrix pins. Inspect merged manifest, Gradle dependency graph, bytecode/desugaring and APK native files. Commit pub/Gradle locks and artifact checksums.
- **Pass:** Clean release build from pinned environment; no native library or merged dependency requires>19; no accidental ABI/split output; install and exercise each included plugin on GKUI. Gradle success alone is insufficient.
- **Fallback:** Remove optional url_launcher/color picker/OS controls/desktop integrations. Replace package-info/connectivity with small API19 channels only if their retained versions fail. Use compatible historical AndroidX artifacts; never `tools:overrideLibrary` a higher minSdk as the “fix.”
- **UNKNOWN:** Full AndroidX transitive runtime floors and Kotlin/AGP integration until assembled. Stop upgrading build generations randomly; inspect the failing constraint, preserve one coherent tuple, and document each deviation.

## Gate D — Is there a viable ARMv7 player and surface path?

- **Evidence/confidence:** Medium. Legacy ExoPlayer2.19.1 source declares min16 and uses platform MediaCodec; Android MediaPlayer is present on19. Vendor decoder/GPU/audio behavior **UNKNOWN**. Available audited mpv payloads are not19 candidates.
- **Experiment:** Soon after M0, create one Flutter external texture + Exo core/HLS instance. Play a short bundled H.264 8-bit SDR/AAC-LC stereo MP4, starting480p then720p<=30fps. Show codec names, output dimensions, first-frame/error timing and memory. Test play/pause/seek, focus loss, navigation exit and20 open/close cycles; then HTTPS media using the real transport.
- **Pass:** Stable hardware decode at proposed baseline, audio sync and valid texture rotation/aspect ratio; no unbounded resource growth, stale callbacks, crash on screen-off or stuck exit. No software video fallback disguised as success.
- **Fallback:** Lower profile/level/resolution/frame rate via PMS; then small Android MediaPlayer adapter with the same Dart interface. Optional old media-kit experiment only if a retrievable ELF/payload is verified against API19 symbols; otherwise no weeks-long mpv rebuild prerequisite.
- **Stop condition:** Both backend paths fail required H.264/AAC playback at a useful low preset on the actual unit after surface/network separation. Record codec inventory and sample properties; seek user direction on reduced capability before new architecture.

## Gate E — Can all transports validate modern HTTPS?

- **Evidence/confidence:** Medium. Dart3.3.4 uses BoringSSL/TLS1.2 minimum and Android system CA directory. Host handshakes succeed; actual device clock/CA contents **UNKNOWN**. Conscrypt2.5.2 declares min9/ARMv7; OkHttp3.12.13 is the legacy candidate, not default Exo extension OkHttp4.11.
- **Experiment:** M1 diagnostic buttons separately exercise Dart to `https://plex.tv` and `https://clients.plex.tv`; later probe selected HTTPS PMS, images, subtitles, Exo playlist and segment fetches. Compare system roots and a reviewed current CA PEM with normal verification. Display TLS category/host/clock/bundle version without credentials. Include controlled wrong-host, expired/untrusted cert and HTTPS-to-HTTP redirect fixtures.
- **Pass:** Required valid chains validate; negative certificates and plaintext authenticated redirects fail. DNS, timeout, TLS, HTTP401 and parser errors are distinguishable. Tokens never appear in exported diagnostics. Every HLS subrequest receives appropriate authorization without cross-origin token leakage.
- **Fallback:** Reviewed signed-update CA bundle in Dart SecurityContext and separate native TrustManager. Prove Exo2.19.1 OkHttp3.12.13 substitution; if incompatible, implement minimal native DataSource. Use Conscrypt only where needed and verify JNI load. A bounded native bridge for small Plex API requests is last transport fallback, not whole-video channel streaming.
- **Hard limit:** No trust-all callback, hostname bypass, invalid-certificate acceptance or plaintext Plex auth. If secure transport cannot be achieved, remote authenticated use is blocked; report evidence instead of lowering security.

## Gate F — Does current Plex device/PIN auth work?

- **Evidence/confidence:** Medium. Base implements PIN creation/polling, user/resources and Plex Home flows; later source fixes cover startup races and token ownership. Current authenticated API behavior **UNKNOWN** because no user account was used.
- **Experiment:** Phone scans GKUI QR; claim PIN, fetch user/resources, save app-private tokens, restart and revalidate. Exercise cancel/expiry/network loss/401/revoked token; multiple Home users; one protected Home user; profile switch during resource refresh; shared server; sign-out before a delayed response returns.
- **Pass:** Bounded completion, no eternal spinner, no passwords typed on GKUI, correct selected profile and resource tokens, no unauthorized protected-user activation, sign-out cannot resurrect tokens. UI distinguishes offline from reauthentication.
- **Fallback:** Fresh device code/QR regeneration and explicit reauthentication on401; manual phone code entry if scanning is difficult. No embedded legacy WebView dependency and no static user token committed to source.
- **UNKNOWN:** Plex service/account policies and remote-play entitlements. Show server/service refusal and required user action; do not assume a particular subscription policy or buy/change anything automatically.

## Gate G — Can hotspot-to-remote-PMS access work without VPN?

- **Evidence/confidence:** Medium. Resource discovery includes HTTPS/relay endpoints and tokens; known failover/recovery algorithms can be ported independently of player. Actual user's PMS/NAT/firewall/relay state **UNKNOWN**.
- **Experiment:** Use phone hotspot, discover account and shared resources, classify local/remote/relay, select validated HTTPS candidate, match `/identity` machineIdentifier and verify a protected PMS request. Disconnect hotspot, restore, sleep/resume, exhaust candidates and manually retry; simulate old-generation probe completion.
- **Pass:** Works without VPN/manual LAN IP/unauthenticated access when PMS offers a reachable authorized remote endpoint. No credential-bearing plaintext probes. Bounded retries/backoff, explicit offline/401/wrong-server errors, recovery does not mark new client offline from stale response.
- **Fallback:** Refresh resource list; show remote-access status and allow HTTPS relay if service/account/bandwidth permits. User may need to configure their server/network; that is not proof of a client architecture failure. Do not open router ports or change PMS security as part of client implementation without direction.

## Gate H — Can PMS provide a compatible transcode and correct timeline?

- **Evidence/confidence:** Medium.1.35 protocol/model implementation and later timebase/subtitle fixes inspected. Current PMS output, entitlement, transcoder speed, HDR tone mapping and Exo behavior **UNKNOWN**.
- **Experiment:** M7 negotiate then play HLS/MPEG-TS H.264/AAC-LC stereo, beginning480p1.5Mbps then720p3Mbps. Test HEVC/TrueHD source converted by PMS without advertising local support. Inspect server decision/output, refusal/malformed decisions, original-capability guard, session IDs, segments/ranges/redirect headers, long seek, resume, pause, end, stop and quality switch. Add external SRT and embedded PGS/ASS burn at M8.
- **Pass:** Actual stream codec/resolution/profile/audio matches the request and device; sustainable playback, source-millisecond timeline/resume without double offset, one seek owner, sensible full duration, abandoned sessions cleaned up. Unsupported/refused content yields an actionable error, not unsafe direct play.
- **Fallback:**480p/2Mbps/lower profile; server-side audio conversion or subtitle burn; direct play only for proven-compatible files. If PMS cannot transcode, expose that limitation rather than attempting HEVC/software decode on GKUI.
- **UNKNOWN protocol details:** Verify accepted resolution/profile expressions, remote location parameter, transcode stop route and current decision codes against the user's PMS. Do not elevate inferred parameter semantics to tested facts.

## Gate I — Can the artifact be installed and updated by the legacy PackageManager?

- **Evidence/confidence:** High that conventional compatible APK installation is possible, from user evidence. Exact new artifact **UNKNOWN**.
- **Experiment:** Inspect min19, `armeabi-v7a` only, normal MAIN/LAUNCHER, pre21 theme/raster icon resources, DEX/multidex and all `.so` files. Align before signing, explicitly enable v1/JAR signing, preserve stable test key, upload one standalone APK plus SHA256. Verify with `aapt dump badging`, `apkanalyzer manifest print`, ZIP inspection and `apksigner verify --verbose --min-sdk-version 19`.
- **Pass:** v1 verification true; device install/launch and a second same-key update both work without uninstalling data. No AAB/XAPK/APKS/splits. No hidden min21 native payload or unsupported Application startup call.
- **Fallback:** Reduce modules/method count; if needed AndroidX multidex2.0.1 installed on pre21; D8 API19 settings, guarded Java/platform APIs, valid raster/resource qualifiers, conventional extracted/compressed native libraries. Signing errors, ABI, SDK and DEX/resource issues are separate diagnostics, not one guessed cause.

## Gate J — Is performance usable without ADB?

- **Evidence/confidence:** Medium that base risks are actionable:500MiB decoded-image budget, uncapped artwork and known later cleanup fixes. Physical RAM/memory class/decoder throughput **UNKNOWN**.
- **Experiment:** Initial32MiB/100-image decoded cache,100–200MiB private disk cache,2–4 image transfers,8–16MiB player target buffer; measure rather than promise these numbers.30–60min mixed browsing/playback,20 player cycles, stalled image body,10 hotspot/sleep recoveries, long logs view and large library. Test safely while stationary.
- **Pass:** No OOM/crash/unbounded memory growth; responsive large landscape touch controls; no library-wide blocking on one failed server; recoverable errors and readable logs. Record observed memory/decoder/network counters rather than inventing exact FPS/RAM thresholds now.
- **Fallback:** Lower artwork pixel bounds/concurrency/cache/buffer, disable hero blur/animation, paginate more aggressively and lower remote output quality. If baseline remains unusable, agree a reduced supported profile with the user.
- **Diagnostics requirement:** App version/build hash, Android/API/ABI, memory, clock, selected server/endpoint/direct-or-relay, TLS/CA version, backend/decoder, source/output codec/dimensions/bitrate, play method/preset, state/error. Bounded lazy on-screen viewer + copy; SAF export only if GKUI has a document picker. No ADB/root/known USB writable path assumed.

## Decision and change control

Proceed with M0/Gates A,C,I, followed by M1/E and an early player spike/D. Keep main unchanged and maintain separate small implementation commits. A failed first build is not NO-GO; an unsupported plugin is not NO-GO when removal/history is available. A demonstrated engine, secure-transport or decoder hard blocker requires its exact versions/artifacts, attempts, smallest workaround and retained-code assessment before considering a new native application.

Do not let authenticated account/PMS tests happen before redaction and HTTPS policy exist. Never publish user tokens, server credentials or signing keys in artifacts. Legacy Flutter/Dart/Exo/OkHttp remain a security-maintenance burden even after all functional gates pass; do not describe a successful old-device port as equivalent to a currently maintained Android stack.
