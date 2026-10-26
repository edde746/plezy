import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../discovery/discovery_choice.dart';
import '../../focus/focusable_button.dart';
import '../../discovery/discovery_store.dart';
import '../../i18n/strings.g.dart';
import '../../i18n/presentation_formats.dart';
import '../../media/ids.dart';
import '../../media/library_query.dart';
import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../media/media_library.dart';
import '../../media/catalog_item_ref.dart';
import '../../models/catalog/catalog_item.dart';
import '../../profiles/active_profile_provider.dart';
import '../../providers/hidden_libraries_provider.dart';
import '../../providers/libraries_provider.dart';
import '../../providers/multi_server_provider.dart';
import '../../providers/download_provider.dart';
import '../../providers/catalog_sources_provider.dart';
import '../../providers/explore_provider.dart';
import '../../providers/offline_mode_provider.dart';
import '../../screens/livetv/program_details_sheet.dart';
import '../../screens/sources/source_detail_screen.dart';
import '../../sources/source_controller.dart';
import '../../sources/source_models.dart';
import '../../services/settings_service.dart';
import '../../utils/formatters.dart';
import '../../utils/catalog_navigation_helper.dart';
import '../../utils/global_key_utils.dart';
import '../../utils/layout_constants.dart';
import '../../utils/live_tv_matching.dart';
import '../../utils/live_tv_player_navigation.dart';
import '../../utils/media_image_helper.dart';
import '../../utils/media_navigation_helper.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/overlay_sheet.dart';
import 'discovery_artwork.dart';
import 'discovery_controls.dart';
import 'discovery_deck_view.dart';

enum _DiscoveryFamily { anything, watch, listen, read }

String _safeLiveReference(String value) => 'sha256:${sourceDigest(value)}';

String _localizedChoiceType(DiscoveryChoice choice) {
  if (choice.mediaKind != null) return choice.mediaKind!.label;
  return switch (choice.type) {
    DiscoveryChoiceType.ebook => t.fileSources.ebooks,
    DiscoveryChoiceType.audiobook => t.fileSources.audiobooks,
    DiscoveryChoiceType.comic => t.fileSources.comics,
    DiscoveryChoiceType.music => t.common.mediaKind.album,
    DiscoveryChoiceType.video || DiscoveryChoiceType.sourceVideo => t.common.mediaKind.movie,
    DiscoveryChoiceType.liveProgram => t.liveTv.title,
  };
}

class FindNextScreen extends StatefulWidget {
  const FindNextScreen({super.key, this.libraryGlobalKey, this.includeCatalog = false});

  /// Optional starting scope when entered from a library context.
  final String? libraryGlobalKey;

  /// Catalog rows are included only when entered through Explore, after its
  /// normal profile visibility and PIN gate has admitted the user.
  final bool includeCatalog;

  @override
  State<FindNextScreen> createState() => _FindNextScreenState();
}

class _FindNextScreenState extends State<FindNextScreen> {
  List<DiscoveryChoice> _choices = const [];
  DiscoveryState _state = const DiscoveryState();
  String? _ownerProfileId;
  int _sourceGeneration = -1;
  int _position = 0;
  int _loadGeneration = 0;
  bool _loading = true;
  bool _committing = false;
  bool _retired = false;
  String? _feedback;
  int _artworkRevision = 0;
  DiscoveryChoice? _restoredChoice;
  _DiscoveryFamily _family = _DiscoveryFamily.anything;
  int? _maxMinutes;
  late DiscoveryStore _store;

  bool get _catalogAllowed {
    final profileId = _ownerProfileId;
    final settings = SettingsService.instanceOrNull;
    return widget.includeCatalog &&
        profileId != null &&
        settings != null &&
        settings.read(SettingsService.showExploreTab) &&
        settings.read(SettingsService.showExploreTabForProfile(profileId));
  }

