import 'package:video_player_example/components/controls_overlay/controls_overlay.dart';
import 'package:flutter/material.dart';
import 'package:video_player_drm/video_player.dart';

class MultiTrackTest extends StatefulWidget {
  const MultiTrackTest({super.key});

  @override
  State<MultiTrackTest> createState() => _MultiTrackTestState();
}

class _MultiTrackTestState extends State<MultiTrackTest> {
  late VideoPlayerController _controller;
  bool _subtitleEnabled = true;
  int _subtitleSync = 0;

  @override
  void initState() {
    super.initState();
    // TODO: Replace with your own multitrack video URL
    // (e.g., MKV with multiple audio/subtitle tracks)
    _controller = VideoPlayerController.network(
      Uri.parse('http://YOUR_SERVER:PORT/path/to/multitrack_video.mkv'),
    );

    _controller.addListener(() {
      setState(() {});
    });
    _controller.initialize().then((_) {
      _controller.setSubtitleEnabled(true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioTracks = _controller.value.audioTracks;
    final subtitleTracks = _controller.value.subtitleTracks;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video Player
          Container(
            padding: const EdgeInsets.all(12),
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  VideoPlayer(_controller),
                  ControlsOverlay(controller: _controller),
                  VideoProgressIndicator(_controller, allowScrubbing: true),
                ],
              ),
            ),
          ),

          const Divider(),

          // Audio Tracks
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Audio Tracks (${audioTracks?.length ?? 0}) - selected: ${_controller.value.currentAudioTrack ?? "none"}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          if (audioTracks != null)
            Wrap(
              spacing: 8,
              children: audioTracks.asMap().entries.map((e) {
                final i = e.key;
                final t = e.value;
                final isSelected = _controller.value.currentAudioTrack == i;
                return ElevatedButton(
                  style: isSelected
                      ? ElevatedButton.styleFrom(backgroundColor: Colors.blue)
                      : null,
                  onPressed: () => _controller.selectAudioTrack(i),
                  child: Text(
                    '${t['language'] ?? 'Track $i'} (#$i)',
                    style: isSelected
                        ? const TextStyle(color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),

          const Divider(),

          // Subtitle Tracks
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Subtitle Tracks (${subtitleTracks?.length ?? 0})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          if (subtitleTracks != null)
            Wrap(
              spacing: 8,
              children: subtitleTracks.asMap().entries.map((e) {
                final i = e.key;
                final t = e.value;
                return ElevatedButton(
                  onPressed: () => _controller.selectSubtitleTrack(i),
                  child: Text('${t['language'] ?? 'Sub $i'} (#$i)'),
                );
              }).toList(),
            ),

          const Divider(),

          // Subtitle On/Off
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Text('Subtitle', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Switch(
                  value: _subtitleEnabled,
                  onChanged: (v) {
                    _subtitleEnabled = v;
                    _controller.setSubtitleEnabled(v);
                    setState(() {});
                  },
                ),
              ],
            ),
          ),

          // Subtitle Sync
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Text('Sync', style: TextStyle(fontSize: 16)),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    _subtitleSync -= 500;
                    _controller.setSubtitleSync(_subtitleSync);
                    setState(() {});
                  },
                ),
                Text('${_subtitleSync}ms'),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    _subtitleSync += 500;
                    _controller.setSubtitleSync(_subtitleSync);
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
