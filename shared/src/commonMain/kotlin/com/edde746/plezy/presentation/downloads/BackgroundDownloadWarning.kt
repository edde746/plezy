package com.edde746.plezy.presentation.downloads

import com.edde746.plezy.data.settings.DeviceSettingsRepository
import com.edde746.plezy.downloads.BackgroundWorkDiagnosticsService
import com.edde746.plezy.downloads.BackgroundWorkReason
import com.edde746.plezy.downloads.BackgroundWorkStatus
import com.edde746.plezy.app.NotificationPermission
import com.edde746.plezy.log.Log
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/** The Downloads screen's background-restriction banner. */
data class BackgroundWarningBanner(val blocked: Boolean, val text: String, val actionLabel: String = T.downloads.backgroundWarning.bannerAction)

/**
 * The background-restriction dialog. [preFlight]: it interrupts a download the user just asked for, offering
 * [dismissLabel] ("Download anyway"); otherwise it informs ("Close"). [fixLabel] is the primary action, which opens the
 * settings screen that fixes the first reason.
 */
data class BackgroundWarningDialog(
    val preFlight: Boolean,
    val title: String,
    val intro: String,
    val reasons: List<String>,
    val dismissLabel: String,
    val fixLabel: String,
) {
    val helpTitle: String get() = T.downloads.backgroundWarning.stillNotWorking
    val helpDescription: String get() = T.downloads.backgroundWarning.stillNotWorkingDescription
    val helpLinkLabel: String get() = BackgroundDownloadWarning.HELP_LINK_LABEL
}

/** [dialog] while one shows; [message] an error to show once (then [BackgroundDownloadWarning.messageShown]). */
data class BackgroundWarningUiState(val dialog: BackgroundWarningDialog? = null, val message: String? = null)

/**
 * The warnings about background restrictions that stop downloads (Android phones and tablets; elsewhere
 * [BackgroundWorkDiagnosticsService.isSupported] is false and both stay silent):
 * - [confirmBeforeDownload], the pre-flight before a user-initiated download: it asks for the notification permission,
 *   then interrupts at most once per install (`background_download_warning_ack`), and only when the verdict is blocked;
 * - [banner], shown on the Downloads screen while something is queued or downloading and the verdict isn't healthy,
 *   whose action ([showDetails]) opens the informational dialog.
 *
 * Call everything on the main thread.
 */
