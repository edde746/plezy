import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../models/seerr/seerr_request.dart';
import '../../providers/seerr_requests_provider.dart';
import '../../services/seerr/seerr_constants.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/loading_indicator_box.dart';
import 'seerr_detail_screen.dart';
import 'widgets/seerr_status_badge.dart';

/// "My Requests" tab — paginated list of the user's Seerr requests with
/// status badges and a swipe-to-cancel affordance for pending items.
class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SeerrRequestsProvider>().loadIfNeeded();
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    if (maxScroll - current < 320) {
      context.read<SeerrRequestsProvider>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _cancel(SeerrRequest req) async {
    final provider = context.read<SeerrRequestsProvider>();
    final ok = await provider.cancel(req.id);
    if (!mounted) return;
    if (ok) {
      showSuccessSnackBar(context, t.seerr.myRequests.cancelled);
    } else {
      showSuccessSnackBar(context, t.seerr.myRequests.cancelFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SeerrRequestsProvider>(
      builder: (context, provider, _) {
        return RefreshIndicator(
          onRefresh: provider.refresh,
          child: _buildBody(provider),
        );
      },
    );
  }

  Widget _buildBody(SeerrRequestsProvider provider) {
    final theme = Theme.of(context);
    if (provider.state == SeerrRequestsLoadState.loading && provider.requests.isEmpty) {
      return const Center(child: LoadingIndicatorBox(size: 32));
    }
    if (provider.state == SeerrRequestsLoadState.error && provider.requests.isEmpty) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                const AppIcon(Symbols.error_rounded, fill: 1, size: 48),
                const SizedBox(height: 8),
                Text(provider.errorMessage ?? t.seerr.myRequests.failedToLoad, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: provider.refresh,
                  icon: const AppIcon(Symbols.refresh_rounded, fill: 1),
                  label: Text(t.seerr.discover.retry),
                ),
              ],
            ),
          ),
        ],
      );
    }
    if (provider.requests.isEmpty) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                AppIcon(Symbols.playlist_add_check_rounded, fill: 1, size: 48, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(height: 8),
                Text(t.seerr.myRequests.empty, style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  t.seerr.myRequests.emptySubtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: provider.requests.length + (provider.loadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        if (i >= provider.requests.length) {
          return const Padding(padding: EdgeInsets.all(16), child: Center(child: LoadingIndicatorBox()));
        }
        final req = provider.requests[i];
        final summary = provider.summaryFor(req);
        final canCancel = req.status == SeerrRequestStatus.pendingApproval || req.status == SeerrRequestStatus.approved;
        return Dismissible(
          key: ValueKey('seerr-request-${req.id}'),
          direction: canCancel ? DismissDirection.endToStart : DismissDirection.none,
          confirmDismiss: (_) async {
            await _cancel(req);
            return false; // we update the list via the provider, not via Dismissible removal
          },
          background: Container(
            color: Theme.of(context).colorScheme.errorContainer,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const AppIcon(Symbols.cancel_rounded, fill: 1),
          ),
          child: ListTile(
            onTap: () => _openDetail(req),
            leading: _leadingFor(req, summary),
            title: Text(_titleFor(req, summary), maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(_subtitleFor(req, summary)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SeerrStatusBadge.request(context, req.status),
                if (canCancel) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const AppIcon(Symbols.cancel_rounded, fill: 1, size: 20),
                    tooltip: t.seerr.myRequests.cancelTooltip,
                    onPressed: () => _confirmCancel(req),
                  ),
                ],
              ],
            ),
            isThreeLine: false,
          ),
        );
      },
    );
  }

  Future<void> _confirmCancel(SeerrRequest req) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.seerr.myRequests.cancelConfirmTitle),
        content: Text(t.seerr.myRequests.cancelConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(t.common.cancel)),
          FilledButton.tonal(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.seerr.myRequests.cancelConfirmYes),
          ),
        ],
      ),
    );
    if (confirmed == true) await _cancel(req);
  }

  Widget _leadingFor(SeerrRequest req, SeerrRequestSummary? summary) {
    final url = SeerrConstants.posterUrl(summary?.posterPath);
    if (url == null) {
      return AppIcon(req.mediaType == 'tv' ? Symbols.live_tv_rounded : Symbols.movie_rounded, fill: 1);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: 40,
        height: 60,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              AppIcon(req.mediaType == 'tv' ? Symbols.live_tv_rounded : Symbols.movie_rounded, fill: 1),
        ),
      ),
    );
  }

  String _titleFor(SeerrRequest req, SeerrRequestSummary? summary) {
    if (summary != null && summary.title.isNotEmpty) return summary.title;
    return req.mediaType == 'tv'
        ? t.seerr.myRequests.tvRowTitle(id: req.id)
        : t.seerr.myRequests.movieRowTitle(id: req.id);
  }

  String _subtitleFor(SeerrRequest req, SeerrRequestSummary? summary) {
    final parts = <String>[];
    if (summary?.year != null && summary!.year!.isNotEmpty) parts.add(summary.year!);
    final by = req.requestedBy?.username;
    if (by != null && by.isNotEmpty) parts.add(by);
    return parts.join(' · ');
  }

  void _openDetail(SeerrRequest req) {
    final tmdbId = req.media?.tmdbId;
    if (tmdbId == null) return;
    final summary = context.read<SeerrRequestsProvider>().summaryFor(req);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SeerrDetailScreen(
          tmdbId: tmdbId,
          mediaType: req.mediaType,
          initialTitle: summary?.title,
          initialPosterPath: summary?.posterPath,
        ),
      ),
    );
  }
}
