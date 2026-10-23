import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/watch_link_dialog.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../test_helpers/media_items.dart';

void main() {
  setUpAll(() => LocaleSettings.setLocaleSync(AppLocale.en));

  final show = testMediaItem(
    id: '42',
    backend: MediaBackend.plex,
    kind: MediaKind.show,
    guid: 'plex://show/5d9c086c46115600200aa2fe',
    serverId: 'plex-1',
  );
  final movie = testMediaItem(id: '7', backend: MediaBackend.plex, kind: MediaKind.movie, serverId: 'plex-1');

  Future<void> pumpDialog(WidgetTester tester, {required bool appleTV, required WatchLinkDialog dialog}) async {
    TvDetectionService.debugSetAppleTVOverride(appleTV);
    addTearDown(() => TvDetectionService.debugSetAppleTVOverride(null));
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: dialog)));
  }

  testWidgets('shows the portable link and mentions shuffle for a show', (tester) async {
    await pumpDialog(tester, appleTV: false, dialog: WatchLinkDialog(item: show));

    expect(find.text('plezy://watch?plex=show%2F5d9c086c46115600200aa2fe'), findsOneWidget);
    expect(find.text(t.watchLink.dialogShowHint), findsOneWidget);
  });

  testWidgets('falls back to the server link for a movie without a Plex GUID', (tester) async {
    await pumpDialog(tester, appleTV: false, dialog: WatchLinkDialog(item: movie));

    expect(find.text('plezy://watch?id=7&server=plex-1'), findsOneWidget);
    expect(find.text(t.watchLink.dialogMovieHint), findsOneWidget);
    expect(find.text(t.watchLink.dialogShowHint), findsNothing);
  });

  testWidgets('shows a QR code, including on Apple TV', (tester) async {
    await pumpDialog(tester, appleTV: true, dialog: WatchLinkDialog(item: show));

    expect(find.byType(QrImageView), findsOneWidget);
  });

  testWidgets('Copy puts the link on the clipboard', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String?;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

    await pumpDialog(tester, appleTV: false, dialog: WatchLinkDialog(item: show));
    await tester.tap(find.text(t.watchLink.copy));
    await tester.pump();

    expect(copied, 'plezy://watch?plex=show%2F5d9c086c46115600200aa2fe');
  });

  testWidgets('hides Copy on Apple TV, which has no clipboard', (tester) async {
    await pumpDialog(tester, appleTV: true, dialog: WatchLinkDialog(item: show));

    expect(find.text(t.watchLink.copy), findsNothing);
    expect(find.text(t.common.close), findsOneWidget);
  });
}
