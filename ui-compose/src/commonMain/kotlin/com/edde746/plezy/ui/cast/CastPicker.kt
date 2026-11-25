package com.edde746.plezy.ui.cast

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.edde746.plezy.presentation.cast.CastPairingCode
import com.edde746.plezy.presentation.cast.CastPickerUiState
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.components.InlineError
import com.edde746.plezy.ui.components.ButtonStyle
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.components.PlezySheet
import com.edde746.plezy.ui.components.SheetOption
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.focus.focusReach
import com.edde746.plezy.ui.theme.PlezyColors

/**
 * The device picker: the app's sheet (a side panel on TV and the desktop) titled "Cast to", with "This device" first,
 * then the receivers found on the network, each with its kind's icon, its name and its platform (or "Playing <title>"
 * for one already playing, "Connecting…" with a spinner while its link opens); the target carries the check. While
 * it looks, a spinner and "Looking for devices…"; once it has looked and found none, how to make one show. While the
 * chosen receiver asks its user, the sheet shows the code both show instead ([PairingCodeView]). [notice] (why the last
 * choice fell back to this device: the receiver refused) heads the list in the error colour. Back closes it
 * ([CastIntents.closePicker], which cancels a pairing). Focus opens on the row with the check.
 *
 * Harness names `cast.picker`, `cast.picker.notice`, `cast.picker.thisDevice`, `cast.picker.device.<i>`,
 * `cast.picker.searching`, `cast.picker.empty`.
 */
@Composable
fun CastPicker(picker: CastPickerUiState, intents: CastIntents, notice: String? = null) {
    val initial = remember { FocusRequester() }
    val pairing = picker.pairing
    PlezySheet(
        onDismiss = intents.closePicker,
        title = if (pairing == null) T.cast.picker.title else null,
        label = pairing?.title ?: T.cast.picker.title,
        initialFocus = initial,
        probe = "cast.picker",
    ) {
        if (pairing != null) {
            PairingCodeView(pairing, intents.closePicker, initial)
        } else {
            notice?.let { InlineError(it, Modifier.padding(horizontal = 16.dp).layoutProbe("cast.picker.notice", reportsFocus = false)) }
            DeviceList(picker, intents, initial, Modifier.weight(1f, fill = false))
        }
    }
}

@Composable
private fun DeviceList(picker: CastPickerUiState, intents: CastIntents, initial: FocusRequester, modifier: Modifier) {
    val selectedIndex = picker.devices.indexOfFirst { it.selected }
    LazyColumn(
        modifier,
        contentPadding = PaddingValues(vertical = LocalPlezyDimens.current.focusReach),
        verticalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        item(key = "thisDevice") {
            SheetOption(
                T.cast.picker.thisDevice,
                intents.chooseThisDevice,
                Modifier.then(if (selectedIndex < 0) Modifier.focusRequester(initial) else Modifier).layoutProbe("cast.picker.thisDevice"),
                selected = picker.thisDeviceSelected,
                icon = thisDeviceIcon(),
            )
        }
        itemsIndexed(picker.devices, key = { _, row -> row.device.id }) { index, row ->
            SheetOption(
                row.device.name,
                { intents.choose(row.device.id) },
                Modifier.then(if (index == selectedIndex) Modifier.focusRequester(initial) else Modifier).layoutProbe("cast.picker.device.$index"),
                selected = row.selected && !row.connecting,
                detail = when {
                    row.connecting -> T.cast.picker.connecting
                    row.nowPlaying != null -> row.nowPlaying
                    else -> row.device.platform
                },
                icon = row.device.kind.icon(),
                contentLabel = true,
                badge = if (row.connecting) {
                    { CircularProgressIndicator(Modifier.size(20.dp), color = LocalContentColor.current, strokeWidth = 2.dp) }
                } else {
                    null
                },
            )
        }
        when {
            picker.searching -> item(key = "searching") {
                Row(
                    Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp).layoutProbe("cast.picker.searching", reportsFocus = false),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    CircularProgressIndicator(Modifier.size(18.dp), strokeWidth = 2.dp)
                    Text(T.cast.picker.searching, style = MaterialTheme.typography.bodyMedium, color = PlezyColors.TextMuted)
                }
            }
            picker.devices.isEmpty() -> item(key = "empty") {
                Text(
                    T.cast.picker.empty,
                    Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp).layoutProbe("cast.picker.empty", reportsFocus = false),
                    style = MaterialTheme.typography.bodyMedium,
                    color = PlezyColors.TextMuted,
                )
            }
        }
    }
}

/**
 * The pairing step of the picker: "Confirm on <device>", the 4-digit code the receiver shows too, what to check, and
 * Cancel ([onCancel]: the picker's close, which cancels the pairing), focused. Harness names `cast.pairing`,
 * `cast.pairing.code`, `cast.pairing.cancel`.
 */
@Composable
internal fun PairingCodeView(pairing: CastPairingCode, onCancel: () -> Unit, cancelFocus: FocusRequester) {
    Column(
        Modifier.fillMaxWidth().padding(horizontal = 8.dp, vertical = 8.dp).layoutProbe("cast.pairing", reportsFocus = false),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Text(pairing.title, style = MaterialTheme.typography.headlineSmall, textAlign = TextAlign.Center)
        PairingCode(pairing.code, Modifier.layoutProbe("cast.pairing.code", reportsFocus = false))
        Text(pairing.message, style = MaterialTheme.typography.bodyMedium, color = PlezyColors.TextMuted, textAlign = TextAlign.Center)
        PlezyButton(T.common.cancel, onCancel, Modifier.focusRequester(cancelFocus).layoutProbe("cast.pairing.cancel"), style = ButtonStyle.SECONDARY)
    }
}

/** A pairing code, large and spaced, as both devices show it; a screen reader reads it as it shows. */
@Composable
internal fun PairingCode(code: String, modifier: Modifier = Modifier) {
    Text(
        code,
        modifier.semantics { liveRegion = LiveRegionMode.Polite },
        style = MaterialTheme.typography.displayMedium.copy(fontFamily = FontFamily.Monospace, fontWeight = FontWeight.SemiBold, letterSpacing = 8.sp),
        textAlign = TextAlign.Center,
    )
}
