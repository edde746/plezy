import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/library_query.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/person_details.dart';
import 'package:plezy/media/server_capabilities.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/screens/actor_media_screen.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/formatters.dart';
import 'package:plezy/utils/media_server_http_client.dart';
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

  Future<void> pumpActorScreen(
    WidgetTester tester,
    MultiServerProvider provider, {
    required MediaBackend backend,
  }) async {
    await tester.pumpWidget(
      TranslationProvider(
        child: ChangeNotifierProvider<MultiServerProvider>.value(
          value: provider,
          child: MaterialApp(
            theme: monoTheme(dark: true),
            home: ActorMediaScreen(
              actorName: 'John Garfield',
              personId: 'person_1',
              personTagKey: '5d77682aeb5d26001f1de4b0',
              serverId: 'server_1',
              backend: backend,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('shows the birth, death and biography the server knows', (tester) async {
    final client = _PersonClient(
      details: const PersonDetails(
        overview: 'An American actor.',
        birthDate: '1913-03-04',
        deathDate: '1952-05-21',
        birthPlace: 'Manhattan, New York City',
      ),
    );
    final multi = testMultiServer(clients: [client]);

    await pumpActorScreen(tester, multi.provider, backend: MediaBackend.jellyfin);

    expect(tester.takeException(), isNull);
    expect(client.requestedPersonIds, ['person_1']);
    expect(find.text('Born'), findsOneWidget);
    expect(find.text('${formatFullDate('1913-03-04')} · Manhattan, New York City'), findsOneWidget);
    expect(find.text('Died'), findsOneWidget);
    expect(find.text('${formatFullDate('1952-05-21')} (aged 39)'), findsOneWidget);
    expect(find.text('An American actor.'), findsOneWidget);
  });

  testWidgets('shows only the birthplace when the birth date is unknown', (tester) async {
    final client = _PersonClient(details: const PersonDetails(birthPlace: 'Memphis, Tennessee'));
    final multi = testMultiServer(clients: [client]);

    await pumpActorScreen(tester, multi.provider, backend: MediaBackend.jellyfin);

    expect(find.text('Born'), findsOneWidget);
    expect(find.text('Memphis, Tennessee'), findsOneWidget);
    expect(find.text('Died'), findsNothing);
  });

  testWidgets('a failed details request leaves the filmography header intact', (tester) async {
    final client = _PersonClient(error: StateError('boom'));
    final multi = testMultiServer(clients: [client]);

    await pumpActorScreen(tester, multi.provider, backend: MediaBackend.jellyfin);

    expect(tester.takeException(), isNull);
    expect(find.text('John Garfield'), findsWidgets);
    expect(find.text('Born'), findsNothing);
  });

  testWidgets('a Plex person without a signed-in plex.tv session shows no details', (tester) async {
    final client = _PersonClient(
      backend: MediaBackend.plex,
      details: const PersonDetails(overview: 'Must not be shown'),
    );
    final multi = testMultiServer(clients: [client]);

    await pumpActorScreen(tester, multi.provider, backend: MediaBackend.plex);

    expect(tester.takeException(), isNull);
    expect(client.requestedPersonIds, isEmpty);
    expect(find.text('Must not be shown'), findsNothing);
  });
}

class _PersonClient implements MediaServerClient, PersonDetailsClient {
  _PersonClient({this.details, this.error, this.backend = MediaBackend.jellyfin});

  final PersonDetails? details;
  final Object? error;
  @override
  final MediaBackend backend;
  final List<String> requestedPersonIds = [];

  @override
  ServerId get serverId => ServerId('server_1');

  @override
  String? get serverName => 'Server';

  @override
  ServerCapabilities get capabilities =>
      backend == MediaBackend.plex ? ServerCapabilities.plex : ServerCapabilities.jellyfin;

  @override
  Future<PersonDetails?> fetchPersonDetails(String personId) async {
    requestedPersonIds.add(personId);
    if (error != null) throw error!;
    return details;
  }

  @override
  Future<LibraryPage<MediaItem>> fetchPersonMediaPage(
    String personId, {
    int? start,
    int? size,
    AbortController? abort,
  }) async => LibraryPage<MediaItem>(items: const [], totalCount: 0, offset: start ?? 0);

  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
