import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'gkui/diagnostics.dart';
import 'gkui/plex_api.dart';

const String buildLabel = 'Plezy GKUI 1.2.2 / adaptive mobile-data startup';
const String sourceLabel = 'Plezy 1.8.1 / GKUI compatibility fork';
const String toolchainLabel = 'Flutter 3.19.6 / ExoPlayer 2.19.1 / API 19';
const MethodChannel nativeChannel =
    MethodChannel('com.jialim.plezygkui/diagnostics');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PlexApi.installLegacyTrust();
  PaintingBinding.instance.imageCache.maximumSize = 48;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 16 * 1024 * 1024;
  await SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const PlezyGkuiApp());
}

class PlezyGkuiApp extends StatelessWidget {
  const PlezyGkuiApp({super.key});

  @override
  Widget build(BuildContext context) {
    const scheme = ColorScheme.dark(
      primary: Color(0xFFE5A00D),
      secondary: Color(0xFFE5A00D),
      surface: Color(0xFF171717),
      background: Color(0xFF0B0B0B),
      error: Color(0xFFFF6B6B),
    );
    return MaterialApp(
      title: 'Plezy GKUI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        brightness: Brightness.dark,
        colorScheme: scheme,
        scaffoldBackgroundColor: scheme.background,
        fontFamily: 'PlezySans',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(minimumSize: const Size(96, 54)),
        ),
      ),
      home: const GkuiRoot(),
    );
  }
}

enum AppPhase { starting, signedOut, signingIn, chooseServer, ready, error }

enum PlaybackMode { direct, transcode720, transcode480 }

PlaybackMode? playbackFallback(PlaybackMode mode, String? failureKind) {
  if (failureKind == 'network' ||
      failureKind == 'http' ||
      failureKind == 'initialization') {
    return null;
  }
  return switch (mode) {
    PlaybackMode.direct => PlaybackMode.transcode720,
    PlaybackMode.transcode720 => PlaybackMode.transcode480,
    PlaybackMode.transcode480 => null,
  };
}

int playbackStartupHardTimeoutMs(PlaybackMode mode) =>
    mode == PlaybackMode.direct ? 90000 : 120000;

enum LibraryView { all, unwatched, collections }

class GkuiController extends ChangeNotifier {
  final RedactingLogStore logs = RedactingLogStore(capacity: 160);
  PlexApi? api;
  AppPhase phase = AppPhase.starting;
  String? error;
  PlexPin? pin;
  String? pendingAccountToken;
  List<PlexServerResource> servers = const <PlexServerResource>[];
  List<PlexShelf> shelves = const <PlexShelf>[];
  List<PlexSection> sections = const <PlexSection>[];
  List<PlexMedia> libraryItems = const <PlexMedia>[];
  List<PlexMedia> searchResults = const <PlexMedia>[];
  List<PlexHomeUser> homeUsers = const <PlexHomeUser>[];
  PlexSection? selectedSection;
  PlexHomeUser? currentHomeUser;
  LibraryView libraryView = LibraryView.all;
  SearchMediaFilter searchFilter = SearchMediaFilter.all;
  GkuiSettings settings = const GkuiSettings();
  String searchQuery = '';
  String? lastSelectedVersion;
  int? lastFirstFrameMs;
  int? lastContentLoadMs;
  String? lastDecoder;
  String? lastVideoFormat;
  bool loadingContent = false;
  bool searching = false;
  bool loadingMoreLibrary = false;
  bool libraryHasMore = false;
  int libraryNextStart = 0;
  bool switchingProfile = false;
  int authGeneration = 0;
  int contentGeneration = 0;
  int searchGeneration = 0;
  Timer? periodicRefresh;
  bool disposed = false;

  bool get clockValid => DateTime.now().year >= 2024;

  Future<void> initialize() async {
    logs.add('Starting consolidated GKUI build.');
    if (!clockValid) {
      logs.add('Clock is invalid; secure network access is paused.');
      phase = AppPhase.signedOut;
      notifySafely();
      return;
    }
    try {
      api = await PlexApi.create(logs);
      settings = api!.loadSettings();
      if (api!.session == null) {
        phase = AppPhase.signedOut;
      } else {
        shelves = api!.loadCachedHome();
        sections = api!.loadCachedSections();
        selectedSection = sections.isEmpty ? null : sections.first;
        libraryItems = selectedSection == null
            ? const <PlexMedia>[]
            : api!.loadCachedSection(selectedSection!.key);
        if (shelves.isNotEmpty || sections.isNotEmpty) {
          phase = AppPhase.ready;
          logs.add('Showing cached Plex content while refreshing.');
          notifySafely();
        }
        await refreshContent(includeLibrary: libraryItems.isEmpty);
      }
    } catch (caught) {
      fail('Startup failed', caught);
    }
    notifySafely();
  }

  Future<void> retryClock() async {
    if (!clockValid) {
      error =
          'The head-unit date is still ${DateTime.now().year}. Connect Wi-Fi/4G or correct its clock.';
      notifySafely();
      return;
    }
    phase = AppPhase.starting;
    error = null;
    notifySafely();
    await initialize();
  }

  Future<void> beginSignIn() async {
    if (!clockValid) return retryClock();
    final generation = ++authGeneration;
    try {
      api ??= await PlexApi.create(logs);
      error = null;
      pin = await api!.createPin();
      phase = AppPhase.signingIn;
      notifySafely();
      for (var attempt = 0; attempt < 120; attempt++) {
        await Future<void>.delayed(const Duration(seconds: 2));
        if (generation != authGeneration || disposed) return;
        final token = await api!.checkPin(pin!);
        if (token == null || token.isEmpty) continue;
        pendingAccountToken = token;
        logs.add('Plex sign-in approved.');
        servers = await api!.fetchServers(token);
        if (servers.isEmpty) {
          throw StateError(
              'No Plex Media Server with a secure HTTPS address was found.');
        }
        if (servers.length == 1) {
          await connectServer(token, servers.first);
        } else {
          phase = AppPhase.chooseServer;
          notifySafely();
        }
        return;
      }
      throw TimeoutException('Plex sign-in timed out.');
    } catch (caught) {
      if (generation == authGeneration) fail('Sign-in failed', caught);
    }
  }

  Future<void> connectServer(String token, PlexServerResource server) async {
    try {
      phase = AppPhase.starting;
      notifySafely();
      await api!.connect(token, server);
      pendingAccountToken = null;
      await refreshContent();
    } catch (caught) {
      fail('Server connection failed', caught);
    }
  }

  Future<void> chooseServer(PlexServerResource server) async {
    final token = pendingAccountToken;
    if (token == null) {
      fail('Server selection failed',
          StateError('The sign-in token is no longer available.'));
      return;
    }
    await connectServer(token, server);
  }

