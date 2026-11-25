package com.edde746.plezy.backend.net

import com.edde746.plezy.backend.MediaServerTimeouts
import com.edde746.plezy.log.Log
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.launch
import kotlinx.coroutines.selects.onTimeout
import kotlinx.coroutines.selects.select
import kotlin.time.Duration
import kotlin.time.TimeSource

enum class EndpointRacePhase { FIRST, BEST }

/**
 * One answer of [raceEndpointCandidates]: the [FIRST][EndpointRacePhase.FIRST] working endpoint to connect with at once,
 * then possibly the [BEST][EndpointRacePhase.BEST] one after measuring every candidate.
 */
data class EndpointRaceSelection<C, R>(
    val phase: EndpointRacePhase,
    val candidate: C,
    val result: R,
    val fromPreferred: Boolean = false,
    val successfulResults: Map<C, R> = emptyMap(),
)

/**
 * Races [candidates] for a working endpoint.
 *
 * Phase 1: the [preferredUrl] (the last good endpoint), when it maps to a candidate of tier 0, is probed first with
 * [preferredTimeout]; answering within [preferredHeadStart] wins at once. A failure inside the head start falls back to
 * the plain race; still pending, it joins the race with its probe kept. In the race every candidate is probed with
 * [raceTimeout]; a success wins unless a lower (better) [tierOf] tier still has probes pending, in which case it is held
 * and accepted only once every lower tier failed (a slow direct endpoint beats a fast relay). The first winner is
 * emitted as [EndpointRacePhase.FIRST].
 *
 * Phase 2: every candidate is [measure]d; when any succeed, [selectBestCandidate]'s pick is emitted as
 * [EndpointRacePhase.BEST]. Nothing is emitted when no candidate works. A probe that throws counts as failed.
 */
fun <C, R> raceEndpointCandidates(
    label: String,
    candidates: List<C>,
    urlOf: (C) -> String,
    probe: suspend (candidate: C, timeout: Duration) -> R,
    measure: suspend (candidate: C) -> R,
    isSuccess: (R) -> Boolean,
    selectBestCandidate: (Map<C, R>) -> C?,
    preferredUrl: String? = null,
    candidateForUrl: ((String) -> C?)? = null,
    tierOf: ((C) -> Int)? = null,
    displayTypeOf: ((C) -> String)? = null,
    onFirstSuccess: ((C, R) -> Unit)? = null,
    preferredTimeout: Duration = MediaServerTimeouts.PREFERRED_ENDPOINT_PROBE,
    preferredHeadStart: Duration = MediaServerTimeouts.PREFERRED_ENDPOINT_HEAD_START,
    raceTimeout: Duration = MediaServerTimeouts.CONNECTION_RACE,
): Flow<EndpointRaceSelection<C, R>> = flow {
    if (candidates.isEmpty()) {
        Log.w(TAG) { "No endpoint candidates available for $label discovery" }
        return@flow
    }
    val started = TimeSource.Monotonic.markNow()
    var first: Pair<C, R>? = null
    var fromPreferred = false
    coroutineScope {
        var cached: C? = if (preferredUrl.isNullOrEmpty()) {
            null
        } else {
            candidateForUrl?.invoke(preferredUrl) ?: candidates.firstOrNull { urlOf(it) == preferredUrl }
        }
        if (cached != null && tierOf != null && tierOf(cached) > 0) {
            // A fallback-tier endpoint never wins the head start: it races so better tiers can beat it.
            Log.d(TAG) { "Cached $label endpoint is fallback-tier, racing without a head start" }
            cached = null
        }
        var pendingCached: Deferred<R?>? = null
        if (cached != null) {
            val cachedProbe = async { probeOrNull(probe, cached, preferredTimeout) }
            val headStart = select<HeadStart<R>> {
                cachedProbe.onAwait { HeadStart.Settled(it) }
                onTimeout(preferredHeadStart) { HeadStart.Pending }
            }
            when {
                headStart is HeadStart.Settled && headStart.result != null && isSuccess(headStart.result) -> {
                    Log.i(TAG) { "Cached $label endpoint succeeded, using immediately (${started.elapsedNow()})" }
                    first = cached to headStart.result
                    fromPreferred = true
                    onFirstSuccess?.invoke(cached, headStart.result)
                }
                headStart is HeadStart.Settled -> Log.w(TAG) { "Cached $label endpoint failed, falling back to candidate race" }
                else -> {
                    Log.d(TAG) { "Cached $label endpoint still pending after head start, racing all candidates" }
                    pendingCached = cachedProbe
                }
            }
        }
        if (first == null) {
            val merged = if (pendingCached != null) cached else null
            val raceCandidates = if (merged == null) candidates else listOf(merged) + candidates.filter { urlOf(it) != preferredUrl }
            val winner = raceFirstSuccess(label, raceCandidates, tierOf, displayTypeOf, isSuccess) { candidate ->
                if (merged != null && candidate === merged) pendingCached!!.await() else probeOrNull(probe, candidate, raceTimeout)
            }
            if (winner == null) {
                Log.e(TAG) { "No working $label endpoints after race (${raceCandidates.size} candidates, ${started.elapsedNow()})" }
            } else {
                onFirstSuccess?.invoke(winner.first, winner.second)
                first = winner
                fromPreferred = merged != null && winner.first === merged
                Log.i(TAG) { "$label race found first working endpoint (${winner.first.let { displayTypeOf?.invoke(it) }}, preferred=$fromPreferred, ${started.elapsedNow()})" }
            }
        }
        pendingCached?.cancel()
    }
    val (firstCandidate, firstResult) = first ?: return@flow
    emit(EndpointRaceSelection(EndpointRacePhase.FIRST, firstCandidate, firstResult, fromPreferred, mapOf(firstCandidate to firstResult)))

    val measured = coroutineScope {
        candidates.map { candidate -> async { candidate to runCatchingProbe { measure(candidate) } } }.awaitAll()
    }
    val successful = LinkedHashMap<C, R>()
    for ((candidate, result) in measured) if (result != null && isSuccess(result)) successful[candidate] = result
    if (successful.isEmpty()) {
        Log.w(TAG) { "$label latency sweep found no additional working endpoints" }
        return@flow
    }
    val best = selectBestCandidate(successful) ?: return@flow
    val bestResult = successful[best] ?: return@flow
    emit(EndpointRaceSelection(EndpointRacePhase.BEST, best, bestResult, successfulResults = successful.toMap()))
}

