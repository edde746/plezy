import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'video_player_platform_interface.dart';
import 'src/messages.g.dart';
import 'src/hole.dart';

/////////////////////////////////////////////////////////////////////
////                        Widget                               ////
/////////////////////////////////////////////////////////////////////
Map _pipelines = {}; // <texture_id, bool>
Map _widgetStates = {}; // <_VideoWidget, _VideoWidgetState>

enum TimerStage { init, clearRect, setRect }

class _VideoWidget extends StatefulWidget {
  final int textureId;
  final VideoPlayerWebOs player;
  const _VideoWidget({required this.textureId, required this.player});

  @override
  State<_VideoWidget> createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<_VideoWidget> {
  final GlobalKey _videoBoxKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _widgetStates[widget] = this;
    WidgetsBinding.instance.addPostFrameCallback(_afterFrameLayout);
  }

  @override
  Widget build(BuildContext context) {
    bool ready = _pipelines.containsKey(widget.textureId);
    if (!ready) {
      _resetRect(true);
      _exported = false;
    }
    return Container(
        key: _videoBoxKey,
        color: const Color(0xff000000),
        child: ready && _exported && !_moving ? const Hole() : Container());
  }

  void onPipelineChanged() {
    setState(() {});
  }

  void reExport() {
    _resetRect(true);
    setState(() {});
  }

  void _afterFrameLayout(_) {
    bool ready = _pipelines.containsKey(widget.textureId);
    final box = _videoBoxKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      if (ready) {
        final pos = box.localToGlobal(Offset.zero);
        double x = pos.dx;
        double y = pos.dy;
        double w = box.size.width;
        double h = box.size.height;
        if (!x.isNaN && !y.isNaN) {
          _rectChanged(x, y, w, h);
        }
      } else {
        _resetRect(true);
        _exported = false;
        setState(() {});
      }
    }
    WidgetsBinding.instance.addPostFrameCallback(_afterFrameLayout);
  }

  final int kMovingTimerMiliseconds = 100;
  TimerStage _timerStage = TimerStage.init;
  bool _moving = false;
  double _x = 0;
  double _y = 0;
  double _w = 0;
  double _h = 0;
  Timer? _timer;
  bool _dirty = false;
  bool _exported = false;

  void _resetRect(bool deep) {
    _timerStage = TimerStage.init;
    _moving = false;
    if (deep) {
      _x = 0;
      _y = 0;
      _w = 0;
      _h = 0;
    }
    _timer?.cancel();
    _timer = null;
    _dirty = false;
  }

  void _rectChanged(double x, double y, double w, double h) {
    if (x == _x && y == _y && w == _w && h == _h) {
      return;
    }

    _x = x;
    _y = y;
    _w = w;
    _h = h;

    if (_timer != null) {
      _dirty = true;
      return;
    }

    _resetRect(false);
    _moving = true;
    if (!_exported) {
      _timerStage = TimerStage.setRect;
      _exported = true;
      widget.player.viewRect(widget.textureId, _x, _y, _w, _h);
    }
    setState(() {});

    _timer =
        Timer.periodic(Duration(milliseconds: kMovingTimerMiliseconds), (_) {
      if (_dirty) {
        _dirty = false;
        _timerStage = TimerStage.clearRect;
      } else {
        if (_timerStage != TimerStage.setRect) {
          _timerStage = TimerStage.setRect;
          _exported = true;
          widget.player.viewRect(widget.textureId, _x, _y, _w, _h);
        } else {
          _resetRect(false);
          setState(() {});
        }
      }
    });
  }
} // end of class

/////////////////////////////////////////////////////////////////////
////                   VideoPlayerPlatform                       ////
/////////////////////////////////////////////////////////////////////
final _windowChannel = const MethodChannel('webos/exported_windows');
final _auxChannel = const MethodChannel('videoplayer_webos');
Map _windowIds = {}; //<texture_id, window_id>
Map _widgets = {}; //<texture_id, _VideoWidget>
bool _hidden = false;

class _LifeCycleObserver {
  final _auxEventChannel = const EventChannel('webos/video_player/events');
  static AppLifecycleState _lifeState = AppLifecycleState.inactive;
  static StreamSubscription? _eventStreamSubscription;

