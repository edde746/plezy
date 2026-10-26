import 'package:flutter/material.dart';
import 'package:video_player_drm/video_player.dart';

class PlayerVideoAndPopPage extends StatefulWidget {
  const PlayerVideoAndPopPage({super.key});

  @override
  State<PlayerVideoAndPopPage> createState() => _PlayerVideoAndPopPageState();
}

class _PlayerVideoAndPopPageState extends State<PlayerVideoAndPopPage> {
  late VideoPlayerController _controller;
  bool _ready = false;
  bool _startedPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/Butterfly-209.mp4');
    _controller.addListener(_onChanged);
    _start();
  }

  Future<void> _start() async {
    await _controller.initialize();
    await _controller.play();
    _startedPlaying = true;
    if (mounted) setState(() => _ready = true);
  }

  void _onChanged() {
    if (_startedPlaying && !_controller.value.isPlaying) {
      _startedPlaying = false;
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Center(
        child: _ready
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const Text('waiting for video to load'),
      ),
    );
  }
}
