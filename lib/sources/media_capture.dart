import 'dart:async';
import 'dart:convert';
import 'dart:io';

enum MediaCaptureKind { screen, camera }

class MediaCaptureAudioSource {
  const MediaCaptureAudioSource({required this.id, required this.name, required this.inputFormat, required this.input});

  final String id;
  final String name;
  final String inputFormat;
  final String input;

  List<String> get inputArguments => ['-f', inputFormat, '-i', input];
}

class MediaCaptureSource {
  const MediaCaptureSource({
    required this.id,
    required this.name,
    required this.kind,
    required this.inputFormat,
    required this.input,
    this.captureCursor = false,
  });

  final String id;
  final String name;
  final MediaCaptureKind kind;
  final String inputFormat;
  final String input;
  final bool captureCursor;

  List<String> inputArguments(int frameRate) => [
    if (captureCursor) ...['-draw_mouse', '1'],
    '-f',
    inputFormat,
    '-framerate',
    '$frameRate',
    '-i',
    input,
  ];
}

class DesktopMediaCapture {
  DesktopMediaCapture._();

  static Future<List<MediaCaptureAudioSource>> discoverAudio() async {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) return const [];
    String devices;
    try {
      devices = await _probe(const ['-hide_banner', '-devices']);
    } on Object {
      return const [];
    }
    if (Platform.isWindows && devices.contains('dshow')) {
      try {
        final listed = await _probe(const ['-hide_banner', '-list_devices', 'true', '-f', 'dshow', '-i', 'dummy']);
        return _parseDirectShowAudio(listed);
      } on Object {
        return const [];
      }
    }
    if (Platform.isMacOS && devices.contains('avfoundation')) {
      try {
        final listed = await _probe(const ['-hide_banner', '-f', 'avfoundation', '-list_devices', 'true', '-i', '']);
        return _parseAvFoundationAudio(listed);
      } on Object {
        return const [];
      }
    }
    if (Platform.isLinux && devices.contains('pulse')) {
      return const [
        MediaCaptureAudioSource(
          id: 'audio:pulse-default',
          name: 'Default microphone or audio input',
          inputFormat: 'pulse',
          input: 'default',
        ),
      ];
    }
    return const [];
  }

  static Future<List<MediaCaptureSource>> discover() async {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) return const [];

    String devices;
    try {
      devices = await _probe(const ['-hide_banner', '-devices']);
    } on Object {
      return const [];
    }

    if (Platform.isWindows) {
      final sources = _windowsSources(devices);
      if (!devices.contains('dshow')) return sources;
      try {
        final listed = await _probe(const ['-hide_banner', '-list_devices', 'true', '-f', 'dshow', '-i', 'dummy']);
        sources.addAll(_parseDirectShow(listed));
      } on Object {
        // Desktop capture remains available even if device enumeration is denied.
      }
      return sources;
    }
    if (Platform.isMacOS) {
      if (!devices.contains('avfoundation')) return const [];
      try {
        final listed = await _probe(const ['-hide_banner', '-f', 'avfoundation', '-list_devices', 'true', '-i', '']);
        return _parseAvFoundation(listed);
      } on Object {
        return const [];
      }
    }
    return _linuxSources(devices);
  }

  static List<MediaCaptureSource> _windowsSources(String deviceList) {
    final sources = <MediaCaptureSource>[];
    if (deviceList.contains('gdigrab')) {
      sources.add(
        const MediaCaptureSource(
          id: 'screen:desktop',
          name: 'Desktop screen',
          kind: MediaCaptureKind.screen,
          inputFormat: 'gdigrab',
          input: 'desktop',
          captureCursor: true,
        ),
      );
    }
    return sources;
  }

  static List<MediaCaptureSource> _parseDirectShow(String output) {
    final sources = <MediaCaptureSource>[];
    final seen = <String>{};
    final expression = RegExp(r'"(.+?)"\s+\(video\)\s*$');
    for (final line in output.split('\n')) {
      final match = expression.firstMatch(line);
      if (match == null) continue;
      final name = match.group(1)!.trim();
      if (name.isEmpty || !seen.add(name)) continue;
      sources.add(
        MediaCaptureSource(
          id: 'camera:$name',
          name: name,
          kind: MediaCaptureKind.camera,
          inputFormat: 'dshow',
          input: 'video="$name"',
        ),
      );
    }
    return sources;
  }

  static List<MediaCaptureAudioSource> _parseDirectShowAudio(String output) {
    final sources = <MediaCaptureAudioSource>[];
    final seen = <String>{};
    final expression = RegExp(r'"(.+?)"\s+\(audio\)\s*$');
    for (final line in output.split('\n')) {
      final match = expression.firstMatch(line);
      if (match == null) continue;
      final name = match.group(1)!.trim();
      if (name.isEmpty || !seen.add(name)) continue;
      sources.add(MediaCaptureAudioSource(id: 'audio:$name', name: name, inputFormat: 'dshow', input: 'audio="$name"'));
    }
    return sources;
  }

  static List<MediaCaptureSource> _parseAvFoundation(String output) {
    final sources = <MediaCaptureSource>[];
    var videoSection = false;
    final expression = RegExp(r'\[(\d+)\]\s+(.+?)(?:\s+\(UID:.*\))?$');
    for (final line in output.split('\n')) {
      if (line.contains('AVFoundation video devices')) {
        videoSection = true;
        continue;
      }
      if (line.contains('AVFoundation audio devices')) {
        videoSection = false;
        continue;
      }
      if (!videoSection) continue;
      final match = expression.firstMatch(line);
      if (match == null) continue;
      final index = match.group(1)!;
      final name = match.group(2)!.trim();
      final isScreen = name.toLowerCase().contains('screen');
      sources.add(
        MediaCaptureSource(
          id: '${isScreen ? 'screen' : 'camera'}:$index',
          name: name,
          kind: isScreen ? MediaCaptureKind.screen : MediaCaptureKind.camera,
          inputFormat: 'avfoundation',
          input: '$index:none',
        ),
      );
    }
    return sources;
  }

  static List<MediaCaptureAudioSource> _parseAvFoundationAudio(String output) {
    final sources = <MediaCaptureAudioSource>[];
    var audioSection = false;
    final expression = RegExp(r'\[(\d+)\]\s+(.+?)(?:\s+\(UID:.*\))?$');
    for (final line in output.split('\n')) {
      if (line.contains('AVFoundation audio devices')) {
        audioSection = true;
        continue;
      }
      if (line.contains('AVFoundation video devices')) {
        audioSection = false;
        continue;
      }
      if (!audioSection) continue;
      final match = expression.firstMatch(line);
      if (match == null) continue;
      final index = match.group(1)!;
      sources.add(
        MediaCaptureAudioSource(
          id: 'audio:$index',
          name: match.group(2)!.trim(),
          inputFormat: 'avfoundation',
          input: 'none:$index',
        ),
      );
    }
    return sources;
  }

  static List<MediaCaptureSource> _linuxSources(String deviceList) {
    final sources = <MediaCaptureSource>[];
    final display = Platform.environment['DISPLAY']?.trim();
    final wayland = Platform.environment['XDG_SESSION_TYPE']?.toLowerCase() == 'wayland';
    if (display != null && display.isNotEmpty && deviceList.contains('x11grab')) {
      sources.add(
        MediaCaptureSource(
          id: 'screen:$display',
          name: wayland ? 'XWayland display (limited capture)' : 'Desktop screen',
          kind: MediaCaptureKind.screen,
          inputFormat: 'x11grab',
          input: display,
          captureCursor: true,
        ),
      );
    }
    if (!deviceList.contains('video4linux2') && !deviceList.contains('v4l2')) return sources;
    try {
      final videoDevices = Directory('/dev').listSync(followLinks: false).where((entry) {
        final parts = entry.uri.pathSegments.where((part) => part.isNotEmpty).toList();
        final name = parts.isEmpty ? '' : parts.last;
        return RegExp(r'^video[0-9]+$').hasMatch(name);
      }).toList()..sort((a, b) => a.path.compareTo(b.path));
      for (final device in videoDevices) {
        final basename = device.uri.pathSegments.where((part) => part.isNotEmpty).last;
        final number = basename.substring('video'.length);
        var name = basename;
        final label = File('/sys/class/video4linux/$basename/name');
        if (label.existsSync()) {
          final value = label.readAsStringSync().trim();
          if (value.isNotEmpty) name = value;
        }
        sources.add(
          MediaCaptureSource(
            id: 'camera:$basename',
            name: '$name ($number)',
            kind: MediaCaptureKind.camera,
            inputFormat: 'v4l2',
            input: device.path,
          ),
        );
      }
    } on Object {
      // Device access can be denied even when capture support is compiled in.
    }
    return sources;
  }

  static Future<String> _probe(List<String> arguments) async {
    final process = await Process.start('ffmpeg', arguments, runInShell: false);
    final stdout = process.stdout.transform(utf8.decoder).join();
    final stderr = process.stderr.transform(utf8.decoder).join();
    final timer = Timer(const Duration(seconds: 8), () => process.kill());
    try {
      await process.exitCode;
      return '${await stdout}\n${await stderr}';
    } finally {
      timer.cancel();
    }
  }
}
