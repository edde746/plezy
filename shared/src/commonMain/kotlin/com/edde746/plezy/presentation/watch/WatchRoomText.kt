package com.edde746.plezy.presentation.watch

import com.edde746.plezy.strings.T
import com.edde746.plezy.watch.WatchCopy
import com.edde746.plezy.watch.WatchLabels
import com.edde746.plezy.watch.WatchSnapshot
import party.openwatch.Control
import party.openwatch.MatchState
import party.openwatch.MediaKind
import party.openwatch.Participant
import kotlin.math.abs

/** The room as the screen and the player's session sheet lay it out, from [WatchSnapshot]. */
internal object WatchRoomText {
    fun room(s: WatchSnapshot): WatchRoomUi {
        val text = T.watchTogether
        val isHost = s.isHost
        return WatchRoomUi(
            title = text.title,
            reconnecting = if (s.reconnecting) WatchBannerUi(text.reconnecting, text.reconnectingDescription) else null,
            header = header(s),
            status = listOf(status(s), text.participantCount(s.participants.size)).joinToString(SEPARATOR),
            media = media(s),
            offset = offset(s),
            participantsTitle = text.participants,
            participantCount = text.participantCount(s.participants.size),
            participants = s.participants.map { participant(s, it) },
            settings = if (isHost) settings(s) else null,
            leave = WatchConfirmUi(text.leaveRoom, text.leaveRoomQuestion, text.leaveRoomConfirm, text.leave, T.common.cancel, destructive = false),
            end = if (isHost) WatchConfirmUi(text.endRoom, text.endRoomQuestion, text.endRoomConfirm, text.end, T.common.cancel, destructive = true) else null,
            isHost = isHost,
        )
    }

    /** "Reconnecting…", "Connected" or "Connecting…". */
    fun status(s: WatchSnapshot): String = when {
        s.reconnecting -> T.watchTogether.reconnecting
        s.connected -> T.watchTogether.connected
        else -> T.watchTogether.connecting
    }

    private fun header(s: WatchSnapshot): WatchHeaderUi {
        val text = T.watchTogether
        val code = s.formattedRoomCode.orEmpty()
        val hostName = s.host?.name
        return WatchHeaderUi(
            codeLabel = text.roomCode,
            code = code,
            copy = text.copyCode,
            copied = text.codeCopied,
            share = text.shareInvite,
            invite = text.inviteMessage(code),
            invited = text.inviteCopied,
            role = when {
                s.isHost -> text.youAreHost
                hostName != null -> text.hostedBy(hostName)
                else -> ""
            },
            // The host's setting says it (WatchHostSettingsUi.everyone): the header only tells a guest.
            control = when {
                s.isHost -> null
                s.control == Control.EVERYONE -> text.anyoneCanControl
                else -> text.hostControlsPlayback
            },
            locked = if (s.locked) text.roomLocked else null,
        )
    }

    private fun media(s: WatchSnapshot): WatchMediaUi {
        val text = T.watchTogether
        val media = s.media
        return WatchMediaUi(
            heading = text.nowPlaying,
            title = media?.let(WatchLabels::mediaTitle),
            idle = text.nothingPlaying,
            idleDetail = if (s.isHost) text.nothingPlayingHost else text.nothingPlayingGuest,
            notShareable = if (media?.kind == MediaKind.VIDEO) text.notShareable else null,
            match = match(s),
            summary = matchSummary(s),
            joinPlayback = if (s.canJoinPlayback) WatchActionUi(text.joinCurrentPlayback, text.joinCurrentPlaybackDescription) else null,
            stop = if (media != null && s.isHost) text.stopMedia else null,
            copies = copies(s),
        )
    }

