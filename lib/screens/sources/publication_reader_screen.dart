import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../i18n/strings.g.dart';
import '../../i18n/locale_preferences.dart';
import '../../i18n/presentation_formats.dart';
import '../../focus/focusable_text_field.dart';
import '../../focus/focusable_slider.dart';
import '../../services/playback_coordinator.dart';
import '../../sources/publication_archive.dart';
import '../../sources/source_controller.dart';
import '../../sources/source_models.dart';
import '../../sources/source_playback.dart';
import '../../sources/reader_preferences.dart';
import '../../theme/mono_tokens.dart';
import '../../utils/dialogs.dart';
import '../../utils/platform_detector.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/app_menu.dart';
import '../../widgets/dialog_action_button.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import 'source_notes_screen.dart';
import 'source_sync_screen.dart';
import 'source_widgets.dart';

class PublicationReaderScreen extends StatefulWidget {
  const PublicationReaderScreen({super.key, required this.entry, required this.file});
  final SourceEntry entry;
  final PublicationFile file;
  @override
  State<PublicationReaderScreen> createState() => _PublicationReaderScreenState();
}

class _PublicationReaderScreenState extends State<PublicationReaderScreen> with WidgetsBindingObserver {
  SourceController? _sources;
  SourcePlayback? _playback;
  String? _profile;
  int _generation = 0;
  PublicationProgress? _progress;
  List<BookAnnotation> _annotations = [];
  final _pdf = PdfViewerController();
  PdfTextSearcher? _pdfSearch;
  InAppWebViewController? _web;
  File? _file;
  PublicationServer? _server;
  Uri? _url;
  Map<String, dynamic> _settings = {};
  List<Map<String, dynamic>> _toc = [], _overlays = [];
  bool _loading = true, _ready = false, _disposed = false, _speaking = false, _readAlong = false;
  bool _cloudConflict = false;
  Object? _error;
  double? _transfer;
  String _chapter = '';
  String? _selectedCFI, _selectedText, _overlayHref;
  int _pages = 0;
  bool _fixed = false;
  Object _viewZoom = 'fit-page';
  Timer? _saveTimer;
  Future<void> _writes = Future.value();
  FlutterTts? _tts;
  bool get pdf => p.extension(widget.file.name).toLowerCase() == '.pdf';
  bool get valid =>
      !_disposed &&
      _sources?.current(_generation) == true &&
      _sources?.profileId == _profile &&
      !(_sources?.blocked ?? true);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      unawaited(_flush());
      unawaited(_stopSpeech());
    }
  }

  Future<void> _open() async {
    try {
      if (PlatformDetector.isTV()) throw const SourceException(SourceFailure.unsupported);
      final sources = context.read<SourceController>();
      _sources = sources;
      _playback = context.read<SourcePlayback>();
      await sources.ready;
      sources.requireSession();
      _profile = sources.profileId;
      _generation = sources.generation;
      sources.addListener(_profileChanged);
      PlaybackCoordinator.instance.registerNarrationSession(_stopSpeech);
      final initial = PublicationProgress(
        entryKey: widget.entry.key,
        edition: widget.file.fingerprint,
        mode: PublicationMode.reading,
        session: const Uuid().v4(),
      );
      _progress = await sources.openProgress(widget.entry, initial);
      if (sources.cloudConflict(initial.key)) {
        _cloudConflict = true;
        throw const SourceException(SourceFailure.conflict);
      }
      sources.holdProgress(initial.key);
      if (await sources.repository.remoteConflict(_profile!, initial.key) != null) {
        throw const SourceException(SourceFailure.conflict);
      }
      _settings = normalizeReaderPreferences(await sources.repository.preference(_profile!, 'reader'));
      _annotations = (await sources.repository.annotations(
        _profile!,
        widget.entry.key,
      )).where((a) => a.edition == widget.file.fingerprint && a.mode == PublicationMode.reading).toList();
      final temp = await getTemporaryDirectory();
      final cached = await sources.downloads.local(_profile!, widget.entry.sourceId, widget.file);
      final pages = cached == null && sources.sources.any((s) => s.id == widget.entry.sourceId)
          ? await sources.adapter(widget.entry.sourceId).comicPages(widget.file)
          : null;
      if (!valid) return;
      if (pages == null) _file = await sources.content(widget.entry, widget.file);
      if (!valid) return;
      if (!pdf || pages != null) {
        final archive = pages != null
            ? await PublicationArchive.stream(pages, temp)
            : await PublicationArchive.open(_file!, temp, comic: widget.file.kind == SourceItemKind.comic);
        if (!valid) {
          await archive.close();
          return;
        }
        _server = PublicationServer(archive, valid: () => valid, onEvent: Platform.isLinux ? _bridge : null);
        _url = await _server!.start();
        if (Platform.isLinux) {
          _url = _url!.replace(queryParameters: {'external': '1'});
          await launchUrl(_url!, mode: LaunchMode.externalApplication);
        }
      }
      if (valid && mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  void _profileChanged() {
    if (!valid) {
      unawaited(_stopSpeech());
      unawaited(_server?.close());
      if (mounted) setState(() => _error = const SourceException(SourceFailure.cancelled));
    }
  }

  Future<dynamic> _js(String method, [Object? argument]) async {
    if (!valid) return null;
    if (Platform.isLinux) return _server?.execute(method, argument);
    if (_web == null) return null;
    final result = await _web!.callAsyncJavaScript(
      functionBody: 'return await window.publication[method](argument);',
      arguments: {'method': method, 'argument': argument},
    );
    if (result?.error != null) throw const SourceException(SourceFailure.invalidData);
    return result?.value;
  }

  Map<String, dynamic> readerSettings() {
    final theme = tokens(context), choice = _settings['theme'] ?? 'app';
    final dark = choice == 'night' || choice == 'app' && Theme.of(context).brightness == Brightness.dark;
    String hex(Color c) => '#${c.toARGB32().toRadixString(16).substring(2)}';
    final background = switch (choice) {
      'paper' => '#faf8f3',
      'sepia' => '#efe4cf',
      'night' => '#131313',
      _ => hex(theme.bg),
    };
    final foreground = switch (choice) {
      'paper' => '#202020',
      'sepia' => '#342e24',
      'night' => '#e7e4dc',
      _ => hex(theme.text),
    };
    return {
      ..._settings,
      'dark': dark,
      'background': background,
      'foreground': foreground,
      'reduceMotion': MediaQuery.disableAnimationsOf(context),
      'textScale': MediaQuery.textScalerOf(context).scale(20) / 20,
    };
  }

  Future<void> _bridge(List<dynamic> args) async {
    if (!valid || args.length != 1) return;
    final message = sourceMap(args.first);
    switch (message['type']) {
      case 'engineReady':
        await _js('open', {
          'title': widget.entry.title,
          'interfaceLocale': LocaleSettings.currentLocale.languageTag,
          'formattingLocale': LocalePreferences.formattingLocaleName.replaceAll('_', '-'),
          'interfaceDirection': Directionality.of(context) == TextDirection.rtl ? 'rtl' : 'ltr',
          'cfi': _progress?.locator?.cfi,
          'settings': readerSettings(),
          'iconStyle': {'fill': AppIconDefaults.fill, 'weight': AppIconDefaults.weight},
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
          'labels': {
            'zoomIn': t.fileSources.zoomIn,
            'zoomOut': t.fileSources.zoomOut,
            'zoom': t.fileSources.zoom,
            'actualSize': t.fileSources.actualSize,
            'font': t.fileSources.font,
            'serif': t.fileSources.serif,
            'sans': t.fileSources.sans,
            'mono': t.fileSources.mono,
            'theme': t.fileSources.readerTheme,
            'app': t.fileSources.appTheme,
            'paper': t.fileSources.paper,
            'sepia': t.fileSources.sepia,
            'night': t.fileSources.night,
            'lineHeight': t.fileSources.lineHeight,
            'margin': t.fileSources.margin,
            'justify': t.fileSources.justify,
            'reset': t.fileSources.resetReader,
            'fitPage': t.fileSources.fitPage,
            'fitWidth': t.fileSources.fitWidth,
            'pageLayout': t.fileSources.pageLayout,
            'singlePage': t.fileSources.singlePage,
            'twoPages': t.fileSources.twoPages,
            'readingDirection': t.fileSources.readingDirection,
            'automatic': t.fileSources.automatic,
            'leftToRight': t.fileSources.leftToRight,
            'rightToLeft': t.fileSources.rightToLeft,
            'imagePage': t.fileSources.imagePage,
            'goToPage': t.fileSources.goToPage,
            'goToSection': t.fileSources.goToSection,
            'letterSpacing': t.fileSources.letterSpacing,
            'wordSpacing': t.fileSources.wordSpacing,
            'prev': t.fileSources.previousPage,
            'next': t.fileSources.nextPage,
            'toc': t.fileSources.contents,
            'search': t.fileSources.searchBook,
            'note': t.fileSources.bookmarks,
            'notes': t.fileSources.bookmarks,
            'addNote': t.fileSources.note,
            'bookmark': t.fileSources.bookmark,
            'settings': t.fileSources.readerSettings,
            'full': t.fileSources.fullscreen,
            'speak': t.fileSources.readAloud,
            'close': t.fileSources.close,
            'save': t.fileSources.save,
            'fontSize': t.fileSources.fontSize,
            'columns': t.fileSources.columns,
            'scrolled': t.fileSources.scroll,
            'on': t.fileSources.on,
            'off': t.common.off,
            'error': t.fileSources.errorUnavailable,
            'disconnected': t.fileSources.errorCancelled,
            'noMatches': t.fileSources.noMatches,
            'pageRange': t.fileSources.pageRange(count: '{count}'),
          },
          'annotations': _annotations
              .where((a) => a.locator?.cfi != null)
              .map((a) => {'id': a.id, 'value': a.locator!.cfi, 'color': a.color, 'note': a.note, 'quote': a.quote})
              .toList(),
        });
      case 'cover':
        final data = message['data'] as String?;
        if (data != null && data.length < 6 * 1024 * 1024 && data.contains(',')) {
          await _sources!.saveCover(widget.entry, base64Decode(data.split(',').last));
        }
      case 'ready':
        _toc = sourceList(message['toc']).map(sourceMap).toList();
        _overlays = sourceList(
          message['overlays'],
        ).take(100000).map(sourceMap).where((m) => _server!.archive.files.containsKey(m['audio'])).toList();
        if (mounted) setState(() => _ready = true);
      case 'location':
        if (_progress == null) return;
        final fraction = (message['fraction'] as num?)?.toDouble() ?? 0;
        _progress = _progress!.copyWith(
          locator: ReadingLocator(
            cfi: message['cfi'] as String?,
            href: message['href'] as String? ?? '',
            page: (sourceInt(message['section']) ?? 0) + 1,
            progression: fraction,
            text: message['text'] as String? ?? '',
          ),
          fraction: fraction,
        );
        if (mounted) setState(() => _chapter = message['title'] as String? ?? '');
        _scheduleSave();
      case 'selection':
        if (mounted) {
          setState(() {
            _selectedCFI = message['cfi'] as String?;
            _selectedText = message['quote'] as String?;
          });
        }
      case 'viewState':
        if (mounted) {
          setState(() {
            _fixed = message['fixed'] == true;
            _pages = sourceInt(message['pages']) ?? 0;
            _viewZoom = message['zoom'] is num ? message['zoom'] as num : '${message['zoom'] ?? 'fit-page'}';
          });
        }
      case 'readerSetting':
        final key = message['key'];
        if (key == 'fontSize' || key == 'zoom') {
          final value = message['value'];
          if (value is num && value.isFinite) {
            _settings['$key'] = value.clamp(key == 'zoom' ? .25 : 12, key == 'zoom' ? 6 : 72);
          }
          if (key == 'zoom' && const ['fit-page', 'fit-width'].contains(value)) _settings['zoom'] = value;
          await _sources!.repository.savePreference(_profile!, 'reader', _settings);
        }
      case 'browserSettings':
        final value = sourceMap(message['settings']);
        _settings = normalizeReaderPreferences(message['reset'] == true ? {} : {..._settings, ...value});
        await _sources!.repository.savePreference(_profile!, 'reader', _settings);
        await _js('settings', readerSettings());
      case 'browserSpeech':
        if (Platform.isLinux) {
          if (message['stop'] == true) {
            await _stopSpeech();
            return;
          }
          await _playback!.stop();
          await PlaybackCoordinator.instance.claimFiles();
          if (valid) await _js('toggleSpeech');
        }
      case 'saveNote':
        final cfi = message['cfi'] as String? ?? _progress?.locator?.cfi;
        if (cfi == null || cfi.length > 8192) return;
        final annotation = BookAnnotation(
          id: const Uuid().v4(),
          entryKey: widget.entry.key,
          edition: widget.file.fingerprint,
          mode: PublicationMode.reading,
          locator: ReadingLocator(cfi: cfi, href: _progress?.locator?.href ?? ''),
          note: (message['note'] as String? ?? '').substring(
            0,
            (message['note'] as String? ?? '').length.clamp(0, 10000),
          ),
          quote: (message['quote'] as String? ?? '').substring(
            0,
            (message['quote'] as String? ?? '').length.clamp(0, 10000),
          ),
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
        await _sources!.repository.saveAnnotation(_profile!, annotation);
        _annotations.add(annotation);
        await _js('annotate', {
          'id': annotation.id,
          'value': cfi,
          'color': annotation.color,
          'note': annotation.note,
          'quote': annotation.quote,
        });
      case 'annotation':
        final note = _annotations.where((a) => a.locator?.cfi == message['cfi']).firstOrNull;
        if (note != null) await _addNote(existing: note);
      case 'externalLink':
        if (mounted) showSnackBar(context, t.fileSources.externalBlocked);
      case 'escape':
        if (mounted) await Navigator.maybePop(context);
    }
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 700), () => unawaited(_flush()));
  }

  Future<void> _flush() {
    _saveTimer?.cancel();
    final snapshot = _progress, profile = _profile, sources = _sources;
    if (snapshot == null || profile == null || sources == null) return Future.value();
    final write = _writes.then((_) async {
      final saved = await sources.repository.saveProgress(
        profile,
        snapshot.copyWith(revision: _progress?.revision ?? snapshot.revision),
      );
      // A layout event arriving during a write keeps its newer cursor.
      _progress = _progress?.copyWith(revision: saved.revision, updatedAt: saved.updatedAt);
      if (valid) sources.scheduleSync();
    });
    _writes = write.catchError((Object e) {
      if (mounted && !_disposed) setState(() => _error = e);
    });
    return _writes;
  }

  Future<void> _addNote({BookAnnotation? existing, String? quote}) async {
    if (!valid || _progress == null) return;
    final selected = quote ?? _selectedText ?? existing?.quote ?? '';
    final note = await editSourceNote(context, initial: existing?.note ?? '', quote: selected);
    if (note == null || !valid) return;
    final cfi = existing?.locator?.cfi ?? _selectedCFI ?? _progress!.locator?.cfi;
    final locator = ReadingLocator(
      cfi: cfi,
      href: _progress!.locator?.href ?? '',
      page: _progress!.locator?.page,
      progression: _progress!.fraction,
      text: selected,
    );
    final annotation = BookAnnotation(
      id: existing?.id ?? const Uuid().v4(),
      entryKey: widget.entry.key,
      edition: widget.file.fingerprint,
      mode: PublicationMode.reading,
      locator: locator,
      note: note,
      quote: selected,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _sources!.repository.saveAnnotation(_profile!, annotation);
    _annotations.removeWhere((a) => a.id == annotation.id);
    _annotations.add(annotation);
    if (cfi != null) await _js('annotate', {'value': cfi, 'color': annotation.color});
    if (mounted) {
      setState(() {
        _selectedCFI = null;
        _selectedText = null;
      });
    }
  }

  Future<void> _notes() async {
    final annotation = await Navigator.push<BookAnnotation>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SourceNotesScreen(entry: widget.entry, edition: widget.file.fingerprint, mode: PublicationMode.reading),
      ),
    );
    if (!valid) return;
    final latest = (await _sources!.repository.annotations(
      _profile!,
      widget.entry.key,
    )).where((a) => a.edition == widget.file.fingerprint).toList();
    for (final removed in _annotations.where((a) => !latest.any((n) => n.id == a.id))) {
      if (removed.locator?.cfi != null) await _js('remove', removed.locator!.cfi);
    }
    _annotations = latest;
    if (annotation == null) return;
    if (pdf && annotation.locator?.page != null) {
      await _pdf.goToPage(pageNumber: annotation.locator!.page!);
    } else if (annotation.locator?.cfi != null) {
      await _js('goTo', annotation.locator!.cfi);
    }
  }

  Duration get _motionDuration =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 150);
  Future<void> _zoom(String action) async {
    if (!_ready) return;
    if (!pdf) {
      await _js('zoom', action);
      return;
    }
    if (!_pdf.isReady) return;
    switch (action) {
      case 'in':
        await _pdf.zoomUp(duration: _motionDuration);
      case 'out':
        await _pdf.zoomDown(duration: _motionDuration);
      case 'fit-width':
        await _pdf.goTo(_pdf.calcMatrixFitWidthForPage(pageNumber: _pdf.pageNumber ?? 1), duration: _motionDuration);
      case 'actual':
        await _pdf.setZoom(_pdf.centerPosition, 1, duration: _motionDuration);
      default:
        await _pdf.goTo(_pdf.calcMatrixForFit(pageNumber: _pdf.pageNumber ?? 1), duration: _motionDuration);
    }
    if (mounted) setState(() => _viewZoom = _pdf.currentZoom);
  }

  Future<void> _jumpToPage() async {
    if (_pages < 1) return;
    final input = TextEditingController(
      text: formatDecimal(pdf ? _pdf.pageNumber ?? 1 : (_progress?.locator?.page ?? 1), maximumDecimals: 0),
    );
    final form = GlobalKey<FormState>();
    final page = await showScopedDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(pdf || _fixed ? t.fileSources.goToPage : t.fileSources.goToSection),
        content: Form(
          key: form,
          child: FocusableTextFormField(
            controller: input,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(helperText: t.fileSources.pageRange(count: formatCount(_pages))),
            validator: (value) {
              final n = parseLocalizedInteger(value ?? '');
              return n != null && n >= 1 && n <= _pages ? null : t.fileSources.pageRange(count: formatCount(_pages));
            },
            onFieldSubmitted: (_) {
              if (form.currentState!.validate()) Navigator.pop(context, parseLocalizedInteger(input.text));
            },
          ),
        ),
        actions: [
          DialogActionButton(onPressed: () => Navigator.pop(context), label: t.fileSources.cancel),
          DialogActionButton(
            onPressed: () {
              if (form.currentState!.validate()) Navigator.pop(context, parseLocalizedInteger(input.text));
            },
            label: t.fileSources.goToPage,
            isPrimary: true,
          ),
        ],
      ),
    );
    unawaited(Future<void>.delayed(const Duration(seconds: 1), input.dispose));
    if (!valid || page == null) return;
    if (pdf) {
      await _pdf.goToPage(pageNumber: page, duration: _motionDuration);
    } else {
      await _js('page', page);
    }
  }

  Future<void> _navigate(bool next) async {
    await _stopSpeech();
    if (pdf) {
      if (_pdf.isReady) await _pdf.goToPage(pageNumber: ((_pdf.pageNumber ?? 1) + (next ? 1 : -1)).clamp(1, _pages));
    } else {
      await _js(next ? 'next' : 'prev');
    }
  }

  Future<void> _contents() async {
    final target = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => _ReaderContents(items: _toc)),
    );
    if (!valid || target == null) return;
    if (pdf) {
      await _pdf.goToPage(pageNumber: sourceInt(target['page']) ?? 1);
    } else {
      await _js('goTo', target['href']);
    }
  }

  Future<void> _search() async {
    if (pdf) {
      if (!_pdf.isReady) return;
      _pdfSearch ??= PdfTextSearcher(_pdf);
      await Navigator.push(context, MaterialPageRoute(builder: (_) => _PdfSearchScreen(search: _pdfSearch!)));
    } else {
      final cfi = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              _BookSearchScreen(search: (q) async => sourceList(await _js('search', q)).map(sourceMap).toList()),
        ),
      );
      if (cfi != null && valid) await _js('goTo', cfi);
    }
  }

  Future<void> _preferences() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReaderSettingsScreen(
          settings: _settings,
          fixed: _fixed,
          onChanged: (value) async {
            if (!valid) return;
            _settings = normalizeReaderPreferences(value);
            await _sources!.repository.savePreference(_profile!, 'reader', _settings);
            await _js('settings', readerSettings());
          },
        ),
      ),
    );
  }

  Future<void> _speak() async {
    if (_speaking) {
      await _stopSpeech();
      return;
    }
    await _playback!.stop();
    await PlaybackCoordinator.instance.claimFiles();
    String text;
    if (pdf) {
      text = (await _pdf.document.pages[(_pdf.pageNumber ?? 1) - 1].loadText())?.fullText ?? '';
    } else {
      text = (await _js('visibleText')) as String? ?? '';
    }
    if (text.trim().isEmpty || !valid) return;
    _tts ??= FlutterTts();
    _tts!.setCompletionHandler(() {
      if (mounted) setState(() => _speaking = false);
    });
    _tts!.setErrorHandler((_) {
      if (mounted) setState(() => _speaking = false);
    });
    await _tts!.setSpeechRate(.5);
    if (widget.entry.language.isNotEmpty) await _tts!.setLanguage(widget.entry.language);
    if (valid) {
      setState(() => _speaking = true);
      await _tts!.speak(text);
    }
  }

  Future<void> _stopSpeech() async {
    await _tts?.stop();
    if (Platform.isLinux && valid && _server != null) {
      try {
        await _js('stopSpeech');
      } catch (_) {
        // A closed browser has already stopped speech and retired its socket.
      }
    }
    if (mounted && !_disposed && _speaking) setState(() => _speaking = false);
  }

  Future<void> _startReadAlong() async {
    if (_readAlong) {
      await _playback!.pause();
      _playback!.removeListener(_followAudio);
      setState(() => _readAlong = false);
      return;
    }
    await _stopSpeech();
    final names = _overlays.map((o) => o['audio'] as String).toSet().toList();
    final files = names
        .map(
          (name) => PublicationFile(
            id: 'overlay:${widget.file.fingerprint}:$name',
            name: name,
            mimeType: 'audio/mp4',
            revision: widget.file.fingerprint,
            size: _server!.archive.files[name],
            durationMs: _overlays
                .where((o) => o['audio'] == name)
                .map((o) => sourceInt(o['endMs']) ?? 0)
                .fold<int>(0, (a, b) => a > b ? a : b),
          ),
        )
        .toList();
    await _playback!.start(
      widget.entry,
      files,
      localOverrides: {
        for (var i = 0; i < files.length; i++)
          files[i].id: File(p.joinAll([_server!.archive.directory.path, ...names[i].split('/')])).uri,
      },
    );
    if (!valid) return;
    _playback!.addListener(_followAudio);
    setState(() => _readAlong = true);
    _followAudio();
  }

  void _followAudio() {
    if (!valid || !_readAlong || _playback?.entry?.key != widget.entry.key) return;
    final file = _playback!.files[_playback!.fileIndex];
    final name = file.name, position = _playback!.player?.currentPosition.inMilliseconds ?? 0;
    final clip = _overlays
        .where(
          (o) =>
              o['audio'] == name &&
              position >= (sourceInt(o['beginMs']) ?? 0) &&
              position < (sourceInt(o['endMs']) ?? 0),
        )
        .firstOrNull;
    final href = clip?['href'] as String?;
    if (href != null && href != _overlayHref) {
      _overlayHref = href;
      unawaited(_js('highlightHref', href));
    }
  }

  Future<void> _pdfReady(PdfDocument document, PdfViewerController controller) async {
    if (!valid) return;
    _pages = document.pages.length;
    List<Map<String, dynamic>> flatten(List<PdfOutlineNode> nodes, int depth) => nodes
        .expand(
          (node) => [
            {'title': node.title, 'page': node.dest?.pageNumber ?? 1, 'depth': depth},
            ...flatten(node.children, depth + 1),
          ],
        )
        .toList();
    final outline = await document.loadOutline();
    if (valid && mounted) {
      setState(() {
        _ready = true;
        _toc = flatten(outline, 0);
      });
    }
  }

  @override
  void dispose() {
    final syncSources = _sources, syncKey = _progress?.key;
    if (syncSources != null && syncKey != null) {
      unawaited(
        _flush().whenComplete(() {
          syncSources.releaseProgress(syncKey);
          syncSources.scheduleSync();
        }),
      );
    }
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _sources?.removeListener(_profileChanged);
    _playback?.removeListener(_followAudio);
    PlaybackCoordinator.instance.unregisterNarrationSession(_stopSpeech);
    _saveTimer?.cancel();
    unawaited(_stopSpeech());
    _pdfSearch?.dispose();
    final session = _playback, server = _server;
    unawaited(() async {
      try {
        if (session?.entry?.key == widget.entry.key && session!.files.any((f) => f.id.startsWith('overlay:'))) {
          await session.stop();
        }
      } catch (_) {
        // Native retirement failure must not retain a reader capability.
      } finally {
        await server?.close();
      }
    }());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = _error != null
        ? Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SourceErrorMessage(message: sourceFailureText(_error!), textAlign: TextAlign.center),
                  if (_cloudConflict) ...[
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () =>
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SourceSyncScreen())),
                      icon: const AppIcon(Symbols.cloud_sync_rounded),
                      label: Text(t.audiobook.syncTitle),
                    ),
                  ],
                ],
              ),
            ),
          )
        : _loading
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(value: _transfer),
                const SizedBox(height: 16),
                Text(t.fileSources.loading),
              ],
            ),
          )
        : pdf
        ? PdfViewer.file(
            _file!.path,
            controller: _pdf,
            initialPageNumber: _progress?.locator?.page ?? 1,
            params: PdfViewerParams(
              backgroundColor: tokens(context).bg,
              forceEnableTextSemantics: true,
              onViewerReady: (document, controller) => unawaited(_pdfReady(document, controller)),
              pagePaintCallbacks: [if (_pdfSearch != null) _pdfSearch!.pageTextMatchPaintCallback],
              onPageChanged: (page) {
                if (!valid || page == null || _progress == null) return;
                _progress = _progress!.copyWith(
                  locator: ReadingLocator(href: '', page: page),
                  fraction: _pages > 0 ? page / _pages : 0,
                );
                _scheduleSave();
                if (mounted) setState(() => _chapter = t.fileSources.page(number: formatCount(page)));
              },
              customizeContextMenuItems: (params, items) {
                items.add(
                  ContextMenuButtonItem(
                    label: t.fileSources.note,
                    onPressed: () {
                      params.dismissContextMenu();
                      unawaited(
                        sourceAction(context, () async {
                          final quote = await params.textSelectionDelegate.getSelectedText();
                          if (mounted) await _addNote(quote: quote);
                        }),
                      );
                    },
                  ),
                );
              },
              linkHandlerParams: PdfLinkHandlerParams(
                onLinkTap: (link) async {
                  if (link.dest != null) {
                    await _pdf.goToDest(link.dest!);
                  } else if (mounted) {
                    showSnackBar(context, t.fileSources.externalBlocked);
                  }
                },
              ),
            ),
          )
        : Platform.isLinux
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 160, height: 240, child: SourceCover(entry: widget.entry)),
                  const SizedBox(height: 24),
                  Text(t.fileSources.browserReaderHelp, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => launchUrl(_url!, mode: LaunchMode.externalApplication),
                    icon: const AppIcon(Symbols.open_in_new_rounded),
                    label: Text(t.fileSources.browserReader),
                  ),
                ],
              ),
            ),
          )
        : InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(_url.toString())),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              transparentBackground: true,
              disableContextMenu: false,
              javaScriptCanOpenWindowsAutomatically: false,
              supportMultipleWindows: false,
              allowFileAccess: false,
              allowContentAccess: false,
              javaScriptHandlersForMainFrameOnly: true,
              javaScriptBridgeForMainFrameOnly: true,
              javaScriptBridgeOriginAllowList: {'http://127.0.0.1:${_url!.port}'},
              useShouldOverrideUrlLoading: true,
              mediaPlaybackRequiresUserGesture: true,
            ),
            onWebViewCreated: (controller) {
              _web = controller;
              controller.addJavaScriptHandler(
                handlerName: 'publication',
                callback: (arguments) async {
                  try {
                    await _bridge(arguments);
                  } catch (e) {
                    if (mounted && valid) setState(() => _error = e);
                  }
                  return null;
                },
              );
            },
            shouldOverrideUrlLoading: (_, action) async {
              final url = action.request.url?.toString() ?? '';
              if (url == _url.toString() || url.startsWith('blob:http://127.0.0.1:${_url!.port}/')) {
                return NavigationActionPolicy.ALLOW;
              }
              return NavigationActionPolicy.CANCEL;
            },
            onReceivedError: (_, request, error) {
              if (request.isForMainFrame == true && mounted) {
                setState(() => _error = const SourceException(SourceFailure.unavailable));
              }
            },
            onPermissionRequest: (_, request) async =>
                PermissionResponse(resources: request.resources, action: PermissionResponseAction.DENY),
          );
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: t.fileSources.contents,
            onPressed: _ready ? () => sourceAction(context, _contents) : null,
            icon: const AppIcon(Symbols.format_list_bulleted_rounded),
          ),
          IconButton(
            tooltip: t.fileSources.searchBook,
            onPressed: _ready ? () => sourceAction(context, _search) : null,
            icon: const AppIcon(Symbols.search_rounded),
          ),
          AppMenuButton<String>(
            icon: const AppIcon(Symbols.more_vert_rounded),
            tooltip: t.fileSources.preferences,
            adaptiveSheet: true,
            enabled: _ready,
            entriesBuilder: (_) => [
              AppMenuItem(
                value: 'note',
                label: _selectedCFI == null ? t.fileSources.bookmark : t.fileSources.highlight,
                icon: Symbols.bookmark_add_rounded,
              ),
              AppMenuItem(value: 'notes', label: t.fileSources.bookmarks, icon: Symbols.bookmarks_rounded),
              AppMenuItem(
                value: 'jump',
                label: pdf || _fixed ? t.fileSources.goToPage : t.fileSources.goToSection,
                icon: Symbols.numbers_rounded,
              ),
              if (pdf || _fixed) ...[
                AppMenuItem(value: 'fit-page', label: t.fileSources.fitPage, icon: Symbols.fit_screen_rounded),
                AppMenuItem(value: 'fit-width', label: t.fileSources.fitWidth, icon: Symbols.width_rounded),
                AppMenuItem(value: 'actual', label: t.fileSources.actualSize, icon: Symbols.zoom_in_rounded),
              ],
              if (!pdf)
                AppMenuItem(value: 'settings', label: t.fileSources.readerSettings, icon: Symbols.text_fields_rounded),
              if (!Platform.isLinux)
                AppMenuItem(
                  value: 'tts',
                  label: _speaking ? t.fileSources.stopReading : t.fileSources.readAloud,
                  icon: Symbols.record_voice_over_rounded,
                ),
              if (_overlays.isNotEmpty)
                AppMenuItem(
                  value: 'along',
                  label: _readAlong ? t.fileSources.pause : t.fileSources.readAlong,
                  icon: Symbols.headphones_rounded,
                ),
              AppMenuItem(value: 'finished', label: t.fileSources.markFinished, icon: Symbols.done_rounded),
            ],
            onSelected: (action) => sourceAction(context, () async {
              switch (action) {
                case 'jump':
                  await _jumpToPage();
                case 'fit-page':
                case 'fit-width':
                case 'actual':
                  await _zoom(action == 'actual' && !pdf ? 'actual' : action);
                case 'note':
                  await _addNote();
                case 'notes':
                  await _notes();
                case 'settings':
                  await _preferences();
                case 'tts':
                  await _speak();
                case 'along':
                  await _startReadAlong();
                case 'finished':
                  _progress = _progress?.copyWith(finished: true);
                  await _flush();
                  if (context.mounted) Navigator.pop(context);
              }
            }),
          ),
        ],
      ),
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.equal, control: true): () =>
              unawaited(sourceAction(context, () => _zoom('in'))),
          const SingleActivator(LogicalKeyboardKey.minus, control: true): () =>
              unawaited(sourceAction(context, () => _zoom('out'))),
          const SingleActivator(LogicalKeyboardKey.digit0, control: true): () =>
              unawaited(sourceAction(context, () => _zoom('fit-page'))),
          const SingleActivator(LogicalKeyboardKey.equal, control: true, shift: true): () =>
              unawaited(sourceAction(context, () => _zoom('in'))),
          const SingleActivator(LogicalKeyboardKey.equal, meta: true): () =>
              unawaited(sourceAction(context, () => _zoom('in'))),
          const SingleActivator(LogicalKeyboardKey.equal, meta: true, shift: true): () =>
              unawaited(sourceAction(context, () => _zoom('in'))),
          const SingleActivator(LogicalKeyboardKey.minus, meta: true): () =>
              unawaited(sourceAction(context, () => _zoom('out'))),
          const SingleActivator(LogicalKeyboardKey.digit0, meta: true): () =>
              unawaited(sourceAction(context, () => _zoom('fit-page'))),
        },
        child: SafeArea(child: body),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              IconButton(
                tooltip: t.fileSources.previousPage,
                onPressed: _ready ? () => sourceAction(context, () => _navigate(false)) : null,
                icon: AppIcon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Symbols.chevron_right_rounded
                      : Symbols.chevron_left_rounded,
                ),
              ),
              Expanded(
                child: Text(
                  [
                    _chapter,
                    if (_progress != null) formatPercent(_progress!.fraction),
                  ].where((part) => part.isNotEmpty).join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                tooltip: t.fileSources.zoomOut,
                onPressed: _ready ? () => sourceAction(context, () => _zoom('out')) : null,
                icon: const AppIcon(Symbols.zoom_out_rounded),
              ),
              IconButton(
                tooltip: '${t.fileSources.zoomIn}${_viewZoom is num ? ' (${formatPercent(_viewZoom as num)})' : ''}',
                onPressed: _ready ? () => sourceAction(context, () => _zoom('in')) : null,
                icon: const AppIcon(Symbols.zoom_in_rounded),
              ),
              IconButton(
                tooltip: t.fileSources.nextPage,
                onPressed: _ready ? () => sourceAction(context, () => _navigate(true)) : null,
                icon: AppIcon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Symbols.chevron_left_rounded
                      : Symbols.chevron_right_rounded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReaderContents extends StatelessWidget {
  const _ReaderContents({required this.items});
  final List<Map<String, dynamic>> items;
  @override
  Widget build(BuildContext context) => FocusedScrollScaffold(
    title: Text(t.fileSources.contents),
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.all(24),
        sliver: SliverList.builder(
          itemCount: items.length,
          itemBuilder: (context, i) => Padding(
            padding: EdgeInsetsDirectional.only(start: (sourceInt(items[i]['depth']) ?? 0).clamp(0, 5) * 16.0),
            child: SourceTile(
              title: items[i]['title'] as String? ?? '',
              index: i,
              count: items.length,
              onTap: () => Navigator.pop(context, items[i]),
              icon: Symbols.menu_book_rounded,
            ),
          ),
        ),
      ),
    ],
  );
}

