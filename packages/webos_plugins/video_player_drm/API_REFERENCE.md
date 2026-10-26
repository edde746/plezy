# API Reference — video_player_drm

## Features

- Inline video playback via the webOS native media subsystem
- DRM support (PlayReady, Widevine) with license-server URL or app-provided license callback
- Multi-audio track and subtitle track selection
- Closed-caption rendering from WebVTT or SubRip files with offset/sync controls
- Asset, file, network, and content-uri data sources
- Platform-managed video plane rendered through a transparent Flutter surface

## API Overview

### Classes

- **VideoPlayerController** — Controls a video from an asset, file, or network resource, with optional DRM and closed-caption configuration.
- **VideoPlayerValue** — Immutable snapshot of a controller's playback state.
- **VideoPlayer** — Widget that displays the video stream managed by a `VideoPlayerController`.
- **VideoProgressColors** — Color configuration for `VideoProgressIndicator`.
- **VideoProgressIndicator** — Widget that displays a progress bar bound to a controller.
- **VideoScrubber** — Widget that lets users scrub through a video by dragging.
- **ClosedCaption** — Widget that renders the active caption from a controller.
- **ClosedCaptionFile** — Abstract base for parsed caption files.
- **WebVTTCaptionFile** — Parser for WebVTT (`.vtt`) caption files.
- **SubRipCaptionFile** — Parser for SubRip (`.srt`) caption files.
- **DrmConfigs** — Configuration for DRM-protected content playback.
- **DurationRange** — Describes a range of `Duration` values (used for buffered ranges).
- **VideoPlayerOptions** — Generic playback options.
- **VideoPlayerWebOptions** — Web-platform playback options (no effect on webOS).
- **VideoPlayerWebOptionsControls** — Web-platform native controls options (no effect on webOS).

### Enums

- **DrmType** — DRM scheme to use (`none`, `playready`, `widevine`).
- **DataSourceType** — Source kind (`asset`, `network`, `file`, `contentUri`).
- **VideoFormat** — Stream container hint (`dash`, `hls`, `ss`, `other`).

### Typedefs

- **LicenseCallback** — `Future<Uint8List> Function(Uint8List challenge)`. Returns a DRM license for the given challenge data.

---

## Classes

### VideoPlayerController

Controls playback of a video and exposes its state via the `VideoPlayerValue` it inherits from `ValueNotifier`. After `dispose` all further calls are ignored.

#### Constructors

```dart
VideoPlayerController.asset(
  String dataSource, {
  String? package,
  Future<ClosedCaptionFile>? closedCaptionFile,
  VideoPlayerOptions? videoPlayerOptions,
})
```

```dart
VideoPlayerController.network(
  String dataSource, {
  VideoFormat? formatHint,
  Future<ClosedCaptionFile>? closedCaptionFile,
  VideoPlayerOptions? videoPlayerOptions,
  Map<String, String> httpHeaders = const <String, String>{},
  DrmConfigs? drmConfigs,
})
```

```dart
VideoPlayerController.file(
  File file, {
  Future<ClosedCaptionFile>? closedCaptionFile,
  VideoPlayerOptions? videoPlayerOptions,
})
```

```dart
VideoPlayerController.contentUri(
  Uri contentUri, {
  Future<ClosedCaptionFile>? closedCaptionFile,
  VideoPlayerOptions? videoPlayerOptions,
})
```

Note: `contentUri` is Android-only on upstream; not supported on webOS.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| dataSource | `String` | Resource path/URL of the loaded video |
| dataSourceType | `DataSourceType` | Kind of source (asset, network, file, contentUri) |
| formatHint | `VideoFormat?` | Optional stream container hint, only for network sources |
| httpHeaders | `Map<String, String>` | Reserved; not used on webOS |
| package | `String?` | Asset package name, only for asset sources |
| drmConfigs | `DrmConfigs?` | DRM configuration, only for network sources |
| videoPlayerOptions | `VideoPlayerOptions?` | Optional generic playback options |
| textureId | `int` | Internal texture identifier; `-1` before `initialize()` returns |
| value | `VideoPlayerValue` | Current playback state snapshot (inherited from `ValueNotifier`) |
| position | `Future<Duration?>` | Current playback position |
| closedCaptionFile | `Future<ClosedCaptionFile>?` | Currently-attached caption file |

