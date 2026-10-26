import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/sources/reader_preferences.dart';
import 'package:plezy/sources/publication_archive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final (comic, rtl) in [(false, false), (true, false), (true, true)]) {
    test(
      rtl
          ? 'Arabic reader chrome accepts localized page digits and preserves book direction'
          : comic
          ? 'real comic engine supports zoom, pan, fit width, RTL and page navigation'
          : 'real EPUB engine renders, navigates CFIs, searches and sanitizes publisher content',
      () async {
        final temporary = await Directory.systemTemp.createTemp('plezy-reader-browser-');
        final zip = Archive();
        final files = {
          'META-INF/container.xml':
              '<container xmlns="urn:oasis:names:tc:opendocument:xmlns:container" version="1.0"><rootfiles><rootfile full-path="EPUB/package.opf" media-type="application/oebps-package+xml"/></rootfiles></container>',
          'EPUB/package.opf':
              '<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="id"><metadata xmlns:dc="http://purl.org/dc/elements/1.1/"><dc:identifier id="id">fixture</dc:identifier><dc:title>Reading fixture</dc:title><dc:language>en</dc:language></metadata><manifest><item id="one" href="one.xhtml" media-type="application/xhtml+xml"/><item id="two" href="two.xhtml" media-type="application/xhtml+xml"/><item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/></manifest><spine><itemref idref="one"/><itemref idref="two"/></spine></package>',
          'EPUB/nav.xhtml':
              '<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops"><body><nav epub:type="toc"><ol><li><a href="one.xhtml">The shore</a></li><li><a href="two.xhtml">The crossing</a></li></ol></nav></body></html>',
          'EPUB/one.xhtml':
              '<html xmlns="http://www.w3.org/1999/xhtml"><head><title>The shore</title><script>parent.publisherScriptRan=true;</script><style>p{font:12px monospace;color:black;background:white}p span{font-size:9px}</style></head><body><h1>The shore</h1><p onclick="alert(1)">A lighthouse stood above the quiet bay.</p><p>${List.filled(35, 'We followed the path beside the sea, watching the light move across the water.').join(' ')}</p><form><input/></form><iframe src="https://example.invalid"/></body></html>',
          'EPUB/two.xhtml':
              '<html xmlns="http://www.w3.org/1999/xhtml"><body><h1>The crossing</h1><p>At dawn we left the harbour.</p></body></html>',
        };
        if (comic) {
          files.clear();
          for (var i = 1; i <= 3; i++) {
            files['page$i.${i == 2 ? 'SVG' : 'svg'}'] =
                '<svg xmlns="http://www.w3.org/2000/svg" width="800" height="1200" viewBox="0 0 800 1200"><rect width="800" height="1200" fill="#18202b"/><rect x="48" y="48" width="704" height="490" rx="14" fill="#40566e"/><rect x="48" y="565" width="704" height="490" rx="14" fill="#536778"/><text x="72" y="1130" font-size="36" fill="white">Page $i</text></svg>';
          }
        }
        for (final entry in files.entries) {
          zip.add(ArchiveFile.bytes(entry.key, utf8.encode(entry.value)));
        }
        final input = await File('${temporary.path}/fixture.epub').writeAsBytes(ZipEncoder().encode(zip));
        final archive = await PublicationArchive.open(input, temporary, comic: comic);
        late PublicationServer server;
        Object? failure;
        server = PublicationServer(
          archive,
          valid: () => true,
          onEvent: (events) async {
            if (events.first['type'] == 'engineReady') {
              try {
                await server.execute('open', {
                  'title': 'Reading fixture',
                  'interfaceLocale': rtl ? 'ar' : 'en',
                  'formattingLocale': rtl ? 'ar-EG' : 'en-US',
                  'interfaceDirection': rtl ? 'rtl' : 'ltr',
                  'icons': {
                    'zoomIn': Symbols.zoom_in_rounded.codePoint,
                    'zoomOut': Symbols.zoom_out_rounded.codePoint,
                    'fitPage': Symbols.fit_screen_rounded.codePoint,
                    'page': Symbols.numbers_rounded.codePoint,
                    'prev': Symbols.chevron_left_rounded.codePoint,
                    'next': Symbols.chevron_right_rounded.codePoint,
                    'toc': Symbols.format_list_bulleted_rounded.codePoint,
                    'search': Symbols.search_rounded.codePoint,
                    'note': Symbols.bookmarks_rounded.codePoint,
                    'settings': Symbols.text_fields_rounded.codePoint,
                    'full': Symbols.fullscreen_rounded.codePoint,
                    'speak': Symbols.record_voice_over_rounded.codePoint,
                  },
                  'settings': {
                    'background': '#0E0F12',
                    'foreground': '#EDEDED',
                    'dark': true,
                    'fontSize': 22,
                    'columns': 2,
                  },
                  'labels': {
                    'zoomIn': 'Zoom in',
                    'zoomOut': 'Zoom out',
                    'zoom': 'Zoom',
                    'fitPage': 'Fit page',
                    'fitWidth': 'Fit width',
                    'actualSize': 'Actual size',
                    'pageLayout': 'Page layout',
                    'readingDirection': 'Reading direction',
                    'automatic': 'Automatic',
                    'singlePage': 'One page',
                    'twoPages': 'Two pages',
                    'leftToRight': 'Left to right',
                    'rightToLeft': 'Right to left',
                    'close': 'Close',
                    'prev': 'Previous page',
                    'next': 'Next page',
                    'toc': 'Contents',
                    'search': 'Search',
                    'note': 'Bookmarks',
                    'settings': 'Reading settings',
                    'full': 'Fullscreen',
                    'speak': 'Read aloud',
                    'page': rtl ? 'انتقل إلى الصفحة' : 'Go to page',
                    'goToPage': rtl ? 'انتقل إلى الصفحة' : 'Go to page',
                    'goToSection': rtl ? 'انتقل إلى الفصل' : 'Go to chapter',
                    'pageRange': rtl ? 'أدخل رقمًا من ١ إلى {count}' : 'Enter a number from 1 to {count}',
                    if (rtl) ...{
                      'settings': 'إعدادات القراءة',
                      'readingDirection': 'اتجاه القراءة',
                      'pageLayout': 'تخطيط الصفحة',
                      'zoom': 'تكبير',
                      'close': 'إغلاق',
                    },
                  },
                });
              } catch (e) {
                failure = e;
              }
            } else if (events.first['type'] == 'browserSettings') {
              await server.execute(
                'settings',
                normalizeReaderPreferences(Map<String, dynamic>.from(events.first['settings'] as Map)),
              );
            }
          },
        );
        final url = (await server.start()).replace(queryParameters: {'external': '1'});
        try {
          final result = await Process.run('node', [
            'test/sources/fixtures/reader_browser.cjs',
            url.toString(),
            comic ? 'comic' : 'epub',
            rtl ? 'rtl' : 'ltr',
          ]);
          expect(result.exitCode, 0, reason: '${result.stderr}; bridge: $failure');
          expect(jsonDecode(result.stdout as String)['search'], greaterThan(0));
        } finally {
          await server.close();
          await temporary.delete(recursive: true);
        }
      },
      skip: Platform.environment['PLEZY_CHROME_PATH'] == null,
      timeout: const Timeout(Duration(seconds: 60)),
    );
  }
}
