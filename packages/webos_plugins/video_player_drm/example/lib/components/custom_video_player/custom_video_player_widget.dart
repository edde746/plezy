import 'package:flutter/material.dart';
import 'package:video_player_example/components/custom_video_player/custom_video_player_controller.dart';
import 'package:video_player_example/components/custom_video_player/custom_video_player_fullscreen.dart';
import 'package:video_player_drm/video_player.dart';

// none : no UI
// CenterButtonOnly : Play/Pause Toggle Button on the Centor
// BottomBarOnly : Bottom indicator, Play/Pause Toggle Button, Sound Toggle Button
// Full = CenterButtonOnly + BottomBarOnly
enum VideoOption { none, centerButtonOnly, bottomBarOnly, full }

// For Toggle Button
enum PlayerButtonState { stopped, playing, paused }

// Time Duration Util
extension DurationToTime on Duration {
  String get getTime {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(inSeconds.remainder(60));
    if (inHours == 0) {
      return '$twoDigitMinutes:$twoDigitSeconds';
    } else {
      return "${twoDigits(inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    }
  }
}

class VideoPlayerWidget extends StatefulWidget {
  const VideoPlayerWidget({
    super.key,
    required this.videoController,
    this.videoOption = VideoOption.none,
    this.isFullScreen = false,
    this.placeHolder,
    this.widgetSize,
  });

  final CustomVideoController videoController;
  final VideoOption videoOption;
  final bool isFullScreen;
  final Widget? placeHolder;
  final Size? widgetSize;

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  // Video Controller
  late CustomVideoController _controller;

  // Play/Pause Toggle
  ValueNotifier<PlayerButtonState>? _playButtonNotifier;

  // Volume Toggle : true = mute
  ValueNotifier<bool>? _volumeNotifier;

  // Time Line Indicator
  ValueNotifier<Duration>? _timelineNotifier;

  late Size _size;

  @override
  void initState() {
    super.initState();
    _controller = widget.videoController;

    // For Timeline
    if (widget.videoOption == VideoOption.full ||
        widget.videoOption == VideoOption.bottomBarOnly) {
      _volumeNotifier = ValueNotifier(_controller.muteSound);
      _timelineNotifier = ValueNotifier(Duration.zero);
    }

    // Play/Pause Toggle
    _playButtonNotifier = ValueNotifier(PlayerButtonState.stopped);

    if (widget.videoOption != VideoOption.none) {
      _controller.addListener(_listener);
    }

    if (_controller.autoPlay == true) {
      _playButtonNotifier!.value = PlayerButtonState.playing;
    } else {
      _playButtonNotifier!.value = PlayerButtonState.paused;
    }
  }

  // For Timeline Slider
  void _listener() {
    _timelineNotifier!.value = _controller.getVideoValue.position;

    if (!_controller.isLooping &&
        !_controller.getVideoValue.isPlaying &&
        _controller.getVideoValue.position ==
            _controller.getVideoValue.duration) {
      _playButtonNotifier!.value = PlayerButtonState.stopped;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_listener);
    _playButtonNotifier?.dispose();
    _volumeNotifier?.dispose();
    _timelineNotifier?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _controller.videoStateNotifier,
      builder: (_, isLoaded, __) {
        return _videoOptionWidget(isLoaded);
      },
    );
  }

  Widget _videoWidget(bool isLoaded) {
    _size = widget.widgetSize ?? MediaQuery.of(context).size;

    return isLoaded
        ? widget.isFullScreen
              ? VideoPlayer(_controller.videoController)
              : SizedBox(
                  height: _size.height,
                  width: _size.width,
                  child: VideoPlayer(_controller.videoController),
                )
        : (widget.placeHolder ?? Container());
  }

