import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../focus/focusable_text_field.dart';
import '../../i18n/strings.g.dart';
import '../../services/settings_service.dart';
import '../../sources/source_controller.dart';
import '../../sources/source_models.dart';
import '../../sources/source_playback.dart';
import '../../sources/source_transport.dart';
import '../../sources/universal_media_input.dart';
import '../../utils/platform_detector.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import 'source_player_screen.dart';
import 'local_media_converter_screen.dart';
import 'capture_share_screen.dart';
import 'source_widgets.dart';
import 'wifi_transfer_screen.dart';

enum _OpenChoice { stream, playlist, files, favorites, disc }

class _StreamFavorite {
  const _StreamFavorite({
    required this.name,
    required this.uri,
    required this.audio,
    required this.allowHttp,
    required this.live,
  });
  final String name;
  final Uri uri;
  final bool audio;
  final bool allowHttp;
  final bool live;

  Map<String, Object> toJson() => {
    'name': name,
    'uri': uri.toString(),
    'audio': audio,
    'allowHttp': allowHttp,
    'live': live,
  };

  static _StreamFavorite? fromJson(Object? value) {
    final row = sourceMap(value);
    final uriText = row['uri'] as String?;
    if (uriText == null) return null;
    try {
      final uri = UniversalMediaAddress.parse(uriText, allowHttp: row['allowHttp'] == true);
      if (!UniversalMediaAddress.canSaveFavorite(uri)) return null;
      final storedName = (row['name'] as String? ?? '').replaceAll(RegExp(r'[\x00-\x1f\x7f]'), '').trim();
      return _StreamFavorite(
        name: storedName.isEmpty
            ? inferredMediaName(uri)
            : storedName.length > 180
            ? storedName.substring(0, 180)
            : storedName,
        uri: uri,
        audio: row['audio'] == true,
        allowHttp: row['allowHttp'] == true,
        live: row['live'] != false,
      );
    } on SourceException {
      return null;
    }
  }
}

class OpenMediaScreen extends StatefulWidget {
  const OpenMediaScreen({super.key, this.initialAddress});

  final String? initialAddress;

  @override
  State<OpenMediaScreen> createState() => _OpenMediaScreenState();
}

class _OpenMediaScreenState extends State<OpenMediaScreen> {
  static const _favoritesKey = 'universal-media-favorites-v1';
  final _url = TextEditingController();
  final _name = TextEditingController();
  _OpenChoice _choice = _OpenChoice.stream;
  bool _audio = false;
  bool _allowHttp = false;
  bool _live = true;
  bool _busy = false;
  Object? _failure;
  bool _favoritesLoading = true;
  int _favoritesLoadSerial = 0;
  SourceController? _sources;
  String? _favoritesProfile;
  int? _favoritesGeneration;
  List<_StreamFavorite> _favorites = const [];

  bool get _mpvProtocolsAvailable {
    if (PlatformDetector.isWebOSBuild() || PlatformDetector.isTizenBuild()) return false;
    if (Platform.isAndroid && SettingsService.instance.read(SettingsService.useExoPlayer)) return false;
    return Platform.isAndroid || Platform.isIOS || Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  }

  bool get _desktopMpvAvailable => PlatformDetector.isDesktopOS() && _mpvProtocolsAvailable;

