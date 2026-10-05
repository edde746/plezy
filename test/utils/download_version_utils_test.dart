import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/utils/download_version_utils.dart';
import 'package:plezy/utils/quality_preset_labels.dart';
import 'package:plezy/models/transcode_quality_preset.dart';

class _DownloadClient implements MediaServerClient {
  _DownloadClient(this.backend);

  @override
  final MediaBackend backend;

  @override
  Future<MediaItem?> fetchItem(String id) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() => LocaleSettings.setLocaleSync(AppLocale.en));

  Future<void> showPicker(
    WidgetTester tester, {
    MediaBackend backend = MediaBackend.plex,
    MediaKind kind = MediaKind.movie,
    TranscodeQualityPreset? quality,
    required ValueChanged<DownloadVersionConfig?> onResult,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => onResult(
                await resolveDownloadVersion(
                  context,
                  MediaItem(id: 'item', backend: backend, kind: kind),
                  _DownloadClient(backend),
                  quality: quality,
                ),
              ),
              child: const Text('Download'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Download'));
    await tester.pumpAndSettle();
  }

  testWidgets('Plex video picker keeps Original first and returns selected bitrate', (tester) async {
    DownloadVersionConfig? result;
    await showPicker(tester, onResult: (value) => result = value);
    expect(find.text(t.downloads.selectQuality), findsOneWidget);
    expect(find.text(t.downloads.preparationBackgroundHint), findsOneWidget);
    final original = find.text(qualityPresetLabel(TranscodeQualityPreset.original));
    final highest = find.text(qualityPresetLabel(TranscodeQualityPreset.p1080_20mbps));
    expect(tester.getTopLeft(original).dy, lessThan(tester.getTopLeft(highest).dy));
    final selected = find.text(qualityPresetLabel(TranscodeQualityPreset.p720_2mbps));
    await tester.ensureVisible(selected);
    await tester.tap(selected);
    await tester.pumpAndSettle();
    expect(result?.quality, TranscodeQualityPreset.p720_2mbps);
    expect(result?.mediaIndex, 0);
  });

  testWidgets('dismissing quality selection cancels the download', (tester) async {
    var completed = false;
    DownloadVersionConfig? result;
    await showPicker(
      tester,
      onResult: (value) {
        completed = true;
        result = value;
      },
    );
    await tester.tapAt(const Offset(2, 2));
    await tester.pumpAndSettle();
    expect(completed, isTrue);
    expect(result, isNull);
  });

  testWidgets('retry preserves the stored bitrate without another quality dialog', (tester) async {
    DownloadVersionConfig? result;
    await showPicker(tester, quality: TranscodeQualityPreset.p720_2mbps, onResult: (value) => result = value);
    expect(find.text(t.downloads.selectQuality), findsNothing);
    expect(result?.quality, TranscodeQualityPreset.p720_2mbps);
  });

  for (final backend in [MediaBackend.jellyfin, MediaBackend.emby]) {
    testWidgets('$backend downloads retain Original without a quality dialog', (tester) async {
      DownloadVersionConfig? result;
      await showPicker(tester, backend: backend, onResult: (value) => result = value);
      expect(find.text(t.downloads.selectQuality), findsNothing);
      expect(result?.quality, TranscodeQualityPreset.original);
    });
  }

  for (final kind in [MediaKind.track, MediaKind.album, MediaKind.artist, MediaKind.collection, MediaKind.playlist]) {
    testWidgets('$kind does not offer video conversion', (tester) async {
      DownloadVersionConfig? result;
      await showPicker(tester, kind: kind, onResult: (value) => result = value);
      expect(find.text(t.downloads.selectQuality), findsNothing);
      expect(result?.quality, TranscodeQualityPreset.original);
    });
  }
}
