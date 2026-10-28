import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../discovery/discovery_choice.dart';
import '../../discovery/discovery_preferences.dart';
import '../../discovery/discovery_reranker.dart';
import '../../focus/focusable_button.dart';
import '../../focus/focusable_text_field.dart';
import '../../discovery/discovery_store.dart';
import '../../i18n/presentation_formats.dart';
import '../../i18n/strings.g.dart';
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
import '../../screens/lending/public_libraries_screen.dart';
import '../../screens/sources/source_detail_screen.dart';
import '../../screens/sources/source_player_screen.dart';
import '../../screens/sources/publication_reader_screen.dart';
import '../../sources/source_controller.dart';
import '../../sources/source_models.dart';
import '../../lending/lending_service.dart';
import '../../sources/source_playback.dart';
import '../../services/settings_service.dart';
import '../../utils/formatters.dart';
import '../../utils/dialogs.dart';
import '../../utils/catalog_navigation_helper.dart';
import '../../utils/external_ids.dart';
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
import 'discovery_history_screen.dart';
import 'discovery_shortlist_vote_screen.dart';

enum _DiscoveryFamily { anything, watch, listen, read }

enum _FamiliarityFilter { any, newToMe, inProgress, revisit }

String _safeLiveReference(String value) => 'sha256:${sourceDigest(value)}';