  void initialize() {
    _eventStreamSubscription ??= _getEventStream().listen((_) {});
  }

  void _didChangeAppLifecycleState(AppLifecycleState state) async {
    if (_lifeState == state) {
      return;
    }

    _lifeState = state;

    if (_lifeState == AppLifecycleState.resumed) {
      _onResumed();
    } else if (_lifeState == AppLifecycleState.hidden) {
      _onHidden();
    }
  }

  Future<void> _onResumed() async {
    if (_hidden == true) {
      _hidden = false;

      // clone _windowIds
      Map winIds = {};
      _windowIds.forEach((texId, winId) async {
        winIds[texId] = winId;
      });

      winIds.forEach((texId, winId) async {
        if (winId == null) {
          String? windowId =
              await _windowChannel.invokeMethod<String>('create', {});
          _windowIds[texId] = windowId ?? 'invalid';

          _auxChannel.invokeMethod<void>('reload', {
            'textureId': texId,
            'windowId': windowId ?? 'invalid',
          });

          if (_widgets.containsKey(texId)) {
            _widgetStates[_widgets[texId]]?.reExport();
          }
        }
      });
    }
  }

  Future<void> _onHidden() async {
    if (_hidden == false) {
      _hidden = true;

      // clone _windowIds
      Map winIds = {};
      _windowIds.forEach((texId, winId) async {
        winIds[texId] = winId;
      });
      for (var texId in winIds.keys) {
        _windowIds[texId] = null;
      }

      winIds.forEach((texId, winId) async {
        _auxChannel.invokeMethod<void>('unload', {
          'textureId': texId,
        });
        if (winId != null) {
          _windowChannel.invokeMethod<void>('dispose', {
            'windowId': winId,
          });
        }
      });
    }
  }

  Stream<void> _getEventStream() {
    return _auxEventChannel.receiveBroadcastStream().map((dynamic event) {
      var map = event as Map<dynamic, dynamic>;
      var eventType = map['event'] as String;
      switch (eventType) {
        case 'appLifecycleState':
          {
            var state = map['state'] as String;
            if (state == 'AppLifecycleState.inactive' ||
                state == 'AppLifecycleState.resumed') {
              _didChangeAppLifecycleState(AppLifecycleState.resumed);
            } else if (state == 'AppLifecycleState.hidden') {
              _didChangeAppLifecycleState(AppLifecycleState.hidden);
            } else if (state == 'AppLifecycleState.paused') {
              _didChangeAppLifecycleState(AppLifecycleState.paused);
            } else if (state == 'AppLifecycleState.detached') {
              _didChangeAppLifecycleState(AppLifecycleState.detached);
            }
          }
          break;
        default:
          break;
      }
    });
  }
}

class VideoPlayerWebOs extends VideoPlayerPlatform {
  final WebOsVideoPlayerApi _api = WebOsVideoPlayerApi();
  final _lifeCycleObserver = _LifeCycleObserver();
  final Map _windowSizes = {}; // <texture_id, Size>

  /// Registers this class as the default platform instance.
  static void registerWith() {
    VideoPlayerPlatform.instance = VideoPlayerWebOs();
  }

  @override
  Future<void> init() {
    _lifeCycleObserver.initialize();
    return _api.initialize();
  }

  @override
  Future<void> dispose(int textureId) {
    _dispose(textureId);
    return _api.dispose(TextureMessage(textureId: textureId));
  }

  void _dispose(int textureId) async {
    if (_pipelines.containsKey(textureId)) {
      _pipelines.remove(textureId);
    }
    if (_widgets.containsKey(textureId)) {
      var w = _widgets[textureId];
      _widgetStates.remove(w);
      _widgets.remove(textureId);
    }

    if (_windowIds.containsKey(textureId)) {
      var winId = _windowIds[textureId];
      _windowIds.remove(textureId);
      _windowSizes.remove(textureId);

      // exported window dispose
      if (winId != null) {
        _windowChannel.invokeMethod<void>('dispose', {
          'windowId': winId,
        });
      }
    }
  }

