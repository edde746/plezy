package com.edde746.plezy.ui.cast

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Icon
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.cast.CastSender
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.cast.CastDeviceKind
import com.edde746.plezy.presentation.cast.CastNoticeKind
import com.edde746.plezy.presentation.cast.CastSenderUiState
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.LocalWindowLayout
import com.edde746.plezy.ui.adaptive.WidthClass
import com.edde746.plezy.ui.components.IconButtonStyle
import com.edde746.plezy.ui.components.PlezyIconButton
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.navigation.RailExtra
import com.edde746.plezy.ui.probe.layoutProbe
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.filterNotNull
import kotlinx.coroutines.flow.map

/**
 * The app's cast sender, for the cast buttons beside the detail pages' Play ([CastButton]); null where there is none
 * (tests), and then no button shows.
 */
val LocalCastSender = staticCompositionLocalOf<CastSender?> { null }

/**
 * What the cast picker, the now-playing bar and the control sheet do, one intent of the sender's each: [castIntents]
 * binds them to the app's [CastSender].
 */
class CastIntents(
    val choose: (deviceId: String) -> Unit,
    val chooseThisDevice: () -> Unit,
    val closePicker: () -> Unit,
    val openControls: () -> Unit,
    val closeControls: () -> Unit,
    val togglePause: () -> Unit,
    val seekTo: (seconds: Double) -> Unit,
    val seekBy: (seconds: Double) -> Unit,
    val selectAudio: (key: String) -> Unit,
    val selectSubtitle: (key: String) -> Unit,
    val selectQuality: (key: String) -> Unit,
    val previous: () -> Unit,
    val next: () -> Unit,
    val stop: () -> Unit,
    val setVolume: (percent: Int) -> Unit,
    val disconnect: () -> Unit,
)

fun castIntents(sender: CastSender) = CastIntents(
    choose = sender::choose,
    chooseThisDevice = sender::chooseThisDevice,
    closePicker = sender::closePicker,
    openControls = sender::openControls,
    closeControls = sender::closeControls,
    togglePause = sender::togglePause,
    seekTo = sender::seekTo,
    seekBy = sender::seekBy,
    selectAudio = sender::selectAudio,
    selectSubtitle = sender::selectSubtitle,
    selectQuality = sender::selectQuality,
    previous = sender::previous,
    next = sender::next,
    stop = sender::stop,
    setVolume = sender::setVolume,
    disconnect = sender::disconnect,
)

/**
 * Casting's overlays over the whole app, the player included: the device picker, the control sheet and the receiver's
 * pairing question, as their states ask. The sender's notices go to the app's notice ([AppSession.notify]), an error in
 * the error colour; one that comes while the picker is open (a refused pairing) shows in the picker instead, which
 * would cover the notice, until the picker closes or links anew.
 */
@Composable
fun CastOverlays(app: AppSession) {
    val sender = app.castSender
    val state by sender.state.collectAsState()
    val receiver by app.castReceiver.state.collectAsState()
    val intents = remember(sender) { castIntents(sender) }
    var pickerNotice by remember { mutableStateOf<String?>(null) }
    LaunchedEffect(sender) {
        sender.state.map { it.notice }.distinctUntilChanged().filterNotNull().collect { notice ->
            if (sender.state.value.picker != null) {
                pickerNotice = notice.message
            } else {
                app.notify(notice.message, isError = notice.kind != CastNoticeKind.ENDED)
            }
            sender.dismissNotice()
        }
    }
    val picker = state.picker
    // Gone with the picker, and as a new link opens from it.
    val linking = picker?.devices?.any { it.connecting } == true
    LaunchedEffect(picker == null, linking) { if (picker == null || linking) pickerNotice = null }
    picker?.let { CastPicker(it, intents, pickerNotice) }
    val target = state.target
    if (state.controlsOpen && state.casting && target != null) CastControlSheet(target.name, state.nowPlaying, state.barIdleText, intents)
    receiver.prompt?.let { CastPairingPromptDialog(it, onAllow = app.castReceiver::approve, onDeny = app.castReceiver::refuse) }
}

/**
 * The cast button beside Play, or across from Back on phones ([castInTopBar]; [overPicture]: drawn as Back and the
 * detail's other round buttons are, over the page's picture): the cast icon, the connected one in the primary fill
 * while casting; it opens the device picker.
 * Nothing without a [LocalCastSender]. Harness name `cast.button`.
 */
@Composable
fun CastButton(modifier: Modifier = Modifier, overPicture: Boolean = false) {
    val sender = LocalCastSender.current ?: return
    val casting = sender.state.collectAsState().value.casting
    PlezyIconButton(
        castIcon(casting),
        T.cast.title,
        { sender.openPicker(fromPlayer = false) },
        modifier.layoutProbe("cast.button"),
        style = when {
            casting -> IconButtonStyle.PRIMARY
            overPicture -> IconButtonStyle.OVER_PICTURE
            else -> IconButtonStyle.FILLED
        },
        selected = casting,
    )
}

/**
 * Phones (a compact handheld window): a page's cast button sits in its top bar across from Back, out of its action row,
 * so the row stays the same whether a cast device is there or not.
 */
val castInTopBar: Boolean
    @Composable get() = LocalWindowLayout.current.let { it.formFactor == FormFactor.HANDHELD && it.widthClass == WidthClass.COMPACT }

/** The cast button's icon: the connected one while [casting]. */
fun castIcon(casting: Boolean): ImageVector = if (casting) PlezyIcons.CastConnected else PlezyIcons.Cast

/** A cast device's icon by its [kind]. */
internal fun CastDeviceKind.icon(): ImageVector = when (this) {
    CastDeviceKind.TV -> PlezyIcons.Tv
    CastDeviceKind.DESKTOP -> PlezyIcons.Computer
    CastDeviceKind.HANDHELD -> PlezyIcons.PhoneAndroid
}

/** This device's icon, by the form factor it lays out as. */
@Composable
internal fun thisDeviceIcon(): ImageVector = when (LocalWindowLayout.current.formFactor) {
    FormFactor.TV -> PlezyIcons.Tv
    FormFactor.DESKTOP -> PlezyIcons.Computer
    FormFactor.HANDHELD -> PlezyIcons.PhoneAndroid
}

/**
 * The rail's and the TV column's cast item while casting ([CastSenderUiState.casting]): "Casting to <device>" over what
 * plays there (or that it is ready); a pick opens the control sheet. Harness name `nav.cast`.
 */
@Composable
fun castRailItem(state: CastSenderUiState, onOpen: () -> Unit): RailExtra? {
    val target = state.target?.takeIf { state.casting } ?: return null
    val label = T.cast.bar.castingTo(name = target.name)
    val subtitle = state.nowPlaying?.title ?: state.barIdleText
    return remember(label, subtitle, onOpen) {
        RailExtra(label, "nav.cast", { tint -> Icon(PlezyIcons.CastConnected, contentDescription = null, Modifier.size(24.dp), tint = tint) }, onOpen, subtitle = subtitle)
    }
}

/**
 * "Casting from <device>": the small line the player's chrome and Now Playing show while a cast plays here, the cast
 * icon before it in [color].
 */
@Composable
fun CastingFromLine(text: String, probe: String, modifier: Modifier = Modifier, color: Color = LocalContentColor.current) {
    Row(modifier.layoutProbe(probe, reportsFocus = false), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
        Icon(PlezyIcons.CastConnected, contentDescription = null, Modifier.size(14.dp), tint = color)
        Text(text, style = MaterialTheme.typography.labelMedium, color = color, maxLines = 1, overflow = TextOverflow.Ellipsis)
    }
}
