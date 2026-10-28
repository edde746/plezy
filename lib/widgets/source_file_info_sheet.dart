import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path/path.dart' as p;

import '../i18n/strings.g.dart';
import '../media/media_file_info.dart';
import '../mpv/mpv.dart';
import '../i18n/presentation_formats.dart';
import 'bottom_sheet_page_scaffold.dart';
import 'file_info_bottom_sheet.dart';
import 'overlay_sheet.dart';

/// Direct MPV inputs do not have a media-server lookup for the shared File
/// Info sheet. Build the same media model from the properties and track table
/// the open player already exposes.
class SourceFileInfoSheet extends StatefulWidget {
  const SourceFileInfoSheet({super.key, required this.player, required this.title});

  final Player player;
  final String title;

  @override
  State<SourceFileInfoSheet> createState() => _SourceFileInfoSheetState();
}

class _SourceFileInfoSheetState extends State<SourceFileInfoSheet> {
  late final Future<MediaFileInfo?> _load;

  @override
  void initState() {
    super.initState();
    _load = _readFileInfo();
    unawaited(_refocusWhenLoaded());
  }

  Future<void> _refocusWhenLoaded() async {
    await _load;
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) OverlaySheetController.maybeOf(context)?.refocus();
    });
  }

  static const _propertyNames = [
    'file-format',
    'file-size',
    'duration',
    'video-params/w',
    'video-params/h',
    'video-params/aspect',
    'video-params/pixelformat',
    'video-params/colormatrix',
    'video-params/colorlevels',
    'video-params/primaries',
    'video-params/gamma',
    'video-codec',
    'video-profile',
    'container-fps',
    'video-bitrate',
    'audio-codec-name',
    'audio-profile',
    'audio-params/samplerate',
    'audio-params/channels',
    'audio-params/hr-channels',
    'audio-bitrate',
    'current-tracks/video/codec-profile',
  ];

  Future<MediaFileInfo?> _readFileInfo() async {
    final values = await Future.wait(
      _propertyNames.map((name) async {
        try {
          return await widget.player.getProperty(name);
        } on Object {
          // Individual properties are optional across MPV builds and inputs.
          return null;
        }
      }),
    );
    final properties = Map<String, String?>.fromIterables(_propertyNames, values);
    String? text(String name) {
      final value = properties[name]?.trim();
      if (value == null || value.isEmpty || value == 'N/A' || value == 'unknown') {
        return null;
      }
      return isolateDisplayText(value);
    }

    int? integer(String name) {
      final value = double.tryParse(properties[name] ?? '');
      if (value == null || !value.isFinite || value <= 0 || value > 0x7fffffffffffffff) {
        return null;
      }
      return value.round();
    }

    double? number(String name) {
      final value = double.tryParse(properties[name] ?? '');
      return value != null && value.isFinite && value > 0 ? value : null;
    }

    int? kbps(String name) {
      final bitsPerSecond = number(name);
      if (bitsPerSecond == null || bitsPerSecond / 1000 > 0x7fffffffffffffff) {
        return null;
      }
      return (bitsPerSecond / 1000).round();
    }

    final state = widget.player.state;
    final tracks = <MediaStreamDetails>[];
    for (var index = 0; index < state.tracks.video.length; index++) {
      final track = state.tracks.video[index];
      tracks.add(
        MediaStreamDetails(
          kind: MediaStreamKind.video,
          ordinal: index + 1,
          id: track.id,
          index: int.tryParse(track.id),
          title: track.title == null ? null : isolateDisplayText(track.title!),
          language: track.language == null ? null : isolateDisplayText(track.language!),
          codec: track.codec == null ? null : isolateDisplayText(track.codec!),
          isDefault: track.isDefault,
          isSelected: track.isSelected,
          isExternal: track.isExternal,
          width: track.width,
          height: track.height,
          bitrateKbps: track.isSelected ? kbps('video-bitrate') : null,
          frameRate: track.isSelected ? number('container-fps') : null,
          pixelFormat: track.isSelected ? text('video-params/pixelformat') : null,
          colorSpace: track.isSelected ? text('video-params/colormatrix') : null,
          colorRange: track.isSelected ? text('video-params/colorlevels') : null,
          colorPrimaries: track.isSelected ? text('video-params/primaries') : null,
          colorTransfer: track.isSelected ? text('video-params/gamma') : null,
        ),
      );
    }
    for (var index = 0; index < state.tracks.audio.length; index++) {
      final track = state.tracks.audio[index];
      tracks.add(
        MediaStreamDetails(
          kind: MediaStreamKind.audio,
          ordinal: index + 1,
          id: track.id,
          index: int.tryParse(track.id),
          title: track.title == null ? null : isolateDisplayText(track.title!),
          language: track.language == null ? null : isolateDisplayText(track.language!),
          codec: track.codec == null ? null : isolateDisplayText(track.codec!),
          profile: track.codecProfile == null ? null : isolateDisplayText(track.codecProfile!),
          bitrateKbps: track.bitrate == null || track.bitrate! <= 0
              ? (track.id == state.track.audio?.id ? kbps('audio-bitrate') : null)
              : (track.bitrate! / 1000).round(),
          channels: track.channels ?? (track.id == state.track.audio?.id ? integer('audio-params/channels') : null),
          channelLayout: track.id == state.track.audio?.id ? text('audio-params/hr-channels') : null,
          sampleRate:
              track.sampleRate ?? (track.id == state.track.audio?.id ? integer('audio-params/samplerate') : null),
          isDefault: track.isDefault,
          isForced: track.isForced,
          isSelected: track.id == state.track.audio?.id,
        ),
      );
    }
    for (var index = 0; index < state.tracks.subtitle.length; index++) {
      final track = state.tracks.subtitle[index];
      tracks.add(
        MediaStreamDetails(
          kind: MediaStreamKind.subtitle,
          ordinal: index + 1,
          id: track.id,
          index: int.tryParse(track.id),
          title: track.title == null ? null : isolateDisplayText(track.title!),
          language: track.language == null ? null : isolateDisplayText(track.language!),
          codec: track.codec == null ? null : isolateDisplayText(track.codec!),
          isDefault: track.isDefault,
          isForced: track.isForced,
          isExternal: track.isExternal,
          isSelected: track.id == state.track.subtitle?.id || track.id == state.track.secondarySubtitle?.id,
        ),
      );
    }

    final selectedVideo = state.tracks.video.where((track) => track.isSelected).firstOrNull;
    final selectedAudio = state.track.audio;
    final width = integer('video-params/w') ?? selectedVideo?.width;
    final height = integer('video-params/h') ?? selectedVideo?.height;
    final aspect = number('video-params/aspect');
    final durationSeconds = number('duration');
    final durationMs = durationSeconds == null || durationSeconds * 1000 > 0x7fffffffffffffff
        ? null
        : (durationSeconds * 1000).round();
    final frameRate = number('container-fps');
    final fileFormat = text('file-format');
    final videoCodec = text('video-codec') ?? selectedVideo?.codec;
    final audioCodec = text('audio-codec-name') ?? selectedAudio?.codec;
    final videoProfile = text('video-profile') ?? text('current-tracks/video/codec-profile');
    final audioProfile = text('audio-profile') ?? selectedAudio?.codecProfile;
    final fileSize = integer('file-size');
    final container = fileFormat ?? _containerFromTitle(widget.title);
    final videoBitrate = kbps('video-bitrate');
    final audioBitrate = kbps('audio-bitrate');
    final hasVideo = state.tracks.video.isNotEmpty || videoCodec != null;
    final hasAudio = state.tracks.audio.isNotEmpty || audioCodec != null;
    final overallBitrate = switch ((hasVideo, hasAudio)) {
      (true, true) when videoBitrate != null && audioBitrate != null => videoBitrate + audioBitrate,
      (true, false) => videoBitrate,
      (false, true) => audioBitrate,
      _ => null,
    };

    final hasInformation =
        container != null ||
        fileSize != null ||
        durationMs != null ||
        width != null ||
        height != null ||
        videoCodec != null ||
        audioCodec != null ||
        tracks.isNotEmpty;
    if (!hasInformation) return null;

    final part = MediaFilePart(fileSize: fileSize, container: container, durationMs: durationMs, streams: tracks);
    final version = MediaFileVersion(
      container: container,
      bitrateKbps: overallBitrate,
      durationMs: durationMs,
      width: width,
      height: height,
      aspectRatio: aspect,
      videoCodec: videoCodec == null ? null : isolateDisplayText(videoCodec),
      videoProfile: videoProfile == null ? null : isolateDisplayText(videoProfile),
      videoFrameRateLabel: frameRate == null ? null : _frameRateLabel(frameRate),
      audioCodec: audioCodec == null ? null : isolateDisplayText(audioCodec),
      audioProfile: audioProfile == null ? null : isolateDisplayText(audioProfile),
      audioChannels: selectedAudio?.channels ?? integer('audio-params/channels'),
      parts: [part],
    );
    return MediaFileInfo(versions: [version]);
  }

  String? _containerFromTitle(String title) {
    final source = Uri.tryParse(title.trim());
    if (source?.hasScheme == true && source!.path.isEmpty) return null;
    final safeName = source?.hasScheme == true && !_looksLikeWindowsPath(title)
        ? p.basename(source!.path)
        : _safeTitle(title);
    final extension = p.extension(safeName).replaceFirst('.', '').toLowerCase();
    return extension.isEmpty ? null : extension;
  }

  String _safeTitle(String title) {
    final value = title.trim();
    if (_looksLikeWindowsPath(value)) return isolateDisplayText(_portableBasename(value));
    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme) {
      final name = p.basename(uri.path);
      return isolateDisplayText(name.isNotEmpty && name != '/' ? name : uri.host);
    }
    if (p.isAbsolute(value) || value.contains('/') || value.contains('\\')) {
      return isolateDisplayText(_portableBasename(value));
    }
    return isolateDisplayText(value);
  }

  bool _looksLikeWindowsPath(String value) => RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(value) || value.startsWith(r'\\');

  String _portableBasename(String value) =>
      value.replaceAll('\\', '/').split('/').where((part) => part.isNotEmpty).lastOrNull ?? '';

  String _frameRateLabel(double value) => value == value.roundToDouble()
      ? '${value.toInt()} fps'
      : '${value.toStringAsFixed(3).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')} fps';

  @override
  Widget build(BuildContext context) => FutureBuilder<MediaFileInfo?>(
    future: _load,
    builder: (context, snapshot) {
      final fileInfo = snapshot.data;
      if (snapshot.connectionState == ConnectionState.done && fileInfo != null) {
        return FileInfoBottomSheet(fileInfo: fileInfo, title: _safeTitle(widget.title));
      }
      final loading = snapshot.connectionState != ConnectionState.done;
      return BottomSheetPageScaffold(
        title: t.fileInfo.title,
        icon: Symbols.info_rounded,
        showHeaderBorder: false,
        child: SizedBox(
          height: 160,
          child: Center(
            child: loading
                ? const CircularProgressIndicator()
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(t.messages.fileInfoNotAvailable, textAlign: TextAlign.center),
                  ),
          ),
        ),
      );
    },
  );
}
