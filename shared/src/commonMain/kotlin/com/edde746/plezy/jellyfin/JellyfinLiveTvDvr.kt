package com.edde746.plezy.jellyfin

import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.RecordingConflictException
import com.edde746.plezy.livetv.LiveTvDvr
import com.edde746.plezy.livetv.LiveTvDvrSupport
import com.edde746.plezy.livetv.MediaGrabOperation
import com.edde746.plezy.livetv.MediaSubscription
import com.edde746.plezy.livetv.MediaSubscriptionCreateRequest
import com.edde746.plezy.livetv.SubscriptionSetting
import com.edde746.plezy.livetv.SubscriptionTemplate
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.flexibleInt
import com.edde746.plezy.strings.T
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

/** Rule keys name their timer space: one-off timers and series rules delete through different routes. */
internal const val TIMER_RULE_PREFIX = "timer:"
internal const val SERIES_RULE_PREFIX = "series:"

/**
 * Recordings on a MediaBrowser server, Jellyfin or Emby, in Plex's shapes. A rule is a series timer
 * (`/LiveTv/SeriesTimers`), a scheduled recording a timer that is neither cancelled nor completed (`/LiveTv/Timers`;
 * cancelled children of a series rule stay as "skip this episode" markers, Emby also returns completed ones, and Emby
 * has no status filters, so both dialects filter here). A template is the server's pre-filled timer
 * (`/LiveTv/Timers/Defaults`), carried JSON-encoded in the entry's `parameters` and posted back whole with the user's
 * settings overlaid; setting ids are the timer's field names.
 *
 * Creates and updates answer 204 (Emby 200) with no body: the new timer shows on the next list fetch.
 */
internal class JellyfinLiveTvDvr(private val core: JellyfinCore) : LiveTvDvrSupport {
    private val productName: String get() = core.dialect.productName

    /** None: a DVR list would replace the synthesized Live TV entry that channels, favourites and tuning key off. */
    override suspend fun fetchDvrs(): List<LiveTvDvr> = emptyList()

    /** The server refreshes its guide on its own schedule; the caller's refresh re-fetches channels and guide. */
    override suspend fun reloadGuide(dvrId: String) = Unit

    override val supportsRuleProcessing: Boolean get() = false

    override suspend fun processRecordingRules() {
        throw UnsupportedOperationException("$productName has no recording-rule re-evaluation endpoint")
    }

    /**
     * "Record episode" (selected), plus "Record series" only for a program the server calls a series (a series timer
     * on anything else fails server-side); a failed series probe offers the episode alone.
     */
    override suspend fun getSubscriptionTemplate(guid: String): List<SubscriptionTemplate> {
        if (guid.isEmpty()) return emptyList()
        val route = JellyfinLiveTvRoutes.timerDefaults(guid)
        val defaults = core.get(route.path, route.query).throwIfError().obj ?: return emptyList()
        val stash = defaults.toString()
        val entries = listOfNotNull(
            MediaSubscription(
                key = "",
                type = MediaSubscription.TYPE_EPISODE,
                title = T.liveTv.recordEpisode,
                selected = true,
                parameters = stash,
                settings = timerSettings(defaults),
            ),
            if (programIsSeries(guid)) {
                MediaSubscription(
                    key = "",
                    type = MediaSubscription.TYPE_SERIES,
                    title = T.liveTv.recordSeries,
                    parameters = stash,
                    settings = seriesTimerSettings(defaults),
                )
            } else {
                null
            },
        )
        return listOf(SubscriptionTemplate(entries))
    }

    private suspend fun programIsSeries(programId: String): Boolean = try {
        val route = JellyfinLiveTvRoutes.program(programId, core.userId)
        core.get(route.path, route.query).throwIfError().obj?.bool("IsSeries") == true
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.d(TAG, e) { "$productName program series probe failed" }
        false
    }

