package com.edde746.plezy.watch

import party.openwatch.Candidate
import party.openwatch.Connection
import party.openwatch.Control
import party.openwatch.Media
import party.openwatch.Participant
import party.openwatch.PartyState
import party.openwatch.Phase
import party.openwatch.Room
import party.openwatch.formatCode

/**
 * Watch Together as the UI shows it, one value per change ([WatchTogether.state]).
 *
 * @property party the party's state (Open Watch Party SDK): connection, room, media, match, choice, mismatch, offset;
 *   after a room ended, its last state (the end reason) until the next one.
 * @property following the room's file is open in this user's player and the room drives it ([WatchTogether.follows]).
 * @property canJoinPlayback the room plays a file this user has but isn't watching: "Join Current Playback".
 * @property playBlocked the player refused to start in a playing room; the user has to press play on it.
 * @property searchFailed the last search for the room's current media found nothing while some server couldn't be
 *   searched: no copies listed doesn't mean there are none.
 * @property relayBaseUrl the self-hosted relay rooms use; null for the public relays.
 * @property pausedHere the player paused on this device alone, out of the room's playback ([WatchAway.PAUSED_HERE]).
 * @property chosen how many copies this user chose for the room's media ([WatchTogether.choose]) and the room took:
 *   a page that offered the choice closes once it grows.
 */
data class WatchSnapshot(
    val party: PartyState<WatchCopy> = PartyState(),
    val following: Boolean = false,
    val canJoinPlayback: Boolean = false,
    val playBlocked: Boolean = false,
    val searchFailed: Boolean = false,
    val relayBaseUrl: String? = null,
    val pausedHere: Boolean = false,
    val chosen: Int = 0,
) {
    val connection: Connection get() = party.connection

    /** In a room, or joining one. */
    val inSession: Boolean
        get() = connection == Connection.CONNECTING || connection == Connection.CONNECTED || connection == Connection.RECONNECTING

    val connected: Boolean get() = connection == Connection.CONNECTED

    val reconnecting: Boolean get() = connection == Connection.RECONNECTING

    val room: Room? get() = party.room.takeIf { inSession }

    val roomCode: String? get() = room?.code

    /** The code as people read it: `K7M-Q2X`. */
    val formattedRoomCode: String? get() = roomCode?.let(::formatCode)

    val participants: List<Participant> get() = room?.participants.orEmpty()

    val myPeerId: String? get() = party.peerId

    val isHost: Boolean get() = inSession && party.isHost

    val canControl: Boolean get() = inSession && party.canControl

    val control: Control get() = room?.control ?: Control.HOST

    val locked: Boolean get() = room?.locked ?: false

    val media: Media? get() = party.media.takeIf { inSession }

    /**
     * The room's media is at its end: it played there, or a controller sought it there. The room holds there (paused, or
     * waiting after a play, which pauses there again) until the host's app shares what plays next.
     */
    val atMediaEnd: Boolean
        get() {
            val room = room ?: return false
            val media = media ?: return false
            return room.phase != Phase.PLAYING && room.positionMs >= media.durationMs
        }

    /**
     * The room's file this user would open: their match, or the media they shared themselves (id `""`). Null while
     * searching or without a copy.
     */
    val roomCopy: Candidate<WatchCopy>? get() = party.choice.takeIf { inSession }

    /** The participant who hosts. */
    val host: Participant? get() = participants.firstOrNull { it.host }
}

/** What an open player gives the room ([WatchTogether.registerPlayer]). */
internal class WatchPlayerHooks(
    /** Switches the open player to the copy; whether it is opening. */
    val openInPlace: suspend (WatchCopy) -> Boolean,
    /** Closes the player: the room stopped its media. */
    val exitPlayer: () -> Unit,
)

/** Why the user is away from the player: the room stops waiting for them meanwhile ([WatchTogether.setAway]). */
internal enum class WatchAway {
    /** The app went to the background. */
    BACKGROUND,

    /**
     * The player paused on this device alone, for something only this user has (a call, the audio output gone, the
     * sleep timer), for one who doesn't control the room's playback.
     */
    PAUSED_HERE,

    /** The car forbids video while driving (Android Automotive): this player pauses alone, not the room. */
    VEHICLE_RESTRICTED,

    /** The profile picker covers the player until a profile is chosen: this player pauses alone, not the room. */
    PROFILE_SELECTION,
}

/**
 * [name] as an Open Watch Party display name: 1 to 32 code points of protocol text ([MediaDescriptor.descriptorText]);
 * "Plezy" when nothing is left.
 */
internal fun watchDisplayName(name: String): String {
    val text = MediaDescriptor.descriptorText(name) ?: return DEFAULT_NAME
    var end = 0
    var points = 0
    while (end < text.length && points < MAX_NAME_CODE_POINTS) {
        end += if (text[end].isHighSurrogate() && end + 1 < text.length) 2 else 1
        points++
    }
    return text.substring(0, end).trim().ifEmpty { DEFAULT_NAME }
}

/** This choice in [room]: one key per epoch and file, so the room opens each choice once. */
internal fun Candidate<WatchCopy>.keyIn(room: Room?): String = "${room?.epoch}:${ref.serverId}:${ref.itemId}:${ref.versionId}"

private const val DEFAULT_NAME = "Plezy"
private const val MAX_NAME_CODE_POINTS = 32
