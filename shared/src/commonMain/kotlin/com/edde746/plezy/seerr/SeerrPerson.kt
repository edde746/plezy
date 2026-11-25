package com.edde746.plezy.seerr

import kotlinx.serialization.json.JsonObject

/**
 * A person from `GET /person/{id}`: TMDB's details as Seerr relays them. Dates are TMDB's `YYYY-MM-DD`; any field may be
 * missing or null.
 */
data class SeerrPerson(
    val id: Int? = null,
    val name: String? = null,
    val biography: String? = null,
    val birthday: String? = null,
    val deathday: String? = null,
    val placeOfBirth: String? = null,
    val knownForDepartment: String? = null,
    val profilePath: String? = null,
) {
    companion object {
        fun fromJson(json: JsonObject): SeerrPerson = SeerrPerson(
            id = json.int("id"),
            name = json.str("name"),
            biography = json.str("biography"),
            birthday = json.str("birthday"),
            deathday = json.str("deathday"),
            placeOfBirth = json.str("placeOfBirth"),
            knownForDepartment = json.str("knownForDepartment"),
            profilePath = json.str("profilePath"),
        )
    }
}

/**
 * A person's titles from `GET /person/{id}/combined_credits`, in Seerr's order: [cast] the roles they played, [crew] the
 * jobs they did. Entries that aren't a movie or show, or carry no id, are left out.
 */
data class SeerrPersonCredits(val cast: List<SeerrPersonCredit>, val crew: List<SeerrPersonCredit>) {
    companion object {
        fun fromJson(json: JsonObject): SeerrPersonCredits = SeerrPersonCredits(
            cast = json.objects("cast") { credit(it, role = it.str("character")) }.orEmpty(),
            crew = json.objects("crew") { credit(it, role = it.str("job")) }.orEmpty(),
        )

        private fun credit(json: JsonObject, role: String?): SeerrPersonCredit? {
            if (json.str("mediaType") !in MEDIA_TYPES || json.int("id") == null) return null
            return SeerrPersonCredit(SeerrMedia.fromJson(json), role)
        }

        private val MEDIA_TYPES = setOf("movie", "tv")
    }
}

/** One title of a person's credits: the title as a discover result, and [role] the character played or the job done. */
data class SeerrPersonCredit(val media: SeerrMedia, val role: String?)