  Future<void> refreshContent({bool includeLibrary = true}) async {
    if (api?.session == null) return;
    final started = Stopwatch()..start();
    final generation = ++contentGeneration;
    loadingMoreLibrary = false;
    loadingContent = true;
    error = null;
    notifySafely();
    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        api!.loadHome(),
        api!.loadSections(),
      ]);
      if (generation != contentGeneration || disposed) return;
      shelves = results[0] as List<PlexShelf>;
      sections = results[1] as List<PlexSection>;
      final previousKey = selectedSection?.key;
      selectedSection = sections.cast<PlexSection?>().firstWhere(
            (section) => section?.key == previousKey,
            orElse: () => sections.isEmpty ? null : sections.first,
          );
      if (includeLibrary && selectedSection != null) {
        final page = await api!.loadSectionPage(selectedSection!.key);
        if (generation != contentGeneration || disposed) return;
        libraryItems = page.items;
        libraryNextStart = page.nextStart;
        libraryHasMore = page.hasMore;
        libraryView = LibraryView.all;
      }
      phase = AppPhase.ready;
      lastContentLoadMs = started.elapsedMilliseconds;
      logs.add('Plex content is ready.');
      unawaited(loadHomeUsers());
      _ensurePeriodicRefresh();
    } catch (caught) {
      if (generation == contentGeneration && !disposed) {
        fail('Could not load Plex content', caught);
      }
    } finally {
      if (generation == contentGeneration && !disposed) {
        loadingContent = false;
        notifySafely();
      }
    }
  }

  Future<void> selectSection(PlexSection section) async {
    final generation = ++contentGeneration;
    loadingMoreLibrary = false;
    selectedSection = section;
    loadingContent = true;
    error = null;
    notifySafely();
    try {
      libraryView = LibraryView.all;
      final page = await api!.loadSectionPage(section.key);
      if (generation != contentGeneration || disposed) return;
      libraryItems = page.items;
      libraryNextStart = page.nextStart;
      libraryHasMore = page.hasMore;
    } catch (caught) {
      if (generation == contentGeneration && !disposed) {
        error = message('Library failed to load', caught);
      }
    } finally {
      if (generation == contentGeneration && !disposed) {
        loadingContent = false;
        notifySafely();
      }
    }
  }

  Future<void> selectLibraryView(LibraryView view) async {
    final section = selectedSection;
    if (section == null) return;
    final generation = ++contentGeneration;
    loadingMoreLibrary = false;
    libraryView = view;
    loadingContent = true;
    error = null;
    notifySafely();
    try {
      if (view == LibraryView.collections) {
        final items = await api!.loadCollections(section.key);
        if (generation != contentGeneration || disposed) return;
        libraryItems = items;
        libraryHasMore = false;
        libraryNextStart = items.length;
      } else {
        final page = await api!.loadSectionPage(section.key,
            unwatchedOnly: view == LibraryView.unwatched);
        if (generation != contentGeneration || disposed) return;
        libraryItems = page.items;
        libraryNextStart = page.nextStart;
        libraryHasMore = page.hasMore;
      }
    } catch (caught) {
      if (generation == contentGeneration && !disposed) {
        error = message('Library view failed to load', caught);
      }
    } finally {
      if (generation == contentGeneration && !disposed) {
        loadingContent = false;
        notifySafely();
      }
    }
  }

  Future<void> loadMoreLibrary() async {
    final section = selectedSection;
    if (section == null ||
        libraryView == LibraryView.collections ||
        !libraryHasMore ||
        loadingMoreLibrary) return;
    final generation = contentGeneration;
    loadingMoreLibrary = true;
    notifySafely();
    try {
      final page = await api!.loadSectionPage(
        section.key,
        start: libraryNextStart,
        unwatchedOnly: libraryView == LibraryView.unwatched,
      );
      if (generation != contentGeneration || disposed) return;
      final known = libraryItems.map((item) => item.ratingKey).toSet();
      libraryItems = <PlexMedia>[
        ...libraryItems,
        ...page.items.where((item) => known.add(item.ratingKey)),
      ];
      libraryNextStart = page.nextStart;
      libraryHasMore = page.hasMore;
    } catch (caught) {
      if (generation == contentGeneration && !disposed) {
        error = message('More library items failed to load', caught);
      }
    } finally {
      if (generation == contentGeneration && !disposed) {
        loadingMoreLibrary = false;
        notifySafely();
      }
    }
  }

  Future<void> runSearch(String query) async {
    final generation = ++searchGeneration;
    searchQuery = query.trim();
    if (searchQuery.length < 2) {
      searching = false;
      searchResults = const <PlexMedia>[];
      notifySafely();
      return;
    }
    searching = true;
    error = null;
    notifySafely();
    try {
      final results = await api!.search(searchQuery, filter: searchFilter);
      if (generation != searchGeneration || disposed) return;
      searchResults = results;
    } catch (caught) {
      if (generation == searchGeneration && !disposed) {
        error = message('Search failed', caught);
      }
    } finally {
      if (generation == searchGeneration && !disposed) {
        searching = false;
        notifySafely();
      }
    }
  }

  Future<void> setSearchFilter(SearchMediaFilter value) async {
    searchFilter = value;
    if (searchQuery.length >= 2) {
      await runSearch(searchQuery);
    } else {
      notifySafely();
    }
  }

  Future<void> updateSettings(GkuiSettings value) async {
    settings = value;
    await api!.saveSettings(value);
    notifySafely();
  }

  Future<void> loadHomeUsers() async {
    try {
      homeUsers = await api!.loadHomeUsers();
      final saved = api!.currentHomeUserUuid;
      currentHomeUser = homeUsers.cast<PlexHomeUser?>().firstWhere(
            (user) => user?.uuid == saved,
            orElse: () => homeUsers.cast<PlexHomeUser?>().firstWhere(
                  (user) => user?.admin == true,
                  orElse: () => homeUsers.isEmpty ? null : homeUsers.first,
                ),
          );
      notifySafely();
    } catch (caught) {
      logs.add('Plex Home profiles unavailable: ${compact(caught)}');
    }
  }

  Future<void> switchProfile(PlexHomeUser user, {String? pin}) async {
    if (user.uuid == currentHomeUser?.uuid) return;
    switchingProfile = true;
    contentGeneration++;
    searchGeneration++;
    error = null;
    notifySafely();
    try {
      final token = await api!.switchHomeUser(user, pin: pin);
      final resources = await api!.fetchServers(token);
      if (resources.isEmpty) {
        throw StateError('This profile has no accessible Plex server.');
      }
      final currentServerId = api!.session?.serverId;
      final server = resources.firstWhere(
        (candidate) => candidate.id == currentServerId,
        orElse: () => resources.first,
      );
      await api!.connect(token, server);
      await api!.saveCurrentHomeUser(user);
      await api!.clearContentCache();
      currentHomeUser = user;
      shelves = const <PlexShelf>[];
      libraryItems = const <PlexMedia>[];
      searchResults = const <PlexMedia>[];
      await refreshContent();
      logs.add('Switched Plex Home profile to ${user.displayName}.');
    } catch (caught) {
      error = message('Profile switch failed', caught);
      rethrow;
    } finally {
      switchingProfile = false;
      notifySafely();
    }
  }

  Future<void> reconnectAfterResume() async {
    if (phase != AppPhase.ready || api?.session == null || loadingContent)
      return;
    logs.add('App resumed; refreshing Plex connection.');
    await refreshContent(includeLibrary: false);
  }

  void _ensurePeriodicRefresh() {
    periodicRefresh ??=
        Timer.periodic(const Duration(minutes: 5), (Timer timer) {
      if (phase == AppPhase.ready && !loadingContent && !switchingProfile) {
        unawaited(refreshHomeQuietly());
      }
    });
  }

  Future<void> refreshHomeQuietly() async {
    if (api?.session == null) return;
    final generation = contentGeneration;
    try {
      final updated = await api!.loadHome();
      if (generation != contentGeneration || disposed) return;
      shelves = updated;
      notifySafely();
    } catch (caught) {
      logs.add('Background Home refresh skipped: ${compact(caught)}');
    }
  }

  void handleMemoryPressure() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    logs.add('Low-memory signal: released decoded artwork.');
  }

  Future<void> signOut() async {
    authGeneration++;
    contentGeneration++;
    searchGeneration++;
    periodicRefresh?.cancel();
    periodicRefresh = null;
    await api?.signOut();
    shelves = const <PlexShelf>[];
    sections = const <PlexSection>[];
    libraryItems = const <PlexMedia>[];
    phase = AppPhase.signedOut;
    error = null;
    notifySafely();
  }

  void cancelSignIn() {
    authGeneration++;
    pin = null;
    phase = AppPhase.signedOut;
    error = null;
    notifySafely();
  }

  Future<void> play(BuildContext context, PlexMedia media, PlaybackMode mode,
      {int? mediaIndex,
      String? audioTrackId,
      String? subtitleTrackId,
      bool allowAutoNext = true}) async {
    String? failureKind;
    PlaybackRequest? activeRequest;
    var preparingVisible = false;
    var selectedIndex = mediaIndex ?? 0;
    var item = media;
    try {
      unawaited(showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Row(children: <Widget>[
            SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(strokeWidth: 3)),
            SizedBox(width: 18),
            Expanded(
                child:
                    Text('Preparing video…', style: TextStyle(fontSize: 19))),
          ]),
        ),
      ));
      preparingVisible = true;
      await Future<void>.delayed(const Duration(milliseconds: 80));

      if (item.versions.isEmpty) {
        item = await api!.loadMetadata(item.ratingKey);
      }
      final remembered = api!.loadPlaybackChoice(item);
      final rememberedIndex = remembered.mediaIndex;
      selectedIndex = mediaIndex ??
          (rememberedIndex != null &&
                  item.versions
                      .any((version) => version.index == rememberedIndex)
              ? rememberedIndex
              : PlexMediaVersion.preferredIndex(item.versions));
      final selectedVersion = item.versions
          .where((version) => version.index == selectedIndex)
          .firstOrNull;
      lastSelectedVersion = selectedVersion?.displayLabel ?? 'Original';

      PlexTrack? findTrack(List<PlexTrack> tracks, String? id) => id == null
          ? null
          : tracks.where((track) => track.id == id).firstOrNull;
      final selectedAudio = findTrack(selectedVersion?.audioTracks ?? const [],
              audioTrackId ?? remembered.audioTrackId) ??
          (selectedVersion?.audioTracks ?? const <PlexTrack>[])
              .where((track) => track.selected)
              .firstOrNull;
      final requestedSubtitleId = subtitleTrackId ?? remembered.subtitleTrackId;
      final selectedSubtitle = requestedSubtitleId == 'off'
          ? null
          : findTrack(selectedVersion?.subtitleTracks ?? const [],
                  requestedSubtitleId) ??
              (selectedVersion?.subtitleTracks ?? const <PlexTrack>[])
                  .where((track) => track.selected)
                  .firstOrNull;
      final resolvedAudioTrackId = selectedAudio?.id;
      final resolvedSubtitleTrackId = requestedSubtitleId == 'off'
          ? 'off'
          : selectedSubtitle?.id ?? remembered.subtitleTrackId;
      await api!.savePlaybackChoice(
          item,
          PlaybackChoice(
            mediaIndex: selectedIndex,
            audioTrackId: resolvedAudioTrackId,
            subtitleTrackId: resolvedSubtitleTrackId,
          ));

      final markers = settings.skipMode != SkipMode.off
          ? api!.cachedMarkers(item.ratingKey)
          : const <PlexMarker>[];
      if (settings.skipMode != SkipMode.off && markers.isEmpty) {
        unawaited(api!
            .loadMarkers(item.ratingKey)
            .catchError((Object _) => const <PlexMarker>[]));
      }
      final bitrate = mode == PlaybackMode.transcode480 ? 1500 : 3000;
      final request = api!.playback(
        item,
        transcode: mode != PlaybackMode.direct,
        bitrate: bitrate,
        mediaIndex: selectedIndex,
        audioTrackId: resolvedAudioTrackId,
        subtitleTrackId:
            resolvedSubtitleTrackId == 'off' ? null : resolvedSubtitleTrackId,
      );
      activeRequest = request;
      logs.add(
          'Opening ${request.transcoding ? '${bitrate}kbps HLS' : 'direct'} playback (${lastSelectedVersion!}): ${item.title}.');
      if (preparingVisible && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        preparingVisible = false;
      }
      final playerFuture = nativeChannel
          .invokeMapMethod<String, dynamic>('playVideo', <String, dynamic>{
        'url': request.url,
        'headers': request.headers,
        'title': item.title,
        'startMs': item.viewOffsetMs,
        'ratingKey': item.ratingKey,
        'durationMs': item.durationMs,
        'timelineUrl': '${api!.session!.baseUrl}/:/timeline',
        'sessionId': request.sessionId,
        'audioLanguage': selectedAudio?.languageCode ?? settings.audioLanguage,
        'subtitleLanguage': resolvedSubtitleTrackId == 'off'
            ? 'off'
            : selectedSubtitle?.languageCode ?? settings.subtitleLanguage,
        'audioTrackId': resolvedAudioTrackId ?? '',
        'subtitleTrackId': resolvedSubtitleTrackId ?? '',
        'seekBackMs': settings.seekBackSeconds * 1000,
        'seekForwardMs': settings.seekForwardSeconds * 1000,
        'skipMode': settings.skipMode.name,
        'startupHardTimeoutMs': playbackStartupHardTimeoutMs(mode),
        'markers': markers
            .map((marker) => <String, dynamic>{
                  'type': marker.type,
                  'startMs': marker.startMs,
                  'endMs': marker.endMs,
                })
            .toList(),
      });
      // Telemetry must never delay the native player opening.
      unawaited(api!.reportProgress(item, item.viewOffsetMs, 'playing',
          sessionId: request.sessionId));
      final raw = await playerFuture;
      for (final line in (raw?['diagnostics'] as List<dynamic>? ?? const [])) {
        logs.add(line.toString());
      }
      failureKind = raw?['failureKind']?.toString();
      final position =
          (raw?['positionMs'] as num?)?.toInt() ?? item.viewOffsetMs;
      lastFirstFrameMs = (raw?['firstFrameMs'] as num?)?.toInt();
      lastDecoder = raw?['decoder']?.toString();
      lastVideoFormat = raw?['videoFormat']?.toString();
      _updateLocalProgress(item.ratingKey, position);
      notifySafely();
      if (raw?['renderedFrame'] == true) {
        await api!.reportProgress(
            item, position, raw?['ended'] == true ? 'stopped' : 'paused',
            sessionId: request.sessionId);
      }
      await api!.stopPlaybackSession(request);
      activeRequest = null;
      final playerError = raw?['error']?.toString();
      if (playerError != null && playerError.isNotEmpty)
        throw StateError(playerError);
      if (raw?['ended'] == true && settings.autoPlayNext && allowAutoNext) {
        final next = await api!.loadNextEpisode(item);
        if (next != null && context.mounted) {
          final proceed = await _showPlayNextCountdown(context, next);
          if (proceed && context.mounted) {
            logs.add('Autoplaying next episode: ${next.title}.');
            await play(context, next, PlaybackMode.direct, allowAutoNext: true);
          }
        }
      }
      unawaited(refreshHomeQuietly());
    } catch (caught) {
      if (preparingVisible && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        preparingVisible = false;
      }
      logs.add('Playback failed: ${compact(caught)}');
      if (context.mounted) {
        // A no-frame timeout often means the source codec/container cannot be
        // rendered by this API-19 head unit. Let it use the normal 720p then
        // 480p compatibility ladder instead of treating it as a dead server.
        final connectionFailed = failureKind == 'network' ||
            failureKind == 'http' ||
            failureKind == 'initialization';
        final fallback = playbackFallback(mode, failureKind);
        if (fallback != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(mode == PlaybackMode.direct
                ? 'Direct play failed; retrying compatible 720p…'
                : '720p failed; retrying 480p safe mode…'),
          ));
          await Future<void>.delayed(const Duration(milliseconds: 500));
          if (context.mounted) {
            await play(context, item, fallback,
                mediaIndex: selectedIndex,
                audioTrackId: audioTrackId,
                subtitleTrackId: subtitleTrackId);
          }
          return;
        }
        final retry = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
                  title: Text(connectionFailed
                      ? 'Player connection failed'
                      : failureKind == 'startup_timeout'
                          ? 'Video could not start'
                          : 'Playback failed'),
                  content: SingleChildScrollView(
                      child: Text(
                          '${compact(caught)}\n\nThe Status screen contains the connection details.')),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Close')),
                    ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context, true),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'))
                  ],
                ));
        if (retry == true && context.mounted) {
          await play(context, item, mode,
              mediaIndex: selectedIndex,
              audioTrackId: audioTrackId,
              subtitleTrackId: subtitleTrackId);
        }
      }
    } finally {
      if (activeRequest != null) {
        unawaited(api!.stopPlaybackSession(activeRequest));
      }
    }
  }

  Future<bool> _showPlayNextCountdown(
      BuildContext context, PlexMedia next) async {
    final seconds = settings.playNextCountdownSeconds;
    if (seconds <= 0) return true;
    var remaining = seconds;
    Timer? timer;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          timer ??= Timer.periodic(const Duration(seconds: 1), (value) {
            remaining--;
            if (remaining <= 0) {
              value.cancel();
              if (dialogContext.mounted) Navigator.pop(dialogContext, true);
            } else if (dialogContext.mounted) {
              setState(() {});
            }
          });
          return AlertDialog(
            title: const Text('Playing next episode'),
            content: Text('${next.title}\n\nStarting in $remaining seconds.'),
            actions: <Widget>[
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Play now')),
            ],
          );
        },
      ),
    );
    timer?.cancel();
    return result == true;
  }

  void _updateLocalProgress(String ratingKey, int position) {
    PlexMedia update(PlexMedia item) => item.ratingKey == ratingKey
        ? item.copyWith(viewOffsetMs: position)
        : item;
    shelves = shelves
        .map((shelf) => PlexShelf(
            title: shelf.title, items: shelf.items.map(update).toList()))
        .toList();
    libraryItems = libraryItems.map(update).toList();
    searchResults = searchResults.map(update).toList();
  }

  void fail(String prefix, Object value) {
    error = message(prefix, value);
    logs.add(error!);
    phase = AppPhase.error;
    notifySafely();
  }

  String message(String prefix, Object value) {
    if (value is DioException && value.response?.statusCode == 401) {
      return '$prefix: Plex rejected the account or server token (HTTP 401).';
    }
    if (value is DioException && !clockValid) {
      return '$prefix: secure HTTPS cannot work while the car clock is incorrect.';
    }
    return '$prefix: ${compact(value)}';
  }

  static String compact(Object value) =>
      value.toString().replaceFirst(RegExp(r'^(Exception|StateError):\s*'), '');

  void notifySafely() {
    if (!disposed) notifyListeners();
  }

  @override
  void dispose() {
    disposed = true;
    authGeneration++;
    contentGeneration++;
    searchGeneration++;
    periodicRefresh?.cancel();
    logs.dispose();
    super.dispose();
  }
}

