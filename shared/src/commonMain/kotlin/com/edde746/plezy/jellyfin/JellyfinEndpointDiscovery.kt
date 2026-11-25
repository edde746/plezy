package com.edde746.plezy.jellyfin

import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.MediaServerTimeouts
import com.edde746.plezy.backend.MediaServerUrlException
import com.edde746.plezy.backend.net.BaseUrlGuess
import com.edde746.plezy.backend.net.EndpointRacePhase
import com.edde746.plezy.backend.net.EndpointRaceSelection
import com.edde746.plezy.backend.net.canonicalizeBaseUrl
import com.edde746.plezy.backend.net.expandBaseUrlCandidates
import com.edde746.plezy.backend.net.hasUrlScheme
import com.edde746.plezy.backend.net.isCertificateFailure
import com.edde746.plezy.backend.net.MediaServerHttpClient
import com.edde746.plezy.backend.net.raceEndpointCandidates
import com.edde746.plezy.backend.net.resolveTypedAddress
import com.edde746.plezy.backend.net.throwIfHttpError
import com.edde746.plezy.model.MediaBrowserDialect
import com.edde746.plezy.log.Log
import com.edde746.plezy.log.LogRedaction
import com.edde746.plezy.strings.T
import io.ktor.client.HttpClient
import io.ktor.http.HttpHeaders
import io.ktor.http.URLBuilder
import io.ktor.http.encodedPath
import io.ktor.http.Url
import io.ktor.http.takeFrom
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.serialization.json.JsonObject
import kotlin.time.Duration
import kotlin.time.TimeSource

/** What `/System/Info/Public` says about a server. [dialect] is null when the response names neither product. */
data class JellyfinServerInfo(
    val serverName: String,
    val machineId: String,
    val version: String,
    val dialect: MediaBrowserDialect? = null,
)

/**
 * What was typed into a form, one entry per URL: [explicitBaseUrls] were typed with a scheme (probed as typed, and the
 * only ones kept), [bareEntryGuesses] holds each entry typed without one as its guesses.
 */
data class JellyfinEndpointUserInputCandidates(
    val explicitBaseUrls: List<String>,
    val bareEntryGuesses: List<List<String>>,
) {
    val isEmpty: Boolean get() = explicitBaseUrls.isEmpty() && bareEntryGuesses.isEmpty()
}

/**
 * A finished endpoint race. [baseUrls] is active-first; candidates that reported another machine are dropped, ones
 * that returned no identity are kept for a later retry.
 */
class JellyfinEndpointRaceResult internal constructor(
    val activeBaseUrl: String,
    val baseUrls: List<String>,
    val serverInfo: JellyfinServerInfo,
    private val verifiedEffectiveBaseUrls: Map<String, String>,
    private val machineMismatchBaseUrls: Set<String>,
) {
    /**
     * An existing connection's stored URLs after a partial race: verified ones become their effective URL, other
     * machines are dropped, unverified ones stay. Fresh user input uses [baseUrls] instead.
     */
    fun reconcilePreviouslyStoredBaseUrls(storedBaseUrls: Iterable<String>): List<String> {
        val retained = JellyfinEndpointDiscovery.normalizeBaseUrls(storedBaseUrls).mapNotNull { url ->
            verifiedEffectiveBaseUrls[url] ?: url.takeUnless { it in machineMismatchBaseUrls }
        }
        return activeFirst(activeBaseUrl, retained)
    }
}