class _BookSearchScreen extends StatefulWidget {
  const _BookSearchScreen({required this.search});
  final Future<List<Map<String, dynamic>>> Function(String) search;
  @override
  State<_BookSearchScreen> createState() => _BookSearchScreenState();
}

class _BookSearchScreenState extends State<_BookSearchScreen> {
  final _query = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;
  int _epoch = 0;
  Future<void> _search(String query) async {
    final epoch = ++_epoch;
    setState(() => _searching = true);
    try {
      final result = await widget.search(query);
      if (mounted && epoch == _epoch) setState(() => _results = result);
    } finally {
      if (mounted && epoch == _epoch) setState(() => _searching = false);
    }
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FocusedScrollScaffold(
    title: Text(t.fileSources.searchBook),
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.all(24),
        sliver: SliverToBoxAdapter(
          child: Column(
            children: [
              FocusableTextField(
                controller: _query,
                autofocus: true,
                onSubmitted: (q) => sourceAction(context, () => _search(q)),
                decoration: InputDecoration(
                  labelText: t.fileSources.searchBook,
                  suffixIcon: const AppIcon(Symbols.search_rounded),
                ),
              ),
              if (_searching) const LinearProgressIndicator(),
              if (!_searching && _results.isEmpty)
                Padding(padding: const EdgeInsets.all(24), child: Text(t.fileSources.noMatches)),
            ],
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        sliver: SliverList.builder(
          itemCount: _results.length,
          itemBuilder: (context, i) => SourceTile(
            title: _results[i]['text'] as String? ?? '',
            index: i,
            count: _results.length,
            onTap: () => Navigator.pop(context, _results[i]['cfi']),
          ),
        ),
      ),
    ],
  );
}

class _PdfSearchScreen extends StatefulWidget {
  const _PdfSearchScreen({required this.search});
  final PdfTextSearcher search;
  @override
  State<_PdfSearchScreen> createState() => _PdfSearchScreenState();
}

class _PdfSearchScreenState extends State<_PdfSearchScreen> {
  final _query = TextEditingController();
  @override
  void initState() {
    super.initState();
    widget.search.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.search.removeListener(_changed);
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FocusedScrollScaffold(
    title: Text(t.fileSources.searchBook),
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.all(24),
        sliver: SliverToBoxAdapter(
          child: Column(
            children: [
              FocusableTextField(
                controller: _query,
                autofocus: true,
                onChanged: widget.search.startTextSearch,
                decoration: InputDecoration(labelText: t.fileSources.searchBook),
              ),
              if (widget.search.isSearching) const LinearProgressIndicator(),
              for (var i = 0; i < widget.search.matches.length; i++)
                SourceTile(
                  title: t.fileSources.page(number: formatCount(widget.search.matches[i].pageNumber)),
                  onTap: () async {
                    await widget.search.goToMatchOfIndex(i);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
      ),
    ],
  );
}

class ReaderSettingsScreen extends StatefulWidget {
  const ReaderSettingsScreen({super.key, required this.settings, required this.onChanged, this.fixed = false});
  final bool fixed;
  final Map<String, dynamic> settings;
  final Future<void> Function(Map<String, dynamic>) onChanged;
  @override
  State<ReaderSettingsScreen> createState() => _ReaderSettingsScreenState();
}

class _ReaderSettingsScreenState extends State<ReaderSettingsScreen> {
  late Map<String, dynamic> value = normalizeReaderPreferences(widget.settings);
  void set(String key, Object v) {
    setState(() => value[key] = v);
    unawaited(sourceAction(context, () => widget.onChanged({...value})));
  }

  @override
  Widget build(BuildContext context) => FocusedScrollScaffold(
    title: Text(t.fileSources.readerSettings),
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.all(24),
        sliver: SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.fileSources.readerControlsHelp),
              const SizedBox(height: 24),
              if (widget.fixed)
                for (final option in [
                  (
                    'spread',
                    t.fileSources.pageLayout,
                    {
                      'auto': t.fileSources.automatic,
                      'single': t.fileSources.singlePage,
                      'double': t.fileSources.twoPages,
                    },
                  ),
                  (
                    'direction',
                    t.fileSources.readingDirection,
                    {
                      'auto': t.fileSources.automatic,
                      'ltr': t.fileSources.leftToRight,
                      'rtl': t.fileSources.rightToLeft,
                    },
                  ),
                ]) ...[
                  DropdownButtonFormField<String>(
                    key: ValueKey('${option.$1}:${value[option.$1]}'),
                    isExpanded: true,
                    initialValue: value[option.$1] as String? ?? 'auto',
                    decoration: InputDecoration(labelText: option.$2),
                    items: [
                      for (final entry in option.$3.entries)
                        DropdownMenuItem(value: entry.key, child: Text(entry.value)),
                    ],
                    onChanged: (v) {
                      if (v != null) set(option.$1, v);
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              Text(t.fileSources.readerTheme),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final choice in {
                    'app': t.fileSources.appTheme,
                    'paper': t.fileSources.paper,
                    'sepia': t.fileSources.sepia,
                    'night': t.fileSources.night,
                  }.entries)
                    ChoiceChip(
                      label: Text(choice.value),
                      selected: (value['theme'] ?? 'app') == choice.key,
                      onSelected: (_) => set('theme', choice.key),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              if (!widget.fixed) ...[
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  key: ValueKey(value['font']),
                  initialValue: value['font'] as String? ?? 'serif',
                  decoration: InputDecoration(labelText: t.fileSources.font),
                  items: [
                    for (final entry in {
                      'serif': t.fileSources.serif,
                      'sans': t.fileSources.sans,
                      'mono': t.fileSources.mono,
                    }.entries)
                      DropdownMenuItem(value: entry.key, child: Text(entry.value)),
                  ],
                  onChanged: (v) {
                    if (v != null) set('font', v);
                  },
                ),
                for (final row in [
                  ('fontSize', t.fileSources.fontSize, 12.0, 72.0, 20.0),
                  ('letterSpacing', t.fileSources.letterSpacing, 0.0, .3, 0.0),
                  ('wordSpacing', t.fileSources.wordSpacing, 0.0, .5, 0.0),
                  ('lineHeight', t.fileSources.lineHeight, 1.0, 2.5, 1.6),
                  ('margin', t.fileSources.margin, 2.0, 20.0, 8.0),
                ]) ...[
                  const SizedBox(height: 24),
                  Text(row.$2),
                  FocusableSlider(
                    min: row.$3,
                    max: row.$4,
                    value: ((value[row.$1] as num?)?.toDouble() ?? row.$5).clamp(row.$3, row.$4),
                    semanticLabel: row.$2,
                    semanticFormatterCallback: (v) =>
                        '${row.$2}: ${formatDecimal(v, maximumDecimals: row.$1 == 'fontSize' ? 0 : 2)}',
                    onChanged: (v) => setState(() => value[row.$1] = v),
                    onChangeEnd: (v) => set(row.$1, v),
                  ),
                ],
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.fileSources.scroll),
                  value: value['scrolled'] == true,
                  onChanged: (v) => set('scrolled', v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.fileSources.justify),
                  value: value['justify'] == true,
                  onChanged: (v) => set('justify', v),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.fileSources.columns),
                  trailing: DropdownButton<int>(
                    value: sourceInt(value['columns']) ?? 2,
                    items: [
                      for (final n in [1, 2]) DropdownMenuItem(value: n, child: Text('$n')),
                    ],
                    onChanged: (v) {
                      if (v != null) set('columns', v);
                    },
                  ),
                ),
              ],
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: () {
                  setState(() => value = normalizeReaderPreferences({}));
                  unawaited(sourceAction(context, () => widget.onChanged({...value})));
                },
                icon: const AppIcon(Symbols.restart_alt_rounded),
                label: Text(t.fileSources.resetReader),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