class GkuiRoot extends StatefulWidget {
  const GkuiRoot({super.key});
  @override
  State<GkuiRoot> createState() => _GkuiRootState();
}

class _GkuiRootState extends State<GkuiRoot> with WidgetsBindingObserver {
  final GkuiController controller = GkuiController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller.initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(controller.reconnectAfterResume());
    }
  }

  @override
  void didHaveMemoryPressure() {
    controller.handleMemoryPressure();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          if (controller.phase == AppPhase.starting) {
            return const BusyScreen(label: 'Starting Plezy GKUI…');
          }
          if (!controller.clockValid)
            return ClockScreen(controller: controller);
          if (controller.phase == AppPhase.signedOut ||
              controller.phase == AppPhase.error) {
            return WelcomeScreen(controller: controller);
          }
          if (controller.phase == AppPhase.signingIn)
            return PinScreen(controller: controller);
          if (controller.phase == AppPhase.chooseServer)
            return ServerScreen(controller: controller);
          return GkuiShell(controller: controller);
        },
      );
}

class BusyScreen extends StatelessWidget {
  const BusyScreen({required this.label, super.key});
  final String label;
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          const CircularProgressIndicator(),
          const SizedBox(height: 22),
          Text(label, style: const TextStyle(fontSize: 22)),
        ])),
      );
}

