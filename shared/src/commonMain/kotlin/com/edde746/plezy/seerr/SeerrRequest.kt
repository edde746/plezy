package com.edde746.plezy.seerr

import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.add
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlinx.serialization.json.putJsonArray

/**
 * A request's approval state (`MediaRequest.status`), the same codes on every product. FAILED: the arr refused the
 * submission; COMPLETED: the media became available.
 */
enum class SeerrRequestStatus(val code: Int) {
    PENDING(1),
    APPROVED(2),
    DECLINED(3),
    FAILED(4),
    COMPLETED(5);

    companion object {
        /** An unknown code reads as [PENDING]: shown as requested and not re-submittable, the conservative reading. */
        fun fromCode(code: Int?): SeerrRequestStatus = entries.firstOrNull { it.code == code } ?: PENDING
    }
}

/**
 * A media request as `POST /request` returns it.
 *
 * @param seasons a show's request: the seasons it covers.
 */
data class SeerrRequest(
    val id: Int,
    val status: SeerrRequestStatus,
    val is4k: Boolean? = null,
    val media: SeerrMediaInfo? = null,
    val seasons: List<SeerrRequestSeason>? = null,
) {
    companion object {
        /** @throws IllegalArgumentException when the request has no `id` (or a season no `seasonNumber`). */
        fun fromJson(json: JsonObject): SeerrRequest = SeerrRequest(
            id = requireNotNull(json.int("id")) { "Seerr request without id" },
            status = SeerrRequestStatus.fromCode(json.int("status")),
            is4k = json.bool("is4k"),
            media = json.obj("media")?.let(SeerrMediaInfo::fromJson),
            seasons = json.objects("seasons") { season ->
                SeerrRequestSeason(requireNotNull(season.int("seasonNumber")) { "Seerr request season without seasonNumber" })
            },
        )
    }
}

/** One season of a request (`MediaRequest.seasons[]`). */
data class SeerrRequestSeason(val seasonNumber: Int)

/**
 * The body of `POST /request`. The advanced fields need `REQUEST_ADVANCED`, [is4k] the 4K permissions.
 *
 * @param mediaType `movie` or `tv`.
 * @param mediaId the TMDB id.
 * @param seasons a show's season numbers; null requests all of them.
 * @param tags the arr's tag ids: an empty list is a real "no tags" override, null keeps the instance's defaults.
 */
data class SeerrRequestPayload(
    val mediaType: String,
    val mediaId: Int,
    val seasons: List<Int>? = null,
    val is4k: Boolean = false,
    val serverId: Int? = null,
    val profileId: Int? = null,
    val rootFolder: String? = null,
    val languageProfileId: Int? = null,
    val tags: List<Int>? = null,
) {
    /** `seasons` only for a show (`"all"` when null), `is4k` always, every other optional field only when set. */
    fun toJson(): JsonObject = buildJsonObject {
        put("mediaType", mediaType)
        put("mediaId", mediaId)
        if (mediaType == "tv") {
            if (seasons == null) put("seasons", "all") else putJsonArray("seasons") { seasons.forEach { add(it) } }
        }
        put("is4k", is4k)
        serverId?.let { put("serverId", it) }
        profileId?.let { put("profileId", it) }
        rootFolder?.let { put("rootFolder", it) }
        languageProfileId?.let { put("languageProfileId", it) }
        tags?.let { ids -> putJsonArray("tags") { ids.forEach { add(it) } } }
    }
}
