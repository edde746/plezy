package com.edde746.plezy.ui.settings

import com.edde746.plezy.presentation.home.UserMenuAction
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Shape
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.presentation.downloads.BackgroundDownloadWarning
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.settings.ExternalTarget
import com.edde746.plezy.presentation.settings.SettingIcon
import com.edde746.plezy.presentation.settings.SettingsEvent
import com.edde746.plezy.presentation.settings.SettingSlot
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.components.Chevron
import com.edde746.plezy.ui.components.GroupRow
import com.edde746.plezy.ui.supporter.AppIconPickerSheet
import com.edde746.plezy.ui.supporter.AppIconRow
import com.edde746.plezy.ui.supporter.DonationTile
import com.edde746.plezy.ui.supporter.SupporterSheet
import com.edde746.plezy.ui.supporter.SupporterTile
import kotlinx.coroutines.launch

// Where other features draw into Settings: the rows of the hub and of Appearance their slices own
// ([com.edde746.plezy.presentation.settings.SettingSlotRow]) and the screens of other features the hub opens.

/**
 * Whether [slot]'s row shows here: a row whose provider draws nothing is left out of its group, so the group's corners
 * stay right. The Supporter tile shows in purchasable builds, the donation tile in donation builds (never both); App
 * icon where the perks are offered and the device switches its icon; Download location wherever the session has
 * downloads; Background downloads where the downloads probe the system's background restrictions.
 */
@Composable
internal fun slotShown(slot: SettingSlot, app: AppSession): Boolean = when (slot) {
    SettingSlot.SUPPORTER -> app.supporterSheet.canOpen || app.donationUrl != null
    SettingSlot.APP_ICON -> app.appIconPicker.state.collectAsState().value.shown
    SettingSlot.DOWNLOAD_LOCATION -> app.downloadLocation != null
    SettingSlot.BACKGROUND_DOWNLOADS -> app.downloads?.warning?.supported == true
}

/** [slot]'s row in [shape] (its place in the group), drawn by the slice that owns it; nothing where [slotShown] is false. */
@Composable
internal fun SettingSlotContent(slot: SettingSlot, app: AppSession, shape: Shape, toasts: SettingsToasts, modifier: Modifier = Modifier) {
    when (slot) {
        SettingSlot.SUPPORTER ->
            if (app.supporterSheet.canOpen) SupporterTile(app, shape, { openSupporter {} }, modifier) else DonationTile(app, shape, modifier)
        SettingSlot.APP_ICON -> {
            var open by remember { mutableStateOf(false) }
            AppIconRow(app, shape, { open = true }, modifier)
            if (open) AppIconPickerSheet(app) { open = false }
        }
        SettingSlot.DOWNLOAD_LOCATION -> app.downloadLocation?.let { model ->
            val state by model.state.collectAsState()
            SettingsLinkRow(state.rowTitle, state.rowSubtitle, state.rowTrailingValue, model::openDialog, shape, modifier, icon = SettingIcon.FOLDER.vector)
        }
        SettingSlot.BACKGROUND_DOWNLOADS -> app.downloads?.warning?.let { BackgroundDownloadsRow(it, shape, toasts, modifier) }
    }
}

/**
 * Whether the system lets downloads run in the background, by the last probe's verdict: not checked yet, blocked (in
 * the error colour), limited, or allowed. A click probes again: allowed says so, anything else opens the background
 * restrictions dialog.
 */
@Composable
private fun BackgroundDownloadsRow(warning: BackgroundDownloadWarning, shape: Shape, toasts: SettingsToasts, modifier: Modifier) {
    val status by warning.status.collectAsState()
    val texts = T.downloads.backgroundWarning
    val scope = rememberCoroutineScope()
    val (icon, tint, summary) = when {
        !status.probed -> Triple(SettingSymbols.Help, null, texts.statusUnknown)
        status.isBlocked -> Triple(SettingSymbols.BatteryAlert, MaterialTheme.colorScheme.error, texts.statusBlocked)
        !status.isHealthy -> Triple(SettingSymbols.Info, MaterialTheme.colorScheme.tertiary, texts.statusDegraded)
        else -> Triple(SettingSymbols.CheckCircle, null, texts.statusOk)
    }
    GroupRow(
        texts.statusTile,
        onClick = {
            scope.launch {
                if (warning.recheck().isHealthy) toasts.show(SettingsEvent.Message(texts.statusOk)) else warning.showDetails()
            }
        },
        modifier = modifier,
        shape = shape,
        subtitle = summary,
        icon = icon,
        iconTint = tint,
        trailing = { Chevron() },
    )
}

/**
 * Opens another feature's screen from Settings ([com.edde746.plezy.presentation.settings.SettingsEvent.OpenExternal]):
 * Services, the profile picker and Add connection through [place] (which keeps them beside the hub on wide windows),
 * the Supporter sheet, the donation page.
 */
internal fun openExternal(target: ExternalTarget, app: AppSession, place: (show: () -> Unit) -> Unit) {
    when (target) {
        ExternalTarget.SERVICES -> place { app.navigator.navigate(Route.Services) }
        ExternalTarget.PROFILES -> place { app.navigator.navigate(Route.ProfilePicker(required = false, manage = true)) }
        ExternalTarget.ADD_CONNECTION -> place { app.onboarding.addConnection() }
        ExternalTarget.SUPPORTER -> openSupporter {}
        ExternalTarget.DONATE -> app.donationUrl?.let(app::openUrl)
        ExternalTarget.LOGOUT -> app.userMenu.act(UserMenuAction.LOGOUT)
    }
}

/** The Supporter sheet's caller while it is open ([SupporterSheetHost]), told whether the perks are unlocked as it closes. */
private var supporterRequest: ((unlocked: Boolean) -> Unit)? by mutableStateOf(null)

/** Opens the Supporter sheet over Settings (the tile, a locked theme picked) and tells [onClosed] whether it unlocked the perks. */
internal fun openSupporter(onClosed: (unlocked: Boolean) -> Unit) {
    supporterRequest = onClosed
}

/** The Supporter sheet while [openSupporter] asked for it; hosted once by the settings screens. */
@Composable
internal fun SupporterSheetHost(app: AppSession) {
    val request = supporterRequest ?: return
    SupporterSheet(app) {
        supporterRequest = null
        request(app.supporter.unlocked.value)
    }
}
