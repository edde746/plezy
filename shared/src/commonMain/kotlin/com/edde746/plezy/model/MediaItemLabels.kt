package com.edde746.plezy.model

private const val SEPARATOR = " · "

/** A queue row's second line: `Show · S2E3`, the show, `2026 · Edition`, the year, else the kind's name. */
fun formatQueueItemSubtitle(item: MediaItem): String {
    val show = item.grandparentTitle
    if (show != null && item.parentIndex != null && item.index != null) return "$show${SEPARATOR}S${item.parentIndex}E${item.index}"
    if (show != null) return show
    if (item.year != null) return item.editionTitle?.let { "${item.year}$SEPARATOR$it" } ?: "${item.year}"
    return item.kind.label
}

/**
 * The exact item a destructive action affects. [MediaItem.displayTitle] collapses an episode or season to its show's
 * name, so a show and one of its episodes would read the same in a delete confirmation; this names the
 * target: an episode's show, `S1 E2` and title, a season's show and title, else the title. Falls back to
 * [MediaItem.displayTitle] when every part is missing.
 */
fun formatMediaTargetLabel(item: MediaItem): String {
    val segments = when (item.kind) {
        MediaKind.EPISODE -> listOf(
            item.grandparentTitle,
            if (item.parentIndex != null && item.index != null) "S${item.parentIndex} E${item.index}" else null,
            item.title,
        )
        MediaKind.SEASON -> listOf(item.grandparentTitle ?: item.parentTitle, item.title)
        else -> listOf(item.title)
    }.filterNot { it.isNullOrEmpty() }
    return if (segments.isEmpty()) item.displayTitle else segments.joinToString(SEPARATOR)
}
