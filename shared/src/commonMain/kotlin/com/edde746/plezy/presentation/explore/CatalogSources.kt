package com.edde746.plezy.presentation.explore

import com.edde746.plezy.catalog.CatalogItem
import com.edde746.plezy.catalog.CatalogSource
import com.edde746.plezy.catalog.CatalogSourceId
import com.edde746.plezy.catalog.catalogEnumOf
import com.edde746.plezy.catalog.matching.LibraryWatchlistCandidates
import com.edde746.plezy.log.Log
import com.edde746.plezy.plex.tv.PlexDiscoverSession
import com.edde746.plezy.profiles.profileUserScope
import com.edde746.plezy.seerr.SeerrClient
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.settings.ProfileSettings
import com.edde746.plezy.settings.ProfileSettingsRepository
import com.edde746.plezy.trackers.TrackerBinding
import com.edde746.plezy.trackers.TrackerService
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/**
 * The profile's connected catalog sources and the one the Explore tab shows.
 *
 * @param connected every bound source, in [CatalogSourceId.listingOrder].
 * @param preferred the profile's stored pick ([ProfileSettings.catalogActiveSource]); null for the first connected.
 * @param seerr the connected Seerr source, for the request surfaces that need Seerr beyond [CatalogSource].
 */
data class CatalogSourcesState(
    val connected: List<CatalogSource> = emptyList(),
    val preferred: CatalogSourceId? = null,
    val seerr: CatalogSource? = null,
) {
    /** Explore is offered only while some source is connected. */
    val hasAnySource: Boolean get() = connected.isNotEmpty()

    /** The source Explore shows: the stored pick while it is still connected, otherwise the first connected source. */
    val active: CatalogSource? get() = connected.firstOrNull { it.id == preferred } ?: connected.firstOrNull()

    /** The first source whose watchlist can be read and changed; independent of [active]. */
    val watchlistCapableSource: CatalogSource? get() = connected.firstOrNull { it.supportsWatchlist }

    /** Every connected source whose watchlist can be read and changed, for surfaces that offer a choice. */
    val watchlistCapableSources: List<CatalogSource> get() = connected.filter { it.supportsWatchlist }

    /**
     * The watchlist a catalog item's surfaces bind to: its own source's, never another provider's. An item whose
     * source is connected but has no watchlist (Seerr) gets none; [watchlistCapableSource] stands in only when the
     * item's own source is no longer connected.
     */
    fun watchlistSourceFor(item: CatalogItem): CatalogSource? {
        val own = connected.firstOrNull { it.id == item.source } ?: return watchlistCapableSource
        return own.takeIf { it.supportsWatchlist }
    }
}

/**
 * Binds one catalog source per connected account and owns which one Explore shows ([CatalogSourcesState]).
 *
 * A source is rebuilt only when its client changes: a tracker's when its [TrackerBinding] instance changes, Seerr's
 * when its [SeerrClient] instance changes, Plex's when the [PlexDiscoverSession] value changes. The replaced source is
 * disposed (which never disposes a borrowed tracker or Seerr client).
 *
 * The Plex session is read with the active profile ([onActiveProfileChanged]) and again when a same-profile server
 * binding finishes ([onProfileBindingStateChanged]). A failed read on a profile change drops the Plex source; on a
 * refresh it keeps the one bound. A read that a later profile change or refresh overtook is discarded.
 *
 * Call everything on the main thread; [release] ends it.
 *
 * @param trackerBindings the active profile's connected tracker accounts.
 * @param seerrClient the active profile's Seerr client; null while Seerr is not connected.
 * @param plexSession the active profile's Plex Discover session (its Home user's token, else the account token, with
 *   the account's client identifier); null or unusable when the profile has no Plex identity.
 * @param isTv whether this is a TV build: its Plex source asks for hub artwork variants for the spotlight.
 * @param trackerSource builds a tracker's source around its account's binding.
 * @param plexSource builds the Plex source; the second argument is `includeImageVariants`.
 * @param seerrSource builds the Seerr source around the connection's client.
 */
