package com.edde746.plezy.app

import com.edde746.plezy.model.MediaItem

/** Continue Watching as the system's shelves take it ([AppSession.continueWatching]): [items] of profile [profileId]. */
data class ContinueWatchingShelf(val profileId: String, val items: List<MediaItem>)
