import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/models/subtitles/subtitle_search_result.dart';
import 'package:plezy/screens/sources/standalone_subtitle_search_sheet.dart';
import 'package:plezy/services/open_subtitles_client.dart';
import 'package:plezy/utils/language_codes.dart';

class _SubtitleClient extends OpenSubtitlesClient {
  _SubtitleClient() : super(apiKey: 'test-key');
  final languages = <String>[];
  @override
  Future<List<SubtitleSearchResult>> search({
    required String query,
    required String languageCode,
    String? imdbId,
    String? tmdbId,
    int? year,
  }) async {
    languages.add(languageCode);
    return const [];
  }
}

void main() {
  testWidgets('Arabic subtitle search fits enlarged text and exposes Asian and regional choices', (tester) async {
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
    addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final client = _SubtitleClient();
    addTearDown(client.close);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(size: Size(390, 844), textScaler: TextScaler.linear(2)),
            child: StandaloneSubtitleSearchSheet(client: client, title: 'فيلم Movie', onApply: (_) async {}),
          ),
        ),
      ),
    );
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
    expect(client.languages, ['ar']);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    final picker = tester.widget<DropdownButtonFormField<String>>(find.byType(DropdownButtonFormField<String>));
    final dropdown = tester.widget<DropdownButton<String>>(find.byType(DropdownButton<String>));
    expect(picker.initialValue, 'ar');
    final values = dropdown.items!.map((item) => item.value).toSet();
    expect(values, containsAll(['ar', 'bn', 'hi', 'ja', 'ko', 'zh-cn', 'zh-tw', 'pt-br', 'pt-pt']));
    expect(
      dropdown.items!.firstWhere((item) => item.value == 'ja').child,
      isA<Text>().having((text) => text.data, 'localized language name', LanguageCodes.getDisplayName('ja')),
    );
    await tester.scrollUntilVisible(
      find.text(t.sourceSetup.subtitleNoMatches),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
  });
}
