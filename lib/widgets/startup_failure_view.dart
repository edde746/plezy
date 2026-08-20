import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../focus/focusable_button.dart';
import '../i18n/strings.g.dart';
import '../services/app_exit_service.dart';
import '../services/log_upload_service.dart';
import '../services/startup_diagnostics.dart';
import '../utils/app_logger.dart';
import '../utils/dialogs.dart';
import '../utils/platform_detector.dart';
import '../utils/snackbar_helper.dart';
import 'app_icon.dart';
import 'dialog_action_button.dart';

const startupBootstrapFailureKey = Key('startup-bootstrap-failure');
const startupBootstrapRetryKey = Key('startup-bootstrap-retry');
const startupFailureDetailsKey = Key('startup-failure-details');
const startupFailureCopyKey = Key('startup-failure-copy');
const startupFailureUploadKey = Key('startup-failure-upload');
const startupFailureRepairKey = Key('startup-failure-repair');
const startupFailureRestartKey = Key('startup-failure-restart');
const startupFailureQuitKey = Key('startup-failure-quit');

/// Everything the startup gate can show when initialization fails.
///
/// Before #1732 this was an icon, the word "Error" and a Retry button: the
/// error object was captured and then discarded, and the only log viewer sat
/// behind the gate that had just failed. On Windows that left literally no way
/// to find out what went wrong — no log file, and no console for a
/// double-clicked release build.
///
/// Everything rendered here comes from [StartupFailureRecord], which is an
/// allowlist of already-redacted fields. Raw preference, database or file
/// contents never reach this widget.
class StartupFailureView extends StatefulWidget {
  const StartupFailureView({
    super.key,
    required this.failure,
    required this.onRetry,
    this.onRepair,
    this.busy = false,
    this.restartRequired = false,
    this.requestExit = AppExitService.requestExit,
  });

  final StartupFailureRecord failure;
  final VoidCallback? onRetry;

  /// Runs the consented storage repair. Null when the failure is not one an
  /// in-app repair can address.
  final Future<void> Function()? onRepair;

  final bool busy;

  /// The repair succeeded but the process must restart before the store can be
  /// opened. Retry and Repair are withdrawn, not merely disabled: the plugin
  /// still holds the bad document, and any preference write from this process
  /// would overwrite the salvaged credentials (#1732).
  final bool restartRequired;

  /// Test seam. Quitting a widget-test binding is not something a test can
  /// observe, so the exit call is injectable exactly like `deleteBackup`.
  final Future<bool> Function({AppExitApplication? exitApplicationForTesting}) requestExit;

  @override
  State<StartupFailureView> createState() => _StartupFailureViewState();
}

class _StartupFailureViewState extends State<StartupFailureView> {
  /// Holds whichever action leads this screen — Repair when it is offered,
  /// Retry otherwise, Quit once a restart is owed.
  late final FocusNode _primaryFocusNode = FocusNode(debugLabel: 'startup-failure-primary');
  bool _detailsExpanded = false;
  bool _uploading = false;

  @override
  void dispose() {
    _primaryFocusNode.dispose();
    super.dispose();
  }

  void _copyDetails() {
    Clipboard.setData(ClipboardData(text: widget.failure.describe()));
    showSuccessSnackBar(context, t.startup.detailsCopied);
  }

  Future<void> _quit() async {
    // Best effort: if the platform declines, the user still has the window
    // controls, and the on-screen instruction already told them what to do.
    try {
      await widget.requestExit();
    } catch (error, stackTrace) {
      appLogger.w('Could not quit after a repair that needs a restart', error: error, stackTrace: stackTrace);
    }
  }

