import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/focusable_wrapper.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_file_info.dart';
import 'package:plezy/widgets/file_info_bottom_sheet.dart';

import '../test_helpers/theme.dart';

void main() {
  setUpAll(() => LocaleSettings.setLocaleSync(AppLocale.en));

  testWidgets('single file renders the item title and every populated media section', (tester) async {
    const fileInfo = MediaFileInfo(
      versions: [
        MediaFileVersion(
          container: 'mkv',
          parts: [
            MediaFilePart(
              filePath: '/media/Example Movie.mkv',
              fileSize: 1048576,
              streams: [
                MediaStreamDetails(kind: MediaStreamKind.video, ordinal: 1, codec: 'h264'),
                MediaStreamDetails(kind: MediaStreamKind.audio, ordinal: 1, codec: 'aac'),
                MediaStreamDetails(kind: MediaStreamKind.subtitle, ordinal: 1, codec: 'srt'),
              ],
            ),
          ],
        ),
      ],
    );

    await _pumpSheet(tester, fileInfo: fileInfo, title: 'Example Movie');

    expect(find.text('Example Movie'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('File'), findsOneWidget);
    expect(find.text('Video'), findsOneWidget);
    expect(find.text('Audio'), findsOneWidget);
    expect(find.text('Subtitles'), findsOneWidget);
  });

  testWidgets('audio-only file drops the video section and keeps the copyable path', (tester) async {
    const path = '/music/Boards of Canada/Geogaddi/01 Ready Lets Go.flac';
    const fileInfo = MediaFileInfo(
      versions: [
        MediaFileVersion(
          container: 'flac',
          parts: [
            MediaFilePart(
              filePath: path,
              fileSize: 35651584,
              streams: [
                MediaStreamDetails(
                  kind: MediaStreamKind.audio,
                  ordinal: 1,
                  codec: 'flac',
                  channels: 2,
                  channelLayout: 'stereo',
                  sampleRate: 44100,
                  bitDepth: 16,
                ),
                MediaStreamDetails(kind: MediaStreamKind.lyric, ordinal: 1, codec: 'lrc'),
              ],
            ),
          ],
        ),
      ],
    );

    await _pumpSheet(tester, fileInfo: fileInfo, title: 'Ready Lets Go');

    expect(find.text('Ready Lets Go'), findsOneWidget);
    expect(find.text('File'), findsOneWidget);
    expect(find.text('Audio'), findsOneWidget);
    expect(find.text('Lyrics'), findsOneWidget);
    expect(find.text('stereo (2 ch)'), findsOneWidget);
    expect(find.text('44.1 kHz'), findsOneWidget);
    expect(find.text('16 bit'), findsOneWidget);
    expect(find.text(path), findsOneWidget);

    // Nothing video-shaped may leak into a track's sheet.
    expect(find.text('Video'), findsNothing);
    expect(find.text('Embedded Images'), findsNothing);
    expect(find.text('Resolution'), findsNothing);
    expect(find.text('Frame Rate'), findsNothing);
  });

  testWidgets('absent fields and empty sections are omitted instead of rendering blank labels', (tester) async {
    const fileInfo = MediaFileInfo(
      versions: [
        MediaFileVersion(parts: [MediaFilePart(container: 'mkv')]),
      ],
    );

    await _pumpSheet(tester, fileInfo: fileInfo);

    expect(find.text('File'), findsOneWidget);
    expect(find.text('Container'), findsOneWidget);
    expect(find.text('Path'), findsNothing);
    expect(find.text('Size'), findsNothing);
    expect(find.text('Overview'), findsNothing);
    expect(find.text('Delivery'), findsNothing);
  });

  testWidgets('version counters and distinct file names render only for multiple versions', (tester) async {
    const multiVersion = MediaFileInfo(
      versions: [
        MediaFileVersion(parts: [MediaFilePart(filePath: '/media/theatrical.mkv')]),
        MediaFileVersion(parts: [MediaFilePart(filePath: '/media/directors-cut.mkv')]),
      ],
    );

    await _pumpSheet(tester, fileInfo: multiVersion);

    expect(find.text('Version 1 of 2'), findsOneWidget);
    expect(find.text('Version 2 of 2'), findsOneWidget);
    expect(find.text('theatrical.mkv'), findsOneWidget);
    expect(find.text('directors-cut.mkv'), findsOneWidget);

    const singleVersion = MediaFileInfo(
      versions: [
        MediaFileVersion(parts: [MediaFilePart(filePath: '/media/theatrical.mkv')]),
      ],
    );
    await _pumpSheet(tester, fileInfo: singleVersion);

    expect(find.textContaining('Version '), findsNothing);
    expect(find.text('theatrical.mkv'), findsOneWidget);
  });

  testWidgets('file counters render for multiple parts and collapse to File for one part', (tester) async {
    const multiPart = MediaFileInfo(
      versions: [
        MediaFileVersion(
          parts: [
            MediaFilePart(filePath: '/media/disc-1.mkv'),
            MediaFilePart(filePath: '/media/disc-2.mkv'),
          ],
        ),
      ],
    );

    await _pumpSheet(tester, fileInfo: multiPart);

    expect(find.text('File 1 of 2'), findsOneWidget);
    expect(find.text('File 2 of 2'), findsOneWidget);
    expect(find.text('File'), findsNothing);

    const singlePart = MediaFileInfo(
      versions: [
        MediaFileVersion(parts: [MediaFilePart(filePath: '/media/movie.mkv')]),
      ],
    );
    await _pumpSheet(tester, fileInfo: singlePart);

    expect(find.text('File'), findsOneWidget);
    expect(find.textContaining('File 1 of'), findsNothing);
  });

  testWidgets('stream section titles number multiple audio tracks but not a single track', (tester) async {
    const multipleAudio = MediaFileInfo(
      versions: [
        MediaFileVersion(
          parts: [
            MediaFilePart(
              streams: [
                MediaStreamDetails(kind: MediaStreamKind.audio, ordinal: 1, codec: 'aac'),
                MediaStreamDetails(kind: MediaStreamKind.audio, ordinal: 2, codec: 'ac3'),
              ],
            ),
          ],
        ),
      ],
    );

    await _pumpSheet(tester, fileInfo: multipleAudio);

    expect(find.text('Audio 1'), findsOneWidget);
    expect(find.text('Audio 2'), findsOneWidget);
    expect(find.text('Audio'), findsNothing);

    const singleAudio = MediaFileInfo(
      versions: [
        MediaFileVersion(
          parts: [
            MediaFilePart(
              streams: [MediaStreamDetails(kind: MediaStreamKind.audio, ordinal: 1, codec: 'aac')],
            ),
          ],
        ),
      ],
    );
    await _pumpSheet(tester, fileInfo: singleAudio);

    expect(find.text('Audio'), findsOneWidget);
    expect(find.textContaining('Audio 1'), findsNothing);
  });

  testWidgets('subtitle flags render as chips only when enabled', (tester) async {
    const flaggedSubtitle = MediaFileInfo(
      versions: [
        MediaFileVersion(
          parts: [
            MediaFilePart(
              streams: [
                MediaStreamDetails(
                  kind: MediaStreamKind.subtitle,
                  ordinal: 1,
                  codec: 'srt',
                  isDefault: true,
                  isForced: true,
                  isHearingImpaired: true,
                ),
              ],
            ),
          ],
        ),
      ],
    );

    await _pumpSheet(tester, fileInfo: flaggedSubtitle);

    expect(find.text('Default'), findsOneWidget);
    expect(find.text('Forced'), findsOneWidget);
    expect(find.text('Hearing impaired'), findsOneWidget);

    const unflaggedSubtitle = MediaFileInfo(
      versions: [
        MediaFileVersion(
          parts: [
            MediaFilePart(
              streams: [
                MediaStreamDetails(
                  kind: MediaStreamKind.subtitle,
                  ordinal: 1,
                  codec: 'srt',
                  isDefault: false,
                  isForced: false,
                  isHearingImpaired: false,
                ),
              ],
            ),
          ],
        ),
      ],
    );
    await _pumpSheet(tester, fileInfo: unflaggedSubtitle);

    expect(find.text('Default'), findsNothing);
    expect(find.text('Forced'), findsNothing);
    expect(find.text('Hearing impaired'), findsNothing);
  });

  testWidgets('file without stream metadata shows the localized no-streams message', (tester) async {
    const fileInfo = MediaFileInfo(
      versions: [
        MediaFileVersion(
          parts: [MediaFilePart(filePath: '/media/movie.mkv', streams: [])],
        ),
      ],
    );

    await _pumpSheet(tester, fileInfo: fileInfo);

    expect(find.text('The server reported no streams for this file.'), findsOneWidget);
  });

  testWidgets('attachments section lists every attachment file name', (tester) async {
    const fileInfo = MediaFileInfo(
      versions: [
        MediaFileVersion(
          attachments: [
            MediaFileAttachment(index: 0, fileName: 'OpenSans.ttf', mimeType: 'font/ttf'),
            MediaFileAttachment(index: 1, fileName: 'NotoSans.otf', codec: 'otf'),
          ],
        ),
      ],
    );

    await _pumpSheet(tester, fileInfo: fileInfo);

    expect(find.text('Attachments'), findsOneWidget);
    expect(find.text('OpenSans.ttf'), findsOneWidget);
    expect(find.text('NotoSans.otf'), findsOneWidget);
  });

  testWidgets('tapping a path copies its full value and confirms the action', (tester) async {
    const path = '/media/movies/Example Movie (2026)/Example Movie.mkv';
    final clipboardCalls = _interceptClipboard();
    const fileInfo = MediaFileInfo(
      versions: [
        MediaFileVersion(parts: [MediaFilePart(filePath: path)]),
      ],
    );

    await _pumpSheet(tester, fileInfo: fileInfo);
    await tester.tap(find.text(path));
    await tester.pumpAndSettle();

    expect(clipboardCalls, hasLength(1));
    expect(clipboardCalls.single.method, 'Clipboard.setData');
    expect(clipboardCalls.single.arguments, <String, dynamic>{'text': path});
    expect(find.text('File path copied'), findsOneWidget);
  });

  testWidgets('keyboard select activates the focused path row and copies its full value', (tester) async {
    const path = '/media/tv/Example Show/Season 01/Episode 01.mkv';
    final clipboardCalls = _interceptClipboard();
    const fileInfo = MediaFileInfo(
      versions: [
        MediaFileVersion(parts: [MediaFilePart(filePath: path)]),
      ],
    );

    await _pumpSheet(tester, fileInfo: fileInfo);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    final pathWrapper = find.ancestor(of: find.text(path), matching: find.byType(FocusableWrapper));
    expect(pathWrapper, findsOneWidget);
    final pathFocus = find.descendant(of: pathWrapper, matching: find.byType(Focus)).first;
    final pathFocusNode = tester.widget<Focus>(pathFocus).focusNode!;
    pathFocusNode.requestFocus();
    await tester.pump();
    expect(pathFocusNode.hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();

    expect(clipboardCalls, hasLength(1));
    expect(clipboardCalls.single.arguments, <String, dynamic>{'text': path});
    expect(find.text('File path copied'), findsOneWidget);
  });

  testWidgets('field grid uses two columns when wide and one column when narrow', (tester) async {
    const fileInfo = MediaFileInfo(versions: [MediaFileVersion(container: 'mkv', durationMs: 123000)]);

    await _pumpSheet(tester, fileInfo: fileInfo, size: const Size(1200, 800));
    final wideContainerDx = tester.getTopLeft(find.text('Container')).dx;
    final wideDurationDx = tester.getTopLeft(find.text('Duration')).dx;
    expect(wideDurationDx, greaterThan(wideContainerDx));

    await _pumpSheet(tester, fileInfo: fileInfo, size: const Size(380, 800));
    final narrowContainerDx = tester.getTopLeft(find.text('Container')).dx;
    final narrowDurationDx = tester.getTopLeft(find.text('Duration')).dx;
    expect(narrowDurationDx, moreOrLessEquals(narrowContainerDx));
  });
}

Future<void> _pumpSheet(
  WidgetTester tester, {
  required MediaFileInfo fileInfo,
  String title = '',
  Size size = const Size(800, 3000),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    TranslationProvider(
      child: MaterialApp(
        theme: ThemeData(extensions: const [testMonoTokens]),
        home: InputModeTracker(
          child: Scaffold(
            body: FileInfoBottomSheet(fileInfo: fileInfo, title: title),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

List<MethodCall> _interceptClipboard() {
  final calls = <MethodCall>[];
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.setData') calls.add(call);
    return null;
  });
  addTearDown(() => messenger.setMockMethodCallHandler(SystemChannels.platform, null));
  return calls;
}
