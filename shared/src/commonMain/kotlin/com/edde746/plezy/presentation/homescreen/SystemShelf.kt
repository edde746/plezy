package com.edde746.plezy.presentation.homescreen

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.links.ShelfContentId
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.EpisodePosterMode
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.strings.T

/**
 * Continue Watching mirrored to the TV's home screen ([HomeScreen]), for the active profile only.
 *
 * One profile's session is open at a time ([beginProfileSession]). It owns the shelf when it may publish; a session that
 * may not (a PIN-protected profile while the app asks for a profile on open: anyone at the TV sees the shelf) clears the
 * shelf instead, also of what an earlier launch left there. Each change of owner raises the generation, so a sync made
 * for an earlier owner is dropped here and, if already handed over, ignored by the home screen. Ending the session
 * ([endProfileSession]: a profile switch, sign-out, removal) clears the shelf at once. A sync ([sync]) publishes at most
 * [HOME_SCREEN_LIMIT] items whose server has a client; anything else is a no-op. Without a [homeScreen] (phones,
 * tablets, desktops, Fire TV) nothing happens. Main thread only.
 *
 * @param now the clock for an item never watched (its engagement time).
 */
class SystemShelf(private val homeScreen: HomeScreen?, private val now: () -> Long) {
    private var session: String? = null
    private var owner: String? = null
    private var generation = 0L

    /** The profile whose session is open, publishing or not; null for none. */
    val sessionProfile: String? get() = session

    /**
     * Opens [profileId]'s session, or applies [mayPublish] again to the one open. When it may publish it becomes the only
     * owner allowed to; when it may not, the shelf clears.
     */
    fun beginProfileSession(profileId: String, mayPublish: Boolean) {
        require(profileId.isNotEmpty()) { "A shelf owner needs a profile id" }
        if (session == profileId && (owner == profileId) == mayPublish) return
        session = profileId
        if (mayPublish) {
            owner = profileId
            generation++
        } else {
            clear()
        }
    }

    /** Ends [profileId]'s session and clears its shelf; nothing when its session isn't open. */
    fun endProfileSession(profileId: String) {
        if (session != profileId) return
        session = null
        // A session that couldn't publish cleared the shelf when it opened or lost the right.
        if (owner == profileId) clear()
    }

    private fun clear() {
        owner = null
        generation++
        homeScreen?.publish(HomeScreenShelf(null, generation, T.discover.continueWatching, emptyList()))
    }

    /**
     * Publishes [continueWatching] (newest first) as [profileId]'s shelf; false when there is no home screen or the
     * profile doesn't own the shelf. [clientFor] gives each item's server, whose image URL the poster comes from; an
     * item whose server has no client is left out, one whose artwork can't be made goes without a poster.
     */
    fun sync(
        profileId: String,
        continueWatching: List<MediaItem>,
        clientFor: (ServerId) -> MediaBackend?,
        hideSpoilers: Boolean,
        episodePosterMode: EpisodePosterMode,
    ): Boolean {
        val homeScreen = homeScreen ?: return false
        if (owner != profileId) return false
        val items = continueWatching.asSequence()
            .mapNotNull { item -> ServerId.tryParse(item.serverId)?.let(clientFor)?.let { item.toShelfItem(it, homeScreen.artwork, hideSpoilers, episodePosterMode) } }
            .take(HOME_SCREEN_LIMIT)
            .toList()
        homeScreen.publish(HomeScreenShelf(profileId, generation, T.discover.continueWatching, items))
        return true
    }

    private fun MediaItem.toShelfItem(
        client: MediaBackend,
        artwork: HomeScreenArtwork,
        hideSpoilers: Boolean,
        episodePosterMode: EpisodePosterMode,
    ): HomeScreenItem {
        val showEpisode = kind == MediaKind.EPISODE && grandparentTitle != null
        return HomeScreenItem(
            contentId = ShelfContentId.build(client.serverId, id),
            kind = kind,
            title = if (showEpisode) grandparentTitle!! else title.orEmpty(),
            episodeTitle = if (showEpisode) title else null,
            description = summary,
            posterSource = posterSource(client, artwork, hideSpoilers, episodePosterMode),
            durationMillis = durationMs ?: 0,
            positionMillis = viewOffsetMs ?: 0,
            lastEngagedMillis = lastViewedAt?.let { it * 1000 } ?: now(),
            seriesTitle = grandparentTitle,
            seasonNumber = parentIndex,
            episodeNumber = index,
        )
    }

    /**
     * The poster's URL on its server. The Top Shelf fills 2:3 poster slots: the series poster for an episode, the
     * season's only under that episode poster setting, and posters can't spoil. Watch Next draws 16:9: an episode's
     * thumbnail, or the spoiler-safe art for an unwatched episode under Hide Spoilers.
     */
    private fun MediaItem.posterSource(
        client: MediaBackend,
        artwork: HomeScreenArtwork,
        hideSpoilers: Boolean,
        episodePosterMode: EpisodePosterMode,
    ): String? = try {
        when (artwork) {
            HomeScreenArtwork.POSTER -> {
                val mode = if (episodePosterMode == EpisodePosterMode.SEASON_POSTER) EpisodePosterMode.SEASON_POSTER else EpisodePosterMode.SERIES_POSTER
                posterThumb(mode)?.let { client.thumbnailUrl(it, width = 600, height = 900) }
            }
            HomeScreenArtwork.LANDSCAPE -> {
                val path = (if (hideSpoilers && shouldHideSpoiler) spoilerSafeArt else null)
                    ?: posterThumb(EpisodePosterMode.EPISODE_THUMBNAIL, mixedHubContext = true)
                path?.let { client.thumbnailUrl(it, width = 640, height = 360) }
            }
        }
    } catch (e: RuntimeException) {
        Log.w(TAG, e) { "Preparing the home screen artwork failed" }
        null
    }

    private companion object {
        const val TAG = "SystemShelf"
    }
}
