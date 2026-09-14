// Measurement harness entrypoint. NOT part of the app.
//
// Drives the real PlayerLinux/mpv/Video rendering path with a local file so
// the compositing cost can be measured without a Plex server. Build with:
//   flutter build linux --target=lib/dev/harness_main.dart
// Run with:
//   PLEZY_HARNESS_MEDIA=/path/to/file.mp4 PLEZY_HARNESS_SECONDS=40 ./plezy
//
// Optional knobs:
//   PLEZY_HARNESS_MPV_LOG=v|debug             mpv's own log stream
//   PLEZY_HARNESS_MPV_PROPS=name=value,...     arbitrary mpv properties, so an
//                                             option can be swept without a
//                                             rebuild for each value
//   PLEZY_HARNESS_HDR=1                       request HDR passthrough
//   PLEZY_HARNESS_TONEMAP=compositor|player   which side tone-maps; the A/B leg
//   PLEZY_HARNESS_INSET=<px>                  toggles a padding every 6s, so the
//                                             plane has to move, not just resize
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../mpv/models.dart';
import '../mpv/player/player.dart';
import '../mpv/video.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _HarnessApp());
}

class _HarnessApp extends StatefulWidget {
  const _HarnessApp();

  @override
  State<_HarnessApp> createState() => _HarnessAppState();
}

class _HarnessAppState extends State<_HarnessApp> {
  Player? _player;
  String _status = 'starting';

  int _frames = 0;
  int _buildUs = 0;
  int _rasterUs = 0;
  final Stopwatch _clock = Stopwatch()..start();
  Timer? _reportTimer;
  Timer? _probeTimer;
  Timer? _quitTimer;
  Timer? _insetTimer;
  double _inset = 0;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback(_onFrames);
    _reportTimer = Timer.periodic(const Duration(seconds: 2), (_) => _report());
    _probeTimer = Timer.periodic(const Duration(seconds: 2), (_) => _probe());