  DiscoveryChoice? get _current {
    final restored = _restoredChoice;
    if (restored != null) return restored;
    for (var index = _position; index < _choices.length; index++) {
      final choice = _choices[index];
      if (!_state.seen.contains(choice.id) && _matchesFilters(choice)) return choice;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profileId = context.watch<ActiveProfileProvider>().active?.id;
    if (_ownerProfileId != null && profileId != _ownerProfileId && !_retired) {
      _retired = true;
      _loadGeneration++;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _choices = const [];
          _state = const DiscoveryState();
          _restoredChoice = null;
          _loading = false;
        });
      });
    }
  }

  bool _sessionCurrent(String profileId, int sourceGeneration, int request) {
    if (!mounted || request != _loadGeneration || _retired) return false;
    if (context.read<ActiveProfileProvider>().active?.id != profileId) return false;
    final sources = context.read<SourceController>();
    return sources.current(sourceGeneration) && sources.profileId == profileId && !sources.blocked;
  }

  Future<void> _load({bool fresh = false}) async {
    final request = ++_loadGeneration;
    final activeProfile = context.read<ActiveProfileProvider>().active;
    final profileId = activeProfile?.id;
    final sources = context.read<SourceController>();
    if (profileId == null) {
      setState(() {
        _loading = false;
        _choices = const [];
      });
      return;
    }
    setState(() {
      _loading = true;
      _retired = false;
      _feedback = null;
    });
    try {
      await sources.ready;
      sources.requireSession();
      final sourceGeneration = sources.generation;
      if (sources.profileId != profileId) return;
      _ownerProfileId = profileId;
      _sourceGeneration = sourceGeneration;
      _store = DiscoveryStore(sources.repository);
      final state = fresh ? await _store.startFreshSession(profileId) : await _store.load(profileId);
      if (!_sessionCurrent(profileId, sourceGeneration, request)) return;

      final candidates = await _fetchCandidates(profileId, sourceGeneration, request);
      if (!_sessionCurrent(profileId, sourceGeneration, request)) return;
      final ranked = balanceDiscoveryChoices(candidates, seed: DateTime.now().millisecondsSinceEpoch);
      final nextPosition = ranked.indexWhere((choice) => !state.seen.contains(choice.id) && _matchesFilters(choice));
      setState(() {
        _state = state;
        _choices = ranked;
        _restoredChoice = null;
        _position = nextPosition < 0 ? ranked.length : nextPosition;
        _loading = false;
      });
    } catch (_) {
      if (_sessionCurrent(profileId, sources.generation, request)) {
        setState(() {
          _loading = false;
          _choices = const [];
        });
      }
    }
  }

  Future<List<DiscoveryChoice>> _fetchCandidates(String profileId, int sourceGeneration, int request) async {
    final result = <DiscoveryChoice>[];
    final multiServer = context.read<MultiServerProvider>();
    final offlineOnly = !context.read<OfflineModeProvider>().hasNetworkConnection;
    final downloads = context.read<DownloadProvider>();
    final hiddenLibraries = context.read<HiddenLibrariesProvider>();
    final librariesProvider = context.read<LibrariesProvider>();
    final sources = context.read<SourceController>();
    final explore = context.read<ExploreProvider?>();
    final downloaded = <MediaItem>[
      ...downloads.downloadedMovies,
      ...downloads.downloadedEpisodes,
      ...downloads.downloadedTracks,
      ...downloads.downloadedAlbums,
      ...downloads.downloadedSeasons,
      ...downloads.downloadedShows,
    ];
    for (final item in downloaded) {
      final libraryKey = item.libraryGlobalKey;
      if (libraryKey != null && hiddenLibraries.hiddenLibraryKeys.contains(libraryKey)) continue;
      final library = MediaLibrary(
        id: item.libraryId ?? 'downloads',
        backend: item.backend,
        title: t.downloads.title,
        kind: item.kind,
        serverId: item.serverId,
      );
      final choice = _choiceForMedia(item, library, offlineReady: true);
      if (choice != null) result.add(choice);
    }
    if (!offlineOnly && librariesProvider.libraries.isEmpty && multiServer.hasConnectedServers) {
      await librariesProvider.loadLibraries();
    }
    if (!mounted || !_sessionCurrent(profileId, sourceGeneration, request)) return result;

    final visibleServerIds = multiServer.serverIds.toSet();
    var libraries = offlineOnly
        ? <MediaLibrary>[]
        : visibleMediaLibraries(
            librariesProvider.libraries,
            hiddenKeys: hiddenLibraries.hiddenLibraryKeys,
            hideEmpty: false,
          ).where((library) => library.serverId != null && visibleServerIds.contains(library.serverId)).toList();
    final scopedKey = widget.libraryGlobalKey;
    if (scopedKey != null) libraries = libraries.where((library) => library.globalKey == scopedKey).toList();
    libraries = libraries.take(9).toList();

    // Query small pages with a hard concurrency bound. It remains useful on a
    // very large server library without scanning the full catalog.
    for (var start = 0; start < libraries.length; start += 3) {
      final batch = libraries.skip(start).take(3);
      await Future.wait([
        for (final library in batch)
          _fetchLibraryPage(library, multiServer).then((choices) => result.addAll(choices)).catchError((Object _) {}),
      ]);
      if (!_sessionCurrent(profileId, sourceGeneration, request)) return result;
    }

    final activeSourceIds = sources.sources.map((source) => source.id).toSet();
    final indexed = await sources.repository.recentEntries(profileId, limit: 72);
    if (!mounted || !_sessionCurrent(profileId, sourceGeneration, request)) return result;
    final bySource = {for (final source in sources.sources) source.id: source};
    final candidateIds = result.map((choice) => choice.id).toSet();
    for (final entry in indexed) {
      if (!activeSourceIds.contains(entry.sourceId)) continue;
      if (candidateIds.contains(discoverySourceIdentity(entry))) continue;
      final source = bySource[entry.sourceId];
      if (source == null) continue;
      final choice = await _choiceForSource(entry, source, sources, profileId, offlineOnly: offlineOnly);
      if (choice != null) {
        result.add(choice);
        candidateIds.add(choice.id);
      }
    }

    // Root browse is one bounded page per connected source. It makes a freshly
    // configured source useful without starting a recursive scan.
    final rootSources = sources.sources.take(9).toList();
    for (var start = 0; !offlineOnly && start < rootSources.length; start += 3) {
      final batch = rootSources.skip(start).take(3);
      await Future.wait([
        for (final source in batch)
          sources
              .browse(source.id)
              .then((page) async {
                for (final entry in page.entries) {
                  if (candidateIds.contains(discoverySourceIdentity(entry))) continue;
                  final choice = await _choiceForSource(entry, source, sources, profileId);
                  if (choice != null) {
                    result.add(choice);
                    candidateIds.add(choice.id);
                  }
                }
              })
              .catchError((Object _) {}),
      ]);
      if (!mounted || !_sessionCurrent(profileId, sourceGeneration, request)) return result;
    }

    // Reuse the active Explore provider's bounded, profile-owned catalog rows.
    // Catalog entries are discovery/detail choices only: they are never
    // presented as owned or directly playable media.
    if (!offlineOnly && _catalogAllowed) {
      if (explore != null) {
        try {
          await explore.load();
          if (!mounted || !_sessionCurrent(profileId, sourceGeneration, request)) return result;
          if (_catalogAllowed) {
            for (final row in explore.rowHubs) {
              for (final media in row.hub.items) {
                final item = media.catalogItem;
                if (item == null) continue;
                final choice = _choiceForCatalog(item);
                if (choice != null && candidateIds.add(choice.id)) result.add(choice);
              }
            }
          }
        } catch (_) {
          // Catalog rows are an optional discovery source.
        }
      }
    }

    if (!offlineOnly && multiServer.hasConnectedServers) result.addAll(await _fetchLiveCandidates(multiServer));
    if (!mounted || !_sessionCurrent(profileId, sourceGeneration, request)) return result;
    final currentlyHidden = context.read<HiddenLibrariesProvider>().hiddenLibraryKeys;
    result.removeWhere((choice) {
      final serverId = choice.serverId;
      final libraryId = choice.libraryId;
      return serverId != null &&
          libraryId != null &&
          currentlyHidden.contains(buildGlobalKey(ServerId(serverId), libraryId));
    });
    final unique = <String, DiscoveryChoice>{};
    for (final choice in result) {
      if (choice.id.isNotEmpty) unique.putIfAbsent(choice.id, () => choice);
    }
    final all = unique.values.toList(growable: false);
    if (all.length <= 240) return all;
    return balanceDiscoveryChoices(all, seed: DateTime.now().millisecondsSinceEpoch).take(240).toList(growable: false);
  }

  Future<List<DiscoveryChoice>> _fetchLibraryPage(MediaLibrary library, MultiServerProvider multiServer) async {
    final serverId = library.serverId;
    if (serverId == null) return const [];
    final client = multiServer.getClientForServer(ServerId(serverId));
    if (client == null) return const [];
    final auth = client.authenticationSessionId;
    final supportedKinds = library.defaultBrowseKinds.where((kind) => discoveryTypeForMediaKind(kind) != null).toList();
    final kind = library.kind != MediaKind.unknown && discoveryTypeForMediaKind(library.kind) != null
        ? library.kind
        : null;
    final offsetMax = math.max(0, (library.itemCount ?? 30) - 30).toInt();
    final offset = offsetMax == 0 ? 0 : math.Random().nextInt(offsetMax + 1);
    final query = LibraryQuery(
      kind: kind,
      includeKinds: kind == null ? supportedKinds : const [],
      offset: offset,
      limit: 30,
    );
    final page = await client.fetchLibraryPagedContent(library.id, query: query, libraryKind: library.kind);
    if (!identical(client.authenticationSessionId, auth) || !multiServer.serverIds.contains(serverId)) return const [];
    return [
      for (final item in page.items)
        if (item.libraryId == null || item.libraryId == library.id)
          ?_choiceForMedia(item, library, libraryId: library.id),
    ];
  }

  DiscoveryChoice? _choiceForMedia(
    MediaItem item,
    MediaLibrary library, {
    bool offlineReady = false,
    String? libraryId,
  }) {
    if (item.serverId == null && library.serverId != null) {
      item = item.copyWith(serverId: library.serverId);
    }
    final type = discoveryTypeForMediaKind(item.kind);
    final id = discoveryMediaIdentity(item);
    final title = item.title?.trim() ?? '';
    if (type == null || id.isEmpty || title.isEmpty || item.isCatalogItem) return null;
    final duration = item.durationMs != null && item.durationMs! > 0 ? item.durationMs : null;
    final subtitle = [
      item.parentTitle,
      item.albumArtistTitle,
      if (item.year != null) formatDecimal(item.year!, maximumDecimals: 0),
      if (item.libraryTitle != null) item.libraryTitle,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).toSet().join(' · ');
    return DiscoveryChoice(
      id: id,
      type: type,
      title: title,
      subtitle: subtitle,
      reason: library.title.isNotEmpty
          ? t.discover.findNext.libraryReason(library: isolateDisplayText(library.title))
          : t.discover.findNext.ownedReason,
      summary: item.summary ?? '',
      durationMs: duration,
      totalDurationMs: duration,
      isEstimate: false,
      serverId: item.serverId,
      mediaId: item.id,
      mediaKind: item.kind,
      sourceId: null,
      entryId: null,
      libraryId: libraryId ?? item.libraryId,
      year: item.year,
      offlineReady: offlineReady,
      mediaItem: item,
      artworkPath: item.posterThumb(mixedHubContext: true),
    );
  }

  DiscoveryChoice? _choiceForCatalog(CatalogItem item) {
    final entryKey = item.entryIdentityKey.trim();
    final title = item.title.trim();
    if (!item.ids.hasAny || entryKey.isEmpty || title.isEmpty) return null;
    final media = item.toMediaItem();
    final sourceLabel =
        context
            .read<CatalogSourcesProvider?>()
            ?.connectedSources
            .where((source) => source.id == item.source)
            .firstOrNull
            ?.displayName ??
        item.source.name;
    return DiscoveryChoice(
      id: jsonEncode(['catalog-title', item.source.name, entryKey]),
      type: DiscoveryChoiceType.video,
      title: title,
      subtitle: sourceLabel,
      reason: t.discover.findNext.sourceReason(source: isolateDisplayText(sourceLabel)),
      summary: item.overview ?? '',
      durationMs: item.kind == MediaKind.movie ? media.durationMs : null,
      totalDurationMs: item.kind == MediaKind.movie ? media.durationMs : null,
      isEstimate: false,
      serverId: null,
      mediaId: null,
      mediaKind: item.kind,
      sourceId: null,
      entryId: null,
      year: item.year,
      catalogSourceId: item.source.name,
      catalogEntryKey: entryKey,
      catalogItem: item,
      artworkPath: item.posterFor(640),
    );
  }

  Future<DiscoveryChoice?> _choiceForSource(
    SourceEntry entry,
    FileSource source,
    SourceController controller,
    String profileId, {
    bool offlineOnly = false,
  }) async {
    final type = discoveryTypeForSourceKind(entry.kind);
    final id = discoverySourceIdentity(entry);
    if (type == null || id.isEmpty || entry.title.trim().isEmpty) return null;
    if (offlineOnly) {
      final playableFiles = switch (entry.kind) {
        SourceItemKind.ebook || SourceItemKind.comic => entry.ebooks,
        SourceItemKind.audiobook || SourceItemKind.music || SourceItemKind.video => entry.files,
        SourceItemKind.folder || SourceItemKind.unknown => const <PublicationFile>[],
      };
      var hasLocalFile = source.kind == FileSourceKind.local && playableFiles.isNotEmpty;
      if (!hasLocalFile) {
        for (final file in playableFiles) {
          if (await controller.downloads.local(profileId, entry.sourceId, file) != null) {
            hasLocalFile = true;
            break;
          }
        }
      }
      if (!hasLocalFile) return null;
    }
    final audio = entry.audio;
    final totalDuration = _sumKnownDurations(entry.files.map((file) => file.durationMs));
    var unitDuration = totalDuration;
    var isEstimate = false;
    var unitLabel = '';
    if (entry.kind == SourceItemKind.audiobook && entry.chapters.isNotEmpty && audio.isNotEmpty) {
      try {
        final edition = sourceDigest(jsonEncode(audio.map((file) => file.fingerprint).toList()));
        final progress = await controller.repository.progress(profileId, jsonEncode([entry.key, edition, 'listening']));
        final position = progress?.positionMs ?? 0;
        final speed = progress?.speed ?? 1.0;
        final chapter = entry.chapters.where((item) => item.endMs > position).firstOrNull;
        if (chapter != null && chapter.endMs > chapter.startMs && speed > 0 && speed <= 8) {
          unitDuration = ((chapter.endMs - math.max(chapter.startMs, position)) / speed).round();
          unitLabel = chapter.title;
          isEstimate = speed != 1;
        }
      } catch (_) {
        // Missing or stale reading progress only removes the chapter hint.
      }
    }
    final subtitle = [
      entry.author,
      if (entry.narrator.isNotEmpty) entry.narrator,
      entry.series,
    ].where((value) => value.trim().isNotEmpty).join(' · ');
    return DiscoveryChoice(
      id: id,
      type: type,
      title: entry.title.trim(),
      subtitle: subtitle,
      reason: t.discover.findNext.sourceReason(source: isolateDisplayText(source.name)),
      summary: entry.description,
      durationMs: unitDuration,
      totalDurationMs: totalDuration,
      isEstimate: isEstimate,
      unitLabel: unitLabel,
      serverId: null,
      mediaId: null,
      mediaKind: null,
      sourceId: entry.sourceId,
      entryId: entry.id,
      year: null,
      sourceEntry: entry,
      offlineReady: offlineOnly,
    );
  }

  int? _sumKnownDurations(Iterable<int?> durations) {
    final known = durations.whereType<int>().where((value) => value > 0).toList();
    if (known.isEmpty) return null;
    return known.fold<int>(0, (sum, value) => sum + value);
  }

  Future<List<DiscoveryChoice>> _fetchLiveCandidates(MultiServerProvider multiServer) async {
    final result = <DiscoveryChoice>[];
    final now = DateTime.now().toUtc();
    final nowSeconds = now.millisecondsSinceEpoch ~/ 1000;
    final from = now.subtract(const Duration(hours: 1));
    final to = now.add(const Duration(hours: 1));
    final visited = <String>{};
    for (final server in multiServer.liveTvServers.take(3)) {
      final scope = '${server.serverId}\u0000${server.dvrKey}';
      if (!visited.add(scope)) continue;
      final client = multiServer.getClientForServer(ServerId(server.serverId));
      if (client == null) continue;
      final authentication = client.authenticationSessionId;
      try {
        final channels = await client.liveTv.fetchChannels(lineup: server.lineup);
        final programs = await client.liveTv.fetchSchedule(from: from, to: to);
        if (!identical(authentication, client.authenticationSessionId)) continue;
        for (final program in programs) {
          final start = program.beginsAt;
          final end = program.endsAt;
          final rawProgramId = (program.ratingKey ?? program.guid)?.trim();
          if (start == null ||
              end == null ||
              rawProgramId == null ||
              rawProgramId.isEmpty ||
              start > nowSeconds ||
              end <= nowSeconds) {
            continue;
          }
          final channel = channels.where((item) => liveTvProgramMatchesChannel(program, item)).firstOrNull;
          if (channel == null || channel.key.isEmpty) continue;
          final programId = _safeLiveReference(rawProgramId);
          final channelId = _safeLiveReference(channel.key);
          final dvrId = _safeLiveReference(server.dvrKey);
          final id = jsonEncode(['live-airing', server.serverId, dvrId, channelId, programId, start]);
          final remainingMs = (end - nowSeconds) * 1000;
          result.add(
            DiscoveryChoice(
              id: id,
              type: DiscoveryChoiceType.liveProgram,
              title: program.title,
              subtitle: channel.displayName,
              reason: t.discover.findNext.liveNow,
              summary: program.summary ?? '',
              durationMs: remainingMs,
              totalDurationMs: null,
              isEstimate: false,
              serverId: server.serverId,
              mediaId: null,
              mediaKind: null,
              sourceId: null,
              entryId: null,
              year: program.year,
              liveProgramId: programId,
              channelId: channelId,
              dvrKey: dvrId,
              liveBeginsAtSeconds: start,
              liveEndsAtSeconds: end,
              liveProgram: program,
              liveChannel: channel,
              artworkPath: program.thumb ?? channel.thumb ?? channel.art,
            ),
          );
        }
      } catch (_) {
        // Live TV is an optional source. A guide failure does not block the deck.
      }
    }
    return result;
  }

  bool _matchesFilters(DiscoveryChoice choice) {
    final familyMatches = switch (_family) {
      _DiscoveryFamily.anything => true,
      _DiscoveryFamily.watch =>
        choice.type == DiscoveryChoiceType.video ||
            choice.type == DiscoveryChoiceType.sourceVideo ||
            choice.type == DiscoveryChoiceType.liveProgram,
      _DiscoveryFamily.listen =>
        choice.type == DiscoveryChoiceType.music || choice.type == DiscoveryChoiceType.audiobook,
      _DiscoveryFamily.read => choice.type == DiscoveryChoiceType.ebook || choice.type == DiscoveryChoiceType.comic,
    };
    if (!familyMatches) return false;
    final maxMinutes = _maxMinutes;
    if (maxMinutes == null) return true;
    final duration = choice.durationMs;
    return duration != null && duration <= Duration(minutes: maxMinutes).inMilliseconds;
  }

  Future<void> _showFilters() async {
    var family = _family;
    var maxMinutes = _maxMinutes;
    final result = await OverlaySheetController.showAdaptive<({_DiscoveryFamily family, int? minutes})>(
      context,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.discover.findNext.filters, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in _DiscoveryFamily.values)
                    ChoiceChip(
                      label: Text(_familyLabel(item)),
                      selected: item == family,
                      onSelected: (_) => setSheetState(() => family = item),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(t.discover.findNext.timeAvailable, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final item in <int?>[null, 20, 45, 90])
                    ChoiceChip(
                      label: Text(
                        localizeDecimalDigits(switch (item) {
                          null => t.discover.findNext.anyTime,
                          20 => t.discover.findNext.twentyMinutes,
                          45 => t.discover.findNext.fortyFiveMinutes,
                          _ => t.discover.findNext.ninetyMinutes,
                        }),
                      ),
                      selected: item == maxMinutes,
                      onSelected: (_) => setSheetState(() => maxMinutes = item),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop((family: family, minutes: maxMinutes)),
                  child: Text(t.discover.findNext.apply),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      _restoredChoice = null;
      _feedback = null;
      _family = result.family;
      _maxMinutes = result.minutes;
      _position = _choices.indexWhere((choice) => !_state.seen.contains(choice.id) && _matchesFilters(choice));
      if (_position < 0) _position = _choices.length;
    });
  }

  String _familyLabel(_DiscoveryFamily family) => switch (family) {
    _DiscoveryFamily.anything => t.discover.findNext.filterAnything,
    _DiscoveryFamily.watch => t.discover.findNext.filterWatch,
    _DiscoveryFamily.listen => t.discover.findNext.filterListen,
    _DiscoveryFamily.read => t.discover.findNext.filterRead,
  };

  Future<void> _decide(DiscoveryDecisionAction action) async {
    if (_committing || _current == null) return;
    final choice = _current!;
    if (action == DiscoveryDecisionAction.save &&
        !_state.saved.any((saved) => saved.id == choice.id) &&
        _state.saved.length >= DiscoveryStore.maxSaved) {
      showErrorSnackBar(context, t.discover.findNext.savedLimit);
      return;
    }
    final profileId = _ownerProfileId;
    final sources = context.read<SourceController>();
    if (profileId == null || sources.profileId != profileId || !sources.current(_sourceGeneration)) return;
    setState(() => _committing = true);
    try {
      final state = await _store.decide(profileId, choice, action);
      if (!mounted ||
          context.read<ActiveProfileProvider>().active?.id != profileId ||
          !sources.current(_sourceGeneration)) {
        return;
      }
      setState(() {
        _state = state;
        _restoredChoice = null;
        if (_current == choice || _position < _choices.length) {
          final index = _choices.indexWhere((item) => item.id == choice.id);
          if (index >= _position) _position = index + 1;
        }
        _feedback = action == DiscoveryDecisionAction.save
            ? t.discover.findNext.savedFeedback
            : t.discover.findNext.skippedFeedback;
      });
    } catch (_) {
      if (mounted) showErrorSnackBar(context, t.discover.findNext.changeFailed);
    } finally {
      if (mounted) setState(() => _committing = false);
    }
  }

  Future<void> _undo() async {
    if (_committing || _ownerProfileId == null) return;
    final lastDecision = _state.history.lastOrNull;
    if (!_catalogAllowed && lastDecision?.choice.catalogSourceId != null) return;
    final profileId = _ownerProfileId!;
    final sources = context.read<SourceController>();
    if (!sources.current(_sourceGeneration) || sources.profileId != profileId) return;
    setState(() => _committing = true);
    try {
      final (state, snapshot) = await _store.undo(profileId);
      if (!mounted ||
          context.read<ActiveProfileProvider>().active?.id != profileId ||
          !sources.current(_sourceGeneration)) {
        return;
      }
      if (snapshot != null) {
        final currentVersion = _choices.where((choice) => choice.id == snapshot.id).firstOrNull;
        setState(() {
          _state = state;
          _feedback = null;
          _restoredChoice = currentVersion ?? snapshot;
        });
      }
    } catch (_) {
      if (mounted) showErrorSnackBar(context, t.discover.findNext.changeFailed);
    } finally {
      if (mounted) setState(() => _committing = false);
    }
  }

  Future<void> _openSaved() async {
    final profileId = _ownerProfileId;
    if (profileId == null || !mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _SavedPicksScreen(
          profileId: profileId,
          store: _store,
          includeCatalog: _catalogAllowed,
          onOpen: _openChoice,
          onChanged: () async {
            if (!mounted || context.read<ActiveProfileProvider>().active?.id != profileId) return;
            _state = await _store.load(profileId);
            setState(() {});
          },
        ),
      ),
    );
    if (mounted && context.read<ActiveProfileProvider>().active?.id == profileId) {
      _state = await _store.load(profileId);
      setState(() {});
    }
  }

  Future<void> _openChoice(DiscoveryChoice choice, {bool detailsOnly = false}) async {
    final profileId = _ownerProfileId;
    final sources = context.read<SourceController>();
    if (profileId == null ||
        context.read<ActiveProfileProvider>().active?.id != profileId ||
        !sources.current(_sourceGeneration)) {
      return;
    }
    try {
      if (choice.catalogSourceId != null) {
        if (!_catalogAllowed) throw const SourceException(SourceFailure.permission);
        await _openCatalogChoice(choice, profileId);
        return;
      }
      if (choice.liveProgramId != null) {
        await _openLiveChoice(choice, detailsOnly: detailsOnly);
        return;
      }
      if (choice.sourceId != null && choice.entryId != null) {
        sources.requireSession(_sourceGeneration);
        final sourceConnected = sources.sources.any((source) => source.id == choice.sourceId);
        var entry = await sources.repository.entryById(profileId, choice.sourceId!, choice.entryId!);
        entry ??= choice.sourceEntry;
        if (entry == null || entry.kind == SourceItemKind.folder || entry.kind == SourceItemKind.unknown) {
          throw const SourceException(SourceFailure.unavailable);
        }
        if (!sourceConnected) {
          var hasLocalContent = false;
          for (final file in entry.files) {
            if (await sources.downloads.local(profileId, entry.sourceId, file) != null) {
              hasLocalContent = true;
              break;
            }
          }
          if (!hasLocalContent) throw const SourceException(SourceFailure.permission);
        }
        if (sourceConnected) {
          try {
            entry = await sources.hydrate(entry);
          } catch (_) {
            // Cached details remain usable when the source is temporarily offline.
          }
        }
        sources.requireSession(_sourceGeneration);
        if (!mounted || context.read<ActiveProfileProvider>().active?.id != profileId) return;
        await Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => SourceDetailScreen(entry: entry!)));
        return;
      }
      final serverId = choice.serverId;
      final mediaId = choice.mediaId;
      if (serverId == null || mediaId == null) throw const SourceException(SourceFailure.unavailable);
      final multiServer = context.read<MultiServerProvider>();
      final hasNetworkConnection = context.read<OfflineModeProvider>().hasNetworkConnection;
      final canResolveLocally =
          choice.offlineReady || !hasNetworkConnection || !multiServer.serverIds.contains(serverId);
      if (canResolveLocally) {
        if (choice.libraryId != null &&
            context.read<HiddenLibrariesProvider>().hiddenLibraryKeys.contains(
              buildGlobalKey(ServerId(serverId), choice.libraryId!),
            )) {
          throw const SourceException(SourceFailure.permission);
        }
        final downloads = context.read<DownloadProvider>();
        final media =
            choice.mediaItem ??
            downloads.metadata.values.where((item) => item.serverId == serverId && item.id == mediaId).firstOrNull;
        if (media != null && await downloads.getCompletedDownload(media.globalKey) != null) {
          if (!mounted || context.read<ActiveProfileProvider>().active?.id != profileId) return;
          if (detailsOnly) {
            await navigateToMediaItemDetails(context, media, isOffline: true);
          } else {
            await navigateToMediaItem(context, media, isOffline: true, playDirectly: true);
          }
          return;
        }
        if (choice.offlineReady || !hasNetworkConnection || !multiServer.serverIds.contains(serverId)) {
          throw const SourceException(SourceFailure.unavailable);
        }
      }
      if (!multiServer.serverIds.contains(serverId)) throw const SourceException(SourceFailure.permission);
      final client = multiServer.getClientForServer(ServerId(serverId));
      if (client == null) throw const SourceException(SourceFailure.unavailable);
      final authentication = client.authenticationSessionId;
      if (choice.mediaKind == MediaKind.playlist) {
        final playlist = await client.fetchPlaylistMetadata(mediaId);
        if (!mounted ||
            context.read<ActiveProfileProvider>().active?.id != profileId ||
            !sources.current(_sourceGeneration) ||
            !identical(client.authenticationSessionId, authentication) ||
            playlist == null ||
            playlist.id != mediaId ||
            playlist.serverId != serverId) {
          throw const SourceException(SourceFailure.permission);
        }
        if (choice.libraryId != null) {
          final libraryKey = buildGlobalKey(ServerId(serverId), choice.libraryId!);
          final hiddenLibraries = context.read<HiddenLibrariesProvider>();
          final isVisible = context.read<LibrariesProvider>().libraries.any(
            (library) => library.globalKey == libraryKey && !hiddenLibraries.hiddenLibraryKeys.contains(libraryKey),
          );
          if (!isVisible) throw const SourceException(SourceFailure.permission);
        }
        await navigateToMediaItem(context, playlist);
        return;
      }
      final media = await client.fetchItem(mediaId);
      if (!mounted ||
          context.read<ActiveProfileProvider>().active?.id != profileId ||
          !sources.current(_sourceGeneration) ||
          !identical(client.authenticationSessionId, authentication) ||
          media == null ||
          media.id != mediaId ||
          media.serverId != serverId ||
          media.kind != choice.mediaKind) {
        throw const SourceException(SourceFailure.permission);
      }
      final libraryId = media.libraryId ?? choice.libraryId;
      if (libraryId != null) {
        final globalLibraryKey = buildGlobalKey(ServerId(serverId), libraryId);
        final hiddenLibraries = context.read<HiddenLibrariesProvider>();
        final isCurrentlyVisible = context.read<LibrariesProvider>().libraries.any(
          (library) =>
              library.globalKey == globalLibraryKey && !hiddenLibraries.hiddenLibraryKeys.contains(globalLibraryKey),
        );
        if (!isCurrentlyVisible) throw const SourceException(SourceFailure.permission);
      }
      if (detailsOnly) {
        await navigateToMediaItemDetails(context, media);
      } else {
        await navigateToMediaItem(
          context,
          media,
          playDirectly:
              media.kind == MediaKind.movie || media.kind == MediaKind.episode || media.kind == MediaKind.clip,
        );
      }
    } catch (_) {
      if (mounted && context.read<ActiveProfileProvider>().active?.id == profileId) {
        showErrorSnackBar(context, t.discover.findNext.openFailed);
      }
    }
  }

  Future<void> _openCatalogChoice(DiscoveryChoice choice, String profileId) async {
    final sourceName = choice.catalogSourceId;
    final entryKey = choice.catalogEntryKey;
    if (sourceName == null || entryKey == null) throw const SourceException(SourceFailure.unavailable);
    final sourceId = CatalogSourceId.values.where((value) => value.name == sourceName).firstOrNull;
    final provider = context.read<CatalogSourcesProvider?>();
    final source = sourceId == null
        ? null
        : provider?.connectedSources.where((value) => value.id == sourceId).firstOrNull;
    if (source == null) throw const SourceException(SourceFailure.permission);
    var item = choice.catalogItem;
    if (item == null || item.source != source.id || item.entryIdentityKey != entryKey) {
      final matches = await source.search(choice.title, limit: 30);
      if (!mounted || context.read<ActiveProfileProvider>().active?.id != profileId) return;
      if (!_catalogAllowed) throw const SourceException(SourceFailure.permission);
      final stillConnected =
          context.read<CatalogSourcesProvider?>()?.connectedSources.any((value) => identical(value, source)) ?? false;
      if (!stillConnected) throw const SourceException(SourceFailure.permission);
      item = matches.where((value) => value.source == source.id && value.entryIdentityKey == entryKey).firstOrNull;
    }
    if (item == null || item.entryIdentityKey != entryKey) throw const SourceException(SourceFailure.unavailable);
    await navigateToCatalogItem(context, item);
  }

  Future<void> _openLiveChoice(DiscoveryChoice choice, {bool detailsOnly = false}) async {
    final profileId = _ownerProfileId;
    if (profileId == null || choice.serverId == null || choice.channelId == null || choice.liveProgramId == null) {
      return;
    }
    final multiServer = context.read<MultiServerProvider>();
    final liveServer = multiServer.liveTvServers
        .where((server) => server.serverId == choice.serverId && _safeLiveReference(server.dvrKey) == choice.dvrKey)
        .firstOrNull;
    if (liveServer == null) throw const SourceException(SourceFailure.permission);
    final client = multiServer.getClientForServer(ServerId(choice.serverId!));
    if (client == null || !multiServer.serverIds.contains(choice.serverId)) {
      throw const SourceException(SourceFailure.unavailable);
    }
    final authentication = client.authenticationSessionId;
    final now = DateTime.now().toUtc();
    final programs = await client.liveTv.fetchSchedule(
      from: now.subtract(const Duration(hours: 1)),
      to: now.add(const Duration(minutes: 1)),
    );
    final channels = await client.liveTv.fetchChannels(lineup: liveServer.lineup);
    if (!mounted ||
        context.read<ActiveProfileProvider>().active?.id != profileId ||
        !identical(client.authenticationSessionId, authentication)) {
      return;
    }
    final nowSeconds = now.millisecondsSinceEpoch ~/ 1000;
    final current = programs.where((program) {
      final identity = (program.ratingKey ?? program.guid)?.trim();
      return identity != null &&
          _safeLiveReference(identity) == choice.liveProgramId &&
          program.beginsAt != null &&
          program.beginsAt! <= nowSeconds &&
          program.endsAt != null &&
          program.endsAt! > nowSeconds;
    }).firstOrNull;
    final channel = channels.where((item) => _safeLiveReference(item.key) == choice.channelId).firstOrNull;
    if (current == null || channel == null || !liveTvProgramMatchesChannel(current, channel)) {
      throw const SourceException(SourceFailure.unavailable);
    }
    final poster = current.thumb ?? channel.thumb ?? channel.art;
    final posterUrl = poster == null
        ? null
        : MediaImageHelper.getOptimizedImageUrl(
            client: client,
            thumbPath: poster,
            maxWidth: 120,
            maxHeight: 180,
            pixelRatio: MediaImageHelper.artworkPixelRatio(context),
          );
    if (detailsOnly) {
      showProgramDetailsSheet(
        context,
        program: current,
        channel: channel,
        posterUrl: posterUrl,
        client: client,
        onTuneChannel: () => navigateToLiveTv(context, multiServer: multiServer, channel: channel, channels: channels),
      );
    } else {
      await navigateToLiveTv(context, multiServer: multiServer, channel: channel, channels: channels);
    }
  }

  Future<void> _showDetails(DiscoveryChoice choice) async {
    if (choice.liveProgram != null && choice.liveChannel != null && choice.serverId != null) {
      unawaited(_openLiveChoice(choice, detailsOnly: true));
      return;
    }
    await _openChoice(choice, detailsOnly: true);
  }

  String _typeLabel(DiscoveryChoice choice) {
    if (choice.liveProgramId != null) return t.discover.findNext.liveNow;
    if (choice.mediaKind != null) return choice.mediaKind!.label;
    return switch (choice.type) {
      DiscoveryChoiceType.ebook => t.fileSources.ebooks,
      DiscoveryChoiceType.audiobook => t.fileSources.audiobooks,
      DiscoveryChoiceType.comic => t.fileSources.comics,
      DiscoveryChoiceType.music => t.common.mediaKind.album,
      DiscoveryChoiceType.sourceVideo || DiscoveryChoiceType.video => t.common.mediaKind.movie,
      DiscoveryChoiceType.liveProgram => t.liveTv.title,
    };
  }

  String _primaryLabel(DiscoveryChoice choice) {
    if (choice.catalogSourceId != null) return t.discover.findNext.details;
    if (choice.liveProgramId != null) return t.discover.findNext.watchLive;
    return switch (choice.type) {
      DiscoveryChoiceType.video =>
        choice.mediaKind == MediaKind.movie ||
                choice.mediaKind == MediaKind.episode ||
                choice.mediaKind == MediaKind.clip
            ? t.common.play
            : t.discover.findNext.details,
      DiscoveryChoiceType.sourceVideo => t.discover.findNext.watch,
      DiscoveryChoiceType.music =>
        choice.sourceId != null || choice.mediaKind == MediaKind.track
            ? t.discover.findNext.listen
            : t.discover.findNext.details,
      DiscoveryChoiceType.audiobook => t.discover.findNext.listen,
      DiscoveryChoiceType.ebook || DiscoveryChoiceType.comic => t.discover.findNext.read,
      DiscoveryChoiceType.liveProgram => t.discover.findNext.watchLive,
    };
  }

  String _durationLabel(DiscoveryChoice choice) {
    final duration = choice.durationMs;
    if (duration == null) return t.discover.findNext.timingVaries;
    final formatted = formatDurationTextual(duration);
    if (choice.type == DiscoveryChoiceType.liveProgram) {
      return t.discover.minutesLeft(minutes: '${(duration / 60000).ceil()}');
    }
    final displayDuration = choice.isEstimate ? t.discover.findNext.aboutDuration(duration: formatted) : formatted;
    if (choice.unitLabel.isNotEmpty) {
      return '${t.discover.findNext.nextUnit(duration: displayDuration)} · ${choice.unitLabel}';
    }
    if (_maxMinutes != null) return t.discover.findNext.finishable(duration: displayDuration);
    if (choice.totalDurationMs != null && choice.totalDurationMs != duration) {
      final total = formatDurationTextual(choice.totalDurationMs!);
      return '${t.discover.findNext.finishable(duration: formatted)} · ${t.discover.findNext.totalDuration(duration: total)}';
    }
    return t.discover.findNext.totalDuration(duration: displayDuration);
  }

  bool _isCoverChoice(DiscoveryChoice choice) => switch (choice.type) {
    DiscoveryChoiceType.music ||
    DiscoveryChoiceType.audiobook ||
    DiscoveryChoiceType.ebook ||
    DiscoveryChoiceType.comic => true,
    DiscoveryChoiceType.video || DiscoveryChoiceType.sourceVideo || DiscoveryChoiceType.liveProgram => false,
  };

  double _artworkAspectRatio(DiscoveryChoice choice) => switch (choice.type) {
    DiscoveryChoiceType.music => GridLayoutConstants.squareAspectRatio,
    DiscoveryChoiceType.liveProgram => GridLayoutConstants.episodeThumbnailAspectRatio,
    DiscoveryChoiceType.video ||
    DiscoveryChoiceType.sourceVideo ||
    DiscoveryChoiceType.audiobook ||
    DiscoveryChoiceType.ebook ||
    DiscoveryChoiceType.comic => GridLayoutConstants.fullCardPosterAspectRatio,
  };

  Widget _artwork(DiscoveryChoice choice, {bool backdrop = false}) {
    final sourceEntry = choice.sourceEntry;
    final sources = context.read<SourceController>();
    final serverId = choice.serverId;
    final client = serverId == null
        ? null
        : context.watch<MultiServerProvider>().getClientForServer(ServerId(serverId));
    final downloads = context.watch<DownloadProvider>();
    // Prefer every available downloaded image before making a network request.
    // A show's poster may not be cached, while an episode/album thumb is.
    final paths = discoveryArtworkPaths(choice, backdrop: backdrop);
    final downloadedThumb = choice.mediaItem == null
        ? null
        : downloads.getArtworkPaths(choice.mediaItem!.globalKey)?.thumbPath;
    if (downloadedThumb != null && downloadedThumb.isNotEmpty && !paths.contains(downloadedThumb)) {
      paths.add(downloadedThumb);
    }
    return DiscoveryArtwork(
      key: ValueKey(
        [
          _ownerProfileId,
          _sourceGeneration,
          _artworkRevision,
          choice.id,
          sourceEntry?.coverId,
          sourceEntry?.onlinePosterUrl,
        ].join(':'),
      ),
      paths: paths,
      decorative: backdrop,
      onRetry: backdrop ? null : () => setState(() => _artworkRevision++),
      client: client,
      localPathFor: serverId == null ? null : (path) => downloads.getArtworkLocalPath(ServerId(serverId), path),
      loadCover: sourceEntry == null ? null : (refresh) => sources.cover(sourceEntry, refresh: refresh),
      fit: !backdrop && _isCoverChoice(choice) ? BoxFit.contain : BoxFit.cover,
      icon: _iconForChoice(choice),
      imageType: backdrop
          ? ImageType.art
          : switch (choice.type) {
              DiscoveryChoiceType.music => ImageType.square,
              DiscoveryChoiceType.liveProgram => ImageType.thumb,
              _ => ImageType.poster,
            },
    );
  }

  IconData _iconForChoice(DiscoveryChoice choice) => switch (choice.type) {
    DiscoveryChoiceType.video || DiscoveryChoiceType.sourceVideo => Symbols.movie_rounded,
    DiscoveryChoiceType.music => Symbols.album_rounded,
    DiscoveryChoiceType.audiobook => Symbols.headphones_rounded,
    DiscoveryChoiceType.ebook => Symbols.menu_book_rounded,
    DiscoveryChoiceType.comic => Symbols.auto_stories_rounded,
    DiscoveryChoiceType.liveProgram => Symbols.live_tv_rounded,
  };

  Widget _buildChoice(DiscoveryChoice choice, {required bool canUndo}) => DiscoveryDeckView(
    choiceId: choice.id,
    title: isolateDisplayText(choice.title),
    subtitle: [choice.subtitle, choice.reason].where((text) => text.isNotEmpty).map(isolateDisplayText).join(' · '),
    facts: [_typeLabel(choice), _durationLabel(choice), if (choice.offlineReady) t.fileSources.offline].join(' · '),
    summary: isolateDisplayText(choice.summary),
    artwork: _artwork(choice),
    artworkAspectRatio: _artworkAspectRatio(choice),
    enabled: !_committing,
    onSave: () => _decide(DiscoveryDecisionAction.save),
    onSkip: () => _decide(DiscoveryDecisionAction.notNow),
    onDetails: () => _showDetails(choice),
    actions: DiscoveryActionBar(
      primaryLabel: _primaryLabel(choice),
      primaryIcon: _iconForChoice(choice),
      showDetails: _primaryLabel(choice) != t.discover.findNext.details,
      onSkip: _committing ? null : () => _decide(DiscoveryDecisionAction.notNow),
      onSave: _committing ? null : () => _decide(DiscoveryDecisionAction.save),
      onOpen: _committing ? null : () => _openChoice(choice),
      onDetails: _committing || _primaryLabel(choice) == t.discover.findNext.details
          ? null
          : () => _showDetails(choice),
      onUndo: _committing || !canUndo ? null : _undo,
      feedback: _feedback,
    ),
  );

  Widget _buildEmpty({required bool noMatches, bool allSeen = false}) => DiscoveryEmptyView(
    heading: noMatches
        ? t.discover.findNext.noMatches
        : allSeen
        ? t.discover.findNext.allDone
        : t.discover.findNext.noPicks,
    hint: noMatches
        ? t.discover.findNext.noMatchesHint
        : allSeen
        ? t.discover.findNext.allDoneHint
        : t.discover.findNext.noPicksHint,
    icon: noMatches ? Symbols.hourglass_empty_rounded : Symbols.explore_rounded,
    onRefresh: _loading ? null : () => _load(fresh: true),
  );

  Widget _emptyAction(String label, VoidCallback? action) => Expanded(
    child: FocusableButton(
      onPressed: action,
      autoScroll: false,
      child: TextButton(
        onPressed: action,
        child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final activeId = context.watch<ActiveProfileProvider>().active?.id;
    final profileChanged = _ownerProfileId != null && activeId != _ownerProfileId;
    final current = profileChanged ? null : _current;
    final title = t.discover.findNext.title;
    final savedChoices = _state.saved.where((choice) => _catalogAllowed || choice.catalogSourceId == null).toList();
    final canUndo =
        _state.history.isNotEmpty && (_catalogAllowed || _state.history.last.choice.catalogSourceId == null);
    final matching = _choices.where(_matchesFilters).toList(growable: false);
    final noMatches = _choices.isNotEmpty && matching.isEmpty;
    final allSeen = matching.isNotEmpty && matching.every((choice) => _state.seen.contains(choice.id));
    final theme = Theme.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: theme.colorScheme.surface),
        if (current != null && !_loading && !profileChanged)
          Positioned.fill(
            child: ExcludeSemantics(child: IgnorePointer(child: _artwork(current, backdrop: true))),
          ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.surface.withValues(alpha: 0.90),
                    theme.colorScheme.surface.withValues(alpha: 0.74),
                    theme.colorScheme.surface.withValues(alpha: 0.94),
                  ],
                ),
              ),
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: Text(
              MediaQuery.sizeOf(context).height < 500 ? isolateDisplayText(current?.title ?? title) : title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              IconButton(
                tooltip: t.discover.findNext.filters,
                onPressed: profileChanged || _loading ? null : _showFilters,
                icon: Badge(
                  isLabelVisible: _family != _DiscoveryFamily.anything || _maxMinutes != null,
                  child: const AppIcon(Symbols.tune_rounded),
                ),
              ),
              IconButton(
                tooltip: t.discover.findNext.savedCount(count: formatCount(savedChoices.length)),
                onPressed: profileChanged || _loading ? null : _openSaved,
                icon: Badge(
                  isLabelVisible: savedChoices.isNotEmpty,
                  label: Text(formatCount(savedChoices.length)),
                  child: const AppIcon(Symbols.bookmarks_rounded),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            top: false,
            child: current != null && !_loading && !profileChanged
                ? _buildChoice(current, canUndo: canUndo)
                : Column(
                    children: [
                      Expanded(
                        child: _loading
                            ? const Center(child: CircularProgressIndicator())
                            : _buildEmpty(noMatches: noMatches, allSeen: allSeen),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _emptyAction(
                            t.discover.findNext.undo,
                            _loading || _committing || !canUndo || profileChanged ? null : _undo,
                          ),
                          _emptyAction(t.discover.findNext.howItWorks, () => showDiscoveryHelp(context)),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _SavedPicksScreen extends StatefulWidget {
  const _SavedPicksScreen({
    required this.profileId,
    required this.store,
    required this.includeCatalog,
    required this.onOpen,
    required this.onChanged,
  });
  final String profileId;
  final DiscoveryStore store;
  final bool includeCatalog;
  final ValueChanged<DiscoveryChoice> onOpen;
  final Future<void> Function() onChanged;
  @override
  State<_SavedPicksScreen> createState() => _SavedPicksScreenState();
}

class _SavedPicksScreenState extends State<_SavedPicksScreen> {
  DiscoveryState _state = const DiscoveryState();
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final state = await widget.store.load(widget.profileId);
    if (!mounted || context.read<ActiveProfileProvider>().active?.id != widget.profileId) return;
    setState(() {
      _state = state;
      _loading = false;
    });
  }

  Future<void> _remove(DiscoveryChoice choice) async {
    if (_busy || context.read<ActiveProfileProvider>().active?.id != widget.profileId) return;
    setState(() => _busy = true);
    try {
      final state = await widget.store.decide(widget.profileId, choice, DiscoveryDecisionAction.removeSaved);
      if (!mounted || context.read<ActiveProfileProvider>().active?.id != widget.profileId) return;
      setState(() => _state = state);
      await widget.onChanged();
    } catch (_) {
      if (mounted) showErrorSnackBar(context, t.discover.findNext.changeFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _undo() async {
    if (_busy || _state.history.isEmpty || context.read<ActiveProfileProvider>().active?.id != widget.profileId) {
      return;
    }
    setState(() => _busy = true);
    try {
      final (state, _) = await widget.store.undo(widget.profileId);
      if (!mounted || context.read<ActiveProfileProvider>().active?.id != widget.profileId) return;
      setState(() => _state = state);
      await widget.onChanged();
    } catch (_) {
      if (mounted) showErrorSnackBar(context, t.discover.findNext.changeFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileChanged = context.watch<ActiveProfileProvider>().active?.id != widget.profileId;
    final savedChoices = _state.saved
        .where((choice) => widget.includeCatalog || choice.catalogSourceId == null)
        .toList();
    final canUndo =
        _state.history.isNotEmpty && (widget.includeCatalog || _state.history.last.choice.catalogSourceId == null);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.discover.findNext.saved),
        actions: [
          TextButton.icon(
            onPressed: _busy || !canUndo || profileChanged ? null : _undo,
            icon: const AppIcon(Symbols.undo_rounded),
            label: Text(t.discover.findNext.undo),
          ),
        ],
      ),
      body: profileChanged
          ? const SizedBox.shrink()
          : _loading
          ? const Center(child: CircularProgressIndicator())
          : savedChoices.isEmpty
          ? Center(child: Text(t.discover.findNext.noPicks))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: savedChoices.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final choice = savedChoices[index];
                return FocusableListTile(
                  autofocus: index == 0,
                  leading: CircleAvatar(child: AppIcon(_savedIcon(choice), size: 22)),
                  title: Text(isolateDisplayText(choice.title), maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    [
                      _localizedChoiceType(choice),
                      isolateDisplayText(choice.subtitle),
                      choice.durationMs == null ? null : formatDurationTextual(choice.durationMs!),
                    ].whereType<String>().where((value) => value.isNotEmpty).join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: _busy || profileChanged ? null : () => widget.onOpen(choice),
                  trailing: IconButton(
                    tooltip: t.common.delete,
                    onPressed: _busy || profileChanged ? null : () => _remove(choice),
                    icon: const AppIcon(Symbols.bookmark_remove_rounded),
                  ),
                );
              },
            ),
    );
  }

  IconData _savedIcon(DiscoveryChoice choice) => switch (choice.type) {
    DiscoveryChoiceType.video || DiscoveryChoiceType.sourceVideo => Symbols.movie_rounded,
    DiscoveryChoiceType.music => Symbols.album_rounded,
    DiscoveryChoiceType.audiobook => Symbols.headphones_rounded,
    DiscoveryChoiceType.ebook => Symbols.menu_book_rounded,
    DiscoveryChoiceType.comic => Symbols.auto_stories_rounded,
    DiscoveryChoiceType.liveProgram => Symbols.live_tv_rounded,
  };
}
