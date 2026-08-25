import 'dart:async';
import 'dart:io' show Directory, Platform, ProcessInfo;
import 'dart:ui' show AppExitResponse;
import 'package:flutter/foundation.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_foundation/shared_preferences_foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as material show ThemeMode;
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'connection/connection.dart';
import 'connection/connection_bootstrap.dart';
import 'connection/connection_registry.dart';
import 'navigation/profile_navigation_scope.dart';
import 'navigation/profile_session_screen.dart';
import 'profiles/active_profile_binder.dart';
import 'profiles/active_profile_provider.dart';
import 'profiles/profile.dart';
import 'profiles/profile_connection_cleanup.dart';
import 'profiles/profile_connection_registry.dart';
import 'profiles/profile_registry.dart';
import 'profiles/profile_selection_policy.dart';
import 'models/external_player_models.dart';
import 'mixins/mounted_set_state_mixin.dart';
import 'theme/mono_theme.dart';
import 'profiles/plex_home_service.dart';
import 'screens/auth_screen.dart';
import 'screens/profile/pin_entry_dialog.dart';
import 'screens/profile/profile_switch_screen.dart';
import 'services/storage_service.dart';
import 'services/device_performance.dart';
import 'services/macos_window_service.dart';
import 'services/native_window_service.dart';
import 'services/fullscreen_state_manager.dart';
import 'services/settings_service.dart';
import 'widgets/settings_builder.dart';
import 'utils/platform_detector.dart';
import 'utils/pointer_scroll_axis.dart';
import 'services/apple_tv_remote_touch_service.dart';
import 'services/discord_rpc_service.dart';
import 'package:path_provider/path_provider.dart';
import 'services/image_cache_service.dart';
import 'services/gamepad_service.dart';
import 'services/trackers/tracker_coordinator.dart';
import 'providers/account_preferences_controller.dart';
import 'services/account_preferences_repository.dart';
import 'providers/user_profile_provider.dart';
import 'providers/multi_server_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/download_provider.dart';
import 'providers/offline_mode_provider.dart';
import 'providers/offline_watch_provider.dart';
import 'providers/shader_provider.dart';
import 'utils/snackbar_helper.dart';
import 'services/multi_server_manager.dart';
import 'services/offline_watch_sync_service.dart';
import 'services/data_aggregation_service.dart';
import 'services/credential_vault.dart';
import 'services/server_registry.dart';
import 'services/download_manager_service.dart';
import 'services/pip_service.dart';
import 'services/download_storage_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'services/jellyfin_api_cache.dart';
import 'services/plex_api_cache.dart';
import 'database/app_database.dart';
import 'database/download_operations.dart';
import 'database/tvos_database_recovery_store.dart';
import 'screens/video_player_screen.dart';
import 'utils/app_logger.dart';
import 'utils/managed_http_client.dart';
import 'utils/media_server_http_client.dart';
import 'utils/orientation_helper.dart';
import 'utils/watch_state_notifier.dart';
import 'i18n/app_locale_utils.dart';
import 'i18n/strings.g.dart';
import 'widgets/app_icon.dart';
import 'focus/input_mode_tracker.dart';
import 'focus/key_event_utils.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'utils/navigation_transitions.dart';
import 'utils/log_redaction_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'utils/android_exit_diagnostics.dart';
import 'utils/storage_failure.dart';
import 'services/base_shared_preferences_service.dart';
import 'services/prefs_recovery.dart';
import 'services/sensitive_prefs.dart';
import 'services/startup_diagnostics.dart';
import 'utils/dialogs.dart';
import 'widgets/dialog_action_button.dart';
import 'widgets/startup_failure_view.dart';

const bool _enableSentry = bool.fromEnvironment('ENABLE_SENTRY', defaultValue: false);
const String _sentryDsn = 'https://6a1a6ef8c72140099b2798973c1bfb2f@bugs.plezy.app/1';
const String gitCommit = String.fromEnvironment('GIT_COMMIT');
const String _sentryEnvironment = String.fromEnvironment('SENTRY_ENVIRONMENT');
const String _sentryDist = String.fromEnvironment('SENTRY_DIST');

// Workaround for Flutter bug #177992: iPadOS 26.1+ misinterprets fake touch events
// at (0,0) as barrier taps, causing modals to dismiss immediately.
// Remove when Flutter PR #179643 is merged.
bool _zeroOffsetPointerGuardInstalled = false;

void _installZeroOffsetPointerGuard() {
  if (_zeroOffsetPointerGuardInstalled || !Platform.isIOS) return;
  GestureBinding.instance.pointerRouter.addGlobalRoute(_absorbZeroOffsetPointerEvent);
  _zeroOffsetPointerGuardInstalled = true;
}

void _absorbZeroOffsetPointerEvent(PointerEvent event) {
  if (event is PointerDownEvent && event.position == Offset.zero) {
    GestureBinding.instance.cancelPointer(event.pointer);
  }
}

/// Register platform plugin stores manually for tvOS. Flutter's tool
/// doesn't support tvOS so it never generates a plugin registrant for it.
/// Each plugin whose iOS Swift implementation is tvOS-compatible must be
/// wired here; the Swift side (GeneratedPluginRegistrant.m / AppDelegate)
/// also needs to call the plugin's Swift register(with:) to attach its
/// message channels.
void _registerTvosPlatformPlugins() {
  if (!Platform.isIOS) return; // tvOS reports as iOS via dart:io.
  SharedPreferencesFoundation.registerWith();
}

void main() {
  final binding = PlezyWidgetsBinding.ensureInitialized();
  AndroidExitDiagnostics.markStartupPhase(AndroidStartupPhase.dartMain);
  // Keep the accessibility tree available to Maestro and other UI automation
  // without adding release-build overhead.
  if (kDebugMode) binding.ensureSemantics();
  _installZeroOffsetPointerGuard(); // Workaround for iPadOS 26.1+ modal dismissal bug

  // On tvOS, Flutter's generated plugin registrant doesn't run (no tvOS
  // target in Flutter's tool), so register platform stores manually for
  // the plugins we use.
  _registerTvosPlatformPlugins();
  _bootstrapApp();
}

void _bootstrapApp() {
  // In release mode, show a colored placeholder instead of a blank/white screen
  // when a widget build() throws an unhandled exception.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (kDebugMode) return ErrorWidget(details.exception);
    return const ColoredBox(color: Color(0xFF000000));
  };

  // Off the critical path: the version label only decorates a diagnostic.
  unawaited(_primeDiagnosticsVersion());

  AndroidExitDiagnostics.markStartupPhase(AndroidStartupPhase.runApp);
  runApp(
    StartupBootstrap<_StartupDependencies>(
      initialize: _initializeApplication,
      buildApp: (context, dependencies) => MainApp(
        settings: dependencies.settings,
        storage: dependencies.storage,
        appDatabase: dependencies.appDatabase,
        databaseRecoveryOutcome: dependencies.databaseRecoveryOutcome,
      ),
      discard: (dependencies) => dependencies.appDatabase.close(),
      onCommitted: (dependencies) => _startNonessentialInitialization(dependencies.settings),
      lightTheme: monoTheme(dark: false),
      darkTheme: monoTheme(dark: true),
      resolveTheme: _resolveStartupTheme,
      // Android runs the Flutter surface in transparent mode over a window
      // whose background MainActivity already restored, so the loading frame
      // can leave the launch screen on display. Every other platform composites
      // opaquely and has nothing behind Flutter worth showing.
      transparentWhileLoading: Platform.isAndroid,
    ),
  );
}

/// Resolves the theme the app will settle on, for the frames that precede it.
///
/// Both singletons are memoised and awaited again by the gate, so this costs
/// one preference load and one platform-channel round trip, shared. TV
/// detection has to come first: the `themeMode` default is TV-aware and
/// [TvDetectionService.isTVSync] answers false until its singleton exists,
/// which would make a fresh Android TV install resolve the light theme.
Future<StartupThemeResolution> _resolveStartupTheme() async {
  final settings = await SettingsService.getInstance();
  await TvDetectionService.getInstance(forceTv: settings.read(SettingsService.forceTvMode));
  final mode = settings.read(SettingsService.themeMode);
  return (themeMode: ThemeProvider.materialThemeModeFor(mode), darkTheme: ThemeProvider.darkThemeFor(mode));
}

/// Wraps [step] so a failure names the gate phase it came from.
///
/// `Future.wait` keeps only the first error and discards the rest, and the old
/// catch-all reported a bare `error.runtimeType`, so a startup failure could
/// not even be attributed to one of four concurrent steps (#1732).
Future<T> _gatePhase<T>(StartupPhase phase, Future<T> Function() step) async {
  try {
    return await step();
  } catch (error, stackTrace) {
    Error.throwWithStackTrace(StartupPhaseException(phase, error), stackTrace);
  }
}

/// How long a degradable startup step may block the launch before it is
/// abandoned. Generous next to the sub-second these normally take, but bounded:
/// `windowManager.ensureInitialized()` is a platform-channel round trip and the
/// Windows runner puts the UI on its own thread, so a stalled platform thread
/// would otherwise hold the splash forever with no error to report.
const Duration _optionalPhaseTimeout = Duration(seconds: 10);

/// Runs a startup step that the app can survive without.
///
/// Window chrome, locale selection, crash reporting and the artwork cache are
/// all degradable; before #1732 any one of them could veto the whole boot —
/// by throwing, or by never completing.
Future<void> _optionalGatePhase(
  StartupPhase phase,
  Future<void> Function() step, {
  Duration timeout = _optionalPhaseTimeout,
}) async {
  // Keep a handler on the original future. `timeout` abandons the work rather
  // than cancelling it, so a late failure would otherwise land as an unhandled
  // async error long after the gate moved on.
  final work = Future<void>.sync(step).catchError((Object error, StackTrace stackTrace) {
    appLogger.w('Optional startup phase "${phase.id}" failed', error: error, stackTrace: stackTrace);
  });
  try {
    await work.timeout(timeout);
  } on TimeoutException {
    appLogger.w('Optional startup phase "${phase.id}" did not finish in ${timeout.inSeconds}s; continuing without it');
  }
}

Future<_StartupDependencies> _initializeApplication() async {
  final settings = await _gatePhase(StartupPhase.preferences, SettingsService.getInstance);
  setLoggerLevel(settings.read(SettingsService.enableDebugLogging));

  if (_enableSentry) {
    // Crash reporting is observability: it must never veto the launch it
    // exists to report on. `Sentry.init` runs its integrations eagerly, so an
    // integration throwing used to fail the gate before any Plezy code ran.
    //
    // Deliberately no `appRunner`. On every non-web platform `Sentry.init`
    // reduces it to `await appRunner()` after the integrations — error capture
    // comes from `OnErrorIntegration`/`PlatformDispatcher.onError`, installed
    // during init either way. Passing the startup work in would make a startup
    // failure indistinguishable from a Sentry failure, and this guard would
    // then run the whole gate — migrations, native recovery, database open —
    // a second time.
    await _optionalGatePhase(StartupPhase.crashReporting, () async {
      await SentryFlutter.init((options) {
        options.dsn = _sentryDsn;
        options.release = _sentryRelease();
        if (_sentryEnvironment.isNotEmpty) options.environment = _sentryEnvironment;
        if (_sentryDist.isNotEmpty) options.dist = _sentryDist;
        options.tracesSampleRate = 0;
        options.attachStacktrace = true;
        options.enableAutoSessionTracking = false;
        options.recordHttpBreadcrumbs = false;
        options.captureNativeFailedRequests = false;
        options.enableAppHangTracking = !kDebugMode;
        options.appHangTimeoutInterval = const Duration(seconds: 3);
        options.beforeSend = _beforeSend;
        options.beforeBreadcrumb = _beforeBreadcrumb;
      });
      // Only reached when init really completed; the phase above swallows a
      // failure or a timeout and would otherwise leave a no-op hub that
      // accepts events and drops them.
      _crashReporterReady = true;
    });
  }

  // Registered rather than awaited: sending must not sit on the critical path,
  // but it must finish before the success path consumes the record off disk.
  // Runs even without Sentry so a build that can never report still resolves
  // the record instead of carrying it forever.
  StartupDiagnosticsStore.holdForFlush(flushPendingStartupFailure());

  AndroidExitDiagnostics.markTelemetryReady();
  return _initializeStartup(settings);
}

