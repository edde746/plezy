import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../focus/focusable_button.dart';
import '../focus/input_mode_tracker.dart';
import '../i18n/strings.g.dart';
import '../services/supporter/supporter_mode.dart';
import '../services/supporter/supporter_service.dart';
import 'app_icon.dart';
import 'bottom_sheet_header.dart';
import 'loading_indicator_box.dart';
import 'overlay_sheet.dart';

/// Opens the Supporter purchase sheet: perks, price, Buy and Restore Purchases.
///
/// Callers use this from every locked perk (a preset or custom theme, an app
/// icon) and from the Settings "Support Plezy" tile in purchasable builds.
/// Completes when the sheet closes; read `SupporterService.isUnlocked` after
/// it to see whether the user unlocked. Shows nothing unless the perks are
/// purchasable in this build.
Future<void> showSupporterSheet(BuildContext context) async {
  final supporter = context.read<SupporterService>();
  if (supporter.availability != SupporterAvailability.purchasable) return;
  supporter.clearError();
  unawaited(supporter.loadProduct());
  await OverlaySheetController.showAdaptive<void>(
    context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => SupporterSheet(supporter: supporter),
  );
}

/// Whether this platform ships the alternate app icons perk: iOS, iPadOS and
/// tvOS (which reports iOS) and Android.
bool supporterOffersAppIcons() =>
    defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android;

class SupporterSheet extends StatefulWidget {
  const SupporterSheet({super.key, required this.supporter});

  final SupporterService supporter;

  @override
  State<SupporterSheet> createState() => _SupporterSheetState();
}

class _SupporterSheetState extends State<SupporterSheet> {
  late final FocusNode _primaryFocusNode = FocusNode(debugLabel: 'supporter_primary');
  late final FocusNode _restoreFocusNode = FocusNode(debugLabel: 'supporter_restore');
  late final FocusNode _closeFocusNode = FocusNode(debugLabel: 'supporter_close');
  final ScrollController _scrollController = ScrollController();

  late SupporterStoreState _state = widget.supporter.storeState.value;
  late bool _unlocked = widget.supporter.isUnlocked;

  SupporterService get _supporter => widget.supporter;

  @override
  void initState() {
    super.initState();
    _supporter.addListener(_handleChange);
    _supporter.storeState.addListener(_handleChange);
    for (final node in _buttonFocusNodes) {
      node.addListener(_revealFocusedButton);
    }
  }

  List<FocusNode> get _buttonFocusNodes => [_primaryFocusNode, _restoreFocusNode, _closeFocusNode];

