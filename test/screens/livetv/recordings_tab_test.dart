import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/live_tv_support.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/server_capabilities.dart';
import 'package:plezy/models/media_grab_operation.dart';
import 'package:plezy/models/media_subscription.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/screens/livetv/tabs/recordings_tab.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));

  testWidgets('coalesces concurrent refreshes and commits completed loads in order', (tester) async {
    final dvr = _ControllableDvr();
    final client = _FakeMediaServerClient(dvr);
    final manager = MultiServerManager()..debugRegisterClientForTesting(client);
    final provider = MultiServerProvider(manager, DataAggregationService(manager))
      ..debugSetLiveTvServersForTesting([LiveTvServerInfo(serverId: client.serverId.value, dvrKey: 'dvr')]);
    addTearDown(provider.dispose);
    final tabKey = GlobalKey<RecordingsTabState>();

    await tester.pumpWidget(
      TranslationProvider(
        child: InputModeTracker(
          child: ChangeNotifierProvider<MultiServerProvider>.value(
            value: provider,
            child: MaterialApp(
              theme: monoTheme(dark: true),
              home: Scaffold(body: RecordingsTab(key: tabKey)),
            ),
          ),
        ),
      ),
    );

    expect(dvr.grabRequests, hasLength(1));
    final queuedRefresh = tabKey.currentState!.reload();
    final coalescedRefresh = tabKey.currentState!.reload();
    expect(identical(queuedRefresh, coalescedRefresh), isTrue);
    expect(dvr.grabRequests, hasLength(1));

    dvr.completeGrabs(0, const []);
    await tester.pump();
    dvr.completeRules(0, const [_rule]);
    await tester.pump();

    expect(find.text(_rule.title!), findsOneWidget);
    expect(dvr.grabRequests, hasLength(2));

    await tester.pump(const Duration(seconds: 30));
    final stillCoalesced = tabKey.currentState!.reload();
    expect(identical(queuedRefresh, stillCoalesced), isTrue);
    expect(dvr.grabRequests, hasLength(2));

    dvr.completeGrabs(1, const []);
    await tester.pump();
    dvr.completeRules(1, const [_rule]);
    await tester.pump();

    expect(find.text(_rule.title!), findsOneWidget);
    expect(dvr.grabRequests, hasLength(3));

    dvr.completeGrabs(2, const []);
    await tester.pump();
    dvr.completeRules(2, const []);
    await queuedRefresh;
    await tester.pumpAndSettle();

    expect(dvr.grabRequests, hasLength(3));
    expect(dvr.ruleRequests, hasLength(3));
    expect(find.text(_rule.title!), findsNothing);
    expect(find.text(t.liveTv.noScheduledRecordings), findsOneWidget);
  });
}

const _rule = MediaSubscription(key: 'rule-1', type: 2, title: 'Obsolete series rule');

final class _FakeMediaServerClient implements MediaServerClient {
  _FakeMediaServerClient(this.dvr);

  final _ControllableDvr dvr;

  @override
  ServerId get serverId => ServerId('server-a');

  @override
  String get serverName => 'DVR server';

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  ServerCapabilities get capabilities => const ServerCapabilities(liveTv: true, liveTvDvr: true);

  @override
  LiveTvSupport get liveTv => _FakeLiveTvSupport(dvr);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeLiveTvSupport implements LiveTvSupport {
  _FakeLiveTvSupport(this.dvr);

  @override
  final LiveTvDvrSupport dvr;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _ControllableDvr implements LiveTvDvrSupport {
  final List<Completer<List<MediaGrabOperation>>> grabRequests = [];
  final List<Completer<List<MediaSubscription>>> ruleRequests = [];
  final List<String> deleteCalls = [];

  @override
  Future<List<MediaGrabOperation>> fetchScheduledRecordings() {
    final request = Completer<List<MediaGrabOperation>>();
    grabRequests.add(request);
    return request.future;
  }

  @override
  Future<List<MediaSubscription>> fetchRecordingRules({bool includeGrabs = true, bool includeStorage = true}) {
    final request = Completer<List<MediaSubscription>>();
    ruleRequests.add(request);
    return request.future;
  }

  @override
  Future<void> deleteRecordingRule(String subscriptionId) async {
    deleteCalls.add(subscriptionId);
  }

  void completeGrabs(int index, List<MediaGrabOperation> grabs) => grabRequests[index].complete(grabs);

  void completeRules(int index, List<MediaSubscription> rules) => ruleRequests[index].complete(rules);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
