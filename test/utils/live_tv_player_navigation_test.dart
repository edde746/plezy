import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/models/livetv_channel.dart';
import 'package:plezy/providers/multi_server_provider.dart';
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