class ClockScreen extends StatelessWidget {
  const ClockScreen({required this.controller, super.key});
  final GkuiController controller;
  @override
  Widget build(BuildContext context) => CenteredPanel(
        icon: Icons.schedule,
        title: 'Car clock needs to sync',
        message:
            'This unit reports ${DateTime.now().year}. Secure Plex HTTPS requires the correct date. '
            'Connect the car to Wi-Fi or 4G, let its clock update, then tap Retry. TLS security will not be disabled.',
        error: controller.error,
        primaryLabel: 'Retry clock',
        primaryAction: controller.retryClock,
      );
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({required this.controller, super.key});
  final GkuiController controller;
  @override
  Widget build(BuildContext context) => CenteredPanel(
        icon: Icons.play_circle_fill,
        title: 'Plezy GKUI',
        message:
            'Sign in with Plex to browse your server and play video. Scan the QR code with your phone to approve this car display.',
        error: controller.error,
        primaryLabel: 'Sign in to Plex',
        primaryAction: controller.beginSignIn,
        secondaryLabel: controller.api?.session == null ? null : 'Retry server',
        secondaryAction:
            controller.api?.session == null ? null : controller.refreshContent,
      );
}

class CenteredPanel extends StatelessWidget {
  const CenteredPanel({
    required this.icon,
    required this.title,
    required this.message,
    required this.error,
    required this.primaryLabel,
    required this.primaryAction,
    this.secondaryLabel,
    this.secondaryAction,
    super.key,
  });
  final IconData icon;
  final String title;
  final String message;
  final String? error;
  final String primaryLabel;
  final FutureOr<void> Function() primaryAction;
  final String? secondaryLabel;
  final FutureOr<void> Function()? secondaryAction;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
            child: Center(
                child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Card(
              margin: const EdgeInsets.all(28),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 38, vertical: 26),
                child:
                    Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                  Icon(icon, size: 60, color: const Color(0xFFE5A00D)),
                  const SizedBox(height: 10),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 30, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Text(message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, height: 1.35)),
                  if (error != null) ...<Widget>[
                    const SizedBox(height: 12),
                    Text(error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Color(0xFFFF8A80), fontSize: 16)),
                  ],
                  const SizedBox(height: 20),
                  Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                    ElevatedButton(
                        onPressed: primaryAction,
                        child: Text(primaryLabel,
                            style: const TextStyle(fontSize: 18))),
                    if (secondaryAction != null) ...<Widget>[
                      const SizedBox(width: 14),
                      OutlinedButton(
                          onPressed: secondaryAction,
                          child: Text(secondaryLabel!,
                              style: const TextStyle(fontSize: 18))),
                    ],
                  ]),
                ]),
              )),
        ))),
      );
}

class PinScreen extends StatelessWidget {
  const PinScreen({required this.controller, super.key});
  final GkuiController controller;
  @override
  Widget build(BuildContext context) {
    final pin = controller.pin!;
    return Scaffold(body: SafeArea(child: LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 1000 || constraints.maxHeight < 600;
        final qrSize = compact ? 220.0 : 285.0;
        final inset = compact ? 22.0 : 34.0;
        return Row(children: <Widget>[
          Expanded(
              child: Padding(
            padding: EdgeInsets.all(inset),
            child: Center(
                child: SingleChildScrollView(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Sign in to Plex',
                        style: TextStyle(
                            fontSize: compact ? 28 : 32,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Text(
                        'Scan with your phone, approve Plezy GKUI, and leave this screen open.',
                        style: TextStyle(
                            fontSize: compact ? 17 : 20, height: 1.3)),
                    const SizedBox(height: 12),
                    Text('Code: ${pin.code}',
                        style: TextStyle(
                            fontSize: compact ? 23 : 27,
                            color: const Color(0xFFE5A00D),
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    const Row(children: <Widget>[
                      SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(strokeWidth: 3)),
                      SizedBox(width: 12),
                      Expanded(
                          child: Text('Waiting for approval…',
                              style: TextStyle(fontSize: 17))),
                    ]),
                    const SizedBox(height: 14),
                    OutlinedButton(
                        onPressed: controller.cancelSignIn,
                        child: const Text('Cancel',
                            style: TextStyle(fontSize: 17))),
                  ]),
            )),
          )),
          Container(
            color: Colors.white,
            margin: EdgeInsets.all(compact ? 16 : 24),
            padding: EdgeInsets.all(compact ? 12 : 16),
            child: QrImageView(
                data: pin.authUrl(controller.api!.clientIdentifier),
                size: qrSize),
          ),
        ]);
      },
    )));
  }
}

