import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../focus/card_focus_scope.dart';
import '../focus/focusable_wrapper.dart';
import '../i18n/strings.g.dart';
import '../media/media_person.dart';
import '../services/settings_service.dart';
import '../theme/mono_tokens.dart';
import '../utils/media_image_helper.dart';
import '../utils/media_navigation_helper.dart';
import '../utils/platform_detector.dart';
import '../utils/provider_extensions.dart';
import 'backend_badge.dart';
import 'media_card_list_layout.dart';
import 'optimized_media_image.dart';
import 'settings_builder.dart';

/// A person search result, laid out like the search screen's list-mode media
/// rows (a `FocusableMediaCard` with `ViewMode.list` and `disableScale`): a
/// circular avatar centered in the rows' artwork column, name and credit
/// beside it.
///
/// Tap, click, or D-pad/keyboard/gamepad select opens the person's filmography.
/// A person has no context menu: nothing on it can be played, rated, or marked.
class PersonSearchRow extends StatelessWidget {
  const PersonSearchRow({
    super.key,
    required this.person,
    this.focusNode,
    this.showServerName = false,
    this.onNavigateLeft,
    this.onNavigateUp,
  });

  final MediaPerson person;
  final FocusNode? focusNode;

  /// Adds the backend badge and server name line media rows show on
  /// multi-server setups.
  final bool showServerName;
  final VoidCallback? onNavigateLeft;
  final VoidCallback? onNavigateUp;

  /// Avatar diameter as a share of the media rows' artwork column width.
  static const double _avatarScale = 0.6;

  String? get _creditLabel => switch (person.credit) {
    PersonCredit.actor => t.explore.creditRole.actor,
    PersonCredit.director => t.explore.creditRole.director,
    null => null,
  };

  void _open(BuildContext context) {
    unawaited(
      navigateToPersonMedia(
        context,
        personId: person.id,
        name: person.name,
        thumbPath: person.thumbPath,
        serverId: person.serverId,
        serverName: person.serverName,
        backend: person.backend,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final creditLabel = _creditLabel;
    // Focus flags mirror FocusableMediaCard with disableScale: the row draws
    // its own whole-row border through CardFocusBorder.
    return FocusableWrapper(
      focusNode: focusNode,
      semanticLabel: [person.name, ?creditLabel].join(', '),
      includeFocusSemantics: !PlatformDetector.isTV() || MediaQuery.accessibleNavigationOf(context),
      onSelect: () => _open(context),
      onNavigateLeft: onNavigateLeft,
      onNavigateUp: onNavigateUp,
      disableScale: true,
      delegateFocusBorder: true,
      useComfortableZone: !PlatformDetector.isTV(), // Always center on TV
      scrollAlignment: 0.5,
      child: SettingValueBuilder<int>(
        pref: SettingsService.libraryDensity,
        builder: (context, density, _) => _buildRow(context, density, creditLabel),
      ),
    );
  }

  Widget _buildRow(BuildContext context, int density, String? creditLabel) {
    final textTheme = Theme.of(context).textTheme;
    final monoTokens = tokens(context);
    final densityFactor = LibraryDensity.factor(density);
    final titleFontSize = 13 + densityFactor * 3; // 13–16, as media list rows
    final metadataFontSize = 10 + densityFactor * 3; // 10–13, as media list rows
    // The artwork column keeps the media rows' width so names line up with
    // titles in a mixed list; the avatar inside it is smaller, so a two-line
    // row isn't as tall as a poster.
    final columnWidth = MediaCardListLayout.basePosterWidth(density);
    final avatarSize = columnWidth * _avatarScale;
    final serverName = showServerName ? person.serverName : null;

    // List rows keep the whole-row border; inside stroke so adjacent rows
    // don't overlap.
    return CardFocusBorder(
      borderRadius: monoTokens.radiusSm,
      strokeAlign: BorderSide.strokeAlignInside,
      child: _RowTapRegion(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(monoTokens.radiusSm),
        child: Padding(
          padding: const EdgeInsets.all(MediaCardListLayout.padding),
          child: Row(
            crossAxisAlignment: .center,
            children: [
              // The circle gets a fixed box of its own, like media rows size
              // their poster slot: the SliverList leaves the row's height
              // unbounded, the column is wider than the circle, and the
              // loading placeholder fills whatever box it gets.
              SizedBox(
                width: columnWidth,
                child: Center(
                  child: SizedBox.square(
                    dimension: avatarSize,
                    child: ClipOval(
                      child: OptimizedMediaImage(
                        client: context.tryGetMediaClientForServer(person.serverId),
                        imagePath: person.thumbPath,
                        width: avatarSize,
                        height: avatarSize,
                        fit: BoxFit.cover,
                        placeholder: _buildAvatarLoadingPlaceholder,
                        fallbackIcon: Symbols.person_rounded,
                        imageType: ImageType.avatar,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      person.name,
                      maxLines: 2,
                      overflow: .ellipsis,
                      style: TextStyle(fontWeight: .w600, fontSize: titleFontSize, height: 1.2),
                    ),
                    if (creditLabel != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        creditLabel,
                        maxLines: 1,
                        overflow: .ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: monoTokens.textMuted.withValues(alpha: 0.9),
                          fontSize: metadataFontSize,
                          fontWeight: .w500,
                        ),
                      ),
                    ],
                    if (serverName != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          // Same optical nudge as the media rows' source line.
                          Transform.translate(
                            offset: Offset(0, metadataFontSize * 0.115),
                            child: BackendBadge(
                              backend: person.backend,
                              size: metadataFontSize + 2,
                              color: monoTokens.textMuted.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              serverName,
                              maxLines: 1,
                              overflow: .ellipsis,
                              style: textTheme.bodySmall?.copyWith(
                                color: monoTokens.textMuted.withValues(alpha: 0.6),
                                fontSize: metadataFontSize,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildAvatarLoadingPlaceholder(BuildContext context, String _) {
  return ColoredBox(color: Theme.of(context).colorScheme.surfaceContainerHighest, child: const SizedBox.expand());
}

/// Pointer/touch surface matching media rows: an [InkWell] on desktop where
/// hover feedback matters, a bare [GestureDetector] on TV and touch devices.
/// Keyboard focus belongs to the enclosing [FocusableWrapper].
class _RowTapRegion extends StatelessWidget {
  const _RowTapRegion({required this.onTap, required this.borderRadius, required this.child});

  final VoidCallback onTap;
  final BorderRadius borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!PlatformDetector.isDesktopOS()) {
      return GestureDetector(excludeFromSemantics: true, behavior: HitTestBehavior.opaque, onTap: onTap, child: child);
    }
    return InkWell(
      excludeFromSemantics: true,
      mouseCursor: SystemMouseCursors.click,
      canRequestFocus: false,
      onTap: onTap,
      borderRadius: borderRadius,
      child: child,
    );
  }
}
