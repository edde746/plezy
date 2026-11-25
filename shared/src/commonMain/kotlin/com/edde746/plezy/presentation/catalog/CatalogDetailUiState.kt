package com.edde746.plezy.presentation.catalog

import com.edde746.plezy.catalog.CatalogCastMember
import com.edde746.plezy.catalog.CatalogItem
import com.edde746.plezy.catalog.CatalogSourceId
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaRatingSource
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.seerr.SeerrBlock
import com.edde746.plezy.strings.T

/**
 * A catalog item's detail screen, top to bottom. Every optional section is null or empty when it has nothing to show,
 * and then shows no header either.
 *
 * @param item the item as currently known: the opening item, replaced by its source's enriched detail once loaded. The
 *   UIs take its artwork from it ([CatalogItem.posterFor], [CatalogItem.backdropFor]) at their rendered size.
 * @param tagline shown above the title, in italics.
 * @param metaLine `year • runtime • certification`; null when none is known.
 * @param genres the genres joined with ` • `.
 * @param watchlist the watchlist toggle; null when no watchlist applies to the item.
 * @param request the Seerr Request action; null unless a Seerr account is connected, may request this kind, and the
 *   item has a TMDB id. It follows permission changes and a disconnect while open. A title Seerr has, or that is
 *   already requested, shows that state ([CatalogRequestAction.blocked]) instead, disabled.
 * @param hasTrailer the Watch trailer action: a library copy's trailer, else the provider's trailer this device opens.
 * @param settled the detail load has ended, loaded or failed (at once without a source to load from), and so has
 *   Seerr's answer on the request's state: the headline's lines and actions are final from then on.
 * @param stats the compact chips under the header, in order: score, air status, episodes, unaired episodes, network,
 *   broadcast season, format, source material, adult, added date, ranks, audience counts, Seerr availability, request
 *   state and seasons.
 * @param background production prose (MyAnimeList), its own section under the overview.
 * @param facts the definition rows (original title, also known as, studios, country, language, released, on disc,
 *   ended, your rating, budget, box office, age guidance).
 * @param recommenders who recommended or favorited the title, with their note.
 * @param ratings the provider's attributed scores; [communityRatings] are the connected trackers' scores for the
 *   title as they arrive, merged into the same Ratings section.
 * @param schedule the broadcast slot and the next episode's countdown.
 * @param crew one row per credit role.
 * @param tags the tag section; null without tags.
 * @param watchOnLinks the "Watch on" outbound links; [links] the other ones. Both empty on a device without a browser.
 * @param library the library availability section.
 * @param castTitle "Characters" for anime providers, else "Cast"; [cast] empty until the detail load brings it.
 * @param relations franchise relations, one entry per title.
 * @param related "More like this".
 * @param message a snackbar to show once, then [CatalogDetailStore.messageShown].
 */
data class CatalogDetailUiState(
    val item: CatalogItem,
    val tagline: String?,
    val title: String,
    val metaLine: String?,
    val genres: String?,
    val watchlist: CatalogWatchlistAction?,
    val request: CatalogRequestAction?,
    val hasTrailer: Boolean,
    val settled: Boolean,
    val stats: List<String>,
    val overview: String?,
    val background: String?,
    val facts: List<CatalogDetailFact>,
    val recommenders: List<CatalogDetailRecommender>,
    val ratings: List<MediaRatingSource>,
    val communityRatings: List<MediaRatingSource>,
    val schedule: List<String>,
    val crew: List<CatalogDetailFact>,
    val tags: CatalogDetailTags?,
    val watchOnLinks: List<CatalogDetailLink>,
    val links: List<CatalogDetailLink>,
    val library: CatalogLibrarySection,
    val castTitle: String,
    val cast: List<CatalogCastMember>,
    val relations: List<CatalogRelationEntry>,
    val related: List<CatalogItem>,
    val message: String?,
) {
    /**
     * The action bar shows when any action does, once the detail has [settled]: the lines the detail adds above it would
     * move it under a press that aimed at it.
     */
    val hasActions: Boolean get() = settled && (watchlist != null || request != null || hasTrailer)

    /**
     * The person page the cast member at [index] opens: on a Seerr title, a member Seerr gave a person id opens their
     * Seerr page; null for any other (the UIs draw it without a press).
     */
    fun personRoute(index: Int): Route.SeerrPerson? {
        if (item.source != CatalogSourceId.SEERR) return null
        val member = cast.getOrNull(index) ?: return null
        return member.personId?.let { Route.SeerrPerson(it, member.name, member.imageUrl) }
    }
}

