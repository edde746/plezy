package com.edde746.plezy.ui.updates

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import com.edde746.plezy.app.AppGraph
import com.edde746.plezy.app.RootScreen
import com.edde746.plezy.app.RootSession
import com.edde746.plezy.log.Log
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.app.LocalPlezyPlatform
import com.edde746.plezy.ui.components.ButtonStyle
import com.edde746.plezy.ui.components.ModalOverlay
import com.edde746.plezy.ui.components.OverlayActions
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.PlezyColors
import com.edde746.plezy.updates.AppUpdates
import com.edde746.plezy.updates.Installation
import com.edde746.plezy.updates.ReleaseUpdate
import com.edde746.plezy.updates.Updater
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch

/** An installed Windows copy's own updater ([Updater.NATIVE]): the update feed's newer build and its installer. */
interface InstallerUpdater {
    /** The feed's build newer than the running one, or null. Throws when the feed can't be read. */
    suspend fun check(): InstallerUpdate?

    /**
     * Downloads [update]'s installer, reporting the share downloaded (0–1) to [progress], verifies its size and
     * signature, starts it and ends the app, which the installer replaces. Throws when any step fails: the app runs on.
     */
    suspend fun install(update: InstallerUpdate, progress: (Float) -> Unit)
}

/** An update [InstallerUpdater.check] found: its [version] ("2.26.0") and the page of its release notes. */
interface InstallerUpdate {
    val version: String
    val notesUrl: String?
}

/**
 * How the product app on this platform updates itself ([com.edde746.plezy.ui.app.PlezyPlatform.updates]): where it is
 * installed ([installation], which decides the [Updater]), and in an installed Windows copy its [installer] updater.
 * One per process, attached to the product's root as it first shows ([checkAtLaunch]); it holds the update the dialog
 * offers ([UpdateDialog]).
 *
 * For Settings' Updates group, once attached: [updates] (`available`, `updater`, the GitHub `checkNow`), [show] for a
 * release `checkNow` found, and [checkInstallerNow] for the installer updater's check.
 */
class PlatformUpdates(val installation: Installation, val installer: InstallerUpdater? = null) {
    /** The update the dialog offers, or null. Compose state. */
    internal var offer: UpdateOffer? by mutableStateOf(null)
        private set

    /** This install's updates, on the product's graph. */
    lateinit var updates: AppUpdates
        private set

    /** The graph's scope: a skip or an install outlives the dialog. */
    private lateinit var scope: CoroutineScope
    private var currentVersion = ""
    private var installing: Job? = null

    /**
     * Attaches to [root]'s graph and runs the launch's check ([AppUpdates.checkAtLaunch]) once the app shows
     * (`RootScreen.Main`), once per process: the installer updater's check ([Updater.NATIVE]), whose failure is logged
     * and offers nothing and which leaves out the version the user skipped, or the GitHub release check.
     */
    internal fun checkAtLaunch(root: RootSession) {
        if (::updates.isInitialized) return
        attach(root.graph)
        scope.launch {
            root.screen.first { it is RootScreen.Main }
            updates.checkAtLaunch(native = { scope.launch { offerInstallerUpdate() } }, offer = ::show)
        }
    }

    /** Attaches to [graph]: the updates of this install on it, and its scope. */
    internal fun attach(graph: AppGraph) {
        updates = AppUpdates(graph, installation)
        scope = graph.scope
        currentVersion = graph.appVersion
    }

    /** The installer updater's launch check: its update unless the user skipped that version; a failure is logged. */
    internal suspend fun offerInstallerUpdate() {
        val found = try {
            installerUpdater().check()
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.e(TAG, e) { "the update feed couldn't be read" }
            null
        }
        if (found != null && found.version != updates.skippedVersion()) {
            offer = UpdateOffer.Installer(found, currentVersion, InstallStep.Offered)
        }
    }

    /** Opens the dialog for [update], a newer GitHub release. */
    fun show(update: ReleaseUpdate) {
        offer = UpdateOffer.Release(update)
    }

    /**
     * The installer updater's check the user asked for: opens the dialog and returns true when the feed has a newer
     * build (one they skipped too), else false. Throws when the feed can't be read.
     */
    suspend fun checkInstallerNow(): Boolean {
        val found = installerUpdater().check() ?: return false
        offer = UpdateOffer.Installer(found, currentVersion, InstallStep.Offered)
        return true
    }

    internal fun skip(offer: UpdateOffer) {
        this.offer = null
        updates.skip(offer.version)
    }

    /** Downloads and starts [offer]'s installer; the dialog shows the download, then the failure if there is one. */
    internal fun install(offer: UpdateOffer.Installer) {
        val installer = installerUpdater()
        this.offer = offer.copy(step = InstallStep.Downloading(0f))
        installing = scope.launch {
            try {
                installer.install(offer.update) { share ->
                    // Posted to the main thread as a child of the install: once Cancel stops it, a late report is dropped.
                    launch { this@PlatformUpdates.offer = offer.copy(step = InstallStep.Downloading(share)) }
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.e(TAG, e) { "the update to ${offer.update.version} couldn't be installed" }
                this@PlatformUpdates.offer = offer.copy(step = InstallStep.Failed)
            }
        }
    }

    /** Closes the dialog, stopping a download under way. */
    internal fun dismiss() {
        installing?.cancel()
        installing = null
        offer = null
    }

    private fun installerUpdater(): InstallerUpdater = checkNotNull(installer) { "an installed copy without its installer updater" }

    private companion object {
        const val TAG = "updates"
    }
}

/** What the update dialog offers. */
internal sealed interface UpdateOffer {
    /** The version it offers, which Skip This Version skips. */
    val version: String