class ServerScreen extends StatelessWidget {
  const ServerScreen({required this.controller, super.key});
  final GkuiController controller;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Choose a Plex server')),
        body: ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: controller.servers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final server = controller.servers[index];
            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              tileColor: const Color(0xFF1D1D1D),
              leading: const Icon(Icons.dns, size: 38),
              title: Text(server.name, style: const TextStyle(fontSize: 22)),
              subtitle: Text('${server.connections.length} secure route(s)'),
              trailing: const Icon(Icons.chevron_right, size: 36),
              onTap: () => controller.chooseServer(server),
            );
          },
        ),
      );
}

class GkuiShell extends StatefulWidget {
  const GkuiShell({required this.controller, super.key});
  final GkuiController controller;
  @override
  State<GkuiShell> createState() => _GkuiShellState();
}

class _GkuiShellState extends State<GkuiShell> {
  int selected = 0;
  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomePane(controller: widget.controller),
      LibraryPane(controller: widget.controller),
      SearchPane(controller: widget.controller),
      SettingsPane(controller: widget.controller),
      DiagnosticsPane(
          logs: widget.controller.logs, controller: widget.controller),
    ];
    return Scaffold(
        body: SafeArea(
            child: Row(children: <Widget>[
      Container(
          width: 96,
          color: const Color(0xFF121212),
          child: NavigationRail(
            backgroundColor: Colors.transparent,
            selectedIndex: selected,
            labelType: NavigationRailLabelType.all,
            minWidth: 92,
            onDestinationSelected: (value) => setState(() => selected = value),
            leading: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: Image.asset('assets/plezy.png', width: 45, height: 45)),
            destinations: const <NavigationRailDestination>[
              NavigationRailDestination(
                  icon: Icon(Icons.home_outlined, size: 29),
                  selectedIcon: Icon(Icons.home, size: 31),
                  label: Text('Home')),
              NavigationRailDestination(
                  icon: Icon(Icons.video_library_outlined, size: 29),
                  selectedIcon: Icon(Icons.video_library, size: 31),
                  label: Text('Library')),
              NavigationRailDestination(
                  icon: Icon(Icons.search, size: 29),
                  selectedIcon: Icon(Icons.manage_search, size: 31),
                  label: Text('Search')),
              NavigationRailDestination(
                  icon: Icon(Icons.tune, size: 29),
                  selectedIcon: Icon(Icons.tune, size: 31),
                  label: Text('Settings')),
              NavigationRailDestination(
                  icon: Icon(Icons.monitor_heart_outlined, size: 29),
                  selectedIcon: Icon(Icons.monitor_heart, size: 31),
                  label: Text('Status')),
            ],
          )),
      const VerticalDivider(width: 1),
      Expanded(child: pages[selected]),
    ])));
  }
}

class HomePane extends StatelessWidget {
  const HomePane({required this.controller, super.key});
  final GkuiController controller;
  @override
  Widget build(BuildContext context) {
    if (controller.loadingContent && controller.shelves.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: () => controller.refreshContent(includeLibrary: false),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 30),
        children: <Widget>[
          Row(children: <Widget>[
            Expanded(
                child: PageHeading(
                    title: controller.api!.session!.serverName,
                    subtitle:
                        '${controller.currentHomeUser?.displayName ?? controller.api!.currentHomeUserName ?? 'Plex Home'} • pull down to refresh')),
            ElevatedButton.icon(
                onPressed: controller.switchingProfile
                    ? null
                    : () => _showProfiles(context),
                icon: const Icon(Icons.switch_account),
                label: const Text('Profiles')),
          ]),
          if (controller.error != null) ErrorBanner(controller.error!),
          const SizedBox(height: 18),
          if (controller.shelves.isEmpty)
            const Padding(
                padding: EdgeInsets.all(30),
                child: Center(
                    child: Text('No home items returned by this server.',
                        style: TextStyle(fontSize: 19))))
          else
            for (final shelf in controller.shelves) ...<Widget>[
              MediaShelf(shelf: shelf, controller: controller),
              const SizedBox(height: 24),
            ],
        ],
      ),
    );
  }

  Future<void> _showProfiles(BuildContext context) async {
    await controller.loadHomeUsers();
    if (!context.mounted) return;
    if (controller.homeUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No Plex Home profiles returned.')));
      return;
    }
    final user = await showDialog<PlexHomeUser>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Switch Plex Home profile'),
        content: SizedBox(
          width: 520,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: controller.homeUsers.length,
            itemBuilder: (_, index) {
              final item = controller.homeUsers[index];
              final current = item.uuid == controller.currentHomeUser?.uuid;
              return ListTile(
                leading: Icon(item.guest ? Icons.person_outline : Icons.person),
                title: Text(item.displayName),
                subtitle: Text(item.admin
                    ? 'Home owner'
                    : item.guest
                        ? 'Guest'
                        : 'Managed user'),
                trailing: current
                    ? const Icon(Icons.check, color: Color(0xFFE5A00D))
                    : item.protected
                        ? const Icon(Icons.lock_outline)
                        : null,
                onTap: current ? null : () => Navigator.pop(context, item),
              );
            },
          ),
        ),
      ),
    );
    if (user == null || !context.mounted) return;
    String? pin;
    if (user.protected) {
      final field = TextEditingController();
      pin = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('PIN for ${user.displayName}'),
          content: TextField(
            controller: field,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: const InputDecoration(labelText: 'Plex Home PIN'),
          ),
          actions: <Widget>[
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, field.text),
                child: const Text('Switch')),
          ],
        ),
      );
      field.dispose();
      if (pin == null) return;
    }
    try {
      await controller.switchProfile(user, pin: pin);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(controller.error ?? 'Profile switch failed.')));
      }
    }
  }
}

class LibraryPane extends StatelessWidget {
  const LibraryPane({required this.controller, super.key});
  final GkuiController controller;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 10),
            child: PageHeading(
                title: 'Library',
                subtitle: controller.selectedSection?.title ??
                    'No Plex libraries found')),
        SizedBox(
            height: 54,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              scrollDirection: Axis.horizontal,
              itemCount: controller.sections.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final section = controller.sections[index];
                return ChoiceChip(
                  label:
                      Text(section.title, style: const TextStyle(fontSize: 17)),
                  selected: section.key == controller.selectedSection?.key,
                  onSelected: (_) => controller.selectSection(section),
                );
              },
            )),
        SizedBox(
            height: 48,
            child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                scrollDirection: Axis.horizontal,
                children: <Widget>[
                  ChoiceChip(
                      label: const Text('All'),
                      selected: controller.libraryView == LibraryView.all,
                      onSelected: (_) =>
                          controller.selectLibraryView(LibraryView.all)),
                  const SizedBox(width: 10),
                  ChoiceChip(
                      label: const Text('Unwatched'),
                      selected: controller.libraryView == LibraryView.unwatched,
                      onSelected: (_) =>
                          controller.selectLibraryView(LibraryView.unwatched)),
                  const SizedBox(width: 10),
                  ChoiceChip(
                      label: const Text('Collections'),
                      selected:
                          controller.libraryView == LibraryView.collections,
                      onSelected: (_) => controller
                          .selectLibraryView(LibraryView.collections)),
                ])),
        if (controller.error != null) ErrorBanner(controller.error!),
        Expanded(
            child: controller.loadingContent
                ? const Center(child: CircularProgressIndicator())
                : NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification.metrics.extentAfter < 500) {
                        unawaited(controller.loadMoreLibrary());
                      }
                      return false;
                    },
                    child: GridView.builder(
                      padding: const EdgeInsets.all(24),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 170,
                        childAspectRatio: 0.66,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 20,
                      ),
                      itemCount: controller.libraryItems.length +
                          (controller.loadingMoreLibrary ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= controller.libraryItems.length) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        return MediaCard(
                            media: controller.libraryItems[index],
                            controller: controller);
                      },
                    ),
                  )),
      ]);
}