#### Methods

##### initialize

```dart
Future<void> initialize()
```

Loads the data source and prepares for playback. Must be called before any other method.

##### play

```dart
Future<void> play()
```

Starts or resumes playback.

##### pause

```dart
Future<void> pause()
```

Pauses playback.

##### dispose

```dart
Future<void> dispose()
```

Releases the underlying platform resources. After dispose, all further calls are ignored.

##### seekTo

```dart
Future<void> seekTo(Duration position)
```

Seeks to the given position. The position is clamped to `[0, value.duration]`.

##### setLooping

```dart
Future<void> setLooping(bool looping)
```

Enables or disables loop playback.

##### setVolume

```dart
Future<void> setVolume(double volume)
```

**Not supported on webOS.** Throws a Dart exception with code `unsupported`. Use system-wide volume controls instead.

##### setPlaybackSpeed

```dart
Future<void> setPlaybackSpeed(double speed)
```

Sets playback speed. Negative or zero values throw `ArgumentError`.

##### selectAudioTrack

```dart
Future<void> selectAudioTrack(int index)
```

Switches the active audio track to the given index.

##### selectSubtitleTrack

```dart
Future<void> selectSubtitleTrack(int index)
```

Switches the active subtitle track to the given index.

##### setSubtitleEnabled

```dart
Future<void> setSubtitleEnabled(bool enable)
```

Shows or hides the platform-rendered subtitle.

##### setSubtitleSync

```dart
Future<void> setSubtitleSync(int offset)
```

Adjusts subtitle timing offset in milliseconds.

##### setClosedCaptionFile

```dart
Future<void> setClosedCaptionFile(Future<ClosedCaptionFile>? captionFile)
```

Attaches or detaches a closed-caption file. Pass `null` to detach.

##### setCaptionOffset

```dart
void setCaptionOffset(Duration offset)
```

Adjusts the time offset applied when looking up the active caption.

---

### VideoPlayerValue

Immutable snapshot of playback state. Subclasses extend `ValueNotifier<VideoPlayerValue>` and listeners receive new instances on change.

#### Constructor

```dart
const VideoPlayerValue({
  required Duration duration,
  Size size = Size.zero,
  Duration position = Duration.zero,
  Caption caption = Caption.none,
  Duration captionOffset = Duration.zero,
  List<DurationRange> buffered = const <DurationRange>[],
  bool isInitialized = false,
  bool isPlaying = false,
  bool isLooping = false,
  bool isBuffering = false,
  double volume = 1.0,
  double playbackSpeed = 1.0,
  String? errorDescription,
  int rotationCorrection = 0,
})
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| duration | `Duration` | Total stream duration |
| size | `Size` | Native pixel size of the video |
| position | `Duration` | Current playback position |
| caption | `Caption` | Active caption at the current position |
| captionOffset | `Duration` | Offset applied when looking up captions |
| buffered | `List<DurationRange>` | Currently buffered ranges |
| isInitialized | `bool` | Whether `initialize()` has completed |
| isPlaying | `bool` | Whether playback is currently active |
| isLooping | `bool` | Whether loop playback is enabled |
| isBuffering | `bool` | Whether the player is currently buffering |
| volume | `double` | Playback volume (informational; see `setVolume` note) |
| playbackSpeed | `double` | Playback speed multiplier |
| errorDescription | `String?` | Error text if an error occurred |
| rotationCorrection | `int` | Degrees of rotation correction to apply when rendering |
| hasError | `bool` (getter) | `errorDescription != null` |
| aspectRatio | `double` (getter) | `size.width / size.height`, or `1.0` if size is zero |
| isInErrorState | `bool` (getter) | Alias for `hasError` |

#### Methods

##### copyWith

```dart
VideoPlayerValue copyWith({...})
```

Returns a new instance with the given fields replaced.

---

### VideoPlayer

Widget that displays the video stream managed by a `VideoPlayerController`.

```dart
VideoPlayer(VideoPlayerController controller)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| controller | `VideoPlayerController` | Yes | The controller whose video to display |

---

### VideoProgressIndicator

Widget that displays a progress bar bound to a `VideoPlayerController`.