class BackgroundDownloadWarning(
    private val service: BackgroundWorkDiagnosticsService,
    private val settings: DeviceSettingsRepository,
    private val notificationPermission: NotificationPermission,
    /** Opens [url] outside the app; false when nothing could. */
    private val openUrl: suspend (url: String) -> Boolean,
    private val scope: CoroutineScope,
) {
    private val mutableState = MutableStateFlow(BackgroundWarningUiState())
    val state: StateFlow<BackgroundWarningUiState> = mutableState.asStateFlow()

    private var answer: CompletableDeferred<Boolean>? = null
    private var shownStatus: BackgroundWorkStatus? = null

    /** Whether this platform probes background work at all (Android phones and tablets). */
    val supported: Boolean get() = service.isSupported

    /** The latest probe's verdict. */
    val status: StateFlow<BackgroundWorkStatus> get() = service.status

    /** Probes the OS again and returns the verdict. */
    suspend fun recheck(): BackgroundWorkStatus = service.refresh()

    /** The banner for [status], or null: nothing pending, an unsupported platform, or a healthy verdict. */
    fun banner(status: BackgroundWorkStatus, hasPendingDownloads: Boolean): BackgroundWarningBanner? {
        if (!hasPendingDownloads || !service.isSupported || status.isHealthy) return null
        val texts = T.downloads.backgroundWarning
        return BackgroundWarningBanner(status.isBlocked, if (status.isBlocked) texts.bannerBlocked else texts.bannerDegraded)
    }

    /** Whether to go on with a download the user asked for. */
    suspend fun confirmBeforeDownload(): Boolean {
        if (!service.isSupported) return true
        notificationPermission.ensure()
        if (settings.value(AppSettings.backgroundDownloadWarningAck)) return true
        service.refresh()
        if (!service.status.value.isBlocked) return true
        // Whatever they pick, they've been told; the banner takes over from here.
        settings.set(AppSettings.backgroundDownloadWarningAck, true)
        return show(preFlight = true)
    }

    /** The banner's action: the informational dialog. */
    fun showDetails() {
        scope.launch { show(preFlight = false) }
    }

    private suspend fun show(preFlight: Boolean): Boolean {
        val status = service.status.value
        if (status.isHealthy) return true
        dismiss()
        val texts = T.downloads.backgroundWarning
        val dialog = BackgroundWarningDialog(
            preFlight = preFlight,
            title = when {
                preFlight -> texts.dialogTitle
                status.isBlocked -> texts.sheetTitle
                else -> texts.sheetTitleDegraded
            },
            intro = if (status.isBlocked) texts.sheetIntro else texts.sheetIntroDegraded,
            reasons = status.reasons.map(::describeReason),
            dismissLabel = if (preFlight) texts.dialogDownloadAnyway else T.common.close,
            fixLabel = if (preFlight) texts.dialogFixFirst else texts.openSettings,
        )
        val pending = CompletableDeferred<Boolean>()
        answer = pending
        shownStatus = status
        mutableState.value = mutableState.value.copy(dialog = dialog)
        return pending.await()
    }

    /** "Download anyway" or "Close": the pre-flight goes on. */
    fun proceed() = close(true)

    /** The dialog dismissed without a choice: a pre-flight doesn't go on. */
    fun dismiss() = close(!(mutableState.value.dialog?.preFlight ?: true))

    /**
     * The primary action: opens the settings screen for the first reason (after dropping an empirical stall, which the
     * user is now fixing), saying so when the device has none. A pre-flight doesn't go on.
     */
    fun fix() {
        val dialog = mutableState.value.dialog ?: return
        val status = shownStatus ?: return
        scope.launch {
            if (BackgroundWorkReason.OEM_UNKNOWN in status.reasons) service.clearStallEvidence()
            if (!service.openSettings(status.remedyTarget)) {
                mutableState.value = mutableState.value.copy(message = T.downloads.backgroundWarning.settingsUnavailable)
            }
            close(!dialog.preFlight)
        }
    }

    /** Opens the community guide to OEM background settings; the dialog stays. */
    fun openHelp() {
        scope.launch {
            val opened = try {
                openUrl(HELP_URL)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Opening the background help link failed" }
                false
            }
            if (!opened) mutableState.value = mutableState.value.copy(message = T.downloads.backgroundWarning.linkUnavailable)
        }
    }

    fun messageShown() {
        mutableState.value = mutableState.value.copy(message = null)
    }

    private fun close(result: Boolean) {
        val pending = answer ?: return
        answer = null
        shownStatus = null
        mutableState.value = mutableState.value.copy(dialog = null)
        pending.complete(result)
    }

    private fun describeReason(reason: BackgroundWorkReason): String {
        val texts = T.downloads.backgroundWarning
        return when (reason) {
            BackgroundWorkReason.BACKGROUND_RESTRICTED -> texts.reasonBackgroundRestricted
            BackgroundWorkReason.STANDBY_RESTRICTED -> texts.reasonStandbyRestricted
            BackgroundWorkReason.DOWNLOAD_CHANNEL_BLOCKED -> texts.reasonDownloadChannelBlocked
            BackgroundWorkReason.NOTIFICATIONS_DISABLED -> texts.reasonNotificationsDisabled
            BackgroundWorkReason.DATA_SAVER -> texts.reasonDataSaver
            BackgroundWorkReason.OEM_UNKNOWN -> texts.reasonOemUnknown
        }
    }

    companion object {
        /** Community-kept per-vendor steps; its root asks for the manufacturer, which beats guessing one. */
        const val HELP_URL = "https://dontkillmyapp.com"
        internal const val HELP_LINK_LABEL = "dontkillmyapp.com"
        private const val TAG = "BackgroundWarning"
    }
}
