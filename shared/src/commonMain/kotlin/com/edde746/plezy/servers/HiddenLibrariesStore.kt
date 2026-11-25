package com.edde746.plezy.servers

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

data class HiddenLibrariesState(
    /** Global keys of the hidden libraries. */
    val hiddenLibraryKeys: Set<String> = emptySet(),
    val isInitialized: Boolean = false,
)

/**
 * The hidden libraries of one profile ([profileId], or the active profile when null), shared by every screen. Loads
 * eagerly on construction.
 */
class HiddenLibrariesStore(
    private val preferences: LibraryPreferences,
    val profileId: String? = null,
    scope: CoroutineScope,
) {
    private val _state = MutableStateFlow(HiddenLibrariesState())
    val state: StateFlow<HiddenLibrariesState> = _state.asStateFlow()

    private var closed = false

    private val initJob = scope.launch { refresh() }

    val isInitialized: Boolean get() = _state.value.isInitialized
    val hiddenLibraryKeys: Set<String> get() = _state.value.hiddenLibraryKeys

    /** Suspends until the first load from storage finished. */
    suspend fun ensureInitialized() = initJob.join()

    suspend fun hideLibrary(libraryKey: String, checkCurrent: (() -> Unit)? = null) =
        setLibraryHidden(libraryKey, true, checkCurrent)

    suspend fun unhideLibrary(libraryKey: String, checkCurrent: (() -> Unit)? = null) =
        setLibraryHidden(libraryKey, false, checkCurrent)

    /**
     * Persists the new set, then publishes it. [checkCurrent] runs before and after persisting and throws to abort
     * when the profile changed meanwhile.
     */
    suspend fun setLibraryHidden(libraryKey: String, hidden: Boolean, checkCurrent: (() -> Unit)? = null) {
        ensureInitialized()
        if (closed) return
        checkCurrent?.invoke()
        val current = hiddenLibraryKeys
        if ((libraryKey in current) == hidden) return
        val next = if (hidden) current + libraryKey else current - libraryKey
        preferences.setHiddenLibraries(next, profileId)
        if (closed) return
        checkCurrent?.invoke()
        _state.value = HiddenLibrariesState(next, isInitialized = true)
    }

    /** Re-reads the hidden set from storage. */
    suspend fun refresh() {
        val keys = preferences.hiddenLibraries(profileId)
        if (closed) return
        _state.value = HiddenLibrariesState(keys, isInitialized = true)
    }

    /** Stops publishing; later calls are no-ops. */
    fun close() {
        closed = true
    }
}
