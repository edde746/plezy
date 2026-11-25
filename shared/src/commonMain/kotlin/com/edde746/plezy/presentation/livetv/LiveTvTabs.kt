package com.edde746.plezy.presentation.livetv

import com.edde746.plezy.livetv.LiveTvChannel
import com.edde746.plezy.livetv.LiveTvChannelGroup
import com.edde746.plezy.livetv.LiveTvProgram

/** The Live TV screen's tabs. */
enum class LiveTvTab { GUIDE, WHATS_ON, RECORDINGS }

/** What [LiveTvStore] drives in the Guide tab's store. */
interface LiveTvGuideTab {
    val refresh: LiveTvRefreshGate

    /** The rows to show ([displayed], in [groups]) and which of them are favourites (their [LiveTvChannel.scopeKey]). */
    fun setChannels(displayed: List<LiveTvChannel>, groups: List<LiveTvChannelGroup>, favoriteKeys: Set<String>)

    /** Focuses [channel]'s row; a request made while the guide loads waits for the load. */
    fun jumpToChannel(channel: LiveTvChannel)

    /** Shows the window [program] airs in and focuses its block on [channel]'s row. */
    fun jumpToProgram(channel: LiveTvChannel, program: LiveTvProgram)
}

/** What [LiveTvStore] drives in the What's On tab's store. */
interface LiveTvWhatsOnTab {
    val refresh: LiveTvRefreshGate

    /** Every loaded channel, so an airing can tune its channel. */
    fun setChannels(channels: List<LiveTvChannel>)
}

/** What [LiveTvStore] drives in the Recordings tab's store. */
interface LiveTvRecordingsTab {
    val refresh: LiveTvRefreshGate

    /** Loads the scheduled recordings and the rules again now. */
    fun reload()
}
