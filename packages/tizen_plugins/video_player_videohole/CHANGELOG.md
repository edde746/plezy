## 0.6.2

* Use the Tizen Core display API on Tizen 11.0 and later.

## 0.6.1

* Fix a "used after being disposed" error when a seek, position, or duration update completes after the controller is disposed.
* Fix multi-line WebVTT cues without an identifier being dropped.

## 0.6.0

* Migrate from Platform Channels to Dart FFI.
* Replace EventChannel with FFI port for event callbacks.
* Add JSON serialization for complex parameters.
* Add pending seekTo handling.

## 0.5.11

* Replace ecore-wl2 code with tizen window manager plugin.
* Resolve `strict_top_level_inference` lint.
* Omit obvious local variable types.
* Reformat with a line length of 100.

## 0.5.10

* Update the repository URL to use the `main` branch.

## 0.5.9

* Adds compatibility with `http` 1.0 in example.
* Removed unused proxy APIs.
* Remove Ecore API.

## 0.5.8

* Add namespace to the C++ code to avoid name conflicts with other plugins.

## 0.5.7

* Update code format.
* Automatically rotates video player based on device orientation.

## 0.5.6

* Add suspend and restore for handing onPause and onResume lifecycle event.

## 0.5.5

* Update the LICENSE file so that it is recognized by pub.dev.

## 0.5.4

*  Synchronize isPlaying state.

## 0.5.3

*  Add 'isCompleted' event to 'VideoPlayerEvent'.

## 0.5.2

* Fix new lint warnings.
* Update minimum Flutter and Dart version to 3.13 and 3.1.
* Fix getAudioTracks out of bounds issue.

## 0.5.1

* Free response buffer after install key.

## 0.5.0

* Add get duration API for live stream

## 0.4.0

* Merge media player code from avplay.

## 0.3.0

* Implement `httpHeaders` of `VideoPlayerController.network`.

## 0.2.0

* Implement functionality of selecting video, audio and text tracks.

## 0.1.3

* Fix event channel issue, sending messages from native to Flutter on the platform thread.

## 0.1.2

* Increase the minimum Flutter version to 3.3.
* Fix web build

## 0.1.1

* Update pigeon to 10.0.0.
* Rename `TizenVideoPlayerApi` to `VideoPlayerVideoholeApi`.
* Rename the event channel to avoid possible conflicts.

## 0.1.0

* Initial release.
