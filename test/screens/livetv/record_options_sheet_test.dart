import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/live_tv_support.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_library.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/server_capabilities.dart';
import 'package:plezy/models/livetv_program.dart';
import 'package:plezy/models/media_subscription.dart';
import 'package:plezy/screens/livetv/livetv_recording_actions.dart';
import 'package:plezy/screens/livetv/record_options_sheet.dart';

class _FakeDvr implements LiveTvDvrSupport {
  final List<MediaSubscriptionCreateRequest> created = [];
  Object? createError;

  @override
  Future<MediaSubscription?> createRecordingRule(MediaSubscriptionCreateRequest request) async {
    final error = createError;
    if (error != null) throw error;
    created.add(request);
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLiveTv implements LiveTvSupport {
  final LiveTvDvrSupport dvrValue;
  _FakeLiveTv(this.dvrValue);

  @override
  LiveTvDvrSupport? get dvr => dvrValue;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeClient implements MediaServerClient {
  final _FakeDvr dvr = _FakeDvr();
  List<MediaLibrary> libraries = const [];

  @override
  ServerId get serverId => ServerId('server-1');

  @override
  MediaBackend get backend => MediaBackend.jellyfin;

  @override
  ServerCapabilities get capabilities => ServerCapabilities.jellyfin;

  @override
  LiveTvSupport get liveTv => _FakeLiveTv(dvr);

  @override
  Future<List<MediaLibrary>> fetchLibraries({bool useCache = true}) async => libraries;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

LiveTvProgram _program() => LiveTvProgram(title: 'Pilot', guid: 'prog-1');

/// A MediaBrowser-shaped template entry: no target library section, settings
/// keyed by timer DTO field names.
MediaSubscription _mediaBrowserEntry() => const MediaSubscription(
  key: '',
  type: MediaSubscription.typeEpisode,
  title: 'Record Episode',
  selected: true,
  parameters: '{"ServiceName":"Emby"}',
  settings: [SubscriptionSetting(id: 'PrePaddingSeconds', label: 'Start early (seconds)', type: 'int', value: 60)],
);

Future<RecordOutcome?> _pumpAndSave(WidgetTester tester, _FakeClient client, MediaSubscription entry) async {
  RecordOutcome? outcome;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                outcome = await RecordOptionsSheet.push(context, client: client, program: _program(), entries: [entry]);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Record'));
  await tester.pumpAndSettle();
  return outcome;
}

void main() {
  testWidgets('create succeeds without a target when the template carries none (MediaBrowser)', (tester) async {
    final client = _FakeClient();

    final outcome = await _pumpAndSave(tester, client, _mediaBrowserEntry());

    expect(outcome, RecordOutcome.scheduled);
    final request = client.dvr.created.single;
    expect(request.targetLibrarySectionID, isNull);
    expect(request.parameters, '{"ServiceName":"Emby"}');
    expect(request.prefs['PrePaddingSeconds'], 60);
  });

  testWidgets('create still requires a target when eligible libraries exist and none resolves', (tester) async {
    final client = _FakeClient()
      // An int-id show library makes the picker eligible, but nothing is
      // selected and the template names no section — the Plex guard holds.
      ..libraries = [
        MediaLibrary(
          id: '5',
          title: 'TV',
          kind: MediaKind.show,
          backend: MediaBackend.plex,
          serverId: ServerId('server-1'),
        ),
      ];

    final outcome = await _pumpAndSave(tester, client, _mediaBrowserEntry());

    expect(outcome, RecordOutcome.targetMissing);
    expect(client.dvr.created, isEmpty);
  });

  testWidgets('RecordingConflictException maps to the alreadyScheduled outcome', (tester) async {
    final client = _FakeClient();
    client.dvr.createError = const RecordingConflictException('duplicate');

    final outcome = await _pumpAndSave(tester, client, _mediaBrowserEntry());

    expect(outcome, RecordOutcome.alreadyScheduled);
  });
}
