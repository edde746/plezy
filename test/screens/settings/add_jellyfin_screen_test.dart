import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/focus/input_mode_tracker.dart';
import 'package:vibe_stream/profiles/profile.dart';
import 'package:vibe_stream/screens/settings/add_jellyfin_screen.dart';
import 'package:vibe_stream/utils/platform_detector.dart';

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

  testWidgets('TV initial focus stays on the server URL field', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);

    await tester.pumpWidget(const InputModeTracker(child: MaterialApp(home: AddJellyfinScreen())));
    await tester.pumpAndSettle();

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'AddJellyfin:Url');
  });

  testWidgets('Android TV remote navigation stays with native URL keyboard', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(null);
    await TvDetectionService.getInstance(forceTv: true);
    TvDetectionService.setForceTVSync(true);

    await tester.pumpWidget(const InputModeTracker(child: MaterialApp(home: AddJellyfinScreen())));
    await tester.pumpAndSettle();

    final urlFocus = FocusManager.instance.primaryFocus!;
    expect(urlFocus.debugLabel, 'AddJellyfin:Url');

    final result = urlFocus.onKeyEvent!(
      urlFocus,
      const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.arrowDown,
        logicalKey: LogicalKeyboardKey.arrowDown,
        timeStamp: Duration.zero,
        deviceType: ui.KeyEventDeviceType.directionalPad,
      ),
    );
    await tester.pump();

    expect(result, KeyEventResult.skipRemainingHandlers);
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
