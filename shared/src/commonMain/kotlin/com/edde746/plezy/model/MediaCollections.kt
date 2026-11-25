package com.edde746.plezy.model

/** A library (Plex section, MediaBrowser view). */
data class MediaLibrary(
    val id: String,
    val backend: BackendKind,
    val title: String,
    val kind: MediaKind = MediaKind.UNKNOWN,
    /** The kinds Browse lists by default (a mixed library lists several). */
    val defaultBrowseKinds: List<MediaKind> = emptyList(),
    val language: String? = null,
    val updatedAt: Long? = null,
    val createdAt: Long? = null,
    val hidden: Boolean = false,
    val isShared: Boolean = false,
    val serverId: String? = null,
    val serverName: String? = null,
) {
    val globalKey: String get() = ServerId.tryParse(serverId)?.let { buildGlobalKey(it, id) } ?: id
}

/** A row of items: a home or library hub, a synthetic row of a MediaBrowser server. */
data class MediaHub(
    val id: String,
    val title: String,
    /** The backend's row type ("movie", "mixed", …). */
    val type: String,
    val items: List<MediaItem>,
    val identifier: String? = null,
    val size: Int = 0,
    /** More items than [items] exist. */
    val more: Boolean = false,
    val libraryId: String? = null,
    val serverId: String? = null,
    val serverName: String? = null,
)

/** A server playlist. */
data class MediaPlaylist(
    val id: String,
    val backend: BackendKind,
    val title: String,
    /** `video`, `audio`, `photo`. */
    val playlistType: String,
    val summary: String? = null,
    val guid: String? = null,
    val smart: Boolean = false,
    val durationMs: Long? = null,
    val leafCount: Int? = null,
    val viewCount: Int? = null,
    val addedAt: Long? = null,
    val updatedAt: Long? = null,
    val lastViewedAt: Long? = null,
    val compositeImagePath: String? = null,
    val thumbPath: String? = null,
    val serverId: String? = null,
    val serverName: String? = null,
) {
    val displayImagePath: String? get() = thumbPath ?: compositeImagePath
    val displayTitle: String get() = title
    val globalKey: String get() = ServerId.tryParse(serverId)?.let { buildGlobalKey(it, id) } ?: id
}

enum class PersonCredit { ACTOR, DIRECTOR }

/** An actor or director on one server. */
data class MediaPerson(
    val id: String,
    val name: String,
    val backend: BackendKind,
    val serverId: ServerId,
    val thumbPath: String? = null,
    val credit: PersonCredit? = null,
    val serverName: String? = null,
) {
    /** `"{serverId}:person:{id}"`: never collides with an item's key. */
    val globalKey: String get() = buildGlobalKey(serverId, "person:$id")
}

/** A person's biography and dates; fields the server has nothing for stay null. */
data class MediaPersonDetails(
    val biography: String? = null,
    val birthDate: CalendarDate? = null,
    val deathDate: CalendarDate? = null,
    val birthPlace: String? = null,
) {
    val isEmpty: Boolean get() = biography == null && birthDate == null && deathDate == null && birthPlace == null

    /** Age in whole years on [today], or at death; null without a birth date or for a negative age. */
    fun ageOn(today: CalendarDate): Int? {
        val birth = birthDate ?: return null
        val end = deathDate ?: today
        var years = end.year - birth.year
        if (end.month < birth.month || (end.month == birth.month && end.day < birth.day)) years--
        return years.takeIf { it >= 0 }
    }

    companion object {
        val EMPTY = MediaPersonDetails()

        /** The calendar date a server's date-time string starts with (its first ten characters); null if none. */
        fun parseDate(value: Any?): CalendarDate? {
            if (value !is String || value.length < 10) return null
            return CalendarDate.parse(value.substring(0, 10))
        }
    }
}

/** One result of a search. */
sealed interface SearchHit {
    val globalKey: String

    data class Media(val item: MediaItem) : SearchHit {
        override val globalKey: String get() = item.globalKey
    }

    data class Person(val person: MediaPerson) : SearchHit {
        override val globalKey: String get() = person.globalKey
    }
}

/** A genre tile of a library's Browse by genre. */
data class LibraryGenre(val title: String, val filterValue: String, val artPath: String? = null, val accentRgb: Int? = null)

enum class DiscographyGroupKind { ALBUMS, SINGLES_AND_EPS, LIVE, COMPILATIONS }

/** One release-format section of an artist's albums. */
data class ArtistDiscographyGroup(val kind: DiscographyGroupKind, val items: List<MediaItem>)

/** [albums] bucketed by [kindOf] in [DiscographyGroupKind] order; album order kept, empty groups dropped. */
fun buildArtistDiscographyGroups(albums: List<MediaItem>, kindOf: (MediaItem) -> DiscographyGroupKind): List<ArtistDiscographyGroup> {
    val buckets = albums.groupBy(kindOf)
    return DiscographyGroupKind.entries.mapNotNull { kind -> buckets[kind]?.let { ArtistDiscographyGroup(kind, it) } }
}

data class LyricLine(val text: String, val startMs: Long? = null)

data class Lyrics(val synced: Boolean, val lines: List<LyricLine>) {
    val isEmpty: Boolean get() = lines.isEmpty()
}

/** A collection holding some of the items asked about, with those items' ids in the collection's own order. */
data class CollectionMembership(val collection: MediaItem, val memberIds: List<String>)

/** A calendar day without a time zone. */
data class CalendarDate(val year: Int, val month: Int, val day: Int) {
    override fun toString(): String =
        "${year.toString().padStart(4, '0')}-${month.toString().padStart(2, '0')}-${day.toString().padStart(2, '0')}"

    companion object {
        /** A valid `YYYY-MM-DD` date, else null. */
        fun parse(value: String): CalendarDate? {
            val match = Regex("""^(\d{4})-(\d{2})-(\d{2})$""").matchEntire(value) ?: return null
            val (year, month, day) = match.destructured.toList().map { it.toInt() }
            if (month !in 1..12 || day !in 1..daysIn(year, month)) return null
            return CalendarDate(year, month, day)
        }

        private fun daysIn(year: Int, month: Int): Int = when (month) {
            2 -> if (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) 29 else 28
            4, 6, 9, 11 -> 30
            else -> 31
        }
    }
}
