import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/screens/settings/add_jellyfin_screen.dart';
import 'package:plezy/utils/platform_detector.dart';

Profile _profile(String id) =>
    Profile.local(id: id, displayName: id, sortOrder: 0, createdAt: DateTime.fromMillisecondsSinceEpoch(0));

void main() {
  tearDown(() {
    TvDetectionService.debugSetAppleTVOverride(null);
    TvDetectionService.setForceTVSync(false);
  });

  testWidgets('autofocuses the server URL field', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AddJellyfinScreen()));
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));

    expect(field.autofocus, isTrue);
  });

  testWidgets('TV initial focus opens the server URL keyboard', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);

    await tester.pumpWidget(const InputModeTracker(child: MaterialApp(home: AddJellyfinScreen())));
    await tester.pumpAndSettle();

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'TvVirtualKeyboard');
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsOneWidget);
  });

  testWidgets('Android TV remote navigation stays with virtual URL keyboard', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(null);
    await TvDetectionService.getInstance(forceTv: true);
    TvDetectionService.setForceTVSync(true);

    await tester.pumpWidget(const InputModeTracker(child: MaterialApp(home: AddJellyfinScreen())));
    await tester.pumpAndSettle();

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'TvVirtualKeyboard');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'TvVirtualKeyboard');
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.gameButtonB);
    await tester.pumpAndSettle();

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'AddJellyfin:Url');
  });

  group('Jellyfin profile binding decisions', () {
    test('creates a local profile only on true first-run with no profiles', () {
      expect(shouldCreateLocalJellyfinProfile(targetProfile: null, activeProfile: null, hasProfiles: false), isTrue);
      expect(
        shouldPromptForJellyfinProfileSelection(targetProfile: null, activeProfile: null, hasProfiles: false),
        isFalse,
      );
    });

    test('uses existing active profile without prompting or creating', () {
      final active = _profile('active');
      expect(shouldCreateLocalJellyfinProfile(targetProfile: null, activeProfile: active, hasProfiles: true), isFalse);
      expect(
        shouldPromptForJellyfinProfileSelection(targetProfile: null, activeProfile: active, hasProfiles: true),
        isFalse,
      );
    });

    test('prompts when profiles exist but no profile is active', () {
      expect(shouldCreateLocalJellyfinProfile(targetProfile: null, activeProfile: null, hasProfiles: true), isFalse);
      expect(
        shouldPromptForJellyfinProfileSelection(targetProfile: null, activeProfile: null, hasProfiles: true),
        isTrue,
      );
    });

    test('explicit target profile never creates or prompts', () {
      final target = _profile('target');
      expect(shouldCreateLocalJellyfinProfile(targetProfile: target, activeProfile: null, hasProfiles: true), isFalse);
      expect(
        shouldPromptForJellyfinProfileSelection(targetProfile: target, activeProfile: null, hasProfiles: true),
        isFalse,
      );
    });
  });
}
