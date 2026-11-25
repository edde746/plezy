package com.edde746.plezy.watch

import com.edde746.plezy.format.formatTimecode
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaVersion
import com.edde746.plezy.model.formatMediaTargetLabel
import com.edde746.plezy.strings.T
import party.openwatch.EndReason
import party.openwatch.MatchState
import party.openwatch.Media
import party.openwatch.MediaKind
import party.openwatch.Participant
import party.openwatch.PlayerState
import kotlin.math.abs
import kotlin.math.roundToLong

/** Watch Together's words for both UIs, in the language `T` is set to. */
internal object WatchLabels {
    /** The user's text for an SDK or relay error [code]; codes this app doesn't know get the generic text. */
    fun errorText(code: String): String {
        val errors = T.watchTogether.errors
        return when (code) {
            "invalid_code" -> errors.invalidCode
            "room_not_found" -> errors.roomNotFound
            "room_full" -> errors.roomFull
            "room_locked" -> errors.roomLocked
            "relay_full" -> errors.relayFull
            "unreachable" -> errors.unreachable
            "rate_limited" -> errors.rateLimited
            "client_blocked" -> errors.clientBlocked
            "forbidden" -> errors.forbidden
            "not_in_room" -> errors.notInRoom
            "already_in_room" -> errors.alreadyInRoom
            "resume_failed" -> errors.resumeFailed
            "unsupported" -> errors.unsupported
            else -> errors.generic
        }
    }

    /** Why the room ended for this user; null for their own leave. */
    fun endText(reason: EndReason): String? = when (reason) {
        EndReason.LEFT -> null
        EndReason.ENDED -> T.watchTogether.ended.ended
        EndReason.KICKED -> T.watchTogether.ended.kicked
        EndReason.EXPIRED -> T.watchTogether.ended.expired
        EndReason.REPLACED -> T.watchTogether.ended.replaced
        EndReason.LOST -> T.watchTogether.ended.lost
    }

    /**
     * The snackbar text for [notice], or null when it shows nothing (an action this app doesn't describe, a host change
     * without a host). [media] and [host] are the room as the notice arrives: a `media` action names the new media, a
     * `host` action the new host.
     */
    fun noticeText(notice: WatchNotice, media: Media? = null, host: Participant? = null, myPeerId: String? = null): String? {
        val notices = T.watchTogether.notices
        return when (notice) {
            is WatchNotice.Action -> {
                val name = notice.name
                when (notice.kind) {
                    "play" -> if (name == null) notices.playbackStarted else notices.pressedPlay(name)
                    "pause" -> if (name == null) notices.playbackPaused else notices.paused(name)
                    "seek" -> notice.positionMs?.let { ms ->
                        val position = formatTimecode(ms / 1000.0)
                        if (name == null) notices.roomJumpedTo(position) else notices.jumpedTo(name, position)
                    }
                    "rate" -> notice.rate?.let { rate ->
                        val speed = rateText(rate)
                        if (name == null) notices.speedChanged(speed) else notices.changedSpeed(name, speed)
                    }
                    "media" -> when {
                        media == null -> if (name == null) notices.mediaStopped else notices.stoppedMedia(name)
                        name == null -> notices.mediaStarted(mediaTitle(media))
                        else -> notices.startedMedia(name, mediaTitle(media))
                    }
                    "stall" -> if (name == null) notices.waitingForSomeone else notices.waitingFor(name)
                    "ended" -> notices.finished
                    "host" -> host?.let { if (it.peerId == myPeerId) notices.youAreNowHost else notices.hostChangedTo(it.name) }
                    else -> null
                }
            }
            is WatchNotice.Joined -> notices.joined(notice.name)
            is WatchNotice.Left -> notices.left(notice.name)
            is WatchNotice.Refused -> errorText(notice.code)
            WatchNotice.ControlRefused -> notices.controlRefused
            WatchNotice.SearchFailed -> notices.searchFailed
            WatchNotice.PlayBlocked -> notices.playBlocked
            is WatchNotice.Ended -> endText(notice.reason)
            WatchNotice.ShareFailed -> notices.shareFailed
            WatchNotice.NotShared -> notices.downloadNotShared
            WatchNotice.OpenFailed -> notices.openFailed
            WatchNotice.ChoiceFailed -> T.watchTogether.choiceFailed
        }
    }

    /** The room's media in one line: a movie with its year, an episode as series, `S1 E2` and title. */
    fun mediaTitle(media: Media): String = when (media.kind) {
        MediaKind.EPISODE -> listOfNotNull(
            media.series?.title,
            if (media.season != null && media.episode != null) "S${media.season} E${media.episode}" else null,
            media.title.takeIf { it != media.series?.title },
        ).joinToString(SEPARATOR)
        MediaKind.MOVIE -> if (media.year == null) media.title else "${media.title} (${media.year})"
        MediaKind.VIDEO -> media.title
    }

