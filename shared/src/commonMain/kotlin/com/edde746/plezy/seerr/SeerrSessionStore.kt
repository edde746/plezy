package com.edde746.plezy.seerr

import com.edde746.plezy.log.Log
import com.edde746.plezy.log.LogRedaction
import com.edde746.plezy.profiles.profileUserScope
import com.edde746.plezy.secrets.SecretStore
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

/** The `SecretStore` key prefix of a profile scope's Seerr session ([SeerrSessionStore]). */
internal const val SEERR_SESSION_SECRET_PREFIX = "seerr_session."

/**
 * Each profile's Seerr session, kept as its JSON ([SeerrSession.encode], password included) in the secret store under
 * `seerr_session.<scope>`, the scope being [profileUserScope]: a Plex Home user's profiles share one session.
 *
 * Every operation runs in call order across the process ([lock]), so an account store made after another was closed
 * can't read before, or write under, the closed one's pending save. The secret store's own failures propagate; a
 * stored value that doesn't decode reads as no session.
 */
class SeerrSessionStore(private val secrets: SecretStore) {
    suspend fun load(profileId: String): SeerrSession? {
        lock.withLock {
            val bytes = secrets.get(key(profileId)) ?: return null
            val session = try {
                SeerrSession.decode(bytes.decodeToString())
            } catch (e: IllegalArgumentException) {
                // SerializationException included.
                Log.w(TAG) { "stored Seerr session unreadable: ${e::class.simpleName}" }
                return null
            }
            registerSecrets(session)
            return session
        }
    }

    suspend fun save(profileId: String, session: SeerrSession) = lock.withLock {
        registerSecrets(session)
        secrets.put(key(profileId), session.encode().encodeToByteArray())
    }

    suspend fun clear(profileId: String) = lock.withLock { secrets.delete(key(profileId)) }

    /** Clears the session of the profile scope [scope] ([profileUserScope]) itself. */
    suspend fun clearScope(scope: String) = lock.withLock { secrets.delete(SEERR_SESSION_SECRET_PREFIX + scope) }

    private fun registerSecrets(session: SeerrSession) {
        LogRedaction.registerCustomValue(session.cookie)
        LogRedaction.registerCustomValue(session.secret)
    }

    private companion object {
        const val TAG = "seerr"

        /** Process-wide: every store instance's operations queue on it, in call order. */
        val lock = Mutex()

        fun key(profileId: String): String = SEERR_SESSION_SECRET_PREFIX + profileUserScope(profileId)
    }
}
