package com.edde746.plezy.model

import com.edde746.plezy.strings.T

/**
 * The sorts the downloads screen offers, as [MediaSort]s for the shared sort sheet. The keys are local: they feed
 * [mediaItemSortComparator], not a server query. [includeDownloadFields] adds download date and file size, which need
 * the comparator's per-item download metadata.
 */
fun downloadSortOptions(includeDownloadFields: Boolean): List<MediaSort> = buildList {
    val labels = T.libraries.sortLabels
    add(MediaSort(MEDIA_SORT_KEY_TITLE, labels.title, defaultDirection = "asc"))
    add(MediaSort(MEDIA_SORT_KEY_DATE_ADDED, labels.dateAdded, defaultDirection = "desc"))
    add(MediaSort(MEDIA_SORT_KEY_RELEASE_DATE, labels.releaseDate, defaultDirection = "desc"))
    add(MediaSort(MEDIA_SORT_KEY_RATING, labels.rating, defaultDirection = "desc"))
    if (includeDownloadFields) {
        add(MediaSort(MEDIA_SORT_KEY_DOWNLOADED_AT, labels.dateDownloaded, defaultDirection = "desc"))
        add(MediaSort(MEDIA_SORT_KEY_SIZE, labels.size, defaultDirection = "desc"))
    }
    add(MediaSort(MEDIA_SORT_KEY_LIBRARY, labels.library, defaultDirection = "asc"))
}
