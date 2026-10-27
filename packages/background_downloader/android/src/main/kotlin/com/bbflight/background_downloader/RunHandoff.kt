package com.bbflight.background_downloader

import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import androidx.core.content.edit
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.serialization.encodeToString
import java.io.File
import java.util.concurrent.ConcurrentHashMap
import kotlin.concurrent.read
import kotlin.concurrent.write

/**
 * Carries a task from a run the platform stopped to the run that replaces it
 *
 * WorkManager reschedules work it stops without canceling it (quota, a constraint no longer met,
 * device state), and a user-initiated job the system stops is enqueued again. The replacement run
 * gets the task's original input, and can start while the stopped run is still unwinding, so on
 * its own it would start the transfer over and write to the same partial file.
 *
 * Runs of a task therefore take turns ([awaitTurn], [endTurn]), and a stopped download records
 * where its partial file ends ([store]) for the next run to resume from ([take]).
 *
 * A run that dies with its process records nothing when it stops, so a SAF download also records
 * the document it creates ([recordDestination]) for a run replacing it to write to again.
 */
object RunHandoff {
    private const val keyHandoffMap = "com.bbflight.background_downloader.runHandoffMap"
    private const val keyDestinationMap = "com.bbflight.background_downloader.runDestinationMap"

    private val turns = ConcurrentHashMap<String, CompletableDeferred<Unit>>()

    /**
     * Wait until earlier runs of [taskId] in this process have finished, and return this run's
     * turn, to pass to [endTurn] when the run finishes
     *
     * A run canceled while waiting still holds back later runs until the earlier ones finish
     */
    suspend fun awaitTurn(taskId: String): CompletableDeferred<Unit> {
        val turn = CompletableDeferred<Unit>()
        val previous = turns.put(taskId, turn) ?: return turn
        try {
            previous.await()
        } catch (e: CancellationException) {
            previous.invokeOnCompletion { endTurn(taskId, turn) }
            throw e
        }
        return turn
    }

    /** End the [turn] of a run of [taskId], letting the next run of that task proceed */
    fun endTurn(taskId: String, turn: CompletableDeferred<Unit>) {
        turns.remove(taskId, turn)
        turn.complete(Unit)
    }

    /** Record [resumeData] for the next run of its task, replacing any earlier record */
    fun store(prefs: SharedPreferences, resumeData: ResumeData) {
        BDPlugin.prefsLock.write {
            val handoffs = readMap(prefs, keyHandoffMap)
            handoffs[resumeData.task.taskId] = bdJson.encodeToString(resumeData)
            // committed synchronously: the process may be frozen or killed right after a stop
            prefs.edit(commit = true) { putString(keyHandoffMap, bdJson.encodeToString(handoffs)) }
        }
    }

    /** Remove and return the record for [taskId], or null if there is none */
    fun take(prefs: SharedPreferences, taskId: String): ResumeData? {
        val json = takeEntry(prefs, keyHandoffMap, taskId) ?: return null
        return try {
            bdJson.decodeFromString<ResumeData>(json)
        } catch (_: Exception) {
            null
        }
    }

    /**
     * Record [uri] as the SAF document runs of [taskId] write to
     *
     * A run packs its document Uri into the task's filename, but only in memory. If the process
     * dies, the platform runs the task again with its original input, and creating the document
     * again would make the provider number a copy ("name (1)") beside the partial one.
     */
    fun recordDestination(prefs: SharedPreferences, taskId: String, uri: Uri) {
        BDPlugin.prefsLock.write {
            val destinations = readMap(prefs, keyDestinationMap)
            destinations[taskId] = uri.toString()
            // committed synchronously: the record must outlive a process that dies right after
            prefs.edit(commit = true) {
                putString(keyDestinationMap, bdJson.encodeToString(destinations))
            }
        }
    }

    /** The SAF document an earlier run of [taskId] created, or null if there is none */
    fun recordedDestination(prefs: SharedPreferences, taskId: String): Uri? =
        BDPlugin.prefsLock.read { readMap(prefs, keyDestinationMap)[taskId] }?.let(Uri::parse)

    /** Remove the SAF document recorded for [taskId], once the task has ended */
    fun forgetDestination(prefs: SharedPreferences, taskId: String) {
        takeEntry(prefs, keyDestinationMap, taskId)
    }

    /** Delete the partial file or document [resumeData] points to */
    fun deletePartialFile(context: Context, resumeData: ResumeData) {
        val uri = Uri.parse(resumeData.data)
        if (uri.scheme == "content" || uri.scheme == "file") {
            DownloadTaskRunner.deleteDestination(context, uri)
        } else {
            File(resumeData.data).delete()
        }
    }

    /** Remove and return the entry for [taskId] in the map stored under [key] */
    private fun takeEntry(prefs: SharedPreferences, key: String, taskId: String): String? {
        BDPlugin.prefsLock.write {
            val entries = readMap(prefs, key)
            val entry = entries.remove(taskId) ?: return null
            prefs.edit(commit = true) { putString(key, bdJson.encodeToString(entries)) }
            return entry
        }
    }

    private fun readMap(prefs: SharedPreferences, key: String): MutableMap<String, String> =
        bdJson.decodeFromString(prefs.getString(key, "{}") ?: "{}")
}
