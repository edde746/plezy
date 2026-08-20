import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/media_image_helper.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/cast_member_strip.dart';
import 'package:plezy/widgets/optimized_media_image.dart';

import '../test_helpers/prefs.dart';

const List<CastStripMember> _members = [
  (name: 'First Actor', secondary: 'Lead', imagePath: null),
  (name: 'Second Actor', secondary: 'Support', imagePath: null),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
    TvDetectionService.debugSetAppleTVOverride(true);
  });

  tearDown(() {
    TvDetectionService.debugSetAppleTVOverride(null);
  });

  testWidgets('owns horizontal focus and delegates vertical section navigation', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final key = GlobalKey<CastMemberStripState>();
    var selectedIndex = -1;
    var navigatedUp = 0;
    var navigatedDown = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: monoTheme(dark: true),
        home: Scaffold(
          body: CastMemberStrip(
            key: key,
            members: _members,
            onMemberTap: (index) => selectedIndex = index,
            onNavigateUp: () => navigatedUp++,
            onNavigateDown: () => navigatedDown++,
          ),
        ),
      ),
    );

    key.currentState!.requestFocus();
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'cast_row');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(selectedIndex, 1);
    expect(navigatedUp, 1);
    expect(navigatedDown, 1);
  });

  testWidgets('renders member images with the square grid-cell decode budget', (tester) async {
    // Cast cards are poster-cell sized; the small avatar budget decodes them
    // below retina resolution and blurs them (issue #1591).
    await tester.pumpWidget(
      MaterialApp(
        theme: monoTheme(dark: true),
        home: Scaffold(body: CastMemberStrip(members: _members)),
      ),
    );

    final images = tester.widgetList<OptimizedMediaImage>(find.byType(OptimizedMediaImage));
    expect(images, hasLength(_members.length));
    for (final image in images) {
      expect(image.imageType, ImageType.square);
    }
  });

  testWidgets('clamps its focus index when the member list changes', (tester) async {
    final key = GlobalKey<CastMemberStripState>();
    var members = _members;
    late StateSetter setHostState;

    await tester.pumpWidget(
      MaterialApp(
        theme: monoTheme(dark: true),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              setHostState = setState;
              return CastMemberStrip(key: key, members: members);
            },
          ),
        ),
      ),
    );

    key.currentState!.requestFocus();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    setHostState(() => members = const []);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