class CatalogSources internal constructor(
    trackerBindings: Flow<List<TrackerBinding>>,
    seerrClient: Flow<SeerrClient?>,
    private val plexSession: suspend () -> PlexDiscoverSession?,
    private val settings: ProfileSettingsRepository,
    private val isTv: Boolean,
    private val trackerSource: (TrackerBinding) -> CatalogSource,
    private val plexSource: (PlexDiscoverSession, Boolean) -> CatalogSource,
    private val seerrSource: (SeerrClient) -> CatalogSource,
    parentScope: CoroutineScope,
) {
    private val scope = parentScope.childScope()

    /** One client/source pair: [update] rebuilds the source when [same] says the client changed. */
    private class Binding<C : Any>(private val same: (C, C) -> Boolean, private val create: (C) -> CatalogSource) {
        private var client: C? = null
        var source: CatalogSource? = null
            private set

        /** True when the source was replaced or removed. */
        fun update(next: C?): Boolean {
            val current = client
            if (current == null && next == null) return false
            if (current != null && next != null && same(current, next)) return false
            val replacement = next?.let(create)
            source?.dispose()
            client = next
            source = replacement
            return true
        }

        fun dispose() {
            source?.dispose()
            source = null
            client = null
        }
    }

    private val trackers: Map<TrackerService, Binding<TrackerBinding>> = TrackerService.entries.associateWith {
        Binding<TrackerBinding>({ a, b -> a === b }, trackerSource)
    }
    private val plex = Binding<PlexDiscoverSession>({ a, b -> a == b }) { session -> plexSource(session, isTv) }
    private val seerr = Binding<SeerrClient>({ a, b -> a === b }, seerrSource)

    private var profileGeneration = 0
    private var plexGeneration = 0
    private var lastBinding: Boolean? = null
    private var profileScope = ""
    private var preferred: CatalogSourceId? = null
    private var released = false

    private val mutableState = MutableStateFlow(CatalogSourcesState())

    val state: StateFlow<CatalogSourcesState> = mutableState.asStateFlow()

    /**
     * The watchlist sources each library item can go on, resolved once per session from the connected sources and
     * forgotten on every rebind. Catalog-card menus mutate through it too, so they share its in-flight guard.
     */
    val watchlistCandidates = LibraryWatchlistCandidates { mutableState.value.connected }

    init {
        scope.launch {
            trackerBindings.collect { bindings ->
                val byService = bindings.associateBy { it.service }
                var changed = false
                for ((service, binding) in trackers) changed = binding.update(byService[service]) || changed
                if (changed) rebound()
            }
        }
        scope.launch {
            seerrClient.collect { client -> if (seerr.update(client)) rebound() }
        }
    }

    /** Reads the profile's stored pick and its Plex session; [profileId] is null without an active profile. */
    suspend fun onActiveProfileChanged(profileId: String?) {
        val generation = ++profileGeneration
        val scopeKey = profileId?.let(::profileUserScope).orEmpty()
        profileScope = scopeKey
        val stored = settings.value(scopeKey, ProfileSettings.catalogActiveSource)
        if (released || generation != profileGeneration) return
        preferred = catalogEnumOf<CatalogSourceId>(stored)
        publish()
        refreshPlexSession(generation, clearOnFailure = true)
    }

    /**
     * The active profile's server binding started ([binding] true) or finished: a finished binding (connections added
     * or removed under the same profile) reads the Plex session again.
     */
    suspend fun onProfileBindingStateChanged(binding: Boolean) {
        val previous = lastBinding
        lastBinding = binding
        if (binding && previous != true) plexGeneration++
        if (previous == true && !binding) refreshPlexSession(profileGeneration, clearOnFailure = false)
    }

    /** Stores [id] as the profile's Explore source; null clears the pick, back to the first connected source. */
    suspend fun setActiveSource(id: CatalogSourceId?) {
        if (id != null && preferred == id) return
        val generation = profileGeneration
        settings.set(profileScope, ProfileSettings.catalogActiveSource, id?.id)
        if (released || generation != profileGeneration) return
        preferred = id
        publish()
    }

    fun release() {
        released = true
        scope.cancel()
        trackers.values.forEach { it.dispose() }
        plex.dispose()
        seerr.dispose()
        watchlistCandidates.invalidate()
    }

    private suspend fun refreshPlexSession(generation: Int, clearOnFailure: Boolean) {
        val sessionGeneration = ++plexGeneration
        val session = try {
            plexSession()
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Plex Discover session read failed" }
            if (clearOnFailure && isCurrent(generation, sessionGeneration) && plex.update(null)) rebound()
            return
        }
        if (!isCurrent(generation, sessionGeneration)) return
        if (plex.update(session?.takeIf { it.isUsable })) rebound()
    }

    private fun isCurrent(generation: Int, sessionGeneration: Int) =
        !released && generation == profileGeneration && sessionGeneration == plexGeneration

    private fun rebound() {
        watchlistCandidates.invalidate()
        publish()
    }

    private fun publish() {
        val bound = buildMap {
            for ((service, binding) in trackers) binding.source?.let { put(service.catalogSourceId, it) }
            plex.source?.let { put(CatalogSourceId.PLEX, it) }
            seerr.source?.let { put(CatalogSourceId.SEERR, it) }
        }
        mutableState.value = CatalogSourcesState(
            connected = CatalogSourceId.listingOrder.mapNotNull { bound[it] },
            preferred = preferred,
            seerr = seerr.source,
        )
    }

    private companion object {
        const val TAG = "CatalogSources"
    }
}

/** The catalog source a tracker's account backs. */
internal val TrackerService.catalogSourceId: CatalogSourceId
    get() = when (this) {
        TrackerService.TRAKT -> CatalogSourceId.TRAKT
        TrackerService.SIMKL -> CatalogSourceId.SIMKL
        TrackerService.MDBLIST -> CatalogSourceId.MDBLIST
        TrackerService.MYANIMELIST -> CatalogSourceId.MAL
        TrackerService.ANILIST -> CatalogSourceId.ANILIST
    }