```dart
VideoProgressIndicator(
  VideoPlayerController controller, {
  VideoProgressColors colors = const VideoProgressColors(),
  bool allowScrubbing = false,
  EdgeInsets padding = const EdgeInsets.only(top: 5.0),
})
```

---

### VideoScrubber

Widget that lets users scrub the video by dragging.

```dart
VideoScrubber({
  required Widget child,
  required VideoPlayerController controller,
})
```

---

### VideoProgressColors

Color configuration for `VideoProgressIndicator`.

```dart
const VideoProgressColors({
  Color playedColor = const Color.fromRGBO(255, 0, 0, 0.7),
  Color bufferedColor = const Color.fromRGBO(50, 50, 200, 0.2),
  Color backgroundColor = const Color.fromRGBO(200, 200, 200, 0.5),
})
```

---

### ClosedCaption

Widget that renders the active caption from a `VideoPlayerController`.

```dart
ClosedCaption({String? text, TextStyle? textStyle})
```

---

### DrmConfigs

Configuration for DRM-protected content playback. Pass to `VideoPlayerController.network` via the `drmConfigs` parameter.

#### Constructor

```dart
const DrmConfigs({
  DrmType type = DrmType.none,
  String? licenseServerUrl,
  LicenseCallback? licenseCallback,
})
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| type | `DrmType` | No | DRM scheme. Defaults to `DrmType.none` |
| licenseServerUrl | `String?` | No | URL of the DRM license server. Either this or `licenseCallback` should be specified |
| licenseCallback | `LicenseCallback?` | No | Custom callback for app-side license acquisition. Either this or `licenseServerUrl` should be specified |

Note: while `licenseCallback` is running the platform thread is blocked. Slow callbacks may cause input lag or pipeline hangs.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| type | `DrmType` | The DRM scheme |
| licenseServerUrl | `String?` | License server URL |
| licenseCallback | `LicenseCallback?` | Custom license callback |

---

### ClosedCaptionFile

Abstract base for parsed caption files. Implementations expose a list of `Caption` objects with their start/end positions.

Concrete implementations:

- **WebVTTCaptionFile(String fileContents)** — parses WebVTT `.vtt` content.
- **SubRipCaptionFile(String fileContents)** — parses SubRip `.srt` content.

---

### DurationRange

Describes a range of `Duration` values. Used by `VideoPlayerValue.buffered` to express buffered intervals.

```dart
DurationRange(Duration start, Duration end)
```

---

### VideoPlayerOptions, VideoPlayerWebOptions, VideoPlayerWebOptionsControls

Generic playback / web-platform options exposed for cross-platform compatibility. `mixWithOthers` and the web-specific options have no effect on webOS.

---

## Enums

### DrmType

| Value | Description |
|-------|-------------|
| none | No DRM (default) |
| playready | Microsoft PlayReady |
| widevine | Google Widevine CDM |

### DataSourceType

| Value | Description |
|-------|-------------|
| asset | Bundled asset in the app |
| network | Network URL (HTTP/HTTPS) |
| file | Local file path |
| contentUri | Android-only content URI; not supported on webOS |

### VideoFormat

| Value | Description |
|-------|-------------|
| dash | MPEG-DASH manifest |
| hls | HTTP Live Streaming manifest |
| ss | Smooth Streaming manifest |
| other | Other / auto-detect |

---

## Typedefs

### LicenseCallback

```dart
typedef LicenseCallback = Future<Uint8List> Function(Uint8List challenge);
```

Returns the DRM license bytes for the given challenge data. Used by `DrmConfigs.licenseCallback` for app-side license acquisition.

---

## webOS-Specific Behavior

- **Concurrent player limit:** Up to 5 `VideoPlayerController` instances can run simultaneously in a single application. Creating a sixth controller automatically evicts the least-recently-created player; the evicted player receives an `error` event with code `-1` (message: `num of pipelines`).
- **Transparent surface:** The application must enable `transparent: true` in `appinfo.json` so the platform video plane is visible underneath the Flutter surface. See [README — Required configurations](README.md#required-configurations).
- **Video plane rendering:** Video frames are rendered on a dedicated hardware video plane. The Flutter widget area becomes transparent to expose the underlying plane.
- **DRM:** PlayReady and Widevine are supported on devices with the corresponding DRM stack provisioned. License delivery can be platform-driven (`licenseServerUrl`) or app-driven (`licenseCallback`).
