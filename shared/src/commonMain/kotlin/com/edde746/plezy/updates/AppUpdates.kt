package com.edde746.plezy.updates

import com.edde746.plezy.app.AppGraph
import com.edde746.plezy.data.settings.DeviceSettingsRepository
import com.edde746.plezy.log.Log
import com.edde746.plezy.net.readText
import com.edde746.plezy.settings.AppSettings
import io.ktor.client.HttpClient
import io.ktor.client.plugins.timeout
import io.ktor.client.request.header
import io.ktor.client.request.prepareGet
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.jsonObject
import kotlin.coroutines.cancellation.CancellationException
import kotlin.time.Clock
import kotlin.time.Duration.Companion.hours
import kotlin.time.Duration.Companion.seconds
import kotlin.time.Instant

/** A newer GitHub release than the running app: what the update dialog shows and opens. */
data class ReleaseUpdate(
    /** The running app's version ("2.25.0"). */
    val currentVersion: String,
    /** The release's version, its tag without a leading `v` ("2.26.0"). */
    val latestVersion: String,
    /** The release's page (`html_url`). */
    val releaseUrl: String,
    /** The release's name, else "Version <latestVersion>". */
    val releaseName: String,
    /** The release's notes (`body`, Markdown), empty when it has none. */
    val releaseNotes: String,
    /** When the release was published (`published_at`, ISO 8601). */
    val publishedAt: String,
)

/** The release check failed: the request, its answer (not HTTP 200) or the answer's JSON. */
class UpdateCheckException(message: String, cause: Throwable? = null) : Exception(message, cause)

/**
 * This install's updates ([updater], from [updaterFor]) and the GitHub release check: `GET` the latest release of
 * edde746/plezy, its tag without a leading `v` compared part by part with the running app's version.
 *
 * - [checkAtLaunch]: with `auto_check_updates_on_startup` on, the platform's updater checks in the background
 *   ([Updater.NATIVE]), or the GitHub release is checked at most every 6 hours ([Updater.GITHUB]). The check's time
 *   (`update_last_check_time`, ISO 8601) is written before the request, so a check that fails also waits 6 hours; a
 *   stored time that doesn't parse or lies in the future is removed and the check is due. A release the user skipped
 *   (`update_skipped_version`, [skip]) isn't offered, nor is anything when the check fails (logged).
 * - [checkNow]: the user asked (Settings): no waiting, the stored time stays as it is, and a failed check throws.
 *
 * [checkAtLaunch] and [skip] run in [scope], the app's main-thread scope.
 */