    data class Release(val update: ReleaseUpdate) : UpdateOffer {
        override val version: String get() = update.latestVersion
    }

    data class Installer(val update: InstallerUpdate, val currentVersion: String, val step: InstallStep) : UpdateOffer {
        override val version: String get() = update.version
    }
}

/** Where installing an [UpdateOffer.Installer] is. */
internal sealed interface InstallStep {
    data object Offered : InstallStep

    /** Downloading: [share] of it done (0–1). */
    data class Downloading(val share: Float) : InstallStep

    data object Failed : InstallStep
}

/**
 * The dialog of [updates]' offer, if any.
 *
 * - A GitHub release: "Update Available", the new and the running version and the release's notes; Later, Skip This
 *   Version, and View Release, which opens the release's page.
 * - An installer update: the same with View Release opening its notes, and Install Update, which downloads the
 *   installer (a bar shows how much; Cancel stops it), starts it and ends the app; a failure says so.
 *
 * Focus starts on the main action (View Release, Install Update). Harness names: `update.<later|skip|view|install|
 * cancel|close>`.
 */
@Composable
internal fun UpdateDialog(updates: PlatformUpdates) {
    when (val offer = updates.offer) {
        null -> Unit
        is UpdateOffer.Release -> ReleaseDialog(offer, updates)
        is UpdateOffer.Installer -> InstallerDialog(offer, updates)
    }
}

@Composable
private fun ReleaseDialog(offer: UpdateOffer.Release, updates: PlatformUpdates) {
    val platform = LocalPlezyPlatform.current
    val update = offer.update
    val primary = remember { FocusRequester() }
    ModalOverlay(title = T.update.available, onDismiss = updates::dismiss, initialFocus = primary) {
        Versions(update.latestVersion, update.currentVersion)
        if (update.releaseNotes.isNotBlank()) {
            Column(Modifier.weight(1f, fill = false).fillMaxWidth().verticalScroll(rememberScrollState())) {
                Text(update.releaseNotes, style = MaterialTheme.typography.bodyMedium, color = PlezyColors.TextMuted)
            }
        }
        OverlayActions(primary = primary) {
            PlezyButton(T.common.later, updates::dismiss, Modifier.layoutProbe("update.later"), style = ButtonStyle.TEXT)
            PlezyButton(T.update.skipVersion, { updates.skip(offer) }, Modifier.layoutProbe("update.skip"), style = ButtonStyle.TEXT)
            PlezyButton(
                T.update.viewRelease,
                {
                    platform.openUrl(update.releaseUrl)
                    updates.dismiss()
                },
                Modifier.focusRequester(primary).layoutProbe("update.view"),
                style = ButtonStyle.PRIMARY,
            )
        }
    }
}

@Composable
private fun InstallerDialog(offer: UpdateOffer.Installer, updates: PlatformUpdates) {
    val platform = LocalPlezyPlatform.current
    val primary = remember { FocusRequester() }
    ModalOverlay(title = T.update.available, onDismiss = updates::dismiss, initialFocus = primary) {
        Versions(offer.update.version, offer.currentVersion)
        when (val step = offer.step) {
            InstallStep.Offered -> OverlayActions(primary = primary) {
                offer.update.notesUrl?.let { notes ->
                    PlezyButton(T.update.viewRelease, { platform.openUrl(notes) }, Modifier.layoutProbe("update.view"), style = ButtonStyle.TEXT)
                }
                PlezyButton(T.common.later, updates::dismiss, Modifier.layoutProbe("update.later"), style = ButtonStyle.TEXT)
                PlezyButton(T.update.skipVersion, { updates.skip(offer) }, Modifier.layoutProbe("update.skip"), style = ButtonStyle.TEXT)
                PlezyButton(T.update.install, { updates.install(offer) }, Modifier.focusRequester(primary).layoutProbe("update.install"), style = ButtonStyle.PRIMARY)
            }
            is InstallStep.Downloading -> {
                Text(T.update.downloading, style = MaterialTheme.typography.bodyMedium)
                LinearProgressIndicator(progress = { step.share }, modifier = Modifier.fillMaxWidth())
                OverlayActions {
                    PlezyButton(T.common.cancel, updates::dismiss, Modifier.layoutProbe("update.cancel"), style = ButtonStyle.TEXT)
                }
            }
            InstallStep.Failed -> {
                Text(T.update.installFailed, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.error)
                OverlayActions {
                    PlezyButton(T.common.close, updates::dismiss, Modifier.layoutProbe("update.close"), style = ButtonStyle.TEXT)
                }
            }
        }
    }
}

/** "Version 2.26.0 is available" over "Current: 2.25.0". */
@Composable
private fun Versions(latest: String, current: String) {
    Column {
        Text(T.update.versionAvailable(version = latest), style = MaterialTheme.typography.titleMedium)
        Text(T.update.currentVersion(version = current), style = MaterialTheme.typography.bodySmall, color = PlezyColors.TextMuted)
    }
}
