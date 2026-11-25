package com.edde746.plezy.catalog

import kotlin.time.Duration
import kotlin.time.Instant
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

// Provider-neutral catalog facts beside [CatalogItem]. Each `fromJson` returns null (or an empty value) rather than
// failing the whole item: catalog payloads are best-effort API data.

/** What a leaderboard position is a position in. */
enum class CatalogRankScope(override val id: String) : CatalogWireEnum {
    POPULAR("popular"),
    AIRING("airing"),
    RATED("rated"),
    TRENDING("trending"),
}

/**
 * A leaderboard position within [scope], over all time or one season/year window. Providers return several at once,
 * so an item holds a list; dropping the window would turn "#3 this season" into a false all-time claim.
 */
data class CatalogRank(
    val rank: Int,
    val scope: CatalogRankScope,
    /** True for an all-time chart; false when [year]/[season] bound it. */
    val allTime: Boolean = true,
    val year: Int? = null,
    val season: CatalogSeasonName? = null,
) {
    /** `allTime` is written only when false. */
    fun toJson(): JsonObject = buildJsonObject {
        put("rank", rank)
        put("scope", scope.id)
        if (!allTime) put("allTime", false)
        putOpt("year", year)
        putOpt("season", season)
    }

    companion object {
        /** Null when `rank` or `scope` is missing or unknown; `allTime` is true unless literally `false`. */
        fun fromJson(json: JsonObject): CatalogRank? {
            val rank = json.catalogInt("rank") ?: return null
            val scope = json.catalogEnum<CatalogRankScope>("scope") ?: return null
            return CatalogRank(
                rank = rank,
                scope = scope,
                allTime = json.catalogBool("allTime") != false,
                year = json.catalogInt("year"),
                season = json.catalogEnum<CatalogSeasonName>("season"),
            )
        }
    }
}

/** The window a windowed counter covers; such a number rendered without its period is a false claim. */
enum class CatalogAudiencePeriod(override val id: String) : CatalogWireEnum {
    DAY("day"),
    WEEK("week"),
    MONTH("month"),
    YEAR("year"),
    ALL_TIME("allTime"),
}

/** Community-size counters. Every field is optional: no provider returns all of them. */
data class CatalogAudience(
    /** Users watching right now (Trakt trending `watchers`). */
    val watchingNow: Int? = null,
    /** Users with the title on any list (MAL `num_list_users`, AniList `popularity`). */
    val listed: Int? = null,
    /** Viewers within [viewersPeriod] (Simkl `watched`); not a completion count. Never render it without the period. */
    val viewers: Int? = null,
    val viewersPeriod: CatalogAudiencePeriod? = null,
    /** Users who plan to watch it (Simkl `plan_to_watch`). */
    val planning: Int? = null,
    /** Users with it in progress on their list (MAL status count); not [watchingNow]. */
    val watching: Int? = null,
    /** Users who finished it (MAL lifetime status count). */
    val completed: Int? = null,
    val onHold: Int? = null,
    /** Users who abandoned it; [dropRate] is the share. */
    val dropped: Int? = null,
    /** Unitless recent-activity score (AniList `trending`); render comparatively or not at all. */
    val trendingActivity: Int? = null,
    val favorited: Int? = null,
    /** Share of users who dropped it, 0–1. */
    val dropRate: Double? = null,
    val comments: Int? = null,
) {
    /** Every count and [dropRate] null; [viewersPeriod] alone counts as empty. */
    val isEmpty: Boolean
        get() = watchingNow == null && listed == null && viewers == null && planning == null && watching == null &&
            completed == null && onHold == null && dropped == null && trendingActivity == null && favorited == null &&
            dropRate == null && comments == null

    fun toJson(): JsonObject = buildJsonObject {
        putOpt("watchingNow", watchingNow)
        putOpt("listed", listed)
        putOpt("viewers", viewers)
        putOpt("viewersPeriod", viewersPeriod)
        putOpt("planning", planning)
        putOpt("watching", watching)
        putOpt("completed", completed)
        putOpt("onHold", onHold)
        putOpt("dropped", dropped)
        putOpt("trendingActivity", trendingActivity)
        putOpt("favorited", favorited)
        putOpt("dropRate", dropRate)
        putOpt("comments", comments)
    }

    /**
     * Field-wise union preferring [other]'s values: a row and its detail body each carry counters the other omits.
     * [viewersPeriod] travels with [viewers], so a count is never relabelled with someone else's window.
     */
    fun mergedWith(other: CatalogAudience): CatalogAudience = CatalogAudience(
        watchingNow = other.watchingNow ?: watchingNow,
        listed = other.listed ?: listed,
        viewers = other.viewers ?: viewers,
        viewersPeriod = if (other.viewers != null) other.viewersPeriod else viewersPeriod,
        planning = other.planning ?: planning,
        watching = other.watching ?: watching,
        completed = other.completed ?: completed,
        onHold = other.onHold ?: onHold,
        dropped = other.dropped ?: dropped,
        trendingActivity = other.trendingActivity ?: trendingActivity,
        favorited = other.favorited ?: favorited,
        dropRate = other.dropRate ?: dropRate,
        comments = other.comments ?: comments,
    )

    companion object {
        fun fromJson(json: JsonObject): CatalogAudience = CatalogAudience(
            watchingNow = json.catalogInt("watchingNow"),
            listed = json.catalogInt("listed"),
            viewers = json.catalogInt("viewers"),
            viewersPeriod = json.catalogEnum<CatalogAudiencePeriod>("viewersPeriod"),
            planning = json.catalogInt("planning"),
            watching = json.catalogInt("watching"),
            completed = json.catalogInt("completed"),
            onHold = json.catalogInt("onHold"),
            dropped = json.catalogInt("dropped"),
            trendingActivity = json.catalogInt("trendingActivity"),
            favorited = json.catalogInt("favorited"),
            dropRate = json.catalogDouble("dropRate"),
            comments = json.catalogInt("comments"),
        )
    }
}

