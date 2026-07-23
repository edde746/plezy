import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:plezy/database/app_database.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/widgets/server_activities_button.dart';
import 'package:provider/provider.dart';

import '../test_helpers/backend_client_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase database;

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
    database = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(database);
  });

  tearDown(() => database.close());

  testWidgets('togglePanel opens and closes the server activities overlay', (tester) async {
    final manager = MultiServerManager();
    final multiServerProvider = MultiServerProvider(manager, DataAggregationService(manager));
    final buttonKey = GlobalKey<ServerActivitiesButtonState>();

    addTearDown(() {
      multiServerProvider.dispose();
      manager.dispose();
    });

    await tester.pumpWidget(
      TranslationProvider(
        child: ChangeNotifierProvider<MultiServerProvider>.value(
          value: multiServerProvider,
          child: MaterialApp(
            home: Scaffold(body: ServerActivitiesButton(key: buttonKey)),
          ),
        ),
      ),
    );

    buttonKey.currentState!.togglePanel();
    await tester.pump();
    await tester.pump();

    expect(find.text(t.serverTasks.title), findsOneWidget);
    expect(find.text(t.serverTasks.noTasks), findsOneWidget);

    buttonKey.currentState!.togglePanel();
    await tester.pump();

    expect(find.text(t.serverTasks.title), findsNothing);
  });

  testWidgets('polls three seconds after completion without overlapping activity aggregates', (tester) async {
    final transport = _ControlledActivitiesClient();
    final harness = await _pumpActivitiesHarness(tester, transport);

    expect(transport.activityRequests, hasLength(1));
    transport.completeActivities(0, const ['Initial activity']);
    await tester.pump();
    await tester.pump();
    expect(find.text('Initial activity'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    expect(transport.activityRequests, hasLength(2));
    expect(transport.activeActivityGets, 1);

    await tester.pump(const Duration(seconds: 4));
    expect(transport.activityRequests, hasLength(2));
    expect(transport.maximumActiveActivityGets, 1);

    transport.completeActivities(1, const ['Completed poll']);
    await tester.pump();
    await tester.pump();
    expect(find.text('Completed poll'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2999));
    expect(transport.activityRequests, hasLength(2));
    await tester.pump(const Duration(milliseconds: 1));
    expect(transport.activityRequests, hasLength(3));
    expect(transport.maximumActiveActivityGets, 1);

    harness.buttonKey.currentState!.togglePanel();
    await tester.pump();
  });

  testWidgets('close and reopen rejects a stale completion and preserves the new poll cadence', (tester) async {
    final transport = _ControlledActivitiesClient(honorAbort: false);
    final harness = await _pumpActivitiesHarness(tester, transport);
    final oldRequest = transport.activityRequests.single;

    harness.buttonKey.currentState!.togglePanel();
    await tester.pump();
    await expectLater(oldRequest.abortObserved.future, completes);

    harness.buttonKey.currentState!.togglePanel();
    await tester.pump();
    expect(transport.activityRequests, hasLength(2));

    transport.completeActivities(1, const ['Fresh activity']);
    await tester.pump();
    await tester.pump();
    expect(find.text('Fresh activity'), findsOneWidget);

    transport.completeActivities(0, const ['Old activity']);
    await tester.pump();
    await tester.pump();
    expect(find.text('Fresh activity'), findsOneWidget);
    expect(find.text('Old activity'), findsNothing);

    await tester.pump(const Duration(milliseconds: 2999));
    expect(transport.activityRequests, hasLength(2));
    await tester.pump(const Duration(milliseconds: 1));
    expect(transport.activityRequests, hasLength(3));
    transport.completeActivities(2, const ['Next activity']);
    await tester.pump();
    await tester.pump();

    harness.buttonKey.currentState!.togglePanel();
    await tester.pump();
  });

  testWidgets('post-cancel refresh cannot be undone by a pre-cancel poll', (tester) async {
    final transport = _ControlledActivitiesClient(honorAbort: false);
    final harness = await _pumpActivitiesHarness(tester, transport);

    transport.completeActivities(0, const ['Cancelable activity'], cancellable: true);
    await tester.pump();
    await tester.pump();
    expect(find.text('Cancelable activity'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    expect(transport.activityRequests, hasLength(2));

    await tester.tap(find.byTooltip(t.common.cancel));
    await tester.pump();
    await tester.pump();
    expect(transport.deleteCount, 1);
    expect(transport.activityRequests, hasLength(3));
    await expectLater(transport.activityRequests[1].abortObserved.future, completes);

    transport.completeActivities(2, const []);
    await tester.pump();
    await tester.pump();
    expect(find.text(t.serverTasks.noTasks), findsOneWidget);

    transport.completeActivities(1, const ['Cancelable activity'], cancellable: true);
    await tester.pump();
    await tester.pump();
    expect(find.text(t.serverTasks.noTasks), findsOneWidget);
    expect(find.text('Cancelable activity'), findsNothing);
    expect(transport.activityRequests, hasLength(3));

    harness.buttonKey.currentState!.togglePanel();
    await tester.pump();
  });
}

class _ActivitiesHarness {
  const _ActivitiesHarness(this.buttonKey);

  final GlobalKey<ServerActivitiesButtonState> buttonKey;
}

Future<_ActivitiesHarness> _pumpActivitiesHarness(WidgetTester tester, _ControlledActivitiesClient transport) async {
  final serverId = ServerId('plex-server');
  final client = testPlexClient(serverId: serverId, serverName: 'Test server', httpClient: transport);
  final manager = MultiServerManager()..debugRegisterClientForTesting(client);
  final multiServerProvider = MultiServerProvider(manager, DataAggregationService(manager));
  final buttonKey = GlobalKey<ServerActivitiesButtonState>();

  addTearDown(() {
    multiServerProvider.dispose();
    manager.dispose();
  });

  await tester.pumpWidget(
    TranslationProvider(
      child: ChangeNotifierProvider<MultiServerProvider>.value(
        value: multiServerProvider,
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(body: ServerActivitiesButton(key: buttonKey)),
        ),
      ),
    ),
  );
  buttonKey.currentState!.togglePanel();
  await tester.pump();
  return _ActivitiesHarness(buttonKey);
}

class _ControlledActivityRequest {
  _ControlledActivityRequest(this.request);

  final http.BaseRequest request;
  final response = Completer<http.StreamedResponse>();
  final abortObserved = Completer<void>();
}

class _ControlledActivitiesClient extends http.BaseClient {
  _ControlledActivitiesClient({this.honorAbort = true});

  final bool honorAbort;
  final activityRequests = <_ControlledActivityRequest>[];
  var activeActivityGets = 0;
  var maximumActiveActivityGets = 0;
  var deleteCount = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (request.method == 'DELETE' && request.url.path.startsWith('/activities/')) {
      deleteCount++;
      return Future.value(_response(request, const {}));
    }
    if (request.method != 'GET' || request.url.path != '/activities') {
      return Future.value(_response(request, const {}));
    }

    final pending = _ControlledActivityRequest(request);
    activityRequests.add(pending);
    activeActivityGets++;
    if (activeActivityGets > maximumActiveActivityGets) {
      maximumActiveActivityGets = activeActivityGets;
    }

    final abortTrigger = (request as http.Abortable).abortTrigger!;
    unawaited(
      abortTrigger.then((_) {
        if (!pending.abortObserved.isCompleted) {
          pending.abortObserved.complete();
        }
        if (honorAbort && !pending.response.isCompleted) {
          pending.response.completeError(http.RequestAbortedException(request.url));
        }
      }),
    );

    return pending.response.future.whenComplete(() {
      activeActivityGets--;
    });
  }

  void completeActivities(int requestIndex, List<String> titles, {bool cancellable = false}) {
    final pending = activityRequests[requestIndex];
    if (pending.response.isCompleted) return;
    pending.response.complete(
      _response(pending.request, {
        'MediaContainer': {
          'Activity': [
            for (var index = 0; index < titles.length; index++)
              {
                'uuid': 'activity-$requestIndex-$index',
                'type': 'library.update',
                'title': titles[index],
                'progress': 50,
                'cancellable': cancellable,
              },
          ],
        },
      }),
    );
  }

  http.StreamedResponse _response(http.BaseRequest request, Map<String, dynamic> body) {
    return http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode(body))),
      200,
      headers: const {'content-type': 'application/json'},
      request: request,
    );
  }
}
