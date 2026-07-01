import 'package:flutter/material.dart';

import '../../../i18n/strings.g.dart';
import '../../../models/seerr/seerr_media_info.dart';
import '../../../models/seerr/seerr_request.dart';

/// Small pill that summarizes a Seerr media's availability/request state.
///
/// Use [SeerrStatusBadge.media] for catalog items (drives the discover/search
/// cards) and [SeerrStatusBadge.request] for "My Requests" rows.
class SeerrStatusBadge extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const SeerrStatusBadge._({required this.label, required this.background, required this.foreground});

  factory SeerrStatusBadge.media(BuildContext context, SeerrMediaStatus status) {
    final scheme = Theme.of(context).colorScheme;
    return switch (status) {
      SeerrMediaStatus.available => SeerrStatusBadge._(
        label: t.seerr.status.available,
        background: scheme.tertiaryContainer,
        foreground: scheme.onTertiaryContainer,
      ),
      SeerrMediaStatus.partiallyAvailable => SeerrStatusBadge._(
        label: t.seerr.status.partiallyAvailable,
        background: scheme.tertiaryContainer,
        foreground: scheme.onTertiaryContainer,
      ),
      SeerrMediaStatus.processing => SeerrStatusBadge._(
        label: t.seerr.status.processing,
        background: scheme.secondaryContainer,
        foreground: scheme.onSecondaryContainer,
      ),
      SeerrMediaStatus.pending => SeerrStatusBadge._(
        label: t.seerr.status.pending,
        background: scheme.secondaryContainer,
        foreground: scheme.onSecondaryContainer,
      ),
      SeerrMediaStatus.unknown => SeerrStatusBadge._(
        label: t.seerr.status.notRequested,
        background: scheme.surfaceContainerHighest,
        foreground: scheme.onSurfaceVariant,
      ),
    };
  }

  factory SeerrStatusBadge.request(BuildContext context, SeerrRequestStatus status) {
    final scheme = Theme.of(context).colorScheme;
    return switch (status) {
      SeerrRequestStatus.approved => SeerrStatusBadge._(
        label: t.seerr.status.approved,
        background: scheme.tertiaryContainer,
        foreground: scheme.onTertiaryContainer,
      ),
      SeerrRequestStatus.completed => SeerrStatusBadge._(
        label: t.seerr.status.available,
        background: scheme.tertiaryContainer,
        foreground: scheme.onTertiaryContainer,
      ),
      SeerrRequestStatus.pendingApproval => SeerrStatusBadge._(
        label: t.seerr.status.pending,
        background: scheme.secondaryContainer,
        foreground: scheme.onSecondaryContainer,
      ),
      SeerrRequestStatus.declined => SeerrStatusBadge._(
        label: t.seerr.status.declined,
        background: scheme.errorContainer,
        foreground: scheme.onErrorContainer,
      ),
      SeerrRequestStatus.failed => SeerrStatusBadge._(
        label: t.seerr.status.failed,
        background: scheme.errorContainer,
        foreground: scheme.onErrorContainer,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: foreground, fontWeight: FontWeight.w600),
      ),
    );
  }
}
