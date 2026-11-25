package com.edde746.plezy.trackers

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.model.MediaItem
import kotlinx.coroutines.flow.first

/** A connected tracker the user rates a title at, with the account it is signed in as. */
class RatingAccount internal constructor(val service: TrackerService, val username: String?, internal val tracker: Rating)

/**
 * The user's own scores of media items at the profile's connected trackers, for the rating sheet. Scores are 1–10;
 * writes go straight to the service (not queued).
 */
class UserRatings internal constructor(
    private val accounts: TrackerAccounts,
    private val resolvers: TrackerIdResolverFactory,
) {
    /**
     * The trackers the profile can rate at right now, in the sheet's order: Trakt, MyAnimeList, AniList, Simkl,
     * MDBList, and what rating [item] of [backend] (`null`: its server is offline) means there.
     */
    suspend fun open(profileId: String, item: MediaItem, backend: MediaBackend?): ItemRatings {
        val connected = accounts.bound(profileId).first()
            .mapNotNull { bound -> (bound.tracker as? Rating)?.let { RatingAccount(bound.service, bound.account.username, it) } }
            .sortedBy { SHEET_ORDER.indexOf(it.service) }
        val resolver = backend?.let { resolvers.create(it) { connected.any { account -> account.tracker.needsAnimeIds } } }
        return ItemRatings(connected, item, resolver)
    }

    private companion object {
        val SHEET_ORDER = listOf(
            TrackerService.TRAKT,
            TrackerService.MYANIMELIST,
            TrackerService.ANILIST,
            TrackerService.SIMKL,
            TrackerService.MDBLIST,
        )
    }
}

/** One media item's scores at [accounts]. [close] when done with it. */
class ItemRatings internal constructor(
    val accounts: List<RatingAccount>,
    private val item: MediaItem,
    private val resolver: TrackerIdResolver?,
) {
    /**
     * What rating the item means at the trackers (resolved by the media server's ids and, while MyAnimeList or AniList
     * is connected, the anime mapping; kept by the resolver), or `null` when no tracker could name it or its server is
     * offline. Throws the server's or the mapping's failure.
     */
    suspend fun target(): RatingTarget? = resolver?.resolveForRating(item)

    /**
     * [account]'s score of [target], or `null` for none.
     *
     * @throws TrackerException.Unsupported when that service can't rate it (no id it takes, a kind it doesn't rate).
     */
    suspend fun score(account: RatingAccount, target: RatingTarget): Int? = account.tracker.rating(target)

    /**
     * Sets [account]'s score of [target] to [score] (1–10); `0` or less removes it.
     *
     * @throws TrackerException.Unsupported when that service can't rate it.
     */
    suspend fun rate(account: RatingAccount, target: RatingTarget, score: Int) {
        if (score <= 0) account.tracker.clearRating(target) else account.tracker.rate(target, score)
    }

    fun close() {
        resolver?.clearCache()
    }
}
