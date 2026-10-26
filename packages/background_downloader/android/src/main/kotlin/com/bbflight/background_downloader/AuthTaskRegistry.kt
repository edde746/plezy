package com.bbflight.background_downloader

import java.util.concurrent.ConcurrentHashMap

/** Keeps the durable descriptor while an auth callback supplies an ephemeral request. */
internal object AuthTaskRegistry {
    private val originalTasks = ConcurrentHashMap<String, Task>()

    fun remember(task: Task) {
        if (task.options?.auth?.hasOnAuthCallback() == true) originalTasks.putIfAbsent(task.taskId, task)
    }

    fun persistable(task: Task): Task {
        val original = originalTasks[task.taskId] ?: return task
        val updatedMetadata = task.metaData
        if (updatedMetadata != original.metaData &&
            updatedMetadata.startsWith("enc:v2:") &&
            updatedMetadata.toByteArray().size <= 16384
        ) {
            // The callback may rotate a refresh token, but only its encrypted
            // descriptor is copied back. Never persist its temporary URL or headers.
            val updated = original.copyWith(metaData = updatedMetadata)
            originalTasks[task.taskId] = updated
            return updated
        }
        return original
    }
    fun isProtected(task: Task): Boolean = originalTasks.containsKey(task.taskId)
    fun remove(taskId: String) { originalTasks.remove(taskId) }
}
