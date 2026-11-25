package com.edde746.plezy.trackers

/** The tracker services a profile can connect. [id] is the stored form: never rename it. */
enum class TrackerService(val id: String) {
    TRAKT("trakt"),
    SIMKL("simkl"),
    MDBLIST("mdblist"),
    MYANIMELIST("mal"),
    ANILIST("anilist"),
    ;

    companion object {
        /** `null` for a service this build doesn't know: a row a newer app version wrote, which is skipped. */
        fun fromId(id: String): TrackerService? = entries.firstOrNull { it.id == id }
    }
}
