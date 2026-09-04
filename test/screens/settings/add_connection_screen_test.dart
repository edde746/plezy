import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/focusable_wrapper.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_browser_dialect.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/screens/settings/add_connection_screen.dart';
import 'package:plezy/screens/settings/add_direct_plex_screen.dart';
import 'package:plezy/screens/settings/add_jellyfin_screen.dart';
import 'package:plezy/screens/settings/add_plex_account_screen.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/widgets/backend_badge.dart';

/// The "Add connection" picker is the only route to a new server, so a backend
/// missing from this list is unreachable no matter how complete its client is.
void main() {
  Widget app(Widget home) => MaterialApp(
    theme: monoTheme(dark: true),
    home: InputModeTracker(child: home),
  );

  Profile profile(String id) =>
      Profile.local(id: id, displayName: id, sortOrder: 0, createdAt: DateTime.fromMillisecondsSinceEpoch(0));

  testWidgets('offers Plex, Jellyfin and Emby, each with its own badge', (tester) async {
    await tester.pumpWidget(app(const AddConnectionScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Sign in with Plex'), findsOneWidget);
    expect(find.text('Plex Media Server (Direct / Local)'), findsOneWidget);
    expect(find.text('Connect to Jellyfin'), findsOneWidget);
    expect(find.text('Connect to Emby'), findsOneWidget);

    final badges = tester.widgetList<BackendBadge>(find.byType(BackendBadge)).map((b) => b.backend).toList();
    expect(badges, containsAll(<MediaBackend>[MediaBackend.plex, MediaBackend.jellyfin, MediaBackend.emby]));
  });

  /// The pushed sign-in screen starts a 2s LAN discovery sweep and a
  /// platform package-info read, neither of which settles under
  /// `pumpAndSettle`. Bounded frames are enough: the route's widget exists as
  /// soon as the push completes.
  Future<AddJellyfinScreen> tapCard(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    return tester.widget<AddJellyfinScreen>(find.byType(AddJellyfinScreen));
  }

  testWidgets('the Emby card opens the sign-in screen bound to the Emby dialect', (tester) async {
    await tester.pumpWidget(app(const AddConnectionScreen()));
    await tester.pumpAndSettle();

    final screen = await tapCard(tester, 'Connect to Emby');
    expect(screen.dialect, MediaBrowserDialect.emby);
    expect(screen.targetProfile, isNull);
    expect(find.text('Add Emby server'), findsOneWidget);
  });

  testWidgets('the Jellyfin card still opens the Jellyfin dialect', (tester) async {
    await tester.pumpWidget(app(const AddConnectionScreen()));
    await tester.pumpAndSettle();

    final screen = await tapCard(tester, 'Connect to Jellyfin');
    expect(screen.dialect, MediaBrowserDialect.jellyfin);
    expect(find.text('Add Jellyfin server'), findsOneWidget);
  });

  testWidgets('the Plex card is unaffected by the new option', (tester) async {
    await tester.pumpWidget(app(const AddConnectionScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign in with Plex'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(AddPlexAccountScreen), findsOneWidget);
    expect(find.byType(AddJellyfinScreen), findsNothing);
  });

  testWidgets('a scoped Emby card names the profile it will bind to', (tester) async {
    final target = profile('Living Room');
    await tester.pumpWidget(app(AddConnectionScreen(targetProfile: target)));
    await tester.pumpAndSettle();

    expect(find.text('Sign in to your Emby server. Binds to Living Room.'), findsOneWidget);
    expect(find.text('Sign in to your Jellyfin server. Binds to Living Room.'), findsOneWidget);

    final screen = await tapCard(tester, 'Connect to Emby');
    expect(screen.dialect, MediaBrowserDialect.emby);
    expect(screen.targetProfile?.id, target.id);
  });

  testWidgets('the direct Plex card opens AddDirectPlexScreen', (tester) async {
    await tester.pumpWidget(app(const AddConnectionScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Plex Media Server (Direct / Local)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(AddDirectPlexScreen), findsOneWidget);
  });

  testWidgets('the D-pad steps through all backend cards', (tester) async {
    await tester.pumpWidget(app(const AddConnectionScreen()));
    await tester.pumpAndSettle();

    // The cards share a debugLabel, so track focus-node identity instead.
    final visited = <FocusNode>{};
    for (var i = 0; i < 8; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      final focused = FocusManager.instance.primaryFocus;
      if (focused != null) visited.add(focused);
    }

    expect(find.byType(FocusableWrapper), findsNWidgets(4));
    expect(visited.length, greaterThanOrEqualTo(4), reason: 'D-pad did not reach every backend card');
  });
}
