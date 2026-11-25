package com.edde746.plezy.servers

import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.parseGlobalKey

/**
 * Per-profile library preferences: the saved library order and the hidden libraries, both lists of library global
 * keys (`serverId:libraryId`), stored under `user_<scope>_library_order` and `user_<scope>_hidden_libraries`.
 *
 * A null `profileId` means the active profile; reading it adopts a legacy unscoped value once (copied into the
 * scoped key, unscoped key removed). An explicit `profileId` other than the active one never adopts legacy values.
 */
interface LibraryPreferences {
    /** The saved order; null when none was saved. */
    suspend fun libraryOrder(profileId: String? = null): List<String>?

    suspend fun setLibraryOrder(keys: List<String>, profileId: String? = null)

    suspend fun hiddenLibraries(profileId: String? = null): Set<String>

    suspend fun setHiddenLibraries(keys: Set<String>, profileId: String? = null)

    /**
     * Drops [serverId]'s entries (see [withoutServer]) from the order and hidden lists of every profile scope and
     * the legacy unscoped slots, so re-adding the server later doesn't revive old choices.
     */
    suspend fun removeServerEverywhere(serverId: ServerId)
}

/** These global keys without those of libraries on [serverId]. */
fun Iterable<String>.withoutServer(serverId: ServerId): List<String> = filterNot { parseGlobalKey(it)?.first == serverId }
