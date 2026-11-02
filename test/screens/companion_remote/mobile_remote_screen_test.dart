import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/models/companion_remote/remote_session.dart';
import 'package:plezy/providers/companion_remote_provider.dart';
import 'package:plezy/screens/companion_remote/mobile_remote_screen.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:provider/provider.dart';

/// Drives the screen through session states without a peer connection.
class _SessionStatusProvider extends CompanionRemoteProvider {
  RemoteSessionStatus _status = RemoteSessionStatus.connected;

  @override
  RemoteSessionStatus get status => _status;

  @override
  bool get isConnected => _status == RemoteSessionStatus.connected;

  set sessionStatus(RemoteSessionStatus value) {
    _status = value;
    notifyListeners();
  }
}

void main() {
  testWidgets('keeps the selected tab and scroll offset across a reconnect', (tester) async {
    // Short enough that the remote controls scroll.
    tester.view.physicalSize = const Size(400, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final provider = _SessionStatusProvider();
    addTearDown(provider.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<CompanionRemoteProvider>.value(
        value: provider,
        child: MaterialApp(theme: monoTheme(MonoPalette.dark), home: const MobileRemoteScreen()),
      ),
    );

    await tester.tap(find.text(t.companionRemote.remote.tabPlay));
    await tester.pumpAndSettle();
    expect(find.text(t.companionRemote.remote.playPause), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -150));
    await tester.pumpAndSettle();
    final scrolledTo = tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;
    expect(scrolledTo, greaterThan(0));

    provider.sessionStatus = RemoteSessionStatus.reconnecting;
    await tester.pump();
    expect(find.text(t.companionRemote.remote.reconnecting), findsOneWidget);
    expect(find.byType(ListView), findsNothing);

    provider.sessionStatus = RemoteSessionStatus.connected;
    await tester.pump();
    expect(find.text(t.companionRemote.remote.playPause), findsOneWidget);
    expect(tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels, scrolledTo);
  });
}
