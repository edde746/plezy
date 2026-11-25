package com.edde746.plezy.downloads

import io.ktor.http.Url
import io.ktor.http.decodeURLPart

/** A download row's native tasks split by whether they carry the row's current task id. */
internal data class NativeTaskPartition(val current: List<DownloadTask>, val stale: List<DownloadTask>)

/** Splits [tasks] into those with [currentTaskId] and the rest; with no current id every task is stale. */
internal fun partitionNativeTasks(tasks: Iterable<DownloadTask>, currentTaskId: String?): NativeTaskPartition {
    val (current, stale) = tasks.partition { currentTaskId != null && it.taskId == currentTaskId }
    return NativeTaskPartition(current, stale)
}

/**
 * Whether [task] writes into a directory left behind by a previous location of the app's private storage.
 *
 * A [BaseDirectory.ROOT] task carries its whole target directory in the downloader's persisted store, so one enqueued
 * before the app moved (Android adoptable storage, an iOS container UUID change) resumes writing where the app owns
 * nothing. Legitimate root-anchored tasks sit under [baseAppDirPath] or under the configured [customRootPath], which
 * does not move with the app. A document task's directory is a tree URI owned by a document provider, never relocated.
 *
 * [rootBasePath] is the downloader's own path for [BaseDirectory.ROOT]; the task's directory is joined onto it before
 * the comparison.
 */
internal fun isRelocatedRootTaskDirectory(
    task: DownloadTask,
    rootBasePath: String,
    baseAppDirPath: String,
    customRootPath: String? = null,
): Boolean {
    if (task.isDocumentTask) return false
    if (task.baseDirectory != BaseDirectory.ROOT) return false
    if (task.directory.isEmpty()) return false
    val directory = LocalPath.normalize(LocalPath.join(rootBasePath, task.directory.trimStart('/')))
    if (directory.isWithinOrEqual(baseAppDirPath)) return false
    if (customRootPath != null && directory.isWithinOrEqual(customRootPath)) return false
    return true
}

private fun String.isWithinOrEqual(parent: String): Boolean {
    val normalizedParent = LocalPath.normalize(parent)
    return this == normalizedParent || LocalPath.isWithin(normalizedParent, this)
}

/**
 * The file extension a download URL names: its last path segment's, else a `Container` query parameter's (Jellyfin and
 * Emby static streams). Only the first of a comma or pipe separated list counts; anything that isn't a short
 * alphanumeric token reads as unknown (null).
 */
fun downloadExtensionFromUrl(url: String): String? {
    val uri = runCatching { Url(url) }.getOrNull() ?: return null
    val lastSegment = uri.encodedPath.substringAfterLast('/').decodeURLPart()
    val lastDot = lastSegment.lastIndexOf('.')
    if (lastDot != -1 && lastDot < lastSegment.length - 1) return safeDownloadExtension(lastSegment.substring(lastDot + 1))
    for ((key, values) in uri.parameters.entries()) {
        if (key.equals("container", ignoreCase = true)) return values.firstOrNull()?.let(::safeDownloadExtension)
    }
    return null
}

private val EXTENSION_SEPARATOR = Regex("[,|]")
private val SAFE_EXTENSION = Regex("^[a-z0-9][a-z0-9._-]{0,39}$")

private fun safeDownloadExtension(raw: String): String? {
    val ext = raw.split(EXTENSION_SEPARATOR).first().trim().trimStart('.').lowercase()
    return ext.takeIf { it.isNotEmpty() && SAFE_EXTENSION.matches(it) }
}
