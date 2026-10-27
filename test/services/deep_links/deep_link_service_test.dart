import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/services/deep_links/deep_link.dart';
import 'package:plezy/services/deep_links/deep_link_service.dart';

Profile _local(String id, String name) => Profile.local(id: id, displayName: name, createdAt: DateTime(2026));

final _parents = _local('parents', 'Parents');
final _kids = _local('kids', 'Kids');

class _FakeHost implements DeepLinkProfileHost {
  _FakeHost({required this.activeProfileId});

  @override
  final List<Profile> profiles = [_parents, _kids];

  @override
  String? activeProfileId;

  final switches = <String>[];
  Completer<bool>? _pendingSwitch;

  /// Completes the switch in flight; on success [activeProfileId] follows.
  void finishSwitch(bool switched) {
    if (switched) activeProfileId = switches.last;
    _pendingSwitch!.complete(switched);
  }

  @override
  Future<bool> switchTo(Profile profile) {
    switches.add(profile.id);
    return (_pendingSwitch = Completer<bool>()).future;
  }
}

class _Session {
  _Session(String? profileId) {
    session = DeepLinkSession(profileId: profileId, launch: (link) async => launched.add(link.toUri().toString()));
  }

  late final DeepLinkSession session;
  final launched = <String>[];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/deep_link');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<String> reports;
  late List<Uri> playerReturns;
  late DeepLinkService service;

  setUp(() {
    reports = [];
    playerReturns = [];
    service = DeepLinkService.forTesting(
      channel,
      report: reports.add,
      handleExternalPlayerReturn: (uri) async {
        playerReturns.add(uri);
        return true;
      },
    );
  });

  tearDown(() {
    channel.setMethodCallHandler(null);
    messenger.setMockMethodCallHandler(channel, null);
  });

  /// Sends `onLink` the way the native plugins do and returns Dart's reply.
  Future<Object?> sendFromPlatform(String url) async {
    final reply = Completer<ByteData?>();
    await messenger.handlePlatformMessage(
      channel.name,
      const StandardMethodCodec().encodeMethodCall(MethodCall('onLink', {'url': url})),
      reply.complete,
    );
    return const StandardMethodCodec().decodeEnvelope((await reply.future)!);
  }

  test('a link waits for a profile session and is delivered once', () async {
    service.host = _FakeHost(activeProfileId: 'parents');
    expect(await sendFromPlatform('plezy://play?server=s1&id=1'), isTrue);

    final session = _Session('parents');
    service.attach(session.session);
    service.attach(session.session);
    await pumpEventQueue();
    expect(session.launched, ['plezy://play?server=s1&id=1']);
  });

  test('a newer link replaces one still waiting', () async {
    service.host = _FakeHost(activeProfileId: 'parents');
    service.receive('plezy://play?server=s1&id=1');
    service.receive('plezy://live?channel=4.1');

    final session = _Session('parents');
    service.attach(session.session);
    await pumpEventQueue();
    expect(session.launched, ['plezy://live?channel=4.1']);
  });

  test('a link naming another profile switches first, then plays in that profile', () async {
    final host = _FakeHost(activeProfileId: 'parents');
    service.host = host;
    final parentsSession = _Session('parents');
    service.attach(parentsSession.session);

    service.receive('plezy://play?server=s1&id=1&profile=Kids');
    await pumpEventQueue();
    expect(host.switches, ['kids']);
    expect(service.selectsProfile, isTrue);

    // The switch rebuilds the profile session: the new one attaches while the
    // switch is still settling, and must wait for it.
    final kidsSession = _Session('kids');
    service.attach(kidsSession.session);
    await pumpEventQueue();
    expect(kidsSession.launched, isEmpty);

    host.finishSwitch(true);
    service.detach(parentsSession.session);
    await pumpEventQueue();
    expect(parentsSession.launched, isEmpty);
    expect(kidsSession.launched, ['plezy://play?server=s1&id=1&profile=Kids']);
    expect(service.selectsProfile, isFalse);
  });

