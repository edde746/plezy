import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/connection/connection_registry.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/database/download_operations.dart';
import 'package:plezy/profiles/active_profile_binder.dart';
import 'package:plezy/profiles/active_profile_provider.dart';
import 'package:plezy/profiles/plex_home_service.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/profiles/profile_activation.dart';
import 'package:plezy/profiles/profile_connection_registry.dart';
import 'package:plezy/profiles/profile_registry.dart';
import 'package:plezy/services/storage_service.dart';
import 'package:plezy/services/system_shelf_service.dart';
import 'package:provider/provider.dart';

import '../test_helpers/prefs.dart';

class _PlexHome extends PlexHomeService {
  _PlexHome({required super.connections, required super.profileConnections, required super.storage})
    : super(plexHomeUserFetcher: (_) async => const []);

  @override
  Future<void> start() async {}

  @override
  Future<void> reloadFromStorage() async {}

  @override
  Future<void> dispose() async {}
}

class _Binder implements ActiveProfileBinder {
  _Binder(this.events);
  final List<String> events;

  @override
  bool lastBindFailureConnectivityOnly = false;

  @override
  void markUserInitiatedActivation(String profileId) => events.add('mark:$profileId');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RollbackBinder implements ActiveProfileBinder {
  _RollbackBinder(this.active, this.events, {this.targetBindingRelease}) : boundClientProfileId = active.activeId {
    active.addListener(_handleActiveChanged);
  }

  final ActiveProfileProvider active;
  final List<String> events;
  final Completer<void> rebindStarted = Completer<void>();
  final Completer<void> allowRebind = Completer<void>();
  final Completer<void> targetBindingStarted = Completer<void>();
  final Completer<void>? targetBindingRelease;
  String? boundClientProfileId;
  @override
  bool lastBindFailureConnectivityOnly = false;
  bool _targetFailed = false;
  final Set<String> _successfullyBoundProfileIds = {};

  @override
  void markUserInitiatedActivation(String profileId) {
    events.add('mark:$profileId');
  }

  void _handleActiveChanged() {
    if (active.activeId == 'target' && !_targetFailed) {
      _targetFailed = true;
      boundClientProfileId = null;
      SystemShelfService().beginProfileSession('target');
      active.markBindingStarted();
      targetBindingStarted.complete();
      final release = targetBindingRelease;
      if (release == null) {
        scheduleMicrotask(() => active.markBindingFinished(success: false));
      } else {
        unawaited(
          release.future.then((_) {
            if (active.activeId == 'target') {
              active.markBindingFinished(success: false);
            }
          }),
        );
      }
      return;
    }
    final profileId = active.activeId;
    if ((profileId == 'newer' || profileId == 'latest') && _successfullyBoundProfileIds.add(profileId!)) {
      boundClientProfileId = profileId;
      SystemShelfService().beginProfileSession(profileId);
      active.markBindingStarted();
      scheduleMicrotask(() => active.markBindingFinished(success: true));
    }
  }

  @override
  Future<void> rebindActive() async {
    events.add('rebind:${active.activeId}');
    active.markBindingStarted();
    rebindStarted.complete();
    await allowRebind.future;
    boundClientProfileId = active.activeId;
    active.markBindingFinished(success: true);
  }

  @override
  void dispose() {
    active.removeListener(_handleActiveChanged);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ThrowingActiveProfileProvider extends ActiveProfileProvider {
  _ThrowingActiveProfileProvider({
    required super.registry,
    required super.plexHome,
    required super.connections,
    required super.profileConnections,
    required super.storage,
    super.activeProfileIdWriter,
  });

  bool throwOnActivation = false;

  @override
  Future<bool> activate(Profile profile, {String? pin}) {
    if (throwOnActivation) throw StateError('synthetic activation failure');
    return super.activate(profile, pin: pin);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/profile_activation_shelf');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(resetSharedPreferencesForTest);
  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    SystemShelfService.debugOverrideInstance(null);
  });

  testWidgets('successful different-profile activation clears old owner before identity publication', (tester) async {
    final harness = await _pumpHarness(tester, channel);
    addTearDown(harness.dispose);
    final events = harness.events;
    harness.active.addListener(() => events.add('active:${harness.active.activeId}'));

    final activated = await switchProfileFromUi(harness.context, harness.target);

    expect(activated, isTrue);
    expect(events, ['clear:owner', 'mark:target', 'active:target']);
    expect(SystemShelfService().debugActiveOwner, isNull);
  });

  testWidgets('newer switch overtakes an older switch blocked clearing the same shelf owner', (tester) async {
    final harness = await _pumpHarness(tester, channel, simulateBindingRollback: true);
    addTearDown(harness.dispose);
    final ownerClearStarted = Completer<void>();
    final allowOwnerClear = Completer<void>();
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'clear') {
        final ownerId = (call.arguments as Map)['ownerId'];
        harness.events.add('clear:$ownerId');
        if (ownerId == 'owner') {
          ownerClearStarted.complete();
          await allowOwnerClear.future;
        }
      }
      return true;
    });

    final olderSwitch = switchProfileFromUi(harness.context, harness.target);
    await ownerClearStarted.future;

    expect(await switchProfileFromUi(harness.context, harness.newer), isTrue);
    expect(harness.active.activeId, 'newer');
    expect(harness.rollbackBinder!.boundClientProfileId, 'newer');
    expect(harness.events, contains('mark:newer'));
    expect(harness.events, isNot(contains('mark:target')));

    allowOwnerClear.complete();
    expect(await olderSwitch, isFalse);
    await tester.pump();

    expect(harness.active.activeId, 'newer');
    expect((await StorageService.getInstance()).getActiveProfileId(), 'newer');
    expect(SystemShelfService().debugActiveOwner, 'newer');
    expect(harness.events, isNot(contains('rebind:target')));
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('selecting current profile and cancelling PIN verification do not clear', (tester) async {
    final harness = await _pumpHarness(tester, channel);
    addTearDown(harness.dispose);

    expect(await switchProfileFromUi(harness.context, harness.active.active!), isTrue);
    expect(harness.events, ['mark:owner']);

    final protected = Profile.local(
      id: 'protected',
      displayName: 'Protected',
      pinHash: computePinHash('1234'),
      createdAt: DateTime(2026, 1, 3),
    );
    final attempt = switchProfileFromUi(harness.context, protected);
    await tester.pumpAndSettle();
    Navigator.of(harness.context, rootNavigator: true).pop();
    await tester.pumpAndSettle();

    expect(await attempt, isFalse);
    expect(harness.events.where((event) => event.startsWith('clear:')), isEmpty);
  });

  testWidgets('activation exception restores the previous shelf owner', (tester) async {
    final harness = await _pumpHarness(tester, channel, throwOnTargetActivation: true);
    addTearDown(harness.dispose);

    final activated = await switchProfileFromUi(harness.context, harness.target);

    expect(activated, isFalse);
    expect(harness.active.activeId, 'owner');
    expect(SystemShelfService().debugActiveOwner, 'owner');
    expect(harness.events, ['clear:owner', 'mark:target']);
  });

  testWidgets('failed target binding explicitly restores prior clients before returning', (tester) async {
    final harness = await _pumpHarness(tester, channel, simulateBindingRollback: true);
    addTearDown(harness.dispose);
    final binder = harness.rollbackBinder!;
    var switchCompleted = false;

    final switchFuture = switchProfileFromUi(harness.context, harness.target).then((result) {
      switchCompleted = true;
      return result;
    });
    await binder.rebindStarted.future;

    expect(harness.active.activeId, 'owner');
    expect(binder.boundClientProfileId, isNull);
    expect(switchCompleted, isFalse);

    binder.allowRebind.complete();
    expect(await switchFuture, isFalse);
    expect(binder.boundClientProfileId, 'owner');
    expect(harness.active.lastBindingSucceeded, isTrue);
    expect(SystemShelfService().debugActiveOwner, 'owner');
  });

  testWidgets('connectivity-only bind failure keeps a downloads-owning profile active offline', (tester) async {
    final harness = await _pumpHarness(tester, channel, simulateBindingRollback: true);
    addTearDown(harness.dispose);
    final binder = harness.rollbackBinder!;
    binder.lastBindFailureConnectivityOnly = true;
    await harness.database.addDownloadOwner(profileId: 'target', globalKey: 'srv-1/episode-1');

    final activated = await switchProfileFromUi(harness.context, harness.target);

    expect(activated, isTrue);
    expect(harness.active.activeId, 'target');
    expect(SystemShelfService().debugActiveOwner, 'target');
    expect((await StorageService.getInstance()).getActiveProfileId(), 'target');
    expect(binder.rebindStarted.isCompleted, isFalse);
    expect(harness.events, isNot(contains('rebind:owner')));
    await tester.pump();
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('connectivity-only bind failure without owned downloads still rolls back', (tester) async {
    final harness = await _pumpHarness(tester, channel, simulateBindingRollback: true);
    addTearDown(harness.dispose);
    final binder = harness.rollbackBinder!;
    binder.lastBindFailureConnectivityOnly = true;

    final switchFuture = switchProfileFromUi(harness.context, harness.target);
    await binder.rebindStarted.future;
    binder.allowRebind.complete();

    expect(await switchFuture, isFalse);
    expect(harness.active.activeId, 'owner');
    expect(binder.boundClientProfileId, 'owner');
    expect(SystemShelfService().debugActiveOwner, 'owner');
    await tester.pump();
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('non-connectivity bind failure rolls back even when the profile owns downloads', (tester) async {
    final harness = await _pumpHarness(tester, channel, simulateBindingRollback: true);
    addTearDown(harness.dispose);
    final binder = harness.rollbackBinder!;
    await harness.database.addDownloadOwner(profileId: 'target', globalKey: 'srv-1/episode-1');

    final switchFuture = switchProfileFromUi(harness.context, harness.target);
    await binder.rebindStarted.future;
    binder.allowRebind.complete();

    expect(await switchFuture, isFalse);
    expect(harness.active.activeId, 'owner');
    expect(binder.boundClientProfileId, 'owner');
    expect(SystemShelfService().debugActiveOwner, 'owner');
    await tester.pump();
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('protected switch rolls back to profile active when its activation is admitted', (tester) async {
    final harness = await _pumpHarness(tester, channel, simulateBindingRollback: true, gateTargetBindingFailure: true);
    addTearDown(harness.dispose);
    final binder = harness.rollbackBinder!;
    final protectedTarget = Profile.local(
      id: harness.target.id,
      displayName: 'Protected Target',
      pinHash: computePinHash('1234'),
      createdAt: harness.target.createdAt,
    );

    final pendingProtectedSwitch = switchProfileFromUi(harness.context, protectedTarget);
    await tester.pumpAndSettle();
    expect(find.text('Protected Target'), findsOneWidget);
    expect(harness.active.activeId, 'owner');

    expect(await switchProfileFromUi(harness.context, harness.newer), isTrue);
    expect(harness.active.activeId, 'newer');
    expect(binder.boundClientProfileId, 'newer');

    final pinField = find.byType(TextField);
    if (pinField.evaluate().isNotEmpty) {
      await tester.enterText(pinField, '1234');
    } else {
      for (final digit in ['1', '2', '3', '4']) {
        await tester.tap(find.text(digit));
      }
    }
    await tester.pump();
    await binder.targetBindingStarted.future;
    binder.targetBindingRelease!.complete();
    await binder.rebindStarted.future;
    final restoredProfileId = harness.active.activeId;

    binder.allowRebind.complete();
    expect(await pendingProtectedSwitch, isFalse);
    await tester.pump();

    expect(restoredProfileId, 'newer');
    expect(harness.active.activeId, 'newer');
    expect(binder.boundClientProfileId, 'newer');
    expect(SystemShelfService().debugActiveOwner, 'newer');
    expect((await StorageService.getInstance()).getActiveProfileId(), 'newer');
  });

  testWidgets('newer activation supersedes a failed switch while rollback shelf clear is pending', (tester) async {
    final harness = await _pumpHarness(tester, channel, simulateBindingRollback: true);
    addTearDown(harness.dispose);
    final binder = harness.rollbackBinder!;
    final targetClearStarted = Completer<void>();
    final allowTargetClear = Completer<void>();
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'clear') {
        final ownerId = (call.arguments as Map)['ownerId'];
        harness.events.add('clear:$ownerId');
        if (ownerId == 'target') {
          targetClearStarted.complete();
          await allowTargetClear.future;
        }
      }
      return true;
    });

    final failedSwitch = switchProfileFromUi(harness.context, harness.target);
    await targetClearStarted.future;

    expect(await switchProfileFromUi(harness.context, harness.newer), isTrue);
    expect(harness.active.activeId, 'newer');
    expect(binder.boundClientProfileId, 'newer');

    allowTargetClear.complete();
    expect(await failedSwitch, isFalse);
    expect(harness.active.activeId, 'newer');
    expect(binder.boundClientProfileId, 'newer');
    expect(SystemShelfService().debugActiveOwner, 'newer');
    expect(binder.rebindStarted.isCompleted, isFalse);
    expect(harness.events, isNot(contains('mark:owner')));
    expect(harness.events, isNot(contains('rebind:owner')));
    expect((await StorageService.getInstance()).getActiveProfileId(), 'newer');
    await tester.pump();
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('rollback waits for successive reserved switches and never rebinds the stale owner', (tester) async {
    final harness = await _pumpHarness(tester, channel, simulateBindingRollback: true, gateTargetBindingFailure: true);
    addTearDown(harness.dispose);
    final binder = harness.rollbackBinder!;
    final firstTargetClearStarted = Completer<void>();
    final allowFirstTargetClear = Completer<void>();
    final secondTargetClearStarted = Completer<void>();
    final allowSecondTargetClear = Completer<void>();
    var targetClearCount = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'clear') {
        final ownerId = (call.arguments as Map)['ownerId'];
        harness.events.add('clear:$ownerId');
        if (ownerId == 'target') {
          targetClearCount++;
          if (targetClearCount == 1) {
            firstTargetClearStarted.complete();
            await allowFirstTargetClear.future;
          } else {
            secondTargetClearStarted.complete();
            await allowSecondTargetClear.future;
          }
        }
      }
      return true;
    });

    final failedSwitch = switchProfileFromUi(harness.context, harness.target);
    await binder.targetBindingStarted.future;
    binder.targetBindingRelease!.complete();
    await firstTargetClearStarted.future;

    // Model the still-authoritative target binder reasserting its shelf marker
    // while the first native clear is pending. The next request now reserves
    // C synchronously and blocks behind that clear before entering the identity
    // queue.
    SystemShelfService().beginProfileSession('target');
    final middleSwitch = switchProfileFromUi(harness.context, harness.newer);
    final middleReservation = harness.active.identityMutationGeneration;

    final latestSwitch = switchProfileFromUi(harness.context, harness.latest);
    expect(harness.active.identityMutationGeneration, greaterThan(middleReservation));
    expect(await latestSwitch, isTrue);
    expect(harness.active.activeId, 'latest');
    expect(binder.boundClientProfileId, 'latest');

    allowFirstTargetClear.complete();
    await secondTargetClearStarted.future;
    expect(await failedSwitch, isFalse);
    expect(harness.active.activeId, 'latest');
    expect(harness.events, isNot(contains('mark:owner')));
    expect(harness.events, isNot(contains('rebind:owner')));

    allowSecondTargetClear.complete();
    expect(await middleSwitch, isFalse);
    await tester.pump();

    expect(targetClearCount, 2);
    expect((await StorageService.getInstance()).getActiveProfileId(), 'latest');
    expect(SystemShelfService().debugActiveOwner, 'latest');
    expect(harness.events, isNot(contains('mark:newer')));
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('new activation during a held restore write prevents stale prior-profile publication', (tester) async {
    final harness = await _pumpHarness(tester, channel, simulateBindingRollback: true, gateOwnerRestoreWrite: true);
    addTearDown(harness.dispose);
    final binder = harness.rollbackBinder!;
    final publishedProfileIds = <String?>[];
    harness.active.addListener(() => publishedProfileIds.add(harness.active.activeId));

    final failedSwitch = switchProfileFromUi(harness.context, harness.target);
    await harness.restoreWriteStarted.future;
    expect(harness.active.activeId, 'target');
    final restoreGeneration = harness.active.identityMutationGeneration;

    final newerSwitch = switchProfileFromUi(harness.context, harness.newer);
    await tester.pump();
    expect(harness.active.identityMutationGeneration, greaterThan(restoreGeneration));

    harness.allowRestoreWrite.complete();
    expect(await newerSwitch, isTrue);
    expect(await failedSwitch, isFalse);
    expect(harness.active.activeId, 'newer');
    expect(binder.boundClientProfileId, 'newer');
    expect(publishedProfileIds, isNot(contains('owner')));
    expect(harness.events, isNot(contains('mark:owner')));
    expect(harness.events, isNot(contains('rebind:owner')));
    expect((await StorageService.getInstance()).getActiveProfileId(), 'newer');
    expect(harness.identityWrites, ['target', 'owner', 'target', 'newer']);
  });

  testWidgets('cancelled newer PIN attempt does not suppress pending failed-switch rollback', (tester) async {
    final harness = await _pumpHarness(tester, channel, simulateBindingRollback: true, gateTargetBindingFailure: true);
    addTearDown(harness.dispose);
    final binder = harness.rollbackBinder!;
    final failedSwitch = switchProfileFromUi(harness.context, harness.target);
    await binder.targetBindingStarted.future;
    final failedGeneration = harness.active.identityMutationGeneration;
    final protectedNewer = Profile.local(
      id: 'protected-newer',
      displayName: 'Protected Newer',
      pinHash: computePinHash('1234'),
      createdAt: DateTime(2026, 1, 4),
    );

    final cancelledSwitch = switchProfileFromUi(harness.context, protectedNewer);
    await tester.pumpAndSettle();
    Navigator.of(harness.context, rootNavigator: true).pop();
    await tester.pumpAndSettle();
    expect(await cancelledSwitch, isFalse);
    expect(harness.active.identityMutationGeneration, failedGeneration);

    binder.targetBindingRelease!.complete();
    await binder.rebindStarted.future;
    binder.allowRebind.complete();
    expect(await failedSwitch, isFalse);
    expect(harness.active.activeId, 'owner');
    expect(binder.boundClientProfileId, 'owner');
    await tester.pump();
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('failed queued activation lets superseded restore retry the prior profile', (tester) async {
    final harness = await _pumpHarness(
      tester,
      channel,
      simulateBindingRollback: true,
      gateOwnerRestoreWrite: true,
      failNewerIdentityWrite: true,
    );
    addTearDown(harness.dispose);
    final binder = harness.rollbackBinder!;

    final failedSwitch = switchProfileFromUi(harness.context, harness.target);
    await harness.restoreWriteStarted.future;
    final restoreGeneration = harness.active.identityMutationGeneration;

    final newerSwitch = switchProfileFromUi(harness.context, harness.newer);
    await tester.pump();
    expect(harness.active.identityMutationGeneration, greaterThan(restoreGeneration));

    harness.allowRestoreWrite.complete();
    expect(await newerSwitch, isFalse);
    await binder.rebindStarted.future;
    binder.allowRebind.complete();
    expect(await failedSwitch, isFalse);

    expect(harness.active.activeId, 'owner');
    expect(binder.boundClientProfileId, 'owner');
    expect(harness.active.committedIdentityGeneration, greaterThan(restoreGeneration));
    expect(harness.events, contains('mark:owner'));
    expect(harness.events, contains('rebind:owner'));
    expect((await StorageService.getInstance()).getActiveProfileId(), 'owner');
    expect(harness.identityWrites, ['target', 'owner', 'target', 'newer', 'target', 'owner']);
  });

  test('superseded failing profile write cannot overwrite the newer committed profile', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final profiles = ProfileRegistry(database);
    final connections = ConnectionRegistry(database);
    final profileConnections = ProfileConnectionRegistry(database);
    final storage = await StorageService.getInstance();
    final plexHome = _PlexHome(connections: connections, profileConnections: profileConnections, storage: storage);
    final targetWriteStarted = Completer<void>();
    final allowTargetWriteToFail = Completer<void>();
    final newerWriteStarted = Completer<void>();
    final identityWrites = <String>[];
    Future<void> writer(String profileId) async {
      identityWrites.add(profileId);
      await storage.setActiveProfileId(profileId);
      if (profileId == 'target') {
        targetWriteStarted.complete();
        await allowTargetWriteToFail.future;
        throw StateError('synthetic target persistence failure');
      }
      if (profileId == 'newer') newerWriteStarted.complete();
    }

    final active = _ThrowingActiveProfileProvider(
      registry: profiles,
      plexHome: plexHome,
      connections: connections,
      profileConnections: profileConnections,
      storage: storage,
      activeProfileIdWriter: writer,
    );
    addTearDown(() async {
      active.dispose();
      await plexHome.dispose();
      await database.close();
    });
    final owner = Profile.local(id: 'owner', displayName: 'Owner', createdAt: DateTime(2026, 1, 1));
    final target = Profile.local(id: 'target', displayName: 'Target', createdAt: DateTime(2026, 1, 2));
    final newer = Profile.local(id: 'newer', displayName: 'Newer', createdAt: DateTime(2026, 1, 3));
    await profiles.upsert(owner);
    await profiles.upsert(target);
    await profiles.upsert(newer);
    await storage.setActiveProfileId(owner.id);
    await active.initialize();

    final targetActivation = active.activate(target);
    final targetFailure = expectLater(targetActivation, throwsA(isA<StateError>()));
    await targetWriteStarted.future;
    final newerActivation = active.activate(newer);

    expect(newerWriteStarted.isCompleted, isFalse);
    expect(storage.getActiveProfileId(), target.id);
    expect(identityWrites, ['target']);

    allowTargetWriteToFail.complete();
    await targetFailure;
    expect(await newerActivation, isTrue);
    expect(newerWriteStarted.isCompleted, isTrue);
    expect(active.activeId, newer.id);
    expect(storage.getActiveProfileId(), newer.id);
    expect(identityWrites, ['target', 'owner', 'newer']);
  });
}

class _Harness {
  _Harness({
    required this.context,
    required this.active,
    required this.target,
    required this.newer,
    required this.events,
    required this.latest,
    required this.plexHome,
    required this.rollbackBinder,
    required this.database,
    required this.restoreWriteStarted,
    required this.allowRestoreWrite,
    required this.identityWrites,
  });

  final BuildContext context;
  final ActiveProfileProvider active;
  final Profile target;
  final Profile newer;
  final Profile latest;
  final List<String> events;
  final PlexHomeService plexHome;
  final _RollbackBinder? rollbackBinder;
  final AppDatabase database;
  final Completer<void> restoreWriteStarted;
  final Completer<void> allowRestoreWrite;
  final List<String> identityWrites;

  Future<void> dispose() async {
    rollbackBinder?.dispose();
    active.dispose();
    await plexHome.dispose();
    await database.close();
  }
}

Future<_Harness> _pumpHarness(
  WidgetTester tester,
  MethodChannel channel, {
  bool throwOnTargetActivation = false,
  bool simulateBindingRollback = false,
  bool gateTargetBindingFailure = false,
  bool gateOwnerRestoreWrite = false,
  bool failNewerIdentityWrite = false,
}) async {
  final events = <String>[];
  final identityWrites = <String>[];
  final database = AppDatabase.forTesting(NativeDatabase.memory());
  final profiles = ProfileRegistry(database);
  final connections = ConnectionRegistry(database);
  final profileConnections = ProfileConnectionRegistry(database);
  final storage = await StorageService.getInstance();
  final restoreWriteStarted = Completer<void>();
  final allowRestoreWrite = Completer<void>();
  Future<void> activeProfileIdWriter(String profileId) async {
    identityWrites.add(profileId);
    await storage.setActiveProfileId(profileId);
    if (gateOwnerRestoreWrite && profileId == 'owner') {
      if (!restoreWriteStarted.isCompleted) restoreWriteStarted.complete();
      await allowRestoreWrite.future;
    }
    if (failNewerIdentityWrite && profileId == 'newer') {
      throw StateError('synthetic newer identity write failure');
    }
  }

  final plexHome = _PlexHome(connections: connections, profileConnections: profileConnections, storage: storage);
  final active = _ThrowingActiveProfileProvider(
    registry: profiles,
    plexHome: plexHome,
    connections: connections,
    profileConnections: profileConnections,
    storage: storage,
    activeProfileIdWriter: gateOwnerRestoreWrite || failNewerIdentityWrite ? activeProfileIdWriter : null,
  );
  final owner = Profile.local(id: 'owner', displayName: 'Owner', createdAt: DateTime(2026, 1, 1));
  final target = Profile.local(id: 'target', displayName: 'Target', createdAt: DateTime(2026, 1, 2));
  final newer = Profile.local(id: 'newer', displayName: 'Newer', createdAt: DateTime(2026, 1, 3));
  final latest = Profile.local(id: 'latest', displayName: 'Latest', createdAt: DateTime(2026, 1, 4));
  await profiles.upsert(owner);
  await profiles.upsert(target);
  await profiles.upsert(newer);
  await profiles.upsert(latest);
  await storage.setActiveProfileId(owner.id);
  await active.initialize();
  active.throwOnActivation = throwOnTargetActivation;
  final targetBindingRelease = gateTargetBindingFailure ? Completer<void>() : null;
  final rollbackBinder = simulateBindingRollback
      ? _RollbackBinder(active, events, targetBindingRelease: targetBindingRelease)
      : null;
  final ActiveProfileBinder binder = rollbackBinder ?? _Binder(events);

  final shelf = SystemShelfService.forTesting(channel: channel, isSupported: () async => true);
  shelf.beginProfileSession(owner.id);
  SystemShelfService.debugOverrideInstance(shelf);
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
    if (call.method == 'clear') events.add('clear:${(call.arguments as Map)['ownerId']}');
    return true;
  });

  BuildContext? captured;
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ActiveProfileProvider>.value(value: active),
        Provider<ActiveProfileBinder>.value(value: binder),
        Provider<AppDatabase>.value(value: database),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              captured = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return _Harness(
    context: captured!,
    active: active,
    target: target,
    newer: newer,
    latest: latest,
    rollbackBinder: rollbackBinder,
    events: events,
    plexHome: plexHome,
    restoreWriteStarted: restoreWriteStarted,
    allowRestoreWrite: allowRestoreWrite,
    identityWrites: identityWrites,
    database: database,
  );
}
