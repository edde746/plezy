package com.edde746.plezy.backend.net

import com.edde746.plezy.backend.MediaServerHttpException
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.launch

/**
 * The server a typed address leads to: [probe]'s answer for one of [candidates], what [expandBaseUrlCandidates] made
 * of the input (the URL as typed when it has a scheme, else its guesses). Every candidate is probed at once.
 *
 * HTTPS first: an `https` answer wins at once. An `http` answer wins only once every `https` candidate failed to
 * connect at all ([couldNotConnect]: refused, unreachable, timed out, or a port that doesn't speak TLS). A certificate
 * the device rejects, or an answer from an `https` server, ends the search with that failure: plaintext is then only
 * used when the user types `http://`.
 *
 * @throws Exception the failure that says most: a rejected certificate, else an answer from a server, else the first
 *   candidate's.
 */
internal suspend fun <T> resolveTypedAddress(candidates: List<String>, probe: suspend (baseUrl: String) -> T): T {
    require(candidates.isNotEmpty()) { "No address to probe" }
    return coroutineScope {
        val results = Channel<Pair<Int, Result<T>>>(candidates.size)
        val probes = candidates.mapIndexed { index, candidate ->
            launch {
                val result = try {
                    Result.success(probe(candidate))
                } catch (e: CancellationException) {
                    throw e
                } catch (e: Exception) {
                    Result.failure(e)
                }
                results.send(index to result)
            }
        }
        val secure = candidates.map { it.startsWith("https://") }
        val failures = arrayOfNulls<Throwable>(candidates.size)
        var pending = candidates.size
        var pendingSecure = secure.count { it }
        var plaintext: Result<T>? = null
        var outcome: Result<T>? = null
        while (outcome == null) {
            val (index, result) = results.receive()
            pending -= 1
            if (secure[index]) pendingSecure -= 1
            result.onFailure { failures[index] = it }
            when {
                result.isFailure -> Unit
                secure[index] -> outcome = result
                plaintext == null -> plaintext = result
            }
            if (outcome != null || pendingSecure > 0) continue
            val secureFailures = failures.filterIndexed { i, failure -> secure[i] && failure != null }.filterNotNull()
            outcome = when {
                secureFailures.any { !couldNotConnect(it) } -> Result.failure(mostTelling(secureFailures))
                plaintext != null -> plaintext
                pending == 0 -> Result.failure(mostTelling(failures.filterNotNull()))
                else -> null
            }
        }
        probes.forEach { it.cancel() }
        outcome!!.getOrThrow()
    }
}

/**
 * [error] never got as far as a server that speaks TLS: the connection was refused, unreachable or timed out, or the
 * TLS handshake failed for want of a TLS server. Never a certificate the device rejected, nor any answer.
 */
internal fun couldNotConnect(error: Throwable): Boolean =
    !isCertificateFailure(error) && generateSequence(error) { it.cause }.any { MediaServerHttpException.from(it).isTransient }

/** [error], or one of its causes, is the platform rejecting a server's certificate (its trust, dates or host name). */
internal expect fun isCertificateFailure(error: Throwable): Boolean

/** A rejected certificate, else an answer from a server, else the first of [failures]. */
private fun mostTelling(failures: List<Throwable>): Throwable =
    failures.firstOrNull(::isCertificateFailure) ?: failures.firstOrNull { !couldNotConnect(it) } ?: failures.first()
