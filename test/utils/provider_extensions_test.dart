import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_library.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/utils/provider_extensions.dart';
import 'package:provider/provider.dart';

import '../test_helpers/backend_client_fixtures.dart';

const _missingOwnerLibrary = MediaLibrary(
  id: '1',
  backend: MediaBackend.plex,
  title: 'Missing owner',
  kind: MediaKind.movie,
  serverId: 'server-a',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;

  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(db);
  });

  tearDown(() => db.close());

  testWidgets('optional media-client lookups return null without MultiServerProvider', (tester) async {
    late BuildContext capturedContext;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(capturedContext.tryGetMediaClientForServer(ServerId('server-1')), isNull);
    expect(capturedContext.tryGetMediaClientWithFallback(ServerId('server-1')), isNull);
    expect(capturedContext.tryGetPlexClientForServer(ServerId('server-1')), isNull);
  });

  testWidgets('library-qualified helpers reject a missing owner instead of returning another online server', (
    tester,
  ) async {
    final replacement = testPlexClient(serverId: ServerId('server-b'));
    final manager = MultiServerManager()..debugRegisterClientForTesting(replacement);
    final provider = MultiServerProvider(manager, DataAggregationService(manager));
    addTearDown(() {
      provider.dispose();
      manager.dispose();
    });
    final context = await _pumpContext(tester, provider);

    expect(() => context.getPlexClientForLibrary(_missingOwnerLibrary), _throwsNoClientAvailable);
    expect(() => context.getMediaClientForLibrary(_missingOwnerLibrary), _throwsNoClientAvailable);
  });

  testWidgets('unqualified libraries fail while explicitly named fallback helpers still select an online server', (
    tester,
  ) async {
    final replacement = testPlexClient(serverId: ServerId('server-b'));
    final manager = MultiServerManager()..debugRegisterClientForTesting(replacement);
    final provider = MultiServerProvider(manager, DataAggregationService(manager));
    addTearDown(() {
      provider.dispose();
      manager.dispose();
    });
    final context = await _pumpContext(tester, provider);

    for (final serverId in <String?>[null, '   ']) {
      final library = MediaLibrary(
        id: '1',
        backend: MediaBackend.plex,
        title: 'Unqualified',
        kind: MediaKind.movie,
        serverId: serverId,
      );
      expect(() => context.getPlexClientForLibrary(library), _throwsNoClientAvailable);
      expect(() => context.getMediaClientForLibrary(library), _throwsNoClientAvailable);
    }

    expect(context.getPlexClientWithFallback(ServerId('server-a')), same(replacement));
    expect(context.getMediaClientWithFallback(ServerId('server-a')), same(replacement));
    expect(context.tryGetMediaClientWithFallback(ServerId('server-a')), same(replacement));
  });

  testWidgets('library-qualified helpers return their registered owner even when it is marked offline', (tester) async {
    final owner = testPlexClient(serverId: ServerId('server-a'));
    final replacement = testPlexClient(serverId: ServerId('server-b'));
    final manager = MultiServerManager()
      ..debugRegisterClientForTesting(owner, online: false)
      ..debugRegisterClientForTesting(replacement);
    final provider = MultiServerProvider(manager, DataAggregationService(manager));
    addTearDown(() {
      provider.dispose();
      manager.dispose();
    });
    final context = await _pumpContext(tester, provider);

    expect(context.getPlexClientForLibrary(_missingOwnerLibrary), same(owner));
    expect(context.getMediaClientForLibrary(_missingOwnerLibrary), same(owner));
  });
}

final _throwsNoClientAvailable = throwsA(
  isA<Exception>().having((error) => error.toString(), 'message', 'Exception: ${t.errors.noClientAvailable}'),
);

Future<BuildContext> _pumpContext(WidgetTester tester, MultiServerProvider provider) async {
  late BuildContext capturedContext;
  await tester.pumpWidget(
    TranslationProvider(
      child: ChangeNotifierProvider<MultiServerProvider>.value(
        value: provider,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    ),
  );
  return capturedContext;
}