  @override
  Future<int?> create(DataSource dataSource) async {
    String? asset;
    String? packageName;
    String? uri;
    String? formatHint;
    Map<Object?, Object?>? drmConfigs;
    Map<String, String> httpHeaders = <String, String>{};
    switch (dataSource.sourceType) {
      case DataSourceType.asset:
        asset = dataSource.asset;
        packageName = dataSource.package;
        break;
      case DataSourceType.network:
        uri = dataSource.uri;
        formatHint = _videoFormatStringMap[dataSource.formatHint];
        httpHeaders = dataSource.httpHeaders;
        drmConfigs = dataSource.drmConfigs?.toMap();
        break;
      case DataSourceType.file:
        uri = dataSource.uri;
        httpHeaders = dataSource.httpHeaders;
        break;
      case DataSourceType.contentUri:
        uri = dataSource.uri;
        break;
    }

    String? windowId = await _windowChannel.invokeMethod<String>('create', {});
    final CreateMessage message = CreateMessage(
      windowId: windowId ?? 'invalid',
      asset: asset,
      packageName: packageName,
      uri: uri,
      httpHeaders: httpHeaders,
      formatHint: formatHint,
      drmConfigs: drmConfigs,
    );

    final TextureMessage response = await _api.create(message);

    // exported window create
    _windowIds[response.textureId] = windowId;
    _windowSizes[response.textureId] = Size(0, 0);

    if (_hidden) {
      _windowIds[response.textureId] = null;
      if (windowId != null) {
        _auxChannel.invokeMethod<void>('unload', {
          'textureId': response.textureId,
        });

        _windowChannel.invokeMethod<void>('dispose', {
          'windowId': windowId,
        });
      }
    }
    return response.textureId;
  }

  @override
  Future<void> setLooping(int textureId, bool looping) {
    return _api.setLooping(LoopingMessage(
      textureId: textureId,
      isLooping: looping,
    ));
  }

  @override
  Future<void> play(int textureId) {
    return _api.play(TextureMessage(textureId: textureId));
  }

  @override
  Future<void> pause(int textureId) {
    return _api.pause(TextureMessage(textureId: textureId));
  }

  @override
  Future<void> setVolume(int textureId, double volume) {
    return _api.setVolume(VolumeMessage(
      textureId: textureId,
      volume: volume,
    ));
  }

  @override
  Future<void> setPlaybackSpeed(int textureId, double speed) {
    assert(speed > 0);

    return _api.setPlaybackSpeed(PlaybackSpeedMessage(
      textureId: textureId,
      speed: speed,
    ));
  }

  @override
  Future<void> seekTo(int textureId, Duration position) {
    return _api.seekTo(PositionMessage(
      textureId: textureId,
      position: position.inMilliseconds,
    ));
  }

  @override
  Future<Duration> getPosition(int textureId) async {
    final PositionMessage response =
        await _api.position(TextureMessage(textureId: textureId));
    return Duration(milliseconds: response.position);
  }

