package com.edde746.plezy.downloads

import com.edde746.plezy.net.UriComponent
import com.edde746.plezy.net.isCredentialHeader

/**
 * Adds a download's credentials to its request as it is sent: the downloader keeps its tasks without them
 * ([withoutCredentials]), in memory and in the database, so a server's token never lands in the task table (or in a
 * backup of it). Returns the task with its credentials, or null when they can't be had now (its server isn't known
 * yet or was signed out): the run fails and is retried.
 */
fun interface TaskCredentials {
    suspend fun authorize(task: DownloadTask): DownloadTask?
}

/** [url] without the query parameters a media server's credentials travel in (Plex's, Jellyfin's, Emby's). */
internal fun withoutCredentials(url: String): String {
    val hash = url.indexOf('#')
    val fragment = if (hash >= 0) url.substring(hash) else ""
    val noFragment = if (hash >= 0) url.substring(0, hash) else url
    val q = noFragment.indexOf('?')
    if (q < 0) return url
    val kept = noFragment.substring(q + 1).split('&').filter { param ->
        param.isNotEmpty() && UriComponent.decode(param.substringBefore('=')).lowercase() !in CREDENTIAL_QUERY_PARAMS
    }
    val path = noFragment.substring(0, q)
    return (if (kept.isEmpty()) path else path + "?" + kept.joinToString("&")) + fragment
}

/** This task without the credentials its URL or headers carry: what the downloader keeps. */
internal fun DownloadTask.withoutCredentials(): DownloadTask =
    copy(url = withoutCredentials(url), headers = headers.filterKeys { !isCredentialHeader(it) })

private val CREDENTIAL_QUERY_PARAMS = setOf("x-plex-token", "api_key", "apikey")
