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
import '../../focus/focusable_slider.dart';
import '../../services/playback_coordinator.dart';
import '../../sources/publication_archive.dart';
import '../../sources/source_controller.dart';
import '../../sources/source_models.dart';
import '../../sources/source_playback.dart';
import '../../sources/reader_preferences.dart';
import '../../theme/mono_tokens.dart';
import '../../utils/platform_detector.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/app_menu.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import 'source_notes_screen.dart';
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
    WidgetsBinding.instance.a…32170 tokens truncated…diobook,
    PublicationShelf.comics =>
      entry.kind == SourceItemKind.comic || entry.ebooks.any((f) => f.kind == SourceItemKind.comic),
  };
}
