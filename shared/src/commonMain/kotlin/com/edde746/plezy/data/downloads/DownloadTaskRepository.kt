package com.edde746.plezy.data.downloads

import com.edde746.plezy.data.Db
import com.edde746.plezy.downloads.BaseDirectory
import com.edde746.plezy.downloads.DownloadTask
import com.edde746.plezy.downloads.RequireWiFi
import com.edde746.plezy.downloads.TaskException
import com.edde746.plezy.downloads.TaskStatus
import kotlinx.serialization.builtins.MapSerializer
import kotlinx.serialization.builtins.serializer
import kotlinx.serialization.json.Json
import com.edde746.plezy.data.db.Download_task as Row

/**
 * A task as the background downloader keeps it: the task, its last status and progress (its record), and what a
 * resume needs. [toString] leaves out the task's URL and headers.
 */
internal data class StoredTask(
    val task: DownloadTask,
    val status: TaskStatus,
    val progress: Double,
    val expectedFileSize: Long,
    val exception: TaskException?,
    val retriesRemaining: Int,
    val validator: String?,
    val documentUri: String?,
    val sequence: Long,
)

/** The background downloader's tasks and settings (data/db/Download.sq). Device-local. TaskDownloader is its only user. */
internal class DownloadTaskRepository(private val db: Db) {
    /** Every task, in the order they were enqueued. */
    suspend fun all(): List<StoredTask> = db.read { downloadQueries.selectAll().executeAsList().map { it.toModel() } }

    /** The sequence the next enqueued task takes. */
    suspend fun nextSequence(): Long = db.read { downloadQueries.nextSequence().executeAsOne() }

    /** Writes [stored] whole, as a new row or over the task's. */
    suspend fun save(stored: StoredTask) {
        db.write { q.downloadQueries.upsert(stored.toRow()) }
    }

    suspend fun delete(taskId: String) {
        db.write { q.downloadQueries.delete(taskId) }
    }

    suspend fun deleteAll() {
        db.write { q.downloadQueries.deleteAll() }
    }

    /** The Wi-Fi policy last applied; [RequireWiFi.AS_SET_BY_TASK] until one was. */
    suspend fun requireWiFi(): RequireWiFi = db.read {
        val stored = downloadQueries.config(REQUIRE_WIFI).executeAsOneOrNull()
        RequireWiFi.entries.firstOrNull { it.name == stored } ?: RequireWiFi.AS_SET_BY_TASK
    }

    suspend fun setRequireWiFi(requirement: RequireWiFi) {
        db.write { q.downloadQueries.setConfig(REQUIRE_WIFI, requirement.name) }
    }

    private companion object {
        const val REQUIRE_WIFI = "require_wifi"
    }
}

private fun Row.toModel() = StoredTask(
    task = DownloadTask(
        taskId = task_id,
        url = url,
        headers = HeadersJson.decode(headers_json),
        filename = filename,
        directory = directory,
        baseDirectory = BaseDirectory.entries.firstOrNull { it.name == base_directory } ?: BaseDirectory.ROOT,
        directoryUri = directory_uri,
        metaData = meta_data,
        displayName = display_name,
        requiresWiFi = requires_wifi,
        retries = retries.toInt(),
        allowPause = allow_pause,
        creationTime = creation_time,
    ),
    // A status a later version wrote reads as failed: final, so the download manager settles it.
    status = TaskStatus.entries.firstOrNull { it.name == status } ?: TaskStatus.FAILED,
    progress = progress,
    expectedFileSize = expected_file_size,
    exception = exceptionOf(exception_type, exception_description, exception_http_status),
    retriesRemaining = retries_remaining.toInt(),
    validator = validator,
    documentUri = document_uri,
    sequence = sequence,
)

private fun StoredTask.toRow() = Row(
    task_id = task.taskId,
    url = task.url,
    headers_json = HeadersJson.encode(task.headers),
    filename = task.filename,
    directory = task.directory,
    base_directory = task.baseDirectory.name,
    directory_uri = task.directoryUri,
    meta_data = task.metaData,
    display_name = task.displayName,
    requires_wifi = task.requiresWiFi,
    retries = task.retries.toLong(),
    allow_pause = task.allowPause,
    creation_time = task.creationTime,
    status = status.name,
    progress = progress,
    expected_file_size = expectedFileSize,
    exception_type = exception?.let { it::class.simpleName },
    exception_description = exception?.description,
    exception_http_status = (exception as? TaskException.HttpResponse)?.httpResponseCode?.toLong(),
    retries_remaining = retriesRemaining.toLong(),
    validator = validator,
    document_uri = documentUri,
    sequence = sequence,
)

private fun exceptionOf(type: String?, description: String?, httpStatus: Long?): TaskException? {
    type ?: return null
    val text = description.orEmpty()
    return when (type) {
        "FileSystem" -> TaskException.FileSystem(text)
        "Url" -> TaskException.Url(text)
        "Connection" -> TaskException.Connection(text)
        "Resume" -> TaskException.Resume(text)
        "HttpResponse" -> TaskException.HttpResponse(httpStatus?.toInt() ?: 0, text)
        else -> TaskException.General(text)
    }
}

/** `download_task.headers_json`: the request headers, name → value. */
private object HeadersJson {
    private val serializer = MapSerializer(String.serializer(), String.serializer())

    fun encode(headers: Map<String, String>): String = Json.encodeToString(serializer, headers)

    fun decode(json: String): Map<String, String> = Json.decodeFromString(serializer, json)
}