class SearchPane extends StatefulWidget {
  const SearchPane({required this.controller, super.key});
  final GkuiController controller;

  @override
  State<SearchPane> createState() => _SearchPaneState();
}

class _SearchPaneState extends State<SearchPane> {
  late final TextEditingController field =
      TextEditingController(text: widget.controller.searchQuery);

  @override
  void dispose() {
    field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 18, 24, 12),
            child: PageHeading(
                title: 'Search', subtitle: 'Find movies, shows and episodes'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(children: <Widget>[
              Expanded(
                child: TextField(
                  controller: field,
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(fontSize: 19),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search this Plex server',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: widget.controller.runSearch,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: widget.controller.searching
                    ? null
                    : () => widget.controller.runSearch(field.text),
                icon: const Icon(Icons.search),
                label: const Text('Search'),
              ),
            ]),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              scrollDirection: Axis.horizontal,
              children: SearchMediaFilter.values
                  .map((filter) => Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: ChoiceChip(
                          label: Text(switch (filter) {
                            SearchMediaFilter.all => 'All',
                            SearchMediaFilter.movie => 'Movies',
                            SearchMediaFilter.show => 'Shows',
                            SearchMediaFilter.episode => 'Episodes',
                          }),
                          selected: widget.controller.searchFilter == filter,
                          onSelected: (_) =>
                              widget.controller.setSearchFilter(filter),
                        ),
                      ))
                  .toList(),
            ),
          ),
          if (widget.controller.error != null)
            ErrorBanner(widget.controller.error!),
          Expanded(
            child: widget.controller.searching
                ? const Center(child: CircularProgressIndicator())
                : widget.controller.searchResults.isEmpty
                    ? Center(
                        child: Text(
                          widget.controller.searchQuery.isEmpty
                              ? 'Enter at least two characters.'
                              : 'No matching Plex items.',
                          style: const TextStyle(
                              fontSize: 18, color: Colors.white70),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(24),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 170,
                          childAspectRatio: 0.66,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 20,
                        ),
                        itemCount: widget.controller.searchResults.length,
                        itemBuilder: (context, index) => MediaCard(
                          media: widget.controller.searchResults[index],
                          controller: widget.controller,
                        ),
                      ),
          ),
        ],
      );
}

class SettingsPane extends StatelessWidget {
  const SettingsPane({required this.controller, super.key});
  final GkuiController controller;

  static const languages = <String, String>{
    '': 'Automatic',
    'en': 'English',
    'ja': 'Japanese',
    'zh': 'Chinese',
    'ms': 'Malay',
  };

  static const subtitleLanguages = <String, String>{
    '': 'Automatic',
    'off': 'Off',
    'en': 'English',
    'ja': 'Japanese',
    'zh': 'Chinese',
    'ms': 'Malay',
  };

  @override
  Widget build(BuildContext context) {
    final value = controller.settings;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 30),
      children: <Widget>[
        const PageHeading(
            title: 'Playback settings',
            subtitle: 'Remembered for this head unit'),
        const SizedBox(height: 18),
        _SettingCard(
          title: 'Preferred audio',
          child: DropdownButton<String>(
            isExpanded: true,
            value: value.audioLanguage,
            items: languages.entries
                .map((entry) => DropdownMenuItem<String>(
                    value: entry.key, child: Text(entry.value)))
                .toList(),
            onChanged: (choice) => controller
                .updateSettings(value.copyWith(audioLanguage: choice ?? '')),
          ),
        ),
        _SettingCard(
          title: 'Preferred subtitles',
          child: DropdownButton<String>(
            isExpanded: true,
            value: value.subtitleLanguage,
            items: subtitleLanguages.entries
                .map((entry) => DropdownMenuItem<String>(
                    value: entry.key, child: Text(entry.value)))
                .toList(),
            onChanged: (choice) => controller
                .updateSettings(value.copyWith(subtitleLanguage: choice ?? '')),
          ),
        ),
        _SettingCard(
          title: 'Seek buttons',
          child: Wrap(spacing: 18, runSpacing: 8, children: <Widget>[
            _SecondsPicker(
              label: 'Back',
              value: value.seekBackSeconds,
              onChanged: (seconds) => controller
                  .updateSettings(value.copyWith(seekBackSeconds: seconds)),
            ),
            _SecondsPicker(
              label: 'Forward',
              value: value.seekForwardSeconds,
              onChanged: (seconds) => controller
                  .updateSettings(value.copyWith(seekForwardSeconds: seconds)),
            ),
          ]),
        ),
        SwitchListTile(
          title: const Text('Autoplay next episode',
              style: TextStyle(fontSize: 18)),
          subtitle: const Text('Continue automatically after an episode ends'),
          value: value.autoPlayNext,
          onChanged: (enabled) =>
              controller.updateSettings(value.copyWith(autoPlayNext: enabled)),
        ),
        _SettingCard(
          title: 'Skip intro / credits',
          child: DropdownButton<SkipMode>(
            isExpanded: true,
            value: value.skipMode,
            items: const <DropdownMenuItem<SkipMode>>[
              DropdownMenuItem(value: SkipMode.off, child: Text('Off')),
              DropdownMenuItem(
                  value: SkipMode.button, child: Text('Show a skip button')),
              DropdownMenuItem(
                  value: SkipMode.automatic, child: Text('Skip automatically')),
            ],
            onChanged: (choice) {
              if (choice != null) {
                controller.updateSettings(value.copyWith(skipMode: choice));
              }
            },
          ),
        ),
        _SettingCard(
          title: 'Play Next countdown',
          child: DropdownButton<int>(
            isExpanded: true,
            value: value.playNextCountdownSeconds,
            items: const <int>[0, 5, 10, 15, 30]
                .map((seconds) => DropdownMenuItem<int>(
                      value: seconds,
                      child: Text(
                          seconds == 0 ? 'Immediately' : '$seconds seconds'),
                    ))
                .toList(),
            onChanged: (seconds) {
              if (seconds != null) {
                controller.updateSettings(
                    value.copyWith(playNextCountdownSeconds: seconds));
              }
            },
          ),
        ),
        SwitchListTile(
          title: const Text('Show watched indicators',
              style: TextStyle(fontSize: 18)),
          subtitle: const Text('Display a check mark on watched titles'),
          value: value.showWatchedIndicators,
          onChanged: (enabled) => controller
              .updateSettings(value.copyWith(showWatchedIndicators: enabled)),
        ),
      ],
    );
  }
}

class _SettingCard extends StatelessWidget {
  const _SettingCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(children: <Widget>[
            SizedBox(
                width: 190,
                child: Text(title, style: const TextStyle(fontSize: 18))),
            Expanded(child: child),
          ]),
        ),
      );
}

class _SecondsPicker extends StatelessWidget {
  const _SecondsPicker(
      {required this.label, required this.value, required this.onChanged});
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('$label:', style: const TextStyle(fontSize: 17)),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: value,
            items: const <int>[5, 10, 15, 30, 60]
                .map((seconds) => DropdownMenuItem<int>(
                    value: seconds, child: Text('$seconds sec')))
                .toList(),
            onChanged: (seconds) {
              if (seconds != null) onChanged(seconds);
            },
          ),
        ],
      );
}

class MediaShelf extends StatelessWidget {
  const MediaShelf({required this.shelf, required this.controller, super.key});
  final PlexShelf shelf;
  final GkuiController controller;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Text(shelf.title,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        SizedBox(
            height: 222,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: shelf.items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) => SizedBox(
                  width: 128,
                  child: MediaCard(
                      media: shelf.items[index], controller: controller)),
            )),
      ]);
}

