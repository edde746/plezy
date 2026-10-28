package org.plezy.preparation

import android.content.Context
import androidx.work.*
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import java.util.concurrent.TimeUnit

class PlezyPreparationPlugin : FlutterPlugin {
    private var channel: MethodChannel? = null
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "org.plezy/preparation").also { ch ->
            ch.setMethodCallHandler { call, result ->
                when (call.method) {
                    "schedule" -> {
                        val constraints = Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED)
                            .setRequiresBatteryNotLow(true).build()
                        val work = OneTimeWorkRequestBuilder<PreparationWorker>().setConstraints(constraints)
                            .setInitialDelay(30, TimeUnit.SECONDS)
                            .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 30, TimeUnit.SECONDS).build()
                        WorkManager.getInstance(context).enqueueUniqueWork(NAME, ExistingWorkPolicy.KEEP, work)
                        // Periodic safety net survives process death and a missed enqueue.
                        val periodic = PeriodicWorkRequestBuilder<PreparationWorker>(15, TimeUnit.MINUTES)
                            .setConstraints(constraints).build()
                        WorkManager.getInstance(context).enqueueUniquePeriodicWork("$NAME.periodic", ExistingPeriodicWorkPolicy.KEEP, periodic)
                        result.success(null)
                    }
                    "cancel" -> {
                        WorkManager.getInstance(context).cancelUniqueWork(NAME)
                        WorkManager.getInstance(context).cancelUniqueWork("$NAME.periodic")
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
    }
    companion object { const val NAME = "org.plezy.preparation" }
}

class PreparationWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result {
        var engine: FlutterEngine? = null
        return try {
            val completed = CompletableDeferred<Boolean>()
            withContext(Dispatchers.Main) {
                val loader = FlutterInjector.instance().flutterLoader()
                loader.startInitialization(applicationContext)
                loader.ensureInitializationComplete(applicationContext, null)
                // Auto-register the actual app plugins, including secure storage,
                // path_provider and preferences, in the isolated headless engine.
                val worker = FlutterEngine(applicationContext)
                engine = worker
                val channel = MethodChannel(worker.dartExecutor.binaryMessenger, "org.plezy/preparation.worker")
                channel.setMethodCallHandler { call, result ->
                    when (call.method) {
                        "complete" -> { completed.complete(call.arguments == true); result.success(null) }
                        else -> result.notImplemented()
                    }
                }
                worker.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint(loader.findAppBundlePath(),
                    "package:plezy/services/remote_streams/remote_preparation_worker.dart", "remotePreparationEntrypoint"))
            }
            if (withTimeout(8 * 60 * 1000L) { completed.await() }) Result.success() else Result.retry()
        } catch (cancelled: CancellationException) {
            throw cancelled
        } catch (_: Exception) {
            Result.retry()
        } finally {
            withContext(NonCancellable + Dispatchers.Main) { engine?.destroy() }
        }
    }
}
