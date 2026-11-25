package com.edde746.plezy.presentation.seerr

import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.localizedErrorReason
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.seerr.SeerrClient
import com.edde746.plezy.seerr.SeerrException
import com.edde746.plezy.seerr.SeerrMediaInfo
import com.edde746.plezy.seerr.SeerrPermission
import com.edde746.plezy.seerr.SeerrPublicSettings
import com.edde746.plezy.seerr.SeerrRequestPayload
import com.edde746.plezy.seerr.SeerrSeason
import com.edde746.plezy.seerr.SeerrServiceDetail
import com.edde746.plezy.seerr.SeerrServiceInstance
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.strings.T
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.async
import kotlinx.coroutines.cancel
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/**
 * The Seerr request sheet of one title, as the Seerr web UI requests: per-season choice with each season's
 * availability, a 4K switch and the advanced destination pickers, each gated by the instance's settings and the user's
 * permissions as Seerr checks them.
 *
 * - It loads the public settings and, with the advanced permission, the Radarr/Sonarr instances together, then the
 *   title's availability; a failed load offers Retry.
 * - Picking a destination server resets the profile, folder and language to its defaults and loads its options; only
 *   the newest pick's options are taken, filling what is still unset (an anime series takes the anime defaults).
 * - The permission mask is followed live: losing the advanced permission drops the destination, gaining it loads the
 *   servers, losing 4K turns the switch off, and losing the request permission closes the sheet (after a submission in
 *   flight settles) as [SeerrRequestCloseReason.PERMISSION_REVOKED].
 * - The sheet belongs to the account [client] was bound to: once the account is replaced or disconnected it closes
 *   silently and ignores what is still in flight.
 *
 * Call everything on the main thread; [release] ends it.
 *
 * @param connectedClient the account's current client; null when disconnected.
 * @param permissions the account's permission mask, a signal to look again at [client]'s live session.
 * @param onSubmitted told once a request went through, so the screens showing the title look at its state again.
 */
