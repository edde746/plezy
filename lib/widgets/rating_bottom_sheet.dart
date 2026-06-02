import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../focus/dpad_navigator.dart';
import '../focus/focusable_wrapper.dart';
import '../focus/input_mode_tracker.dart';
import '../i18n/strings.g.dart';
import '../media/media_backend.dart';
import '../media/media_item.dart';
import '../media/media_server_client.dart';
import '../providers/trackers_provider.dart';
import '../providers/trakt_account_provider.dart';
import '../services/trackers/anilist/anilist_tracker.dart';
import '../services/trackers/mal/mal_tracker.dart';
import '../services/trackers/simkl/simkl_tracker.dart';
import '../services/trackers/tracker.dart';
import '../services/trackers/tracker_constants.dart';
import '../services/trackers/tracker_id_resolver.dart';
import '../services/trakt/trakt_scrobble_service.dart';
import '../utils/app_logger.dart';
import '../utils/snackbar_helper.dart';
import 'app_icon.dart';
import 'backend_badge.dart';
import 'bottom_sheet_header.dart';
import 'clickable_cursor.dart';

class RatingBottomSheet extends StatefulWidget {
  final MediaItem item;
  final MediaServerClient? serverClient;
  final ValueChanged<double>? onServerRatingChanged;

  const RatingBottomSheet({super.key, required this.item, required this.serverClient, this.onServerRatingChanged});

  @override
  State<RatingBottomSheet> createState() => _RatingBottomSheetState();
}

class _RatingBottomSheetState extends State<RatingBottomSheet> {
  static const _autoSaveDelay = Duration(milliseconds: 600);

  late double _serverStars;
  late double _serverRating;
  late bool? _serverLike;
  late final FocusNode _serverFocusNode;

  final Map<TrackerService, int> _trackerScores = {};
  final Map<TrackerService, FocusNode> _trackerFocusNodes = {};
  final Map<String, Timer> _autoSaveTimers = {};
  final Map<String, _TrackerRatingSource> _trackerSourcesByKey = {};
  final Set<String> _pendingAutoSaves = {};
  final Set<TrackerService> _hiddenTrackers = {};
  final Set<String> _loading = {};
  final Map<String, _SectionStatus> _statuses = {};
  TrackerIdResolver? _resolver;
  bool _resolverNeedsFribb = false;
  String? _trackerLoadKey;

  @override
  void initState() {
    super.initState();
    _serverFocusNode = FocusNode(debugLabel: 'rating_server');
    final rawServerRating = widget.item.userRating;
    _serverRating = rawServerRating != null && rawServerRating > 0 ? rawServerRating : 0.0;
    _serverStars = _serverRating > 0 ? _serverRating / 2.0 : 0.0;
    _serverLike = rawServerRating == null ? null : rawServerRating >= 6.0;
  }

