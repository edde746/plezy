import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../focus/focusable_button.dart';
import '../i18n/strings.g.dart';
import '../services/supporter/supporter_service.dart';
import '../services/supporter/supporter_mode.dart';
import 'app_icon.dart';
import 'loading_indicator_box.dart';

/// Blocks store builds after the seven-day full-feature trial expires.
/// Developer and free builds pass through without a paywall.
class AppAccessGate extends StatefulWidget {
  const AppAccessGate({super.key, required this.service, required this.child});

  final SupporterService service;
  final Widget child;

  @override
  State<AppAccessGate> createState() => _AppAccessGateState();
}

class _AppAccessGateState extends State<AppAccessGate> {
  late final FocusNode _trialFocusNode = FocusNode(debugLabel: 'app_access_trial');
  late final FocusNode _purchaseFocusNode = FocusNode(debugLabel: 'app_access_purchase');
  late final FocusNode _restoreFocusNode = FocusNode(debugLabel: 'app_access_restore');
  bool _startingTrial = false;
  String? _trialError;

  @override
  void initState() {
    super.initState();
    if (widget.service.availability == SupporterAvailability.purchasable) {
      unawaited(widget.service.loadProduct());
    }
  }

  @override
  void dispose() {
    _trialFocusNode.dispose();
    _purchaseFocusNode.dispose();
    _restoreFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.service,
      builder: (context, _) {
        if (widget.service.availability != SupporterAvailability.purchasable || widget.service.hasAccess) {
          return widget.child;
        }
        if (!widget.service.isReady) return _loading(context);
        return ValueListenableBuilder(
          valueListenable: widget.service.storeState,
          builder: (context, storeState, _) => _offer(context, storeState),
        );
      },
    );
  }

  Widget _loading(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [const CircularProgressIndicator(), const SizedBox(height: 16), Text(t.common.loading)],
        ),
      ),
    );
  }

  Widget _offer(BuildContext context, SupporterStoreState storeState) {
    final theme = Theme.of(context);
    final service = widget.service;
    final productError = storeState.price == null && !storeState.isLoadingProduct ? storeState.productError : null;
    final error = _trialError ?? _localizedError(storeState.error ?? productError);
    final busy = storeState.isBusy || storeState.isLoadingProduct || _startingTrial;

    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppIcon(Symbols.lock_open_rounded, fill: 1, size: 48),
                  const SizedBox(height: 18),
                  Text(
                    service.hasStartedTrial ? t.appAccess.trialEnded : t.appAccess.title,
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    service.hasStartedTrial ? t.appAccess.trialEndedDescription : t.appAccess.description,
                    style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 20),
                    Text(error, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
                  ] else if (storeState.status == SupporterPurchaseStatus.pending) ...[
                    const SizedBox(height: 20),
                    Text(t.appAccess.pending, textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 24),
                  if (service.shouldOfferTrial) ...[
                    FocusableButton(
                      focusNode: _trialFocusNode,
                      autofocus: true,
                      useBackgroundFocus: true,
                      onPressed: busy || !service.canStartTrial ? null : _startTrial,
                      child: FilledButton.icon(
                        onPressed: busy || !service.canStartTrial ? null : _startTrial,
                        icon: const AppIcon(Symbols.play_arrow_rounded, fill: 1),
                        label: Text(t.appAccess.startTrial),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (productError != null)
                    FocusableButton(
                      focusNode: _purchaseFocusNode,
                      autofocus: !service.shouldOfferTrial,
                      useBackgroundFocus: true,
                      onPressed: busy ? null : () => unawaited(service.loadProduct()),
                      child: FilledButton.tonalIcon(
                        onPressed: busy ? null : () => unawaited(service.loadProduct()),
                        icon: const AppIcon(Symbols.refresh_rounded, fill: 1),
                        label: Text(t.appAccess.retryPrice),
                      ),
                    )
                  else
                    FocusableButton(
                      focusNode: _purchaseFocusNode,
                      autofocus: !service.shouldOfferTrial,
                      useBackgroundFocus: true,
                      onPressed:
                          storeState.price == null || busy || storeState.status == SupporterPurchaseStatus.pending
                          ? null
                          : () => unawaited(service.purchase()),
                      child: FilledButton.icon(
                        onPressed:
                            storeState.price == null || busy || storeState.status == SupporterPurchaseStatus.pending
                            ? null
                            : () => unawaited(service.purchase()),
                        icon: storeState.status == SupporterPurchaseStatus.purchasing || storeState.isLoadingProduct
                            ? const LoadingIndicatorBox()
                            : const AppIcon(Symbols.key_rounded, fill: 1),
                        label: Text(
                          storeState.price == null
                              ? t.appAccess.loadingPrice
                              : t.appAccess.buy(price: storeState.price!),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  FocusableButton(
                    focusNode: _restoreFocusNode,
                    onPressed: busy ? null : () => unawaited(service.restore()),
                    child: TextButton.icon(
                      onPressed: busy ? null : () => unawaited(service.restore()),
                      icon: storeState.status == SupporterPurchaseStatus.restoring
                          ? const LoadingIndicatorBox()
                          : const AppIcon(Symbols.restore_rounded, fill: 1),
                      label: Text(t.appAccess.restore),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startTrial() async {
    setState(() {
      _startingTrial = true;
      _trialError = null;
    });
    final started = await widget.service.startTrial();
    if (!mounted) return;
    setState(() {
      _startingTrial = false;
      if (!started && !widget.service.hasAccess) _trialError = t.appAccess.trialStartFailed;
    });
  }

  String? _localizedError(SupporterError? error) => switch (error) {
    null => null,
    SupporterError.storeUnavailable => t.appAccess.storeUnavailable,
    SupporterError.productNotFound => t.appAccess.productNotFound,
    SupporterError.productQueryFailed => t.appAccess.productQueryFailed,
    SupporterError.purchaseFailed => t.appAccess.purchaseFailed,
    SupporterError.restoreFailed => t.appAccess.restoreFailed,
    SupporterError.nothingToRestore => t.appAccess.nothingToRestore,
  };
}