    /** Null: the created timer shows on the next fetch. A one-off's 400 is the server's duplicate answer. */
    override suspend fun createRecordingRule(request: MediaSubscriptionCreateRequest): MediaSubscription? {
        val stash = request.parameters
        require(!stash.isNullOrEmpty()) { "The recording request is missing the timer defaults" }
        val defaults = Json.parseToJsonElement(stash) as? JsonObject ?: throw IllegalArgumentException("The timer defaults aren't an object")
        val isSeries = request.type == MediaSubscription.TYPE_SERIES
        val response = core.post(if (isSeries) JellyfinLiveTvRoutes.SERIES_TIMERS else JellyfinLiveTvRoutes.TIMERS, body = defaults.withPrefs(request.prefs))
        if (!isSeries && response.status == 400) throw RecordingConflictException("A recording is already scheduled for this program")
        response.throwIfError()
        return null
    }

    /** Series rules only (`series:` keys): one-off timers have no settings the server honours beyond cancelling. */
    override suspend fun updateRecordingRule(subscriptionId: String, prefs: Map<String, Any?>, checkCurrent: (() -> Unit)?): MediaSubscription? {
        checkCurrent?.invoke()
        val id = stripPrefix(subscriptionId, SERIES_RULE_PREFIX) ?: throw IllegalArgumentException("Expected a series rule key")
        val path = JellyfinLiveTvRoutes.seriesTimer(id)
        val current = core.get(path).throwIfError().obj
            ?: throw MediaServerHttpException(MediaServerHttpErrorType.UNKNOWN, "Series timer not found", statusCode = 404)
        val validated = MediaSubscription(key = subscriptionId, settings = seriesTimerSettings(current)).validatePrefs(prefs)
        checkCurrent?.invoke()
        core.post(path, body = current.withPrefs(validated)).throwIfError()
        checkCurrent?.invoke()
        val refreshed = core.get(path).throwIfError()
        val updated = refreshed.obj
            ?: throw MediaServerHttpException(MediaServerHttpErrorType.UNKNOWN, "Invalid recording rule response", statusCode = refreshed.status)
        return MediaSubscription(key = subscriptionId, type = MediaSubscription.TYPE_SERIES, title = updated.str("Name"), settings = seriesTimerSettings(updated))
    }

    /** A series rule's delete removes its child timers server-side. */
    override suspend fun deleteRecordingRule(subscriptionId: String) {
        val path = stripPrefix(subscriptionId, SERIES_RULE_PREFIX)?.let(JellyfinLiveTvRoutes::seriesTimer)
            ?: stripPrefix(subscriptionId, TIMER_RULE_PREFIX)?.let(JellyfinLiveTvRoutes::timer)
            ?: throw IllegalArgumentException("Expected a timer or series rule key")
        core.delete(path).throwIfError()
    }

    override suspend fun fetchScheduledRecordings(): List<MediaGrabOperation> = fetchActiveTimers().map(::grabFromTimer)

    override suspend fun cancelGrab(operationId: String) {
        val id = stripPrefix(operationId, TIMER_RULE_PREFIX) ?: operationId
        require(id.isNotEmpty()) { "The recording id is empty" }
        core.delete(JellyfinLiveTvRoutes.timer(id)).throwIfError()
    }

    /** None: guide programs carry their rule keys, and the mapping needs Plex's provider id. */
    override suspend fun fetchSubscriptionMapping(providerId: String, ratingKeys: List<String>, includeStorage: Boolean): List<MediaSubscription> =
        emptyList()

    /** Series rules, each with its scheduled children unless [includeGrabs] is false. Rules have no storage totals. */
    override suspend fun fetchRecordingRules(includeGrabs: Boolean, includeStorage: Boolean): List<MediaSubscription> {
        val route = JellyfinLiveTvRoutes.seriesTimersByName
        val rules = core.itemsArray(core.get(route.path, route.query).throwIfError().data)
        val grabsByRule = if (includeGrabs && rules.isNotEmpty()) {
            fetchActiveTimers()
                .filter { !it.str("SeriesTimerId").isNullOrEmpty() }
                .groupBy({ SERIES_RULE_PREFIX + it.str("SeriesTimerId") }, ::grabFromTimer)
        } else {
            emptyMap()
        }
        return rules.map { dto ->
            val key = SERIES_RULE_PREFIX + dto.str("Id").orEmpty()
            MediaSubscription(
                key = key,
                type = MediaSubscription.TYPE_SERIES,
                title = dto.str("Name"),
                settings = seriesTimerSettings(dto),
                grabOperations = grabsByRule[key].orEmpty(),
            )
        }
    }

