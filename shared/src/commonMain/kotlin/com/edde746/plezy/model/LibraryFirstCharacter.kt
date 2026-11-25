package com.edde746.plezy.model

/**
 * One entry of the alpha-jump bar: a letter (or `#` for titles starting with a digit or symbol) and how many items
 * start with it. Plex serves these with real counts, which the bar scrolls by; Jellyfin and Emby have none, so they get a
 * synthetic 27-entry alphabet with [size] 1 each and the bar filters by name prefix instead.
 */
data class LibraryFirstCharacter(val key: String, val title: String, val size: Int)
