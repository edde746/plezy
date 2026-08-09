package com.edde746.plezy.watchnext

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import java.util.concurrent.Executor
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/** Migrates versioned shelf state after updates and restores volatile launcher grants after boot. */
class SystemShelfUpdateReceiver private constructor(
  private val executor: Executor,
  private val ownsExecutor: Boolean
) : BroadcastReceiver() {
  constructor() : this(Executors.newSingleThreadExecutor(), true)
  internal constructor(executor: Executor) : this(executor, false)

  override fun onReceive(context: Context, intent: Intent) {
    val action = intent.action
    if (action != Intent.ACTION_MY_PACKAGE_REPLACED && action != Intent.ACTION_BOOT_COMPLETED) return
    val pending = goAsync()
    executor.execute {
      try {
        val provider = WatchNextProvider.forMaintenance(context.applicationContext)
        // Snapshot before maintenance: restoreReadGrants() re-commits the
        // granted-URI key even when no sync ever wrote it.
        val hadPriorSync = provider.hasPersistedShelfState()
        if (action == Intent.ACTION_MY_PACKAGE_REPLACED) {
          provider.migrateShelfSchema()
        } else {
          provider.restoreReadGrants()
        }
        // WorkManager normally survives reboots on its own; re-arming here
        // covers force-stop and update edge cases, and only for devices whose
        // persisted state says a shelf was actually synced before.
        if (hadPriorSync) ShelfRefreshScheduler.schedule(context.applicationContext)
      } finally {
        pending?.finish()
        if (ownsExecutor) (executor as ExecutorService).shutdown()
      }
    }
  }
}
