import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../focus/focusable_button.dart';
import '../i18n/strings.g.dart';
import '../media/ids.dart';
import '../providers/multi_server_provider.dart';
import '../providers/trackers_provider.dart';
import '../screens/settings/add_connection_screen.dart';
import '../screens/settings/services_settings_screen.dart';
import '../screens/settings/tracker_service_info.dart';
import '../services/trackers/tracker_constants.dart';
import '../utils/app_logger.dart';
import 'app_icon.dart';

/// Top-of-app banner for servers that answered and refused this account.
/// Distinct from "server offline" — the server is reachable, so empty hubs
/// need an explanation.
///
/// Two refusals, two rows. A rejected token (HTTP 401,
/// [MultiServerProvider.authErrorServers]) gets a CTA that opens
/// [AddConnectionScreen]; the user picks the right backend and the resulting
/// token replaces the stale row in the registry, which clears the auth-error
/// state on the next health sweep. A refused account (HTTP 403,
/// [MultiServerProvider.accessDeniedServers]) gets no CTA: a new sign-in gets
/// the same refusal, and only the server owner or the network the device is on
/// can change it.
///
/// Confirmed tracker login failures share the banner. Group them into one row
/// so losing several trackers does not fill the screen with repeated alerts.
/// Tracker reconnect uses the existing service-specific login flows; servers
/// retain their own sign-in and access-denied actions.
///
/// Collapses to `SizedBox.shrink()` when no connection needs attention.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final signInEntries = context.select<MultiServerProvider, List<({ServerId serverId, String displayName})>>(
      (p) => p.authErrorServers,
    );
    final deniedEntries = context.select<MultiServerProvider, List<({ServerId serverId, String displayName})>>(
      (p) => p.accessDeniedServers,
    );
    final reconnectServices = context.select<TrackersProvider, List<TrackerService>>(
      (p) => p.reconnectRequiredServices,
    );
    final connectingTracker = context.select<TrackersProvider, bool>((p) => p.isConnectingTracker);
    final trackers = TrackerServiceInfo.all.where((info) => reconnectServices.contains(info.service)).toList();
    if (signInEntries.isEmpty && deniedEntries.isEmpty && trackers.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.errorContainer,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (signInEntries.isNotEmpty)
              _BannerRow(
                icon: Symbols.lock_rounded,
                label: signInEntries.length == 1
                    ? t.connections.sessionExpiredOne(name: signInEntries.first.displayName)
                    : t.connections.sessionExpiredMany(count: signInEntries.length),
                action: FocusableButton(
                  onPressed: () => _openReauth(context),
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.onErrorContainer,
                      foregroundColor: scheme.errorContainer,
                    ),
                    onPressed: () => _openReauth(context),
                    child: Text(t.connections.signInAgain),
                  ),
                ),
              ),
            if (deniedEntries.isNotEmpty)
              _BannerRow(
                icon: Symbols.block_rounded,
                label: deniedEntries.length == 1
                    ? t.connections.accessDeniedOne(name: deniedEntries.first.displayName)
                    : t.connections.accessDeniedMany(count: deniedEntries.length),
              ),
            if (trackers.isNotEmpty)
              _BannerRow(
                icon: Symbols.sync_problem_rounded,
                label: trackers.length == 1
                    ? t.services.reconnectWarning(service: trackers.single.displayName)
                    : t.services.reconnectWarningMany(count: trackers.length),
                action: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 4,
                  children: [
                    FocusableButton(
                      onPressed: connectingTracker ? null : () => _reconnectTrackers(context, trackers),
                      child: FilledButton.tonal(
                        onPressed: connectingTracker ? null : () => _reconnectTrackers(context, trackers),
                        child: Text(t.common.reconnect),
                      ),
                    ),
                    FocusableButton(
                      onPressed: connectingTracker ? null : () => _dismissTrackerWarnings(context, reconnectServices),
                      child: IconButton(
                        tooltip: t.services.dismissReconnectWarning,
                        onPressed: connectingTracker ? null : () => _dismissTrackerWarnings(context, reconnectServices),
                        icon: AppIcon(Symbols.close_rounded, color: scheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openReauth(BuildContext context) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddConnectionScreen()));
  }

  void _reconnectTrackers(BuildContext context, List<TrackerServiceInfo> trackers) {
    if (trackers.length == 1) {
      unawaited(trackers.single.startConnection(context));
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ServicesSettingsScreen()));
    }
  }

  Future<void> _dismissTrackerWarnings(BuildContext context, List<TrackerService> services) async {
    final account = context.read<TrackersProvider>();
    try {
      await Future.wait<void>([for (final service in services) account.dismissReconnectWarning(service)]);
    } catch (error, stackTrace) {
      appLogger.w('Could not persist tracker warning dismissal', error: error, stackTrace: stackTrace);
    }
  }
}

class _BannerRow extends StatelessWidget {
  const _BannerRow({required this.icon, required this.label, this.action});

  final IconData icon;
  final String label;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final action = this.action;
    final message = Row(
      children: [
        AppIcon(icon, fill: 1, color: scheme.onErrorContainer),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onErrorContainer, fontWeight: .w500),
          ),
        ),
      ],
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, action == null ? 16 : 8, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Long localized names and larger text need room on phones. Keep
          // TV/desktop actions beside the message, and stack them on narrow
          // surfaces without sacrificing either remote or touch navigation.
          if (action != null && constraints.maxWidth < 480) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                message,
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerRight, child: action),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: message),
              if (action != null) ...[const SizedBox(width: 8), action],
            ],
          );
        },
      ),
    );
  }
}
