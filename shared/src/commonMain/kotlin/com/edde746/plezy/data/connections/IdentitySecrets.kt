package com.edde746.plezy.data.connections

import com.edde746.plezy.data.Db
import com.edde746.plezy.data.Tx
import com.edde746.plezy.log.Log
import com.edde746.plezy.secrets.SecretStore
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.withContext
import kotlin.uuid.Uuid

/**
 * The tokens of the identity rows (connections and profile bindings), kept in the SecretStore under keys of the row's
 * secret version, never changed once written. A change writes its tokens under a new version, then commits the rows
 * naming it, then deletes the keys the rows named before; wherever it stops, each row names keys holding the tokens it
 * was committed with. The keys no row names are listed (`unreferenced_secrets`) in the transaction that frees them
 * (a new key before it's written) until they're deleted; [sweep] deletes those an interrupted change left.
 *
 * A null version is the unversioned keys an earlier release's import wrote.
 */
internal class IdentitySecrets(private val db: Db, private val secrets: SecretStore) {
    /**
     * Writes [fresh] (tokens by key, each under a version no row names yet), then runs [block] in one transaction,
     * which names them (or [IdentityTx.unreference]s those it didn't use) and unreferences the keys its rows stop
     * naming; those are deleted after the commit. When [block] fails, the keys it would have named are deleted again.
     */
    suspend fun <R> write(fresh: Map<String, String>, block: IdentityTx.() -> R): R {
        val result = try {
            if (fresh.isNotEmpty()) list(fresh.keys)
            fresh.forEach { (key, token) -> secrets.put(key, token.encodeToByteArray()) }
            // A commit that completed is never reported as failed: its rows name the new keys.
            withContext(NonCancellable) {
                db.write {
                    val tx = IdentityTx(this)
                    val result = tx.block()
                    fresh.keys.forEach { q.identitySecretQueries.deleteKey(it) }
                    tx.unreferenced.forEach { q.identitySecretQueries.insertKey(it) }
                    result to tx.unreferenced.toList()
                }
            }
        } catch (failure: Throwable) {
            withContext(NonCancellable) {
                try {
                    // Only those still listed: the transaction that would have named them didn't commit.
                    val listed = db.read { identitySecretQueries.selectAll().executeAsList() }.toSet()
                    delete(fresh.keys.filter { it in listed })
                } catch (cleanup: Exception) {
                    failure.addSuppressed(cleanup)
                }
            }
            throw failure
        }
        withContext(NonCancellable) {
            try {
                delete(result.second)
            } catch (e: Exception) {
                // Committed: the keys stay listed, and the next start deletes them.
                Log.w(TAG, e) { "Listing deleted tokens failed" }
            }
        }
        return result.first
    }

    /** Deletes the keys an interrupted change left unreferenced. Runs at start, before any identity change. */
    suspend fun sweep() {
        val keys = db.read { identitySecretQueries.selectAll().executeAsList() }
        if (keys.isEmpty()) return
        delete(keys)
        Log.i(TAG) { "Deleted ${keys.size} tokens an interrupted change left" }
    }

    private suspend fun list(keys: Collection<String>) {
        db.write { keys.forEach { q.identitySecretQueries.insertKey(it) } }
    }

    /** Deletes unreferenced [keys] from the SecretStore, then from the list; one that fails stays listed for [sweep]. */
    private suspend fun delete(keys: Collection<String>) {
        if (keys.isEmpty()) return
        val deleted = keys.filter { key ->
            try {
                secrets.delete(key)
                true
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Deleting an unreferenced token failed; the next start deletes it" }
                false
            }
        }
        if (deleted.isNotEmpty()) db.write { deleted.forEach { q.identitySecretQueries.deleteKey(it) } }
    }

    private companion object {
        const val TAG = "identity-secrets"
    }
}

/** An identity transaction: [tx], and the SecretStore keys its rows stopped naming. */
internal class IdentityTx(val tx: Tx) {
    internal val unreferenced = LinkedHashSet<String>()

    fun unreference(keys: Iterable<String>) {
        unreferenced += keys
    }
}

/** A secret version no row names yet. */
internal fun newSecretVersion(): String = Uuid.random().toHexString()
