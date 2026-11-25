package com.edde746.plezy.profiles

import com.edde746.plezy.secrets.MemorySecretStore
import com.edde746.plezy.secrets.SecretStore
import kotlinx.coroutines.CompletableDeferred

/**
 * A [SecretStore] in memory whose next write a test can hold ([holdNextPut]) or fail ([failPutNumber]), or that can
 * stop working for good as the app would at its end ([crashAtOperation]) until [restart].
 */
internal class ControllableSecretStore : SecretStore {
    private val memory = MemorySecretStore()
    val entries: Map<String, ByteArray> get() = memory.entries

    private var puts = 0
    private var hold: CompletableDeferred<Unit>? = null
    private var held: CompletableDeferred<Unit>? = null
    private var released: CompletableDeferred<Unit>? = null
    private var operationsBeforeCrash: Int? = null
    private var crashed = false

    /** The 0-based number of the put that fails, counting from the store's creation. */
    var failPutNumber: Int? = null

    fun token(key: String): String? = memory.entries[key]?.decodeToString()

    /** The tokens stored, whatever their keys. */
    fun tokens(): Set<String> = memory.entries.values.map { it.decodeToString() }.toSet()

    /** Holds the next put until [release]; the returned signal completes once that put is waiting. */
    fun holdNextPut(): CompletableDeferred<Unit> {
        val gate = CompletableDeferred<Unit>()
        hold = gate
        released = gate
        return CompletableDeferred<Unit>().also { held = it }
    }

    fun release() {
        released?.complete(Unit)
    }

    /** The app ends at the [number]th put or delete from now (0-based): it and every later call fail, changing nothing. */
    fun crashAtOperation(number: Int) {
        operationsBeforeCrash = number
    }

    /** The app starts again: the store works, with what it held when it crashed. */
    fun restart() {
        crashed = false
        operationsBeforeCrash = null
    }

    override suspend fun get(key: String): ByteArray? {
        if (crashed) throw SimulatedCrash()
        return memory.get(key)
    }

    override suspend fun put(key: String, value: ByteArray) {
        operation()
        val number = puts++
        if (number == failPutNumber) throw IllegalStateException("The secret store is unavailable")
        val gate = hold
        if (gate != null) {
            hold = null
            held?.complete(Unit)
            gate.await()
        }
        memory.put(key, value)
    }

    override suspend fun delete(key: String) {
        operation()
        memory.delete(key)
    }

    override suspend fun deleteAll(prefix: String) {
        operation()
        memory.deleteAll(prefix)
    }

    private fun operation() {
        if (crashed) throw SimulatedCrash()
        val left = operationsBeforeCrash ?: return
        if (left == 0) {
            crashed = true
            throw SimulatedCrash()
        }
        operationsBeforeCrash = left - 1
    }
}

/** The app ended here ([ControllableSecretStore.crashAtOperation]). */
internal class SimulatedCrash : IllegalStateException("The app ended")
