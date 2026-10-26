import 'package:flutter/material.dart';
import 'package:video_player_drm/video_player.dart';

class CustomVideoController {
  // Video Controller
  late VideoPlayerController videoController;

  // Video Url
  final String videoUrl;

  // Video Format Hint
  final VideoFormat? formatHint;

  // true : Mute
  final bool muteSound;

  // true : Looping
  final bool isLooping;

  // true : Auto Play
  final bool autoPlay;

  // Drm configs
  final DrmConfigs? drmConfigs;

  // Logger instance
  //final Logger _logger = Logger(name: 'CustomVideoController');

  CustomVideoController({
    required this.videoUrl,
    this.formatHint = VideoFormat.other,
    this.muteSound = false,
    this.isLooping = false,
    this.autoPlay = false,
    this.drmConfigs,
  }) {
    // For Preview Thumbnail
    videoStateNotifier = ValueNotifier(false);

    // Auto Play
    initVideoController().whenComplete(() {
      if (autoPlay) {
        playVideo();
      }
    });
  }

  // Video State Notifier
  late ValueNotifier<bool> videoStateNotifier;

  // getter : VideoPlayerController.value
  VideoPlayerValue get getVideoValue => videoController.value;

  // initVideoController : VideoPlayerController.initialize()
  // When videoStateNotifier is true, the thumbnail disappears and the video plays.
  Future<void> initVideoController() async {
    if (videoUrl.startsWith("http") == true) {
      videoController = VideoPlayerController.network(
        Uri.parse(videoUrl),
        formatHint: formatHint,
        drmConfigs: drmConfigs,
      );
    } else {
      videoController = VideoPlayerController.asset(videoUrl);
    }

    await videoController.setVolume(muteSound ? 0.0 : 1.0);
    await videoController.setLooping(isLooping);

    await videoController.initialize();

    videoStateNotifier.value = getVideoValue.isInitialized;
  }

  // playVideo : VideoPlayerController.play()
  Future<void> playVideo() async {
    if (!(getVideoValue.isPlaying)) {
      if (getVideoValue.position == Duration.zero) {
        await videoController.play();
      } else {
        await seekTo(getVideoValue.position);
        await videoController.play();
      }
    }
  }

  // pauseVideo : VideoPlayerController.pause()
  Future<void> pauseVideo() async {
    await videoController.pause();
  }

  // seekTo : VideoPlayerController.seekTo()
  Future<void> seekTo(Duration duration) async {
    await videoController.seekTo(duration);
  }

  // setVolume : VideoPlayerController.setVolume() from 0.0(mute) to 1.0
  Future<void> setVolume(double volume) async {
    await videoController.setVolume(volume);
  }

  // dispose : VideoPlayerController.dispose()
  Future<void> dispose() async {
    await videoController.dispose();
    videoStateNotifier.dispose();
  }

  // Only Support in Full Mode
  // For Timeline
  void addListener(Function() listener) {
    videoController.addListener(listener);
  }

  void removeListener(Function() listener) {
    videoController.removeListener(listener);
  }
}
