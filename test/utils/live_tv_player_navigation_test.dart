import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/models/livetv_channel.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/server_capabilities.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/screens/video_player_screen.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/utils/live_tv_player_navigation.dart';

void main() {
  late MultiServerManager manager;
  late MultiServerProvider multiServer;

  setUp(() async {
    await LocaleSettings.setLocale(AppLocale.bg);
    manager = MultiServerManager();
    multiServer = MultiServerProvider(manager, DataAggregationService(manager));
  });

  tearDown(() {
    multiServer.dispose();
    manager.dispose();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  Future<void> pumpLauncher(WidgetTester tester, LiveTvChannel channel) async {
    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    navigateToLiveTv(context, multiServer: multiServer, channel: channel, channels: [channel]),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  test('scoped Live TV selection fails closed and unscoped selection retains fallback', () {
    final aDvr = LiveTvServerInfo(serverId: 'server-a', dvrKey: 'dvr-a');
    final aOtherDvr = LiveTvServerInfo(serverId: 'server-a', dvrKey: 'dvr-other');
    final bDvr = LiveTvServerInfo(serverId: 'server-b', dvrKey: 'dvr-b');

    multiServer.debugSetLiveTvServersForTesting([bDvr]);
    expect(
      liveTvServerInfoForChannel(
        multiServer,
        LiveTvChannel(key: 'channel-a', serverId: 'server-a', liveDvrKey: 'dvr-a'),
      ),
      isNull,
    );

    multiServer.debugSetLiveTvServersForTesting([aOtherDvr, bDvr]);
    expect(
      liveTvServerInfoForChannel(
        multiServer,
        LiveTvChannel(key: 'channel-a', serverId: 'server-a', liveDvrKey: 'dvr-a'),
      ),
      isNull,
      reason: 'an explicit DVR must not relax to another DVR on the same server',
    );
    expect(
      liveTvServerInfoForChannel(multiServer, LiveTvChannel(key: 'channel-a', serverId: 'server-a')),
      same(aOtherDvr),
    );

    multiServer.debugSetLiveTvServersForTesting([bDvr, aDvr]);
    expect(
      liveTvServerInfoForChannel(
        multiServer,
        LiveTvChannel(key: 'channel-a', serverId: 'server-a', liveDvrKey: 'dvr-a'),
      ),
      same(aDvr),
    );
    expect(liveTvServerInfoForChannel(multiServer, LiveTvChannel(key: 'legacy-channel')), same(bDvr));

    multiServer.debugSetLiveTvServersForTesting(const []);
    expect(liveTvServerInfoForChannel(multiServer, LiveTvChannel(key: 'legacy-channel')), isNull);
  });

  testWidgets('missing scoped server is not replaced by an online server', (tester) async {
    manager.debugRegisterClientForTesting(_TestClient(ServerId('server-b')));
    multiServer.debugSetLiveTvServersForTesting([LiveTvServerInfo(serverId: 'server-b', dvrKey: 'dvr-b')]);
    final channel = LiveTvChannel(key: 'channel-a', title: 'Channel A', serverId: 'server-a', liveDvrKey: 'dvr-a');
    await pumpLauncher(tester, channel);

    await tester.tap(find.text('Open'));
    await tester.pump();

    expect(find.byType(VideoPlayerScreen), findsNothing);
    expect(find.text('Сървърът за телевизия на живо не е наличен.'), findsOneWidget);
  });

  testWidgets('unavailable Live TV server error uses the active locale', (tester) async {
    final channel = LiveTvChannel(key: 'channel-1', title: 'Channel');
    await pumpLauncher(tester, channel);

    await tester.tap(find.text('Open'));
    await tester.pump();

    expect(find.text('Сървърът за телевизия на живо не е наличен.'), findsOneWidget);
    expect(find.text('Live TV server is not available.'), findsNothing);
  });

  testWidgets('disconnected Live TV server error uses the active locale', (tester) async {
    const serverId = 'server-1';
    final channel = LiveTvChannel(key: 'channel-1', title: 'Channel', serverId: serverId, liveDvrKey: 'dvr-1');
    multiServer.debugSetLiveTvServersForTesting([LiveTvServerInfo(serverId: serverId, dvrKey: 'dvr-1')]);
    await pumpLauncher(tester, channel);

    await tester.tap(find.text('Open'));
    await tester.pump();

    expect(find.text('Сървърът за телевизия на живо не е свързан.'), findsOneWidget);
    expect(find.text('Live TV server is not connected.'), findsNothing);
  });
}

class _TestClient implements MediaServerClient {
  _TestClient(this.serverId);

  @override
  final ServerId serverId;

  @override
  String? get serverName => 'Test server';

  @override
  MediaBackend get backend => MediaBackend.jellyfin;

  @override
  ServerCapabilities get capabilities => const ServerCapabilities(liveTv: true);

  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