  @override
  void initState() {
    super.initState();
    _url.text = widget.initialAddress ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _sources = context.read<SourceController>()..addListener(_onSessionChanged);
      unawaited(_loadFavorites());
    });
  }

  @override
  void dispose() {
    _sources?.removeListener(_onSessionChanged);
    _url.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final request = ++_favoritesLoadSerial;
    final sources = _sources ?? context.read<SourceController>();
    try {
      await sources.ready;
      final generation = sources.generation;
      sources.requireSession(generation);
      final profile = sources.profileId;
      if (profile == null) throw const SourceException(SourceFailure.unavailable);
      final value = await sources.repository.preference(profile, _favoritesKey);
      sources.requireSession(generation);
      final rows = sourceList(value['items']).map(_StreamFavorite.fromJson).whereType<_StreamFavorite>().toList();
      if (mounted && request == _favoritesLoadSerial) {
        setState(() {
          _favorites = rows;
          _favoritesProfile = profile;
          _favoritesGeneration = generation;
          _favoritesLoading = false;
        });
      }
    } on Object {
      if (mounted && request == _favoritesLoadSerial) {
        setState(() {
          _failure = const SourceException(SourceFailure.unavailable);
          _favoritesLoading = false;
        });
      }
    }
  }

  void _onSessionChanged() {
    if (!mounted) return;
    final sources = _sources;
    if (sources == null || sources.profileId == _favoritesProfile && sources.generation == _favoritesGeneration) {
      return;
    }
    _favoritesLoadSerial++;
    setState(() {
      _favorites = const [];
      _favoritesProfile = null;
      _favoritesGeneration = null;
      _favoritesLoading = true;
      _failure = null;
    });
    unawaited(_loadFavorites());
  }

  void _requireFavoritesSession() {
    final sources = _sources ?? context.read<SourceController>();
    final profile = _favoritesProfile;
    final generation = _favoritesGeneration;
    if (profile == null || generation == null) throw const SourceException(SourceFailure.unavailable);
    sources.requireSession(generation);
    if (sources.profileId != profile) throw const SourceException(SourceFailure.cancelled);
  }

  Future<void> _saveFavorites(List<_StreamFavorite> favorites) async {
    final sources = _sources ?? context.read<SourceController>();
    final profile = _favoritesProfile;
    final generation = _favoritesGeneration;
    if (profile == null || generation == null) throw const SourceException(SourceFailure.unavailable);
    sources.requireSession(generation);
    if (sources.profileId != profile) throw const SourceException(SourceFailure.cancelled);
    await sources.repository.savePreference(profile, _favoritesKey, {
      'items': favorites.take(100).map((item) => item.toJson()).toList(),
    });
    sources.requireSession(generation);
    if (sources.profileId != profile) throw const SourceException(SourceFailure.cancelled);
    if (mounted) setState(() => _favorites = favorites.take(100).toList(growable: false));
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      await action();
    } on SourceException catch (error) {
      if (mounted) setState(() => _failure = error);
    } on Object {
      if (mounted) setState(() => _failure = const SourceException(SourceFailure.unavailable));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openMediaTools() async {
    final selected = await Navigator.push<Uri>(context, MaterialPageRoute(builder: (_) => const MediaToolsScreen()));
    if (!mounted || selected == null) return;
    setState(() {
      _choice = _OpenChoice.stream;
      _url.text = selected.toString();
      _name.clear();
      _audio = false;
      _live = true;
    });
  }

  Future<void> _openAddress({String? value, String? title, bool? audio, bool? allowHttp, bool? live}) async {
    final useAudio = audio ?? _audio;
    final httpAllowed = allowHttp ?? _allowHttp;
    final uri = UniversalMediaAddress.parse(
      value ?? _url.text,
      allowHttp: httpAllowed,
      allowMpvProtocols: _mpvProtocolsAvailable,
    );
    final name = (title ?? _name.text).trim();
    await _startItems(
      [UniversalMediaItem(title: name.isEmpty ? inferredMediaName(uri) : name, uri: uri)],
      name.isEmpty ? inferredMediaName(uri) : name,
      audio: useAudio,
      live: live ?? _live,
    );
  }

  Future<void> _openStream() => _run(() => _openAddress());

  Future<void> _openDisc(String address, String title, {required bool audio}) => _run(
    () => _startItems(
      [UniversalMediaItem(title: title, uri: Uri.parse(address))],
      title,
      audio: audio,
    ),
  );

  Future<void> _saveCurrentFavorite() async {
    try {
      final uri = UniversalMediaAddress.parse(_url.text, allowHttp: _allowHttp);
      if (!UniversalMediaAddress.canSaveFavorite(uri)) throw const SourceException(SourceFailure.permission);
      final enteredLabel = _name.text.replaceAll(RegExp(r'[\x00-\x1f\x7f]'), '').trim();
      final label = enteredLabel.isEmpty
          ? inferredMediaName(uri)
          : enteredLabel.length > 180
          ? enteredLabel.substring(0, 180)
          : enteredLabel;
      final favorite = _StreamFavorite(name: label, uri: uri, audio: _audio, allowHttp: _allowHttp, live: _live);
      final next = [favorite, ..._favorites.where((item) => item.uri != uri)];
      await _saveFavorites(next);
      if (mounted) showSnackBar(context, t.universalMedia.favoriteSaved);
    } on SourceException catch (error) {
      if (mounted) setState(() => _failure = error);
    } on Object {
      if (mounted) setState(() => _failure = const SourceException(SourceFailure.unavailable));
    }
  }

  Future<void> _removeFavorite(_StreamFavorite favorite) async {
    await _saveFavorites(_favorites.where((item) => item.uri != favorite.uri).toList(growable: false));
  }

  Future<void> _openNetworkPlaylist() async {
    await _run(() async {
      final uri = UniversalMediaAddress.parse(_url.text, allowHttp: _allowHttp);
      if (!const {'http', 'https'}.contains(uri.scheme)) throw const SourceException(SourceFailure.unsupported);
      final transport = SourceTransport(allowHttp: _allowHttp);
      try {
        final content = await transport.text(
          'GET',
          uri,
          redirects: true,
          limit: UniversalMediaPlaylistParser.maxCharacters,
        );
        final playlist = UniversalMediaPlaylistParser.parse(
          content,
          fallbackTitle: _name.text.trim().isEmpty ? inferredMediaName(uri) : _name.text.trim(),
          base: uri,
          allowHttp: _allowHttp,
          allowMpvProtocols: _mpvProtocolsAvailable,
        );
        if (playlist.skipped > 0 && mounted) {
          showSnackBar(context, t.universalMedia.skippedEntries(n: playlist.skipped, count: playlist.skipped));
        }
        await _startItems(playlist.items, playlist.title, audio: _audio, live: playlist.live);
      } finally {
        transport.close();
      }
    });
  }

  Future<List<int>> _readPlaylistFile(PlatformFile file) async {
    if (file.size < 1 || file.size > UniversalMediaPlaylistParser.maxCharacters) {
      throw const SourceException(SourceFailure.invalidData);
    }
    if (file.bytes != null) return file.bytes!;
    if (file.readStream != null) {
      final bytes = <int>[];
      await for (final chunk in file.readStream!) {
        if (bytes.length + chunk.length > UniversalMediaPlaylistParser.maxCharacters) {
          throw const SourceException(SourceFailure.invalidData);
        }
        bytes.addAll(chunk);
      }
      return bytes;
    }
    if (file.path != null) return File(file.path!).readAsBytes();
    throw const SourceException(SourceFailure.unavailable);
  }

  Future<void> _pickPlaylist() async {
    final choice = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['m3u', 'm3u8', 'pls'],
      withData: true,
      withReadStream: true,
    );
    if (choice == null || choice.files.isEmpty || !mounted) return;
    await _run(() async {
      final file = choice.files.first;
      final text = utf8.decode(await _readPlaylistFile(file), allowMalformed: true);
      final isHls = text.split(RegExp(r'\r?\n')).any((line) => line.trimLeft().toUpperCase().startsWith('#EXT-X-'));
      if (isHls) {
        final originalPath = file.path;
        File? temporaryManifest;
        final temporaryFiles = <File>[];
        final name = p.basename(file.name);
        try {
          final Uri uri;
          if (originalPath != null) {
            uri = File(originalPath).uri;
          } else {
            temporaryManifest = await _writeTemporaryManifest(name, text);
            temporaryFiles.add(temporaryManifest);
            uri = temporaryManifest.uri;
          }
          await _startItems(
            [UniversalMediaItem(title: name, uri: uri)],
            name,
            audio: _audio,
            live: UniversalMediaPlaylistParser.isLiveHls(text),
            temporaryMediaFiles: temporaryFiles,
          );
        } finally {
          if (temporaryManifest != null && await temporaryManifest.exists()) await temporaryManifest.delete();
        }
        return;
      }
      final playlist = UniversalMediaPlaylistParser.parse(
        text,
        fallbackTitle: p.basenameWithoutExtension(file.name),
        allowHttp: _allowHttp,
        allowMpvProtocols: _mpvProtocolsAvailable,
      );
      if (playlist.skipped > 0 && mounted) {
        showSnackBar(context, t.universalMedia.skippedEntries(n: playlist.skipped, count: playlist.skipped));
      }
      await _startItems(playlist.items, playlist.title, audio: _audio, live: playlist.live);
    });
  }

  Future<File> _writeTemporaryManifest(String name, String content) async {
    final directory = await getTemporaryDirectory();
    const extension = '.m3u8';
    final file = File(p.join(directory.path, 'plezy-open-${const Uuid().v4()}$extension'));
    await file.writeAsString(content, flush: true);
    return file;
  }

  Future<File> _temporaryCopy(PlatformFile picked) async {
    final stream = picked.readStream;
    if (stream == null) throw const SourceException(SourceFailure.unavailable);
    final directory = await getTemporaryDirectory();
    final extension = p.extension(picked.name).toLowerCase().replaceAll(RegExp(r'[^.a-z0-9]'), '');
    final suffix = const Uuid().v4();
    final file = File(p.join(directory.path, 'plezy-open-$suffix$extension'));
    final output = await file.open(mode: FileMode.write);
    try {
      await for (final chunk in stream) {
        await output.writeFrom(chunk);
      }
      await output.flush();
      return file;
    } catch (_) {
      if (await file.exists()) await file.delete();
      rethrow;
    } finally {
      await output.close();
    }
  }

  Future<void> _pickFiles() async {
    final selection = await FilePicker.pickFiles(allowMultiple: true, withReadStream: true);
    if (selection == null || selection.files.isEmpty || !mounted) return;
    await _run(() async {
      if (selection.files.length > 100) throw const SourceException(SourceFailure.invalidData);
      final opened = <UniversalMediaItem>[];
      final overrides = <String, Uri>{};
      final cleanup = <File>[];
      var audioOnly = true;
      try {
        for (final picked in selection.files) {
          final kind = classifySourceFile(picked.name);
          final isDiscImage = p.extension(picked.name).toLowerCase() == '.iso';
          if (kind == SourceItemKind.unknown && !isDiscImage) continue;
          if (kind != SourceItemKind.music && kind != SourceItemKind.audiobook) audioOnly = false;
          final path = picked.path;
          final localFile = path == null ? await _temporaryCopy(picked) : null;
          if (localFile != null) cleanup.add(localFile);
          final uri = path != null ? File(path).uri : localFile!.uri;
          final id = const Uuid().v4();
          final item = UniversalMediaItem(title: p.basename(picked.name), uri: uri);
          opened.add(item);
          overrides[id] = uri;
          _pendingFileIds[item] = id;
        }
        if (opened.isEmpty) throw const SourceException(SourceFailure.unsupported);
        await _startItems(
          opened,
          opened.length == 1 ? opened.first.title : t.universalMedia.fileQueue(n: opened.length, count: opened.length),
          audio: audioOnly,
          localOverrides: overrides,
          temporaryMediaFiles: cleanup,
        );
        cleanup.clear();
      } finally {
        _pendingFileIds.clear();
        for (final file in cleanup) {
          if (await file.exists()) await file.delete();
        }
      }
    });
  }

  final Map<UniversalMediaItem, String> _pendingFileIds = {};

  Future<void> _startItems(
    List<UniversalMediaItem> items,
    String title, {
    required bool audio,
    bool live = false,
    Map<String, Uri> localOverrides = const {},
    List<File> temporaryMediaFiles = const [],
  }) async {
    if (items.isEmpty) throw const SourceException(SourceFailure.invalidData);
    final sessionId = const Uuid().v4();
    final files = <PublicationFile>[];
    final overrides = <String, Uri>{...localOverrides};
    for (final input in items) {
      final id = _pendingFileIds[input] ?? const Uuid().v4();
      files.add(
        PublicationFile(
          id: id,
          name: input.title,
          mimeType: universalMediaMimeType(input.title),
          durationMs: input.durationSeconds == null || input.durationSeconds! < 0
              ? null
              : input.durationSeconds! * 1000,
          streamOnly: true,
        ),
      );
      overrides[id] = input.uri;
    }
    final entry = SourceEntry(
      sourceId: 'open:$sessionId',
      id: sessionId,
      title: title,
      kind: audio ? SourceItemKind.music : SourceItemKind.video,
      files: files,
    );
    await context.read<SourcePlayback>().start(
      entry,
      files,
      playbackMode: audio ? PublicationMode.listening : PublicationMode.watching,
      localOverrides: overrides,
      persistProgress: false,
      liveInput: live,
      temporaryMediaFiles: temporaryMediaFiles,
    );
    if (!mounted) return;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: 'universal-media-player'),
        builder: (_) => const SourcePlayerScreen(),
      ),
    );
  }

  Widget _modePicker() => SegmentedButton<bool>(
    segments: [
      ButtonSegment(value: false, icon: const AppIcon(Symbols.movie_rounded), label: Text(t.fileSources.video)),
      ButtonSegment(value: true, icon: const AppIcon(Symbols.music_note_rounded), label: Text(t.fileSources.audio)),
    ],
    selected: {_audio},
    onSelectionChanged: _busy ? null : (values) => setState(() => _audio = values.first),
  );

  Widget _streamForm() {
    final typedUri = Uri.tryParse(_url.text.trim());
    final isHttp = typedUri?.scheme.toLowerCase() == 'http';
    final canFavorite =
        typedUri != null &&
        (typedUri.scheme.toLowerCase() != 'http' || _allowHttp) &&
        UniversalMediaAddress.canSaveFavorite(typedUri);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FocusableTextFormField(
          controller: _url,
          keyboardType: TextInputType.url,
          textDirection: TextDirection.ltr,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: t.universalMedia.address,
            hintText: 'https://radio.example/stream',
            helperText: t.universalMedia.addressHelp,
            helperMaxLines: 3,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        FocusableTextFormField(
          controller: _name,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: t.universalMedia.displayName,
            helperText: t.universalMedia.displayNameHelp,
          ),
        ),
        if (isHttp)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(t.universalMedia.allowHttp),
            subtitle: Text(t.universalMedia.allowHttpHelp),
            value: _allowHttp,
            onChanged: _busy ? null : (value) => setState(() => _allowHttp = value),
          ),
        if (_mpvProtocolsAvailable)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(t.universalMedia.advancedProtocols, style: Theme.of(context).textTheme.bodySmall),
          ),
        _modePicker(),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(t.universalMedia.liveStream),
          subtitle: Text(t.universalMedia.liveStreamHelp),
          value: _live,
          onChanged: _busy ? null : (value) => setState(() => _live = value),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(t.universalMedia.privateSession, style: Theme.of(context).textTheme.bodySmall),
        ),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            if (canFavorite)
              OutlinedButton.icon(
                onPressed: _busy || _favoritesLoading ? null : _saveCurrentFavorite,
                icon: const AppIcon(Symbols.bookmark_add_rounded),
                label: Text(t.universalMedia.saveFavorite),
              ),
            FilledButton.icon(
              onPressed: _busy ? null : _openStream,
              icon: const AppIcon(Symbols.play_arrow_rounded, fill: 1),
              label: Text(t.universalMedia.playNow),
            ),
          ],
        ),
      ],
    );
  }

  Widget _playlistForm() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FocusableTextFormField(
        controller: _url,
        keyboardType: TextInputType.url,
        textDirection: TextDirection.ltr,
        autocorrect: false,
        enableSuggestions: false,
        decoration: InputDecoration(
          labelText: t.universalMedia.playlistAddress,
          hintText: 'https://example.org/stations.m3u',
          helperText: t.universalMedia.playlistAddressHelp,
          helperMaxLines: 3,
        ),
      ),
      if (Uri.tryParse(_url.text.trim())?.scheme.toLowerCase() == 'http')
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(t.universalMedia.allowHttp),
          subtitle: Text(t.universalMedia.allowHttpHelp),
          value: _allowHttp,
          onChanged: _busy ? null : (value) => setState(() => _allowHttp = value),
        ),
      _modePicker(),
      const SizedBox(height: 12),
      Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: _busy ? null : _pickPlaylist,
            icon: const AppIcon(Symbols.folder_open_rounded),
            label: Text(t.universalMedia.choosePlaylist),
          ),
          FilledButton.icon(
            onPressed: _busy ? null : _openNetworkPlaylist,
            icon: const AppIcon(Symbols.play_arrow_rounded, fill: 1),
            label: Text(t.universalMedia.openPlaylist),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Text(t.universalMedia.playlistFormatsHelp, style: Theme.of(context).textTheme.bodySmall),
    ],
  );

  Widget _favoriteList() {
    if (_favorites.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(t.universalMedia.noFavorites, textAlign: TextAlign.center),
      );
    }
    return Column(
      children: [
        for (final (index, favorite) in _favorites.indexed)
          SourceTile(
            key: ValueKey(favorite.uri.toString()),
            title: favorite.name,
            subtitle: '${favorite.uri.host} · ${favorite.audio ? t.fileSources.audio : t.fileSources.video}',
            icon: favorite.audio ? Symbols.radio_rounded : Symbols.movie_rounded,
            index: index,
            count: _favorites.length,
            trailing: IconButton(
              tooltip: t.universalMedia.removeFavorite,
              onPressed: _busy ? null : () => _run(() => _removeFavorite(favorite)),
              icon: const AppIcon(Symbols.delete_outline_rounded),
            ),
            onTap: _busy
                ? null
                : () => _run(() {
                    _requireFavoritesSession();
                    return _openAddress(
                      value: favorite.uri.toString(),
                      title: favorite.name,
                      audio: favorite.audio,
                      allowHttp: favorite.allowHttp,
                      live: favorite.live,
                    );
                  }),
          ),
      ],
    );
  }

  Widget _choiceBody() => switch (_choice) {
    _OpenChoice.stream => _streamForm(),
    _OpenChoice.playlist => _playlistForm(),
    _OpenChoice.files => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.universalMedia.filesHelp),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _busy ? null : _pickFiles,
          icon: const AppIcon(Symbols.file_open_rounded),
          label: Text(t.universalMedia.chooseFiles),
        ),
      ],
    ),
    _OpenChoice.favorites => _favoriteList(),
    _OpenChoice.disc => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.universalMedia.discHelp),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _busy ? null : () => _openDisc('dvd://', t.universalMedia.dvd, audio: false),
          icon: const AppIcon(Symbols.album_rounded),
          label: Text(t.universalMedia.dvd),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _busy ? null : () => _openDisc('bd://', t.universalMedia.bluray, audio: false),
          icon: const AppIcon(Symbols.album_rounded),
          label: Text(t.universalMedia.bluray),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _busy ? null : () => _openDisc('cdda://', t.universalMedia.audioCd, audio: true),
          icon: const AppIcon(Symbols.album_rounded),
          label: Text(t.universalMedia.audioCd),
        ),
      ],
    ),
  };

  @override
  Widget build(BuildContext context) => FocusedScrollScaffold(
    title: Text(t.universalMedia.title),
    focusableAppBarActions: true,
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.all(24),
        sliver: SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(t.universalMedia.intro, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<_OpenChoice>(
                    initialValue: _choice,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: t.universalMedia.openWhat),
                    items: [
                      DropdownMenuItem(value: _OpenChoice.stream, child: Text(t.universalMedia.stream)),
                      DropdownMenuItem(value: _OpenChoice.playlist, child: Text(t.universalMedia.playlist)),
                      DropdownMenuItem(value: _OpenChoice.files, child: Text(t.universalMedia.files)),
                      DropdownMenuItem(value: _OpenChoice.favorites, child: Text(t.universalMedia.favorites)),
                      if (_desktopMpvAvailable)
                        DropdownMenuItem(value: _OpenChoice.disc, child: Text(t.universalMedia.discs)),
                    ],
                    onChanged: _busy ? null : (value) => setState(() => _choice = value ?? _choice),
                  ),
                  const SizedBox(height: 20),
                  _choiceBody(),
                  if (_failure != null) ...[
                    const SizedBox(height: 16),
                    SourceErrorMessage(
                      message: sourceFailureText(
                        SourceException(
                          _failure is SourceException
                              ? (_failure as SourceException).reason
                              : SourceFailure.unavailable,
                        ),
                      ),
                    ),
                  ],
                  if (_busy) ...[const SizedBox(height: 12), const LinearProgressIndicator()],
                  const SizedBox(height: 28),
                  if (WifiTransferScreen.isSupported(context))
                    SourceTile(
                      title: t.universalMedia.wifiTransfer,
                      subtitle: t.universalMedia.wifiTransferHelp,
                      icon: Symbols.wifi_tethering_rounded,
                      onTap: _busy
                          ? null
                          : () =>
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const WifiTransferScreen())),
                    ),
                  if (PlatformDetector.isDesktopOS()) ...[
                    SourceTile(
                      title: t.universalMedia.converterTitle,
                      subtitle: t.universalMedia.converterHelp,
                      icon: Symbols.swap_horiz_rounded,
                      onTap: _busy
                          ? null
                          : () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const LocalMediaConverterScreen()),
                            ),
                    ),
                    if (_desktopMpvAvailable)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(t.universalMedia.discAvailability, style: Theme.of(context).textTheme.bodySmall),
                      ),
                  ],
                  if (MediaToolsScreen.isSupported)
                    SourceTile(
                      title: t.universalMedia.mediaToolsTitle,
                      subtitle: t.universalMedia.mediaToolsShortcut,
                      icon: Symbols.tune_rounded,
                      onTap: _busy ? null : _openMediaTools,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
