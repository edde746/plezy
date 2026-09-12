import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/models/transcode_quality_preset.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/utils/download_utils.dart';
import 'package:plezy/utils/quality_preset_labels.dart';
import 'package:plezy/widgets/focusable_list_tile.dart';

import '../test_helpers/prefs.dart';

class _QualityClient implements MediaServerClient, QualityDownloadMediaServerClient {
  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RegularClient implements MediaServerClient {
  @override
  MediaBackend get backend => MediaBackend.jellyfin;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() => LocaleSettings.setLocaleSync(AppLocale.en));

  setUp(() {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
  });

  test('episode count validation returns a localized message for invalid input', () {
    expect(validateEpisodeCountInput('', allowZero: false), t.downloads.invalidEpisodeCount);
    expect(validateEpisodeCountInput('0', allowZero: false), t.downloads.invalidEpisodeCount);
    expect(validateEpisodeCountInput('not-a-number', allowZero: true), t.downloads.invalidEpisodeCount);
  });

  test('episode count validation accepts zero only when requested', () {
    expect(validateEpisodeCountInput('0', allowZero: true), isNull);
    expect(validateEpisodeCountInput('12', allowZero: false), isNull);
  });

  testWidgets('Plex manual quality picker offers System and explicit presets', (tester) async {
    DownloadQualitySelection? selection;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              selection = await pickDownloadQualityForClient(context, _QualityClient());
            },
            child: const Text('Pick'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Pick'));
    await tester.pumpAndSettle();

    expect(find.text('System (Original)'), findsOneWidget);
    expect(find.text('Original'), findsOneWidget);
    expect(find.text('720p 3 Mbps'), findsOneWidget);
    final systemRow = find.ancestor(of: find.text('System (Original)'), matching: find.byType(FocusableListTile));
    expect(find.descendant(of: systemRow, matching: find.byIcon(Symbols.check_rounded)), findsOneWidget);

    await tester.tap(find.text('720p 3 Mbps'));
    await tester.pumpAndSettle();
    expect(selection?.override, TranscodeQualityPreset.p720_3mbps);
  });

  testWidgets('download quality picker marks an existing explicit override', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDownloadQualityPickerDialog(
              context,
              defaultPreset: TranscodeQualityPreset.original,
              currentOverride: TranscodeQualityPreset.p720_3mbps,
            ),
            child: const Text('Pick'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Pick'));
    await tester.pumpAndSettle();

    final selectedRow = find.ancestor(of: find.text('720p 3 Mbps'), matching: find.byType(FocusableListTile));
    final systemRow = find.ancestor(of: find.text('System (Original)'), matching: find.byType(FocusableListTile));
    expect(find.descendant(of: selectedRow, matching: find.byIcon(Symbols.check_rounded)), findsOneWidget);
    expect(find.descendant(of: systemRow, matching: find.byIcon(Symbols.check_rounded)), findsNothing);
  });

  testWidgets('non-Plex clients keep the existing download flow without a quality dialog', (tester) async {
    DownloadQualitySelection? selection;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              selection = await pickDownloadQualityForClient(context, _RegularClient());
            },
            child: const Text('Download'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Download'));
    await tester.pump();

    expect(find.byType(AlertDialog), findsNothing);
    expect(selection, isNotNull);
    expect(selection?.override, isNull);
  });
}