/**
 * The watchlist toggle. It stays focusable while [onWatchlist] is unknown (null): a press then loads the membership
 * instead of toggling.
 *
 * @param label the tooltip: Add to or Remove from Watchlist.
 */
data class CatalogWatchlistAction(val onWatchlist: Boolean?, val label: String)

/**
 * What the Seerr request sheet opens for. [blocked] says why the title can't be requested ("Available", "Requested"):
 * the action then shows that [label], disabled; else it reads Request.
 */
data class CatalogRequestAction(val tmdbId: Int, val title: String, val blocked: SeerrBlock? = null) {
    val label: String get() = blocked?.label ?: T.seerr.request
    val enabled: Boolean get() = blocked == null

    /**
     * The action as it can show while its page is open: as Request, as what sending a request turns it into
     * (Requested, Processing, Available), and as it is now. The UIs give it the widest one's width, so the actions
     * beside it stay put when Request turns into Requested.
     */
    val states: List<CatalogRequestAction>
        get() = (listOf(null) + REQUEST_OUTCOMES + blocked).distinct().map { copy(blocked = it) }

    private companion object {
        val REQUEST_OUTCOMES = listOf(SeerrBlock.REQUESTED, SeerrBlock.PROCESSING, SeerrBlock.AVAILABLE)
    }
}

data class CatalogDetailFact(val label: String, val value: String)

/** "Recommended by Pat" or "Favorited by Pat", with the note they left. */
data class CatalogDetailRecommender(val text: String, val note: String?)

/**
 * Tags by community relevance, highest first.
 *
 * @param visible the tags shown: spoilers only once revealed.
 * @param canRevealSpoilers a hidden spoiler tag exists; the "Show spoiler tags" action shows.
 */
data class CatalogDetailTags(val visible: List<String>, val canRevealSpoilers: Boolean)

/** An outbound link: [label] is "Open on <site>". */
data class CatalogDetailLink(val label: String, val url: String)

/** One franchise relation: [label] says how it relates ("Sequel"), [text] is `title • year`. */
data class CatalogRelationEntry(val label: String, val text: String, val item: CatalogItem)

/** Library availability, resolved in place. */
sealed interface CatalogLibrarySection {
    /** The lookup runs and nothing was found yet. */
    data object Checking : CatalogLibrarySection

    /** Every server answered and none has it. */
    data object NotInLibrary : CatalogLibrarySection

    /**
     * Every server answered and none of the profile's libraries has it, but Seerr has it on its server: the Request's
     * Available status ([CatalogRequestAction]) already says so, so the section shows nothing (no "Not in your library").
     */
    data object SaidByStatus : CatalogLibrarySection

    /** Nothing was found, but [text] ("Couldn't check 2 servers") servers never answered. */
    data class Unchecked(val text: String) : CatalogLibrarySection

    /**
     * "In these libraries": every copy, best quality first. [uncheckedNote] says how many servers sat the lookup out.
     */
    data class Copies(val copies: List<CatalogLibraryCopy>, val uncheckedNote: String?) : CatalogLibrarySection
}

/**
 * One library copy.
 *
 * @param key the copy's stable identity ([MediaItem.globalKey]): a later lookup can add or re-sort copies, and focus
 *   stays on the copy it was on.
 * @param title the library title, else the server name, else the server software's name.
 * @param subtitle the copy's quality and, under a library title, its server name, joined with ` • `.
 * @param libraryKind the kind of the library the copy sits in (its icon), else, where that library isn't known, the
 *   copy's own kind.
 */
data class CatalogLibraryCopy(
    val key: String,
    val item: MediaItem,
    val backend: BackendKind,
    val title: String,
    val subtitle: String?,
    val libraryKind: MediaKind,
)