class MediaCard extends StatelessWidget {
  const MediaCard({required this.media, required this.controller, super.key});
  final PlexMedia media;
  final GkuiController controller;
  @override
  Widget build(BuildContext context) {
    final image = controller.api!.imageUrl(media.thumb);
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => DetailsScreen(media: media, controller: controller))),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Stack(fit: StackFit.expand, children: <Widget>[
                  Container(
                    color: const Color(0xFF272727),
                    width: double.infinity,
                    child: image == null
                        ? const Icon(Icons.movie_outlined,
                            size: 48, color: Colors.white38)
                        : CachedNetworkImage(
                            imageUrl: image,
                            httpHeaders: controller.api!.imageHeaders,
                            fit: BoxFit.cover,
                            memCacheWidth: 260,
                            maxWidthDiskCache: 320,
                            fadeInDuration: Duration.zero,
                            placeholder: (_, __) => const Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)),
                            errorWidget: (_, __, ___) => const Icon(
                                Icons.broken_image_outlined,
                                size: 44,
                                color: Colors.white38),
                          ),
                  ),
                  if (controller.settings.showWatchedIndicators &&
                      media.watched)
                    const Positioned(
                      top: 7,
                      right: 7,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                            color: Color(0xFFE5A00D), shape: BoxShape.circle),
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child:
                              Icon(Icons.check, size: 18, color: Colors.black),
                        ),
                      ),
                    ),
                ]),
              ),
            ),
            const SizedBox(height: 6),
            Text(media.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15)),
            if (media.viewOffsetMs > 0 && media.durationMs > 0)
              LinearProgressIndicator(
                  value:
                      (media.viewOffsetMs / media.durationMs).clamp(0.0, 1.0),
                  minHeight: 3),
          ]),
    );
  }
}

class DetailsScreen extends StatefulWidget {
  const DetailsScreen(
      {required this.media, required this.controller, super.key});
  final PlexMedia media;
  final GkuiController controller;
  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  Future<List<PlexMedia>>? children;
  Future<PlexMedia>? details;
  int? selectedMediaIndex;
  String? selectedAudioTrackId;
  String? selectedSubtitleTrackId;

  @override
  void initState() {
    super.initState();
    children = widget.media.children
        ? widget.controller.api!.loadChildren(widget.media)
        : null;
    if (children == null) {
      details = widget.controller.api!
          .loadMetadata(widget.media.ratingKey)
          .then((item) {
        final remembered = widget.controller.api!.loadPlaybackChoice(item);
        selectedMediaIndex ??= remembered.mediaIndex != null &&
                item.versions
                    .any((version) => version.index == remembered.mediaIndex)
            ? remembered.mediaIndex
            : PlexMediaVersion.preferredIndex(item.versions);
        selectedAudioTrackId ??= remembered.audioTrackId;
        selectedSubtitleTrackId ??= remembered.subtitleTrackId;
        if (widget.controller.settings.skipMode != SkipMode.off) {
          unawaited(widget.controller.api!
              .loadMarkers(item.ratingKey)
              .catchError((Object _) => const <PlexMarker>[]));
        }
        return item;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.media;
    final image = widget.controller.api!
        .imageUrl(media.art ?? media.thumb, width: 900, height: 500);
    return Scaffold(
      appBar: AppBar(title: Text(media.title)),
      body: Stack(fit: StackFit.expand, children: <Widget>[
        if (image != null)
          Opacity(
              opacity: 0.18,
              child: CachedNetworkImage(
                imageUrl: image,
                httpHeaders: widget.controller.api!.imageHeaders,
                fit: BoxFit.cover,
                memCacheWidth: 900,
              )),
        Container(color: Colors.black.withOpacity(0.38)),
        Padding(
            padding: const EdgeInsets.all(26),
            child: children == null
                ? FutureBuilder<PlexMedia>(
                    future: details,
                    initialData: media,
                    builder: (context, snapshot) =>
                        playableDetails(snapshot.data ?? media),
                  )
                : childrenList(media)),
      ]),
    );
  }

  Widget playableDetails(PlexMedia media) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        SizedBox(
            width: 210,
            child: MediaCard(media: media, controller: widget.controller)),
        const SizedBox(width: 28),
        Expanded(
            child: ListView(children: <Widget>[
          Text(media.title,
              style:
                  const TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
              <String>[
                if (media.year != null) '${media.year}',
                if (media.subtitle != null) media.subtitle!
              ].join(' • '),
              style: const TextStyle(fontSize: 18, color: Colors.white70)),
          const SizedBox(height: 14),
          Text(media.summary ?? 'No summary available.',
              style: const TextStyle(fontSize: 17, height: 1.4)),
          const SizedBox(height: 22),
          if (media.versions.length > 1) ...<Widget>[
            OutlinedButton.icon(
              onPressed: () => chooseVersion(media),
              icon: const Icon(Icons.video_settings),
              label: Text('Version: ${selectedVersionLabel(media)}'),
            ),
            const SizedBox(height: 12),
          ],
          if (currentVersion(media) case final version?) ...<Widget>[
            Text('Selected media: ${version.displayLabel}',
                style: const TextStyle(fontSize: 16, color: Colors.white70)),
            const SizedBox(height: 10),
            Wrap(spacing: 12, runSpacing: 10, children: <Widget>[
              if (version.audioTracks.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => chooseAudioTrack(media),
                  icon: const Icon(Icons.audiotrack),
                  label: Text('Audio: ${selectedAudioLabel(media)}'),
                ),
              if (version.subtitleTracks.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => chooseSubtitleTrack(media),
                  icon: const Icon(Icons.subtitles),
                  label: Text('Subtitles: ${selectedSubtitleLabel(media)}'),
                ),
            ]),
            const SizedBox(height: 14),
          ],
          Wrap(spacing: 12, runSpacing: 12, children: <Widget>[
            ElevatedButton.icon(
              onPressed: () => widget.controller.play(
                  context, media, PlaybackMode.direct,
                  mediaIndex: requestedMediaIndex(media),
                  audioTrackId: selectedAudioTrackId,
                  subtitleTrackId: selectedSubtitleTrackId),
              icon: const Icon(Icons.play_arrow),
              label: Text(media.viewOffsetMs > 0 ? 'Resume' : 'Play'),
            ),
            OutlinedButton(
              onPressed: () => widget.controller.play(
                  context, media, PlaybackMode.transcode720,
                  mediaIndex: requestedMediaIndex(media),
                  audioTrackId: selectedAudioTrackId,
                  subtitleTrackId: selectedSubtitleTrackId),
              child: const Text('720p compatible'),
            ),
            OutlinedButton(
              onPressed: () => widget.controller.play(
                  context, media, PlaybackMode.transcode480,
                  mediaIndex: requestedMediaIndex(media),
                  audioTrackId: selectedAudioTrackId,
                  subtitleTrackId: selectedSubtitleTrackId),
              child: const Text('480p safe mode'),
            ),
          ]),
        ])),
      ]);

  int selectedIndex(PlexMedia media) =>
      selectedMediaIndex ?? PlexMediaVersion.preferredIndex(media.versions);

  int? requestedMediaIndex(PlexMedia media) =>
      media.versions.isEmpty ? null : selectedIndex(media);

  String selectedVersionLabel(PlexMedia media) {
    final index = selectedIndex(media);
    for (final version in media.versions) {
      if (version.index == index) return version.displayLabel;
    }
    return 'Original';
  }

  PlexMediaVersion? currentVersion(PlexMedia media) {
    final index = selectedIndex(media);
    for (final version in media.versions) {
      if (version.index == index) return version;
    }
    return null;
  }

  String selectedAudioLabel(PlexMedia media) {
    final tracks = currentVersion(media)?.audioTracks ?? const <PlexTrack>[];
    final selected =
        tracks.where((track) => track.id == selectedAudioTrackId).firstOrNull;
    return selected?.displayLabel ??
        tracks.where((track) => track.selected).firstOrNull?.displayLabel ??
        'Automatic';
  }

  String selectedSubtitleLabel(PlexMedia media) {
    if (selectedSubtitleTrackId == 'off') return 'Off';
    final tracks = currentVersion(media)?.subtitleTracks ?? const <PlexTrack>[];
    final selected = tracks
        .where((track) => track.id == selectedSubtitleTrackId)
        .firstOrNull;
    return selected?.displayLabel ??
        tracks.where((track) => track.selected).firstOrNull?.displayLabel ??
        'Automatic';
  }

  Future<void> chooseVersion(PlexMedia media) async {
    final choice = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choose video version'),
        children: media.versions
            .map((version) => RadioListTile<int>(
                  value: version.index,
                  groupValue: selectedIndex(media),
                  title: Text(version.displayLabel,
                      style: const TextStyle(fontSize: 18)),
                  subtitle: version.index ==
                          PlexMediaVersion.preferredIndex(media.versions)
                      ? const Text('Recommended for this head unit')
                      : null,
                  onChanged: (value) => Navigator.pop(context, value),
                ))
            .toList(),
      ),
    );
    if (choice != null && mounted) {
      setState(() {
        selectedMediaIndex = choice;
        selectedAudioTrackId = null;
        selectedSubtitleTrackId = null;
      });
    }
  }

  Future<void> chooseAudioTrack(PlexMedia media) async {
    final tracks = currentVersion(media)?.audioTracks ?? const <PlexTrack>[];
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choose audio track'),
        children: <Widget>[
          RadioListTile<String>(
            value: '',
            groupValue: selectedAudioTrackId ?? '',
            title: const Text('Automatic'),
            onChanged: (value) => Navigator.pop(context, value),
          ),
          ...tracks.map((track) => RadioListTile<String>(
                value: track.id,
                groupValue: selectedAudioTrackId ?? '',
                title: Text(track.displayLabel),
                onChanged: (value) => Navigator.pop(context, value),
              )),
        ],
      ),
    );
    if (choice != null && mounted) {
      setState(() => selectedAudioTrackId = choice.isEmpty ? null : choice);
    }
  }

  Future<void> chooseSubtitleTrack(PlexMedia media) async {
    final tracks = currentVersion(media)?.subtitleTracks ?? const <PlexTrack>[];
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choose subtitles'),
        children: <Widget>[
          RadioListTile<String>(
            value: '',
            groupValue: selectedSubtitleTrackId ?? '',
            title: const Text('Automatic'),
            onChanged: (value) => Navigator.pop(context, value),
          ),
          RadioListTile<String>(
            value: 'off',
            groupValue: selectedSubtitleTrackId ?? '',
            title: const Text('Off'),
            onChanged: (value) => Navigator.pop(context, value),
          ),
          ...tracks.map((track) => RadioListTile<String>(
                value: track.id,
                groupValue: selectedSubtitleTrackId ?? '',
                title: Text(track.displayLabel),
                onChanged: (value) => Navigator.pop(context, value),
              )),
        ],
      ),
    );
    if (choice != null && mounted) {
      setState(() => selectedSubtitleTrackId = choice.isEmpty ? null : choice);
    }
  }

  Widget childrenList(PlexMedia media) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Text(media.title,
            style: const TextStyle(fontSize: 29, fontWeight: FontWeight.w700)),
        if (media.summary != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: Text(media.summary!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16)),
          ),
        Expanded(
            child: FutureBuilder<List<PlexMedia>>(
          future: children,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError)
              return Center(
                  child: Text('Could not load items: ${snapshot.error}'));
            final items = snapshot.data ?? const <PlexMedia>[];
            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 175,
                childAspectRatio: 0.68,
                crossAxisSpacing: 16,
                mainAxisSpacing: 18,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) =>
                  MediaCard(media: items[index], controller: widget.controller),
            );
          },
        )),
      ]);
}