  @override
  void dispose() {
    _flushPendingAutoSavesOnDispose();
    _serverFocusNode.dispose();
    for (final node in _trackerFocusNodes.values) {
      node.dispose();
    }
    _resolver?.clearCache();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final maxHeight = size.height * (size.width > 600 ? 0.64 : 0.74);

    return Consumer2<TraktAccountProvider, TrackersProvider>(
      builder: (context, trakt, trackers, _) {
        final allTrackerSources = _trackerSources(trakt, trackers);
        final trackerSources = allTrackerSources.where((source) => !_hiddenTrackers.contains(source.service)).toList();
        _updateTrackerSourceMap(trackerSources);
        _resolverNeedsFribb = trackers.isMalConnected || trackers.isAnilistConnected;
        _queueTrackerScoreLoad(allTrackerSources);

        final focusNodes = <FocusNode>[
          if (widget.serverClient != null) _serverFocusNode,
          for (final source in trackerSources) _trackerFocusNode(source.service),
        ];
        var focusIndex = 0;

        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: .min,
            children: [
              BottomSheetHeader(title: t.rateSheet.title, icon: Symbols.star_rounded),
              Flexible(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 12),
                  children: [
                    if (widget.serverClient != null)
                      _buildServerRow(
                        widget.serverClient!,
                        _serverFocusNode,
                        autofocus: focusIndex == 0,
                        onNavigateUp: _navTo(focusNodes, focusIndex - 1),
                        onNavigateDown: _navTo(focusNodes, focusIndex++ + 1),
                      ),
                    for (final source in trackerSources)
                      _buildTrackerRow(
                        source,
                        _trackerFocusNode(source.service),
                        autofocus: focusIndex == 0,
                        onNavigateUp: _navTo(focusNodes, focusIndex - 1),
                        onNavigateDown: _navTo(focusNodes, focusIndex++ + 1),
                      ),
                    if (allTrackerSources.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                        child: Text(
                          t.rateSheet.noConnectedTrackers,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildServerRow(
    MediaServerClient client,
    FocusNode focusNode, {
    required bool autofocus,
    required VoidCallback? onNavigateUp,
    required VoidCallback? onNavigateDown,
  }) {
    final loading = _loading.contains(_serverKey);
    final status = _statuses[_serverKey];
    final subtitle =
        '${_backendLabel(client.backend)} - ${client.serverName ?? widget.item.serverName ?? t.common.unknown}';

    if (client.capabilities.numericUserRating) {
      final value = (_serverStars * 2).round().clamp(0, 10).toInt();
      return _RatingRow(
        focusNode: focusNode,
        autofocus: autofocus,
        leading: BackendBadge(backend: client.backend, size: 22),
        title: t.rateSheet.server,
        subtitle: subtitle,
        loading: loading,
        status: status,
        enabled: !loading,
        onNavigateUp: onNavigateUp,
        onNavigateDown: onNavigateDown,
        onDecrease: () => _setServerStarUnits(value - 1),
        onIncrease: () => _setServerStarUnits(value + 1),
        onSubmit: () => unawaited(_submitServerStars()),
        control: _StarRatingControl(
          value: value,
          enabled: !loading,
          onChanged: _setServerStarUnits,
          onSubmitValue: (units) => unawaited(_submitServerStars(stars: units / 2.0)),
        ),
      );
    }

    final value = switch (_serverLike) {
      null => 0,
      false => 1,
      true => 2,
    };
    return _RatingRow(
      focusNode: focusNode,
      autofocus: autofocus,
      leading: BackendBadge(backend: client.backend, size: 22),
      title: t.rateSheet.server,
      subtitle: subtitle,
      loading: loading,
      status: status,
      enabled: !loading,
      onNavigateUp: onNavigateUp,
      onNavigateDown: onNavigateDown,
      onDecrease: () => _setServerLikeValue(value - 1),
      onIncrease: () => _setServerLikeValue(value + 1),
      onSubmit: () => unawaited(_submitServerLike()),
      control: _BinaryControl(
        value: value,
        enabled: !loading,
        onChanged: _setServerLikeValue,
        onSubmitValue: (next) => unawaited(_submitServerLike(value: _likeFromIndex(next))),
      ),
    );
  }

  Widget _buildTrackerRow(
    _TrackerRatingSource source,
    FocusNode focusNode, {
    required bool autofocus,
    required VoidCallback? onNavigateUp,
    required VoidCallback? onNavigateDown,
  }) {
    final key = source.service.name;
    final loading = _loading.contains(key);
    final status = _statuses[key];
    final score = _trackerScores[source.service] ?? 0;
    return _RatingRow(
      focusNode: focusNode,
      autofocus: autofocus,
      leading: _TrackerLogo(source.logoAsset),
      title: source.title,
      subtitle: source.username != null ? t.trackers.connectedAs(username: source.username!) : source.connectedLabel,
      loading: loading,
      status: status,
      enabled: !loading,
      onNavigateUp: onNavigateUp,
      onNavigateDown: onNavigateDown,
      onDecrease: () => _setTrackerScore(source, score - 1),
      onIncrease: () => _setTrackerScore(source, score + 1),
      onSubmit: () => unawaited(_submitTrackerRating(source)),
      control: _StarRatingControl(
        value: score,
        enabled: !loading,
        onChanged: (value) => _setTrackerScore(source, value),
        onSubmitValue: (value) => unawaited(_submitTrackerRating(source, score: value)),
      ),
    );
  }

  List<_TrackerRatingSource> _trackerSources(TraktAccountProvider trakt, TrackersProvider trackers) {
    final sources = <_TrackerRatingSource>[];
    if (trakt.isConnected) {
      sources.add(
        _TrackerRatingSource(
          service: TrackerService.trakt,
          title: t.trakt.title,
          username: trakt.username,
          connectedLabel: t.trakt.connected,
          logoAsset: 'assets/trakt_circlemark.svg',
          getRating: TraktScrobbleService.instance.getRating,
          onRate: TraktScrobbleService.instance.rate,
          onClear: TraktScrobbleService.instance.clearRating,
        ),
      );
    }
    if (trackers.isMalConnected) {
      sources.add(
        _TrackerRatingSource(
          service: TrackerService.mal,
          title: t.trackers.services.mal,
          username: trackers.malUsername,
          connectedLabel: t.trakt.connected,
          logoAsset: 'assets/mal_mark.svg',
          getRating: MalTracker.instance.getRating,
          onRate: MalTracker.instance.rate,
          onClear: MalTracker.instance.clearRating,
        ),
      );
    }
    if (trackers.isAnilistConnected) {
      sources.add(
        _TrackerRatingSource(
          service: TrackerService.anilist,
          title: t.trackers.services.anilist,
          username: trackers.anilistUsername,
          connectedLabel: t.trakt.connected,
          logoAsset: 'assets/anilist_mark.svg',
          getRating: AnilistTracker.instance.getRating,
          onRate: AnilistTracker.instance.rate,
          onClear: AnilistTracker.instance.clearRating,
        ),
      );
    }
    if (trackers.isSimklConnected) {
      sources.add(
        _TrackerRatingSource(
          service: TrackerService.simkl,
          title: t.trackers.services.simkl,
          username: trackers.simklUsername,
          connectedLabel: t.trakt.connected,
          logoAsset: 'assets/simkl_mark.svg',
          getRating: SimklTracker.instance.getRating,
          onRate: SimklTracker.instance.rate,
          onClear: SimklTracker.instance.clearRating,
        ),
      );
    }
    return sources;
  }

  void _updateTrackerSourceMap(List<_TrackerRatingSource> sources) {
    _trackerSourcesByKey
      ..clear()
      ..addEntries(sources.map((source) => MapEntry(source.service.name, source)));
  }

  void _queueTrackerScoreLoad(List<_TrackerRatingSource> sources) {
    final services = sources.map((s) => s.service.name).join(',');
    final key = '${widget.serverClient?.serverId}:${widget.item.id}:$services';
    if (_trackerLoadKey == key) return;
    _trackerLoadKey = key;
    if (sources.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _trackerLoadKey != key) return;
      unawaited(_loadTrackerScores(sources));
    });
  }

  Future<void> _loadTrackerScores(List<_TrackerRatingSource> sources) async {
    setState(() {
      for (final source in sources) {
        _loading.add(source.service.name);
        _statuses.remove(source.service.name);
      }
    });

    TrackerRatingContext ctx;
    try {
      ctx = await _resolveTrackerContext();
    } on TrackerRatingUnavailableException {
      if (!mounted) return;
      setState(() {
        for (final source in sources) {
          if (_hidesWhenUnavailable(source)) {
            _hideTrackerSource(source);
          } else {
            _loading.remove(source.service.name);
            _statuses[source.service.name] = _SectionStatus(t.rateSheet.notAvailable, isError: true);
          }
        }
      });
      return;
    }

    await Future.wait(
      sources.map((source) async {
        final key = source.service.name;
        try {
          final score = await source.getRating(ctx);
          if (!mounted) return;
          setState(() {
            _trackerScores[source.service] = score ?? 0;
            _statuses.remove(key);
          });
        } on TrackerRatingUnavailableException catch (e) {
          appLogger.d('Rating unavailable', error: e);
          if (!mounted) return;
          if (_hidesWhenUnavailable(source)) {
            setState(() {
              _hideTrackerSource(source);
            });
            return;
          }
          setState(() {
            _statuses[key] = _SectionStatus(t.rateSheet.notAvailable, isError: true);
          });
        } catch (e) {
          appLogger.w('Failed to load rating', error: e);
          if (!mounted) return;
          setState(() {
            _statuses[key] = _SectionStatus(t.errors.failedToRate, isError: true);
          });
        } finally {
          if (mounted) {
            setState(() {
              _loading.remove(key);
            });
          }
        }
      }),
    );
  }

  bool _hidesWhenUnavailable(_TrackerRatingSource source) {
    return source.service == TrackerService.mal || source.service == TrackerService.anilist;
  }

  void _hideTrackerSource(_TrackerRatingSource source) {
    final key = source.service.name;
    _hiddenTrackers.add(source.service);
    _loading.remove(key);
    _statuses.remove(key);
    _trackerScores.remove(source.service);
    _autoSaveTimers.remove(key)?.cancel();
    _pendingAutoSaves.remove(key);
    _trackerSourcesByKey.remove(key);
  }

  void _setServerStarUnits(int units) {
    final clamped = units.clamp(0, 10).toInt();
    if ((_serverStars * 2).round() == clamped) return;
    setState(() {
      _serverStars = clamped / 2.0;
      _statuses.remove(_serverKey);
    });
    _scheduleAutoSave(_serverKey, _submitServerStars);
  }

  void _setServerLikeValue(int value) {
    final clamped = value.clamp(0, 2).toInt();
    final next = _likeFromIndex(clamped);
    if (_serverLike == next) return;
    setState(() {
      _serverLike = next;
      _statuses.remove(_serverKey);
    });
    _scheduleAutoSave(_serverKey, _submitServerLike);
  }

  bool? _likeFromIndex(int value) => switch (value.clamp(0, 2).toInt()) {
    0 => null,
    1 => false,
    _ => true,
  };

  void _setTrackerScore(_TrackerRatingSource source, int score) {
    final clamped = score.clamp(0, 10).toInt();
    if ((_trackerScores[source.service] ?? 0) == clamped) return;
    setState(() {
      _trackerScores[source.service] = clamped;
      _statuses.remove(source.service.name);
    });
    _scheduleAutoSave(source.service.name, () => _submitTrackerRating(source));
  }

  Future<void> _submitServerStars({double? stars}) async {
    _cancelAutoSave(_serverKey);
    final value = stars ?? _serverStars;
    if (value <= 0) {
      await _clearServerRating();
      return;
    }

    final rating = value * 2.0;
    await _run(_serverKey, () async {
      await widget.serverClient!.rate(widget.item, rating);
      _serverRating = rating;
      _serverStars = value;
      widget.onServerRatingChanged?.call(rating);
    });
  }

  Future<void> _clearServerRating() async {
    _cancelAutoSave(_serverKey);
    await _run(_serverKey, () async {
      await widget.serverClient!.rate(widget.item, -1);
      _serverRating = 0;
      _serverStars = 0;
      _serverLike = null;
      widget.onServerRatingChanged?.call(0);
    });
  }

  Future<void> _submitServerLike({bool? value}) async {
    _cancelAutoSave(_serverKey);
    final selected = value ?? _serverLike;
    if (selected == null) {
      await _clearServerRating();
      return;
    }

    final rating = selected ? 10.0 : 0.0;
    await _run(_serverKey, () async {
      await widget.serverClient!.rate(widget.item, rating);
      _serverLike = selected;
      _serverRating = rating;
      widget.onServerRatingChanged?.call(_serverRating);
    });
  }

  Future<void> _submitTrackerRating(_TrackerRatingSource source, {int? score}) async {
    _cancelAutoSave(source.service.name);
    final value = score ?? _trackerScores[source.service] ?? 0;
    if (value <= 0) {
      await _clearTrackerRating(source);
      return;
    }
    await _run(source.service.name, () async {
      final ctx = await _resolveTrackerContext();
      await source.onRate(ctx, value);
      _trackerScores[source.service] = value;
    });
  }

  Future<void> _clearTrackerRating(_TrackerRatingSource source) async {
    _cancelAutoSave(source.service.name);
    await _run(source.service.name, () async {
      final ctx = await _resolveTrackerContext();
      await source.onClear(ctx);
      _trackerScores[source.service] = 0;
    });
  }

  Future<TrackerRatingContext> _resolveTrackerContext() async {
    final client = widget.serverClient;
    if (client == null) throw const TrackerRatingUnavailableException('tracker');
    _resolver ??= TrackerIdResolver(client, needsFribb: () => _resolverNeedsFribb);
    final ctx = await _resolver!.resolveForRating(widget.item);
    if (ctx == null) throw const TrackerRatingUnavailableException('tracker');
    return ctx;
  }

  Future<void> _run(String key, Future<void> Function() action) async {
    setState(() {
      _loading.add(key);
      _statuses.remove(key);
    });

    try {
      await action();
      if (!mounted) return;
      setState(() {
        _statuses[key] = _SectionStatus(t.rateSheet.saved);
      });
    } on TrackerRatingUnavailableException catch (e) {
      appLogger.d('Rating unavailable', error: e);
      if (!mounted) return;
      setState(() {
        _statuses[key] = _SectionStatus(t.rateSheet.notAvailable, isError: true);
      });
    } catch (e) {
      appLogger.w('Failed to update rating', error: e);
      if (!mounted) return;
      setState(() {
        _statuses[key] = _SectionStatus(t.errors.failedToRate, isError: true);
      });
      showErrorSnackBar(context, t.errors.failedToRate);
    } finally {
      if (mounted) {
        setState(() {
          _loading.remove(key);
        });
      }
    }
  }

  void _scheduleAutoSave(String key, Future<void> Function() submit) {
    _pendingAutoSaves.add(key);
    _autoSaveTimers.remove(key)?.cancel();
    _autoSaveTimers[key] = Timer(_autoSaveDelay, () {
      _autoSaveTimers.remove(key);
      _pendingAutoSaves.remove(key);
      unawaited(submit());
    });
  }

  void _cancelAutoSave(String key) {
    _autoSaveTimers.remove(key)?.cancel();
    _pendingAutoSaves.remove(key);
  }

  void _flushPendingAutoSavesOnDispose() {
    final pendingKeys = Set<String>.from(_pendingAutoSaves);
    for (final key in pendingKeys) {
      _autoSaveTimers.remove(key)?.cancel();
    }
    _pendingAutoSaves.clear();

    for (final key in pendingKeys) {
      if (key == _serverKey) {
        unawaited(_saveServerRatingDetached());
        continue;
      }
      final source = _trackerSourcesByKey[key];
      if (source != null) unawaited(_saveTrackerRatingDetached(source));
    }
  }

  Future<void> _saveServerRatingDetached() async {
    final client = widget.serverClient;
    if (client == null) return;

    try {
      if (client.capabilities.numericUserRating) {
        final rating = _serverStars <= 0 ? -1.0 : _serverStars * 2.0;
        await client.rate(widget.item, rating);
        widget.onServerRatingChanged?.call(rating < 0 ? 0 : rating);
        return;
      }

      final selected = _serverLike;
      final rating = selected == null ? -1.0 : (selected ? 10.0 : 0.0);
      await client.rate(widget.item, rating);
      widget.onServerRatingChanged?.call(rating < 0 ? 0 : rating);
    } catch (e) {
      appLogger.w('Failed to update rating after sheet close', error: e);
    }
  }

  Future<void> _saveTrackerRatingDetached(_TrackerRatingSource source) async {
    try {
      final ctx = await _resolveTrackerContext();
      final value = _trackerScores[source.service] ?? 0;
      if (value <= 0) {
        await source.onClear(ctx);
      } else {
        await source.onRate(ctx, value);
      }
    } catch (e) {
      appLogger.w('Failed to update tracker rating after sheet close', error: e);
    }
  }

  FocusNode _trackerFocusNode(TrackerService service) {
    return _trackerFocusNodes.putIfAbsent(service, () => FocusNode(debugLabel: 'rating_${service.name}'));
  }

  VoidCallback? _navTo(List<FocusNode> nodes, int index) {
    if (index < 0 || index >= nodes.length) return null;
    return () => nodes[index].requestFocus();
  }

  String _backendLabel(MediaBackend backend) => switch (backend) {
    MediaBackend.plex => 'Plex',
    MediaBackend.jellyfin => 'Jellyfin',
  };
}

const _serverKey = 'server';

class _TrackerRatingSource {
  final TrackerService service;
  final String title;
  final String? username;
  final String connectedLabel;
  final String logoAsset;
  final Future<int?> Function(TrackerRatingContext ctx) getRating;
  final Future<void> Function(TrackerRatingContext ctx, int score) onRate;
  final Future<void> Function(TrackerRatingContext ctx) onClear;

  const _TrackerRatingSource({
    required this.service,
    required this.title,
    required this.username,
    required this.connectedLabel,
    required this.logoAsset,
    required this.getRating,
    required this.onRate,
    required this.onClear,
  });
}

class _SectionStatus {
  final String text;
  final bool isError;

  const _SectionStatus(this.text, {this.isError = false});
}

class _RatingRow extends StatelessWidget {
  final FocusNode focusNode;
  final bool autofocus;
  final Widget leading;
  final String title;
  final String subtitle;
  final bool loading;
  final _SectionStatus? status;
  final bool enabled;
  final VoidCallback? onNavigateUp;
  final VoidCallback? onNavigateDown;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onSubmit;
  final Widget control;

  const _RatingRow({
    required this.focusNode,
    required this.autofocus,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.loading,
    required this.status,
    required this.enabled,
    required this.onNavigateUp,
    required this.onNavigateDown,
    required this.onDecrease,
    required this.onIncrease,
    required this.onSubmit,
    required this.control,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = this.status;
    final statusText = status?.isError == true ? status!.text : subtitle;
    final statusColor = status?.isError == true ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant;
    final controlWidth = MediaQuery.sizeOf(context).width < 390 ? 124.0 : 142.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: FocusableWrapper(
        focusNode: focusNode,
        autofocus: autofocus && InputModeTracker.isKeyboardMode(context),
        borderRadius: 12,
        autoScroll: true,
        disableScale: true,
        useBackgroundFocus: true,
        descendantsAreFocusable: false,
        onSelect: enabled ? onSubmit : null,
        onNavigateUp: onNavigateUp,
        onNavigateDown: onNavigateDown,
        onKeyEvent: (_, event) {
          if (!enabled || !event.isActionable) return KeyEventResult.ignored;
          final key = event.logicalKey;
          if (key.isLeftKey) {
            onDecrease();
            return KeyEventResult.handled;
          }
          if (key.isRightKey) {
            onIncrease();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Row(
            children: [
              SizedBox(width: 24, height: 24, child: Center(child: leading)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: .min,
                  crossAxisAlignment: .start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: .w700)),
                    Text(
                      statusText,
                      style: theme.textTheme.bodySmall?.copyWith(color: statusColor),
                      maxLines: 1,
                      overflow: .ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(width: controlWidth, child: control),
              const SizedBox(width: 8),
              SizedBox(
                width: 18,
                height: 18,
                child: _TrailingStatus(loading: loading, status: status),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrailingStatus extends StatelessWidget {
  final bool loading;
  final _SectionStatus? status;

  const _TrailingStatus({required this.loading, required this.status});

  @override
  Widget build(BuildContext context) {
    if (loading) return const CircularProgressIndicator(strokeWidth: 2);
    final status = this.status;
    if (status == null) return const SizedBox.shrink();
    final color = status.isError ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary;
    return Tooltip(
      message: status.text,
      child: AppIcon(
        status.isError ? Symbols.error_rounded : Symbols.check_circle_rounded,
        fill: 1,
        color: color,
        size: 18,
      ),
    );
  }
}

class _StarRatingControl extends StatefulWidget {
  final int value;
  final bool enabled;
  final ValueChanged<int> onChanged;
  final ValueChanged<int> onSubmitValue;

  const _StarRatingControl({
    required this.value,
    required this.enabled,
    required this.onChanged,
    required this.onSubmitValue,
  });

  @override
  State<_StarRatingControl> createState() => _StarRatingControlState();
}

class _StarRatingControlState extends State<_StarRatingControl> {
  int? _pointerValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final starWidth = (constraints.maxWidth / 5).clamp(0.0, 27.0).toDouble();
        final iconSize = (starWidth * 0.9).clamp(0.0, 24.0).toDouble();
        return ClickableCursor(
          enabled: widget.enabled,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: widget.enabled ? (details) => _setFromDx(details.localPosition.dx, constraints.maxWidth) : null,
            onTapUp: widget.enabled ? (_) => widget.onSubmitValue(_pointerValue ?? widget.value) : null,
            onPanUpdate: widget.enabled
                ? (details) => _setFromDx(details.localPosition.dx, constraints.maxWidth)
                : null,
            onPanEnd: widget.enabled ? (_) => widget.onSubmitValue(_pointerValue ?? widget.value) : null,
            child: SizedBox(
              height: 34,
              child: Row(
                mainAxisAlignment: .end,
                children: List.generate(5, (i) {
                  final threshold = (i + 1) * 2;
                  final filled = widget.value >= threshold;
                  final half = widget.value == threshold - 1;
                  return SizedBox(
                    width: starWidth,
                    child: Center(
                      child: AppIcon(
                        half ? Symbols.star_half_rounded : Symbols.star_rounded,
                        fill: filled || half ? 1 : 0,
                        color: filled || half
                            ? Colors.amber
                            : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.34),
                        size: iconSize,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }

  void _setFromDx(double dx, double width) {
    final safeWidth = width <= 0 ? 1.0 : width;
    final value = ((dx.clamp(0.0, safeWidth) / safeWidth) * 10).round().clamp(0, 10).toInt();
    _pointerValue = value;
    widget.onChanged(value);
  }
}

class _BinaryControl extends StatelessWidget {
  final int value;
  final bool enabled;
  final ValueChanged<int> onChanged;
  final ValueChanged<int> onSubmitValue;

  const _BinaryControl({
    required this.value,
    required this.enabled,
    required this.onChanged,
    required this.onSubmitValue,
  });

  @override
  Widget build(BuildContext context) {
    final label = switch (value) {
      0 => t.rateSheet.notRated,
      1 => t.rateSheet.notLiked,
      _ => t.rateSheet.liked,
    };
    return _StepperPill(
      label: label,
      enabled: enabled,
      onDecrease: () => onChanged((value - 1).clamp(0, 2).toInt()),
      onIncrease: () => onChanged((value + 1).clamp(0, 2).toInt()),
      onSubmit: () => onSubmitValue(value),
    );
  }
}

class _StepperPill extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onSubmit;

  const _StepperPill({
    required this.label,
    required this.enabled,
    required this.onDecrease,
    required this.onIncrease,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.54),
        borderRadius: const BorderRadius.all(Radius.circular(100)),
      ),
      child: Row(
        children: [
          _arrow(context, Symbols.chevron_left_rounded, onDecrease),
          Expanded(
            child: ClickableCursor(
              enabled: enabled,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: enabled ? onSubmit : null,
                child: Center(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: .ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(fontWeight: .w700),
                  ),
                ),
              ),
            ),
          ),
          _arrow(context, Symbols.chevron_right_rounded, onIncrease),
        ],
      ),
    );
  }

  Widget _arrow(BuildContext context, IconData icon, VoidCallback action) {
    final theme = Theme.of(context);
    return ClickableCursor(
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? action : null,
        child: SizedBox(
          width: 30,
          height: 32,
          child: Center(
            child: AppIcon(
              icon,
              fill: 1,
              color: enabled ? theme.colorScheme.onSurfaceVariant : theme.disabledColor,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _TrackerLogo extends StatelessWidget {
  final String asset;

  const _TrackerLogo(this.asset);

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color ?? Theme.of(context).colorScheme.onSurface;
    return SvgPicture.asset(asset, width: 24, height: 24, theme: SvgTheme(currentColor: color));
  }
}