/** A recurring weekly broadcast slot (Trakt `airs`, MAL `broadcast`): a schedule, never a next-episode date. */
data class CatalogBroadcast(
    /** ISO-8601 weekday, Monday = 1 through Sunday = 7. */
    val weekday: Int? = null,
    /** Local broadcast time as `HH:mm` in [timezone]. */
    val time: String? = null,
    /** IANA zone name, e.g. `Asia/Tokyo`. */
    val timezone: String? = null,
) {
    /** No weekday and no time; a timezone alone counts as empty. */
    val isEmpty: Boolean get() = weekday == null && time == null

    fun toJson(): JsonObject = buildJsonObject {
        putOpt("weekday", weekday)
        putOpt("time", time)
        putOpt("timezone", timezone)
    }

    companion object {
        fun fromJson(json: JsonObject): CatalogBroadcast = CatalogBroadcast(
            weekday = json.catalogInt("weekday"),
            time = json.catalogString("time"),
            timezone = json.catalogString("timezone"),
        )
    }
}

/** The next episode's actual air time (AniList `nextAiringEpisode`). */
data class CatalogNextEpisode(val airsAt: Instant, val episode: Int? = null) {
    /** Remaining time from [now], clamped at zero once the slot has passed. */
    fun timeUntil(now: Instant): Duration = (airsAt - now).coerceAtLeast(Duration.ZERO)

    /** `airsAt` as a UTC ISO-8601 instant. */
    fun toJson(): JsonObject = buildJsonObject {
        putOpt("airsAt", airsAt)
        putOpt("episode", episode)
    }

    companion object {
        /** Null when `airsAt` is missing or unparseable. */
        fun fromJson(json: JsonObject): CatalogNextEpisode? {
            val airsAt = json.catalogInstant("airsAt") ?: return null
            return CatalogNextEpisode(airsAt = airsAt, episode = json.catalogInt("episode"))
        }
    }
}

/** Whether the title exists on the user's own media servers, per quality tier. */
enum class CatalogAvailability(override val id: String) : CatalogWireEnum {
    UNAVAILABLE("unavailable"),
    PARTIALLY_AVAILABLE("partiallyAvailable"),
    AVAILABLE("available"),
}