/// Release identifier for Sentry.
///
/// `PackageInfo.fromPlatform()` reads the executable's Win32 version resource
/// and throws `WindowsException`/`ArgumentError` when that read fails (UNC
/// launch, antivirus interception). Official builds always define
/// `GIT_COMMIT`, so resolve that first and only pay the platform read — inside
/// a guard — when there is no commit to use.
String _sentryRelease() {
  if (gitCommit.length >= 7) return 'plezy@${gitCommit.substring(0, 7)}';
  if (gitCommit.isNotEmpty) return 'plezy@$gitCommit';
  return 'plezy@unknown';
}

const startupBootstrapProgressKey = Key('startup-bootstrap-progress');

/// Human-readable build label for a failure record, primed off the critical
/// path by [_primeDiagnosticsVersion].
String _diagnosticsVersion = gitCommit.isEmpty ? 'unknown' : gitCommit.substring(0, gitCommit.length.clamp(0, 7));

/// Resolves the package version for diagnostics without putting it in the gate.
///
/// `PackageInfo.fromPlatform()` reads the executable's Win32 version resource
/// and throws `WindowsException`/`ArgumentError` when that read fails (a UNC
/// launch, antivirus interception). It used to run inside the startup gate for
/// a value only Sentry consumed; here a failure just leaves the commit label.
Future<void> _primeDiagnosticsVersion() async {
  try {
    final info = await PackageInfo.fromPlatform();
    final commit = gitCommit.isEmpty ? '' : ' (${gitCommit.substring(0, gitCommit.length.clamp(0, 7))})';
    _diagnosticsVersion = '${info.version}+${info.buildNumber}$commit';
  } catch (error, stackTrace) {
    appLogger.d('Could not resolve the package version for diagnostics', error: error, stackTrace: stackTrace);
  }
}

/// Platform label for a failure record. Deliberately coarse — enough to
/// triage a report, never enough to identify a machine.
String _diagnosticsPlatform() => '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';

/// Whether an in-app repair can address [error].
///
/// Only preference-store damage qualifies. Everything else — a denied
/// directory, a locked database, a native library that will not load — needs
/// the environment to change, and offering a destructive repair for it would
/// be worse than offering nothing.
bool _isRepairable(Object error) {
  final cause = StartupPhaseException.unwrap(error);
  return cause is CorruptPreferenceStoreException || cause is UnreadableSensitivePreferenceException;
}

/// Default [StartupBootstrap.describeFailure].
@visibleForTesting
StartupFailureRecord describeStartupFailure(Object error, StackTrace stackTrace) => StartupFailureRecord.fromError(
  error: error,
  stackTrace: stackTrace,
  appVersion: _diagnosticsVersion,
  platform: _diagnosticsPlatform(),
  repairable: _isRepairable(error),
);

/// Whether `SentryFlutter.init` actually completed this launch.
///
/// The crash-reporting phase is best-effort, so init can fail or time out and
/// leave a no-op hub behind. A no-op hub accepts `captureMessage` and returns
/// an empty id *without throwing*, so "the send did not throw" is not evidence
/// that anything was sent.
var _crashReporterReady = false;

/// Sends a persisted startup failure to the crash reporter, once.
///
/// Reporting cannot happen where the failure is caught. The gate opens
/// preferences — the likeliest thing to fail, and the whole reason #1732 has
/// no telemetry — before crash reporting exists, so a capture there goes to a
/// no-op hub and is silently dropped. Initialising the reporter first is not
/// an option either: `_beforeSend` reads the crash-reporting opt-out from
/// settings, which are not loaded yet, so early events would bypass a user's
/// choice.
///
/// So every failure is persisted first and flushed here, immediately after
/// the reporter comes up with settings loaded. In practice that is the user's
/// own retry, seconds later, in the same process.
///
/// The record is only marked reported on proof of delivery — a non-empty
/// Sentry id — or when the user has opted out, which is a deliberate
/// suppression rather than a failure to retry. Anything else leaves it
/// pending for the next launch.
@visibleForTesting
Future<void> flushPendingStartupFailure({
  Future<SentryId> Function(StartupFailureRecord record)? send,
  bool? reporterReady,
  bool? crashReportingEnabled,
  bool? reportingCompiledIn,
}) async {
  final record = await StartupDiagnosticsStore.peekPersisted();
  if (record == null || record.reported) return;

  final optedIn = crashReportingEnabled ?? SettingsService.instanceOrNull?.read(SettingsService.crashReporting) ?? true;
  final canEverReport = reportingCompiledIn ?? _enableSentry;
  if (!optedIn || !canEverReport) {
    // Deliberate suppression, not a delivery failure. Marking it reported is
    // what lets `consumePrevious` eventually drop the file; without this a
    // fork build with no DSN, or an opted-out user, would carry the record
    // forever.
    appLogger.d(
      optedIn
          ? 'Startup failure not reported: crash reporting is not available in this build'
          : 'Startup failure not reported: crash reporting is disabled',
    );
    await StartupDiagnosticsStore.markReported(record);
    return;
  }

  if (!(reporterReady ?? _crashReporterReady)) {
    // Kept on disk deliberately: `consumePrevious` retains an unreported
    // record so the next launch can try again.
    appLogger.d('Startup failure kept for the next launch: crash reporting is not initialised');
    return;
  }

  try {
    final id = await (send ?? _captureStartupFailure)(record);
    if (id == const SentryId.empty()) {
      // A no-op hub, a disabled client, or an event dropped in `beforeSend`.
      appLogger.d('Startup failure was not accepted by the crash reporter; keeping it for the next launch');
      return;
    }
    await StartupDiagnosticsStore.markReported(record);
  } catch (error, stackTrace) {
    // Leave it unreported so the next launch tries again.
    appLogger.d('Could not report the startup failure', error: error, stackTrace: stackTrace);
  }
}

Future<SentryId> _captureStartupFailure(StartupFailureRecord record) {
  // The original error object is long gone by now; the record is the
  // allowlisted, already-redacted rendering of it.
  return Sentry.captureMessage(
    'Startup failed: ${record.headline}',
    level: SentryLevel.fatal,
    withScope: (scope) {
      scope.setTag('startup.phase', record.phaseId);
      scope.setContexts('startup', {
        'phase': record.phaseId,
        'errorType': record.errorType,
        'repairable': record.repairable,
        'when': record.timestamp.toUtc().toIso8601String(),
        'stackTrace': ?record.stackTrace,
      });
    },
  );
}

/// Default [StartupBootstrap.repair]: states the cost, runs the repair that
/// matches the failure, then reports what was kept and what was lost.
///
/// The result tells the bootstrap what it may do next; see
/// [StartupRepairResult]. Never returns [StartupRepairResult.retry] for a
/// repair that requires a restart — re-running initialization in that state
/// would destroy the salvage.
@visibleForTesting
Future<StartupRepairResult> repairStartupStorage(
  BuildContext context,
  StartupFailureRecord record,
  Object error,
) async {
  final cause = StartupPhaseException.unwrap(error);
  final unreadableKey = cause is UnreadableSensitivePreferenceException ? cause.key : null;
  final reopenSafe = cause is! CorruptPreferenceStoreException || cause.reopenSafe;

  // Name the real cost before touching anything, not the usual one. Servers
  // and profiles survive a repair only because their tokens are ciphertext in
  // the database and the key that decrypts them lives in the store — so a
  // store the key cannot be read out of signs the user out of everything. An
  // all-zero file is exactly that case (#1732), and telling them their
  // sign-ins are safe would be a promise the outcome dialog then contradicts.
  final signInsSurvive = unreadableKey != null
      ? unreadableKey != credentialVaultKeyPref
      : (await PrefsRecovery.previewSalvage()).vaultKey != null;
  if (!context.mounted) return StartupRepairResult.none;

  final confirmed = await showConfirmDialog(
    context,
    title: t.startup.repairTitle,
    message: repairConsentMessage(oneCredential: unreadableKey != null, signInsSurvive: signInsSurvive),
    confirmText: t.startup.repairConfirm,
    isDestructive: true,
  );
  if (!confirmed || !context.mounted) return StartupRepairResult.none;

  final outcome = unreadableKey != null
      ? await BaseSharedPreferencesService.dropUnreadableCredential(unreadableKey)
      : await BaseSharedPreferencesService.repairCorruptStore(reopenSafe: reopenSafe);
  // The repair replaced or dropped entries in the backing store, so the vault's
  // memoized key and its ciphertext -> plaintext cache now describe a store
  // that no longer exists. Drop both before anything reads a credential again,
  // or a repaired install could keep serving pre-repair plaintext.
  CredentialVault.invalidateCache();
  final result = outcome.requiresRestart ? StartupRepairResult.restart : StartupRepairResult.retry;
  if (!context.mounted) return result;

  await showRepairOutcomeDialog(context, outcome);
  return result;
}

/// The consent dialog's body: what is being repaired, then what it costs.
///
/// Separated from [repairStartupStorage] because the two halves fail
/// differently. Deciding whether the sign-ins survive is I/O against a
/// damaged file; deciding what to *tell* the user about it is a promise, and
/// #1732 is what happens when the promise is written once, optimistically,
/// for a case that does not always hold.
///
/// [signInsSurvive] covers servers and profiles only. Their tokens are
/// ciphertext in the database, so they live or die with the vault key —
/// which is exactly why that one value decides this sentence.
///
/// Tracker and Seerr sessions are plaintext preference entries, salvaged and
/// reseeded one by one and untouched entirely by the single-credential
/// repair. They therefore do not follow the vault key in either direction,
/// and get one cautious sentence in both branches rather than a promise
/// borrowed from a value that does not govern them.
@visibleForTesting
String repairConsentMessage({required bool oneCredential, required bool signInsSurvive}) => [
  oneCredential ? t.startup.repairBodyOneCredential : t.startup.repairBodyCommon,
  signInsSurvive ? t.startup.repairBodySignInsKept : t.startup.repairBodySignInsLost,
  t.startup.repairBodySessionsUncertain,
].join('\n\n');

