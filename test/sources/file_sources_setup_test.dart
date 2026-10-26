import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:plezy/navigation/profile_session_screen.dart';
import 'package:plezy/profiles/active_profile_binder.dart';
import 'package:plezy/profiles/active_profile_provider.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/profiles/profile_registry.dart';
import 'package:plezy/screens/profile/profile_switch_screen.dart';
import 'package:plezy/screens/sources/file_sources_setup.dart';
import 'package:plezy/services/settings_service.dart';
import '../test_helpers/prefs.dart';
import '../test_helpers/profile_stack.dart';

class _Binder implements ActiveProfileBinder {
  bool started = false;
  @override
  void start({bool allowInitialPinPrompt = true}) => started = true;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Routes extends NavigatorObserver {
  Route<dynamic>? latest;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => latest = route;
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => latest = newRoute;
}

void main() {
  late ProfileStack profiles;
  late _Binder binder;
  late _Routes routes;
  late BuildContext launchContext;
  setUp(() async {
    resetSharedPreferencesForTest();
    await SettingsService.getInstance();
    profiles = await ProfileStack.create();
    binder = _Binder();
    routes = _Routes();
  });
  tearDown(() => profiles.dispose());
  Future<void> mount(WidgetTester tester) => tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ActiveProfileProvider>.value(value: profiles.active),
        Provider<ProfileRegistry>.value(value: profiles.profiles),
        Provider<ActiveProfileBinder>.value(value: binder),
      ],
      child: MaterialApp(
        navigatorObservers: [routes],
        home: Builder(
          builder: (context) {
            launchContext = context;
            return const SizedBox();
          },
        ),
      ),
    ),
  );
  testWidgets('fresh startup does not silently create a files-only profile', (tester) async {
    await mount(tester);
    expect(await openFileSourcesSession(launchContext, createIfEmpty: false), isFalse);
    expect(profiles.active.profiles, isEmpty);
    expect(binder.started, isFalse);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('explicit files onboarding creates a standard local profile and opens its source library', (
    tester,
  ) async {
    await mount(tester);
    expect(await openFileSourcesSession(launchContext, createIfEmpty: true), isTrue);
    expect(profiles.active.active, isA<LocalProfile>());
    expect(profiles.active.profiles, hasLength(1));
    expect(await profiles.connections.list(), isEmpty);
    expect(binder.started, isTrue);
    final shell = (routes.latest! as MaterialPageRoute).builder(launchContext) as ProfileSessionScreen;
    expect(shell.initialSourceLibrary, isTrue);
    expect(shell.initialPromptHandled, isTrue);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('protected profile requires the existing picker and cancellation never opens its files', (tester) async {
    await profiles.profiles.upsert(
      Profile.local(id: 'protected', displayName: 'Protected', pinHash: 'fixture-pin-hash', createdAt: DateTime(2026)),
    );
    await mount(tester);
    final opening = openFileSourcesSession(launchContext, createIfEmpty: false);
    // Let the actual registry reload finish without building the pushed route:
    // the existing profile picker has its own PIN/activation widget tests.
    await tester.runAsync(() async {
      for (
        var i = 0;
        i < 50 && (routes.latest as MaterialPageRoute).builder(launchContext) is! ProfileSwitchScreen;
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    final picker = (routes.latest! as MaterialPageRoute).builder(launchContext) as ProfileSwitchScreen;
    expect(picker.requireSelection, isTrue);
    Navigator.of(launchContext).pop(false);
    expect(await opening, isFalse);
    await tester.pumpWidget(const SizedBox());
  });
}
