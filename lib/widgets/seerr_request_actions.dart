import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../i18n/strings.g.dart';
import '../media/media_kind.dart';
import '../models/catalog/catalog_item.dart';
import '../models/seerr/seerr_request.dart';
import '../providers/catalog_sources_provider.dart';
import '../providers/explore_provider.dart';
import '../services/catalog/seerr_catalog_source.dart';
import '../services/catalog/seerr_requests.dart';
import '../services/seerr/seerr_exceptions.dart';
import '../utils/app_logger.dart';
import '../utils/dialogs.dart';
import '../utils/snackbar_helper.dart';
import 'app_menu.dart';

/// One destructive thing the signed-in user may do about a title's Seerr
/// requests. Built only for actions the user's permissions allow — see
/// [seerrRequestActions] — and always confirmed before it runs.
sealed class SeerrRequestAction {
  const SeerrRequestAction();

  String get label;

  /// Tells apart several requests for one title (variant, seasons, status).
  String? get subtitle => null;

  IconData get icon;
}

/// Withdraw one request (`DELETE /request/{id}`). Downloaded files stay.
class SeerrDeleteRequestAction extends SeerrRequestAction {
  final SeerrRequest request;
  final SeerrRequestBadge badge;

  /// Who asked for it, when that is someone other than the signed-in user —
  /// a manager's menu can hold several people's requests for one title.
  final String? requester;

  const SeerrDeleteRequestAction(this.request, {required this.badge, this.requester});

  @override
  String get label => t.seerr.requests.deleteRequest;

  @override
  String? get subtitle => [
    seerrRequestBadgeLabel(badge),
    ?requester,
    if (request.is4k ?? false) '4K',
    if (request.seasons case final seasons? when seasons.isNotEmpty)
      t.seerr.requests.seasonsList(seasons: ([for (final s in seasons) s.seasonNumber]..sort()).join(', ')),
  ].join(' · ');

  @override
  IconData get icon => Symbols.delete_rounded;
}

/// Remove the title from Sonarr/Radarr **including its files** and clear
/// Seerr's record of it.
class SeerrRemoveCompletelyAction extends SeerrRequestAction {
  /// Seerr's media id.
  final int mediaId;
  final MediaKind kind;

  /// The variants whose files go: false = regular, true = 4K.
  final Set<bool> variants;

  const SeerrRemoveCompletelyAction({required this.mediaId, required this.kind, required this.variants});

  /// The service the files are removed from, naming the variants when it is
  /// not just the regular one.
  String get service {
    final name = kind == MediaKind.movie ? 'Radarr' : 'Sonarr';
    if (variants.length > 1) return t.seerr.requests.serviceBoth(service: name);
    return variants.contains(true) ? t.seerr.requests.service4k(service: name) : name;
  }

  @override
  String get label => t.seerr.requests.removeCompletely;

  @override
  String? get subtitle => service;

  @override
  IconData get icon => Symbols.delete_forever_rounded;
}

/// The localized name of a request badge, reusing the catalog card wording.
String seerrRequestBadgeLabel(SeerrRequestBadge badge) => switch (badge) {
  SeerrRequestBadge.pending => t.explore.badge.pendingApproval,
  SeerrRequestBadge.approved => t.seerr.requests.statusApproved,
  SeerrRequestBadge.processing => t.explore.badge.processing,
  SeerrRequestBadge.partiallyAvailable => t.explore.badge.partiallyAvailable,
  SeerrRequestBadge.available => t.explore.badge.available,
  SeerrRequestBadge.declined => t.explore.badge.declined,
  SeerrRequestBadge.failed => t.explore.badge.requestFailed,
};

/// Every action the signed-in user may take on [title], read from the
/// source's live permission mask. Empty when there is nothing to offer.
List<SeerrRequestAction> seerrRequestActions(SeerrCatalogSource source, SeerrTitleRequests title, MediaKind kind) {
  final requests = source.requests;
  final product = source.client.session.product;
  final removable = requests.removableVariants(title);
  return [
    for (final request in title.requests)
      if (requests.canDeleteRequest(request))
        // Detail bodies nest requests without their media; the badge needs it
        // to tell an approved request from an available one.
        SeerrDeleteRequestAction(
          request,
          badge: SeerrRequests.badgeFor(_withMedia(request, title), product),
          requester: request.requestedBy?.id == source.client.session.userId
              ? null
              : _nonBlank(request.requestedBy?.displayName),
        ),
    if (removable.isNotEmpty) SeerrRemoveCompletelyAction(mediaId: title.media!.id!, kind: kind, variants: removable),
  ];
}