/// Reports a completed repair, including the retained copy of the damaged
/// store.
///
/// The backup path is shown so the user can find and delete it, never so it
/// can be attached to a report: it can hold the credential-vault key, tracker
/// refresh tokens and Seerr cookies in plaintext. The warning is suppressed
/// only when the quarantined *bytes* prove there is nothing in them — an
/// all-zero file (#1732) — never on the strength of what the salvage managed
/// to recover, which says nothing about what is still in the file. A warning
/// on a file of zeros is the one that teaches users to ignore the warning
/// that matters.
@visibleForTesting
Future<void> showRepairOutcomeDialog(
  BuildContext context,
  PrefsRepairOutcome outcome, {
  // Test seam: the widget-test binding's fake-async zone never completes a
  // `dart:io` future, so a real delete cannot be driven from a widget test.
  Future<void> Function(String path) deleteBackup = PrefsRecovery.deleteBackup,
}) {
  final backupPath = outcome.backupPath;
  // Outside the builder: a `StatefulBuilder` re-runs its closure on every
  // rebuild, so state declared inside it would reset the moment the rebuild it
  // triggered arrives — leaving the sensitive path on screen after deletion.
  var deleted = false;
  return showScopedDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        return AlertDialog(
          title: Text(outcome.requiresRestart ? t.startup.repairNeedsRestart : t.startup.repairSucceeded),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(outcome.vaultKeySalvaged ? t.startup.repairKeptSignIns : t.startup.repairLostSignIns),
              if (outcome.sessionsAffected) ...[const SizedBox(height: 8), Text(t.startup.repairLostSessions)],
              if (backupPath != null && !deleted) ...[
                const SizedBox(height: 16),
                Text(t.startup.backupTitle, style: Theme.of(dialogContext).textTheme.titleSmall),
                const SizedBox(height: 4),
                SelectableText(backupPath, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                if (outcome.backupHoldsCredentials) ...[
                  const SizedBox(height: 4),
                  Text(t.startup.backupWarning, style: TextStyle(color: Theme.of(dialogContext).colorScheme.error)),
                ],
                const SizedBox(height: 8),
                DialogActionButton(
                  label: t.startup.deleteBackup,
                  onPressed: () async {
                    await deleteBackup(backupPath);
                    // The barrier can dismiss this dialog while the delete is
                    // in flight; the file is gone either way.
                    if (!dialogContext.mounted) return;
                    setDialogState(() => deleted = true);
                  },
                ),
              ],
              if (deleted) ...[const SizedBox(height: 8), Text(t.startup.backupDeleted)],
            ],
          ),
          actions: [
            DialogActionButton(
              autofocus: true,
              isPrimary: true,
              onPressed: () => Navigator.of(dialogContext).pop(),
              label: t.common.close,
            ),
          ],
        );
      },
    ),
  );
}

/// Theme the startup frames adopt once the persisted preference is readable.
typedef StartupThemeResolution = ({material.ThemeMode themeMode, ThemeData darkTheme});

/// Mounts a Flutter-owned startup frame before invoking the asynchronous
/// initialization gate. The generic seam keeps frame ordering, failure, and
/// retry behavior testable without constructing platform services.
@visibleForTesting
class StartupBootstrap<T> extends StatefulWidget {
  const StartupBootstrap({
    super.key,
    required this.initialize,
    required this.buildApp,
    this.discard,
    this.onCommitted,
    this.describeFailure = describeStartupFailure,
    this.repair = repairStartupStorage,
    this.lightTheme,
    this.darkTheme,
    this.themeMode = material.ThemeMode.system,
    this.resolveTheme,
    this.transparentWhileLoading = false,
  });

  final Future<T> Function() initialize;
  final Widget Function(BuildContext context, T value) buildApp;
  final FutureOr<void> Function(T value)? discard;
  final FutureOr<void> Function(T value)? onCommitted;

  /// Reduces a thrown error to the allowlisted record the failure screen,
  /// the persisted diagnostic and the crash report all share.
  final StartupFailureRecord Function(Object error, StackTrace stackTrace) describeFailure;

  /// Offers the user a consented repair for a recoverable failure and reports
  /// what the gate may do next. [StartupRepairResult.retry] re-runs
  /// [initialize]; [StartupRepairResult.restart] parks the app on the failure
  /// screen, because nothing may touch preferences until the process restarts.
  ///
  /// The context is a descendant of the gate's own bootstrap [MaterialApp]
  /// (never the gate `State`'s context, which sits above it), so dialogs and
  /// snackbars can resolve a `Navigator`, `MaterialLocalizations` and
  /// `ScaffoldMessenger` from it.
  final Future<StartupRepairResult> Function(BuildContext context, StartupFailureRecord record, Object error)? repair;

  final ThemeData? lightTheme;
  final ThemeData? darkTheme;
  final material.ThemeMode themeMode;

  /// Reads the persisted theme so the startup frames match the one the app
  /// settles on. Until it answers, [themeMode] resolves from platform
  /// brightness, which disagrees with the app's own default on every device
  /// that reports light while running the dark or OLED theme (#1833).
  final Future<StartupThemeResolution> Function()? resolveTheme;

  /// Whether the platform window behind Flutter already paints the launch
  /// background, so the loading frame must not cover it.
  ///
  /// True only on Android, where `TransparencyMode.transparent` lets the
  /// window decor show through and `MainActivity` has already restored the
  /// persisted launch colour.
  final bool transparentWhileLoading;

  @override
  State<StartupBootstrap<T>> createState() => _StartupBootstrapState<T>();
}

class _StartupBootstrapState<T> extends State<StartupBootstrap<T>> {
  T? _value;
  StartupFailureRecord? _failure;

  /// Retained alongside [_failure] so the repair hook can classify the real
  /// cause; the record is a redacted allowlist and deliberately cannot.
  Object? _failureError;
  bool _completed = false;
  bool _initializing = false;
  bool _repairing = false;

  /// Terminal: the store was repaired but the plugin still holds the bad
  /// document, so this process can never open it. Latched, never cleared —
  /// re-running the gate from here would flush the stale map over the seed.
  bool _restartRequired = false;
  int _generation = 0;

  /// Persisted theme for the startup frames, null until [StartupBootstrap.resolveTheme] answers.
  StartupThemeResolution? _resolvedTheme;

  @override
  void initState() {
    super.initState();
    unawaited(_resolveTheme());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AndroidExitDiagnostics.markStartupPhase(AndroidStartupPhase.firstFrame);
      if (mounted) unawaited(_initialize());
    });
  }

  /// Adopts the persisted theme for the startup frames.
  ///
  /// Deliberately best-effort and unbounded: on Android the loading frame is
  /// transparent, so a slow answer costs spinner contrast rather than the
  /// launch, and a store this cannot read is the gate's failure to report —
  /// reporting it twice would race the diagnostic record.
  Future<void> _resolveTheme() async {
    final resolve = widget.resolveTheme;
    if (resolve == null) return;
    try {
      final resolved = await resolve();
      if (!mounted) return;
      setState(() => _resolvedTheme = resolved);
    } catch (error, stackTrace) {
      appLogger.d('Could not resolve the persisted startup theme', error: error, stackTrace: stackTrace);
    }
  }

  Future<void> _initialize() async {
    if (_initializing) return;

    final generation = ++_generation;
    setState(() {
      _failure = null;
      _initializing = true;
    });

    try {
      final value = await widget.initialize();
      if (!mounted || generation != _generation) {
        await _discard(value);
        return;
      }

      setState(() {
        _value = value;
        _completed = true;
        _initializing = false;
      });
      // A launch that got through is the first chance to surface a record
      // written by one that did not. Consuming it takes the file off disk and
      // holds the contents in memory for Settings › Logs, so the user can
      // upload the failure that had no other way out (#1732).
      unawaited(StartupDiagnosticsStore.consumePrevious());
      unawaited(Future.sync(() => widget.onCommitted?.call(value)));
    } catch (error, stackTrace) {
      final failure = widget.describeFailure(error, stackTrace);
      // `headline` is the sanitised rendering; the raw error is deliberately
      // not passed, because `FormatException.toString()` embeds an excerpt of
      // whatever document failed to parse.
      appLogger.e('Startup initialization failed: ${failure.headline}', stackTrace: stackTrace);
      // Persist first: this record is the only thing that survives the
      // process. On Windows there is no log file and no console for a
      // double-clicked release build.
      unawaited(StartupDiagnosticsStore.record(failure));
      // Not reported from here: the earliest phases run before the crash
      // reporter exists, so the record is persisted and flushed by
      // `flushPendingStartupFailure` once it is up — on the retry below, or on
      // the next launch.
      if (!mounted || generation != _generation) return;
      setState(() {
        _failure = failure;
        _failureError = error;
        _initializing = false;
      });
    }
  }

  /// [context] must sit below the bootstrap `MaterialApp` — it comes from the
  /// `home` builder in [_buildBootstrapHome]. The gate `State`'s own context
  /// is above that `MaterialApp` and has no `Navigator`,
  /// `MaterialLocalizations` or `ScaffoldMessenger`, so the repair dialogs and
  /// the failure snackbar would all throw when built from it.
  Future<void> _repair(BuildContext context, StartupFailureRecord failure) async {
    final repair = widget.repair;
    final error = _failureError;
    if (repair == null || error == null || _repairing || _restartRequired) return;
    setState(() => _repairing = true);
    var result = StartupRepairResult.none;
    try {
      result = await repair(context, failure, error);
    } catch (error, stackTrace) {
      appLogger.e('Startup storage repair failed', error: error, stackTrace: stackTrace);
      if (context.mounted) showErrorSnackBar(context, t.startup.repairFailed);
    }
    if (!mounted) return;
    setState(() {
      _repairing = false;
      if (result == StartupRepairResult.restart) _restartRequired = true;
    });
    if (result == StartupRepairResult.retry) unawaited(_initialize());
  }

  Future<void> _discard(T value) async {
    try {
      await widget.discard?.call(value);
    } catch (error, stackTrace) {
      appLogger.e('Failed to dispose an uncommitted startup result (${error.runtimeType})', stackTrace: stackTrace);
    }
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_completed) return widget.buildApp(context, _value as T);

    final resolved = _resolvedTheme;
    return TranslationProvider(
      child: Builder(
        builder: (context) => InputModeTracker(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: widget.lightTheme,
            darkTheme: resolved?.darkTheme ?? widget.darkTheme,
            themeMode: resolved?.themeMode ?? widget.themeMode,
            home: Builder(builder: _buildBootstrapHome),
          ),
        ),
      ),
    );
  }

  Widget _buildBootstrapHome(BuildContext context) {
    final failure = _failure;
    if (failure != null) {
      return Scaffold(
        body: StartupFailureView(
          failure: failure,
          busy: _initializing || _repairing,
          restartRequired: _restartRequired,
          onRetry: () => unawaited(_initialize()),
          onRepair: failure.repairable && widget.repair != null ? () => _repair(context, failure) : null,
        ),
      );
    }

    // Nothing here is worth covering the launch screen for. The platform
    // window already holds the user's launch colour, and this frame outlives
    // the whole gate, so painting a theme guessed from platform brightness is
    // what turned a black Android TV splash into a flashbang (#1833).
    return Scaffold(
      backgroundColor: widget.transparentWhileLoading ? Colors.transparent : null,
      body: const Center(child: CircularProgressIndicator(key: startupBootstrapProgressKey)),
    );
  }
}

class _StartupDependencies {
  const _StartupDependencies({
    required this.settings,
    required this.storage,
    required this.appDatabase,
    required this.databaseRecoveryOutcome,
  });