/** Unauthenticated probing and racing of MediaBrowser (Jellyfin/Emby) server URLs; latency is measured on [timeSource]. */
class JellyfinEndpointDiscovery(
    private val http: HttpClient,
    val dialect: MediaBrowserDialect = MediaBrowserDialect.JELLYFIN,
    private val timeSource: TimeSource = TimeSource.Monotonic,
) {

    private data class Candidate(val url: String, val index: Int)

    private class ProbeResult(
        val success: Boolean,
        val latencyMs: Long,
        val serverInfo: JellyfinServerInfo? = null,
        val effectiveBaseUrl: String? = null,
    )

    private class Probed(val serverInfo: JellyfinServerInfo, val effectiveBaseUrl: String)

    /** The server at [baseUrl], without authenticating. Every failure is a [MediaServerUrlException]. */
    suspend fun probe(baseUrl: String, timeout: Duration = MediaServerTimeouts.JELLYFIN_PROBE): JellyfinServerInfo =
        probeServer(baseUrl, timeout).serverInfo

    private suspend fun probeServer(baseUrl: String, timeout: Duration): Probed {
        val requested = normalizeBaseUrl(baseUrl)
        val product = dialect.productName
        // Before any traffic: a self-hosted origin never reaches a log line, not even a failed probe's warning.
        LogRedaction.registerServerUrl(requested)
        try {
            val response = MediaServerHttpClient(http, requested).get(PUBLIC_INFO_PATH, timeout = timeout)
            // The client does not follow an HTTPS downgrade; judge such a redirect by its target instead.
            val location = response.headers.entries.firstOrNull { it.key.equals(HttpHeaders.Location, ignoreCase = true) }?.value
            if (response.statusCode in 300..399 && location != null) {
                resolveEffectiveBaseUrl(requested, response.requestUri, URLBuilder(response.requestUri).takeFrom(location).build())
            }
            throwIfHttpError(response)
            val effectiveBaseUrl = resolveEffectiveBaseUrl(requested, response.requestUri, response.effectiveUri)
            LogRedaction.registerServerUrl(effectiveBaseUrl)
            val data = response.data as? JsonObject
                ?: throw MediaServerUrlException("Server response was not JSON", T.addServer.responseNotJson)
            val id = data.str("Id")
            val name = data.str("ServerName") ?: data.str("LocalAddress")
            if (id == null || name == null) {
                throw MediaServerUrlException(
                    "Server response missing Id/ServerName — not a $product server?",
                    T.addServer.responseMissingIdentity(product = product),
                )
            }
            val info = JellyfinServerInfo(
                serverName = name,
                machineId = id,
                version = data.str("Version").orEmpty(),
                dialect = MediaBrowserDialect.detectFromPublicSystemInfo(data.str("ProductName"), "RemoteAddresses" in data),
            )
            return Probed(info, effectiveBaseUrl)
        } catch (e: MediaServerUrlException) {
            throw e
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            val failure = MediaServerHttpException.from(e)
            if (failure.isCancellation) throw failure
            if (isCertificateFailure(e)) {
                throw MediaServerUrlException("Server certificate rejected: ${failure.message}", T.addServer.untrustedCertificate(url = requested), failure)
            }
            if (failure.type == MediaServerHttpErrorType.CONNECTION_TIMEOUT || failure.type == MediaServerHttpErrorType.RECEIVE_TIMEOUT) {
                throw MediaServerUrlException("Server did not respond in time", T.addServer.serverTimedOut, failure)
            }
            throw MediaServerUrlException("Server probe failed: ${failure.message}", T.addServer.probeFailed(error = failure.message.orEmpty()), failure)
        }
    }

    /**
     * Races what was typed into a form: each URL typed with a scheme as typed, each bare entry as the guess
     * [resolveTypedAddress] accepts (HTTPS first; plain HTTP only when no HTTPS guess could connect at all). Only the
     * typed URLs are kept, besides the active one. A bare entry none of whose guesses is accepted is left out; the
     * entries left must all reach one server.
     *
     * @throws MediaServerUrlException a bare entry's certificate failure when nothing is left to race, else as
     *   [raceEndpoints] does.
     */
    suspend fun raceUserInput(
        input: JellyfinEndpointUserInputCandidates,
        preferredUrl: String? = null,
        expectedMachineId: String? = null,
    ): JellyfinEndpointRaceResult {
        val resolved = coroutineScope {
            input.bareEntryGuesses.map { guesses ->
                async {
                    try {
                        Result.success(resolveTypedAddress(guesses) { url -> url.also { probe(it) } })
                    } catch (e: CancellationException) {
                        throw e
                    } catch (e: Exception) {
                        Log.w(TAG, e) { "No guess for a typed address was accepted" }
                        Result.failure(e)
                    }
                }
            }.awaitAll()
        }
        val urls = input.explicitBaseUrls + resolved.mapNotNull { it.getOrNull() }
        if (urls.isEmpty()) {
            val product = dialect.productName
            throw resolved.firstNotNullOfOrNull { result -> result.exceptionOrNull()?.takeIf(::isCertificateFailure) }
                ?: MediaServerUrlException("No reachable $product server found", T.addServer.noReachableServer(product = product))
        }
        val separateEntries = if (urls.size > 1) urls else emptyList()
        return raceEndpoints(urls, preferredUrl, expectedMachineId, baseUrlsToPersist = input.explicitBaseUrls, baseUrlsToValidate = separateEntries)
    }

    /**
     * Races public probes of [baseUrls] and returns persistence-safe endpoints. [expectedMachineId] pins the server;
     * [baseUrlsToPersist] picks what is stored; identity mismatches are checked across [baseUrlsToValidate].
     */
    suspend fun raceEndpoints(
        baseUrls: Iterable<String>,
        preferredUrl: String? = null,
        expectedMachineId: String? = null,
        baseUrlsToPersist: Iterable<String>? = null,
        baseUrlsToValidate: Iterable<String>? = null,
    ): JellyfinEndpointRaceResult {
        val product = dialect.productName
        val urls = normalizeBaseUrls(baseUrls)
        if (urls.isEmpty()) {
            throw MediaServerUrlException("Enter at least one $product server URL", T.addServer.enterAtLeastOneUrl(product = product))
        }
        val persistUrls = baseUrlsToPersist?.let(::normalizeBaseUrls) ?: urls
        val validateUrls = (baseUrlsToValidate?.let(::normalizeBaseUrls) ?: urls).toSet()
        val preferred = preferredUrl?.takeIf { it.isNotBlank() }?.let(::normalizeBaseUrl)
        val candidates = urls.mapIndexed { i, url -> Candidate(url, i) }

        val lock = Mutex()
        val identityResults = mutableMapOf<Candidate, ProbeResult>()
        suspend fun record(candidate: Candidate, result: ProbeResult): ProbeResult {
            if (result.serverInfo != null) lock.withLock { identityResults[candidate] = result }
            return result
        }

        var first: EndpointRaceSelection<Candidate, ProbeResult>? = null
        var best: EndpointRaceSelection<Candidate, ProbeResult>? = null
        // The first-success race returns while slower phase-one probes still run (each bounded by the race timeout).
        // They run in this scope, so it waits for their identities before persisted fallbacks are filtered.
        coroutineScope {
            raceEndpointCandidates(
                label = "$product server URL",
                candidates = candidates,
                urlOf = { it.url },
                probe = { candidate, timeout -> async { record(candidate, probeWithLatency(candidate.url, timeout)) }.await() },
                measure = { candidate -> record(candidate, probeWithAverageLatency(candidate.url, attempts = 2)) },
                isSuccess = { it.success },
                selectBestCandidate = ::lowestLatency,
                preferredUrl = preferred,
            ).collect { selection ->
                if (selection.phase == EndpointRacePhase.FIRST) first = selection else best = selection
            }
        }

        val selected = (best ?: first)?.takeIf { it.result.serverInfo != null }
            ?: throw MediaServerUrlException("No reachable $product server found", T.addServer.noReachableServer(product = product))
        val successfulResults = selected.successfulResults
        var selectedCandidate = selected.candidate
        var selectedResult = selected.result

        val expectedId = expectedMachineId?.trim()?.takeIf { it.isNotEmpty() }
        if (expectedId != null) {
            val matching = successfulResults.filterValues { it.serverInfo?.machineId == expectedId }
            lowestLatency(matching)?.let {
                selectedCandidate = it
                selectedResult = matching.getValue(it)
            }
        }
        val selectedInfo = selectedResult.serverInfo
            ?: throw MediaServerUrlException("No reachable $product server found", T.addServer.noReachableServer(product = product))

        val expected = expectedId ?: selectedInfo.machineId
        val differentServers = MediaServerUrlException(
            "The URLs point to different $product servers",
            T.addServer.urlsPointToDifferentServers(product = product),
        )
        for ((candidate, result) in identityResults) {
            if (candidate.url !in validateUrls) continue
            val info = result.serverInfo
            if (info != null && info.machineId != expected) throw differentServers
        }
        if (selectedInfo.machineId != expected) {
            throw MediaServerUrlException(
                "The URL does not match this $product server",
                T.addServer.urlDoesNotMatchServer(product = product),
            )
        }

        val effectiveUrls = mutableMapOf<String, String>()
        val mismatched = mutableSetOf<String>()
        for ((candidate, result) in identityResults) {
            if (result.serverInfo?.machineId != expected) {
                mismatched += candidate.url
                continue
            }
            result.effectiveBaseUrl?.let { effectiveUrls[candidate.url] = it }
        }
        val activeBaseUrl = selectedResult.effectiveBaseUrl ?: selectedCandidate.url
        effectiveUrls[selectedCandidate.url] = activeBaseUrl
        val persisted = persistUrls.filter { it !in mismatched }.map { effectiveUrls[it] ?: it }
        return JellyfinEndpointRaceResult(activeBaseUrl, activeFirst(activeBaseUrl, persisted), selectedInfo, effectiveUrls, mismatched)
    }

    private suspend fun probeWithLatency(baseUrl: String, timeout: Duration): ProbeResult {
        val start = timeSource.markNow()
        return try {
            val probed = probeServer(baseUrl, timeout)
            ProbeResult(true, start.elapsedNow().inWholeMilliseconds, probed.serverInfo, probed.effectiveBaseUrl)
        } catch (e: MediaServerUrlException) {
            Log.w(TAG, e) { "Probing $baseUrl failed" }
            ProbeResult(false, start.elapsedNow().inWholeMilliseconds)
        }
    }

    /** Average latency over [attempts] sequential probes; a failure ends it, keeping the identity seen so far. */
    private suspend fun probeWithAverageLatency(baseUrl: String, attempts: Int): ProbeResult {
        var total = 0L
        var info: JellyfinServerInfo? = null
        var effective: String? = null
        repeat(attempts) {
            val result = probeWithLatency(baseUrl, MediaServerTimeouts.CONNECTION_RACE)
            if (!result.success) return ProbeResult(false, result.latencyMs, info, effective)
            info = result.serverInfo
            effective = result.effectiveBaseUrl
            total += result.latencyMs
        }
        return ProbeResult(true, total / attempts, info, effective)
    }

    private fun lowestLatency(results: Map<Candidate, ProbeResult>): Candidate? =
        results.entries.minWithOrNull(compareBy({ it.value.latencyMs }, { it.key.index }))?.key

    /**
     * The base URL a redirect landed on. Only same-host redirects to the same info path are trusted, and never a
     * downgrade from HTTPS: anything else must be entered directly.
     */
    private fun resolveEffectiveBaseUrl(requestedBaseUrl: String, requestedUrl: Url, effectiveUrl: Url): String {
        if (effectiveUrl == requestedUrl) return requestedBaseUrl
        val product = dialect.productName
        val scheme = effectiveUrl.protocol.name.lowercase()
        if (requestedUrl.host.isEmpty() || (scheme != "http" && scheme != "https")) {
            throw MediaServerUrlException("Server redirected to an unsupported URL", T.addServer.redirectUnsupported)
        }
        if (!requestedUrl.host.equals(effectiveUrl.host, ignoreCase = true)) {
            throw MediaServerUrlException(
                "Server redirected to a different host. Enter the final $product URL directly",
                T.addServer.redirectDifferentHost(product = product),
            )
        }
        if (requestedUrl.protocol.name.lowercase() == "https" && scheme != "https") {
            throw MediaServerUrlException("Server redirected from HTTPS to an insecure URL", T.addServer.redirectInsecure)
        }
        val path = effectiveUrl.encodedPath
        if (!path.endsWith(PUBLIC_INFO_PATH)) {
            throw MediaServerUrlException(
                "Server redirected to an unsupported URL. Enter the final $product URL directly",
                T.addServer.redirectUnsupportedEnterFinal(product = product),
            )
        }
        val base = URLBuilder(effectiveUrl).apply {
            encodedPath = path.dropLast(PUBLIC_INFO_PATH.length)
            parameters.clear()
            fragment = ""
        }.buildString()
        return normalizeBaseUrl(base)
    }

    companion object {
        const val DEFAULT_PORT = 8096
        private const val PUBLIC_INFO_PATH = "/System/Info/Public"
        private const val TAG = "JellyfinEndpointDiscovery"

        /** A concrete base URL, canonicalized; no scheme or port is invented. */
        fun normalizeBaseUrl(input: String): String = canonicalizeBaseUrl(input)

        /**
         * Probe guesses for a bare form entry, HTTPS first: TLS on the default and the dialect's TLS ports, then the
         * default HTTP port (the common LAN install) and plain HTTP. Guesses are never stored unverified.
         */
        fun expandInputToBaseUrls(input: String, dialect: MediaBrowserDialect = MediaBrowserDialect.JELLYFIN): List<String> =
            expandBaseUrlCandidates(
                input,
                listOf(BaseUrlGuess("https", null)) +
                    dialect.httpsPortGuesses.map { BaseUrlGuess("https", it) } +
                    BaseUrlGuess("http", DEFAULT_PORT) +
                    BaseUrlGuess("http", null),
            )

        /** The URLs typed into one form field, separated by newlines and/or commas. */
        fun parseUserEnteredUrls(raw: String): List<String> =
            raw.split(Regex("[\\n,]+")).map { it.trim() }.filter { it.isNotEmpty() }

        fun buildUserInputCandidates(
            input: Iterable<String>,
            dialect: MediaBrowserDialect = MediaBrowserDialect.JELLYFIN,
        ): JellyfinEndpointUserInputCandidates {
            val explicit = LinkedHashSet<String>()
            val bare = mutableListOf<List<String>>()
            for (raw in input) {
                val normalized = normalizeBaseUrl(raw)
                if (normalized.isEmpty()) continue
                if (hasUrlScheme(normalized)) {
                    explicit += normalized
                } else {
                    val guesses = expandInputToBaseUrls(normalized, dialect).map(::normalizeBaseUrl).filter { it.isNotEmpty() }
                    if (guesses.isNotEmpty()) bare += guesses
                }
            }
            return JellyfinEndpointUserInputCandidates(explicit.toList(), bare)
        }

        /** Canonicalized, blanks dropped, first occurrence kept. */
        fun normalizeBaseUrls(input: Iterable<String>): List<String> =
            input.map(::normalizeBaseUrl).filter { it.isNotEmpty() }.distinct()
    }
}

private fun activeFirst(activeBaseUrl: String, urls: List<String>): List<String> =
    (listOf(activeBaseUrl) + urls).filter { it.isNotEmpty() }.distinct()

/**
 * Validates edited [urls] for an existing [connection] against its server identity, preferring its current endpoint.
 * Probes public identity only; the returned connection is not stored anywhere.
 */
suspend fun prepareMediaBrowserEndpoints(
    http: HttpClient,
    connection: JellyfinConnection,
    urls: List<String>,
    timeSource: TimeSource = TimeSource.Monotonic,
): JellyfinConnection {
    val input = JellyfinEndpointDiscovery.buildUserInputCandidates(urls, connection.dialect)
    val endpoint = JellyfinEndpointDiscovery(http, connection.dialect, timeSource).raceUserInput(
        input,
        preferredUrl = connection.baseUrl,
        expectedMachineId = connection.serverMachineId,
    )
    return connection.copy(baseUrl = endpoint.activeBaseUrl, baseUrls = endpoint.baseUrls, serverName = endpoint.serverInfo.serverName)
}