    private suspend fun fetchActiveTimers(): List<JsonObject> =
        core.itemsArray(core.get(JellyfinLiveTvRoutes.TIMERS).throwIfError().data)
            .filter { it.str("Status") != "Cancelled" && it.str("Status") != "Completed" }

    /** A timer as a grab whose airing uses the Plex keys [com.edde746.plezy.livetv.LiveTvProgram.fromJson] reads. */
    private fun grabFromTimer(dto: JsonObject): MediaGrabOperation {
        val id = TIMER_RULE_PREFIX + dto.str("Id").orEmpty()
        val seriesTimerId = dto.str("SeriesTimerId")?.takeIf { it.isNotEmpty() }
        val programInfo = dto.obj("ProgramInfo")
        return MediaGrabOperation(
            id = id,
            status = when (dto.str("Status")) {
                "InProgress" -> "grabbing"
                "Error", "ConflictedNotOk" -> "error"
                else -> "scheduled"
            },
            metadata = buildJsonObject {
                dto.str("Name")?.let { put("title", it) }
                dto.str("Overview")?.let { put("summary", it) }
                dto.str("ProgramId")?.let {
                    put("ratingKey", it)
                    put("guid", it)
                }
                JellyfinTime.isoToEpochSeconds(dto.str("StartDate"))?.let { put("beginsAt", it) }
                JellyfinTime.isoToEpochSeconds(dto.str("EndDate"))?.let { put("endsAt", it) }
                dto.str("ChannelId")?.let { put("channelIdentifier", it) }
                dto.str("ChannelName")?.let { put("channelCallSign", it) }
                put("subscriptionID", id)
                seriesTimerId?.let { put("grandparentSubscriptionID", SERIES_RULE_PREFIX + it) }
                if (programInfo != null) {
                    programInfo.str("SeriesName")?.let { put("grandparentTitle", it) }
                    programInfo["IndexNumber"]?.let { put("index", it) }
                    programInfo["ParentIndexNumber"]?.let { put("parentIndex", it) }
                }
            },
        )
    }

    /** Paddings: what a one-off timer honours. */
    private fun timerSettings(dto: JsonObject): List<SubscriptionSetting> = listOf(
        intSetting("PrePaddingSeconds", T.liveTv.recordSettings.startEarly, dto),
        intSetting("PostPaddingSeconds", T.liveTv.recordSettings.endLate, dto),
    )

    private fun seriesTimerSettings(dto: JsonObject): List<SubscriptionSetting> = timerSettings(dto) + listOf(
        boolSetting("RecordNewOnly", T.liveTv.recordSettings.newOnly, dto),
        boolSetting("RecordAnyChannel", T.liveTv.recordSettings.anyChannel, dto),
        boolSetting("RecordAnyTime", T.liveTv.recordSettings.anyTime, dto),
        boolSetting("SkipEpisodesInLibrary", T.liveTv.recordSettings.skipInLibrary, dto),
        intSetting("KeepUpTo", T.liveTv.recordSettings.keepUpTo, dto, summary = T.liveTv.recordSettings.keepUpToHint),
    )

    private fun intSetting(id: String, label: String, dto: JsonObject, summary: String? = null) =
        SubscriptionSetting(id = id, label = label, summary = summary, type = "int", value = flexibleInt(dto[id]) ?: 0, minimum = 0)

    private fun boolSetting(id: String, label: String, dto: JsonObject) =
        SubscriptionSetting(id = id, label = label, type = "bool", value = dto.bool(id) == true)

    private companion object {
        const val TAG = "JellyfinLiveTvDvr"

        fun stripPrefix(key: String, prefix: String): String? =
            if (key.startsWith(prefix) && key.length > prefix.length) key.substring(prefix.length) else null

        /** [prefs] overlaid on the timer; a null pref (a cleared number) keeps the server's value. */
        fun JsonObject.withPrefs(prefs: Map<String, Any?>): JsonObject {
            val body = LinkedHashMap(this)
            for ((id, value) in prefs) {
                body[id] = when (value) {
                    null -> continue
                    is Boolean -> JsonPrimitive(value)
                    is Number -> JsonPrimitive(value)
                    is String -> JsonPrimitive(value)
                    else -> throw IllegalArgumentException("Unsupported recording option value for $id")
                }
            }
            return JsonObject(body)
        }
    }
}