  final SettingsService settings;
  final StorageService storage;
  final AppDatabase appDatabase;
  final TvosDatabaseRecoveryOutcome databaseRecoveryOutcome;
}

@visibleForTesting
Future<AppDatabaseBootstrap> openAppDatabaseWithDownloadRecovery({
  required Future<AppDatabaseBootstrap> Function() openDatabase,
  required Future<void> Function() recoverNativeDownloads,
  required String storageFullMessage,
}) async {
  try {
    return await openDatabase();
  } catch (error, stackTrace) {
    if (!isStorageFullError(error)) rethrow;
    appLogger.w(
      'Application database could not open because storage is full; discarding interrupted downloads',
      error: error,
      stackTrace: stackTrace,
    );
  }

  await recoverNativeDownloads();
  final bootstrap = await openDatabase();
  try {
    final failedKeys = await bootstrap.database.failActiveDownloadsForStorageFull(storageFullMessage);
    appLogger.w('Recovered startup after storage exhaustion; stopped ${failedKeys.length} active download(s)');
    return bootstrap;
  } catch (_) {
    // The caller only takes ownership once this helper returns, so the freshly
    // opened background isolate has to be released here.
    await bootstrap.database.close();
    rethrow;
  }
}

Future<_StartupDependencies> _initializeStartup(SettingsService settings) async {
  final startupWatch = Stopwatch()..start();
  var lastStartupMarkMs = 0;
  void markStartupPhase(String phase) {
    if (!kProfileMode) return;
    final elapsedMs = startupWatch.elapsedMilliseconds;
    appLogger.i('Startup phase $phase: ${elapsedMs - lastStartupMarkMs}ms (total ${elapsedMs}ms)');
    lastStartupMarkMs = elapsedMs;
  }

  AppDatabase? openedDatabase;
  try {
    // Slang builds the base locale eagerly, so `t` already resolves before
    // this runs; a failure here degrades to English rather than no app.
    await _optionalGatePhase(StartupPhase.locale, () async {
      final savedLocale = settings.read(SettingsService.appLocale);
      await LocaleSettings.setLocale(savedLocale);
    });
    markStartupPhase('locale');

    // Window chrome is cosmetic; losing it costs the custom titlebar and the
    // remembered size, not the app. It is also the step most exposed to a
    // stalled platform thread, so it must not sit in the same combined future
    // as the services the first build genuinely needs.
    if (PlatformDetector.isDesktopOS()) {
      await _optionalGatePhase(StartupPhase.windowManager, () async {
        await windowManager.ensureInitialized();
        if (Platform.isMacOS) await MacOSWindowService.setupCustomTitlebar();
      });
    }

    // MainApp reads both synchronous facades during its first build, and both
    // have a working sync fallback, so a detection failure is not fatal.
    await _optionalGatePhase(StartupPhase.deviceCapabilities, () async {
      await (
        TvDetectionService.getInstance(forceTv: settings.read(SettingsService.forceTvMode)),
        DevicePerformance.getInstance(override: settings.read(SettingsService.visualEffects)),
      ).wait;
    });

    final storage = await _gatePhase(StartupPhase.storage, StorageService.getInstance);
    markStartupPhase('platform-services');

    AndroidExitDiagnostics.markStartupPhase(AndroidStartupPhase.databaseOpenStarted);
    final databaseBootstrap = await _gatePhase(
      StartupPhase.database,
      () => openAppDatabaseWithDownloadRecovery(
        openDatabase: () => AppDatabase.open(isTvos: PlatformDetector.isAppleTV()),
        recoverNativeDownloads: DownloadManagerService.discardInterruptedNativeDownloadsAfterStorageFailure,
        storageFullMessage: t.downloads.storageFull,
      ),
    );
    openedDatabase = databaseBootstrap.database;
    AndroidExitDiagnostics.markStartupPhase(AndroidStartupPhase.databaseReady);
    markStartupPhase('database-recovery');

    await _optionalGatePhase(StartupPhase.imageCache, () async => DevicePerformance.applyImageCacheBudget());

    markStartupPhase('image-cache');

    return _StartupDependencies(
      settings: settings,
      storage: storage,
      appDatabase: databaseBootstrap.database,
      databaseRecoveryOutcome: databaseBootstrap.recoveryOutcome,
    );
  } catch (_) {
    await openedDatabase?.close();
    rethrow;
  }
}

void _startNonessentialInitialization(SettingsService settings) {
  // `onCommitted` runs before the rebuild that creates MainApp. Share one
  // end-of-frame hop so synchronous tasks cannot delay its first frame.
  final afterFirstAppFrame = WidgetsBinding.instance.endOfFrame;

  void bestEffort(String name, FutureOr<void> Function() action) {
    unawaited(
      afterFirstAppFrame.then((_) => action()).catchError((Object error, StackTrace stackTrace) {
        appLogger.e('$name startup task failed (${error.runtimeType})', stackTrace: stackTrace);
      }),
    );
  }

  bestEffort(
    'Date formatting',
    () => initializeDateFormatting(settings.read(SettingsService.appLocale).intlLocaleName, null),
  );
  bestEffort('Download storage', () => DownloadStorageService.instance.initialize(settings));
  bestEffort('Trackers', TrackerCoordinator.instance.initialize);

  bestEffort('Legacy image cache cleanup', () async {
    if (settings.read(SettingsService.cleanedOldImageCache)) return;
    try {
      final tempDir = await getTemporaryDirectory();
      final oldCacheDir = Directory('${tempDir.path}/plexImageCache');
      if (await oldCacheDir.exists()) await oldCacheDir.delete(recursive: true);
    } finally {
      await settings.write(SettingsService.cleanedOldImageCache, true);
    }
  });

  bestEffort('Native window', () {
    if (Platform.isAndroid) PipService();
    NativeWindowService.initialize();
  });

  bestEffort('Fullscreen monitor', () async {
    FullscreenStateManager().startMonitoring();
    if (PlatformDetector.isDesktopOS() && settings.read(SettingsService.startInFullscreen)) {
      await FullscreenStateManager().enterFullscreen();
    }
  });

  bestEffort('Gamepad', () {
    GamepadService.instance.start();
    if (PlatformDetector.isAppleTV()) AppleTvRemoteTouchService.instance.start();
  });

  if (PlatformDetector.isDesktopOS()) {
    bestEffort('Discord RPC', DiscordRPCService.instance.initialize);
    // Detection forks helper processes; resolve it here so the External Player
    // settings page never has to wait on a cold probe.
    bestEffort('External player detection', KnownPlayers.getForCurrentPlatform);
  }

  if (settings.read(SettingsService.crashReporting)) {
    unawaited(AndroidExitDiagnostics.logPreviousExit());
  }

  bestEffort('Shader licenses', _registerShaderLicenses);
  // The startup-gate application can precede the engine's first metrics
  // report, which reads as a 1.0 display budget; re-derive it now that the
  // tree is mounted and the display is known.
  bestEffort('Image cache budget', DevicePerformance.applyImageCacheBudget);
  bestEffort('Environment diagnostics', _logEnvironmentDiagnostics);
}

Future<void> _logEnvironmentDiagnostics() async {
  final packageInfo = await PackageInfo.fromPlatform();
  final commitSuffix = gitCommit.isNotEmpty ? ' (${gitCommit.substring(0, 7)})' : '';
  String renderer = '';
  if (Platform.isAndroid) {
    final rendererName = await const MethodChannel('com.plezy/theme').invokeMethod<String>('getRenderer');
    renderer = ' [$rendererName]';
    await Future.sync(() => Sentry.configureScope((scope) => scope.setTag('renderer', rendererName ?? 'unknown')));
  }
  appLogger.i(
    'Plezy v${packageInfo.version}+${packageInfo.buildNumber}$commitSuffix$renderer'
    ' [effects: ${DevicePerformance.describeSync()}]',
  );
  appLogger.i('Display: ${DevicePerformance.describeDisplay()}');
  if (Platform.isAndroid) {
    appLogger.i('Startup RSS: ${ProcessInfo.currentRss >> 20}MB');
  }
}

Breadcrumb? _beforeBreadcrumb(Breadcrumb? breadcrumb, Hint _) {
  if (breadcrumb == null) return null;

  final message = breadcrumb.message;
  final data = breadcrumb.data;
  if (message == null && (data == null || data.isEmpty)) return breadcrumb;

  if (message != null) breadcrumb.message = LogRedactionManager.redact(message);
  if (data != null) breadcrumb.data = data.map((k, v) => MapEntry(k, v is String ? LogRedactionManager.redact(v) : v));
  return breadcrumb;
}

FutureOr<SentryEvent?> _beforeSend(SentryEvent event, Hint _) {
  // Drop event if user opted out of crash reporting.
  final instance = SettingsService.instanceOrNull;
  if (instance != null && !instance.read(SettingsService.crashReporting)) return null;

  // Drop unactionable errors
  final exceptions = event.exceptions;
  if (exceptions != null) {
    bool shouldDrop(SentryException e) {
      final v = e.value;
      final lowerValue = v?.toLowerCase();
      // Windows file-lock errors from cache manager cleanup
      if (e.type == 'FileSystemException' && v != null && v.contains('plexImageCache') && v.contains('errno = 32')) {
        return true;
      }
      if (e.type == 'FileSystemException' &&
          lowerValue != null &&
          lowerValue.contains('cached_network_image_ce') &&
          (lowerValue.contains('lock failed') || lowerValue.contains('writefrom failed'))) {
        return true;
      }
      // Linux without DBus/NetworkManager
      if (e.type == 'DBusServiceUnknownException' || (v != null && v.contains('system_bus_socket'))) {
        return true;
      }
      // Device out of disk space
      if (isStorageFullMessage(v)) return true;
      // Native HTTP errors from CFNetwork (server errors, not actionable)
      if (e.type == 'HTTPClientError') return true;
      // Benign EventChannel teardown race: the engine replies this when a
      // 'cancel' lands after the stream is already gone, and the framework
      // reports it via FlutterError — nothing was ever wrong user-side.
      if (e.type == 'PlatformException' && v != null && v.contains('No active stream to cancel')) return true;
      // Discord RPC errors when Discord is not running
      if (e.type == 'DiscordStateException') return true;
      return false;
    }

    if (exceptions.any(shouldDrop)) return null;

    // Scrub Plex tokens and server URLs from exception messages
    for (final e in exceptions) {
      final value = e.value;
      if (value != null) {
        e.value = LogRedactionManager.redact(value);
      }
    }
  }

  // Enrich TimeoutException with operation name + duration as tags/fingerprint.
  // value format: "TimeoutException after 0:00:05.000000: <operation> timed out"
  if (exceptions != null) {
    final timeoutException = exceptions.where((e) => e.type == 'TimeoutException').firstOrNull;
    if (timeoutException != null) {
      final value = timeoutException.value ?? '';
      final colonIdx = value.indexOf(': ');
      final message = colonIdx >= 0 ? value.substring(colonIdx + 2) : value;
      final operation = message.endsWith(' timed out')
          ? message.substring(0, message.length - ' timed out'.length)
          : null;
      final durationMatch = RegExp(r'after (\d+:\d{2}:\d{2}\.\d+)').firstMatch(value);

      final tags = event.tags ??= {};
      if (operation != null) tags['timeout.operation'] = operation;
      if (durationMatch != null) tags['timeout.duration'] = durationMatch.group(1)!;
      event.fingerprint = ['TimeoutException', ?operation];
    }
  }

  // Scrub breadcrumb messages and data
  final breadcrumbs = event.breadcrumbs;
  if (breadcrumbs != null) {
    for (final b in breadcrumbs) {
      final message = b.message;
      final data = b.data;
      if (message != null) b.message = LogRedactionManager.redact(message);
      if (data != null) b.data = data.map((k, v) => MapEntry(k, v is String ? LogRedactionManager.redact(v) : v));
    }
  }

  return event;
}