  Widget _videoOptionWidget(bool isLoaded) {
    switch (widget.videoOption) {
      case VideoOption.none:
        return _videoWidget(isLoaded);
      case VideoOption.centerButtonOnly:
        return Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [_videoWidget(isLoaded), _toggleButton()],
        );
      case VideoOption.bottomBarOnly:
        return Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          children: [
            _videoWidget(isLoaded),
            Align(alignment: Alignment.bottomCenter, child: _bottomBar()),
          ],
        );
      case VideoOption.full:
        return Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          children: [
            _videoWidget(isLoaded),
            _toggleButton(),
            Align(alignment: Alignment.bottomCenter, child: _bottomBar()),
          ],
        );
    }
  }

  Widget _toggleButton({bool isBottomButton = false, double iconSize = 30}) {
    return ValueListenableBuilder<PlayerButtonState>(
      valueListenable: _playButtonNotifier!,
      builder: (_, state, __) {
        switch (state) {
          case PlayerButtonState.stopped:
            return IconButton(
              iconSize: iconSize,
              icon: widget.isFullScreen
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                      ),
                    )
                  : const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                      ),
                    ),
              onPressed: () async {
                await _controller.playVideo();
                _playButtonNotifier!.value = PlayerButtonState.playing;
              },
            );
          case PlayerButtonState.playing:
            if (isBottomButton) {
              return IconButton(
                iconSize: iconSize,
                icon: widget.isFullScreen
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.pause_rounded, color: Colors.white),
                      )
                    : const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.pause_rounded, color: Colors.white),
                      ),
                onPressed: () async {
                  await _controller.pauseVideo();
                  _playButtonNotifier!.value = PlayerButtonState.paused;
                },
              );
            }
            return Center(
              child: InkWell(
                radius: 20,
                onTap: () async {
                  await _controller.pauseVideo();
                  _playButtonNotifier!.value = PlayerButtonState.paused;
                },
              ),
            );
          case PlayerButtonState.paused:
            return IconButton(
              iconSize: iconSize,
              icon: widget.isFullScreen
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                      ),
                    )
                  : const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                      ),
                    ),
              onPressed: () async {
                await _controller.playVideo();
                _playButtonNotifier!.value = PlayerButtonState.playing;
              },
            );
        }
      },
    );
  }

  Widget _bottomBar() {
    return SizedBox(
      width: _size.width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ValueListenableBuilder<Duration>(
            valueListenable: _timelineNotifier!,
            builder: (_, duration, __) {
              return Transform.translate(
                offset: const Offset(0, 30),
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(trackHeight: 2),
                  child: Slider(
                    activeColor: Colors.redAccent,
                    inactiveColor: Colors.black54,
                    min: 0.0,
                    max: 1.0,
                    value:
                        (duration.inMilliseconds /
                                _controller
                                    .getVideoValue
                                    .duration
                                    .inMilliseconds) <
                            1.0
                        ? (duration.inMilliseconds /
                              _controller.getVideoValue.duration.inMilliseconds)
                        : 0.0,
                    onChanged: (value) {
                      double touchedPosition =
                          value *
                          _controller.getVideoValue.duration.inMilliseconds;

                      _controller.seekTo(
                        Duration(milliseconds: touchedPosition.round()),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          Row(
            children: [
              _toggleButton(isBottomButton: true, iconSize: 14),
              Expanded(
                child: widget.isFullScreen
                    ? ValueListenableBuilder<Duration>(
                        valueListenable: _timelineNotifier!,
                        builder: (_, duration, __) {
                          return Text(
                            duration.getTime,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          );
                        },
                      )
                    : ValueListenableBuilder<Duration>(
                        valueListenable: _timelineNotifier!,
                        builder: (_, duration, __) {
                          return Text(
                            duration.getTime,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
              ),
              IconButton(
                onPressed: () async {
                  await _controller.setVolume(
                    _volumeNotifier!.value ? 1.0 : 0.0,
                  );
                  _volumeNotifier!.value = !_volumeNotifier!.value;
                },
                icon: ValueListenableBuilder<bool>(
                  valueListenable: _volumeNotifier!,
                  builder: (_, isMute, __) {
                    return Icon(
                      isMute
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      color: widget.isFullScreen ? Colors.white : Colors.white,
                      size: 14,
                    );
                  },
                ),
              ),
              IconButton(
                onPressed: () async {
                  if (widget.isFullScreen) {
                    Navigator.pop(context);
                  } else {
                    await _controller.pauseVideo();
                    _playButtonNotifier!.value = PlayerButtonState.paused;

                    if (!mounted) return;
                    Navigator.push(
                      context,
                      expandVideoRoute(
                        pushPage: FullScreenVideoWidget(
                          videoUrl: _controller.videoUrl,
                        ),
                      ),
                    );
                  }
                },
                icon: Icon(
                  widget.isFullScreen
                      ? Icons.close_fullscreen_rounded
                      : Icons.fullscreen_rounded,
                  color: widget.isFullScreen ? Colors.white : Colors.white,
                  size: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Route expandVideoRoute({required Widget pushPage}) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) => pushPage,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return child;
      },
    );
  }
}