private sealed interface HeadStart<out R> {
    data class Settled<R>(val result: R?) : HeadStart<R>

    data object Pending : HeadStart<Nothing>
}

private suspend fun <C, R> probeOrNull(probe: suspend (C, Duration) -> R, candidate: C, timeout: Duration): R? =
    runCatchingProbe { probe(candidate, timeout) }

private suspend fun <R> runCatchingProbe(block: suspend () -> R): R? = try {
    block()
} catch (e: CancellationException) {
    throw e
} catch (e: Exception) {
    // The type only: probe errors carry the endpoint's host and path.
    Log.w(TAG) { "Endpoint candidate threw during race (${e::class.simpleName})" }
    null
}

/** The first success under the tier-holding rule, or null when every candidate failed. Losing probes are cancelled. */
private suspend fun <C, R> raceFirstSuccess(
    label: String,
    candidates: List<C>,
    tierOf: ((C) -> Int)?,
    displayTypeOf: ((C) -> String)?,
    isSuccess: (R) -> Boolean,
    probe: suspend (C) -> R?,
): Pair<C, R>? = coroutineScope {
    fun tierFor(candidate: C) = tierOf?.invoke(candidate) ?: 0
    val pendingByTier = mutableMapOf<Int, Int>()
    for (candidate in candidates) pendingByTier[tierFor(candidate)] = (pendingByTier[tierFor(candidate)] ?: 0) + 1
    val outcome = CompletableDeferred<Pair<C, R>?>()
    var held: Triple<C, R, Int>? = null

    fun lowerTierPending(tier: Int) = pendingByTier.any { (key, count) -> key < tier && count > 0 }

    fun settle() {
        if (outcome.isCompleted) return
        val fallback = held
        if (fallback != null && !lowerTierPending(fallback.third)) {
            Log.i(TAG) { "$label fallback-tier endpoint accepted after preferred tiers failed (${displayTypeOf?.invoke(fallback.first)})" }
            outcome.complete(fallback.first to fallback.second)
            return
        }
        if (pendingByTier.values.all { it == 0 }) outcome.complete(null)
    }

    val probes = candidates.map { candidate ->
        val tier = tierFor(candidate)
        launch {
            val result = probe(candidate)
            pendingByTier[tier] = pendingByTier.getValue(tier) - 1
            if (result == null || !isSuccess(result)) {
                Log.w(TAG) { "$label endpoint candidate failed (${displayTypeOf?.invoke(candidate)})" }
                settle()
                return@launch
            }
            if (outcome.isCompleted) return@launch
            if (!lowerTierPending(tier)) {
                outcome.complete(candidate to result)
                return@launch
            }
            val current = held
            if (current == null || tier < current.third) {
                Log.d(TAG) { "$label fallback-tier endpoint succeeded, holding while preferred tiers race" }
                held = Triple(candidate, result, tier)
            }
        }
    }
    val winner = outcome.await()
    probes.forEach { it.cancel() }
    winner
}

private const val TAG = "EndpointRace"