    /** A copy's item in one line: title, and series and season/episode for an episode. */
    fun copyTitle(copy: WatchCopy): String = copy.item?.let(::formatMediaTargetLabel) ?: T.common.unknown

    /** The copy's version as its technical label, with the server and length: "1080p H.264 MKV (8.5 Mbps) · Home server · 2h 1m". */
    fun copyDetails(copy: WatchCopy): String {
        val duration = copy.durationMs
        return listOfNotNull(
            versionLabel(copy.item, copy.version),
            copy.item?.serverName,
            duration?.takeIf { it > 0 }?.let(::durationText),
        ).joinToString(SEPARATOR)
    }

    /**
     * [version]'s label without a name that only restates [item]'s title (with or without its year): Plex and Jellyfin
     * often name a movie's only version after the movie. Null without a version or when nothing else is left.
     */
    fun versionLabel(item: MediaItem?, version: MediaVersion?): String? {
        if (version == null) return null
        val label = version.displayLabel
        val name = version.name
        if (name.isNullOrEmpty() || !restatesTitle(name, item)) return label
        val prefix = "$name$SEPARATOR"
        return if (label.startsWith(prefix)) label.substring(prefix.length) else null
    }

    /** How a file's length compares with the room's: "2m longer", "Same length". */
    fun lengthDifference(deltaMs: Long?): String {
        if (deltaMs == null) return T.watchTogether.lengthUnknown
        val magnitude = abs(deltaMs)
        if (magnitude < 1000) return T.watchTogether.lengthSame
        val duration = durationText(magnitude)
        return if (deltaMs > 0) T.watchTogether.lengthLonger(duration) else T.watchTogether.lengthShorter(duration)
    }

    /** The app part of a participant's `client` ("Plezy/2.23.0" → "Plezy"). */
    fun clientApp(client: String): String = client.substringBefore('/')

    fun playerStateText(state: PlayerState): String = when (state) {
        PlayerState.IDLE -> T.watchTogether.playerIdle
        PlayerState.LOADING -> T.watchTogether.playerLoading
        PlayerState.READY -> T.watchTogether.playerReady
        PlayerState.BUFFERING -> T.watchTogether.playerBuffering
    }

    fun matchStateText(state: MatchState): String = when (state) {
        MatchState.SEARCHING -> T.watchTogether.matchSearching
        MatchState.MATCHED -> T.watchTogether.matchMatched
        MatchState.MISMATCHED -> T.watchTogether.matchMismatched
        MatchState.UNAVAILABLE -> T.watchTogether.matchUnavailable
    }

    /** A sync offset as the offset controls show it: "+200ms", "-1500ms", "+12.5s" from 10 s. */
    fun offsetText(offsetMs: Long): String {
        val sign = if (offsetMs >= 0) "+" else "-"
        val magnitude = abs(offsetMs)
        if (magnitude >= 10_000) {
            val tenths = (magnitude / 100.0).roundToLong()
            return "$sign${tenths / 10}.${tenths % 10}s"
        }
        return "$sign${magnitude}ms"
    }

    /** A room rate: 1.25 → "1.25x", 2.0 → "2x". */
    fun rateText(rate: Double): String {
        val hundredths = (rate * 100).roundToLong()
        val whole = hundredths / 100
        val fraction = (hundredths % 100).toString().padStart(2, '0').trimEnd('0')
        return if (fraction.isEmpty()) "${whole}x" else "$whole.${fraction}x"
    }

    /** A length in words: "2h 1m", "45m", under a minute "45s"; units at zero left out. */
    fun durationText(ms: Long): String {
        val totalSeconds = ms / 1000
        if (totalSeconds < 60) return "${totalSeconds}s"
        val days = totalSeconds / 86_400
        val hours = totalSeconds % 86_400 / 3600
        val minutes = totalSeconds % 3600 / 60
        return listOfNotNull(
            days.takeIf { it > 0 }?.let { "${it}d" },
            hours.takeIf { it > 0 }?.let { "${it}h" },
            minutes.takeIf { it > 0 }?.let { "${it}m" },
        ).joinToString(" ")
    }

    private fun restatesTitle(name: String, item: MediaItem?): Boolean {
        val title = item?.title
        if (title.isNullOrEmpty()) return false
        val nameWords = words(name)
        val titleWords = words(title)
        if (nameWords == titleWords) return true
        val year = item.year ?: return false
        return nameWords == titleWords + year.toString()
    }

    private fun words(text: String): List<String> = WORD.findAll(text.lowercase()).map { it.value }.toList()

    private val WORD = Regex("""[\p{L}\p{N}]+""")

    private const val SEPARATOR = " · "
}