SourceItemKind? _sourceKindForPortableChoice(DiscoveryChoice choice) => switch (choice.type) {
  DiscoveryChoiceType.ebook => SourceItemKind.ebook,
  DiscoveryChoiceType.audiobook => SourceItemKind.audiobook,
  DiscoveryChoiceType.comic => SourceItemKind.comic,
  DiscoveryChoiceType.music => SourceItemKind.music,
  DiscoveryChoiceType.sourceVideo => SourceItemKind.video,
  DiscoveryChoiceType.video || DiscoveryChoiceType.liveProgram => null,
};

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
  const FindNextScreen({
    super.key,
    this.libraryGlobalKey,
    this.includeCatalog = false,
    this.openSavedPicksOnStart = false,
  });

  /// Optional starting scope when entered from a library context.
  final String? libraryGlobalKey;

  /// Catalog rows are included only when entered through Explore, after its
  /// normal profile visibility and PIN gate has admitted the user.
  final bool includeCatalog;

  /// Opens profile-local Saved picks without fetching the discovery deck first.
  final bool openSavedPicksOnStart;

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
  bool _openedInitialSavedPicks = false;
  String? _feedback;
  int _artworkRevision = 0;
  DiscoveryChoice? _restoredChoice;
  _DiscoveryFamily _family = _DiscoveryFamily.anything;
  int? _maxMinutes;
  String? _genre;
  String? _sourceReason;
  String? _mood;
  _FamiliarityFilter _familiarity = _FamiliarityFilter.any;
  DiscoveryTastePreferences _taste = const DiscoveryTastePreferences();
  late DiscoveryTasteStore _tasteStore;
  late DiscoveryReranker _reranker;
  bool _aiEnabled = false;
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

  bool get _hasActiveFilters =>
      _family != _DiscoveryFamily.anything ||
      _maxMinutes != null ||
      _genre != null ||
      _sourceReason != null ||
      _mood != null ||
      _familiarity != _FamiliarityFilter.any ||
      _taste.hidden.isNotEmpty;

  DiscoveryChoice? get _current {
    final restored = _restoredChoice;
    if (restored != null && !_taste.hides(restored.id) && _matchesFilters(restored)) return restored;
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
      _tasteStore = DiscoveryTasteStore(sources.repository);
      _reranker = DiscoveryReranker(sources.repository);
      final state = fresh ? await _store.startFreshSession(profileId) : await _store.load(profileId);
      if (!_sessionCurrent(profileId, sourceGeneration, request)) return;
      final taste = await _tasteStore.load(profileId);
      if (!_sessionCurrent(profileId, sourceGeneration, request)) return;
      _taste = taste;
      try {
        final config = await _reranker.load(profileId);
        _aiEnabled = config.enabled && config.isConfigured;
      } catch (_) {
        // Optional AI settings must never make the ordinary deck unavailable.
        _aiEnabled = false;
      }
      if (!_sessionCurrent(profileId, sourceGeneration, request)) return;

      final openSavedPicks = widget.openSavedPicksOnStart && !_openedInitialSavedPicks;
      if (openSavedPicks) {
        _openedInitialSavedPicks = true;
        setState(() {
          _state = state;
          _choices = const [];
          _restoredChoice = null;
          _position = 0;
          _loading = false;
        });
        await _openSaved();
        if (mounted && _restoredChoice == null) Navigator.of(context).pop();
        return;
      }

      final candidates = await _fetchCandidates(profileId, sourceGeneration, request);
      if (!_sessionCurrent(profileId, sourceGeneration, request)) return;
      final ranked = _applyTastePriority(
        balanceDiscoveryChoices(candidates, seed: DateTime.now().millisecondsSinceEpoch),
      );
      final nextPosition = ranked.indexWhere((choice) => !state.seen.contains(choice.id) && _matchesFilters(choice));
      setState(() {
        _state = state;
        _choices = ranked;
        _restoredChoice = null;
        _position = nextPosition < 0 ? ranked.length : nextPosition;
        _loading = false;
      });
      if (_aiEnabled && nextPosition >= 0 && nextPosition < ranked.length) {
        unawaited(_rerankTail(profileId, sourceGeneration, request, nextPosition, ranked));
      }
    } catch (_) {
      if (_sessionCurrent(profileId, sources.generation, request)) {
        setState(() {
          _loading = false;
          _choices = const [];
        });
      }
    }
  }

  List<DiscoveryChoice> _applyTastePriority(List<DiscoveryChoice> baseline) {
    if (_taste.preferredGenres.isEmpty && _taste.avoidedGenres.isEmpty) return baseline;
    final preferred = _taste.preferredGenres.map((value) => value.toLowerCase()).toSet();
    final avoided = _taste.avoidedGenres.map((value) => value.toLowerCase()).toSet();
    final ranked = <DiscoveryChoice>[];
    for (var start = 0; start < baseline.length; start += 12) {
      final window = baseline.skip(start).take(12).toList();
      final indexed = [for (var index = 0; index < window.length; index++) (index: index, choice: window[index])];
      int score(DiscoveryChoice choice) {
        final genres = _genresFor(choice).map((value) => value.toLowerCase()).toSet();
        if (genres.any(preferred.contains)) return 1;
        if (genres.any(avoided.contains)) return -1;
        return 0;
      }

      indexed.sort((left, right) {
        final byTaste = score(right.choice).compareTo(score(left.choice));
        return byTaste != 0 ? byTaste : left.index.compareTo(right.index);
      });
      ranked.addAll(indexed.map((item) => item.choice));
    }
    return ranked;
  }

  Future<void> _rerankTail(
    String profileId,
    int sourceGeneration,
    int request,
    int currentPosition,
    List<DiscoveryChoice> baseline,
  ) async {
    final fixedChoiceId = baseline[currentPosition].id;
    final mediaFamily = _family.name;
    final maxMinutes = _maxMinutes;
    final genre = _genre;
    final mood = _mood;
    final familiarity = _familiarity.name;
    final tail = baseline
        .skip(currentPosition + 1)
        .where((choice) => !_state.seen.contains(choice.id) && _matchesFilters(choice))
        .take(DiscoveryReranker.maxCandidates)
        .toList(growable: false);
    if (tail.length < 2) return;
    final reranked = await _reranker.reorder(
      profileId: profileId,
      baseline: tail,
      genresFor: _genresFor,
      mediaFamily: mediaFamily,
      maxMinutes: maxMinutes,
      genre: genre,
      mood: mood,
      familiarity: familiarity,
      stillCurrent: () =>
          _aiEnabled &&
          _sessionCurrent(profileId, sourceGeneration, request) &&
          _current?.id == fixedChoiceId &&
          _family.name == mediaFamily &&
          _maxMinutes == maxMinutes &&
          _genre == genre &&
          _mood == mood &&
          _familiarity.name == familiarity,
    );
    if (!_sessionCurrent(profileId, sourceGeneration, request) || _current?.id != fixedChoiceId) return;
    if (reranked == null || reranked.length != tail.length) {
      if (_aiEnabled) setState(() => _feedback = t.discover.findNext.aiError);
      return;
    }
    final eligible = tail.map((choice) => choice.id).toSet();
    var replacement = 0;
    final next = [...baseline];
    for (var index = currentPosition + 1; index < next.length && replacement < reranked.length; index++) {
      if (eligible.contains(next[index].id)) next[index] = reranked[replacement++];
    }
    if (replacement != reranked.length) return;
    setState(() => _choices = next);
  }

  Future<void> _showTasteControls() async {
    final profileId = _ownerProfileId;
    if (profileId == null || !_sessionCurrent(profileId, _sourceGeneration, _loadGeneration)) return;
    final preferred = {..._taste.preferredGenres};
    final avoided = {..._taste.avoidedGenres};
    final hiddenIds = _taste.hidden.map((pick) => pick.id).toSet();
    final genres = <String>{..._choices.expand(_genresFor), ...preferred, ...avoided}.toList()
      ..sort((left, right) => left.toLowerCase().compareTo(right.toLowerCase()));
    final shownGenres = genres.take(64).toList();
    for (final selected in [...preferred, ...avoided]) {
      if (shownGenres.length >= 96) break;
      if (!shownGenres.any((item) => item.toLowerCase() == selected.toLowerCase())) shownGenres.add(selected);
    }
    final result =
        await OverlaySheetController.showAdaptive<
          ({Set<String> preferred, Set<String> avoided, Set<String> hiddenIds, bool reset})
        >(
          context,
          showDragHandle: true,
          builder: (sheetContext) => StatefulBuilder(
            builder: (context, setSheetState) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.76),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.discover.findNext.tasteControls, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text(t.discover.findNext.tasteControlsHelp, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 16),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.discover.findNext.preferMore, style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final genre in shownGenres)
                                  FocusableButton(
                                    onPressed: () => setSheetState(() {
                                      if (!preferred.add(genre)) {
                                        preferred.remove(genre);
                                      } else {
                                        avoided.remove(genre);
                                      }
                                    }),
                                    autoScroll: false,
                                    child: FilterChip(
                                      label: Text(isolateDisplayText(genre)),
                                      selected: preferred.contains(genre),
                                      onSelected: (selected) => setSheetState(() {
                                        if (selected) {
                                          preferred.add(genre);
                                          avoided.remove(genre);
                                        } else {
                                          preferred.remove(genre);
                                        }
                                      }),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(t.discover.findNext.showLess, style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final genre in shownGenres)
                                  FocusableButton(
                                    onPressed: () => setSheetState(() {
                                      if (!avoided.add(genre)) {
                                        avoided.remove(genre);
                                      } else {
                                        preferred.remove(genre);
                                      }
                                    }),
                                    autoScroll: false,
                                    child: FilterChip(
                                      label: Text(isolateDisplayText(genre)),
                                      selected: avoided.contains(genre),
                                      onSelected: (selected) => setSheetState(() {
                                        if (selected) {
                                          avoided.add(genre);
                                          preferred.remove(genre);
                                        } else {
                                          avoided.remove(genre);
                                        }
                                      }),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    t.discover.findNext.hiddenPicks,
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                ),
                                if (_taste.hidden.isNotEmpty)
                                  TextButton(
                                    onPressed: () => setSheetState(() => hiddenIds.clear()),
                                    child: Text(t.common.clear),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            if (_taste.hidden.isEmpty)
                              Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  t.discover.findNext.noHiddenPicks,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              )
                            else
                              for (final pick in _taste.hidden)
                                FocusableListTile(
                                  title: Text(
                                    isolateDisplayText(pick.title),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(pick.type),
                                  trailing: hiddenIds.contains(pick.id)
                                      ? const AppIcon(Symbols.visibility_off_rounded)
                                      : const AppIcon(Symbols.check_rounded),
                                  onTap: () => setSheetState(() {
                                    if (!hiddenIds.remove(pick.id)) hiddenIds.add(pick.id);
                                  }),
                                ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(
                            sheetContext,
                          ).pop((preferred: <String>{}, avoided: <String>{}, hiddenIds: <String>{}, reset: true)),
                          child: Text(t.discover.findNext.resetTaste),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(sheetContext).pop((
                            preferred: Set<String>.of(preferred),
                            avoided: Set<String>.of(avoided),
                            hiddenIds: Set<String>.of(hiddenIds),
                            reset: false,
                          )),
                          child: Text(t.discover.findNext.apply),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
    if (!mounted || result == null || !_sessionCurrent(profileId, _sourceGeneration, _loadGeneration)) return;
    try {
      final previouslyHidden = _taste.hidden.map((pick) => pick.id).toSet();
      if (result.reset) {
        if (!await showConfirmDialog(
          context,
          title: t.discover.findNext.resetTaste,
          message: t.discover.findNext.resetTasteConfirm,
          confirmText: t.common.reset,
        )) {
          return;
        }
        _taste = await _tasteStore.resetTaste(profileId);
      } else {
        _taste = await _tasteStore.save(
          profileId: profileId,
          preferred: result.preferred,
          avoided: result.avoided,
          hiddenIds: result.hiddenIds,
        );
      }
      if (!_sessionCurrent(profileId, _sourceGeneration, _loadGeneration)) return;
      final restoredIds = previouslyHidden.difference(_taste.hidden.map((pick) => pick.id).toSet());
      final nextChoices = _applyTastePriority(_choices);
      setState(() {
        _choices = nextChoices;
        _restoredChoice = null;
        final restoredPosition = nextChoices.indexWhere(
          (choice) => restoredIds.contains(choice.id) && !_state.seen.contains(choice.id) && _matchesFilters(choice),
        );
        final firstEligible = nextChoices.indexWhere(
          (choice) => !_state.seen.contains(choice.id) && _matchesFilters(choice),
        );
        _position = restoredPosition >= 0 ? restoredPosition : firstEligible;
        if (_position < 0) _position = _choices.length;
      });
    } catch (_) {
      if (mounted) showErrorSnackBar(context, t.discover.findNext.changeFailed);
    }
  }

  Future<void> _showAiSettings() async {
    final profileId = _ownerProfileId;
    if (profileId == null || !_sessionCurrent(profileId, _sourceGeneration, _loadGeneration)) return;
    final generation = _sourceGeneration;
    late final DiscoveryAiConfig existing;
    try {
      existing = await _reranker.load(profileId);
    } catch (_) {
      if (mounted) showErrorSnackBar(context, t.discover.findNext.changeFailed);
      return;
    }
    if (!mounted || !_sessionCurrent(profileId, generation, _loadGeneration)) return;
    final endpoint = TextEditingController(text: existing.endpoint);
    final model = TextEditingController(text: existing.model);
    final apiKey = TextEditingController();
    var enabled = existing.enabled;
    var clearKey = false;
    try {
      final save = await OverlaySheetController.showAdaptive<bool>(
        context,
        showDragHandle: true,
        builder: (sheetContext) => StatefulBuilder(
          builder: (context, setSheetState) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(t.discover.findNext.aiRanking, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(t.discover.findNext.aiRankingHelp, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 12),
                  Text(t.discover.findNext.aiConsentBody, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 16),
                  FocusableTextField(
                    controller: endpoint,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(labelText: t.discover.findNext.aiEndpoint),
                  ),
                  const SizedBox(height: 10),
                  FocusableTextField(
                    controller: model,
                    decoration: InputDecoration(labelText: t.discover.findNext.aiModel),
                  ),
                  const SizedBox(height: 10),
                  FocusableTextField(
                    controller: apiKey,
                    obscureText: true,
                    onChanged: (_) => setSheetState(() => clearKey = false),
                    decoration: InputDecoration(
                      labelText: t.discover.findNext.aiApiKey,
                      helperText: existing.apiKey.isNotEmpty ? t.discover.findNext.aiSavedKey : null,
                    ),
                  ),
                  if (existing.apiKey.isNotEmpty)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(t.discover.findNext.aiClearKey),
                      value: clearKey,
                      onChanged: (value) => setSheetState(() => clearKey = value ?? false),
                    ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(t.discover.findNext.aiEnabled),
                    value: enabled,
                    onChanged: (value) => setSheetState(() => enabled = value),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: () => Navigator.of(sheetContext).pop(true), child: Text(t.fileSources.save)),
                ],
              ),
            ),
          ),
        ),
      );
      if (save != true || !mounted || !_sessionCurrent(profileId, generation, _loadGeneration)) return;
      final next = DiscoveryAiConfig(
        endpoint: endpoint.text.trim(),
        model: model.text.trim(),
        apiKey: apiKey.text.trim().isNotEmpty
            ? apiKey.text.trim()
            : clearKey
            ? ''
            : existing.apiKey,
        enabled: enabled,
      );
      if (!next.isConfigured) {
        if (!enabled && endpoint.text.trim().isEmpty && model.text.trim().isEmpty) {
          await _reranker.clear(profileId);
          if (!_sessionCurrent(profileId, generation, _loadGeneration)) return;
          _aiEnabled = false;
          if (mounted) showSuccessSnackBar(context, t.discover.findNext.aiSaved);
          return;
        }
        showErrorSnackBar(context, t.discover.findNext.aiInvalidConfig);
        return;
      }
      if (enabled &&
          !await showConfirmDialog(
            context,
            title: t.discover.findNext.aiConsentTitle,
            message: t.discover.findNext.aiConsentBody,
            confirmText: t.discover.findNext.aiEnabled,
          )) {
        return;
      }
      await _reranker.save(profileId, next);
      if (!mounted || !_sessionCurrent(profileId, generation, _loadGeneration)) return;
      setState(() => _aiEnabled = next.enabled);
      showSuccessSnackBar(context, t.discover.findNext.aiSaved);
      if (_aiEnabled && _current != null) {
        unawaited(_rerankTail(profileId, generation, _loadGeneration, _position, _choices));
      }
    } catch (_) {
      if (mounted) showErrorSnackBar(context, t.discover.findNext.changeFailed);
    } finally {
      endpoint.dispose();
      model.dispose();
      apiKey.dispose();
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
      portableIds: sanitizeDiscoveryPortableIds(item.ids.toJson().map((key, value) => MapEntry(key, '$value'))),
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
        SourceItemKind.audiobook ||
        SourceItemKind.music ||
        SourceItemKind.video => entry.files.where((file) => !file.sampleOnly).toList(growable: false),
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
    final totalDuration = _sumKnownDurations(
      entry.files.where((file) => !file.sampleOnly).map((file) => file.durationMs),
    );
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
      portableIds: sanitizeDiscoveryPortableIds(entry.identifiers),
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

  bool _matchesFamily(DiscoveryChoice choice, _DiscoveryFamily family) => switch (family) {
    _DiscoveryFamily.anything => true,
    _DiscoveryFamily.watch =>
      choice.type == DiscoveryChoiceType.video ||
          choice.type == DiscoveryChoiceType.sourceVideo ||
          choice.type == DiscoveryChoiceType.liveProgram,
    _DiscoveryFamily.listen => choice.type == DiscoveryChoiceType.music || choice.type == DiscoveryChoiceType.audiobook,
    _DiscoveryFamily.read => choice.type == DiscoveryChoiceType.ebook || choice.type == DiscoveryChoiceType.comic,
  };

  List<String> _genresFor(DiscoveryChoice choice) {
    final genres = <String>{
      ...?choice.mediaItem?.genres,
      ...?choice.catalogItem?.genres,
      ...?choice.sourceEntry?.genres,
    };
    return genres.where((value) => value.trim().isNotEmpty).map((value) => value.trim()).toList(growable: false);
  }

  List<String> _moodsFor(DiscoveryChoice choice) => (choice.mediaItem?.moods ?? const <String>[])
      .where((value) => value.trim().isNotEmpty)
      .map((value) => value.trim())
      .toList(growable: false);

  bool _matchesFamiliarity(DiscoveryChoice choice, _FamiliarityFilter filter) {
    if (filter == _FamiliarityFilter.any) return true;
    final item = choice.mediaItem;
    if (item == null) return false;
    if (item.viewCount == null && item.viewOffsetMs == null && item.viewedLeafCount == null) return false;
    final leafCount = item.leafCount ?? 0;
    final viewedLeaves = item.viewedLeafCount ?? 0;
    final viewed = (item.viewCount ?? 0) > 0 || (leafCount > 0 && viewedLeaves >= leafCount);
    final started = (item.viewOffsetMs ?? 0) > 0 || viewedLeaves > 0;
    return switch (filter) {
      _FamiliarityFilter.any => true,
      _FamiliarityFilter.newToMe => !viewed && !started,
      _FamiliarityFilter.inProgress => !viewed && started,
      _FamiliarityFilter.revisit => viewed,
    };
  }

  bool _matchesFilters(DiscoveryChoice choice) {
    if (_taste.hides(choice.id)) return false;
    if (!_matchesFamily(choice, _family)) return false;
    if (_sourceReason != null && choice.reason != _sourceReason) return false;
    if (!_matchesFamiliarity(choice, _familiarity)) return false;
    final mood = _mood;
    if (mood != null && !_moodsFor(choice).any((value) => value.toLowerCase() == mood.toLowerCase())) return false;
    final genre = _genre;
    if (genre != null && !_genresFor(choice).any((value) => value.toLowerCase() == genre.toLowerCase())) {
      return false;
    }
    final maxMinutes = _maxMinutes;
    if (maxMinutes == null) return true;
    final duration = choice.durationMs;
    return duration != null && duration <= Duration(minutes: maxMinutes).inMilliseconds;
  }

  Future<({bool applied, String? value})?> _pickFilterValue({
    required String title,
    required List<String> options,
    required String? selected,
  }) async {
    final controller = TextEditingController();
    var query = '';
    try {
      return await OverlaySheetController.pushAdaptive<({bool applied, String? value})>(
        context,
        showDragHandle: true,
        builder: (sheetContext) => StatefulBuilder(
          builder: (context, setSheetState) {
            final normalizedQuery = query.trim().toLowerCase();
            final filtered = normalizedQuery.isEmpty
                ? options
                : options.where((value) => value.toLowerCase().contains(normalizedQuery)).toList(growable: false);
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.72),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        prefixIcon: const AppIcon(Symbols.search_rounded),
                        hintText: t.common.search,
                      ),
                      onChanged: (value) => setSheetState(() => query = value),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length + (filtered.isEmpty ? 2 : 1),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return FocusableListTile(
                              title: Text(t.discover.findNext.filterAnything),
                              trailing: selected == null ? const AppIcon(Symbols.check_rounded) : null,
                              onTap: () =>
                                  OverlaySheetController.popAdaptive(sheetContext, (applied: true, value: null)),
                            );
                          }
                          if (filtered.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(20),
                              child: Center(child: Text(t.messages.noResultsFound)),
                            );
                          }
                          final value = filtered[index - 1];
                          final isSelected = value.toLowerCase() == selected?.toLowerCase();
                          return FocusableListTile(
                            title: Text(isolateDisplayText(value), maxLines: 2, overflow: TextOverflow.ellipsis),
                            trailing: isSelected ? const AppIcon(Symbols.check_rounded) : null,
                            onTap: () =>
                                OverlaySheetController.popAdaptive(sheetContext, (applied: true, value: value)),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _showFilters() async {
    var family = _family;
    var maxMinutes = _maxMinutes;
    var genre = _genre;
    var sourceReason = _sourceReason;
    var mood = _mood;
    var familiarity = _familiarity;
    final availableGenres = _choices.expand(_genresFor).toSet().toList()
      ..sort((left, right) => left.toLowerCase().compareTo(right.toLowerCase()));
    final shownGenres = availableGenres.take(48).toList();
    final selectedGenre = genre;
    if (selectedGenre != null && !shownGenres.any((value) => value.toLowerCase() == selectedGenre.toLowerCase())) {
      if (shownGenres.length == 48) shownGenres.removeLast();
      shownGenres.insert(0, selectedGenre);
    }
    final availableSources = _choices.map((choice) => choice.reason).where((value) => value.isNotEmpty).toSet().toList()
      ..sort((left, right) => left.toLowerCase().compareTo(right.toLowerCase()));
    final availableMoods = _choices.expand(_moodsFor).toSet().toList()
      ..sort((left, right) => left.toLowerCase().compareTo(right.toLowerCase()));
    final shownMoods = availableMoods.take(48).toList();
    final selectedMood = mood;
    if (selectedMood != null && !shownMoods.any((value) => value.toLowerCase() == selectedMood.toLowerCase())) {
      if (shownMoods.length == 48) shownMoods.removeLast();
      shownMoods.insert(0, selectedMood);
    }
    final selectedSource = sourceReason;
    final shownSources = availableSources.take(48).toList();
    if (selectedSource != null && !shownSources.contains(selectedSource)) {
      if (shownSources.length == 48) shownSources.removeLast();
      shownSources.insert(0, selectedSource);
    }
    final result =
        await OverlaySheetController.showAdaptive<
          ({
            _DiscoveryFamily family,
            int? minutes,
            String? genre,
            String? sourceReason,
            String? mood,
            _FamiliarityFilter familiarity,
            bool openTaste,
            bool openAi,
          })
        >(
          context,
          showDragHandle: true,
          builder: (sheetContext) => StatefulBuilder(
            builder: (context, setSheetState) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.68),
                child: SingleChildScrollView(
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
                            FocusableButton(
                              onPressed: () => setSheetState(() => family = item),
                              autoScroll: false,
                              child: ChoiceChip(
                                label: Text(_familyLabel(item)),
                                selected: item == family,
                                onSelected: (_) => setSheetState(() => family = item),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(t.discover.findNext.mood, style: Theme.of(context).textTheme.titleSmall),
                          ),
                          if (availableMoods.length > shownMoods.length)
                            TextButton(
                              onPressed: () async {
                                final selection = await _pickFilterValue(
                                  title: t.discover.findNext.mood,
                                  options: availableMoods,
                                  selected: mood,
                                );
                                if (selection != null && selection.applied) {
                                  final value = selection.value;
                                  if (value != null &&
                                      !shownMoods.any((item) => item.toLowerCase() == value.toLowerCase())) {
                                    if (shownMoods.length == 48) shownMoods.removeLast();
                                    shownMoods.insert(0, value);
                                  }
                                  setSheetState(() => mood = value);
                                }
                              },
                              child: Text(t.common.viewAll),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (shownMoods.isEmpty)
                        Text(t.discover.findNext.moodMetadataHint, style: Theme.of(context).textTheme.bodySmall)
                      else
                        SizedBox(
                          height: 48,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              for (final item in <String?>[null, ...shownMoods])
                                FocusableButton(
                                  onPressed: () => setSheetState(() => mood = item),
                                  autoScroll: false,
                                  child: ChoiceChip(
                                    label: Text(
                                      item == null ? t.discover.findNext.filterAnything : isolateDisplayText(item),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    selected: item == mood,
                                    onSelected: (_) => setSheetState(() => mood = item),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(t.discover.findNext.familiarity, style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final item in _FamiliarityFilter.values)
                            FocusableButton(
                              onPressed: () => setSheetState(() => familiarity = item),
                              autoScroll: false,
                              child: ChoiceChip(
                                label: Text(switch (item) {
                                  _FamiliarityFilter.any => t.discover.findNext.familiarityAny,
                                  _FamiliarityFilter.newToMe => t.discover.findNext.newToMe,
                                  _FamiliarityFilter.inProgress => t.discover.findNext.inProgress,
                                  _FamiliarityFilter.revisit => t.discover.findNext.revisit,
                                }),
                                selected: item == familiarity,
                                onSelected: (_) => setSheetState(() => familiarity = item),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: Text(t.fileSources.source, style: Theme.of(context).textTheme.titleSmall)),
                          if (availableSources.length > shownSources.length)
                            TextButton(
                              onPressed: () async {
                                final selection = await _pickFilterValue(
                                  title: t.fileSources.source,
                                  options: availableSources,
                                  selected: sourceReason,
                                );
                                if (selection != null && selection.applied) {
                                  final value = selection.value;
                                  if (value != null && !shownSources.contains(value)) {
                                    if (shownSources.length == 48) shownSources.removeLast();
                                    shownSources.insert(0, value);
                                  }
                                  setSheetState(() => sourceReason = value);
                                }
                              },
                              child: Text(t.common.viewAll),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 48,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            for (final item in <String?>[null, ...shownSources])
                              FocusableButton(
                                onPressed: () => setSheetState(() => sourceReason = item),
                                autoScroll: false,
                                child: ChoiceChip(
                                  label: ConstrainedBox(
                                    constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.55),
                                    child: Text(
                                      item == null ? t.discover.findNext.filterAnything : isolateDisplayText(item),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  selected: item == sourceReason,
                                  onSelected: (_) => setSheetState(() => sourceReason = item),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              t.libraries.filterCategories.genre,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          if (availableGenres.length > shownGenres.length)
                            TextButton(
                              onPressed: () async {
                                final selection = await _pickFilterValue(
                                  title: t.libraries.filterCategories.genre,
                                  options: availableGenres,
                                  selected: genre,
                                );
                                if (selection != null && selection.applied) {
                                  final value = selection.value;
                                  if (value != null &&
                                      !shownGenres.any((item) => item.toLowerCase() == value.toLowerCase())) {
                                    if (shownGenres.length == 48) shownGenres.removeLast();
                                    shownGenres.insert(0, value);
                                  }
                                  setSheetState(() => genre = value);
                                }
                              },
                              child: Text(t.common.viewAll),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 48,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            for (final item in <String?>[null, ...shownGenres])
                              FocusableButton(
                                onPressed: () => setSheetState(() => genre = item),
                                autoScroll: false,
                                child: ChoiceChip(
                                  label: ConstrainedBox(
                                    constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.55),
                                    child: Text(
                                      item == null ? t.discover.findNext.filterAnything : isolateDisplayText(item),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  selected: item == genre,
                                  onSelected: (_) => setSheetState(() => genre = item),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(t.discover.findNext.timeAvailable, style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final item in <int?>[null, 20, 45, 90])
                            FocusableButton(
                              onPressed: () => setSheetState(() => maxMinutes = item),
                              autoScroll: false,
                              child: ChoiceChip(
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
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => Navigator.of(sheetContext).pop((
                              family: family,
                              minutes: maxMinutes,
                              genre: genre,
                              sourceReason: sourceReason,
                              mood: mood,
                              familiarity: familiarity,
                              openTaste: true,
                              openAi: false,
                            )),
                            icon: const AppIcon(Symbols.tune_rounded),
                            label: Text(t.discover.findNext.tasteControls),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => Navigator.of(sheetContext).pop((
                              family: family,
                              minutes: maxMinutes,
                              genre: genre,
                              sourceReason: sourceReason,
                              mood: mood,
                              familiarity: familiarity,
                              openTaste: false,
                              openAi: true,
                            )),
                            icon: const AppIcon(Symbols.auto_awesome_rounded),
                            label: Text(t.discover.findNext.aiRanking),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: FocusableButton(
                          onPressed: () => Navigator.of(sheetContext).pop((
                            family: family,
                            minutes: maxMinutes,
                            genre: genre,
                            sourceReason: sourceReason,
                            mood: mood,
                            familiarity: familiarity,
                            openTaste: false,
                            openAi: false,
                          )),
                          useBackgroundFocus: true,
                          child: FilledButton(
                            onPressed: () => Navigator.of(sheetContext).pop((
                              family: family,
                              minutes: maxMinutes,
                              genre: genre,
                              sourceReason: sourceReason,
                              mood: mood,
                              familiarity: familiarity,
                              openTaste: false,
                              openAi: false,
                            )),
                            child: Text(t.discover.findNext.apply),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
    if (!mounted || result == null) return;
    if (result.openTaste) {
      await _showTasteControls();
      return;
    }
    if (result.openAi) {
      await _showAiSettings();
      return;
    }
    setState(() {
      _restoredChoice = null;
      _feedback = null;
      _family = result.family;
      _maxMinutes = result.minutes;
      _genre = result.genre;
      _sourceReason = result.sourceReason;
      _mood = result.mood;
      _familiarity = result.familiarity;
      _position = _choices.indexWhere((choice) => !_state.seen.contains(choice.id) && _matchesFilters(choice));
      if (_position < 0) _position = _choices.length;
    });
  }

  void _clearFilters() {
    setState(() {
      _family = _DiscoveryFamily.anything;
      _maxMinutes = null;
      _genre = null;
      _sourceReason = null;
      _mood = null;
      _familiarity = _FamiliarityFilter.any;
      if (_taste.hidden.isNotEmpty && _ownerProfileId != null) {
        unawaited(
          _tasteStore.clearHidden(_ownerProfileId!).then((next) {
            if (mounted && context.read<ActiveProfileProvider>().active?.id == _ownerProfileId) {
              setState(() {
                _taste = next;
                _position = _choices.indexWhere(
                  (choice) => !_state.seen.contains(choice.id) && _matchesFilters(choice),
                );
                if (_position < 0) _position = _choices.length;
              });
            }
          }),
        );
      }
      _restoredChoice = null;
      _feedback = null;
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
    var choice = _current!;
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
      if (action == DiscoveryDecisionAction.save) {
        choice = await _withPortableIdentifiers(choice, profileId, sources);
        if (!sources.current(_sourceGeneration) || sources.profileId != profileId) return;
      }
      final state = await _store.decide(profileId, choice, action);
      if (!mounted ||
          context.read<ActiveProfileProvider>().active?.id != profileId ||
          !sources.current(_sourceGeneration)) {
        return;
      }
      setState(() {
        _state = state;
        _restoredChoice = null;
        final index = _choices.indexWhere((item) => item.id == choice.id);
        if (index >= _position) _position = index + 1;
        _feedback = action == DiscoveryDecisionAction.save
            ? t.discover.findNext.savedFeedback
            : t.discover.findNext.skippedFeedback;
      });
      if (action == DiscoveryDecisionAction.save) sources.scheduleSync();
      if (widget.openSavedPicksOnStart && _choices.isEmpty) unawaited(_load());
    } catch (_) {
      if (mounted) showErrorSnackBar(context, t.discover.findNext.changeFailed);
    } finally {
      if (mounted) setState(() => _committing = false);
    }
  }

  Future<DiscoveryChoice> _withPortableIdentifiers(
    DiscoveryChoice choice,
    String profileId,
    SourceController sources,
  ) async {
    if (choice.portableIds.isNotEmpty) return choice;
    if (choice.catalogItem case final item?) {
      return choice.withPortableIds(item.ids.toJson().map((key, value) => MapEntry(key, '$value')));
    }
    if (choice.sourceEntry case final entry?) {
      return choice.withPortableIds(entry.identifiers);
    }
    final serverId = choice.serverId;
    final mediaId = choice.mediaId;
    final kind = choice.mediaKind;
    if (serverId == null || mediaId == null || (kind != MediaKind.movie && kind != MediaKind.show)) return choice;
    final multiServer = context.read<MultiServerProvider>();
    final client = multiServer.getClientForServer(ServerId(serverId));
    if (client == null) return choice;
    final authentication = client.authenticationSessionId;
    try {
      final ids = await client.fetchExternalIds(mediaId).timeout(const Duration(seconds: 8));
      if (!mounted ||
          context.read<ActiveProfileProvider>().active?.id != profileId ||
          !sources.current(_sourceGeneration) ||
          !multiServer.serverIds.contains(serverId) ||
          !identical(client.authenticationSessionId, authentication)) {
        return choice;
      }
      return choice.withPortableIds(ids.toJson().map((key, value) => MapEntry(key, '$value')));
    } catch (_) {
      return choice;
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
        if (lastDecision?.savedChanged == true) sources.scheduleSync();
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
          syncSavedPicks: context.read<SourceController>().syncConfig?.includeDiscovery == true,
          onOpen: _openChoice,
          onChooseForMe: _chooseSavedPick,
          onChooseTogether: _chooseTogether,
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

  void _chooseSavedPick(List<DiscoveryChoice> saved) {
    final profileId = _ownerProfileId;
    final sources = context.read<SourceController>();
    if (!mounted ||
        profileId == null ||
        context.read<ActiveProfileProvider>().active?.id != profileId ||
        sources.profileId != profileId ||
        sources.blocked ||
        !sources.current(_sourceGeneration)) {
      return;
    }
    final liveById = {for (final choice in _choices) choice.id: choice};
    final eligible = saved
        .map((snapshot) => liveById[snapshot.id] ?? snapshot)
        .where(_matchesFilters)
        .toList(growable: false);
    if (eligible.isEmpty) {
      showErrorSnackBar(context, t.discover.findNext.noMatches);
      return;
    }
    final choice = eligible[math.Random().nextInt(eligible.length)];
    setState(() {
      _restoredChoice = choice;
      _feedback = null;
    });
    Navigator.of(context).pop();
  }

  Future<void> _chooseTogether(DiscoveryChoice choice) async {
    final profileId = _ownerProfileId;
    final sources = context.read<SourceController>();
    if (!mounted ||
        profileId == null ||
        context.read<ActiveProfileProvider>().active?.id != profileId ||
        !sources.current(_sourceGeneration)) {
      return;
    }
    try {
      final state = await _store.restoreToDeck(profileId, choice.id);
      final taste = _taste.hides(choice.id) ? await _tasteStore.unhide(profileId, choice.id) : _taste;
      if (!mounted ||
          context.read<ActiveProfileProvider>().active?.id != profileId ||
          !sources.current(_sourceGeneration)) {
        return;
      }
      final existingIndex = _choices.indexWhere((item) => item.id == choice.id);
      final restoreAt = existingIndex >= 0 ? existingIndex : _position.clamp(0, _choices.length).toInt();
      final nextChoices = existingIndex >= 0
          ? [..._choices]
          : [..._choices.take(restoreAt), choice, ..._choices.skip(restoreAt)];
      setState(() {
        _state = state;
        _choices = nextChoices;
        _taste = taste;
        _family = _DiscoveryFamily.anything;
        _maxMinutes = null;
        _genre = null;
        _sourceReason = null;
        _mood = null;
        _familiarity = _FamiliarityFilter.any;
        _position = restoreAt;
        _restoredChoice = choice;
        _feedback = null;
      });
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) showErrorSnackBar(context, t.discover.findNext.changeFailed);
    }
  }

  Future<void> _openHistory() async {
    final profileId = _ownerProfileId;
    if (profileId == null || !mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => DiscoveryHistoryScreen(
          profileId: profileId,
          store: _store,
          includeCatalog: _catalogAllowed,
          onDetails: (choice) => _openChoice(choice, detailsOnly: true),
          onRestoreToDeck: (choice) => _restoreHistoryChoice(choice, profileId),
        ),
      ),
    );
    if (mounted && context.read<ActiveProfileProvider>().active?.id == profileId) {
      _state = await _store.load(profileId);
      setState(() {});
    }
  }

  Future<void> _restoreHistoryChoice(DiscoveryChoice choice, String profileId) async {
    final sources = context.read<SourceController>();
    if (!mounted ||
        context.read<ActiveProfileProvider>().active?.id != profileId ||
        _ownerProfileId != profileId ||
        !sources.current(_sourceGeneration)) {
      return;
    }
    if (!_matchesFilters(choice)) {
      showErrorSnackBar(context, t.discover.findNext.noMatches);
      return;
    }
    try {
      final state = await _store.restoreToDeck(profileId, choice.id);
      if (!mounted ||
          context.read<ActiveProfileProvider>().active?.id != profileId ||
          _ownerProfileId != profileId ||
          !sources.current(_sourceGeneration)) {
        return;
      }
      final currentVersion = _choices.where((item) => item.id == choice.id).firstOrNull;
      setState(() {
        _state = state;
        _restoredChoice = currentVersion ?? choice;
        _feedback = null;
      });
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) showErrorSnackBar(context, t.discover.findNext.changeFailed);
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
      final lendingLibraryId = choice.lendingLibraryId;
      final lendingBookId = choice.lendingBookId;
      if (lendingLibraryId != null || lendingBookId != null) {
        if (lendingLibraryId == null || lendingBookId == null || !LendingService.overdriveEnabled) {
          throw const SourceException(SourceFailure.unavailable);
        }
        final service = LendingService(
          sources.repository,
          profileId,
          valid: () =>
              mounted && sources.current(_sourceGeneration) && !sources.blocked && sources.profileId == profileId,
        );
        try {
          final library = (await service.libraries())
              .where((item) => item.id == lendingLibraryId && item.native)
              .firstOrNull;
          if (library == null) throw const SourceException(SourceFailure.unavailable);
          if (!mounted ||
              context.read<ActiveProfileProvider>().active?.id != profileId ||
              !sources.current(_sourceGeneration)) {
            return;
          }
          final isConnected = await service.connected(library);
          if (!mounted ||
              context.read<ActiveProfileProvider>().active?.id != profileId ||
              !sources.current(_sourceGeneration)) {
            return;
          }
          if (!isConnected) {
            await signInToLendingLibrary(context, service, library);
            if (!mounted || context.read<ActiveProfileProvider>().active?.id != profileId) return;
          }
          if (!await service.connected(library)) throw const SourceException(SourceFailure.authentication);
          if (!mounted ||
              context.read<ActiveProfileProvider>().active?.id != profileId ||
              !sources.current(_sourceGeneration)) {
            return;
          }
          await Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => LibraryCatalogueScreen(
                service: service,
                library: library,
                initialQuery: choice.title,
                initialBookId: lendingBookId,
              ),
            ),
          );
        } finally {
          service.close();
        }
        return;
      }
      final publicWorkId = choice.publicCatalogWorkId;
      if (publicWorkId != null) {
        if (!RegExp(r'^OL[0-9]{1,14}W$').hasMatch(publicWorkId)) {
          throw const SourceException(SourceFailure.invalidData);
        }
        final service = LendingService(
          sources.repository,
          profileId,
          valid: () => mounted && sources.current(_sourceGeneration) && !sources.blocked,
        );
        try {
          await service.openPage(Uri.https('openlibrary.org', '/works/$publicWorkId'));
        } finally {
          service.close();
        }
        return;
      }
      if (choice.serverId == null &&
          choice.sourceId == null &&
          choice.catalogSourceId == null &&
          choice.portableKey != null) {
        await _openPortableChoice(choice, profileId, detailsOnly: detailsOnly);
        return;
      }
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
          for (final file in entry.files.where((item) => !item.sampleOnly)) {
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

  bool _publicIdsOverlap(Map<String, String> left, Map<String, String> right) =>
      left.entries.any((entry) => right[entry.key] == entry.value);

  bool _matchesPortableChoice(DiscoveryChoice candidate, DiscoveryChoice saved) =>
      candidate.isSamePortableWorkAs(saved);

  Future<void> _openPortableChoice(DiscoveryChoice choice, String profileId, {required bool detailsOnly}) async {
    final sources = context.read<SourceController>();
    sources.requireSession(_sourceGeneration);

    if (choice.type == DiscoveryChoiceType.ebook ||
        choice.type == DiscoveryChoiceType.audiobook ||
        choice.type == DiscoveryChoiceType.comic ||
        choice.type == DiscoveryChoiceType.music ||
        choice.type == DiscoveryChoiceType.sourceVideo) {
      final bySource = {for (final source in sources.sources) source.id: source};
      final candidates = await sources.repository.entriesByPublicIdentifiers(
        profileId,
        choice.portableIds,
        kind: _sourceKindForPortableChoice(choice),
        sourceIds: bySource.keys.toSet(),
      );
      sources.requireSession(_sourceGeneration);
      final matches = candidates
          .where(
            (entry) =>
                discoveryTypeForSourceKind(entry.kind) == choice.type &&
                _publicIdsOverlap(choice.portableIds, sanitizeDiscoveryPortableIds(entry.identifiers)) &&
                bySource.containsKey(entry.sourceId),
          )
          .toList(growable: false);
      for (final entry in matches) {
        final rebound = await _choiceForSource(entry, bySource[entry.sourceId]!, sources, profileId);
        if (rebound == null || !_matchesPortableChoice(rebound, choice)) continue;
        sources.requireSession(_sourceGeneration);
        await _openChoice(rebound, detailsOnly: detailsOnly);
        return;
      }
    }

    if (choice.type == DiscoveryChoiceType.video &&
        (choice.mediaKind == MediaKind.movie || choice.mediaKind == MediaKind.show)) {
      final ids = ExternalIds(
        imdb: choice.portableIds['imdb'],
        tmdb: int.tryParse(choice.portableIds['tmdb'] ?? ''),
        tvdb: int.tryParse(choice.portableIds['tvdb'] ?? ''),
      );
      if (ids.hasCatalogIds) {
        if (!mounted ||
            context.read<ActiveProfileProvider>().active?.id != profileId ||
            !sources.current(_sourceGeneration)) {
          return;
        }
        final multiServer = context.read<MultiServerProvider>();
        final result = await multiServer.aggregationService.findByExternalIdsAcrossServers(
          ids,
          kind: choice.mediaKind!,
          serverIds: multiServer.expectedServerIds.toSet(),
          titles: [choice.title],
        );
        sources.requireSession(_sourceGeneration);
        if (!mounted || context.read<ActiveProfileProvider>().active?.id != profileId) return;
        final hidden = context.read<HiddenLibrariesProvider>().hiddenLibraryKeys;
        final libraries = context.read<LibrariesProvider>().libraries;
        final visibleCopy = result.items.where((item) {
          if (item.kind != choice.mediaKind) return false;
          final libraryId = item.libraryId;
          final serverId = item.serverId;
          if (libraryId == null || serverId == null) return true;
          final key = buildGlobalKey(ServerId(serverId), libraryId);
          return !hidden.contains(key) && libraries.any((library) => library.globalKey == key);
        }).firstOrNull;
        if (visibleCopy != null) {
          if (detailsOnly) {
            await navigateToMediaItemDetails(context, visibleCopy);
          } else {
            await navigateToMediaItem(context, visibleCopy, playDirectly: visibleCopy.kind == MediaKind.movie);
          }
          return;
        }
      }
    }

    if (!mounted ||
        context.read<ActiveProfileProvider>().active?.id != profileId ||
        !sources.current(_sourceGeneration)) {
      return;
    }
    final catalogProvider = context.read<CatalogSourcesProvider?>();
    if (_catalogAllowed && catalogProvider != null && choice.type == DiscoveryChoiceType.video) {
      for (final source in catalogProvider.connectedSources) {
        List<CatalogItem> items;
        try {
          items = await source.search(choice.title, limit: 50).timeout(const Duration(seconds: 8));
        } catch (_) {
          continue;
        }
        sources.requireSession(_sourceGeneration);
        if (!mounted || context.read<ActiveProfileProvider>().active?.id != profileId) return;
        final stillConnected =
            context.read<CatalogSourcesProvider?>()?.connectedSources.any((value) => identical(value, source)) ?? false;
        if (!_catalogAllowed || !stillConnected) continue;
        final match = items.where((item) {
          if (item.kind != choice.mediaKind) return false;
          final ids = sanitizeDiscoveryPortableIds(item.ids.toJson().map((key, value) => MapEntry(key, '$value')));
          return _publicIdsOverlap(choice.portableIds, ids);
        }).firstOrNull;
        if (match != null) {
          await navigateToCatalogItem(context, match);
          return;
        }
      }
    }

    throw const SourceException(SourceFailure.unavailable);
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
    await _openChoice(choice, detailsOnly: true);
  }

  Future<void> _hideFromDiscovery(DiscoveryChoice choice) async {
    final profileId = _ownerProfileId;
    if (profileId == null || !_sessionCurrent(profileId, _sourceGeneration, _loadGeneration)) return;
    try {
      final next = await _tasteStore.hide(profileId, choice);
      if (!_sessionCurrent(profileId, _sourceGeneration, _loadGeneration)) return;
      setState(() {
        _taste = next;
        _restoredChoice = null;
        _position = _choices.indexWhere((item) => !_state.seen.contains(item.id) && _matchesFilters(item));
        if (_position < 0) _position = _choices.length;
        _feedback = null;
      });
    } catch (_) {
      if (mounted) showErrorSnackBar(context, t.discover.findNext.changeFailed);
    }
  }

  Future<void> _searchLibraryCandidate(DiscoveryChoice anchor) async {
    final profileId = _ownerProfileId;
    final sources = context.read<SourceController>();
    if (profileId == null ||
        _committing ||
        !context.read<OfflineModeProvider>().hasNetworkConnection ||
        !_sessionCurrent(profileId, _sourceGeneration, _loadGeneration)) {
      return;
    }
    setState(() => _committing = true);
    final generation = _sourceGeneration;
    final service = LendingService(
      sources.repository,
      profileId,
      valid: () => mounted && sources.current(generation) && !sources.blocked && sources.profileId == profileId,
    );
    try {
      LendingLibrary? selectedLibrary;
      if (LendingService.overdriveEnabled) {
        try {
          final configured = (await service.libraries()).where((library) => library.native).toList(growable: false);
          if (configured.isNotEmpty && mounted && _sessionCurrent(profileId, generation, _loadGeneration)) {
            final selection =
                await OverlaySheetController.showAdaptive<({bool publicCatalog, LendingLibrary? library})>(
                  context,
                  showDragHandle: true,
                  builder: (sheetContext) => Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.72),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              t.discover.findNext.libraryCatalog,
                              style: Theme.of(sheetContext).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              t.discover.findNext.libraryCatalogHint,
                              style: Theme.of(sheetContext).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 12),
                            FocusableListTile(
                              leading: const AppIcon(Symbols.menu_book_rounded),
                              title: const Text('Open Library'),
                              subtitle: Text(t.discover.findNext.catalogOnly),
                              onTap: () => Navigator.of(sheetContext).pop((publicCatalog: true, library: null)),
                            ),
                            for (final library in configured)
                              FocusableListTile(
                                leading: const AppIcon(Symbols.local_library_rounded),
                                title: Text(isolateDisplayText(library.name)),
                                subtitle: Text(library.provider.label),
                                onTap: () => Navigator.of(sheetContext).pop((publicCatalog: false, library: library)),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
            if (selection == null) return;
            if (selection.publicCatalog == (selection.library != null)) return;
            selectedLibrary = selection.library;
          }
        } catch (_) {
          // A local lender setup issue does not remove the public catalog path.
        }
      }
      final selectedLender = selectedLibrary;
      if (selectedLender != null && !await service.connected(selectedLender)) {
        if (!mounted || !_sessionCurrent(profileId, generation, _loadGeneration)) return;
        await signInToLendingLibrary(context, service, selectedLender);
        if (!mounted || !_sessionCurrent(profileId, generation, _loadGeneration)) return;
        if (!await service.connected(selectedLender)) return;
      }
      if (!mounted || !_sessionCurrent(profileId, generation, _loadGeneration)) return;
      final book = await Navigator.of(context).push<LendingBook>(
        MaterialPageRoute(
          builder: (_) => LibraryCatalogueScreen(
            service: service,
            library: selectedLender,
            initialQuery: anchor.title,
            selectOnly: true,
          ),
        ),
      );
      if (book == null || !_sessionCurrent(profileId, generation, _loadGeneration)) return;
      final title = book.title.trim();
      if (title.isEmpty) return;
      late final DiscoveryChoice choice;
      if (selectedLender == null) {
        final match = RegExp(r'^/works/(OL[0-9]{1,14}W)$').firstMatch(book.id);
        if (match == null) return;
        final workId = match.group(1)!;
        choice = DiscoveryChoice(
          id: jsonEncode(['open-library-work', workId]),
          type: DiscoveryChoiceType.ebook,
          title: title,
          subtitle: book.author.trim(),
          reason: t.discover.findNext.catalogOnly,
          summary: '',
          durationMs: null,
          totalDurationMs: null,
          isEstimate: false,
          serverId: null,
          mediaId: null,
          mediaKind: null,
          sourceId: null,
          entryId: null,
          year: null,
          publicCatalogWorkId: workId,
          publicCatalogAuthor: book.author.trim(),
        );
      } else {
        if (!selectedLender.native ||
            selectedLender.id.trim().isEmpty ||
            selectedLender.id.length > 128 ||
            book.id.trim().isEmpty ||
            book.id == 'null' ||
            book.id.length > 256 ||
            RegExp(r'[\r\n\u0000]').hasMatch(book.id)) {
          return;
        }
        choice = DiscoveryChoice(
          id: jsonEncode(['lending-candidate', selectedLender.id, book.id]),
          type: DiscoveryChoiceType.ebook,
          title: title,
          subtitle: book.author.trim(),
          reason: t.discover.findNext.libraryReason(library: selectedLender.name),
          summary: '',
          durationMs: null,
          totalDurationMs: null,
          isEstimate: false,
          serverId: null,
          mediaId: null,
          mediaKind: null,
          sourceId: null,
          entryId: null,
          year: null,
          lendingLibraryId: selectedLender.id,
          lendingBookId: book.id,
        );
      }
      final existing = _choices.indexWhere((item) => item.id == choice.id);
      final insertedAt = existing >= 0 ? existing : _position.clamp(0, _choices.length).toInt();
      final nextChoices = existing >= 0
          ? [..._choices]
          : [..._choices.take(insertedAt), choice, ..._choices.skip(insertedAt)];
      final nextState = await _store.restoreToDeck(profileId, choice.id);
      final nextTaste = _taste.hides(choice.id) ? await _tasteStore.unhide(profileId, choice.id) : _taste;
      if (!_sessionCurrent(profileId, generation, _loadGeneration)) return;
      setState(() {
        _choices = nextChoices;
        _state = nextState;
        _taste = nextTaste;
        _position = insertedAt;
        _restoredChoice = null;
        _feedback = null;
      });
    } catch (_) {
      if (mounted && context.read<ActiveProfileProvider>().active?.id == profileId) {
        showErrorSnackBar(context, t.discover.findNext.openFailed);
      }
    } finally {
      service.close();
      if (mounted) setState(() => _committing = false);
    }
  }

  Future<void> _previewChoice(DiscoveryChoice choice) async {
    final profileId = _ownerProfileId;
    final sourceId = choice.sourceId;
    final entryId = choice.entryId;
    final sources = context.read<SourceController>();
    if (profileId == null ||
        sourceId == null ||
        entryId == null ||
        context.read<ActiveProfileProvider>().active?.id != profileId ||
        !sources.current(_sourceGeneration)) {
      return;
    }
    try {
      final source = sources.sources.where((item) => item.id == sourceId).firstOrNull;
      if (source == null) throw const SourceException(SourceFailure.unavailable);
      final storedEntry = await sources.repository.entryById(profileId, sourceId, entryId) ?? choice.sourceEntry;
      if (storedEntry == null ||
          storedEntry.kind == SourceItemKind.folder ||
          storedEntry.kind == SourceItemKind.unknown) {
        throw const SourceException(SourceFailure.unavailable);
      }
      var entry = storedEntry;
      try {
        entry = await sources.hydrate(entry);
      } on SourceException catch (error) {
        if (error.reason == SourceFailure.cancelled) rethrow;
      }
      sources.requireSession(_sourceGeneration);
      if (!mounted || context.read<ActiveProfileProvider>().active?.id != profileId) return;
      final sample = entry.sampleFiles.where((file) => file.previewableSample).firstOrNull;
      if (sample == null) throw const SourceException(SourceFailure.unavailable);
      if (sample.kind == SourceItemKind.ebook || sample.kind == SourceItemKind.comic) {
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => PublicationReaderScreen(entry: entry, file: sample),
          ),
        );
      } else {
        final playback = context.read<SourcePlayback>();
        await playback.start(
          entry,
          [sample],
          playbackMode: sample.kind == SourceItemKind.video ? PublicationMode.watching : PublicationMode.listening,
          persistProgress: false,
          samplePreview: sources.beginPreview(entry, sample),
        );
        if (!mounted || context.read<ActiveProfileProvider>().active?.id != profileId) return;
        await Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => const SourcePlayerScreen()));
      }
    } catch (_) {
      if (mounted && context.read<ActiveProfileProvider>().active?.id == profileId) {
        showErrorSnackBar(context, t.discover.findNext.openFailed);
      }
    }
  }

  String _typeLabel(DiscoveryChoice choice) {
    if (choice.publicCatalogWorkId != null) return t.discover.findNext.catalogOnly;
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
    if (choice.publicCatalogWorkId != null || choice.lendingBookId != null) return t.discover.findNext.details;
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
    DiscoveryChoiceType.comic => GridLayoutConstants.posterAspectRatio,
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
      onPreview: _committing || choice.sourceEntry?.sampleFiles.isNotEmpty != true
          ? null
          : () => _previewChoice(choice),
      onHide: _committing ? null : () => _hideFromDiscovery(choice),
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
    onClearFilters: noMatches && _hasActiveFilters ? _clearFilters : null,
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
              if (current != null && context.watch<OfflineModeProvider>().hasNetworkConnection)
                IconButton(
                  tooltip: t.discover.findNext.libraryCatalog,
                  onPressed: profileChanged || _loading || _committing ? null : () => _searchLibraryCandidate(current),
                  icon: const AppIcon(Symbols.local_library_rounded),
                ),
              IconButton(
                tooltip: t.discover.findNext.filters,
                onPressed: profileChanged || _loading ? null : _showFilters,
                icon: Badge(isLabelVisible: _hasActiveFilters, child: const AppIcon(Symbols.tune_rounded)),
              ),
              IconButton(
                tooltip: t.fileSources.history,
                onPressed: profileChanged || _loading ? null : _openHistory,
                icon: const AppIcon(Symbols.history_rounded),
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
    required this.syncSavedPicks,
    required this.onOpen,
    required this.onChooseForMe,
    required this.onChooseTogether,
    required this.onChanged,
  });
  final String profileId;
  final DiscoveryStore store;
  final bool includeCatalog;
  final bool syncSavedPicks;
  final ValueChanged<DiscoveryChoice> onOpen;
  final ValueChanged<List<DiscoveryChoice>> onChooseForMe;
  final ValueChanged<DiscoveryChoice> onChooseTogether;
  final Future<void> Function() onChanged;
  @override
  State<_SavedPicksScreen> createState() => _SavedPicksScreenState();
}

class _SavedPicksScreenState extends State<_SavedPicksScreen> {
  DiscoveryState _state = const DiscoveryState();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  bool _busy = false;
  bool _searching = false;
  bool _compareMode = false;
  bool _voteMode = false;
  bool _comparing = false;
  bool _voting = false;
  int _sourceGeneration = -1;
  final Set<String> _comparisonIds = {};
  String _query = '';

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final sources = context.read<SourceController>();
    if (sources.profileId != widget.profileId || sources.blocked) return;
    _sourceGeneration = sources.generation;
    final state = await widget.store.load(widget.profileId);
    if (!mounted ||
        !sources.current(_sourceGeneration) ||
        sources.profileId != widget.profileId ||
        context.read<ActiveProfileProvider>().active?.id != widget.profileId) {
      return;
    }
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
      setState(() {
        _state = state;
        _comparisonIds.remove(choice.id);
      });
      context.read<SourceController>().scheduleSync();
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
    final savedChanged = _state.history.last.savedChanged;
    setState(() => _busy = true);
    try {
      final (state, _) = await widget.store.undo(widget.profileId);
      if (!mounted || context.read<ActiveProfileProvider>().active?.id != widget.profileId) return;
      setState(() => _state = state);
      if (savedChanged) context.read<SourceController>().scheduleSync();
      await widget.onChanged();
    } catch (_) {
      if (mounted) showErrorSnackBar(context, t.discover.findNext.changeFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toggleSearch() {
    if (_searching) _searchController.clear();
    setState(() {
      _searching = !_searching;
      _query = '';
    });
  }

  void _toggleCompareMode() {
    setState(() {
      _compareMode = !_compareMode;
      _voteMode = false;
      _comparisonIds.clear();
    });
  }

  void _toggleVoteMode() {
    setState(() {
      _voteMode = !_voteMode;
      _compareMode = false;
      _comparisonIds.clear();
    });
  }

  void _toggleComparison(DiscoveryChoice choice) {
    if (_comparisonIds.contains(choice.id)) {
      setState(() => _comparisonIds.remove(choice.id));
      return;
    }
    if (_comparisonIds.length >= (_voteMode ? 12 : 3)) {
      showErrorSnackBar(context, _voteMode ? t.discover.findNext.voteLimit : t.discover.findNext.compareLimit);
      return;
    }
    setState(() => _comparisonIds.add(choice.id));
  }

  Future<void> _startVoting(List<DiscoveryChoice> choices) async {
    if (_voting || _comparisonIds.length < 2 || _comparisonIds.length > 12) return;
    final sources = context.read<SourceController>();
    if (!sources.current(_sourceGeneration) || sources.profileId != widget.profileId || sources.blocked) return;
    final selected = choices.where((choice) => _comparisonIds.contains(choice.id)).take(12).toList(growable: false);
    if (selected.length < 2) {
      showErrorSnackBar(context, t.discover.findNext.voteLimit);
      return;
    }
    setState(() => _voting = true);
    try {
      final choice = await Navigator.of(context).push<DiscoveryChoice>(
        MaterialPageRoute(
          builder: (_) => DiscoveryShortlistVoteScreen(profileId: widget.profileId, choices: selected),
        ),
      );
      sources.requireSession(_sourceGeneration);
      if (choice != null && mounted && context.read<ActiveProfileProvider>().active?.id == widget.profileId) {
        widget.onChooseTogether(choice);
      }
    } catch (_) {
      if (mounted) showErrorSnackBar(context, t.discover.findNext.changeFailed);
    } finally {
      if (mounted) setState(() => _voting = false);
    }
  }

  Future<void> _compareSelected(List<DiscoveryChoice> choices) async {
    if (_comparing || _comparisonIds.length < 2) return;
    final sources = context.read<SourceController>();
    if (!sources.current(_sourceGeneration) || sources.profileId != widget.profileId) return;
    setState(() => _comparing = true);
    try {
      final selected = choices.where((choice) => _comparisonIds.contains(choice.id)).toList(growable: false);
      if (selected.length < 2) {
        if (mounted) {
          setState(() => _comparisonIds.removeWhere((id) => !choices.any((choice) => choice.id == id)));
          showErrorSnackBar(context, t.discover.findNext.compareNeedsTwo);
        }
        return;
      }
      final facts = await Future.wait(selected.map(_comparisonFacts));
      sources.requireSession(_sourceGeneration);
      if (!mounted || context.read<ActiveProfileProvider>().active?.id != widget.profileId) return;
      await OverlaySheetController.showAdaptive<void>(
        context,
        showDragHandle: true,
        builder: (sheetContext) {
          final screenHeight = MediaQuery.sizeOf(sheetContext).height;
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: screenHeight * 0.84),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(t.common.compare, style: Theme.of(sheetContext).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 720;
                        if (wide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var index = 0; index < facts.length; index++) ...[
                                if (index > 0) const SizedBox(width: 12),
                                Expanded(child: _comparisonCard(context, facts[index])),
                              ],
                            ],
                          );
                        }
                        return ListView.separated(
                          itemCount: facts.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) => _comparisonCard(context, facts[index]),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(onPressed: () => Navigator.of(sheetContext).pop(), child: Text(t.common.close)),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (_) {
      if (mounted) showErrorSnackBar(context, t.discover.findNext.openFailed);
    } finally {
      if (mounted) setState(() => _comparing = false);
    }
  }

  Future<_SavedPickFacts> _comparisonFacts(DiscoveryChoice choice) async {
    final sources = context.read<SourceController>();
    sources.requireSession(_sourceGeneration);
    final downloads = context.read<DownloadProvider>();
    var entry = choice.sourceEntry;
    if (entry == null && choice.sourceId != null && choice.entryId != null) {
      try {
        entry = await sources.repository.entryById(widget.profileId, choice.sourceId!, choice.entryId!);
        sources.requireSession(_sourceGeneration);
      } catch (_) {}
    }
    if (entry == null &&
        choice.portableKey != null &&
        (choice.type == DiscoveryChoiceType.ebook ||
            choice.type == DiscoveryChoiceType.audiobook ||
            choice.type == DiscoveryChoiceType.comic ||
            choice.type == DiscoveryChoiceType.music ||
            choice.type == DiscoveryChoiceType.sourceVideo)) {
      try {
        final configured = {for (final source in sources.sources) source.id};
        entry =
            (await sources.repository.entriesByPublicIdentifiers(
                  widget.profileId,
                  choice.portableIds,
                  kind: _sourceKindForPortableChoice(choice),
                  sourceIds: configured,
                ))
                .where(
                  (candidate) =>
                      discoveryTypeForSourceKind(candidate.kind) == choice.type &&
                      configured.contains(candidate.sourceId) &&
                      _sharesPublicId(choice.portableIds, sanitizeDiscoveryPortableIds(candidate.identifiers)),
                )
                .firstOrNull;
        sources.requireSession(_sourceGeneration);
      } catch (_) {}
    }
    var offline = false;
    var language = '';
    var narrator = '';
    var edition = '';
    if (entry != null) {
      language = entry.language.trim();
      narrator = entry.narrator.trim();
      final ordinary = entry.files.where((file) => !file.sampleOnly).toList(growable: false);
      edition = ordinary.map((file) => isolateDisplayText(file.name)).take(4).join('\n');
      for (final file in ordinary) {
        if (await sources.hasOfflineContent(entry, file)) {
          sources.requireSession(_sourceGeneration);
          offline = true;
          break;
        }
        sources.requireSession(_sourceGeneration);
      }
    } else if (choice.serverId != null && choice.mediaId != null) {
      final media =
          choice.mediaItem ??
          downloads.metadata.values
              .where((item) => item.serverId == choice.serverId && item.id == choice.mediaId)
              .firstOrNull;
      if (media != null && await downloads.getCompletedDownload(media.globalKey) != null) {
        try {
          if (media.kind == MediaKind.movie || media.kind == MediaKind.episode || media.kind == MediaKind.clip) {
            offline = await downloads.getVideoFilePath(media.globalKey).timeout(const Duration(seconds: 2)) != null;
          }
        } catch (_) {}
      }
    } else if (choice.type == DiscoveryChoiceType.video &&
        (choice.mediaKind == MediaKind.movie || choice.mediaKind == MediaKind.show)) {
      final media = await _findPortableLibraryCopy(choice);
      sources.requireSession(_sourceGeneration);
      if (media != null && await downloads.getCompletedDownload(media.globalKey) != null) {
        try {
          if (media.kind == MediaKind.movie || media.kind == MediaKind.episode || media.kind == MediaKind.clip) {
            offline = await downloads.getVideoFilePath(media.globalKey).timeout(const Duration(seconds: 2)) != null;
          }
        } catch (_) {}
      }
    }
    return _SavedPickFacts(
      title: isolateDisplayText(choice.title),
      type: _localizedChoiceType(choice),
      localOnly: widget.syncSavedPicks && choice.portableKey == null,
      duration: choice.totalDurationMs ?? choice.durationMs,
      language: language.isEmpty ? t.common.notAvailable : language,
      narrator: narrator.isEmpty ? t.common.notAvailable : isolateDisplayText(narrator),
      edition: edition.isEmpty ? t.common.notAvailable : edition,
      availability: offline ? t.fileSources.offline : t.discover.findNext.availabilityNotChecked,
      summary: isolateDisplayText(choice.summary).trim().isEmpty
          ? t.common.notAvailable
          : isolateDisplayText(choice.summary),
    );
  }

  bool _sharesPublicId(Map<String, String> left, Map<String, String> right) =>
      left.entries.any((entry) => right[entry.key] == entry.value);

  Future<MediaItem?> _findPortableLibraryCopy(DiscoveryChoice choice) async {
    final sourceController = context.read<SourceController>();
    if (!sourceController.current(_sourceGeneration) || sourceController.profileId != widget.profileId) return null;
    final ids = ExternalIds(
      imdb: choice.portableIds['imdb'],
      tmdb: int.tryParse(choice.portableIds['tmdb'] ?? ''),
      tvdb: int.tryParse(choice.portableIds['tvdb'] ?? ''),
    );
    if (!ids.hasCatalogIds) return null;
    try {
      final multiServer = context.read<MultiServerProvider>();
      final result = await multiServer.aggregationService.findByExternalIdsAcrossServers(
        ids,
        kind: choice.mediaKind!,
        serverIds: multiServer.expectedServerIds.toSet(),
        titles: [choice.title],
      );
      if (!sourceController.current(_sourceGeneration) || sourceController.profileId != widget.profileId) return null;
      if (!mounted || context.read<ActiveProfileProvider>().active?.id != widget.profileId) return null;
      final hidden = context.read<HiddenLibrariesProvider>().hiddenLibraryKeys;
      final libraries = context.read<LibrariesProvider>().libraries;
      return result.items.where((item) {
        if (item.kind != choice.mediaKind) return false;
        final libraryId = item.libraryId;
        final serverId = item.serverId;
        if (libraryId == null || serverId == null) return true;
        final key = buildGlobalKey(ServerId(serverId), libraryId);
        return !hidden.contains(key) && libraries.any((library) => library.globalKey == key);
      }).firstOrNull;
    } catch (_) {
      return null;
    }
  }

  Widget _comparisonCard(BuildContext context, _SavedPickFacts facts) {
    final theme = Theme.of(context);
    Widget field(String label, String value) => Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 3),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
    return Card(
      margin: EdgeInsets.zero,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(facts.title, style: theme.textTheme.titleMedium, maxLines: 3, overflow: TextOverflow.ellipsis),
            field(t.fileInfo.mediaType, facts.type),
            if (widget.syncSavedPicks)
              field(t.discover.findNext.syncSavedPicks, facts.localOnly ? t.discover.findNext.localOnly : t.common.yes),
            field(
              t.fileInfo.duration,
              facts.duration == null ? t.common.notAvailable : formatDurationTextual(facts.duration!),
            ),
            field(t.fileInfo.language, facts.language),
            field(t.fileSources.narrator, facts.narrator),
            field(t.fileSources.editions, facts.edition),
            field(t.discover.findNext.availability, facts.availability),
            field(t.discover.overview, facts.summary),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeProfile = context.watch<ActiveProfileProvider>().active;
    final sources = context.watch<SourceController>();
    final profileChanged =
        activeProfile?.id != widget.profileId ||
        sources.profileId != widget.profileId ||
        sources.blocked ||
        !sources.current(_sourceGeneration);
    final savedChoices = _state.saved
        .where((choice) => widget.includeCatalog || choice.catalogSourceId == null)
        .toList();
    final query = _query.trim().toLowerCase();
    final visibleChoices = query.isEmpty
        ? savedChoices
        : savedChoices
              .where(
                (choice) => [
                  choice.title,
                  choice.subtitle,
                  choice.reason,
                  _localizedChoiceType(choice),
                ].join('\n').toLowerCase().contains(query),
              )
              .toList(growable: false);
    final canUndo =
        _state.history.isNotEmpty && (widget.includeCatalog || _state.history.last.choice.catalogSourceId == null);
    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(hintText: t.common.search, border: InputBorder.none, isDense: true),
                onChanged: (value) => setState(() => _query = value),
              )
            : Text(
                _compareMode || _voteMode
                    ? t.libraries.selection.selectedCount(count: localizeDecimalDigits('${_comparisonIds.length}'))
                    : t.discover.findNext.saved,
              ),
        actions: [
          if (_compareMode || _voteMode)
            IconButton(
              tooltip: t.common.close,
              onPressed: profileChanged || _busy || _comparing || _voting
                  ? null
                  : _voteMode
                  ? _toggleVoteMode
                  : _toggleCompareMode,
              icon: const AppIcon(Symbols.close_rounded),
            )
          else
            IconButton(
              tooltip: t.discover.findNext.selectToCompare,
              onPressed: profileChanged || _busy || _searching || savedChoices.length < 2 ? null : _toggleCompareMode,
              icon: const AppIcon(Symbols.compare_arrows_rounded),
            ),
          if (!_compareMode && !_voteMode)
            IconButton(
              tooltip: t.discover.findNext.selectToVote,
              onPressed: profileChanged || _busy || _searching || savedChoices.length < 2 ? null : _toggleVoteMode,
              icon: const AppIcon(Symbols.groups_rounded),
            ),
          if (_compareMode)
            FocusableButton(
              onPressed: profileChanged || _busy || _comparing || _comparisonIds.length < 2
                  ? null
                  : () => _compareSelected(savedChoices),
              autoScroll: false,
              child: TextButton.icon(
                onPressed: profileChanged || _busy || _comparing || _comparisonIds.length < 2
                    ? null
                    : () => _compareSelected(savedChoices),
                icon: const AppIcon(Symbols.compare_arrows_rounded),
                label: Text(t.common.compare),
              ),
            ),
          if (_voteMode)
            FocusableButton(
              onPressed: profileChanged || _busy || _voting || _comparisonIds.length < 2
                  ? null
                  : () => _startVoting(savedChoices),
              autoScroll: false,
              child: TextButton.icon(
                onPressed: profileChanged || _busy || _voting || _comparisonIds.length < 2
                    ? null
                    : () => _startVoting(savedChoices),
                icon: const AppIcon(Symbols.groups_rounded),
                label: Text(t.discover.findNext.startVote),
              ),
            ),
          if (_searching || savedChoices.isNotEmpty)
            IconButton(
              tooltip: _searching ? t.common.close : t.common.search,
              onPressed: profileChanged ? null : _toggleSearch,
              icon: AppIcon(_searching ? Symbols.close_rounded : Symbols.search_rounded),
            ),
          if (!_compareMode && !_voteMode)
            IconButton(
              tooltip: t.common.shuffle,
              onPressed: _busy || visibleChoices.isEmpty || profileChanged
                  ? null
                  : () => widget.onChooseForMe(visibleChoices),
              icon: const AppIcon(Symbols.shuffle_rounded),
            ),
          if (!_compareMode && !_voteMode)
            FocusableButton(
              onPressed: _busy || !canUndo || profileChanged ? null : _undo,
              autoScroll: false,
              child: TextButton.icon(
                onPressed: _busy || !canUndo || profileChanged ? null : _undo,
                icon: const AppIcon(Symbols.undo_rounded),
                label: Text(t.discover.findNext.undo),
              ),
            ),
        ],
      ),
      body: profileChanged
          ? const SizedBox.shrink()
          : _loading
          ? const Center(child: CircularProgressIndicator())
          : savedChoices.isEmpty
          ? Center(child: Text(t.discover.findNext.noPicks))
          : visibleChoices.isEmpty
          ? Center(child: Text(t.messages.noResultsFound))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: visibleChoices.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final choice = visibleChoices[index];
                final selectedForComparison = _comparisonIds.contains(choice.id);
                return FocusableListTile(
                  autofocus: index == 0 && !_searching,
                  leading: CircleAvatar(child: AppIcon(_savedIcon(choice), size: 22)),
                  title: Text(isolateDisplayText(choice.title), maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    [
                      _localizedChoiceType(choice),
                      isolateDisplayText(choice.subtitle),
                      if (choice.publicCatalogWorkId != null) t.discover.findNext.catalogOnly,
                      if (choice.lendingLibraryId != null) isolateDisplayText(choice.reason),
                      if (widget.syncSavedPicks && choice.portableKey == null) t.discover.findNext.localOnly,
                      choice.durationMs == null ? null : formatDurationTextual(choice.durationMs!),
                    ].whereType<String>().where((value) => value.isNotEmpty).join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: _busy || profileChanged || _voting
                      ? null
                      : _compareMode || _voteMode
                      ? () => _toggleComparison(choice)
                      : () => widget.onOpen(choice),
                  trailing: IconButton(
                    tooltip: _compareMode
                        ? t.discover.findNext.selectToCompare
                        : _voteMode
                        ? t.discover.findNext.selectToVote
                        : t.common.delete,
                    onPressed: _busy || profileChanged || _voting
                        ? null
                        : _compareMode || _voteMode
                        ? () => _toggleComparison(choice)
                        : () => _remove(choice),
                    icon: AppIcon(
                      _compareMode
                          ? selectedForComparison
                                ? Symbols.check_circle_rounded
                                : Symbols.radio_button_unchecked_rounded
                          : Symbols.bookmark_remove_rounded,
                    ),
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

class _SavedPickFacts {
  const _SavedPickFacts({
    required this.title,
    required this.type,
    required this.localOnly,
    required this.duration,
    required this.language,
    required this.narrator,
    required this.edition,
    required this.availability,
    required this.summary,
  });
  final String title;
  final String type;
  final bool localOnly;
  final int? duration;
  final String language;
  final String narrator;
  final String edition;
  final String availability;
  final String summary;
}
