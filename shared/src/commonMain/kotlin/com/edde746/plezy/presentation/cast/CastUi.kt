package com.edde746.plezy.presentation.cast

import com.edde746.plezy.strings.T

/** What kind of device a cast receiver or sender is: the icon the picker and Settings show beside its name. */
enum class CastDeviceKind { TV, DESKTOP, HANDHELD }

/**
 * A Plezy device on the network: [id] is its install's cast id (stable across launches), [name] the name it gives
 * itself, [platform] its system as the device names it (`Android`, `iOS`, `tvOS`, `macOS`, `Windows`, `Linux`).
 */
data class CastDevice(val id: String, val name: String, val platform: String, val kind: CastDeviceKind)

/** How the sender's link to its target stands. */
enum class CastLinkStatus {
    /** No target: Play plays on this device. */
    IDLE,

    /** Opening the link to the chosen receiver. */
    CONNECTING,

    /** The receiver asks its user to allow this device; both show [CastPickerUiState.pairing]'s code. */
    PAIRING,

    /** The target is connected: Play plays there, the bar and the controls show. */
    CONNECTED,
}

/**
 * The device picker (the cast button's sheet): "This device" first, then the receivers found on the network. Open
 * while [CastSenderUiState.picker] isn't null; closing it ([com.edde746.plezy.cast.CastSender.closePicker]) cancels a
 * pairing in progress.
 *
 * @param fromPlayer opened from the player's top bar: choosing a receiver hands over what plays here (item and
 *   position) and closes the local player.
 * @param thisDeviceSelected "This device" carries the check: no receiver is the target.
 * @param searching the picker is still looking: a spinner beside the list (it looks for as long as it is open).
 * @param pairing the code to show while the chosen receiver asks its user; null otherwise.
 */
data class CastPickerUiState(
    val fromPlayer: Boolean,
    val devices: List<CastDeviceRow>,
    val thisDeviceSelected: Boolean,
    val searching: Boolean,
    val pairing: CastPairingCode? = null,
)

/**
 * One receiver in the picker.
 *
 * @param selected it is the target now (the check).
 * @param connecting the link to it is opening or pairing (a spinner in place of the check).
 * @param nowPlaying what it plays now ("Playing <title>"), known for receivers this device paired with; choosing it then
 *   picks up control without restarting playback.
 */
data class CastDeviceRow(
    val device: CastDevice,
    val selected: Boolean,
    val connecting: Boolean,
    val nowPlaying: String?,
)

/** The 4-digit code both devices show while [deviceName] asks its user to allow this device. */
data class CastPairingCode(val deviceName: String, val code: String, val title: String, val message: String)

/** What the receiver plays, which the bar and the controls show. */
enum class CastMediaKind { VIDEO, MUSIC, LIVE }

/**
 * One choice of a track or quality menu in the controls. [key] is what the store's select intent takes back.
 */
@kotlinx.serialization.Serializable
data class CastOption(val key: String, val label: String, val detail: String?, val selected: Boolean)

/**
 * What the target plays, from its state stream: the now-playing bar (every screen) and the control sheet draw it.
 *
 * @param position / [duration] formatted ("12:34"); [progress] 0..1. Live TV has no duration: [canSeek] is false.
 * @param volume the receiver's player volume (0–100); null when it has no volume to set (the bar and sheet hide it).
 * @param artworkUrl the item's poster from this device's own access to its server; null when this device has none.
 */
data class CastNowPlaying(
    val receiverName: String,
    val kind: CastMediaKind,
    val title: String,
    val subtitle: String?,
    val artworkUrl: String?,
    val paused: Boolean,
    val buffering: Boolean,
    val positionSeconds: Double,
    val durationSeconds: Double,
    val position: String,
    val duration: String,
    val progress: Float,
    val canSeek: Boolean,
    val audioTracks: List<CastOption>,
    val subtitleTracks: List<CastOption>,
    val qualities: List<CastOption>,
    val hasPrevious: Boolean,
    val hasNext: Boolean,
    val volume: Int?,
)

/** Why a [CastNotice] shows. Every kind but [ENDED] also dropped the target: Play plays on this device again. */
enum class CastNoticeKind { RECEIVER_UNREACHABLE, PAIRING_REFUSED, SERVER_UNREACHABLE, PLAYBACK_FAILED, ENDED }

/** A message for the user (a snackbar or toast), [message] already in their language; dismiss it once shown. */
data class CastNotice(val kind: CastNoticeKind, val message: String)

/**
 * The sender's whole cast state ([com.edde746.plezy.cast.CastSender.state]).
 *
 * @param target the receiver Play plays on; null: this device.
 * @param picker the open picker; null while closed.
 * @param nowPlaying what the target plays; null while it plays nothing (the bar then reads [barIdleText]).
 * @param controlsOpen the control sheet is open ([com.edde746.plezy.cast.CastSender.openControls]).
 */
data class CastSenderUiState(
    val target: CastDevice? = null,
    val status: CastLinkStatus = CastLinkStatus.IDLE,
    val picker: CastPickerUiState? = null,
    val nowPlaying: CastNowPlaying? = null,
    val controlsOpen: Boolean = false,
    val notice: CastNotice? = null,
) {
    /** Connected to a target: the cast button shows as active and the now-playing bar shows on every screen. */
    val casting: Boolean get() = target != null && status == CastLinkStatus.CONNECTED

    /** The bar's second line while the target plays nothing. */
    val barIdleText: String? get() = target?.takeIf { casting && nowPlaying == null }?.let { T.cast.bar.ready }
}

/**
 * A receiver's question to its user: "Allow <device> to cast?" with the code the sender shows too. TV receivers
 * approve with the D-pad (Allow focused first), desktop and phone receivers by click.
 */
data class CastPairingPrompt(val senderName: String, val code: String, val title: String, val message: String)

/**
 * The receiver's cast state ([com.edde746.plezy.cast.CastReceiver.state]).
 *
 * @param prompt the pairing question to show over everything (the player too); null when none waits.
 * @param castingFrom the player chrome's small line ("Casting from Pixel 8") while a cast plays here; null otherwise.
 */
data class CastReceiverUiState(
    val prompt: CastPairingPrompt? = null,
    val castingFrom: String? = null,
)