    /** This user's match in one line, for a summary row; null without media. */
    fun matchSummary(s: WatchSnapshot): String? {
        if (s.media == null) return null
        val text = T.watchTogether
        val copy = s.roomCopy
        if (copy != null && copy.id.isEmpty()) return text.sharingYourCopy
        if (s.party.mismatch != null) return text.mismatchTitle
        val match = s.party.match
        return when (match?.state) {
            null, MatchState.SEARCHING -> text.searching
            MatchState.MATCHED -> copy?.let { WatchLabels.copyTitle(it.ref) } ?: text.yourCopy
            MatchState.MISMATCHED -> text.playingOtherLength(WatchLabels.lengthDifference(match.deltaMs))
            MatchState.UNAVAILABLE -> unavailableTitle(s)
        }
    }

    private fun unavailableTitle(s: WatchSnapshot): String =
        if (s.searchFailed) T.watchTogether.notices.searchFailed else T.watchTogether.unavailableTitle

    private fun match(s: WatchSnapshot): WatchMatchUi? {
        if (s.media == null) return null
        val text = T.watchTogether
        val copy = s.roomCopy
        if (copy != null && copy.id.isEmpty()) return WatchMatchUi.Sharing(copy(copy.ref, text.sharingYourCopy))
        mismatch(s)?.let { return WatchMatchUi.Mismatch(it) }
        val match = s.party.match
        return when (match?.state) {
            null, MatchState.SEARCHING -> WatchMatchUi.Searching(text.searching)
            MatchState.MATCHED, MatchState.MISMATCHED -> WatchMatchUi.Playing(
                label = if (match.state == MatchState.MATCHED) text.yourCopy else text.playingOtherLength(WatchLabels.lengthDifference(match.deltaMs)),
                copy = copy?.let { copy(it.ref, label = null) },
                chooseAnother = if (s.party.candidates.size > 1) text.chooseAnotherCopy else null,
            )
            MatchState.UNAVAILABLE -> WatchMatchUi.Unavailable(unavailableTitle(s), text.unavailableDescription, text.chooseCopy, text.searchAgain)
        }
    }

    /** The mismatch waiting for this user, with its key; null without one. */
    fun mismatch(s: WatchSnapshot): WatchMismatchUi? {
        val mismatch = s.party.mismatch ?: return null
        val text = T.watchTogether
        val difference = WatchLabels.lengthDifference(mismatch.deltaMs)
        return WatchMismatchUi(
            key = "${s.room?.epoch}|${mismatch.candidate.id}",
            title = text.mismatchTitle,
            description = text.mismatchDescription(difference),
            copy = copy(mismatch.candidate.ref, label = null),
            playAnyway = text.playAnyway,
            chooseAnother = text.chooseAnotherCopy,
            dontPlay = text.dontPlay,
        )
    }

    /** The mismatch the player asks about: connected, and never for the host's own media. */
    fun mismatchPrompt(s: WatchSnapshot): WatchMismatchUi? {
        if (!s.connected) return null
        val copy = s.roomCopy
        if (s.isHost && copy != null && copy.id.isEmpty()) return null
        return mismatch(s)
    }

    private fun copy(copy: WatchCopy, label: String?) = WatchCopyUi(label, WatchLabels.copyTitle(copy), WatchLabels.copyDetails(copy))

    private fun copies(s: WatchSnapshot): WatchCopiesUi {
        val text = T.watchTogether
        val current = s.roomCopy?.ref
        val searching = s.party.match?.state == MatchState.SEARCHING
        val candidates = s.party.candidates
        return WatchCopiesUi(
            title = text.chooseCopy,
            rows = candidates.map { ranked ->
                val ref = ranked.candidate.ref
                WatchCandidateUi(
                    id = ranked.candidate.id,
                    title = WatchLabels.copyTitle(ref),
                    subtitle = listOf(WatchLabels.copyDetails(ref), WatchLabels.lengthDifference(ranked.deltaMs)).filter { it.isNotEmpty() }.joinToString(SEPARATOR),
                    current = ref == current,
                )
            },
            empty = if (candidates.isEmpty() && !searching) (if (s.searchFailed) text.notices.searchFailed else text.noCandidates) else null,
            searching = if (searching) text.searching else null,
            searchAgain = text.searchAgain,
            searchAgainEnabled = !searching,
            chosen = s.chosen,
        )
    }