  Future<void> _uploadDetails() async {
    setState(() => _uploading = true);
    try {
      final id = await uploadDiagnosticText(widget.failure.describe());
      if (!mounted) return;
      await showScopedDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(t.messages.logsUploaded),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${t.messages.logId}:'),
              const SizedBox(height: 8),
              SelectableText(
                id,
                style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 18),
              ),
            ],
          ),
          actions: [
            DialogActionButton(
              autofocus: true,
              onPressed: () => Navigator.of(dialogContext).pop(),
              label: t.common.close,
            ),
          ],
        ),
      );
    } catch (error, stackTrace) {
      appLogger.w('Startup diagnostics upload failed', error: error, stackTrace: stackTrace);
      if (mounted) showErrorSnackBar(context, t.messages.logsUploadFailed);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final failure = widget.failure;
    final restartRequired = widget.restartRequired;
    final enabled = !widget.busy && !_uploading;
    // Retry and Repair are the two actions that can touch the store, so they
    // are gone entirely once a restart is owed — not greyed out, because a
    // disabled control still reads as "try me again later".
    final canAct = enabled && !restartRequired;
    final repair = widget.onRepair;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            key: startupBootstrapFailureKey,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(restartRequired ? Symbols.restart_alt_rounded : Symbols.error_rounded, size: 48),
              const SizedBox(height: 16),
              Text(
                restartRequired ? t.startup.repairNeedsRestart : t.startup.failedTitle,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                restartRequired
                    ? t.startup.restartRequiredBody
                    : repair != null
                    ? t.startup.failedBodyRepairable
                    : t.startup.failedBody,
                key: restartRequired ? startupFailureRestartKey : null,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                '${t.startup.phaseLabel}: ${failure.phaseId} · ${failure.errorType}',
                style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _buildDetails(theme, failure),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  // Repair leads whenever it is offered. The failure it
                  // addresses is a document on disk that Retry re-reads
                  // unchanged, so Retry cannot clear it however many times it
                  // is pressed — and it used to be the primary, autofocused,
                  // first-in-order action, which is what a reporter on #1732
                  // pressed repeatedly before concluding the fix had not
                  // shipped. Retry keeps its place for every other failure,
                  // where the environment really can change between attempts.
                  if (!restartRequired && repair != null)
                    FocusableButton(
                      focusNode: _primaryFocusNode,
                      autofocus: true,
                      onPressed: canAct ? () => repair() : null,
                      child: FilledButton(
                        key: startupFailureRepairKey,
                        onPressed: canAct ? () => repair() : null,
                        child: Text(t.startup.repairStorage),
                      ),
                    ),
                  if (!restartRequired)
                    FocusableButton(
                      focusNode: repair == null ? _primaryFocusNode : null,
                      autofocus: repair == null,
                      onPressed: canAct ? widget.onRetry : null,
                      child: repair == null
                          ? FilledButton(
                              key: startupBootstrapRetryKey,
                              onPressed: canAct ? widget.onRetry : null,
                              child: Text(t.common.retry),
                            )
                          : OutlinedButton(
                              key: startupBootstrapRetryKey,
                              onPressed: canAct ? widget.onRetry : null,
                              child: Text(t.common.retry),
                            ),
                    ),
                  if (restartRequired && PlatformDetector.isDesktopOS())
                    FocusableButton(
                      focusNode: _primaryFocusNode,
                      autofocus: true,
                      onPressed: enabled ? _quit : null,
                      child: FilledButton(
                        key: startupFailureQuitKey,
                        onPressed: enabled ? _quit : null,
                        child: Text(t.startup.quitPlezy),
                      ),
                    ),
                  FocusableButton(
                    onPressed: enabled ? _copyDetails : null,
                    child: OutlinedButton(
                      key: startupFailureCopyKey,
                      onPressed: enabled ? _copyDetails : null,
                      child: Text(t.startup.copyDetails),
                    ),
                  ),
                  FocusableButton(
                    onPressed: enabled ? () => _uploadDetails() : null,
                    child: OutlinedButton(
                      key: startupFailureUploadKey,
                      onPressed: enabled ? () => _uploadDetails() : null,
                      child: Text(t.startup.uploadDetails),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetails(ThemeData theme, StartupFailureRecord failure) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FocusableButton(
          onPressed: () => setState(() => _detailsExpanded = !_detailsExpanded),
          child: TextButton(
            onPressed: () => setState(() => _detailsExpanded = !_detailsExpanded),
            child: Text(_detailsExpanded ? t.startup.hideDetails : t.startup.showDetails),
          ),
        ),
        if (_detailsExpanded)
          Container(
            key: startupFailureDetailsKey,
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 240),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                failure.describe(),
                style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}