/** Where a request for the title stands in the approval/download pipeline. */
enum class CatalogRequestState(override val id: String) : CatalogWireEnum {
    PENDING("pending"),
    APPROVED("approved"),
    PROCESSING("processing"),
    DECLINED("declined"),
    FAILED("failed"),
}

/**
 * Seerr's server-side knowledge about a discovery result. Availability and request state are independent: a show can
 * be available in HD while a 4K request for it is pending.
 */
data class CatalogServerState(
    val availability: CatalogAvailability? = null,
    val availability4k: CatalogAvailability? = null,
    val request: CatalogRequestState? = null,
    val request4k: CatalogRequestState? = null,
    /** Seasons already on the server, when the provider breaks it down. */
    val availableSeasons: Int? = null,
    val totalSeasons: Int? = null,
) {
    val isEmpty: Boolean
        get() = availability == null && availability4k == null && request == null && request4k == null &&
            availableSeasons == null && totalSeasons == null

    fun toJson(): JsonObject = buildJsonObject {
        putOpt("availability", availability)
        putOpt("availability4k", availability4k)
        putOpt("request", request)
        putOpt("request4k", request4k)
        putOpt("availableSeasons", availableSeasons)
        putOpt("totalSeasons", totalSeasons)
    }

    companion object {
        fun fromJson(json: JsonObject): CatalogServerState = CatalogServerState(
            availability = json.catalogEnum<CatalogAvailability>("availability"),
            availability4k = json.catalogEnum<CatalogAvailability>("availability4k"),
            request = json.catalogEnum<CatalogRequestState>("request"),
            request4k = json.catalogEnum<CatalogRequestState>("request4k"),
            availableSeasons = json.catalogInt("availableSeasons"),
            totalSeasons = json.catalogInt("totalSeasons"),
        )
    }
}

/** Anime broadcast season (AniList `season`/`seasonYear`, MAL `start_season`). */
enum class CatalogSeasonName(override val id: String) : CatalogWireEnum {
    WINTER("winter"),
    SPRING("spring"),
    SUMMER("summer"),
    FALL("fall"),
    ;

    companion object {
        /** Case-insensitive: AniList's `FALL` and MAL's `fall` alike. */
        fun parse(raw: String?): CatalogSeasonName? = catalogEnumOf<CatalogSeasonName>(raw?.lowercase())
    }
}

/** A calendar broadcast window, "Fall 2025". */
data class CatalogSeasonInfo(val name: CatalogSeasonName, val year: Int? = null) {
    fun toJson(): JsonObject = buildJsonObject {
        put("name", name.id)
        putOpt("year", year)
    }

    companion object {
        /** Null when the name is missing or unknown. */
        fun fromJson(json: JsonObject): CatalogSeasonInfo? {
            val name = json.catalogEnum<CatalogSeasonName>("name") ?: return null
            return CatalogSeasonInfo(name = name, year = json.catalogInt("year"))
        }
    }
}

/** Release format, finer-grained than the media kind (AniList `format`, MAL `media_type`): a show can be an OVA. */
enum class CatalogFormat(override val id: String) : CatalogWireEnum {
    TV("tv"),
    TV_SHORT("tvShort"),
    MOVIE("movie"),
    SPECIAL("special"),
    OVA("ova"),
    ONA("ona"),
    MUSIC("music"),
    OTHER("other"),
}

/** What the title was adapted from (AniList/MAL `source`). */
enum class CatalogSourceMaterial(override val id: String) : CatalogWireEnum {
    ORIGINAL("original"),
    MANGA("manga"),
    LIGHT_NOVEL("lightNovel"),
    NOVEL("novel"),
    VISUAL_NOVEL("visualNovel"),
    GAME("game"),
    WEB_COMIC("webComic"),
    MUSIC_RELEASE("musicRelease"),
    OTHER_MEDIA("otherMedia"),
}

/** A non-cast credit. */
enum class CatalogCreditRole(override val id: String) : CatalogWireEnum {
    DIRECTOR("director"),
    WRITER("writer"),
    PRODUCER("producer"),
    CREATOR("creator"),
    COMPOSER("composer"),
}

data class CatalogCredit(val name: String, val role: CatalogCreditRole) {
    fun toJson(): JsonObject = buildJsonObject {
        put("name", name)
        put("role", role.id)
    }