  test('backing out of the switch drops the link', () async {
    final host = _FakeHost(activeProfileId: 'parents');
    service.host = host;
    final session = _Session('parents');
    service.attach(session.session);

    service.receive('plezy://open?profile=kids');
    await pumpEventQueue();
    host.finishSwitch(false);
    await pumpEventQueue();

    service.attach(session.session);
    await pumpEventQueue();
    expect(session.launched, isEmpty);
    expect(service.selectsProfile, isFalse);
  });

  test('a link for the active profile plays without switching', () async {
    final host = _FakeHost(activeProfileId: 'kids');
    service.host = host;
    final session = _Session('kids');
    service.attach(session.session);

    service.receive('plezy://play?server=s1&id=1&profile=KIDS');
    await pumpEventQueue();
    expect(host.switches, isEmpty);
    expect(session.launched, hasLength(1));
  });

  test('an unknown profile is reported and the link dropped', () async {
    service.host = _FakeHost(activeProfileId: 'parents');
    final session = _Session('parents');
    service.attach(session.session);

    service.receive('plezy://play?server=s1&id=1&profile=Grandma');
    await pumpEventQueue();
    expect(session.launched, isEmpty);
    expect(reports.single, contains('Grandma'));
  });

  test('an invalid link is reported', () async {
    service.receive('plezy://play?id=1');
    expect(reports, hasLength(1));
  });

  group('startup', () {
    test('a claimed profile is applied by startup, not switched again', () async {
      final host = _FakeHost(activeProfileId: 'kids');
      service.host = host;
      service.receive('plezy://play?server=s1&id=1&profile=kids');

      expect(service.claimStartupProfile([_parents, _kids]), _kids);
      expect(service.startupProfileId, 'kids');

      service.settleStartupProfile(applied: true);
      expect(service.startupProfileId, isNull);
      final session = _Session('kids');
      service.attach(session.session);
      await pumpEventQueue();
      expect(host.switches, isEmpty);
      expect(session.launched, hasLength(1));
    });

    test('a profile startup could not apply drops the link', () async {
      service.host = _FakeHost(activeProfileId: 'parents');
      service.receive('plezy://play?server=s1&id=1&profile=kids');
      expect(service.claimStartupProfile([_parents, _kids]), _kids);

      service.settleStartupProfile(applied: false);
      final session = _Session('parents');
      service.attach(session.session);
      await pumpEventQueue();
      expect(session.launched, isEmpty);
    });

    test('nothing is claimed for a link without a profile or with an unknown one', () {
      service.receive('plezy://play?server=s1&id=1');
      expect(service.claimStartupProfile([_parents, _kids]), isNull);
      service.receive('plezy://open?profile=Grandma');
      expect(service.claimStartupProfile([_parents, _kids]), isNull);
      expect(service.startupProfileId, isNull);
    });

    test('the launch link is read once, and its channel replay is not a second link', () async {
      var reads = 0;
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'getInitialLink');
        reads++;
        return 'plezy://play?server=s1&id=1';
      });
      service.host = _FakeHost(activeProfileId: 'parents');
      final session = _Session('parents');
      service.attach(session.session);

      await sendFromPlatform('plezy://play?server=s1&id=1');
      await service.fetchInitialLink();
      await service.fetchInitialLink();
      await pumpEventQueue();
      expect(reads, 1);
      expect(session.launched, hasLength(1));
    });

    test('a session reached without startup reading the launch link still gets it', () async {
      messenger.setMockMethodCallHandler(channel, (call) async => 'plezy://play?server=s1&id=1');
      service.host = _FakeHost(activeProfileId: 'parents');
      final session = _Session('parents');

      service.attach(session.session);
      await pumpEventQueue();

      expect(session.launched, ['plezy://play?server=s1&id=1']);
    });
  });

  test('external player return links go to the player service, not a session', () async {
    service.host = _FakeHost(activeProfileId: 'parents');
    final session = _Session('parents');
    service.attach(session.session);

    const url = 'plezy://external-player/success/s1?position=12';
    service.receive(url);
    await pumpEventQueue();
    expect(playerReturns.single.toString(), url);
    expect(session.launched, isEmpty);
    expect(DeepLink.tryParse(url), isA<ExternalPlayerReturnLink>());
  });
}
