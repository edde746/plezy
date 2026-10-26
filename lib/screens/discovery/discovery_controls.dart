import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../focus/focusable_button.dart';
import '../../focus/focusable_wrapper.dart';
import '../../focus/input_mode_tracker.dart';
import '../../utils/platform_detector.dart';
import '../../i18n/strings.g.dart';
import '../../theme/mono_tokens.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/overlay_sheet.dart';

/// The same reading-direction mapping is used by the cues and the gesture.
class DiscoverySwipeHints extends StatelessWidget {
  const DiscoverySwipeHints({super.key});

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final style = Theme.of(context).textTheme.labelLarge;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 24,
      runSpacing: 4,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(rtl ? Symbols.arrow_forward_rounded : Symbols.arrow_back_rounded, textDirection: TextDirection.ltr),
            const SizedBox(width: 6),
            Text(t.discover.findNext.notNow, style: style),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.common.save, style: style),
            const SizedBox(width: 6),
            AppIcon(rtl ? Symbols.arrow_back_rounded : Symbols.arrow_forward_rounded, textDirection: TextDirection.ltr),
          ],
        ),
      ],
    );
  }
}

/// Gestures and focused-cover direction keys mirror the explicit buttons.
/// Assistive technology retains normal focus navigation and button actions.
class DiscoverySwipeCard extends StatefulWidget {
  const DiscoverySwipeCard({
    super.key,
    required this.child,
    required this.choiceId,
    this.autofocus = false,
    required this.canSwipe,
    required this.onSave,
    required this.onSkip,
    this.onDetails,
  });

  final Widget child;
  final String choiceId;
  final bool autofocus;
  final bool canSwipe;
  final VoidCallback onSave;
  final VoidCallback onSkip;
  final VoidCallback? onDetails;

  @override
  State<DiscoverySwipeCard> createState() => _DiscoverySwipeCardState();
}

class _DiscoverySwipeCardState extends State<DiscoverySwipeCard> {
  double _dx = 0;