String? _nonBlank(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

SeerrRequest _withMedia(SeerrRequest request, SeerrTitleRequests title) => request.media != null || title.media == null
    ? request
    : SeerrRequest(
        id: request.id,
        status: request.status,
        is4k: request.is4k,
        media: title.media,
        seasons: request.seasons,
        type: request.type,
        requestedBy: request.requestedBy,
        createdAt: request.createdAt,
        canRemove: request.canRemove,
      );

/// Menu rows for [actions], styled as destructive.
List<AppMenuEntry<SeerrRequestAction>> seerrRequestActionEntries(List<SeerrRequestAction> actions) => [
  for (final action in actions)
    AppMenuItem<SeerrRequestAction>(
      value: action,
      label: action.label,
      subtitle: action.subtitle,
      icon: action.icon,
      destructive: true,
    ),
];

/// What a catalog card's context menu may do about [item]'s requests: the
/// actions for what the last read said Seerr holds for it. Nothing when
/// Seerr is not connected, the item has no TMDB id, or no read has covered
/// the title yet (its detail page loads that state).
({SeerrCatalogSource source, List<SeerrRequestAction> actions})? seerrRequestMenuActions(
  BuildContext context,
  CatalogItem item,
) {
  final source = Provider.of<CatalogSourcesProvider?>(context, listen: false)?.seerrSource;
  final tmdbId = item.ids.tmdb;
  if (source == null || tmdbId == null) return null;
  final title = source.requests.known(item.kind, tmdbId);
  if (title == null) return null;
  final actions = seerrRequestActions(source, title, item.kind);
  return actions.isEmpty ? null : (source: source, actions: actions);
}

/// Let the user pick one of [actions] from a menu, then confirm and run it.
/// [anchor] places the menu on pointer platforms. Returns true when Seerr
/// was changed.
Future<bool> showSeerrRequestActionsMenu(
  BuildContext context, {
  required SeerrCatalogSource source,
  required List<SeerrRequestAction> actions,
  required String title,
  BuildContext? anchor,
}) async {
  if (actions.isEmpty) return false;
  final renderBox = (anchor ?? context).findRenderObject();
  final anchorRect = renderBox is RenderBox && renderBox.hasSize
      ? renderBox.localToGlobal(Offset.zero) & renderBox.size
      : Rect.zero;
  final action = await showAdaptiveAppMenu<SeerrRequestAction>(
    context,
    title: title,
    anchorRect: anchorRect,
    focusFirstItem: true,
    entries: seerrRequestActionEntries(actions),
  );
  if (action == null || !context.mounted) return false;
  return runSeerrRequestAction(context, source: source, action: action, title: title);
}

/// Confirm [action], run it and report the outcome in a snackbar. Returns
/// true when Seerr was changed.
///
/// Both confirmations open with Cancel focused, so a stray SELECT on a TV
/// remote never deletes anything. The complete removal additionally spells
/// out, in a warning block, that files on disk are deleted for good.
///
/// Seerr is the authority on permissions: a refusal arrives as
/// [SeerrPermissionException] after the client has already adopted the
/// current permission mask, so the surfaces that offered the action re-gate
/// themselves; here it only needs reporting.
Future<bool> runSeerrRequestAction(
  BuildContext context, {
  required SeerrCatalogSource source,
  required SeerrRequestAction action,
  required String title,
}) async {
  final strings = t.seerr.requests;
  final confirmed = await switch (action) {
    SeerrDeleteRequestAction() => showConfirmDialog(
      context,
      title: strings.deleteRequestTitle,
      message: strings.deleteRequestBody(title: title),
      confirmText: strings.deleteRequest,
      isDestructive: true,
    ),
    SeerrRemoveCompletelyAction() => showConfirmDialog(
      context,
      title: strings.removeCompletelyTitle(title: title),
      message: strings.removeCompletelyBody(title: title, service: action.service),
      warning: strings.removeCompletelyWarning(title: title),
      confirmText: strings.removeCompletely,
      isDestructive: true,
    ),
  };
  if (!confirmed || !context.mounted) return false;

  // Captured before the call: the surface that opened this may be gone by
  // the time Seerr answers, and the Explore shelf still has to follow.
  final explore = Provider.of<ExploreProvider?>(context, listen: false);
  final requests = source.requests;
  String failure;
  try {
    switch (action) {
      case SeerrDeleteRequestAction(:final request):
        await requests.deleteRequest(request);
      case SeerrRemoveCompletelyAction(:final mediaId, :final variants):
        await requests.removeCompletely(mediaId: mediaId, variants: variants);
    }
    if (explore != null) unawaited(explore.load());
    if (context.mounted) {
      showSuccessSnackBar(context, switch (action) {
        SeerrDeleteRequestAction() => strings.requestDeleted,
        SeerrRemoveCompletelyAction() => strings.removedCompletely(title: title),
      });
    }
    return true;
  } on SeerrPermissionException catch (e) {
    failure = e.display;
  } on SeerrProxyException catch (e) {
    failure = e.display;
  } on SeerrAuthException catch (e) {
    failure = e.display ?? strings.actionFailed(error: e.message);
  } on SeerrApiException catch (e) {
    // Seerr answered but refused or failed (request already gone, no
    // Sonarr/Radarr instance configured): its state may differ from what the
    // shelf shows, so let the shelf re-read too.
    if (explore != null) unawaited(explore.load());
    failure = strings.actionFailed(error: e.message);
  } catch (e) {
    appLogger.w('Seerr: request action failed', error: e);
    failure = strings.actionFailed(error: '$e');
  }
  if (context.mounted) showErrorSnackBar(context, failure);
  return false;
}

/// Tracks what Seerr holds for one title so a detail page can offer the
/// request actions, and re-reads it whenever a request is mutated anywhere.
///
/// [bind] is cheap to call on every build: it only acts when the source or
/// title changed. Listeners fire when [actions] may have changed; [onMutated]
/// fires when a mutation went through the bound source, so the host can
/// refresh whatever else it shows from Seerr.
class SeerrTitleRequestsController extends ChangeNotifier {
  SeerrTitleRequestsController({this.onMutated});

  final VoidCallback? onMutated;

  SeerrCatalogSource? _source;
  MediaKind? _kind;
  int? _tmdbId;
  SeerrTitleRequests? _title;
  int _generation = 0;
  bool _disposed = false;

  SeerrCatalogSource? get source => _source;

  void bind(SeerrCatalogSource? source, MediaKind kind, int? tmdbId) {
    if (identical(source, _source) && kind == _kind && tmdbId == _tmdbId) return;
    _source?.requests.removeListener(_onRequestsChanged);
    _source = source;
    _kind = kind;
    _tmdbId = tmdbId;
    _title = null;
    _generation++;
    source?.requests.addListener(_onRequestsChanged);
    unawaited(_load());
  }

  /// The actions the signed-in user may take right now. Re-derived on every
  /// read so a permission change adopted by the client applies at once.
  List<SeerrRequestAction> get actions {
    final source = _source;
    final kind = _kind;
    final title = _title;
    if (source == null || kind == null || title == null) return const [];
    return seerrRequestActions(source, title, kind);
  }

  bool get hasActions => actions.isNotEmpty;

  void _onRequestsChanged() {
    unawaited(_load());
    onMutated?.call();
  }

  Future<void> _load() async {
    final source = _source;
    final kind = _kind;
    final tmdbId = _tmdbId;
    if (source == null || kind == null || tmdbId == null) return;
    final generation = _generation;
    SeerrTitleRequests? title;
    try {
      final media = (await source.requests.fetchDetails(kind, tmdbId)).mediaInfo;
      title = SeerrTitleRequests(media: media, requests: media?.requests ?? const []);
    } catch (e) {
      // No actions without a current reading; the page itself is unaffected.
      appLogger.d('Seerr: request state load failed for tmdb:$tmdbId', error: e);
    }
    if (_disposed || generation != _generation) return;
    _title = title;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _source?.requests.removeListener(_onRequestsChanged);
    super.dispose();
  }
}