    companion object {
        /** Null when either field is missing or the role is unknown. */
        fun fromJson(json: JsonObject): CatalogCredit? {
            val name = json.catalogString("name") ?: return null
            val role = json.catalogEnum<CatalogCreditRole>("role") ?: return null
            return CatalogCredit(name, role)
        }
    }
}

/** A ranked descriptive tag (AniList `tags`); some spoil the plot. */
data class CatalogTag(
    val name: String,
    /** 0–100 community relevance, when the provider ranks them. */
    val rank: Int? = null,
    val isSpoiler: Boolean = false,
) {
    /** `isSpoiler` is written only when true. */
    fun toJson(): JsonObject = buildJsonObject {
        put("name", name)
        putOpt("rank", rank)
        if (isSpoiler) put("isSpoiler", true)
    }

    companion object {
        fun fromJson(json: JsonObject): CatalogTag? {
            val name = json.catalogString("name") ?: return null
            return CatalogTag(name = name, rank = json.catalogInt("rank"), isSpoiler = json.catalogBool("isSpoiler") == true)
        }
    }
}

/** An outbound link the provider supplies (AniList `externalLinks`/`streamingEpisodes`, Simkl `url`). */
data class CatalogLink(
    /** Site name as the provider gives it; a proper noun, never translated. */
    val label: String,
    val url: String,
    /** Plays the title rather than describing it ("Watch on" versus "Links"). */
    val isStreaming: Boolean = false,
) {
    /** `isStreaming` is written only when true. */
    fun toJson(): JsonObject = buildJsonObject {
        put("label", label)
        put("url", url)
        if (isStreaming) put("isStreaming", true)
    }

    companion object {
        fun fromJson(json: JsonObject): CatalogLink? {
            val label = json.catalogString("label") ?: return null
            val url = json.catalogString("url") ?: return null
            return CatalogLink(label = label, url = url, isStreaming = json.catalogBool("isStreaming") == true)
        }
    }
}

/** Why a person appears against a recommended title. */
enum class CatalogRecommendationReason(override val id: String) : CatalogWireEnum {
    FAVORITED("favorited"),
    RECOMMENDED("recommended"),
}

/** A user whose activity produced a recommendation (Trakt `favorited_by`/`recommended_by`). */
data class CatalogRecommender(
    val username: String,
    val reason: CatalogRecommendationReason,
    val name: String? = null,
    /** Free-text note the user attached to the recommendation. */
    val note: String? = null,
) {
    /** The display name when set, otherwise the handle. */
    val displayName: String get() = name?.takeIf { it.isNotEmpty() } ?: username

    fun toJson(): JsonObject = buildJsonObject {
        put("username", username)
        put("reason", reason.id)
        putOpt("name", name)
        putOpt("note", note)
    }

    companion object {
        fun fromJson(json: JsonObject): CatalogRecommender? {
            val username = json.catalogString("username") ?: return null
            val reason = json.catalogEnum<CatalogRecommendationReason>("reason") ?: return null
            return CatalogRecommender(username, reason, name = json.catalogString("name"), note = json.catalogString("note"))
        }
    }
}

/** One cast entry: an actor with their character (Trakt) or an anime character with its role (MAL). */
data class CatalogCastMember(
    val name: String,
    /** Character name, or a role such as `Main` / `Supporting`. */
    val secondary: String? = null,
    /** Absolute https headshot/portrait URL. */
    val imageUrl: String? = null,
    /** The source's id of the person: Seerr's TMDB person id, which opens their Seerr person page. */
    val personId: Int? = null,
) {
    fun toJson(): JsonObject = buildJsonObject {
        put("name", name)
        putOpt("secondary", secondary)
        putOpt("imageUrl", imageUrl)
        putOpt("personId", personId)
    }

    companion object {
        /** Null without a `name`. */
        fun fromJson(json: JsonObject): CatalogCastMember? {
            val name = json.catalogString("name") ?: return null
            return CatalogCastMember(
                name,
                secondary = json.catalogString("secondary"),
                imageUrl = json.catalogString("imageUrl"),
                personId = json.catalogInt("personId"),
            )
        }
    }
}
