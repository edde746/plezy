import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../focus/focusable_button.dart';
import '../../focus/focusable_text_field.dart';
import '../../i18n/strings.g.dart';
import '../../i18n/presentation_formats.dart';
import '../../media/media_backend.dart';
import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../models/trakt/trakt_catalog_entry.dart';
import '../../providers/trackers_provider.dart';
import '../../services/playback_context.dart';
import '../../services/trackers/trakt/trakt_constants.dart';
import '../../sources/external_video_progress.dart';
import '../../sources/source_controller.dart';
import '../../sources/source_models.dart';
import '../../sources/source_playback.dart';
import '../../theme/mono_tokens.dart';
import '../../utils/dialogs.dart';
import '../../utils/formatters.dart';
import '../../utils/platform_detector.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/app_menu.dart';
import '../../widgets/dialog_action_button.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../settings/services_settings_screen.dart';
import '../video_player_screen.dart';
import 'publication_reader_screen.dart';
import 'source_notes_screen.dart';
import 'source_player_screen.dart';
import 'source_sync_screen.dart';
import 'source_widgets.dart';

class SourceDetailScreen extends StatefulWidget {
  const SourceDetailScreen({super.key, required this.entry});
  final SourceEntry entry;
  @override
  State<SourceDetailScreen> createState() => _SourceDetailScreenState();
}

