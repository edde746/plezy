package com.edde746.plezy.profiles

import com.edde746.plezy.data.connections.ConnectionStore
import com.edde746.plezy.log.Log
import com.edde746.plezy.servers.childScope
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.async
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlin.time.Clock

/**
 * The profiles to pick from (the local ones and one per cached Plex Home user, most recently used first) and the
 * active one, kept current as profiles, connections and Home users change.
 *
 * The active profile is the stored `active_app_profile_id`: none while no id is stored (the picker asks; the first
 * profile is never picked for the user), and none while the id matches no profile, with the id kept, as an early
 * snapshot may still miss it. The changes' values may also predate the active profile (its tables are read apart, so a
 * new profile's connection can show before the profile does): the active profile goes only once storage has it gone
 * too. Changes of the active profile ([activate], [restoreAfterFailedActivation], [clearActiveProfile]) run one at a
 * time, a newer one superseding those still waiting.
 *
 * Confined to [scope]'s thread.
 */
class ActiveProfileProvider(
    private val registry: ProfileRegistry,
    private val connections: ConnectionStore,
    private val identity: ProfileIdentity,
    private val plexHome: PlexHomeService,
    scope: CoroutineScope,
    private val clock: Clock,
) {
    private val work = scope.childScope()

    private val mutableProfiles = MutableStateFlow<List<Profile>>(emptyList())
    val profiles: StateFlow<List<Profile>> = mutableProfiles.asStateFlow()

    private val mutableActive = MutableStateFlow<Profile?>(null)
    val active: StateFlow<Profile?> = mutableActive.asStateFlow()

    private val mutableHydrated = MutableStateFlow(false)

    /** True once the local profiles, connections and cached Home users were read: [profiles] means something. */
    val hydrated: StateFlow<Boolean> = mutableHydrated.asStateFlow()

    /**
     * Called, on the changing coroutine, each time the active profile's id changes and after each committed
     * activation, also of the profile already active (the user picked it).
     */
    internal var onActiveChanged: () -> Unit = {}

    /** The newest change of the active profile asked for. */
    var mutationGeneration = 0
        private set

    /** The change of the active profile that was last stored; failed and superseded ones don't count. */
    var committedGeneration = 0
        private set

    private var pendingMutations = 0
    private val mutations = Mutex()

    private var locals: List<LocalProfile> = emptyList()
    private var connectionIds: Set<String> = emptySet()
    private var homeUsers: Map<String, List<PlexHomeUser>> = emptyMap()
    private var initialization: Deferred<Unit>? = null

    val hasMultipleProfiles: Boolean get() = profiles.value.size > 1

    /** Reads everything once, then follows changes. Runs once. */
    suspend fun initialize() {
        val pass = initialization ?: work.async {
            reloadSnapshot()
            work.launch {
                combine(registry.observe(), connections.observeSummaries().map { list -> list.map { it.id }.toSet() }, plexHome.users) { l, c, h ->
                    Triple(l, c, h)
                }.collect { (l, c, h) ->
                    locals = l
                    connectionIds = c
                    homeUsers = h
                    recompute()
                    resolveActive(fresh = false)
                }
            }
            Unit
        }.also { initialization = it }
        try {
            pass.await()
        } catch (e: Exception) {
            if (initialization === pass) initialization = null
            throw e
        }
    }

    /** Reads profiles, connections, Home users and the active id again: an import may have written them. */
    suspend fun reloadFromStorage() {
        initialize()
        plexHome.reloadFromStorage()
        reloadSnapshot()
    }

    /**
     * Claims the newest change of the active profile for a request that prepares before it changes anything (asks for a
     * PIN, checks one with plex.tv), superseding every change asked for before; pass the returned generation to
     * [activate]. The request may go on while [isRequestCurrent].
     */
    fun beginRequest(): Int = ++mutationGeneration

    /** Whether no change of the active profile was asked for since [generation] ([beginRequest]). */
    fun isRequestCurrent(generation: Int): Boolean = generation == mutationGeneration

    /**
     * Makes [profile] the active one: records its use, then stores its id. A PIN-protected local profile needs its
     * [pin]; a Plex Home profile's PIN is plex.tv's to check, when the binder switches to it. [request] is the
     * generation [beginRequest] claimed for it, if any. Returns false when the PIN is wrong or a newer change superseded
     * this one; a failed write throws, with the stored id put back.
     */
    suspend fun activate(profile: Profile, pin: String? = null, request: Int? = null): Boolean {
        if (profile is LocalProfile && profile.isPinProtected) {
            val hash = profile.pinHash
            if (pin == null || hash == null || !verifyPin(pin, hash)) return false
        }
        val generation = request ?: ++mutationGeneration
        return serialized {
            if (generation != mutationGeneration) return@serialized false
            val now = clock.now().toEpochMilliseconds()
            identity.markProfileUsed(profile.id, now)
            if (generation != mutationGeneration) return@serialized false
            val previous = identity.activeProfileId()
            writeMarker(profile.id, previous)
            if (generation != mutationGeneration) {
                restoreMarker(previous)
                return@serialized false
            }
            val activated = profile.withLastUsedAt(now)
            committedGeneration = generation
            mutableProfiles.value = sortProfilesByLastUsed(profiles.value.map { if (it.id == profile.id) activated else it })
            setActive(activated, committed = true)
            Log.i(TAG) { "Activated ${profile.displayName} (${profile.id})" }
            if (profile is LocalProfile) {
                work.launch {
                    try {
                        registry.markUsed(profile.id, now)
                    } catch (e: CancellationException) {
                        throw e
                    } catch (e: Exception) {
                        Log.w(TAG, e) { "Recording the use of ${profile.id} failed" }
                    }
                }
            }
            true
        }
    }

    /**
     * Makes [profile], the one active before a switch that failed to bind, active again, without its PIN: it was
     * unlocked already. Only while the failed profile [expectedActiveId] is still the one [expectedCommittedGeneration]
     * stored; returns the restoring change's generation, or null when something else happened meanwhile.
     */
    suspend fun restoreAfterFailedActivation(profile: Profile, expectedActiveId: String, expectedCommittedGeneration: Int): Int? {
        val generation = ++mutationGeneration
        return serialized {
            if (active.value?.id != expectedActiveId || committedGeneration != expectedCommittedGeneration || generation != mutationGeneration) {
                return@serialized null
            }
            val previous = identity.activeProfileId()
            writeMarker(profile.id, previous)
            if (generation != mutationGeneration) {
                restoreMarker(previous)
                return@serialized null
            }
            committedGeneration = generation
            mutableProfiles.value = sortProfilesByLastUsed(profiles.value.map { if (it.id == profile.id) profile else it })
            setActive(profile, committed = true)
            Log.i(TAG) { "Restored ${profile.displayName} (${profile.id}) after a failed switch" }
            generation
        }
    }

    /** Clears the active profile, stored and in memory, so the picker asks for one. */
    suspend fun clearActiveProfile() {
        val generation = ++mutationGeneration
        serialized {
            if (generation != mutationGeneration) return@serialized
            val previous = identity.activeProfileId()
            identity.clearActiveProfileId()
            if (generation != mutationGeneration) {
                restoreMarker(previous)
                return@serialized
            }
            committedGeneration = generation
            setActive(null)
        }
    }

    /** Stops following changes. */
    fun close() {
        work.cancel()
    }

    private suspend fun reloadSnapshot() {
        plexHome.hydrate()
        readSnapshot()
        resolveActive(fresh = true)
        mutableHydrated.value = true
    }

    private suspend fun readSnapshot() {
        locals = registry.list()
        connectionIds = connections.list().map { it.id }.toSet()
        homeUsers = plexHome.users.value
        recompute()
    }

    private suspend fun recompute() {
        val ids = locals.map { it.id } + homeUsers.flatMap { (connectionId, users) -> users.map { plexHomeProfileId(connectionId, it.uuid) } }
        mutableProfiles.value = mergeLocalWithPlexHome(locals, homeUsers, connectionIds, identity.profilesLastUsed(ids))
    }

    /** Sets the active profile from the stored id and [profiles], read from storage when [fresh], else from the changes. */
    private suspend fun resolveActive(fresh: Boolean) {
        if (pendingMutations > 0) return
        val committed = committedGeneration
        val id = identity.activeProfileId()
        // A change of the active profile that started meanwhile decides it.
        if (pendingMutations > 0 || committed != committedGeneration) return
        if (!fresh && id != null && id == active.value?.id && profiles.value.none { it.id == id }) {
            readSnapshot()
            if (pendingMutations > 0 || committed != committedGeneration) return
        }
        setActive(resolveActiveProfile(profiles.value, id))
    }

    private fun setActive(profile: Profile?, committed: Boolean = false) {
        val changed = active.value?.id != profile?.id
        mutableActive.value = profile
        if (changed || committed) onActiveChanged()
    }

    private suspend fun writeMarker(id: String, previous: String?) {
        try {
            identity.setActiveProfileId(id)
        } catch (e: Exception) {
            restoreMarker(previous)
            throw e
        }
    }

    private suspend fun restoreMarker(id: String?) {
        if (id == null) identity.clearActiveProfileId() else identity.setActiveProfileId(id)
    }

    private suspend fun <T> serialized(block: suspend () -> T): T {
        pendingMutations++
        try {
            return mutations.withLock { block() }
        } finally {
            pendingMutations--
        }
    }

    private companion object {
        const val TAG = "ActiveProfile"
    }
}