void _registerShaderLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks(
      ['Anime4K'],
      'MIT License\n'
      '\n'
      'Copyright (c) 2019-2021 bloc97\n'
      'All rights reserved.\n'
      '\n'
      'Permission is hereby granted, free of charge, to any person obtaining a copy '
      'of this software and associated documentation files (the "Software"), to deal '
      'in the Software without restriction, including without limitation the rights '
      'to use, copy, modify, merge, publish, distribute, sublicense, and/or sell '
      'copies of the Software, and to permit persons to whom the Software is '
      'furnished to do so, subject to the following conditions:\n'
      '\n'
      'The above copyright notice and this permission notice shall be included in all '
      'copies or substantial portions of the Software.\n'
      '\n'
      'THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR '
      'IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, '
      'FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE '
      'AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER '
      'LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, '
      'OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE '
      'SOFTWARE.',
    );
    yield const LicenseEntryWithLineBreaks(
      ['NVIDIA Image Scaling (NVScaler)'],
      'The MIT License (MIT)\n'
      '\n'
      'Copyright (c) 2022 NVIDIA CORPORATION & AFFILIATES. All rights reserved.\n'
      '\n'
      'Permission is hereby granted, free of charge, to any person obtaining a copy of '
      'this software and associated documentation files (the "Software"), to deal in '
      'the Software without restriction, including without limitation the rights to '
      'use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of '
      'the Software, and to permit persons to whom the Software is furnished to do so, '
      'subject to the following conditions:\n'
      '\n'
      'The above copyright notice and this permission notice shall be included in all '
      'copies or substantial portions of the Software.\n'
      '\n'
      'THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR '
      'IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS '
      'FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR '
      'COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER '
      'IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN '
      'CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.',
    );
  });
}

final rootNavigatorKey = GlobalKey<NavigatorState>();

@visibleForTesting
bool shouldEnterOfflineModeAfterStartupBind({required bool bindingSucceeded, required bool hasOnlineServers}) {
  return !bindingSucceeded && !hasOnlineServers;
}

/// Top-level PIN prompt used by [ActiveProfileBinder] when it runs above the
/// profile-scoped widget tree. Routes through the app-global
/// [rootNavigatorKey] so the dialog survives profile-session remounts. Returns
/// `null` when no Navigator is available yet (early boot, post-dispose) so the
/// binder treats it as "PIN cancelled".
Future<String?> _rootPinPrompt(Profile profile, {String? errorMessage}) {
  final ctx = rootNavigatorKey.currentContext;
  if (ctx == null) return Future.value(null);
  return showPinEntryDialog(ctx, profile.displayName, errorMessage: errorMessage);
}

class MainApp extends StatefulWidget {
  final SettingsService settings;
  final StorageService storage;
  final AppDatabase appDatabase;
  final TvosDatabaseRecoveryOutcome databaseRecoveryOutcome;

  const MainApp({
    super.key,
    required this.settings,
    required this.storage,
    required this.appDatabase,
    required this.databaseRecoveryOutcome,
  });

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  late final MultiServerManager _serverManager;
  late final DataAggregationService _aggregationService;
  late final AppDatabase _appDatabase;
  late final DownloadManagerService _downloadManager;
  late final OfflineWatchSyncService _offlineWatchSyncService;
  late final AppLifecycleListener _appLifecycleListener;
  StreamSubscription<WatchStateEvent>? _watchStateSubscription;

  /// WiFi-reconnect sync trigger, listening on [OfflineModeProvider] — the
  /// app's single connectivity subscription lives there.
  VoidCallback? _connectivitySyncListener;
  OfflineModeProvider? _connectivitySyncProvider;
  Timer? _syncDebounce;
  final Set<String> _pendingSyncKeys = <String>{};
  bool _isAutoDeleteRunning = false;
  bool _lastConnectivityWasWifi = false;
  bool _lastConnectivityHadNetwork = true;
  bool _shutdownStarted = false;

  /// Last time server health probes ran from a resume event (cooldown for desktop)
  DateTime _lastResumeProbe = DateTime(0);

  /// Periodic RSS watchdog timer (desktop + Android).
  Timer? _memoryCheckTimer;