class AppUpdates internal constructor(
    val updater: Updater,
    private val http: HttpClient,
    private val settings: DeviceSettingsRepository,
    private val currentVersion: String,
    private val clock: Clock,
    private val scope: CoroutineScope,
) {
    constructor(graph: AppGraph, installation: Installation) :
        this(updaterFor(graph.flavor, installation), graph.http, graph.data.deviceSettings, graph.appVersion, graph.clock, graph.scope)

    /** Whether the app updates itself at all: Settings shows its Updates group only then. */
    val available: Boolean get() = updater != Updater.NONE

    /**
     * The launch's check (once per launch: the caller's to keep), on the main thread: with the setting on, [native]
     * where the platform's updater checks now in the background, or [offer] with a newer GitHub release.
     */
    fun checkAtLaunch(native: () -> Unit, offer: (ReleaseUpdate) -> Unit): Job = scope.launch {
        when (updater) {
            Updater.NONE -> Unit
            Updater.NATIVE -> if (nativeCheckAtLaunch()) native()
            Updater.GITHUB -> releaseAtLaunch()?.let(offer)
        }
    }

    /** Whether the platform's updater checks in the background now, at launch: its updater, the setting on. */
    internal suspend fun nativeCheckAtLaunch(): Boolean =
        updater == Updater.NATIVE && settings.value(AppSettings.autoCheckUpdatesOnStartup)

    /** The launch's GitHub check: a release to offer, or null (another updater, the setting off, not due, none, failed). */
    internal suspend fun releaseAtLaunch(): ReleaseUpdate? {
        if (updater != Updater.GITHUB || !settings.value(AppSettings.autoCheckUpdatesOnStartup)) return null
        return check(respectCooldown = true, throwOnFailure = false)
    }

    /**
     * The user's check (the GitHub updater only): the newer release not skipped, or null when there is none. Throws
     * [UpdateCheckException] when the check itself fails, so the caller says so rather than "latest version".
     */
    @Throws(UpdateCheckException::class, CancellationException::class)
    suspend fun checkNow(): ReleaseUpdate? {
        check(updater == Updater.GITHUB) { "the release check is the GitHub updater's, not $updater's" }
        return check(respectCooldown = false, throwOnFailure = true)
    }

    /** Offers [version] no more (the dialog's "Skip This Version"): stored in [scope]. */
    fun skip(version: String): Job = scope.launch { settings.set(AppSettings.updateSkippedVersion, version) }

    /** The version the user skipped, if any: the installer updater's launch check leaves it out too. */
    suspend fun skippedVersion(): String? = settings.value(AppSettings.updateSkippedVersion)

    /** Whether 6 hours have passed since the last launch check; a stored time unparsed or in the future is removed. */
    internal suspend fun isDue(): Boolean {
        val stored = settings.value(AppSettings.updateLastCheckTime) ?: return true
        val now = clock.now()
        val last = parseCheckTime(stored)
        if (last == null || last > now) {
            settings.set(AppSettings.updateLastCheckTime, null)
            return true
        }
        return now - last >= COOLDOWN
    }

    internal suspend fun check(respectCooldown: Boolean, throwOnFailure: Boolean): ReleaseUpdate? {
        if (respectCooldown) {
            if (!isDue()) return null
            settings.set(AppSettings.updateLastCheckTime, clock.now().toString())
        }
        return try {
            offer(latestRelease())
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.e(TAG, e) { "the release check failed" }
            if (throwOnFailure) throw e as? UpdateCheckException ?: UpdateCheckException("the release check failed", e)
            null
        }
    }

    /** [release] as an update to offer: null when it isn't newer than the running app, or the user skipped it. */
    private suspend fun offer(release: JsonObject): ReleaseUpdate? {
        val latest = release.string("tag_name").removePrefix("v")
        if (!isNewerVersion(latest, currentVersion) || skippedVersion() == latest) return null
        return ReleaseUpdate(
            currentVersion = currentVersion,
            latestVersion = latest,
            releaseUrl = release.string("html_url"),
            releaseName = release.optionalString("name") ?: "Version $latest",
            releaseNotes = release.optionalString("body") ?: "",
            publishedAt = release.string("published_at"),
        )
    }

    private suspend fun latestRelease(): JsonObject = http.prepareGet(LATEST_RELEASE_URL) {
        header(HttpHeaders.Accept, "application/vnd.github+json")
        timeout { requestTimeoutMillis = REQUEST_TIMEOUT.inWholeMilliseconds }
    }.execute { response ->
        if (response.status != HttpStatusCode.OK) throw UpdateCheckException("the release check answered HTTP ${response.status.value}")
        val text = response.readText(MAX_BODY_BYTES) ?: throw UpdateCheckException("the release check's answer is over $MAX_BODY_BYTES bytes")
        try {
            Json.parseToJsonElement(text).jsonObject
        } catch (e: IllegalArgumentException) {
            throw UpdateCheckException("the release check's answer isn't a JSON object", e)
        }
    }

    private fun JsonObject.optionalString(key: String): String? = (get(key) as? JsonPrimitive)?.takeIf { it.isString }?.content

    private fun JsonObject.string(key: String): String = optionalString(key) ?: throw UpdateCheckException("the release has no $key")

    private companion object {
        const val TAG = "updates"
        const val LATEST_RELEASE_URL = "https://api.github.com/repos/edde746/plezy/releases/latest"
        val COOLDOWN = 6.hours
        val REQUEST_TIMEOUT = 30.seconds

        /** A release's JSON with its notes and assets is tens of kilobytes. */
        const val MAX_BODY_BYTES = 4L * 1024 * 1024
    }
}

/**
 * `update_last_check_time`: an ISO 8601 time with its offset, as this app writes it; the earlier releases wrote the
 * device's local time without one, read here as UTC (off by the device's offset, once).
 */
private fun parseCheckTime(value: String): Instant? =
    runCatching { Instant.parse(value) }.getOrNull() ?: runCatching { Instant.parse(value + "Z") }.getOrNull()

/**
 * Whether [candidate] is a later version than [current]: their dot-separated parts compared as numbers, each without a
 * `+` or `-` suffix, an unreadable or missing part as 0 ("2.26" equals "2.26.0").
 */
internal fun isNewerVersion(candidate: String, current: String): Boolean {
    val next = versionParts(candidate)
    val now = versionParts(current)
    for (i in 0 until maxOf(next.size, now.size)) {
        val a = next.getOrElse(i) { 0 }
        val b = now.getOrElse(i) { 0 }
        if (a != b) return a > b
    }
    return false
}

private fun versionParts(version: String): List<Int> =
    version.split('.').map { it.substringBefore('+').substringBefore('-').toIntOrNull() ?: 0 }
