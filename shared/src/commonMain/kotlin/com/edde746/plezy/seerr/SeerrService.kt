package com.edde746.plezy.seerr

import kotlinx.serialization.json.JsonObject

/**
 * One Radarr or Sonarr instance configured in Seerr (`GET /service/radarr|sonarr`).
 *
 * @param activeLanguageProfileId Sonarr only.
 * @param activeAnimeDirectory Sonarr only, as the other anime defaults: what Seerr routes anime series to instead of
 *   the standard defaults; absent when the instance has no anime override.
 * @param activeTags the tag ids applied by default. Only the detail route reports them; the list route answers `[]`
 *   on Sonarr.
 */
data class SeerrServiceInstance(
    val id: Int,
    val name: String? = null,
    val is4k: Boolean = false,
    val isDefault: Boolean = false,
    val activeDirectory: String? = null,
    val activeProfileId: Int? = null,
    val activeLanguageProfileId: Int? = null,
    val activeAnimeDirectory: String? = null,
    val activeAnimeProfileId: Int? = null,
    val activeAnimeLanguageProfileId: Int? = null,
    val activeTags: List<Int>? = null,
    val activeAnimeTags: List<Int>? = null,
) {
    companion object {
        /** @throws IllegalArgumentException when the instance has no `id`. */
        fun fromJson(json: JsonObject): SeerrServiceInstance = SeerrServiceInstance(
            id = requireId(json, "service"),
            name = json.str("name"),
            is4k = json.bool("is4k") ?: false,
            isDefault = json.bool("isDefault") ?: false,
            activeDirectory = json.str("activeDirectory"),
            activeProfileId = json.int("activeProfileId"),
            activeLanguageProfileId = json.int("activeLanguageProfileId"),
            activeAnimeDirectory = json.str("activeAnimeDirectory"),
            activeAnimeProfileId = json.int("activeAnimeProfileId"),
            activeAnimeLanguageProfileId = json.int("activeAnimeLanguageProfileId"),
            activeTags = json.ints("activeTags"),
            activeAnimeTags = json.ints("activeAnimeTags"),
        )
    }
}

/**
 * One instance's quality profiles, root folders, language profiles and tags (`GET /service/radarr|sonarr/{id}`).
 *
 * @param languageProfiles Sonarr v3 only; absent on Radarr and newer Sonarr.
 */
data class SeerrServiceDetail(
    val server: SeerrServiceInstance? = null,
    val profiles: List<SeerrServiceProfile>? = null,
    val rootFolders: List<SeerrRootFolder>? = null,
    val languageProfiles: List<SeerrServiceProfile>? = null,
    val tags: List<SeerrServiceTag>? = null,
) {
    companion object {
        /** @throws IllegalArgumentException when an entry has no `id`. */
        fun fromJson(json: JsonObject): SeerrServiceDetail = SeerrServiceDetail(
            server = json.obj("server")?.let(SeerrServiceInstance::fromJson),
            profiles = json.objects("profiles", SeerrServiceProfile::fromJson),
            rootFolders = json.objects("rootFolders") { SeerrRootFolder(requireId(it, "root folder"), it.str("path")) },
            languageProfiles = json.objects("languageProfiles", SeerrServiceProfile::fromJson),
            tags = json.objects("tags") { SeerrServiceTag(requireId(it, "tag"), it.str("label")) },
        )
    }
}

/** A quality or language profile `{id, name}`. */
data class SeerrServiceProfile(val id: Int, val name: String? = null) {
    companion object {
        fun fromJson(json: JsonObject): SeerrServiceProfile = SeerrServiceProfile(requireId(json, "profile"), json.str("name"))
    }
}

data class SeerrRootFolder(val id: Int, val path: String? = null)

/** An arr tag `{id, label}`. */
data class SeerrServiceTag(val id: Int, val label: String? = null)

private fun requireId(json: JsonObject, what: String): Int = requireNotNull(json.int("id")) { "Seerr $what without id" }