class PageHeading extends StatelessWidget {
  const PageHeading({required this.title, required this.subtitle, super.key});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Text(title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
        const SizedBox(height: 3),
        Text(subtitle,
            style: const TextStyle(fontSize: 16, color: Colors.white70)),
      ]);
}

class ErrorBanner extends StatelessWidget {
  const ErrorBanner(this.message, {super.key});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
        padding: const EdgeInsets.all(12),
        color: const Color(0xFF5A2020),
        child: Text(message),
      );
}

class DiagnosticsPane extends StatefulWidget {
  const DiagnosticsPane(
      {required this.logs, required this.controller, super.key});
  final RedactingLogStore logs;
  final GkuiController controller;
  @override
  State<DiagnosticsPane> createState() => _DiagnosticsPaneState();
}

class _DiagnosticsPaneState extends State<DiagnosticsPane> {
  late Future<DeviceDiagnostics> diagnostics = DeviceDiagnostics.load();

  Future<void> copyDiagnostics() async {
    final snapshot = await diagnostics;
    final details = snapshot.values.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join('\n');
    await Clipboard.setData(ClipboardData(
        text:
            '$buildLabel\n$sourceLabel\n$toolchainLabel\n$details\n\n${widget.logs.exportText()}'));
    widget.logs.add('Diagnostics copied to clipboard.');
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(children: <Widget>[
                const Expanded(
                    child: PageHeading(
                        title: 'Device status',
                        subtitle: 'Plex, player, memory and redacted logs')),
                ElevatedButton.icon(
                  onPressed: () =>
                      setState(() => diagnostics = DeviceDiagnostics.load()),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                    onPressed: copyDiagnostics,
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy')),
                const SizedBox(width: 8),
                OutlinedButton(
                    onPressed: widget.controller.signOut,
                    child: const Text('Sign out')),
              ]),
              const SizedBox(height: 12),
              Expanded(
                  child: Row(children: <Widget>[
                Expanded(
                    child: Card(
                        child: FutureBuilder<DeviceDiagnostics>(
                  future: diagnostics,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());
                    final rows = <MapEntry<String, String>>[
                      const MapEntry<String, String>('build', buildLabel),
                      const MapEntry<String, String>('source', sourceLabel),
                      const MapEntry<String, String>(
                          'toolchain', toolchainLabel),
                      MapEntry<String, String>(
                          'server',
                          widget.controller.api?.session?.serverName ??
                              'not connected'),
                      ...snapshot.data!.values.entries,
                      MapEntry<String, String>(
                          'endpoint',
                          widget.controller.api?.safeEndpoint ??
                              'not connected'),
                      MapEntry<String, String>(
                          'profile',
                          widget.controller.currentHomeUser?.displayName ??
                              widget.controller.api?.currentHomeUserName ??
                              'Plex account'),
                      MapEntry<String, String>(
                          'media version',
                          widget.controller.lastSelectedVersion ??
                              'not played yet'),
                      MapEntry<String, String>(
                          'content startup',
                          widget.controller.lastContentLoadMs == null
                              ? 'not measured'
                              : '${widget.controller.lastContentLoadMs} ms'),
                      MapEntry<String, String>(
                          'first frame',
                          widget.controller.lastFirstFrameMs == null
                              ? 'not measured'
                              : '${widget.controller.lastFirstFrameMs} ms'),
                      MapEntry<String, String>('decoder',
                          widget.controller.lastDecoder ?? 'not reported'),
                      MapEntry<String, String>('video format',
                          widget.controller.lastVideoFormat ?? 'not reported'),
                    ];
                    return ListView.separated(
                      padding: const EdgeInsets.all(14),
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => const Divider(height: 12),
                      itemBuilder: (_, index) => Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            SizedBox(
                                width: 125,
                                child: Text(rows[index].key,
                                    style: const TextStyle(
                                        color: Colors.white60))),
                            Expanded(
                                child: SelectableText(rows[index].value,
                                    style: const TextStyle(fontSize: 15))),
                          ]),
                    );
                  },
                ))),
                const SizedBox(width: 14),
                Expanded(
                    child: Card(
                        child: AnimatedBuilder(
                  animation: widget.logs,
                  builder: (_, __) => ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: widget.logs.entries.length,
                    itemBuilder: (_, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SelectableText(widget.logs.entries[index].line,
                          style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: Colors.white70)),
                    ),
                  ),
                ))),
              ])),
            ]),
      );
}
