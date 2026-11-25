package com.edde746.plezy.jellyfin

/** A request path and its query. */
internal data class JellyfinRoute(val path: String, val query: List<Pair<String, String?>>)

/** Live TV endpoints. Dates are ISO-8601 UTC strings; null query values are dropped on send. */
internal object JellyfinLiveTvRoutes {
    /** Live TV is available when this answers a `TotalRecordCount` above 0. */
    fun availability(userId: String) = JellyfinRoute("/LiveTv/Channels", listOf("limit" to "1", "userId" to userId))

    fun channels(userId: String) = JellyfinRoute(
        "/LiveTv/Channels",
        listOf(
            "userId" to userId,
            "enableImages" to "true",
            "enableUserData" to "true",
            "sortBy" to "SortName",
            "sortOrder" to "Ascending",
        ),
    )

    fun programs(userId: String, channelIds: List<String> = emptyList(), minEndDate: String? = null, maxStartDate: String? = null) = JellyfinRoute(
        "/LiveTv/Programs",
        listOf(
            "userId" to userId,
            "enableImages" to "true",
            "fields" to "Overview",
            "sortBy" to "StartDate",
            "sortOrder" to "Ascending",
            "channelIds" to channelIds.takeIf { it.isNotEmpty() }?.joinToString(","),
            "minEndDate" to minEndDate,
            "maxStartDate" to maxStartDate,
        ),
    )

    /** The direct stream of a tuned channel; the caller adds the token. */
    fun directStream(channelId: String, container: String, mediaSourceId: String?, liveStreamId: String?, deviceId: String) = JellyfinRoute(
        "/Videos/${JellyfinCore.segment(channelId)}/stream.$container",
        listOf("Static" to "true", "MediaSourceId" to mediaSourceId, "LiveStreamId" to liveStreamId, "DeviceId" to deviceId),
    )

    /** Releases a live stream a negotiation opened; the id must ride in the query (400 in the body). */
    fun closeLiveStream(liveStreamId: String) = JellyfinRoute("/LiveStreams/Close", listOf("liveStreamId" to liveStreamId))

    /** Kills the transcodes of one play session, leaving its live stream open. */
    fun activeEncodings(deviceId: String, playSessionId: String) =
        JellyfinRoute("/Videos/ActiveEncodings", listOf("deviceId" to deviceId, "playSessionId" to playSessionId))

    /** One guide program, for its `IsSeries` flag. */
    fun program(programId: String, userId: String) = JellyfinRoute("/LiveTv/Programs/${JellyfinCore.segment(programId)}", listOf("userId" to userId))

    /** The timer the server pre-fills for recording [programId]. */
    fun timerDefaults(programId: String) = JellyfinRoute("/LiveTv/Timers/Defaults", listOf("programId" to programId))

    /** Every timer; Emby has no status filters, so callers filter. */
    const val TIMERS = "/LiveTv/Timers"
    const val SERIES_TIMERS = "/LiveTv/SeriesTimers"

    fun timer(id: String) = "$TIMERS/${JellyfinCore.segment(id)}"

    fun seriesTimer(id: String) = "$SERIES_TIMERS/${JellyfinCore.segment(id)}"

    val seriesTimersByName = JellyfinRoute(SERIES_TIMERS, listOf("sortBy" to "SortName", "sortOrder" to "Ascending"))
}