  @override
  void didUpdateWidget(DiscoverySwipeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.canSwipe || widget.choiceId != oldWidget.choiceId) _dx = 0;
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final logicalDx = rtl ? -_dx : _dx;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final threshold = (constraints.maxWidth * 0.25).clamp(64.0, 144.0);
        final ready = logicalDx.abs() >= threshold;
        final save = logicalDx > 0;
        return FocusableWrapper(
          autofocus: widget.autofocus,
          autoScroll: false,
          disableScale: true,
          borderRadius: tokens(context).radiusLg,
          onSelect: widget.onDetails,
          child: MouseRegion(
            cursor: widget.onDetails == null ? MouseCursor.defer : SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true, // The persistent Details button is the accessible equivalent.
              onTap: widget.onDetails,
              onHorizontalDragStart: widget.canSwipe ? (_) => setState(() => _dx = 0) : null,
              onHorizontalDragUpdate: widget.canSwipe ? (event) => setState(() => _dx += event.delta.dx) : null,
              onHorizontalDragCancel: widget.canSwipe ? () => setState(() => _dx = 0) : null,
              onHorizontalDragEnd: widget.canSwipe
                  ? (_) {
                      final finalDx = rtl ? -_dx : _dx;
                      setState(() => _dx = 0);
                      if (finalDx.abs() >= threshold) (finalDx > 0 ? widget.onSave : widget.onSkip)();
                    }
                  : null,
              child: Transform.translate(
                offset: Offset(reducedMotion ? 0 : _dx.clamp(-180.0, 180.0), 0),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    widget.child,
                    if (widget.canSwipe && _dx.abs() > 18)
                      Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: IgnorePointer(
                            child: Material(
                              color: Theme.of(context).colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(tokens(context).radiusSm),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Text(
                                  '${save ? t.common.save : t.discover.findNext.notNow}${ready ? '\n${t.discover.findNext.releaseToConfirm}' : ''}',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Lives outside the bounded artwork stage, so long descriptions cannot hide
/// actions. Compact controls preserve narrow and landscape layouts.
class DiscoveryActionBar extends StatelessWidget {
  const DiscoveryActionBar({
    super.key,
    required this.primaryLabel,
    required this.primaryIcon,
    this.onSkip,
    this.onSave,
    this.onOpen,
    this.onDetails,
    this.showDetails = true,
    this.onUndo,
    this.feedback,
  });

  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback? onSkip;
  final VoidCallback? onSave;
  final VoidCallback? onOpen;
  final VoidCallback? onDetails;
  final bool showDetails;
  final VoidCallback? onUndo;
  final String? feedback;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final keyboard =
        (PlatformDetector.isTV() || InputModeTracker.isKeyboardMode(context)) &&
        !MediaQuery.accessibleNavigationOf(context);
    final hint = MediaQuery.accessibleNavigationOf(context)
        ? t.discover.findNext.chooseHint
        : keyboard
        ? t.discover.findNext.controlsHelp
        : t.discover.findNext.swipeHint;
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.surface.withValues(alpha: 0.92),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 12, 4),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  liveRegion: feedback != null,
                  child: Text(
                    feedback ?? hint,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _action(
                        context,
                        t.discover.findNext.notNow,
                        rtl ? Symbols.arrow_forward_rounded : Symbols.arrow_back_rounded,
                        onSkip,
                        help: t.discover.findNext.notNowHelp,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: _action(context, primaryLabel, primaryIcon, onOpen, primary: true)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _action(
                        context,
                        t.common.save,
                        rtl ? Symbols.arrow_back_rounded : Symbols.arrow_forward_rounded,
                        onSave,
                        help: t.discover.findNext.saveHelp,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: _secondary(t.discover.findNext.undo, onUndo)),
                    if (showDetails) Expanded(child: _secondary(t.discover.findNext.details, onDetails)),
                    Expanded(child: _secondary(t.discover.findNext.howItWorks, () => showDiscoveryHelp(context))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _action(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback? action, {
    bool primary = false,
    String? help,
  }) {
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(tokens(context).radiusSm)),
      ),
    );
    final compact = MediaQuery.sizeOf(context).height < 440;
    final labelWidget = Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center);
    final child = compact
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(icon, size: 20, textDirection: TextDirection.ltr),
              const SizedBox(width: 4),
              Flexible(child: labelWidget),
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(icon, textDirection: TextDirection.ltr),
              const SizedBox(height: 2),
              labelWidget,
            ],
          );
    return Tooltip(
      message: help ?? label,
      child: FocusableButton(
        onPressed: action,
        autoScroll: false,
        child: SizedBox(
          width: double.infinity,
          child: primary
              ? FilledButton(onPressed: action, style: style, child: child)
              : OutlinedButton(onPressed: action, style: style, child: child),
        ),
      ),
    );
  }

  Widget _secondary(String label, VoidCallback? action) => FocusableButton(
    onPressed: action,
    autoScroll: false,
    child: TextButton(
      onPressed: action,
      style: TextButton.styleFrom(minimumSize: const Size(48, 48), padding: const EdgeInsets.symmetric(horizontal: 4)),
      child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
    ),
  );
}

Future<void> showDiscoveryHelp(BuildContext context) {
  final showGestureDirections =
      !PlatformDetector.isTV() &&
      !InputModeTracker.isKeyboardMode(context) &&
      !MediaQuery.accessibleNavigationOf(context);
  return OverlaySheetController.showAdaptive<void>(
    context,
    builder: (sheetContext) => SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(t.discover.findNext.howItWorks, style: Theme.of(sheetContext).textTheme.titleLarge),
          const SizedBox(height: 16),
          Text(t.discover.findNext.chooseHint),
          if (showGestureDirections) ...[
            const SizedBox(height: 16),
            const DiscoverySwipeHints(),
            const SizedBox(height: 8),
            Text(t.discover.findNext.swipeHint),
          ],
          const SizedBox(height: 16),
          Text(t.discover.findNext.notNow, style: Theme.of(sheetContext).textTheme.titleSmall),
          Text(t.discover.findNext.notNowHelp),
          const SizedBox(height: 16),
          Text(t.common.save, style: Theme.of(sheetContext).textTheme.titleSmall),
          Text(t.discover.findNext.saveHelp),
          const SizedBox(height: 16),
          Text(t.discover.findNext.details, style: Theme.of(sheetContext).textTheme.titleSmall),
          Text(t.discover.findNext.openHelp),
          const SizedBox(height: 16),
          Text(t.discover.findNext.controlsHelp),
          const SizedBox(height: 16),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FocusableButton(
              onPressed: () => Navigator.of(sheetContext).pop(),
              child: FilledButton(onPressed: () => Navigator.of(sheetContext).pop(), child: Text(t.common.close)),
            ),
          ),
        ],
      ),
    ),
  );
}
