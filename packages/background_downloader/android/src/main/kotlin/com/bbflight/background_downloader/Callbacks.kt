package com.bbflight.background_downloader

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.preference.PreferenceManager
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.FlutterCallbackInformation
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json


class Callbacks {
    companion object {
        const val TAG = "Callbacks"
        private var callbackMethodChannel: MethodChannel? = null
        private val methodChannelMutex = Mutex()

        /**
         * Registers only the app credential vault needed by authenticated background callbacks.
         * A missing plugin is handled by the Dart callback as a failed, credential-free task.
         */
        private fun registerSecureStoragePlugin(flutterEngine: FlutterEngine) {
            try {
                val pluginClass = Class.forName("com.it_nomads.fluttersecurestorage.FlutterSecureStoragePlugin")
                val plugin = pluginClass.getDeclaredConstructor().newInstance() as? FlutterPlugin
                if (plugin == null) {
                    Log.e(TAG, "Secure storage plugin does not implement FlutterPlugin")
                    return
                }
                flutterEngine.plugins.add(plugin)
            } catch (e: ClassNotFoundException) {
                Log.i(TAG, "Secure storage plugin is unavailable in this callback engine")
            } catch (e: Exception) {
                Log.e(TAG, "Could not register secure storage for background callback", e)
            }
        }

        /**
         * Retrieves the [MethodChannel] used for communication with the Flutter background isolate.
         *
         * This method initializes the `MethodChannel` if it hasn't been created yet. It does so by:
         * 1. Obtaining the `callbackDispatcherRawHandle` from shared preferences.
         * 2. Creating a new [FlutterEngine] and executing the Dart callback dispatcher.
         * 3. Creating a [MethodChannel] using the engine's binary messenger.
         *
         * The initialization process happens on the UI thread to avoid potential issues.
         *
         * This method is thread-safe due to the use of a mutex.
         *
         * @param context The [Context] required for accessing resources and the UI thread.
         * @return The [MethodChannel] instance, or `null` if initialization fails.
         */
        private suspend fun getMethodChannel(context: Context): MethodChannel? {
            methodChannelMutex.withLock {
                if (callbackMethodChannel == null) {
                    // create new flutterEngine and invoke callbackDispatcher, on the UI thread
                    val methodChannelCompleter = CompletableDeferred<MethodChannel?>()
                    Handler(Looper.getMainLooper()).post { // Run on UI thread
                        try {
                            val prefs = PreferenceManager.getDefaultSharedPreferences(context)
                            val rawHandle =
                                prefs.getLong(BDPlugin.keyCallbackDispatcherRawHandle, -1L)
                            if (rawHandle == -1L) {
                                Log.w(
                                    TAG,
                                    "getMethodChannel without registered callbackDispatcherRawHandle"
                                )
                                methodChannelCompleter.complete(null)
                                return@post
                            }
                            val flutterEngine = FlutterEngine(context, null, false)
                            registerSecureStoragePlugin(flutterEngine)
                            val callbackDispatcherCallback =
                                FlutterCallbackInformation.lookupCallbackInformation(rawHandle)
                            if (callbackDispatcherCallback == null) {
                                Log.w(
                                    TAG,
                                    "invokeOnStartCallback failed to find callbackDispatcher"
                                )
                                methodChannelCompleter.complete(null)
                                return@post
                            }
                            val appBundlePath: String =
                                FlutterInjector.instance().flutterLoader().findAppBundlePath()
                            val assets = context.assets
                            flutterEngine.dartExecutor.executeDartCallback(
                                DartExecutor.DartCallback(
                                    assets,
                                    appBundlePath,
                                    callbackDispatcherCallback
                                )
                            )
                            callbackMethodChannel = MethodChannel(
                                flutterEngine.dartExecutor.binaryMessenger,
                                "com.bbflight.background_downloader.callbacks"
                            )
                            methodChannelCompleter.complete(callbackMethodChannel)
                        } catch (e: Exception) {
                            Log.e(TAG, "Error creating MethodChannel", e)
                            methodChannelCompleter.complete(null)
                        }
                    }
                    return methodChannelCompleter.await() // Wait for the UI thread to finish
                }
                return callbackMethodChannel
            }
        }

        /**
         * Invokes a callback method on the Flutter side using the specified method channel.
         *
         * This function handles the asynchronous communication with Flutter, ensuring thread safety
         * and proper handling of the result. It serializes the given `task` object to JSON
         * and passes it as an argument to the Flutter method.
         *
         * @param context The Android context.
         * @param task The [Task] object to be passed to the Flutter callback, or null.
         * @param statusUpdate The [TaskStatusUpdate] object to be passed to the Flutter callback, or null.
         * @param methodName The name of the method to invoke on the Flutter side.
         * @return The updated object returned by the Flutter callback, or `null` if
         *         the task is unchanged, an error occurs, or the method channel is not available.
         */
        private suspend fun invokeCallback(
            context: Context,
            methodName: String,
            task: Task? = null,
            statusUpdate: TaskStatusUpdate? = null,
        ): Any? {
            val methodChannel = getMethodChannel(context) ?: return null
            methodChannelMutex.withLock {
                val resultingObjectAsJsonStringCompleter = CompletableDeferred<String?>()
                Handler(Looper.getMainLooper()).post {
                    // Run on UI thread
                    val arg = if (task != null) bdJson.encodeToString(task) else bdJson.encodeToString(
                        statusUpdate
                    )
                    Log.i(
                        TAG,
                        "Invoking $methodName for taskId ${task?.taskId}"
                    )
                    methodChannel.invokeMethod(
                        methodName,
                        arg, // either task or update
                        FlutterResultHandler(resultingObjectAsJsonStringCompleter)
                    )
                }
                val objectAsJsonString = resultingObjectAsJsonStringCompleter.await()
                return if (objectAsJsonString == null) null else
                    if (methodName == "beforeTaskStartCallback") bdJson.decodeFromString<TaskStatusUpdate>(
                        objectAsJsonString
                    ) else bdJson.decodeFromString<Task>(
                        objectAsJsonString
                    )
            }
        }

        /**
         * Invoke the beforeTaskStartCallback and return the result
         */
        suspend fun invokeBeforeTaskStartCallback(context: Context, task: Task): TaskStatusUpdate? {
            try {
                return invokeCallback(
                    context,
                    "beforeTaskStartCallback",
                    task = task
                ) as TaskStatusUpdate?
            } catch (e: Exception) {
                Log.e(TAG, "Error in invokeBeforeTaskStartCallback", e)
            }
            return null
        }

        /**
         * Invoke the onTaskStartCallback and return the result
         */
        suspend fun invokeOnTaskStartCallback(context: Context, task: Task): Task? {
            try {
                return invokeCallback(context, "onTaskStartCallback", task = task) as Task?
            } catch (e: Exception) {
                Log.e(TAG, "Error in invokeOnTaskStartCallback", e)
            }
            return null
        }

        /**
         * Invoke the invokeOnAuthCallback and return the result
         */
        suspend fun invokeOnAuthCallback(context: Context, task: Task): Task? {
            try {
                return invokeCallback(context, "onAuthCallback", task = task) as Task?
            } catch (e: Exception) {
                Log.e(TAG, "Error in invokeOnAuthCallback", e)
            }
            return null
        }

        /**
         * Invoke the onTaskFinishedCallback
         */
        suspend fun invokeOnTaskFinishedCallback(context: Context, statusUpdate: TaskStatusUpdate) {
            try {
                invokeCallback(
                    context,
                    "onTaskFinishedCallback",
                    statusUpdate = statusUpdate
                ) as Task?
            } catch (e: Exception) {
                Log.e(TAG, "Error in invokeOnTaskFinishedCallback", e)
            }
        }
    }
}