class _SourceDetailScreenState extends State<SourceDetailScreen> {
  late SourceEntry _entry = widget.entry;
  bool _busy = false;
  bool _metadataLookupPending = false;
  bool _metadataLookupFailed = false;
  bool _metadataNoMatch = false;
  Object? _error;
  List<PublicationProgress> _progress = [];
  final Map<String, PublicationProgress> _conflicts = {};
  final Set<String> _offline = {};
  final Map<String, double?> _transfers = {};
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final sources = context.read<SourceController>();
    setState(() => _busy = true);
    try {
      await sources.ready;
      sources.requireSession();
      final epoch = sources.generation, profile = sources.profileId!;
      if (!_entry.id.startsWith('group:') && sources.sources.any((s) => s.id == _entry.sourceId)) {
        try {
          _entry = await sources.hydrate(_entry);
        } catch (_) {
          /* Cached details are usable offline. */
        }
      }
      final seeds = [
        for (final f in _entry.ebooks)
          PublicationProgress(
            entryKey: _entry.key,
            edition: f.fingerprint,
            mode: PublicationMode.reading,
            session: const Uuid().v4(),
          ),
        if (_entry.audio.isNotEmpty)
          PublicationProgress(
            entryKey: _entry.key,
            edition: sourceDigest(jsonEncode(_entry.audio.map((f) => f.fingerprint).toList())),
            mode: PublicationMode.listening,
            session: const Uuid().v4(),
          ),
        if (_entry.kind == SourceItemKind.video && _entry.files.isNotEmpty)
          PublicationProgress(
            entryKey: _entry.key,
            edition: sourceDigest(jsonEncode(_entry.files.map((f) => f.fingerprint).toList())),
            mode: PublicationMode.watching,
            session: const Uuid().v4(),
          ),
      ];
      for (final seed in seeds) {
        await sources.openProgress(_entry, seed);
      }
      final progresses = (await sources.repository.allProgress(
        profile,
      )).where((p) => p.entryKey == _entry.key).toList();
      _conflicts.clear();
      for (final progress in progresses) {
        final conflict = await sources.repository.remoteConflict(profile, progress.key);
        if (conflict != null) _conflicts[progress.key] = conflict;
      }
      _offline.clear();
      for (final file in _entry.files) {
        if (await sources.downloads.local(profile, _entry.sourceId, file) != null) _offline.add(file.id);
      }
      sources.requireSession(epoch);
      if (mounted) setState(() => _progress = progresses);
      if (mounted && _entry.kind == SourceItemKind.video) {
        unawaited(_identifyStandaloneMetadata(sources, epoch));
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _identifyStandaloneMetadata(SourceController sources, int epoch) async {
    if (_entry.kind != SourceItemKind.video) return;
    final source = sources.sources.where((item) => item.id == _entry.sourceId).firstOrNull;
    if (source == null || source.options['onlineMetadata'] != 'true') return;
    final entryKey = _entry.key;
    setState(() {
      _metadataLookupPending = true;
      _metadataLookupFailed = false;
      _metadataNoMatch = false;
    });
    try {
      final matched = await sources.identifyOnlineMetadata(_entry);
      if (!mounted || sources.generation != epoch || _entry.key != entryKey) return;
      setState(() {
        _entry = matched;
        _metadataLookupPending = false;
        _metadataNoMatch = matched.onlineMetadataProvider == null && matched.onlineMetadataCheckedAt != null;
        _metadataLookupFailed = matched.onlineMetadataProvider == null && matched.onlineMetadataCheckedAt == null;
      });
    } on Object {
      // Online metadata is an enhancement; offline details stay usable.
      if (mounted && sources.generation == epoch && _entry.key == entryKey) {
        setState(() {
          _metadataLookupPending = false;
          _metadataLookupFailed = true;
        });
      }
    }
  }

  Future<void> _qualifyNfsRead() async {
    final controller = context.read<SourceController>();
    if (_entry.files.isEmpty) return;
    final file = _entry.files.reduce((a, b) => (a.size ?? 0) >= (b.size ?? 0) ? a : b);
    setState(() => _busy = true);
    try {
      final result = await controller.qualifyNfsRead(_entry.sourceId, file);
      if (!mounted) return;
      await showScopedDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(t.sourceSetup.nfsQualificationResult),
          scrollable: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.sourceSetup.nfsReadTestHelp),
              const SizedBox(height: 12),
              Text(
                '${t.sourceSetup.nfsReadBytes}: '
                '${formatDecimal(result.bytes / (1024 * 1024), minimumDecimals: 1, maximumDecimals: 1)} MiB',
              ),
              Text(
                '${t.sourceSetup.nfsReadSpeed}: '
                '${formatDecimal(result.mebibytesPerSecond, minimumDecimals: 2, maximumDecimals: 2)} MiB/s',
              ),
              Text(
                '${t.sourceSetup.nfsReadRequests}: ${formatCount(result.requests)} · '
                '${t.sourceSetup.nfsReadAhead}: ${formatCount(result.readAhead)}',
              ),
            ],
          ),
          actions: [
            DialogActionButton(autofocus: true, onPressed: () => Navigator.pop(dialogContext), label: t.common.close),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editSharedEntryMapping() async {
    final controller = context.read<SourceController>();
    final current = await controller.sharedEntryMapping(_entry);
    if (!mounted) return;
    final sharedId = TextEditingController(text: current ?? '');
    final formKey = GlobalKey<FormState>();
    final save = await showScopedDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: Text(t.sourceSetup.sharedEntryPair),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.sourceSetup.sharedEntryPairHelp),
              const SizedBox(height: 12),
              FocusableTextFormField(
                controller: sharedId,
                autofocus: true,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.none,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(labelText: t.sourceSetup.sharedEntryId),
                validator: (value) {
                  final id = value?.trim() ?? '';
                  if (id.isEmpty || RegExp(r'^[a-zA-Z0-9._-]{8,100}$').hasMatch(id)) return null;
                  return t.sourceSetup.sharedLibraryInvalid;
                },
                onFieldSubmitted: (_) {
                  if (formKey.currentState?.validate() == true) {
                    Navigator.pop(dialogContext, true);
                  }
                },
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FocusableButton(
                  onPressed: () => sharedId.text = const Uuid().v4(),
                  child: TextButton(
                    onPressed: () => sharedId.text = const Uuid().v4(),
                    child: Text(t.sourceSetup.generateSharedEntryId),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          DialogActionButton(onPressed: () => Navigator.pop(dialogContext), label: t.common.cancel),
          DialogActionButton(
            isPrimary: true,
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.pop(dialogContext, true);
              }
            },
            label: t.common.save,
          ),
        ],
      ),
    );
    final value = sharedId.text.trim();
    sharedId.dispose();
    if (save != true || !mounted) return;
    try {
      await controller.setSharedEntryMapping(_entry, value.isEmpty ? null : value);
    } on Object catch (error) {
      if (!mounted) return;
      final message = error is SourceException && error.reason == SourceFailure.conflict
          ? t.sourceSetup.sharedEntryConflict
          : sourceFailureText(error);
      showErrorSnackBar(context, message);
    }
  }

  Future<String?> _metadataSearchQuery() async {
    final controller = TextEditingController(text: _entry.displayTitle);
    final query = await showScopedDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: Text(t.common.search),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.sourceSetup.metadataSearchPrivacy),
            const SizedBox(height: 12),
            FocusableTextField(
              controller: controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(labelText: t.metadataEdit.title, hintText: t.search.hint),
              onSubmitted: (_) => Navigator.pop(dialogContext, controller.text.trim()),
            ),
          ],
        ),
        actions: [
          DialogActionButton(onPressed: () => Navigator.pop(dialogContext), label: t.common.cancel),
          DialogActionButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            label: t.common.search,
            isPrimary: true,
          ),
        ],
      ),
    );
    controller.dispose();
    return query;
  }

  Future<TraktCatalogEntry?> _chooseMetadataMatch(List<TraktCatalogEntry> candidates) =>
      showModalBottomSheet<TraktCatalogEntry>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(sheetContext).height * .72,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(t.sourceSetup.chooseMatch, style: Theme.of(sheetContext).textTheme.titleLarge),
                      ),
                      const SizedBox(height: 4),
                      Text(t.sourceSetup.metadataMatchHelp),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: candidates.length,
                    itemBuilder: (context, index) {
                      final candidate = candidates[index];
                      final media = candidate.media!;
                      final title = media.title?.trim() ?? '';
                      return FocusableListTile(
                        title: Text(
                          media.year == null
                              ? isolateDisplayText(title)
                              : '${isolateDisplayText(title)} (${formatDecimal(media.year!, maximumDecimals: 0)})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: media.overview?.trim().isNotEmpty == true
                            ? Text(isolateDisplayText(media.overview!), maxLines: 2, overflow: TextOverflow.ellipsis)
                            : null,
                        trailing: media.rating == null
                            ? null
                            : Semantics(
                                label: t.sourceSetup.subtitleRating(
                                  rating: isolateDisplayText(
                                    '${formatRating(media.rating!)}/${formatDecimal(10, maximumDecimals: 0)}',
                                  ),
                                ),
                                child: ExcludeSemantics(child: Text('★ ${formatRating(media.rating!)}')),
                              ),
                        onTap: () => Navigator.pop(sheetContext, candidate),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Future<void> _searchOnlineMetadata() async {
    final client = context.read<TrackersProvider>().traktCatalogClient;
    if (client == null) return;
    final query = await _metadataSearchQuery();
    if (query == null || query.trim().isEmpty || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final page = await client.searchCatalog(query.trim(), limit: 25);
      if (!mounted) return;
      final candidates = page.items
          .where((entry) => entry.media?.title?.trim().isNotEmpty == true)
          .take(25)
          .toList(growable: false);
      if (candidates.isEmpty) {
        showAppSnackBar(context, t.sourceSetup.metadataNoMatches);
        return;
      }
      final selected = await _chooseMetadataMatch(candidates);
      if (selected == null || !mounted) return;
      final media = selected.media;
      final traktId = media?.ids.trakt;
      if (media == null || traktId == null) return;
      final type = selected.show != null ? TraktCatalogType.shows : TraktCatalogType.movies;
      var cast = <String>[];
      try {
        final people = await client.getPeople(type, traktId.toString());
        cast = people.cast
            .map((credit) {
              final name = credit.person?.name?.trim();
              if (name == null || name.isEmpty) return null;
              final character = credit.characters?.isNotEmpty == true ? credit.characters!.first.trim() : '';
              return character.isEmpty ? name : '$name — $character';
            })
            .whereType<String>()
            .take(12)
            .toList(growable: false);
      } catch (_) {
        /* Catalog metadata remains useful when Trakt has no people credits. */
      }
      final identifiers = <String, String>{
        'trakt': traktId.toString(),
        if (media.ids.tmdb != null) 'tmdb': media.ids.tmdb.toString(),
        if (media.ids.imdb != null) 'imdb': media.ids.imdb!,
        if (media.ids.tvdb != null) 'tvdb': media.ids.tvdb.toString(),
      };
      if (!mounted) return;
      await context.read<SourceController>().saveOnlineMetadata(
        _entry,
        title: media.title ?? _entry.displayTitle,
        overview: media.overview,
        releaseYear: media.year,
        rating: media.rating,
        genres: media.genres ?? const [],
        identifiers: identifiers,
        posterUrl: media.images?.primaryPoster,
        trailerUrl: media.trailer,
        cast: cast,
        provider: 'trakt',
      );
      if (mounted) await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Uri? get _trailerUri {
    final uri = Uri.tryParse(_entry.trailerUrl ?? '');
    final host = uri?.host.toLowerCase();
    if (uri == null || uri.scheme != 'https' || host == null || uri.userInfo.isNotEmpty) return null;
    if (host == 'youtu.be' ||
        host == 'youtube.com' ||
        host.endsWith('.youtube.com') ||
        host == 'vimeo.com' ||
        host.endsWith('.vimeo.com')) {
      return uri;
    }
    return null;
  }

  Future<void> _openTrailer() async {
    final uri = _trailerUri;
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _play(List<PublicationFile> files) async {
    if (_entry.kind == SourceItemKind.video && files.length == 1 && files.single.kind == SourceItemKind.video) {
      final usedSharedPlayer = await _playRemoteCloudVideo(files.single);
      if (usedSharedPlayer) return;
    }
    final playback = context.read<SourcePlayback>();
    await playback.start(
      _entry,
      files,
      playbackMode: files.first.kind == SourceItemKind.video ? PublicationMode.watching : PublicationMode.listening,
    );
    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: 'source-player'),
          builder: (_) => const SourcePlayerScreen(),
        ),
      );
    }
    if (mounted) await _load();
  }

  /// A single cloud video uses the same video player surface as server
  /// playback. The signed lease stays in memory behind its loopback gateway;
  /// source progress is written to the existing profile-scoped publication
  /// journal rather than pretending the item belongs to a server.
  Future<bool> _playRemoteCloudVideo(PublicationFile selectedFile) async {
    final sources = context.read<SourceController>();
    await sources.ready;
    sources.requireSession();
    final owner = sources.sources.where((source) => source.id == _entry.sourceId).firstOrNull;
    if (owner?.kind != FileSourceKind.remoteCloud) return false;

    final epoch = sources.generation;
    final profile = sources.profileId!;
    final entry = await sources.hydrate(_entry);
    sources.requireSession(epoch);
    final file = entry.files.where((candidate) => candidate.id == selectedFile.id).firstOrNull;
    if (file == null || file.fingerprint != selectedFile.fingerprint) {
      throw const SourceException(SourceFailure.conflict);
    }
    final lease = await sources.resolveRemoteCloudFile(entry, file);
    sources.requireSession(epoch);
    await context.read<SourcePlayback>().stop();
    sources.requireSession(epoch);

    final progress = await ExternalVideoProgressSession.open(sources, entry, file);
    if (!sources.current(epoch) || sources.profileId != profile) {
      await progress.close();
      throw const SourceException(SourceFailure.cancelled);
    }

    final media = MediaItem(
      id: 'remote-source:${sourceDigest(jsonEncode([profile, entry.key, file.fingerprint]))}',
      backend: MediaBackend.plex,
      kind: MediaKind.movie,
      title: entry.onlineTitle ?? entry.displayTitle,
      summary: entry.description,
      year: entry.releaseYear,
      durationMs: file.durationMs,
      thumbPath: entry.onlinePosterUrl,
    );
    Future<({Uri uri, Map<String, String> headers})> renew() async {
      if (sources.blocked || sources.profileId != profile || !sources.current(epoch)) {
        throw const SourceException(SourceFailure.cancelled);
      }
      final renewed = await sources.resolveRemoteCloudFile(entry, file);
      sources.requireSession(epoch);
      return (uri: renewed.uri, headers: renewed.headers);
    }

    final descriptor = ExternalPlaybackSource(
      mediaGlobalKey: media.globalKey,
      profileId: profile,
      uri: lease.uri,
      headers: lease.headers,
      renew: renew,
      onProgress: progress.record,
    );
    try {
      if (!mounted || sources.blocked || sources.profileId != profile || !sources.current(epoch)) {
        throw const SourceException(SourceFailure.cancelled);
      }
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: 'remote-cloud-video-player'),
          builder: (_) => VideoPlayerScreen(
            metadata: media,
            externalPlaybackSource: descriptor,
            initialPosition: Duration(milliseconds: progress.resumePositionMs),
          ),
        ),
      );
    } finally {
      await progress.close();
    }
    if (mounted) await _load();
    return true;
  }

  Future<void> _read(PublicationFile file) async {
    if (PlatformDetector.isTV()) throw const SourceException(SourceFailure.unsupported);
    await Navigator.push(
      context,
      PageRouteBuilder<void>(
        settings: const RouteSettings(name: 'publication-reader'),
        opaque: false,
        pageBuilder: (_, _, _) => PublicationReaderScreen(entry: _entry, file: file),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _download(PublicationFile file) async {
    if (_transfers.containsKey(file.id)) return;
    setState(() => _transfers[file.id] = null);
    try {
      await context.read<SourceController>().content(
        _entry,
        file,
        onProgress: (done, total) {
          if (mounted) setState(() => _transfers[file.id] = total == null ? null : done / total);
        },
      );
    } finally {
      if (mounted) {
        setState(() => _transfers.remove(file.id));
        await _load();
      }
    }
  }

  Future<void> _removeDownload(PublicationFile file) async {
    final sources = context.read<SourceController>(), profile = sourcesProfile(context);
    if (!await showConfirmDialog(
      context,
      title: t.fileSources.removeDownload,
      message: t.fileSources.confirmDelete,
      confirmText: t.fileSources.removeDownload,
      isDestructive: true,
    )) {
      return;
    }
    if (!mounted || sources.profileId != profile) return;
    await sources.downloads.remove(profile, _entry.sourceId, file);
    await _load();
  }

  Future<void> _changeProgress(PublicationProgress progress, String action) async {
    final sources = context.read<SourceController>(), profile = sourcesProfile(context);
    await context.read<SourcePlayback>().stop();
    final current = await sources.repository.progress(profile, progress.key);
    if (current == null) return;
    final value = action == 'reset'
        ? PublicationProgress(
            entryKey: current.entryKey,
            edition: current.edition,
            mode: current.mode,
            session: const Uuid().v4(),
            revision: current.revision,
          )
        : current.copyWith(finished: !current.finished);
    await sources.repository.saveProgress(profile, value, kind: action);
    await _load();
  }

  Future<void> _history(PublicationProgress progress) async {
    final sources = context.read<SourceController>(), profile = sourcesProfile(context);
    final history = await sources.repository.history(profile, progress.key);
    if (!mounted) return;
    final restore = await Navigator.push<PublicationProgress>(
      context,
      MaterialPageRoute(
        builder: (context) => FocusedScrollScaffold(
          title: Text(t.fileSources.history),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList.builder(
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final row = history[index],
                      p = PublicationProgress.fromJson(sourceMap(jsonDecode(history[index]['payload'] as String)));
                  return SourceTile(
                    title: p.mode == PublicationMode.reading
                        ? '${(p.fraction * 100).round()}%'
                        : sourceTime(p.positionMs),
                    subtitle: formatDateTime(DateTime.fromMillisecondsSinceEpoch(row['created'] as int)),
                    icon: Symbols.history_rounded,
                    index: index,
                    count: history.length,
                    onTap: () => Navigator.pop(context, p),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (restore == null || !mounted || sources.profileId != profile) return;
    await context.read<SourcePlayback>().stop();
    final latest = await sources.repository.progress(profile, progress.key);
    await sources.repository.saveProgress(
      profile,
      restore.copyWith(revision: latest!.revision, session: const Uuid().v4()),
      kind: 'restore',
    );
    await _load();
  }

  Future<void> _reorder() async {
    final ordered = await Navigator.push<List<PublicationFile>>(
      context,
      MaterialPageRoute(builder: (_) => _AudioOrder(files: _entry.audio)),
    );
    if (ordered == null || !mounted) return;
    final sources = context.read<SourceController>();
    sources.requireSession();
    _entry = SourceEntry.fromJson({
      ..._entry.toJson(),
      'files': [...ordered, ..._entry.ebooks].map((f) => f.toJson()).toList(),
    });
    await sources.repository.cacheEntries(sources.profileId!, [_entry]);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), tk = tokens(context), audio = _entry.audio;
    final hasTrakt = context.watch<TrackersProvider>().traktCatalogClient != null;
    final source = context.watch<SourceController>().sources.where((item) => item.id == _entry.sourceId).firstOrNull;
    final automaticMetadataEnabled = source?.options['onlineMetadata'] == 'true';
    return FocusedScrollScaffold(
      title: Text(_entry.displayTitle),
      focusableAppBarActions: true,
      actions: [
        if (source?.kind == FileSourceKind.nfs && _entry.files.isNotEmpty)
          IconButton(
            tooltip: t.sourceSetup.nfsReadTest,
            onPressed: _busy ? null : () => sourceAction(context, _qualifyNfsRead),
            icon: const AppIcon(Symbols.speed_rounded),
          ),
        if (_entry.kind == SourceItemKind.video && hasTrakt)
          IconButton(
            tooltip: t.sourceSetup.metadataSearch,
            onPressed: _busy ? null : () => sourceAction(context, _searchOnlineMetadata),
            icon: const AppIcon(Symbols.search_rounded),
          ),
        if (source?.options['syncLibrary']?.trim().isNotEmpty == true &&
            !_entry.isFolder &&
            !_entry.id.startsWith('group:'))
          FocusableButton(
            autoScroll: false,
            onPressed: _busy ? null : () => sourceAction(context, _editSharedEntryMapping),
            child: IconButton(
              tooltip: t.sourceSetup.sharedEntryPair,
              onPressed: _busy ? null : () => sourceAction(context, _editSharedEntryMapping),
              icon: const AppIcon(Symbols.link_rounded),
            ),
          ),
        IconButton(
          tooltip: t.audiobook.syncTitle,
          icon: const AppIcon(Symbols.cloud_sync_rounded),
          onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const SourceSyncScreen()));
            if (mounted) await _load();
          },
        ),
        IconButton(
          tooltip: t.fileSources.bookmarks,
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SourceNotesScreen(entry: _entry))),
          icon: const AppIcon(Symbols.bookmarks_rounded),
        ),
        if (_entry.id.startsWith('group:'))
          IconButton(
            tooltip: t.fileSources.order,
            onPressed: () => sourceAction(context, _reorder),
            icon: const AppIcon(Symbols.reorder_rounded),
          ),
      ],
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, size) {
                        final cover = SizedBox(width: 180, height: 270, child: SourceCover(entry: _entry));
                        final details = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(isolateDisplayText(_entry.displayTitle), style: theme.textTheme.headlineMedium),
                            if (_entry.author.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(isolateDisplayText(_entry.author), style: theme.textTheme.titleLarge),
                              ),
                            if (_entry.narrator.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  '${t.fileSources.narrator} · ${isolateDisplayText(_entry.narrator)}',
                                  style: theme.textTheme.bodyMedium?.copyWith(color: tk.textMuted),
                                ),
                              ),
                            if (_entry.series.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(isolateDisplayText(_entry.series), style: theme.textTheme.bodyMedium),
                              ),
                            if (_entry.releaseYear != null || _entry.rating != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(
                                  [
                                    if (_entry.releaseYear != null)
                                      formatDecimal(_entry.releaseYear!, maximumDecimals: 0),
                                    if (_entry.rating != null)
                                      t.sourceSetup.subtitleRating(
                                        rating: isolateDisplayText(
                                          '${formatRating(_entry.rating!)}/${formatDecimal(10, maximumDecimals: 0)}',
                                        ),
                                      ),
                                  ].join(' · '),
                                  style: theme.textTheme.bodyMedium?.copyWith(color: tk.textMuted),
                                ),
                              ),
                            if (_entry.genres.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _entry.genres.join(' · '),
                                  style: theme.textTheme.bodyMedium?.copyWith(color: tk.textMuted),
                                ),
                              ),
                            const SizedBox(height: 24),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                if (_entry.ebooks.isNotEmpty)
                                  FilledButton.icon(
                                    onPressed: PlatformDetector.isTV()
                                        ? null
                                        : () => sourceAction(context, () => _read(_entry.ebooks.first)),
                                    icon: const AppIcon(Symbols.menu_book_rounded),
                                    label: Text(t.fileSources.read),
                                  ),
                                if (audio.isNotEmpty)
                                  FilledButton.icon(
                                    onPressed: () => sourceAction(context, () => _play(audio)),
                                    icon: const AppIcon(Symbols.headphones_rounded),
                                    label: Text(t.fileSources.listen),
                                  ),
                                if (_entry.kind == SourceItemKind.video)
                                  FilledButton.icon(
                                    onPressed: () => sourceAction(context, () => _play(_entry.files)),
                                    icon: const AppIcon(Symbols.play_arrow_rounded, fill: 1),
                                    label: Text(t.fileSources.play),
                                  ),
                                if (_trailerUri != null)
                                  OutlinedButton.icon(
                                    onPressed: () => sourceAction(context, _openTrailer),
                                    icon: const AppIcon(Symbols.movie_rounded),
                                    label: Text(t.tooltips.playTrailer),
                                  ),
                                if (source?.options['syncLibrary']?.trim().isNotEmpty == true)
                                  FocusableButton(
                                    onPressed: _busy ? null : () => sourceAction(context, _editSharedEntryMapping),
                                    child: TextButton.icon(
                                      onPressed: _busy ? null : () => sourceAction(context, _editSharedEntryMapping),
                                      icon: const AppIcon(Symbols.link_rounded),
                                      label: Text(t.sourceSetup.sharedEntryPair),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        );
                        return size.maxWidth > 620
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  cover,
                                  const SizedBox(width: 32),
                                  Expanded(child: details),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(child: cover),
                                  const SizedBox(height: 24),
                                  details,
                                ],
                              );
                      },
                    ),
                    if (_busy)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Semantics(
                          label: t.sourceSetup.videoDetailsLoading,
                          liveRegion: true,
                          child: LinearProgressIndicator(),
                        ),
                      ),
                    if (_metadataLookupPending)
                      Padding(
                        padding: EdgeInsets.only(top: 4, bottom: 12),
                        child: Semantics(
                          label: t.sourceSetup.metadataLoading,
                          liveRegion: true,
                          child: Row(
                            children: [
                              SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                              SizedBox(width: 12),
                              Expanded(child: Text(t.sourceSetup.metadataLoading)),
                            ],
                          ),
                        ),
                      ),
                    if (_entry.onlineMetadataProvider == 'trakt')
                      Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Semantics(
                          label: t.sourceSetup.metadataFromTrakt,
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Chip(
                              avatar: const AppIcon(Symbols.public_rounded, size: 18),
                              label: Text(t.sourceSetup.metadataFromTrakt),
                            ),
                          ),
                        ),
                      ),
                    if (_metadataNoMatch && hasTrakt)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(liveRegion: true, child: Text(t.sourceSetup.metadataNoAutomaticMatch)),
                            TextButton.icon(
                              onPressed: _busy ? null : () => sourceAction(context, _searchOnlineMetadata),
                              icon: const AppIcon(Symbols.search_rounded),
                              label: Text(t.sourceSetup.metadataSearch),
                            ),
                          ],
                        ),
                      ),
                    if (_metadataLookupFailed && hasTrakt)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(liveRegion: true, child: Text(t.sourceSetup.metadataFailed)),
                            TextButton.icon(
                              onPressed: _busy ? null : () => sourceAction(context, _searchOnlineMetadata),
                              icon: const AppIcon(Symbols.search_rounded),
                              label: Text(t.sourceSetup.metadataSearch),
                            ),
                          ],
                        ),
                      ),
                    if (_entry.kind == SourceItemKind.video && hasTrakt && !automaticMetadataEnabled)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${t.sourceSetup.automaticMetadata} · ${t.common.off}',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                            TextButton.icon(
                              onPressed: _busy ? null : () => sourceAction(context, _searchOnlineMetadata),
                              icon: const AppIcon(Symbols.search_rounded),
                              label: Text(t.sourceSetup.metadataSearch),
                            ),
                          ],
                        ),
                      ),
                    if (_entry.kind == SourceItemKind.video && !hasTrakt)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.sourceSetup.metadataSearchPrivacy,
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                            TextButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ServicesSettingsScreen()),
                              ),
                              icon: const AppIcon(Symbols.link_rounded),
                              label: Text('${t.common.connect} ${t.trakt.title}'),
                            ),
                          ],
                        ),
                      ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: SourceErrorMessage(message: sourceFailureText(_error!)),
                      ),
                    if (_entry.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(_entry.description, style: theme.textTheme.bodyLarge),
                      ),
                    if (_entry.cast.isNotEmpty) ...[
                      Semantics(header: true, child: Text(t.discover.cast, style: theme.textTheme.titleMedium)),
                      const SizedBox(height: 8),
                      Text(_entry.cast.join(', '), style: theme.textTheme.bodyMedium),
                    ],
                    for (final progress in _progress) ...[
                      if (_conflicts.containsKey(progress.key))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.fileSources.conflict),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 12,
                                children: [
                                  for (final remote in [false, true])
                                    OutlinedButton(
                                      onPressed: () => sourceAction(context, () async {
                                        await context.read<SourceController>().resolveConflict(
                                          _entry,
                                          progress,
                                          useRemote: remote,
                                        );
                                        await _load();
                                      }),
                                      child: Text(
                                        '${remote ? t.fileSources.useRemote : t.fileSources.useLocal} · ${progress.mode == PublicationMode.reading ? '${(((remote ? _conflicts[progress.key]! : progress).fraction) * 100).round()}%' : sourceTime((remote ? _conflicts[progress.key]! : progress).positionMs)}',
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      SourceTile(
                        title: progress.mode == PublicationMode.reading
                            ? t.fileSources.read
                            : progress.mode == PublicationMode.listening
                            ? t.fileSources.listen
                            : t.fileSources.continueWatching,
                        subtitle: progress.finished
                            ? t.fileSources.finished
                            : progress.mode == PublicationMode.reading
                            ? '${(progress.fraction * 100).round()}%'
                            : sourceTime(progress.positionMs),
                        progress: progress.fraction,
                        icon: progress.mode == PublicationMode.reading
                            ? Symbols.menu_book_rounded
                            : progress.mode == PublicationMode.listening
                            ? Symbols.headphones_rounded
                            : Symbols.movie_rounded,
                        onTap: progress.mode == PublicationMode.watching
                            ? () => sourceAction(context, () => _play(_entry.files))
                            : null,
                        trailing: AppMenuButton<String>(
                          icon: const AppIcon(Symbols.more_vert_rounded),
                          tooltip: t.fileSources.timePosition,
                          adaptiveSheet: true,
                          entriesBuilder: (_) => [
                            AppMenuItem(
                              value: 'finished',
                              label: progress.finished ? t.fileSources.markUnfinished : t.fileSources.markFinished,
                            ),
                            AppMenuItem(value: 'reset', label: t.fileSources.startOver),
                            AppMenuItem(value: 'history', label: t.fileSources.history),
                          ],
                          onSelected: (action) => sourceAction(
                            context,
                            () => action == 'history' ? _history(progress) : _changeProgress(progress, action),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(t.fileSources.editions, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 16),
                    for (var i = 0; i < _entry.files.length; i++)
                      Builder(
                        builder: (context) {
                          final f = _entry.files[i];
                          return SourceTile(
                            title: f.name,
                            subtitle: _offline.contains(f.id) ? t.fileSources.offline : f.mimeType,
                            icon: sourceItemIcon(f.kind),
                            index: i,
                            count: _entry.files.length,
                            progress: _transfers.containsKey(f.id) ? _transfers[f.id] ?? 0 : null,
                            onTap: (f.kind == SourceItemKind.ebook || f.kind == SourceItemKind.comic)
                                ? () => sourceAction(context, () => _read(f))
                                : () => sourceAction(context, () => _play([f])),
                            trailing: f.streamOnly
                                ? null
                                : _transfers.containsKey(f.id)
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : IconButton(
                                    tooltip: _offline.contains(f.id)
                                        ? t.fileSources.removeDownload
                                        : t.fileSources.download,
                                    onPressed: () => sourceAction(
                                      context,
                                      () => _offline.contains(f.id) ? _removeDownload(f) : _download(f),
                                    ),
                                    icon: AppIcon(
                                      _offline.contains(f.id)
                                          ? Symbols.download_done_rounded
                                          : Symbols.download_rounded,
                                    ),
                                  ),
                          );
                        },
                      ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AudioOrder extends StatefulWidget {
  const _AudioOrder({required this.files});
  final List<PublicationFile> files;
  @override
  State<_AudioOrder> createState() => _AudioOrderState();
}

class _AudioOrderState extends State<_AudioOrder> {
  late final List<PublicationFile> _files = [...widget.files];
  void move(int i, int direction) {
    final next = i + direction;
    if (next < 0 || next >= _files.length) return;
    setState(() {
      final f = _files.removeAt(i);
      _files.insert(next, f);
    });
  }

  @override
  Widget build(BuildContext context) => FocusedScrollScaffold(
    title: Text(t.fileSources.order),
    focusableAppBarActions: true,
    actions: [TextButton(onPressed: () => Navigator.pop(context, _files), child: Text(t.fileSources.save))],
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.all(24),
        sliver: SliverList.builder(
          itemCount: _files.length,
          itemBuilder: (context, i) => SourceTile(
            title: _files[i].name,
            index: i,
            count: _files.length,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: t.fileSources.moveUp,
                  onPressed: i > 0 ? () => move(i, -1) : null,
                  icon: const AppIcon(Symbols.arrow_upward_rounded),
                ),
                IconButton(
                  tooltip: t.fileSources.moveDown,
                  onPressed: i + 1 < _files.length ? () => move(i, 1) : null,
                  icon: const AppIcon(Symbols.arrow_downward_rounded),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