  @override
  Stream<VideoEvent> videoEventsFor(int textureId) {
    return _eventChannelFor(textureId)
        .receiveBroadcastStream()
        .map((dynamic event) {
      final Map<dynamic, dynamic> map = event as Map<dynamic, dynamic>;
      switch (map['event']) {
        case 'initialized':
          Size size = Size((map['width'] as num?)?.toDouble() ?? 0.0,
              (map['height'] as num?)?.toDouble() ?? 0.0);
          // exported window set Size
          _windowSizes[textureId] = size;
          final audioTracks = (map['audioTracks'] as List<dynamic>?)
              ?.map((t) => Map<String, dynamic>.from(t as Map))
              .toList();
          final subtitleTracks = (map['subtitleTracks'] as List<dynamic>?)
              ?.map((t) => Map<String, dynamic>.from(t as Map))
              .toList();
          return VideoEvent(
            eventType: VideoEventType.initialized,
            duration: Duration(milliseconds: map['duration'] as int),
            size: size,
            rotationCorrection: map['rotationCorrection'] as int? ?? 0,
            audioTracks: audioTracks,
            subtitleTracks: subtitleTracks,
          );
        case 'completed':
          return VideoEvent(
            eventType: VideoEventType.completed,
          );
        case 'bufferingUpdate':
          final List<dynamic> values = map['values'] as List<dynamic>;

          return VideoEvent(
            buffered: values.map<DurationRange>(_toDurationRange).toList(),
            eventType: VideoEventType.bufferingUpdate,
          );
        case 'bufferingStart':
          return VideoEvent(eventType: VideoEventType.bufferingStart);
        case 'bufferingEnd':
          return VideoEvent(eventType: VideoEventType.bufferingEnd);
        case 'isPlayingStateUpdate':
          return VideoEvent(
            eventType: VideoEventType.isPlayingStateUpdate,
            isPlaying: map['isPlaying'] as bool,
          );

        case 'trackSelected':
          final trackType = map['trackType'];
          final trackIndex = map['trackIndex'];
          return VideoEvent(
            eventType: VideoEventType.trackSelected,
            trackSelectedType: trackType?.toString(),
            trackSelectedIndex:
                trackIndex is int ? trackIndex : (trackIndex as num?)?.toInt(),
          );

        // webOS Custom Events
        case 'onLoaded':
          _pipelines[textureId] = true;
          if (_widgets.containsKey(textureId)) {
            _widgetStates[_widgets[textureId]]?.onPipelineChanged();
          }
          return VideoEvent(eventType: VideoEventType.unknown);

        case 'onUnloaded':
          if (_pipelines.containsKey(textureId)) {
            _pipelines.remove(textureId);
          }
          if (_widgets.containsKey(textureId)) {
            _widgetStates[_widgets[textureId]]?.onPipelineChanged();
          }
          return VideoEvent(eventType: VideoEventType.unknown);

        case 'onError':
          _dispose(textureId);
          return VideoEvent(eventType: VideoEventType.unknown);

        default:
          return VideoEvent(eventType: VideoEventType.unknown);
      }
    });
  }

  @override
  Widget buildView(int textureId) {
    Widget widget = _VideoWidget(textureId: textureId, player: this);
    _widgets[textureId] = widget;
    return widget;
  }

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) {
    return _api
        .setMixWithOthers(MixWithOthersMessage(mixWithOthers: mixWithOthers));
  }

  @override
  Future<void> selectTrack(int textureId, String type, int index) {
    return _api.selectTrack(TrackMessage(
      textureId: textureId,
      trackType: type,
      trackIndex: index,
    ));
  }

  @override
  Future<void> setSubtitleEnable(int textureId, bool enable) {
    return _api.setSubtitleEnable(SubtitleEnableMessage(
      textureId: textureId,
      enable: enable,
    ));
  }

  @override
  Future<void> setSubtitleSync(int textureId, int offset) {
    return _api.setSubtitleSync(SubtitleSyncMessage(
      textureId: textureId,
      offset: offset,
    ));
  }

  EventChannel _eventChannelFor(int textureId) {
    return EventChannel('flutter.io/videoPlayer/videoEvents$textureId');
  }

  Future<void> viewRect(int textureId, double x, double y, double w, double h) {
    var windowId = _windowIds[textureId] ?? 'invalid';
    var size = _windowSizes[textureId] ?? Size(0, 0);

    if (size.width == 0 && size.height == 0) {
      return _windowChannel.invokeMethod<void>('resize', {
        'windowId': windowId,
        'srcRect': [x.round(), y.round(), w.round(), h.round()],
      });
    }

    return _windowChannel.invokeMethod<void>('resize', {
      'windowId': windowId,
      'srcRect': [0, 0, size.width.round(), size.height.round()],
      'dstRect': [x.round(), y.round(), w.round(), h.round()],
    });
  }

  static const Map<VideoFormat, String> _videoFormatStringMap =
      <VideoFormat, String>{
    VideoFormat.ss: 'ss',
    VideoFormat.hls: 'hls',
    VideoFormat.dash: 'dash',
    VideoFormat.other: 'other',
  };

  DurationRange _toDurationRange(dynamic value) {
    final List<dynamic> pair = value as List<dynamic>;
    return DurationRange(
      Duration(milliseconds: pair[0] as int),
      Duration(milliseconds: pair[1] as int),
    );
  }
}