    private fun offset(s: WatchSnapshot): WatchOffsetUi {
        val text = T.watchTogether
        val offset = s.party.offsetMs
        val match = s.party.match
        val hint = (s.party.mismatch?.deltaMs ?: match?.deltaMs?.takeIf { match.state == MatchState.MISMATCHED })?.takeIf { abs(it) >= HINT_MIN_MS }
        return WatchOffsetUi(
            title = text.syncOffset,
            value = WatchLabels.offsetText(offset),
            description = text.syncOffsetDescription,
            steps = listOf(
                WatchOffsetStepUi(text.offsetMinusSecond, offset - SECOND_MS),
                WatchOffsetStepUi(text.offsetMinusTenth, offset - TENTH_MS),
                WatchOffsetStepUi(text.offsetPlusTenth, offset + TENTH_MS),
                WatchOffsetStepUi(text.offsetPlusSecond, offset + SECOND_MS),
            ),
            reset = WatchOffsetStepUi(T.common.reset, 0, enabled = offset != 0L),
            hint = hint?.let { text.offsetHint(WatchLabels.lengthDifference(it)) },
            apply = hint?.let { WatchOffsetStepUi(text.applyDifference(WatchLabels.offsetText(it)), it, enabled = offset != it) },
        )
    }

    private fun participant(s: WatchSnapshot, participant: Participant): ParticipantUi {
        val text = T.watchTogether
        val me = participant.peerId == s.myPeerId
        val match = participant.match
        val details = listOfNotNull(
            WatchLabels.clientApp(participant.client),
            if (participant.connected) text.connected else text.disconnected,
            if (participant.connected) WatchLabels.playerStateText(participant.player) else null,
            match?.let { WatchLabels.matchStateText(it.state) },
            if (participant.offsetMs != 0L) text.participantOffset(WatchLabels.offsetText(participant.offsetMs)) else null,
        ).joinToString(SEPARATOR)
        val name = participant.name
        return ParticipantUi(
            peerId = participant.peerId,
            name = if (me) text.nameYou(name) else name,
            isYou = me,
            hostBadge = if (participant.host) text.hostBadge else null,
            connected = participant.connected,
            details = details,
            actions = if (s.isHost && !me) {
                ParticipantActionsUi(
                    title = name,
                    makeHost = WatchConfirmUi(text.makeHost, text.makeHostQuestion, text.makeHostConfirm(name), text.transfer, T.common.cancel, destructive = false),
                    remove = WatchConfirmUi(
                        text.removeParticipant,
                        text.removeParticipantQuestion(name),
                        text.removeParticipantConfirm(name),
                        text.remove,
                        T.common.cancel,
                        destructive = true,
                    ),
                )
            } else {
                null
            },
        )
    }

    private fun settings(s: WatchSnapshot): WatchHostSettingsUi {
        val text = T.watchTogether
        val everyone = s.control == Control.EVERYONE
        return WatchHostSettingsUi(
            title = text.roomSettings,
            everyone = WatchToggleUi(text.letEveryoneControl, if (everyone) text.anyoneCanControl else text.hostControlsPlayback, everyone),
            lock = WatchToggleUi(text.lockRoom, text.lockRoomDescription, s.locked),
        )
    }

    /** The player header's room pill. */
    fun pill(s: WatchSnapshot): WatchPillUi {
        val text = T.watchTogether
        val count = s.participants.size
        return WatchPillUi(
            count = count.toString(),
            connected = s.connected,
            isHost = s.isHost,
            status = if (s.reconnecting) text.reconnecting else null,
            label = text.openSessionControls,
            value = listOfNotNull(text.participantCount(count), status(s), if (s.isHost) text.youAreHost else null).joinToString(", "),
        )
    }

    /** Home's toolbar action. */
    fun toolbar(s: WatchSnapshot?): WatchToolbarUi =
        WatchToolbarUi(inSession = s?.inSession == true, participantCount = s?.participants?.size ?: 0, label = T.watchTogether.title)

    private const val SEPARATOR = " · "
    private const val HINT_MIN_MS = 1000L
    private const val SECOND_MS = 1000L
    private const val TENTH_MS = 100L
}
