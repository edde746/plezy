import 'package:video_player_example/components/custom_video_player/custom_video_player_controller.dart';
import 'package:video_player_example/components/custom_video_player/custom_video_player_widget.dart';
import 'package:flutter/material.dart';
import 'package:video_player_drm/video_player.dart';

class CustomVideoPlayer extends StatefulWidget {
  const CustomVideoPlayer({
    super.key,
    required this.contentsInfo,
    this.formatHint,
    this.drmConfigs,
  });

  final String contentsInfo;
  final VideoFormat? formatHint;
  final DrmConfigs? drmConfigs;

  @override
  State<CustomVideoPlayer> createState() => _CustomVideoPlayer();
}

class _CustomVideoPlayer extends State<CustomVideoPlayer> {
  late CustomVideoController _cController;

  @override
  void initState() {
    super.initState();
    _cController = CustomVideoController(
      videoUrl: widget.contentsInfo,
      formatHint: widget.formatHint,
      muteSound: false,
      isLooping: false,
      autoPlay: true,
      drmConfigs: widget.drmConfigs,
    );
  }

  @override
  void dispose() {
    _cController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: Future.delayed(const Duration(milliseconds: 1000)),
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return AspectRatio(
            aspectRatio: _cController.getVideoValue.aspectRatio,
            child: VideoPlayerWidget(
              videoController: _cController,
              videoOption: VideoOption.bottomBarOnly,
            ),
          );
        } else {
          return const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }
}
