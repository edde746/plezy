# video_player_drm

A Flutter plugin for **webOS** devices that provides video playback with **multi-audio track**, **subtitle**, and **DRM** support via the platform's native media subsystem.

## Supported platforms

This plugin is supported on webOS 26 media or above.

## Usage

**pubspec.yaml:**

```yaml
dependencies:
  video_player_drm:
    git:
      url: https://github.com/lg-flutter-webos/plugins.git
      path: packages/video_player_drm
      ref: main
```

**Import:**

```dart
import 'package:video_player_drm/video_player.dart';
```

## Required configurations

Video playback uses a transparent Flutter surface so the platform video plane
can show through. Set `transparent: true` in your application's
`appinfo.json`:

```json
{
  "transparent": true
}
```

## Example

See the [example application](example/lib/main.dart) for a complete usage demonstration. The example app includes a **MultiTrack** tab for testing audio track switching and subtitle features.

## API Reference

See the [API Reference](API_REFERENCE.md) for detailed documentation of all classes, methods, and parameters.

## Limitations

- Up to **5 video players** can run concurrently in a single application.
  When the limit is reached, the next `VideoPlayerController` creation
  automatically evicts the least-recently-created player; that player
  receives an `error` event with code `-1` ("num of pipelines") so the
  Dart side can detect the eviction.
- `VideoPlayerController.setVolume` is not supported on webOS in this
  release. Calling it surfaces a Dart exception with error code
  `unsupported`. Apps that need per-stream volume control should rely
  on system-wide volume controls.
- The `httpHeaders` option of `VideoPlayerController.network` is not
  supported.
- `VideoPlayerOptions.mixWithOthers` is not supported.

## Notes

- `video_player_drm` is **not** compatible with the original `video_player`
  plugin. For cross-platform apps targeting webOS and other platforms,
  create separate source files and import each plugin respectively.
