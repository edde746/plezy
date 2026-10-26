package com.bbflight.background_downloader

import java.util.concurrent.ConcurrentHashMap

/** Keeps the durable descriptor while an auth callback supplies an ephemeral request. */
internal object AuthTaskRegistry {
    private val originalTasks = ConcurrentHashMap<String, Task>()

    fun remember(task: Task) {
        if (task.options?.auth?.hasOnAuthCallback() == true) originalTasks.putIfAbsent(task.taskId, task)
    }

    fun persistable(task: Task): Task = originalTasks[task.taskId] ?: task
    fun isProtected(task: Task): Boolean = originalTasks.containsKey(task.taskId)
    fun remove(taskId: String) { originalTasks.remove(taskId) }
}
