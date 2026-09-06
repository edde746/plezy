import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_file_info.dart';
import 'package:plezy/models/transcode_quality_preset.dart';
import 'package:plezy/services/downloaded_file_info_service.dart';

void main() {
  test('describes the local Plex transcode instead of its server source', () async {
    final directory = await Directory.systemTemp.createTemp('plezy-file-info-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/episode.mkv');
    await file.writeAsBytes(List<int>.filled(150000, 0));

    final info = await getTranscodedDownloadFileInfo(
      filePath: file.path,
      qualityPreset: TranscodeQualityPreset.p240_320,
      durationMs: 60000,
    );

    expect(info, isNotNull);
    final version = info!.versions.single;
    final part = version.parts.single;
    expect(version.container, 'mkv');
    expect(version.videoResolutionLabel, '240p');
    expect(version.videoCodec, 'h264');
    expect(version.audioCodec, 'aac');
    expect(version.bitrateKbps, 20);
    expect(part.filePath, file.path);
    expect(part.fileSize, 150000);
    expect(part.streams.map((stream) => stream.kind), [MediaStreamKind.video, MediaStreamKind.audio]);
  });

  test('does not replace Original file metadata', () async {
    expect(
      await getTranscodedDownloadFileInfo(
        filePath: '/unused/original.mkv',
        qualityPreset: TranscodeQualityPreset.original,
      ),
      isNull,
    );
  });
}
