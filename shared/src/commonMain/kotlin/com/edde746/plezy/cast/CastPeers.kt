package com.edde746.plezy.cast

import com.edde746.plezy.log.Log
import com.edde746.plezy.secrets.SecretStore
import dev.whyoleg.cryptography.random.CryptographyRandom
import kotlin.io.encoding.Base64
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.serialization.Serializable
import kotlinx.serialization.builtins.ListSerializer

/** A device this one paired with, and the pairing [secret] (base64) both keep. */
@Serializable
internal data class RememberedPeer(val device: CastPeerInfo, val secret: String) {
    val secretBytes: ByteArray get() = Base64.decode(secret)

    override fun toString(): String = "RememberedPeer(${device.id}, ${device.name})"
}

/**
 * The devices this one paired with, one list per role (the senders a receiver lets in, the receivers a sender casts
 * to), newest first, at most [LIMIT]: in the secret store under [key], never in the database or a backup.
 */
internal class CastPeers(private val secrets: SecretStore, private val key: String) {
    private val lock = Mutex()
    private var loaded = false
    private val mutablePeers = MutableStateFlow<List<RememberedPeer>>(emptyList())

    /** The list as last read or written; [load] reads it first. */
    val peers: StateFlow<List<RememberedPeer>> = mutablePeers.asStateFlow()

    suspend fun load(): List<RememberedPeer> = lock.withLock { read() }

    suspend fun get(id: String): RememberedPeer? = load().firstOrNull { it.device.id == id }

    /** Remembers [peer], replacing the entry of its id; the oldest goes past [LIMIT]. */
    suspend fun remember(peer: RememberedPeer) = lock.withLock {
        write(listOf(peer) + read().filter { it.device.id != peer.device.id })
    }

    suspend fun forget(id: String) = lock.withLock {
        val peers = read()
        if (peers.any { it.device.id == id }) write(peers.filter { it.device.id != id })
    }

    private suspend fun read(): List<RememberedPeer> {
        if (loaded) return mutablePeers.value
        val stored = secrets.get(key)?.decodeToString()
        mutablePeers.value = stored?.let {
            try {
                castJson.decodeFromString(ListSerializer(RememberedPeer.serializer()), it)
            } catch (e: Exception) {
                Log.w(TAG, e) { "The remembered devices under $key didn't read: starting over" }
                null
            }
        }.orEmpty()
        loaded = true
        return mutablePeers.value
    }

    private suspend fun write(peers: List<RememberedPeer>) {
        val kept = peers.take(LIMIT)
        secrets.put(key, castJson.encodeToString(ListSerializer(RememberedPeer.serializer()), kept).encodeToByteArray())
        mutablePeers.value = kept
    }

    companion object {
        /** A secret-store value holds 4 KiB: about 25 entries. */
        const val LIMIT: Int = 16
        const val SENDERS: String = "cast.senders"
        const val RECEIVERS: String = "cast.receivers"
        private const val ID: String = "cast.id"
        private const val TAG = "CastPeers"
        private val idLock = Mutex()

        /**
         * This install's cast id: made once, kept in the secret store with the pairings it names. One call at a time, so
         * the receiver (which announces it) and the sender (which leaves it out of its picker) never make two.
         */
        suspend fun installId(secrets: SecretStore): String = idLock.withLock {
            secrets.get(ID)?.decodeToString() ?: CryptographyRandom.nextBytes(16)
                .joinToString("") { (it.toInt() and 0xFF).toString(16).padStart(2, '0') }
                .also { secrets.put(ID, it.encodeToByteArray()) }
        }
    }
}
