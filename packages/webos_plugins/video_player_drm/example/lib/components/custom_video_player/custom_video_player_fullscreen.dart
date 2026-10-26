import 'package:flutter/material.dart';
import 'package:video_player_example/components/custom_video_player/custom_video_player_controller.dart';
import 'package:video_player_example/components/custom_video_player/custom_video_player_widget.dart';

class FullScreenVideoWidget extends StatefulWidget {
  const FullScreenVideoWidget({super.key, required this.videoUrl});

  final String videoUrl;

  @override
  State<FullScreenVideoWidget> createState() => _FullScreenVideoWidgetState();
}

class _FullScreenVideoWidgetState extends State<FullScreenVideoWidget> {
  late CustomVideoController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CustomVideoController(
      videoUrl: widget.videoUrl,
      muteSound: false,
      isLooping: false,
      autoPlay: false,
    );
  }

  @override
  void dispose() async {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: Future.delayed(const Duration(milliseconds: 500)),
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return VideoPlayerWidget(
              videoController: _controller,
              videoOption: VideoOption.full,
              isFullScreen: true,
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