    final seconds = int.tryParse(Platform.environment['PLEZY_HARNESS_SECONDS'] ?? '');
    if (seconds != null && seconds > 0) {
      _quitTimer = Timer(Duration(seconds: seconds), () {
        _report();
        stdout.writeln('HARNESS_DONE');
        exit(0);
      });
    }
    final inset = double.tryParse(Platform.environment['PLEZY_HARNESS_INSET'] ?? '');
    if (inset != null && inset > 0) {
      _insetTimer = Timer.periodic(const Duration(seconds: 6), (_) {
        setState(() => _inset = _inset == 0 ? inset : 0);
        stdout.writeln('HARNESS_INSET $_inset');
      });
    }
    _start();
  }

  void _onFrames(List<FrameTiming> timings) {
    for (final t in timings) {
      _frames++;
      _buildUs += t.buildDuration.inMicroseconds;
      _rasterUs += t.rasterDuration.inMicroseconds;
    }
  }

  void _report() {
    final n = _frames;
    final secs = _clock.elapsedMilliseconds / 1000.0;
    final fps = secs > 0 ? n / secs : 0.0;
    final build = n > 0 ? (_buildUs / n / 1000.0) : 0.0;
    final raster = n > 0 ? (_rasterUs / n / 1000.0) : 0.0;
    stdout.writeln(
      'FRAMESTAT t=${secs.toStringAsFixed(1)} frames=$n '
      'fps=${fps.toStringAsFixed(2)} build_ms=${build.toStringAsFixed(2)} '
      'raster_ms=${raster.toStringAsFixed(2)}',
    );
    _frames = 0;
    _buildUs = 0;
    _rasterUs = 0;
    _clock.reset();
  }

  // Independent of Flutter's frame loop: tells us whether mpv is actually
  // advancing even when nothing is being composited.
  Future<void> _probe() async {
    final player = _player;
    if (player == null) return;
    try {
      final pos = await player.getProperty('time-pos');
      final paused = await player.getProperty('pause');
      final dropped = await player.getProperty('frame-drop-count');
      final decoded = await player.getProperty('decoder-frame-drop-count');
      stdout.writeln('PROBE time-pos=$pos pause=$paused drops=$dropped dec_drops=$decoded');
    } catch (e) {
      stdout.writeln('PROBE_ERROR $e');
    }
  }

  // Which side tone-maps, and against what peak, is decided by mpv options that
  // leave no trace on screen: two very different curves look like "the video
  // plane works". Reading the effective values back is the only way to tell a
  // deliberate target from a default nobody chose - and the render API cannot
  // discover the display for itself the way a windowed mpv does, so the answer
  // here is not the answer `mpv` alone would give.
  //
  // Read after open() because the source-dependent ones are unset until a
  // format is known.
  Future<void> _reportColourState(Player player, String when) async {
    const names = <String>[
      'target-peak',
      'target-trc',
      'target-prim',
      'tone-mapping',
      'hdr-compute-peak',
      'video-params/gamma',
      'video-params/primaries',
      'video-params/sig-peak',
      'video-params/max-luma',
    ];
    final parts = <String>[];
    for (final name in names) {
      try {
        parts.add('$name=${await player.getProperty(name) ?? "-"}');
      } catch (_) {
        // The message is dropped rather than interpolated: this line is parsed
        // as space-separated name=value pairs, and an exception string carries
        // spaces of its own.
        parts.add('$name=<error>');
      }
    }
    stdout.writeln('HARNESS_COLOUR[$when] ${parts.join(' ')}');
  }

  // build() only shows _status while there is no player, and by this point one
  // has usually been assigned. Without clearing it a deliberate abort renders as
  // an empty transparent window, i.e. indistinguishable from a hang.
  Future<void> _abort(Player? player, String status) async {
    await player?.dispose();
    if (!mounted) return;
    setState(() {
      _player = null;
      _status = status;
    });
  }

  Future<void> _start() async {
    final media = Platform.environment['PLEZY_HARNESS_MEDIA'];
    if (media == null || media.isEmpty) {
      setState(() => _status = 'set PLEZY_HARNESS_MEDIA');
      return;
    }
    final uri = media.startsWith('/') ? 'file://$media' : media;
    try {
      final player = Player();
      setState(() => _player = player);
      final level = Platform.environment['PLEZY_HARNESS_MPV_LOG'];
      if (level != null && level.isNotEmpty) {
        await player.setLogLevel(level);
        stdout.writeln('HARNESS_MPV_LOG $level');
      }
      // Example: PLEZY_HARNESS_MPV_PROPS='tone-mapping=mobius,target-peak=200'.
      // Names the plugin intercepts (hdr-enabled, hdr-tone-mapping) also have
      // dedicated knobs, and those are applied *after* this block, so the
      // dedicated one wins if both name the same thing. Both writes are logged
      // and HARNESS_COLOUR[settled] reads the effective state back, so a capture
      // cannot be silently mislabelled either way.
      //
      // Applied before open(), so the first configured frame already has them.
      //
      // That timing is also the catch, and it has already produced a wrong
      // answer: the native side re-applies the whole output description on
      // playback-restart and on every seek, so anything it manages -
      // target-peak, target-prim, target-trc, tone-mapping - is overwritten
      // moments later. A sweep of those reads back as the shipped value while
      // looking perfectly plausible. Use this for properties the runner does not
      // set itself; for the ones it does, change the code.
      //
      // A malformed or rejected override aborts the leg, for the same reason
      // PLEZY_HARNESS_TONEMAP does: these captures get labelled with the value
      // that was asked for, and carrying on would file the default curve under
      // whatever was requested. A silently wrong label is worse than no capture.
      final props = Platform.environment['PLEZY_HARNESS_MPV_PROPS'];
      if (props != null && props.isNotEmpty) {
        for (final pair in props.split(',')) {
          final split = pair.indexOf('=');
          final name = split > 0 ? pair.substring(0, split).trim() : '';
          final value = split > 0 ? pair.substring(split + 1).trim() : '';
          String? failure;
          if (name.isEmpty || value.isEmpty) {
            failure = 'not name=value';
          } else {
            try {
              await player.setProperty(name, value);
              stdout.writeln('HARNESS_MPV_PROP $name=$value');
            } catch (e) {
              failure = '$e';
            }
          }
          if (failure != null) {
            stdout.writeln('HARNESS_MPV_PROP_ERROR $pair: $failure');
            await _abort(player, 'bad PLEZY_HARNESS_MPV_PROPS: $pair');
            return;
          }
        }
      }
      // Selected before hdr-enabled so the first description built already uses
      // the requested mode; the native side re-applies either way.
      //
      // A rejected value aborts instead of carrying on. This harness exists to
      // produce A/B photographs, and continuing in whatever mode happened to be
      // active would label the result with a leg that was never shown.
      final toneMapping = Platform.environment['PLEZY_HARNESS_TONEMAP'];
      if (toneMapping != null && toneMapping.isNotEmpty) {
        try {
          await player.setProperty('hdr-tone-mapping', toneMapping);
          stdout.writeln('HARNESS_TONEMAP $toneMapping');
        } catch (e) {
          stdout.writeln('HARNESS_TONEMAP_ERROR $e');
          await _abort(player, 'bad PLEZY_HARNESS_TONEMAP: $toneMapping');
          return;
        }
      }
      if (Platform.environment['PLEZY_HARNESS_HDR'] == '1') {
        try {
          await player.setProperty('hdr-enabled', 'yes');
          stdout.writeln('HARNESS_HDR requested');
        } catch (e) {
          stdout.writeln('HARNESS_HDR_ERROR $e');
        }
      }
      await player.open(Media(uri));
      stdout.writeln('HARNESS_OPENED $uri');
      // Twice, and the second one is the one that means anything. The native
      // side applies the output description from playback-restart, which has
      // not fired yet: reading only here reports the pre-HDR defaults and makes
      // a working transaction look like it never ran. The delayed read is the
      // independent check that mpv actually holds what the transaction logged
      // asking for - our own log says what was requested, not what landed.
      await _reportColourState(player, 'open');
      Timer(const Duration(seconds: 6), () async {
        if (!mounted || _player != player) return;
        await _reportColourState(player, 'settled');
      });
    } catch (e, st) {
      stdout.writeln('HARNESS_ERROR $e\n$st');
      await _abort(_player, 'error: $e');
    }
  }

  @override
  void dispose() {
    _reportTimer?.cancel();
    _probeTimer?.cancel();
    _quitTimer?.cancel();
    _insetTimer?.cancel();
    SchedulerBinding.instance.removeTimingsCallback(_onFrames);
    // Reported, not ignored: this harness exists to say what mpv did, and a
    // teardown that failed is part of that.
    if (_player case final player?) {
      unawaited(player.dispose().catchError((Object e) => stdout.writeln('HARNESS_DISPOSE_FAILED $e')));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = _player;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Transparent all the way down: in plane mode the video is a Wayland
      // subsurface *below* this surface, so anything opaque here hides it.
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: player == null
            ? Center(
                child: Text(_status, style: const TextStyle(color: Colors.white)),
              )
            : Padding(
                // The inset moves the plane to a non-zero origin, which a plain
                // window resize would never exercise.
                padding: EdgeInsets.all(_inset),
                child: Video(player: player, backgroundColor: Colors.transparent),
              ),
      ),
    );
  }
}
