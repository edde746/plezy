import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/screens/actor_media_screen.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:provider/provider.dart';

import '../test_helpers/multi_server_fixtures.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));

  testWidgets('opening a cast member whose server is unavailable shows the load error', (tester) async {
    final multi = testMultiServer();

    await tester.pumpWidget(
      TranslationProvider(
        child: ChangeNotifierProvider<MultiServerProvider>.value(
          value: multi.provider,
          child: MaterialApp(
            theme: monoTheme(dark: true),
            home: const ActorMediaScreen(
              actorName: 'Jane Doe',
              personId: 'person_1',
              serverId: 'server_1',
              backend: MediaBackend.jellyfin,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text(t.errors.unableToLoad(context: 'Jane Doe')), findsOneWidget);
  });
}