  /// Last watchdog eviction, for the cooldown; RSS at that moment so a
  /// still-climbing RSS can re-evict inside the cooldown window.
  DateTime _lastRssEviction = DateTime(0);
  int _lastEvictionRss = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // The watchdog's first useful sample is at least 15 seconds away; install
    // its timer only after the first app frame has completed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startRssWatchdog();
    });

    _serverManager = MultiServerManager();
    _aggregationService = DataAggregationService(_serverManager);
    _appDatabase = widget.appDatabase;

    PlexApiCache.initialize(_appDatabase);
    JellyfinApiCache.initialize(_appDatabase);

    _downloadManager = DownloadManagerService(
      database: _appDatabase,
      storageService: DownloadStorageService.instance,
      clientResolver: _serverManager.resolveDownloadClient,
    );
    // Keep the awaitable assigned synchronously, but do not let recovery's
    // Drift/native work compete with SetupScreen's first frame.
    _downloadManager.recoveryFuture = WidgetsBinding.instance.endOfFrame.then(
      (_) => _downloadManager.recoverInterruptedDownloads(),
    );

    _offlineWatchSyncService = OfflineWatchSyncService(database: _appDatabase, serverManager: _serverManager);

    _appLifecycleListener = AppLifecycleListener(
      onExitRequested: () async {
        await _shutdownForExit();
        return AppExitResponse.exit;
      },
    );
  }

  Future<void> _shutdownForExit() async {
    if (_shutdownStarted) return;
    _shutdownStarted = true;

    // Hide the window before anything else so the exit reads as an instant
    // close: the teardown below runs against a still-mounted tree and its
    // state churn must never be user-visible. Cmd+Q and OS-initiated exits
    // arrive here directly, so the close-button path is not the only entry.
    // Bounded — hide() is a platform-channel round trip and a stalled
    // platform thread must not hold the already-accepted exit open.
    if (PlatformDetector.isDesktopOS()) {
      try {
        await windowManager.hide().timeout(const Duration(seconds: 1));
      } catch (e, st) {
        appLogger.w('Failed to hide window before exit teardown', error: e, stackTrace: st);
      }
    }

    _syncDebounce?.cancel();
    await _watchStateSubscription?.cancel();
    _removeConnectivitySyncListener();
    _memoryCheckTimer?.cancel();

    _downloadManager.dispose();
    // Quitting straight from the player is a real stop: the trackers that own
    // their own watched semantics need the terminal report before the process
    // goes away. Bounded — a hung tracker must not hold the app open.
    await TrackerCoordinator.instance.stopPlayback().timeout(const Duration(seconds: 3), onTimeout: () {});
    TrackerCoordinator.instance.cancelInFlight();

    await _serverManager.shutdown();
    await Future.wait([
      httpClient.closeGracefully(drainTimeout: const Duration(seconds: 5)),
      closeArtworkHttpClientGracefully(),
    ], eagerError: false);
    await ManagedHttpClient.closeAllGracefully();
    await _appDatabase.close();
  }

  @override
  void dispose() {
    _syncDebounce?.cancel();
    _watchStateSubscription?.cancel();
    _removeConnectivitySyncListener();
    _memoryCheckTimer?.cancel();
    _appLifecycleListener.dispose();
    if (!_shutdownStarted) {
      _downloadManager.dispose();
      _serverManager.dispose();
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didHaveMemoryPressure() {
    super.didHaveMemoryPressure();
    appLogger.w('System memory pressure, evicting image caches');
    _evictImageCaches();
  }

  /// RSS-based image-cache eviction. Desktop keeps its fixed 1.5GB bar;
  /// Android scales to the device because LMK on a 2GB TV box kills well
  /// below any fixed desktop threshold — and Android trim callbacks
  /// ([didHaveMemoryPressure]) are best-effort, LMK can kill without ever
  /// delivering one (#1349).
  void _startRssWatchdog() {
    final int threshold;
    final Duration period;
    if (PlatformDetector.isDesktopOS()) {
      threshold = 1536 << 20; // 1.5GB
      period = const Duration(seconds: 30);
    } else if (Platform.isAndroid) {
      final totalMem = DevicePerformance.totalMemBytes;
      threshold = totalMem != null ? (totalMem * 0.45).round().clamp(512 << 20, 1536 << 20) : 1 << 30;
      // Decode bursts can spike RSS in seconds on low-end boxes; the read
      // itself is an in-process syscall, cheap enough for a short period.
      period = DevicePerformance.isLowEndHardware ? const Duration(seconds: 15) : const Duration(seconds: 30);
    } else {
      return; // iOS/tvOS: jetsam pressure arrives via didHaveMemoryPressure.
    }

    _memoryCheckTimer = Timer.periodic(period, (_) {
      final rss = ProcessInfo.currentRss;
      if (rss <= threshold) return;
      final cache = PaintingBinding.instance.imageCache;
      // Floor + cooldown: clearing an already-small cache buys nothing, and
      // refetch churn is its own memory-spike and jank source. Inside the
      // cooldown, re-evict only if RSS kept climbing past the last eviction.
      if (cache.currentSizeBytes < (8 << 20)) return;
      final now = DateTime.now();
      final inCooldown = now.difference(_lastRssEviction) < const Duration(seconds: 60);
      if (inCooldown && rss <= _lastEvictionRss) return;
      _lastRssEviction = now;
      _lastEvictionRss = rss;
      appLogger.w(
        'RSS high (${rss >> 20}MB > ${threshold >> 20}MB), evicting image caches '
        '(cache ${cache.currentSizeBytes >> 20}MB/${cache.currentSize} images, ${cache.liveImageCount} live)',
      );
      _evictImageCaches();
    });
  }

  void _evictImageCaches() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  /// Two connectivity-driven triggers, both listening on [OfflineModeProvider],
  /// which owns the app's single connectivity subscription:
  ///
  /// * [_autoDeleteAndSync] on each WiFi/Ethernet reconnect, so download rules
  ///   run as soon as the device is back on an unmetered link. Rapid flapping is
  ///   bounded by the executor's cooldown.
  /// * A tracker write-queue flush whenever the network comes back at all,
  ///   metered included: tracker history writes are internet calls, so they can
  ///   land while media servers are still unreachable and the app stays offline.
  void _startConnectivitySyncTrigger(DownloadProvider downloadProvider, OfflineModeProvider offlineModeProvider) {
    _removeConnectivitySyncListener();
    _lastConnectivityWasWifi = offlineModeProvider.hasWifiOrEthernet;
    _lastConnectivityHadNetwork = offlineModeProvider.hasNetworkConnection;
    _connectivitySyncProvider = offlineModeProvider;
    _connectivitySyncListener = () {
      final hasWifi = offlineModeProvider.hasWifiOrEthernet;
      final movedOntoWifi = hasWifi && !_lastConnectivityWasWifi;
      _lastConnectivityWasWifi = hasWifi;

      final hasNetwork = offlineModeProvider.hasNetworkConnection;
      final networkRestored = hasNetwork && !_lastConnectivityHadNetwork;
      _lastConnectivityHadNetwork = hasNetwork;

      if (networkRestored) {
        appLogger.d('Network restored — replaying queued tracker writes');
        unawaited(TrackerCoordinator.instance.flushWriteQueue());
      }
      if (movedOntoWifi) {
        appLogger.d('Connectivity moved onto WiFi/Ethernet — triggering sync pass');
        _autoDeleteAndSync(downloadProvider);
      }
    };
    offlineModeProvider.addListener(_connectivitySyncListener!);
  }

  void _removeConnectivitySyncListener() {
    final listener = _connectivitySyncListener;
    if (listener != null) _connectivitySyncProvider?.removeListener(listener);
    _connectivitySyncListener = null;
    _connectivitySyncProvider = null;
  }

  /// Run auto-delete (if enabled) and then a sync-rule pass.
  ///
  /// When [targetKeys] is non-null, only those rules are re-evaluated
  /// (cooldown doesn't apply — targeted runs are always "we know this
  /// changed"). When null, every rule runs via the executor, with [force]
  /// gating the cooldown: `true` for user-initiated drains, `false` for
  /// background probes like a connectivity reconnect.
  Future<void> _autoDeleteAndSync(
    DownloadProvider downloadProvider, {
    List<String>? targetKeys,
    bool force = false,
  }) async {
    if (_isAutoDeleteRunning) {
      if (targetKeys != null) _pendingSyncKeys.addAll(targetKeys);
      return;
    }
    _isAutoDeleteRunning = true;
    try {
      await downloadProvider.refreshMetadataFromCache();
      final activeGlobalKey = VideoPlayerScreenState.activeGlobalKey;
      final settings = SettingsService.instanceOrNull;
      if (settings != null && settings.read(SettingsService.autoRemoveWatchedDownloads)) {
        final deleted = await downloadProvider.autoDeleteWatchedDownloads(activeGlobalKey: activeGlobalKey);
        if (deleted.isNotEmpty) {
          final msg = deleted.length == 1
              ? t.messages.autoRemovedWatchedDownload(title: deleted.first)
              : t.messages.autoRemovedWatchedDownloads(n: deleted.length);
          showMainSnackBar(msg);
        }
      }

      if (targetKeys != null) {
        for (final key in targetKeys) {
          if (!downloadProvider.hasSyncRule(key)) continue;
          final result = await downloadProvider.executeSyncRuleFor(key, _serverManager);
          if (result != null && result.queuedCount > 0) {
            final title = result.title ?? t.common.unknown;
            showMainSnackBar(t.downloads.syncedNewEpisodes(count: '1', title: '$title (${result.queuedCount})'));
          }
        }
      } else {
        final synced = await downloadProvider.executeSyncRules(_serverManager, force: force);
        if (synced.isNotEmpty) {
          showMainSnackBar(t.downloads.syncedNewEpisodes(count: synced.length.toString(), title: synced.first));
        }
      }
    } finally {
      _isAutoDeleteRunning = false;
      if (_pendingSyncKeys.isNotEmpty) {
        final queuedKeys = _pendingSyncKeys.toList();
        _pendingSyncKeys.clear();
        unawaited(_autoDeleteAndSync(downloadProvider, targetKeys: queuedKeys));
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // App came back to foreground - trigger sync check
        _offlineWatchSyncService.onAppResumed();
        unawaited(TrackerCoordinator.instance.flushWriteQueue());
        // Re-probe servers — mobile OS may have dropped TCP connections during doze/sleep.
        // On desktop, resumed fires on every window focus (alt-tab), so apply a cooldown
        // to avoid piling up network probes from rapid alt-tabbing.
        final now = DateTime.now();
        final cooldown = (Platform.isIOS || Platform.isAndroid)
            ? const Duration(seconds: 10)
            : const Duration(minutes: 2);
        if (now.difference(_lastResumeProbe) >= cooldown) {
          _lastResumeProbe = now;
          // Await health check before reconnecting so stale "online" servers
          // get marked offline and included in the reconnection sweep.
          unawaited(() async {
            await _serverManager.checkServerHealth();
            await _serverManager.reconnectOfflineServers();
          }());
        }
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // Database is session-scoped and must survive suspend/resume.
        // Closing here would kill the Drift isolate channel while services
        // (sync, downloads, cache) still hold references to the executor.
        // SQLite WAL mode handles process death; desktop uses onExitRequested.
        if (PlatformDetector.isDesktopOS()) {
          if (ProcessInfo.currentRss > 1024 * 1024 * 1024) {
            // 1GB
            _evictImageCaches();
          }
        } else if (Platform.isAndroid) {
          // A backgrounded app is LMK's first candidate; shed the image
          // caches at a lower bar than the foreground watchdog to survive
          // the HOME press on low-RAM boxes.
          final totalMem = DevicePerformance.totalMemBytes;
          final bar = totalMem != null ? (totalMem * 0.35).round() : 768 << 20;
          if (ProcessInfo.currentRss > bar) {
            _evictImageCaches();
          }
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // Transitional states - don't trigger session events
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Expose AppDatabase + ConnectionRegistry so screens (Settings, Setup)
        // can manage stored Jellyfin/Plex connections without re-creating
        // the registry per-call site.
        Provider<SettingsService>.value(value: widget.settings),
        Provider<StorageService>.value(value: widget.storage),
        Provider<AppDatabase>.value(value: _appDatabase),
        Provider<ConnectionRegistry>(create: (_) => ConnectionRegistry(_appDatabase)),
        Provider<ProfileRegistry>(create: (_) => ProfileRegistry(_appDatabase)),
        Provider<ProfileConnectionRegistry>(create: (_) => ProfileConnectionRegistry(_appDatabase)),
        Provider<PlexHomeService>(
          create: (context) {
            // Hydrate the disk cache eagerly for profile resolution. Live
            // refresh is started only after MainScreen has settled the
            // startup offline decision.
            final service = PlexHomeService(
              connections: context.read<ConnectionRegistry>(),
              profileConnections: context.read<ProfileConnectionRegistry>(),
              storage: context.read<StorageService>(),
            );
            unawaited(service.hydrate());
            return service;
          },
          dispose: (_, s) => s.dispose(),
        ),
        ChangeNotifierProvider<ActiveProfileProvider>(
          create: (context) {
            final provider = ActiveProfileProvider(
              registry: context.read<ProfileRegistry>(),
              plexHome: context.read<PlexHomeService>(),
              connections: context.read<ConnectionRegistry>(),
              profileConnections: context.read<ProfileConnectionRegistry>(),
              storage: context.read<StorageService>(),
            );
            unawaited(provider.initialize());
            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (context) {
            _serverManager.onJellyfinConnectionUpdated = context.read<ConnectionRegistry>().upsert;
            return MultiServerProvider(_serverManager, _aggregationService);
          },
        ),
        ChangeNotifierProxyProvider<MultiServerProvider, OfflineModeProvider>(
          create: (context) {
            final provider = OfflineModeProvider(
              _serverManager,
              multiServerProvider: context.read<MultiServerProvider>(),
            );
            provider.initialize(); // Initialize immediately so statusStream listener is ready
            return provider;
          },
          update: (_, multiServerProvider, previous) {
            final provider = previous!;
            provider.updateMultiServerProvider(multiServerProvider);
            provider.initialize(); // Idempotent - safe to call again
            return provider;
          },
        ),
        // Profile binder owns the cold-start client connect: Plex token
        // refresh + Jellyfin client creation. Hoisted out of MainScreen so
        // the splash can await its first settle — without this, MainScreen
        // mounts (and discover/libraries query) before any client exists.
        // It is intentionally not auto-started here: SetupScreen first checks
        // whether startup should go straight offline, otherwise the binder's
        // microtask can begin network work before the offline decision lands.
        Provider<ActiveProfileBinder>(
          lazy: false,
          create: (context) {
            final activeProfile = context.read<ActiveProfileProvider>();
            return ActiveProfileBinder(
              activeProfile: activeProfile,
              connections: context.read<ConnectionRegistry>(),
              profileConnections: context.read<ProfileConnectionRegistry>(),
              serverManager: _serverManager,
              multiServerProvider: context.read<MultiServerProvider>(),
              pinPrompt: _rootPinPrompt,
              shouldDeferInitialBind: (_) async {
                final settings = await SettingsService.getInstance();
                return activeProfile.requiresSelectionOnOpen(settings);
              },
            );
          },
          dispose: (_, binder) => binder.dispose(),
        ),
        // Download provider. Downloads are shared, but sync rules are scoped to
        // the active profile and reload when the profile changes.
        ChangeNotifierProxyProvider<ActiveProfileProvider, DownloadProvider>(
          create: (context) => DownloadProvider(downloadManager: _downloadManager, database: _appDatabase),
          update: (context, activeProfile, previous) {
            final provider = previous!;
            provider.setActiveProfileId(activeProfile.activeId);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<ActiveProfileProvider, OfflineWatchSyncService>(
          create: (context) {
            final offlineModeProvider = context.read<OfflineModeProvider>();
            final downloadProvider = context.read<DownloadProvider>();
            final activeProfile = context.read<ActiveProfileProvider>();
            _offlineWatchSyncService.setActiveProfileId(
              activeProfile.activeId,
              // Legacy-adoption gate: only trust the count once the provider
              // has hydrated (locals + cached home users) — a transient
              // count of 1 mid-load would permanently mis-adopt pre-profile
              // watch actions.
              availableProfileCount: activeProfile.isInitialized ? activeProfile.profiles.length : null,
            );

            // Offline-sync drain replays a batch of queued watch actions without
            // per-item data, so we can't target rules — force a full pass.
            _offlineWatchSyncService.onWatchStatesRefreshed = () async {
              await _autoDeleteAndSync(downloadProvider, force: true);
            };

            // In-session watch events carry the episode's parent chain, so we
            // only re-evaluate rules that actually cover the watched item —
            // leaves unrelated collection/playlist rules alone. Debounced so
            // binge-watching coalesces into one pass.
            _watchStateSubscription = WatchStateNotifier().stream.listen((event) {
              if (event.changeType != WatchStateChangeType.watched) return;
              if (VideoPlayerScreenState.activeGlobalKey == event.globalKey) return;

              _pendingSyncKeys.addAll(downloadProvider.syncRuleKeysForWatchEvent(event));

              _syncDebounce?.cancel();
              _syncDebounce = Timer(const Duration(seconds: 5), () {
                final keys = _pendingSyncKeys.toList();
                _pendingSyncKeys.clear();
                _autoDeleteAndSync(downloadProvider, targetKeys: keys);
              });
            });

            _startConnectivitySyncTrigger(downloadProvider, offlineModeProvider);

            // Thread the offline flag into services so queue/resume paths can
            // short-circuit instead of hitting the network and failing.
            downloadProvider.setOfflineSource(offlineModeProvider);

            _offlineWatchSyncService.startConnectivityMonitoring(offlineModeProvider);
            return _offlineWatchSyncService;
          },
          update: (_, activeProfile, previous) {
            final provider = previous!;
            provider.setActiveProfileId(
              activeProfile.activeId,
              availableProfileCount: activeProfile.isInitialized ? activeProfile.profiles.length : null,
            );
            return provider;
          },
        ),
        ChangeNotifierProxyProvider2<OfflineWatchSyncService, DownloadProvider, OfflineWatchProvider>(
          create: (context) => OfflineWatchProvider(
            syncService: context.read<OfflineWatchSyncService>(),
            downloadProvider: context.read<DownloadProvider>(),
          ),
          update: (_, syncService, downloadProvider, previous) => previous!,
        ),
        // Account preferences (server-stored: Jellyfin UserConfiguration,
        // plex.tv user profile) live above the profile session so a write
        // survives navigation, and so a profile switch clears the cache in one
        // place. The repository is exposed separately because UI reads it
        // directly; the controller owns and disposes it.
        ChangeNotifierProxyProvider2<ActiveProfileProvider, ConnectionRegistry, AccountPreferencesController>(
          create: (_) => AccountPreferencesController(),
          update: (context, activeProfile, connections, previous) {
            final controller = previous!;
            controller.attach(
              connections: connections,
              profileConnections: context.read<ProfileConnectionRegistry>(),
              activeProfile: activeProfile,
              serverManager: context.read<MultiServerProvider>().serverManager,
            );
            return controller;
          },
        ),
        ProxyProvider<AccountPreferencesController, AccountPreferencesRepository>(
          update: (_, controller, _) => controller.repository,
        ),
        ChangeNotifierProxyProvider2<ActiveProfileProvider, ConnectionRegistry, UserProfileProvider>(
          create: (context) => UserProfileProvider(storageService: context.read<StorageService>()),
          update: (context, activeProfile, connections, previous) {
            final provider = previous!;
            provider.attach(
              connections: connections,
              activeProfile: activeProfile,
              profileConnections: context.read<ProfileConnectionRegistry>(),
              serverManager: context.read<MultiServerProvider>().serverManager,
              accountPreferences: context.read<AccountPreferencesController>(),
            );
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        // Shader presets are app-global — deliberately outside the
        // profile-scoped session in ProfileSessionScreen.
        ChangeNotifierProvider(create: (context) => ShaderProvider()),
      ],
      child: _AppShell(databaseRecoveryOutcome: widget.databaseRecoveryOutcome),
    );
  }
}

/// App-global shell: theme consumer, translations, root input handling, and the
/// root MaterialApp. Profile-scoped providers/navigation live in
/// [ProfileSessionScreen], not here, so root auth/PIN/global dialogs survive a
/// profile switch.
class _AppShell extends StatelessWidget {
  const _AppShell({required this.databaseRecoveryOutcome});

  final TvosDatabaseRecoveryOutcome databaseRecoveryOutcome;

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return TranslationProvider(
          child: Builder(
            builder: (context) {
              return Listener(
                onPointerDown: (event) {
                  if ((event.buttons & kBackMouseButton) != 0) {
                    unawaited(() async {
                      final rootNavigator = rootNavigatorKey.currentState;
                      if (rootNavigator?.canPop() ?? false) {
                        await rootNavigator?.maybePop();
                        return;
                      }
                      await profileNavigationRegistry.maybePopProfileRoute();
                    }());
                  }
                },
                behavior: HitTestBehavior.translucent,
                child: InputModeTracker(
                  child: MaterialApp(
                    title: t.app.title,
                    debugShowCheckedModeBanner: false,
                    theme: themeProvider.lightTheme,
                    darkTheme: themeProvider.darkTheme,
                    themeMode: themeProvider.materialThemeMode,
                    navigatorKey: rootNavigatorKey,
                    navigatorObservers: [BackKeySuppressorObserver()],
                    home: SetupScreen(databaseRecoveryOutcome: databaseRecoveryOutcome),
                    // Siri Remote select + gamepad A report as
                    // LogicalKeyboardKey.{select,gameButtonA} which aren't
                    // in Flutter's default shortcut set — Material-level
                    // widgets (menu items, showModalBottomSheet actions)
                    // ignore them. Map both to ActivateIntent so tapping
                    // select on tvOS activates the focused widget.
                    shortcuts: <ShortcutActivator, Intent>{
                      ...WidgetsApp.defaultShortcuts,
                      const SingleActivator(LogicalKeyboardKey.select): const ActivateIntent(),
                      const SingleActivator(LogicalKeyboardKey.gameButtonA): const ActivateIntent(),
                      const SingleActivator(LogicalKeyboardKey.goBack): const DismissIntent(),
                      const SingleActivator(LogicalKeyboardKey.browserBack): const DismissIntent(),
                      const SingleActivator(LogicalKeyboardKey.gameButtonB): const DismissIntent(),
                    },
                    builder: (context, child) => rootShell(child),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// The root shell every route renders inside.
///
/// The form-factor scale sits above the messenger and its root [Scaffold], not inside them:
/// Flutter presents a messenger's snackbars on the rootmost registered scaffold, so anything
/// below would leave global snackbars at the car's native density while the rest of the
/// interface grew.
Widget rootShell(Widget? child) {
  return FormFactorScale(
    child: ScaffoldMessenger(
      key: rootScaffoldMessengerKey,
      child: Scaffold(backgroundColor: Colors.transparent, body: child),
    ),
  );
}

/// Apple TV receives a full-HD logical surface, while Android Automotive can
/// report a very low display density. Both make otherwise comfortable controls
/// physically too small, so render through a smaller, self-consistent logical
/// viewport and scale the result back to the physical surface.
class FormFactorScale extends StatelessWidget {
  final Widget? child;
  const FormFactorScale({super.key, required this.child});

  static const double _appleTvScale = 2.0;

  @override
  Widget build(BuildContext context) {
    final child = this.child;
    if (child == null) return const SizedBox.shrink();

    // Keep the existing Apple TV path independent of settings so its 2×
    // behavior and overscan handling remain unchanged.
    if (PlatformDetector.isAppleTV()) {
      return _scaledSurface(child: child, scale: _appleTvScale, zeroInsets: true);
    }
    if (!PlatformDetector.isAutomotive()) return child;

    return SettingValueBuilder<double>(
      pref: SettingsService.automotiveUiScale,
      builder: (context, scale, _) => _scaledSurface(child: child, scale: scale, zeroInsets: false),
    );
  }

  Widget _scaledSurface({required Widget child, required double scale, required bool zeroInsets}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final logicalSize = Size(constraints.maxWidth / scale, constraints.maxHeight / scale);
        final outerQ = MediaQuery.of(context);
        // tvOS reports conservative overscan insets (~60pt top/bottom,
        // ~90pt left/right). Modern TVs don't overscan, so treat them as
        // dead margin and zero them out — the UI can use the full surface.
        //
        // Automotive system bars are real touch-exclusion regions. Preserve
        // their physical size in the scaled coordinate system so SafeArea
        // continues to keep controls out from underneath them.
        return Transform.scale(
          scale: scale,
          alignment: .topLeft,
          transformHitTests: true,
          // Align loosens what it passes down. Without it a tight incoming constraint — which is
          // what the app's root hands its builder — forces the SizedBox back to the full surface,
          // and the transform then only magnifies a full-size layout instead of rendering a
          // smaller one into the same space.
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: logicalSize.width,
              height: logicalSize.height,
              child: MediaQuery(
                data: outerQ.copyWith(
                  size: logicalSize,
                  devicePixelRatio: outerQ.devicePixelRatio * scale,
                  padding: zeroInsets ? .zero : outerQ.padding * (1 / scale),
                  viewPadding: zeroInsets ? .zero : outerQ.viewPadding * (1 / scale),
                  viewInsets: zeroInsets ? .zero : outerQ.viewInsets * (1 / scale),
                  systemGestureInsets: zeroInsets ? .zero : outerQ.systemGestureInsets * (1 / scale),
                ),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

@visibleForTesting
bool shouldBypassSetupForDatabaseRecovery(TvosDatabaseRecoveryOutcome outcome) {
  return outcome == TvosDatabaseRecoveryOutcome.recoveryRequired;
}

class SetupScreen extends StatefulWidget {
  const SetupScreen({
    super.key,
    required this.databaseRecoveryOutcome,
    this.initializeAuthServices = true,
    this.debugRecoveryRequiredRouter,
  });

  final TvosDatabaseRecoveryOutcome databaseRecoveryOutcome;
  final bool initializeAuthServices;
  @visibleForTesting
  final FutureOr<void> Function(BuildContext context, String message)? debugRecoveryRequiredRouter;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> with MountedSetStateMixin {
  String _statusMessage = '';
  bool _enteringOffline = false;

  // Per-server connection status: serverId -> (name, connected?)
  final Map<String, (String name, bool? connected)> _serverStatus = {};

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The app's first screen: undo any orientation lock a previous run's
    // full-screen player left behind, and re-apply it whenever the form
    // factor signals (Theme.platform / MediaQuery size) change.
    OrientationHelper.restoreDefaultOrientations(context);
  }

  void _setStatus(String message) {
    setStateIfMounted(() => _statusMessage = message);
  }

  Future<void> _enterOfflineMode() async {
    if (_enteringOffline) return;
    _enteringOffline = true;
    _setStatus(t.common.startingOfflineMode);
    await context.read<DownloadProvider>().ensureInitialized();
    if (!mounted) return;
    AndroidExitDiagnostics.markStartupPhase(AndroidStartupPhase.mainScreen);
    unawaited(Navigator.pushReplacement(context, fadeRoute(const ProfileSessionScreen(isOfflineMode: true))));
  }

  Future<void> _loadSavedCredentials() async {
    if (shouldBypassSetupForDatabaseRecovery(widget.databaseRecoveryOutcome)) {
      final message = t.auth.localDataRecoveryRequired;
      final debugRouter = widget.debugRecoveryRequiredRouter;
      if (debugRouter != null) {
        await Future.sync(() => debugRouter(context, message));
        return;
      }
      await Future<void>.delayed(Duration.zero);
      if (mounted) {
        unawaited(
          Navigator.pushReplacement(
            context,
            fadeRoute(
              AuthScreen(
                initialErrorMessage: message,
                initializeServices: widget.initializeAuthServices,
                databaseRecoveryRequired: true,
              ),
            ),
          ),
        );
      }
      return;
    }

    _setStatus(t.common.checkingNetwork);

    final storage = await StorageService.getInstance();
    final registry = ServerRegistry(storage);

    // Idempotent: brings legacy SharedPreferences state (plexToken,
    // currentUserUUID, homeUsersCache) into the new ConnectionRegistry +
    // ProfileRegistry tables. No-op on subsequent launches.
    if (mounted) {
      try {
        final connRegistry = context.read<ConnectionRegistry>();
        final profileConnections = context.read<ProfileConnectionRegistry>();
        final profileRegistry = context.read<ProfileRegistry>();
        final activeProfiles = context.read<ActiveProfileProvider>();
        final serverManager = context.read<MultiServerProvider>().serverManager;
        final bootstrap = ConnectionBootstrap(
          storage: storage,
          connectionRegistry: connRegistry,
          serverRegistry: registry,
          profileRegistry: profileRegistry,
        );
        await bootstrap.run();
        final pruned = await ProfileConnectionCleanup(
          profileConnections: profileConnections,
          connections: connRegistry,
          storage: storage,
          serverManager: serverManager,
        ).pruneUnreferencedJellyfinConnections();
        if (pruned > 0) {
          appLogger.i('Setup: pruned $pruned unreferenced MediaBrowser connection${pruned == 1 ? '' : 's'}');
        }
        // Provider initialization starts before this screen runs the legacy
        // migration. Reload after bootstrap so copied Plex Home users and the
        // selected active profile are visible before setup decides binding is
        // already settled and navigates to MainScreen.
        await activeProfiles.reloadFromStorage();
      } catch (e, st) {
        appLogger.w('Boot-time migration failed', error: e, stackTrace: st);
      }
    }

    // Check network connectivity early to fast-path airplane mode.
    // Timeout guards against connectivity_plus hanging on some Android TV devices after force-close.
    bool hasNetwork;
    unawaited(Sentry.addBreadcrumb(Breadcrumb(message: 'Checking network connectivity', category: 'setup')));
    try {
      final connectivityResult = await Connectivity().checkConnectivity().timeout(
        const Duration(seconds: 3),
        onTimeout: () => [ConnectivityResult.other],
      );
      hasNetwork = !connectivityResult.contains(ConnectivityResult.none);
    } catch (e) {
      // connectivity_plus throws DBusServiceUnknownException on Linux without NetworkManager
      hasNetwork = true;
    }

    unawaited(
      Sentry.addBreadcrumb(Breadcrumb(message: 'Network check done: hasNetwork=$hasNetwork', category: 'setup')),
    );

    _setStatus(t.common.loadingServers);

    if (!mounted) return;

    // Snapshot ConnectionRegistry before we cross any awaits — Provider lookups
    // through `context` after async gaps trip the use_build_context_synchronously
    // lint, and reading early is safe because the registry is a singleton.
    final connectionRegistry = context.read<ConnectionRegistry>();
    final List<Connection> allConnections;
    try {
      allConnections = await connectionRegistry.list();
      AndroidExitDiagnostics.markStartupPhase(AndroidStartupPhase.credentialsLoaded);
    } catch (e, st) {
      // Defence-in-depth: a DB-open failure here used to propagate
      // uncaught and strand the splash forever (#1022). Route to auth so
      // the user is never trapped, and surface to Sentry so an unknown
      // regression doesn't go silent.
      appLogger.e('Setup: failed to load connections; returning to auth', error: e, stackTrace: st);
      unawaited(Sentry.captureException(e, stackTrace: st));
      if (mounted) {
        unawaited(Navigator.pushReplacement(context, fadeRoute(const AuthScreen())));
      }
      return;
    }

    if (allConnections.isEmpty) {
      if (mounted) {
        unawaited(Navigator.pushReplacement(context, fadeRoute(const AuthScreen())));
      }
      return;
    }

    if (!mounted) return;

    // No network — skip connection attempts and go straight to offline mode
    if (!hasNetwork) {
      await _enterOfflineMode();
      return;
    }

    if (mounted) {
      setState(() {
        for (final conn in allConnections) {
          if (conn is PlexAccountConnection) {
            for (final s in conn.servers) {
              _serverStatus[s.clientIdentifier] = (s.name, null);
            }
          } else if (conn is JellyfinConnection) {
            _serverStatus[conn.serverMachineId] = (conn.serverName, null);
          }
        }
      });
    }

    final plexCount = allConnections.whereType<PlexAccountConnection>().fold<int>(0, (n, c) => n + c.servers.length);
    final mediaBrowserCount = allConnections.whereType<JellyfinConnection>().length;
    unawaited(
      Sentry.addBreadcrumb(
        Breadcrumb(
          message: 'Handing off to MainScreen with $plexCount Plex + $mediaBrowserCount MediaBrowser server(s)',
          category: 'setup',
        ),
      ),
    );
    _setStatus(t.common.connectingToServers);

    // Snapshot Provider refs before further awaits.
    final activeProfile = context.read<ActiveProfileProvider>();
    // The Provider is `lazy: false` so the binder is constructed already, but
    // SetupScreen starts it only after the offline fast path has been ruled out.
    final binder = context.read<ActiveProfileBinder>();
    final downloadProvider = context.read<DownloadProvider>();

    // Wait for the active profile to load from disk so the binder has a
    // profile to bind. `initialize` is fire-and-forget at provider creation,
    // so awaiting here pulls control through the same future and triggers
    // the listener-driven rebind synchronously.
    await activeProfile.reloadFromStorage();
    if (!mounted) return;

    if (activeProfile.active == null && activeProfile.profiles.isEmpty) {
      appLogger.w('Setup: stored connections exist but no profiles resolved after bootstrap; returning to auth');
      unawaited(Navigator.pushReplacement(context, fadeRoute(const AuthScreen())));
      return;
    }

    // Wire the per-server status listener before either branch so the splash
    // checkmarks fill in even while the user is choosing a profile.
    _bindServerStatusListener();

    // Start only after network/offline startup has been decided and the
    // active profile snapshot is hydrated. This prevents an eager binder
    // microtask from racing the no-network/manual-offline fast path.
    AndroidExitDiagnostics.markStartupPhase(AndroidStartupPhase.bindingStarted);
    binder.start();

    // If "prompt for profile on launch" is on (or no profile is selected
    // yet), surface the picker BEFORE waiting for the previously-active
    // profile's bind to settle — otherwise the user sees the splash fully
    // connect before the prompt arrives. The picker's own `_switchTo` calls
    // `awaitBindingSettle` after activation, so by the time it pops, the
    // chosen profile's bind is settled.
    final settings = await SettingsService.getInstance();
    if (!mounted) return;
    final hasNoActive = activeProfile.active == null && activeProfile.profiles.isNotEmpty;
    final shouldPrompt = hasNoActive || activeProfile.requiresSelectionOnOpen(settings);

    var bindingSucceeded = activeProfile.lastBindingSucceeded;
    if (shouldPrompt) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const ProfileSwitchScreen(requireSelection: true)));
      if (!mounted) return;
      bindingSucceeded = activeProfile.active != null && activeProfile.lastBindingSucceeded;
    } else {
      // Now wait for the binder to settle. This is the media-server client
      // race: per-server status flips on the splash list as each client comes
      // online, and we don't push MainScreen until they're all done (success
      // or fail). Eliminates the "Failed to load discover content: No servers
      // available" race the old eager-navigate flow caused.
      bindingSucceeded = await activeProfile.awaitBindingSettle();
      if (!mounted) return;
    }
    AndroidExitDiagnostics.markStartupPhase(AndroidStartupPhase.bindingSettled);

    if (shouldEnterOfflineModeAfterStartupBind(
      bindingSucceeded: bindingSucceeded,
      hasOnlineServers: _serverManagerFromContext().onlineServerIds.isNotEmpty,
    )) {
      appLogger.w('Setup: no servers online after startup bind; starting offline mode');
      await _enterOfflineMode();
      return;
    }

    // Repopulate metadata for downloaded items now that per-backend caches
    // are resolvable (the Connections row + live MediaBrowser client are in
    // place). Without this the downloads list and sync-rule titles render
    // empty until something forces a later refresh.
    await downloadProvider.refreshMetadataFromCache();
    if (!mounted) return;

    AndroidExitDiagnostics.markStartupPhase(AndroidStartupPhase.mainScreen);
    unawaited(Navigator.pushReplacement(context, fadeRoute(ProfileSessionScreen(initialPromptHandled: shouldPrompt))));
  }

  /// Wire per-server status updates from [MultiServerManager] into the
  /// splash list so the user sees check/cross marks land as the binder
  /// brings each client online. [MultiServerManager.connectProgressStream]
  /// fires as each individual server settles; [MultiServerManager.statusStream]
  /// emits once per connect pass and back-fills anything the progress stream
  /// missed (e.g. servers torn down by the binder's visibility sweep).
  /// Best-effort: stops listening when the state goes away.
  StreamSubscription<Map<String, bool>>? _statusSub;
  StreamSubscription<({String serverId, bool online})>? _connectProgressSub;

  void _bindServerStatusListener() {
    _statusSub?.cancel();
    _connectProgressSub?.cancel();
    final manager = _serverManagerFromContext();
    _connectProgressSub = manager.connectProgressStream.listen((progress) {
      if (!mounted) return;
      final existing = _serverStatus[progress.serverId];
      if (existing == null) return;
      setState(() {
        _serverStatus[progress.serverId] = (existing.$1, progress.online);
      });
    });
    _statusSub = manager.statusStream.listen((status) {
      if (!mounted) return;
      setState(() {
        for (final entry in status.entries) {
          final existing = _serverStatus[entry.key];
          if (existing != null) {
            _serverStatus[entry.key] = (existing.$1, entry.value);
          }
        }
      });
    });
  }

  MultiServerManager _serverManagerFromContext() => context.read<MultiServerProvider>().serverManager;

  @override
  void dispose() {
    _statusSub?.cancel();
    _connectProgressSub?.cancel();
    super.dispose();
  }

  Widget _buildStatusText(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Text(
        _statusMessage,
        key: ValueKey(_statusMessage),
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
      ),
    );
  }

  Widget _buildServerStatusList(BuildContext context) {
    if (_serverStatus.isEmpty) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;
    final dimColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);
    const successColor = Color(0xFF4CAF50);
    const failColor = Color(0xFFEF5350);

    return Column(
      mainAxisSize: .min,
      children: _serverStatus.entries.map((entry) {
        final (name, connected) = entry.value;
        final Widget statusIcon;
        if (connected == null) {
          statusIcon = AppIcon(Symbols.circle_rounded, size: 10, color: dimColor);
        } else if (connected) {
          statusIcon = const AppIcon(Symbols.check_circle_rounded, size: 14, color: successColor);
        } else {
          statusIcon = const AppIcon(Symbols.cancel_rounded, size: 14, color: failColor);
        }
        return Padding(
          key: ValueKey(entry.key),
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisSize: .min,
            children: [
              statusIcon,
              const SizedBox(width: 8),
              Text(name, style: textTheme.bodySmall?.copyWith(color: dimColor)),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    const coralColor = Color(0xFFE5A00D);
    final height = MediaQuery.sizeOf(context).height;
    // The stacked layout below hangs its two rows off fixed ±170/180 offsets from the middle, which
    // needs roughly 700 logical pixels of height. A car at a large interface scale — and a phone in
    // landscape — has less than that, and the rows would collide or fall outside the Stack's clip.
    if (height < 700) {
      return ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset('assets/plezy_adaptive_foreground.svg', width: 160, height: 160),
                  _buildStatusText(context),
                  const SizedBox(height: 16),
                  Center(
                    child: _serverStatus.isEmpty
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: coralColor),
                          )
                        : _buildServerStatusList(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Stack(
        children: [
          Center(child: SvgPicture.asset('assets/plezy_adaptive_foreground.svg', width: 288, height: 288)),
          Positioned(left: 0, right: 0, bottom: height * 0.5 - 170, child: _buildStatusText(context)),
          Positioned(
            left: 0,
            right: 0,
            top: height * 0.5 + 180,
            child: Center(
              child: _serverStatus.isEmpty
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: coralColor),
                    )
                  : _buildServerStatusList(context),
            ),
          ),
        ],
      ),
    );
  }
}
