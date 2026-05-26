import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/i18n/strings.g.dart';
import 'package:vibe_stream/mixins/refreshable.dart';
import 'package:vibe_stream/screens/search_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testWidgets('stale callbacks are no-ops after SearchScreen is disposed', (tester) async {
    final key = GlobalKey<State<SearchScreen>>();

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(home: SearchScreen(key: key)),
      ),
    );

    final state = key.currentState!;
    final searchInput = state as SearchInputFocusable;
    searchInput.setSearchQuery('movie');
    await tester.pump();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(() => (state as Refreshable).refresh(), returnsNormally);
    expect(() => (state as dynamic).updateItem('movie_1'), returnsNormally);
    expect(() => (state as FullRefreshable).fullRefresh(), returnsNormally);
    expect(() => searchInput.setSearchQuery('new movie'), returnsNormally);
    expect(() => (state as FocusableTab).focusActiveTabIfReady(), returnsNormally);
    expect(tester.takeException(), isNull);
  });
}
