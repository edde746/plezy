import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../focus/focusable_button.dart';
import '../../i18n/strings.g.dart';
import '../../utils/platform_detector.dart';
import '../../widgets/app_icon.dart';
import 'discovery_controls.dart';

/// A bounded stage and a separately measured action area. The synopsis never
/// determines page height; the full text remains on the existing Details route.
class DiscoveryDeckView extends StatelessWidget {
  const DiscoveryDeckView({
    super.key,
    required this.choiceId,
    required this.title,
    required this.subtitle,
    required this.facts,
    required this.summary,
    required this.artwork,
    required this.artworkAspectRatio,
    required this.actions,
    required this.enabled,
    required this.onSave,
    required this.onSkip,
    required this.onDetails,
  });

  final String choiceId;
  final String title;
  final String subtitle;
  final String facts;
  final String summary;
  final Widget artwork;
  final double artworkAspectRatio;
  final Widget actions;
  final bool enabled;
  final VoidCallback onSave;
  final VoidCallback onSkip;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: DiscoverySwipeCard(
          choiceId: choiceId,
          autofocus: PlatformDetector.isTV(),
          canSwipe: enabled && !MediaQuery.accessibleNavigationOf(context),
          onSave: onSave,
          onSkip: onSkip,
          onDetails: enabled ? onDetails : null,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final theme = Theme.of(context);
              final scale = MediaQuery.textScalerOf(context);
              final titleStyle = theme.textTheme.headlineSmall!;
              final titleLine = scale.scale(titleStyle.fontSize!) * (titleStyle.height ?? 1.3);
              final bodyLine = scale.scale(theme.textTheme.bodyMedium!.fontSize!) * 1.5;
              final height = constraints.maxHeight;
              final wide = constraints.maxWidth >= 700 && height >= titleLine * 2 + bodyLine * 2 + 32;
              final titleLines = height < titleLine * 2 + bodyLine + 24 ? 1 : 2;
              // If the window is extremely short, retain the actions and the
              // matching background. No fixed minimum poster can cause overflow.
              if (height < titleLine + 8) return const SizedBox.expand();
              final titleWidget = Text(
                title,
                maxLines: titleLines,
                overflow: TextOverflow.ellipsis,
                textAlign: wide ? TextAlign.start : TextAlign.center,
                style: titleStyle,
              );
              final showFacts = height >= titleLine * titleLines + bodyLine + 24;
              final text = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                children: [
                  titleWidget,
                  if (showFacts) ...[
                    const SizedBox(height: 6),
                    Text(facts, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium),
                  ],
                  if (wide && height > titleLine * 2 + bodyLine * 4 + 40) ...[
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                    if (summary.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        summary,
                        maxLines: math
                            .max(1, ((height - titleLine * 2 - bodyLine * 3 - 52) / bodyLine).floor())
                            .clamp(1, 5),
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ],
              );
              final poster = Center(
                child: AspectRatio(aspectRatio: artworkAspectRatio, child: artwork),
              );
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: wide ? 40 : 16, vertical: 4),
                child: wide
                    ? Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Padding(padding: const EdgeInsets.all(16), child: poster),
                          ),
                          const SizedBox(width: 32),
                          Expanded(flex: 6, child: text),
                        ],
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: Padding(padding: const EdgeInsets.only(bottom: 8), child: poster),
                          ),
                          text,
                        ],
                      ),
              );
            },
          ),
        ),
      ),
      actions,
    ],
  );
}

/// The restart action remains reachable when the deck is exhausted or filtered.
class DiscoveryEmptyView extends StatelessWidget {
  const DiscoveryEmptyView({
    super.key,
    required this.heading,
    required this.hint,
    required this.icon,
    this.onClearFilters,
    required this.onRefresh,
  });

  final String heading;
  final String hint;
  final IconData icon;
  final VoidCallback? onClearFilters;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 430),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final theme = Theme.of(context);
                  final scale = MediaQuery.textScalerOf(context);
                  final titleLine = scale.scale(theme.textTheme.titleLarge!.fontSize!) * 1.4;
                  final bodyLine = scale.scale(theme.textTheme.bodyMedium!.fontSize!) * 1.5;
                  final height = constraints.maxHeight;
                  final titleLines = height >= titleLine * 2 + 8 ? 2 : 1;
                  final showHint = height >= titleLine * titleLines + bodyLine * 2 + 8;
                  final showIcon = height >= titleLine * titleLines + bodyLine * 2 + 80;
                  if (height < titleLine) return const SizedBox.shrink();
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showIcon) ...[
                          AppIcon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(height: 16),
                        ],
                        Text(
                          heading,
                          maxLines: titleLines,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge,
                        ),
                        if (showHint) ...[
                          const SizedBox(height: 8),
                          Text(
                            hint,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            FocusableButton(
              onPressed: onClearFilters ?? onRefresh,
              autoScroll: false,
              child: FilledButton(
                onPressed: onClearFilters ?? onRefresh,
                child: Text(
                  onClearFilters != null ? t.common.clear : t.discover.findNext.refresh,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