class SeerrRequestStore internal constructor(
    private val tmdbId: Int,
    private val kind: MediaKind,
    private val title: String,
    private val client: SeerrClient,
    connectedClient: Flow<SeerrClient?>,
    permissions: Flow<Int?>,
    parentScope: CoroutineScope,
    private val onSubmitted: () -> Unit,
) {
    private val scope = parentScope.childScope()
    private val movie = kind == MediaKind.MOVIE

    private var loading = true
    private var loadFailed = false
    private var loadJob: Job? = null

    private var settings: SeerrPublicSettings? = null
    private var mediaInfo: SeerrMediaInfo? = null

    /** A show's requestable seasons: specials and seasons without episodes are left out. */
    private var seasons: List<SeerrSeason> = emptyList()
    private val selectedSeasons = mutableSetOf<Int>()
    private var is4k = false

    /** The show carries the TMDB anime keyword: Seerr routes it to the Sonarr instance's anime defaults. */
    private var isAnime = false

    private var allServers: List<SeerrServiceInstance> = emptyList()
    private var server: SeerrServiceInstance? = null
    private var serverDetail: SeerrServiceDetail? = null
    private var serverDetailLoading = false

    /**
     * Bumped by every destination pick (none and the 4K round trip included); an options load for an older pick is
     * dropped, so A→B→A can't take the first A answer over the second's.
     */
    private var serverSelectionGeneration = 0
    private var profileId: Int? = null
    private var rootFolder: String? = null
    private var languageProfileId: Int? = null

    /** Null until the server's options report its default tags; null leaves the tags to Seerr's defaults. */
    private var tags: List<Int>? = null
    private var tagsExpanded = false

    private var submitting = false
    private var errorText: String? = null

    private var connected = true

    /** The mask the sheet was last reconciled with, so a grant or loss while open applies as a transition. */
    private var reconciledPermissions: Int? = livePermissions
    private var authorityGeneration = 0
    private var serverListGeneration = 0

    private var closed: SeerrRequestClosed? = null
    private var refocus: SeerrRequestRefocus? = null
    private var refocusRequests = 0

    /** Whether the published form showed the 4K switch and the advanced section, for [refocus]. */
    private var shown4k = false
    private var shownAdvanced = false

    private val mutableState = MutableStateFlow(build())

    val state: StateFlow<SeerrRequestUiState> = mutableState.asStateFlow()

    init {
        load()
        scope.launch {
            connectedClient.collect { current ->
                connected = current === client
                reconcile()
            }
        }
        scope.launch { permissions.collect { reconcile() } }
    }

    /** Loads again after [SeerrRequestBody.LoadFailed]. */
    fun retry() {
        if (closed == null) load()
    }

    fun setSeasonSelected(seasonNumber: Int, selected: Boolean) {
        if (!editable || seasonBlocked(seasonNumber)) return
        if (selected) selectedSeasons += seasonNumber else selectedSeasons -= seasonNumber
        publish()
    }

    /** "All seasons": selects every requestable season, or clears the choice. */
    fun setAllSeasons(selected: Boolean) {
        if (!editable) return
        if (selected) selectedSeasons += requestableSeasons else selectedSeasons.clear()
        publish()
    }

    /** The 4K switch: deselects seasons blocked in the new variant and picks that variant's default server. */
    fun set4k(on: Boolean) {
        if (!editable || (on && !can4k)) return
        toggle4k(on)
        publish()
    }

    /** Picks [optionId] of the [kind] picker (a server, profile or language profile id, a root folder's id). */
    fun select(kind: SeerrPickerKind, optionId: Int) {
        if (!editable || !advancedAllowed) return
        val detail = serverDetail
        when (kind) {
            SeerrPickerKind.SERVER -> adoptServer(serversForVariant.firstOrNull { it.id == optionId } ?: return)
            SeerrPickerKind.QUALITY_PROFILE -> profileId = detail?.profiles?.firstOrNull { it.id == optionId }?.id ?: return
            SeerrPickerKind.ROOT_FOLDER -> rootFolder = detail?.rootFolders?.firstOrNull { it.id == optionId }?.path ?: return
            SeerrPickerKind.LANGUAGE_PROFILE ->
                languageProfileId = detail?.languageProfiles?.firstOrNull { it.id == optionId }?.id ?: return
        }
        publish()
    }

    fun toggleTagsExpanded() {
        if (!editable) return
        tagsExpanded = !tagsExpanded
        publish()
    }

    /** Checks or unchecks a tag; the chosen tags keep the arr's order. */
    fun setTagSelected(tagId: Int, selected: Boolean) {
        if (!editable || !advancedAllowed) return
        val options = serverDetail?.tags ?: return
        val chosen = tags.orEmpty().toMutableSet()
        if (selected) chosen += tagId else chosen -= tagId
        tags = options.map { it.id }.filter { it in chosen }
        publish()
    }

    /**
     * Sends the request. A permission the mask no longer grants fails here without a round trip. Success closes the
     * sheet ([SeerrRequestCloseReason.SUBMITTED]); a refusal stays inline and the sheet stays usable.
     */
    fun submit() {
        if (!canSubmit) return
        if (!canRequest || (is4k && !can4k)) {
            errorText = T.seerr.permissionRevoked
            reconcile()
            return
        }
        submitting = true
        errorText = null
        publish()
        val payload = payload()
        scope.launch {
            val error = try {
                client.createRequest(payload)
                onSubmitted()
                close(if (connected) SeerrRequestCloseReason.SUBMITTED else SeerrRequestCloseReason.SILENT)
                return@launch
            } catch (e: CancellationException) {
                throw e
            } catch (e: SeerrException.Api) {
                e.message
            } catch (e: SeerrException.Permission) {
                // The client took the probe's mask before throwing: the reconcile below closes or trims the sheet.
                e.display
            } catch (e: SeerrException.Proxy) {
                e.display
            } catch (e: Exception) {
                Log.w(TAG, e) { "request submit failed" }
                T.seerr.requestFailed((e as? SeerrException)?.display ?: localizedErrorReason(MediaServerHttpException.from(e)))
            }
            submitting = false
            errorText = error
            reconcile()
        }
    }

    fun release() {
        scope.cancel()
    }

    // ---- Load ----

    private fun load() {
        loadJob?.cancel()
        loading = true
        loadFailed = false
        val authority = authorityGeneration
        val serverList = ++serverListGeneration
        reconciledPermissions = livePermissions
        publish()
        loadJob = scope.launch {
            try {
                val (loadedSettings, servers) = coroutineScope {
                    val settingsLoad = async { client.getPublicSettings() }
                    val serversLoad = async { if (advancedAllowed) serverList() else emptyList() }
                    settingsLoad.await() to serversLoad.await()
                }
                if (!connected) return@launch
                val details = if (movie) client.getMovie(tmdbId) else client.getTv(tmdbId)
                if (!connected) return@launch
                settings = loadedSettings
                mediaInfo = details.mediaInfo
                if (!movie) {
                    seasons = details.seasons.orEmpty().filter { it.requestable }
                    isAnime = details.isAnime
                }
                val current = authority == authorityGeneration && serverList == serverListGeneration
                allServers = if (current && advancedAllowed) servers else emptyList()
                loading = false
                selectDefaultServer()
                if (advancedAllowed && !current) loadServers()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "request sheet load failed for tmdb $tmdbId" }
                if (!connected) return@launch
                loading = false
                loadFailed = true
            }
            reconcile()
        }
    }

    private suspend fun serverList(): List<SeerrServiceInstance> = if (movie) client.getRadarrServices() else client.getSonarrServices()

    /** The servers alone, for an advanced grant that came after [load] skipped them; a failure keeps the defaults. */
    private fun loadServers() {
        val generation = ++serverListGeneration
        scope.launch {
            val servers = try {
                serverList()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "service list load failed" }
                return@launch
            }
            if (!connected || !advancedAllowed || generation != serverListGeneration) return@launch
            allServers = servers
            selectDefaultServer()
            publish()
        }
    }

    private fun selectDefaultServer() {
        val candidates = serversForVariant
        adoptServer(candidates.firstOrNull { it.isDefault } ?: candidates.firstOrNull())
    }

    private fun adoptServer(next: SeerrServiceInstance?) {
        val generation = ++serverSelectionGeneration
        val loadsDetail = next != null && advancedAllowed
        server = next
        serverDetail = null
        serverDetailLoading = loadsDetail
        profileId = defaultProfileId(next)
        rootFolder = defaultRootFolder(next)
        languageProfileId = defaultLanguageProfileId(next)
        // The list route reports no usable tags: the options load does.
        tags = null
        if (next != null && loadsDetail) loadServerDetail(next, generation)
    }

    private fun loadServerDetail(target: SeerrServiceInstance, generation: Int) {
        scope.launch {
            val detail = try {
                if (movie) client.getRadarrService(target.id) else client.getSonarrService(target.id)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                // The pickers fall back to the server's defaults; the request still works.
                Log.w(TAG, e) { "service detail load failed" }
                if (connected && generation == serverSelectionGeneration) {
                    serverDetailLoading = false
                    publish()
                }
                return@launch
            }
            if (!connected || !advancedAllowed || generation != serverSelectionGeneration) return@launch
            // Once per accepted pick: fill only what the list left unset; `activeTags: []` is a real "no tags".
            serverDetail = detail
            serverDetailLoading = false
            profileId = profileId ?: defaultProfileId(detail.server)
            rootFolder = rootFolder ?: defaultRootFolder(detail.server)
            languageProfileId = languageProfileId ?: defaultLanguageProfileId(detail.server)
            if (detail.tags != null) tags = defaultTags(detail.server).orEmpty()
            publish()
        }
    }

    private fun toggle4k(on: Boolean) {
        is4k = on
        selectedSeasons.removeAll { seasonBlocked(it) }
        selectDefaultServer()
    }

    // ---- Authority ----

    /**
     * Applies the live permission mask as a transition, even during a load or submission, so a late server list can't
     * outlive a loss and regrant; only the close for a lost request permission waits for a submission to settle.
     */
    private fun reconcile() {
        if (closed != null) return
        if (!connected) {
            close(SeerrRequestCloseReason.SILENT)
            return
        }
        val current = livePermissions
        val previous = reconciledPermissions
        reconciledPermissions = current
        if (previous != current) {
            authorityGeneration++
            val hadAdvanced = previous != null && SeerrPermission.has(previous, SeerrPermission.REQUEST_ADVANCED)
            if (hadAdvanced != advancedAllowed) serverListGeneration++
            if (!advancedAllowed && hadAdvanced) {
                allServers = emptyList()
                tagsExpanded = false
                adoptServer(null)
            } else if (advancedAllowed && !hadAdvanced && !loading && !loadFailed) {
                loadServers()
            }
            if (is4k && !can4k) toggle4k(false)
            val vanished = (shownAdvanced && !advancedAllowed) || (shown4k && !can4k)
            if (vanished && canRequest) {
                refocus = SeerrRequestRefocus(
                    if (canSubmit) SeerrRequestFocusTarget.SUBMIT else SeerrRequestFocusTarget.FIRST_SEASON,
                    ++refocusRequests,
                )
            }
        }
        if (!submitting && !canRequest) {
            close(SeerrRequestCloseReason.PERMISSION_REVOKED)
            return
        }
        publish()
    }

    private fun close(reason: SeerrRequestCloseReason) {
        if (closed != null) return
        closed = when (reason) {
            SeerrRequestCloseReason.SUBMITTED -> SeerrRequestClosed(reason, T.seerr.requestSubmitted, isError = false)
            SeerrRequestCloseReason.PERMISSION_REVOKED -> SeerrRequestClosed(reason, T.seerr.permissionRevoked, isError = true)
            SeerrRequestCloseReason.SILENT -> SeerrRequestClosed(reason, null, isError = false)
        }
        loadJob?.cancel()
        publish()
    }

    private val livePermissions: Int get() = client.session.permissions

    private val canRequest: Boolean get() = SeerrPermission.canRequest(livePermissions, movie)

    private val advancedAllowed: Boolean get() = SeerrPermission.has(livePermissions, SeerrPermission.REQUEST_ADVANCED)

    private val can4k: Boolean
        get() {
            val settings = settings ?: return false
            val enabled = if (movie) settings.movie4kEnabled else settings.series4kEnabled
            return enabled && SeerrPermission.has(
                livePermissions,
                SeerrPermission.REQUEST_4K,
                if (movie) SeerrPermission.REQUEST_4K_MOVIE else SeerrPermission.REQUEST_4K_TV,
            )
        }

    private val partialSeasons: Boolean get() = settings?.partialRequestsEnabled ?: true

    private val serversForVariant: List<SeerrServiceInstance> get() = allServers.filter { it.is4k == is4k }

    private val editable: Boolean get() = closed == null && connected && !submitting && !loading && !loadFailed

    private fun defaultProfileId(server: SeerrServiceInstance?): Int? =
        (if (isAnime) server?.activeAnimeProfileId else null) ?: server?.activeProfileId

    private fun defaultRootFolder(server: SeerrServiceInstance?): String? =
        (if (isAnime) server?.activeAnimeDirectory else null) ?: server?.activeDirectory

    private fun defaultLanguageProfileId(server: SeerrServiceInstance?): Int? =
        (if (isAnime) server?.activeAnimeLanguageProfileId else null) ?: server?.activeLanguageProfileId

    private fun defaultTags(server: SeerrServiceInstance?): List<Int>? = if (isAnime) server?.activeAnimeTags else server?.activeTags

    // ---- Availability ----

    /** Read live: the settings load records the instance's product on the session before anything shows. */
    private val availability: SeerrAvailability get() = SeerrAvailability(mediaInfo, client.session.product, is4k)

    private fun seasonBlocked(seasonNumber: Int): Boolean = availability.seasonBlock(seasonNumber) != null

    private val requestableSeasons: List<Int>
        get() {
            val availability = availability
            return seasons.map { it.seasonNumber }.filter { availability.seasonBlock(it) == null }
        }

    private val nothingToRequest: Boolean get() = if (movie) availability.movieBlock != null else requestableSeasons.isEmpty()

    private val canSubmit: Boolean
        get() {
            if (closed != null || !connected || submitting || loading || loadFailed || nothingToRequest) return false
            return movie || !partialSeasons || selectedSeasons.isNotEmpty()
        }

    private fun payload(): SeerrRequestPayload {
        val advanced = advancedAllowed && server != null
        return SeerrRequestPayload(
            mediaType = if (movie) "movie" else "tv",
            mediaId = tmdbId,
            seasons = if (movie || !partialSeasons) null else selectedSeasons.sorted(),
            is4k = is4k,
            serverId = if (advanced) server?.id else null,
            profileId = if (advanced) profileId else null,
            rootFolder = if (advanced) rootFolder else null,
            languageProfileId = if (advanced) languageProfileId else null,
            tags = if (advanced) tags else null,
        )
    }

    // ---- State ----

    private fun publish() {
        mutableState.value = build()
    }

    private fun build(): SeerrRequestUiState {
        val body = when {
            loading -> SeerrRequestBody.Loading
            loadFailed -> SeerrRequestBody.LoadFailed(T.seerr.requestsLoadFailed, T.common.retry)
            nothingToRequest -> SeerrRequestBody.NothingToRequest((if (movie) availability.movieBlock?.label else null) ?: T.seerr.nothingToRequest)
            else -> form()
        }
        val form = body as? SeerrRequestBody.Form
        shown4k = form?.request4k != null
        shownAdvanced = form?.advanced != null
        return SeerrRequestUiState(heading = T.seerr.request, title = title, body = body, closed = closed, refocus = refocus)
    }

    private fun form(): SeerrRequestBody.Form {
        val requestable = requestableSeasons
        val seasonSection = if (movie || !partialSeasons) {
            null
        } else {
            val availability = availability
            SeerrSeasonSection(
                heading = T.seerr.seasons,
                allLabel = T.seerr.allSeasons,
                allSelected = requestable.isNotEmpty() && selectedSeasons.containsAll(requestable),
                rows = seasons.map { season ->
                    SeerrSeasonRow(
                        seasonNumber = season.seasonNumber,
                        title = season.name ?: T.common.seasonNumber(season.seasonNumber.toString()),
                        subtitle = season.episodeCount?.let { T.explore.episodeCount(it) },
                        blockedLabel = availability.seasonBlock(season.seasonNumber)?.label,
                        checked = season.seasonNumber in selectedSeasons,
                    )
                },
            )
        }
        val advanced = if (advancedAllowed && serversForVariant.isNotEmpty()) advancedSection() else null
        val submittable = canSubmit
        val hasVisibleAdvancedControls = advanced != null && (advanced.pickers.isNotEmpty() || advanced.tags != null)
        return SeerrRequestBody.Form(
            seasons = seasonSection,
            request4k = if (can4k) is4k else null,
            request4kLabel = T.seerr.request4k,
            advanced = advanced,
            error = errorText,
            submitting = submitting,
            canSubmit = submittable,
            submitLabel = T.seerr.request,
            submitJumpSeason = requestable.lastOrNull()?.takeIf { !can4k && !hasVisibleAdvancedControls && submittable },
        )
    }

    private fun advancedSection(): SeerrAdvancedSection {
        val servers = serversForVariant
        val detail = serverDetail
        val shown = detail?.server ?: server
        val defaultProfile = defaultProfileId(shown)
        val defaultFolder = defaultRootFolder(shown)
        val defaultLanguage = defaultLanguageProfileId(shown)
        fun describe(name: String, isDefault: Boolean) = if (isDefault) T.seerr.defaultOption(name) else name
        val pickers = buildList {
            if (servers.size > 1) {
                add(
                    SeerrPicker(
                        SeerrPickerKind.SERVER,
                        T.seerr.destinationServer,
                        server?.name.orEmpty(),
                        servers.map { SeerrPickerOption(it.id, it.name ?: "#${it.id}", it.id == server?.id) },
                    ),
                )
            }
            detail?.profiles?.takeIf { it.isNotEmpty() }?.let { profiles ->
                val options = profiles.map { SeerrPickerOption(it.id, describe(it.name ?: "#${it.id}", it.id == defaultProfile), it.id == profileId) }
                add(SeerrPicker(SeerrPickerKind.QUALITY_PROFILE, T.seerr.qualityProfile, options.firstOrNull { it.selected }?.label.orEmpty(), options))
            }
            detail?.rootFolders?.takeIf { it.isNotEmpty() }?.let { folders ->
                val options = folders.map {
                    SeerrPickerOption(it.id, describe(it.path ?: "#${it.id}", it.path == defaultFolder), it.path == rootFolder)
                }
                add(
                    SeerrPicker(
                        SeerrPickerKind.ROOT_FOLDER,
                        T.seerr.rootFolder,
                        options.firstOrNull { it.selected }?.label ?: rootFolder.orEmpty(),
                        options,
                    ),
                )
            }
            detail?.languageProfiles?.takeIf { it.isNotEmpty() }?.let { languages ->
                val options = languages.map {
                    SeerrPickerOption(it.id, describe(it.name ?: "#${it.id}", it.id == defaultLanguage), it.id == languageProfileId)
                }
                add(SeerrPicker(SeerrPickerKind.LANGUAGE_PROFILE, T.seerr.languageProfile, options.firstOrNull { it.selected }?.label.orEmpty(), options))
            }
        }
        val tagsPicker = detail?.tags?.takeIf { it.isNotEmpty() }?.let { options ->
            val chosen = tags.orEmpty()
            val labels = options.filter { it.id in chosen }.map { it.label ?: "#${it.id}" }
            SeerrTagsPicker(
                label = T.seerr.tags,
                summary = if (labels.isEmpty()) T.seerr.noTags else labels.joinToString(", "),
                expanded = tagsExpanded,
                options = options.map { SeerrPickerOption(it.id, it.label ?: "#${it.id}", it.id in chosen) },
            )
        }
        return SeerrAdvancedSection(
            heading = T.seerr.advancedOptions,
            loading = serverDetailLoading,
            pickers = pickers,
            tags = tagsPicker,
            animeNote = if (isAnime) T.seerr.animeNote else null,
        )
    }

    private companion object {
        const val TAG = "seerr"
    }
}
