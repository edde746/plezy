package com.edde746.plezy.playback.source

/** A cached Plex `/library/metadata` envelope: one movie, an English version, a French second version when asked. */
fun plexMetadataEnvelope(includeSecondVersion: Boolean = false, malformedExtras: Boolean = false, subtitle: Boolean = false): String {
    val chapters = listOfNotNull(
        """{"id":"bad"}""".takeIf { malformedExtras },
        """{"id":1,"index":0,"startTimeOffset":0,"endTimeOffset":90000,"tag":"Intro"}""",
        """{"id":3,"index":1,"startTimeOffset":90000,"endTimeOffset":1290000,"tag":"Part A"}""",
    )
    val markers = listOfNotNull(
        """{"id":99,"type":"broken"}""".takeIf { malformedExtras },
        """{"id":2,"type":"credits","startTimeOffset":1290000,"endTimeOffset":1380000}""",
    )
    val media = listOfNotNull(plexMediaWithAudio("English", "eng", subtitle), plexMediaWithAudio("French", "fre", subtitle).takeIf { includeSecondVersion })
    return """
        {"MediaContainer":{"Metadata":[{"ratingKey":"movie-1","type":"movie","title":"Movie",
        "Chapter":[${chapters.joinToString(",")}],"Marker":[${markers.joinToString(",")}],"Media":[${media.joinToString(",")}]}]}}
    """.trimIndent()
}

private fun plexMediaWithAudio(language: String, languageCode: String, subtitle: Boolean): String {
    val subtitleStream = if (subtitle) {
        """,{"id":2,"streamType":3,"index":2,"codec":"srt","language":"English","languageCode":"eng","displayTitle":"English (SRT)","forced":true}"""
    } else {
        ""
    }
    return """{"Part":[{"Stream":[{"id":10,"streamType":2,"index":1,"language":"$language","languageCode":"$languageCode"}$subtitleStream]}]}"""
}

/** A movie stacked over two files of 50 and 40 minutes. */
const val STACKED_ENVELOPE = """
{"MediaContainer":{"Metadata":[{"ratingKey":"movie-1","type":"movie","title":"Movie","duration":5400000,
"Media":[{"id":1,"Part":[{"id":11,"duration":3000000},{"id":12,"duration":2400000}]}]}]}}
"""

/** A cached Jellyfin movie with one English audio stream and one chapter. */
const val JELLYFIN_ITEM = """
{"Id":"item-1","Type":"Movie","Name":"Jellyfin Movie","Chapters":[{"Name":"Chapter 1","StartPositionTicks":0}],
"MediaSources":[{"Id":"src-1","MediaStreams":[{"Type":"Audio","Index":1,"Language":"eng","DisplayLanguage":"English","IsDefault":true}]}]}
"""