  /// Scrolls a D-pad-focused button into view with as much of the content
  /// above it showing as fits. Nothing above the buttons takes focus, so on a
  /// short screen (a 1080p TV is 960x540) this keeps the intro and perks in
  /// view whenever the top button is focused: when the sheet opens and on UP
  /// from below. The buttons' own auto-scroll is off because it centers them,
  /// which pushes the intro out.
  void _revealFocusedButton() {
    if (InputModeTracker.currentMode != InputMode.keyboard) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      FocusNode? focused;
      for (final node in _buttonFocusNodes) {
        if (node.hasPrimaryFocus) focused = node;
      }
      final button = focused?.context?.findRenderObject();
      final viewport = focused?.context == null
          ? null
          : Scrollable.maybeOf(focused!.context!)?.context.findRenderObject();
      if (button is! RenderBox || viewport is! RenderBox) return;
      final position = _scrollController.position;
      // Room for the focus decoration below the button.
      const focusPadding = 8.0;
      final buttonBottom = button.localToGlobal(Offset(0, button.size.height), ancestor: viewport).dy;
      final target = (position.pixels + buttonBottom + focusPadding - viewport.size.height).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      if ((target - position.pixels).abs() < 1) return;
      unawaited(position.animateTo(target, duration: const Duration(milliseconds: 200), curve: Curves.easeOut));
    });
  }

  @override
  void dispose() {
    _supporter.removeListener(_handleChange);
    _supporter.storeState.removeListener(_handleChange);
    _primaryFocusNode.dispose();
    _restoreFocusNode.dispose();
    _closeFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleChange() {
    final next = _supporter.storeState.value;
    final unlocked = _supporter.isUnlocked;
    final priceArrived = _state.price == null && next.price != null;
    final becameUnlocked = unlocked && !_unlocked;
    setState(() {
      _state = next;
      _unlocked = unlocked;
    });
    _settleFocus(priceArrived: priceArrived, becameUnlocked: becameUnlocked);
  }

  /// Keeps D-pad focus on a live control as buttons enable, disable and swap.
  void _settleFocus({required bool priceArrived, required bool becameUnlocked}) {
    if (!InputModeTracker.isKeyboardMode(context, listen: false)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (becameUnlocked) {
        _closeFocusNode.requestFocus();
        return;
      }
      // Buy is disabled while the price loads, so the sheet's first focus
      // lands on Restore Purchases; hand it to Buy once Buy can act.
      if (priceArrived && _restoreFocusNode.hasPrimaryFocus && _primaryFocusNode.canRequestFocus) {
        _primaryFocusNode.requestFocus();
        return;
      }
      if (_primaryFocusNode.hasPrimaryFocus || _restoreFocusNode.hasPrimaryFocus) return;
      // A focused button was disabled, which hands focus back to the sheet's
      // scope. Return it to the first button that can act.
      final focused = FocusManager.instance.primaryFocus;
      if (focused == null || !_restoreFocusNode.ancestors.contains(focused)) return;
      for (final node in [_primaryFocusNode, _restoreFocusNode]) {
        if (node.context != null && node.canRequestFocus) {
          node.requestFocus();
          return;
        }
      }
    });
  }

  void _buy() => unawaited(_supporter.purchase());

  void _restore() => unawaited(_supporter.restore());

  void _retryProduct() => unawaited(_supporter.loadProduct());

  void _close() => OverlaySheetController.closeAdaptive(context);

  /// UP on the top button: show the rest of the intro and perks, even where
  /// they and the button do not fit on screen together.
  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    unawaited(_scrollController.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BottomSheetHeader(title: t.supporter.title),
        Flexible(
          child: SingleChildScrollView(
            controller: _scrollController,
            primary: false,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: _unlocked ? _buildThankYou(theme) : _buildOffer(theme),
          ),
        ),
      ],
    );
  }

  Widget _buildThankYou(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppIcon(Symbols.favorite_rounded, fill: 1, size: 48, color: theme.colorScheme.primary),
        const SizedBox(height: 12),
        Text(t.supporter.thankYouTitle, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(
          t.supporter.thankYouBody,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        FocusableButton(
          focusNode: _closeFocusNode,
          useBackgroundFocus: true,
          onPressed: _close,
          autoScroll: false,
          onNavigateUp: _scrollToTop,
          child: FilledButton.tonal(onPressed: _close, child: Text(t.common.close)),
        ),
      ],
    );
  }

  Widget _buildOffer(ThemeData theme) {
    final state = _state;
    final price = state.price;
    final productError = price == null && !state.isLoadingProduct ? state.productError : null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.supporter.intro, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 12),
        _Perk(
          icon: Symbols.palette_rounded,
          title: t.supporter.presetThemes,
          description: t.supporter.presetThemesDescription,
        ),
        _Perk(
          icon: Symbols.colorize_rounded,
          title: t.supporter.customTheme,
          description: t.supporter.customThemeDescription,
        ),
        if (supporterOffersAppIcons())
          _Perk(icon: Symbols.apps_rounded, title: t.supporter.appIcons, description: t.supporter.appIconsDescription),
        const SizedBox(height: 12),
        // One notice at a time: the latest action's error, else why the price
        // is missing, else the pending purchase.
        if (state.error ?? productError case final error?)
          _Notice.error(error)
        else if (state.status == SupporterPurchaseStatus.pending)
          _Notice(icon: Symbols.hourglass_top_rounded, message: t.supporter.pending, isFailure: false),
        const SizedBox(height: 4),
        if (productError != null) _buildRetryButton() else _buildBuyButton(state),
        const SizedBox(height: 8),
        _buildRestoreButton(state),
      ],
    );
  }

  Widget _buildBuyButton(SupporterStoreState state) {
    final price = state.price;
    final onBuy = price != null && !state.isBusy && state.status != SupporterPurchaseStatus.pending ? _buy : null;
    final showSpinner = state.isLoadingProduct || state.status == SupporterPurchaseStatus.purchasing;
    return FocusableButton(
      focusNode: _primaryFocusNode,
      useBackgroundFocus: true,
      onPressed: onBuy,
      autoScroll: false,
      onNavigateUp: _scrollToTop,
      child: FilledButton.icon(
        onPressed: onBuy,
        icon: showSpinner ? const LoadingIndicatorBox() : const AppIcon(Symbols.favorite_rounded, fill: 1),
        label: Text(price != null ? t.supporter.buy(price: price) : t.supporter.loadingPrice),
      ),
    );
  }

  Widget _buildRetryButton() {
    return FocusableButton(
      focusNode: _primaryFocusNode,
      useBackgroundFocus: true,
      onPressed: _retryProduct,
      autoScroll: false,
      onNavigateUp: _scrollToTop,
      child: FilledButton.tonalIcon(
        onPressed: _retryProduct,
        icon: const AppIcon(Symbols.refresh_rounded, fill: 1),
        label: Text(t.common.retry),
      ),
    );
  }

  Widget _buildRestoreButton(SupporterStoreState state) {
    final onRestore = state.isBusy ? null : _restore;
    return FocusableButton(
      focusNode: _restoreFocusNode,
      onPressed: onRestore,
      autoScroll: false,
      child: TextButton.icon(
        onPressed: onRestore,
        icon: state.status == SupporterPurchaseStatus.restoring
            ? const LoadingIndicatorBox()
            : const AppIcon(Symbols.restore_rounded, fill: 1),
        label: Text(t.supporter.restore),
      ),
    );
  }
}

class _Perk extends StatelessWidget {
  const _Perk({required this.icon, required this.title, required this.description});

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          AppIcon(icon, fill: 1, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One status line above the buttons: a store error, or the pending notice.
class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.message, required this.isFailure});

  // Finding nothing to restore is an answer, not a failure.
  _Notice.error(SupporterError error)
    : this(
        icon: error == SupporterError.nothingToRestore ? Symbols.info_rounded : Symbols.error_rounded,
        message: switch (error) {
          SupporterError.storeUnavailable => t.supporter.errors.storeUnavailable,
          SupporterError.productNotFound => t.supporter.errors.productNotFound,
          SupporterError.productQueryFailed => t.supporter.errors.productQueryFailed,
          SupporterError.purchaseFailed => t.supporter.errors.purchaseFailed,
          SupporterError.restoreFailed => t.supporter.errors.restoreFailed,
          SupporterError.nothingToRestore => t.supporter.errors.nothingToRestore,
        },
        isFailure: error != SupporterError.nothingToRestore,
      );

  final IconData icon;
  final String message;
  final bool isFailure;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isFailure ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(icon, fill: 1, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: theme.textTheme.bodyMedium?.copyWith(color: color)),
          ),
        ],
      ),
    );
  }
}
