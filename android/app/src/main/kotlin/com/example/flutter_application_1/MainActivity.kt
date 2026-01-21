package com.edde746.plezy

import android.os.Build
import android.os.Bundle
import android.app.AppOpsManager
import android.app.PictureInPictureParams
import android.content.Context
import android.content.res.Configuration
import android.util.Rational
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.edde746.plezy.mpv.MpvPlayerPlugin

class MainActivity : FlutterActivity() {

    private val PIP_CHANNEL = "app.plezy/pip"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Disable Android's default focus highlight ring that appears when using
        // D-pad navigation so the Flutter UI can render its own focus state.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            window.decorView.defaultFocusHighlightEnabled = false
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(MpvPlayerPlugin())

        MethodChannel( flutterEngine.dartExecutor.binaryMessenger, PIP_CHANNEL ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isSupported" -> {
                    result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                }
                "enter" -> {
                    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                        result.success(mapOf("success" to false, "errorCode" to "android_version"))
                        return@setMethodCallHandler
                    }

                    // Check if PiP permission is granted via AppOpsManager
                    val appOpsManager = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
                    val pipAllowed = appOpsManager.checkOpNoThrow(
                        AppOpsManager.OPSTR_PICTURE_IN_PICTURE,
                        applicationInfo.uid,
                        packageName
                    ) == AppOpsManager.MODE_ALLOWED

                    if (!pipAllowed) {
                        result.success(mapOf("success" to false, "errorCode" to "permission_disabled"))
                        return@setMethodCallHandler
                    }

                    try {
                        val width = call.argument<Int>("width") ?: 16
                        val height = call.argument<Int>("height") ?: 9
                        val params = PictureInPictureParams.Builder()
                            .setAspectRatio(Rational(width, height))
                            .build()
                        val success = enterPictureInPictureMode(params)
                        if (success) {
                            result.success(mapOf("success" to true))
                        } else {
                            result.success(mapOf("success" to false, "errorCode" to "failed"))
                        }
                    } catch (e: IllegalStateException) {
                        result.success(mapOf("success" to false, "errorCode" to "not_supported"))
                    } catch (e: Exception) {
                        result.success(mapOf("success" to false, "errorCode" to "unknown", "errorMessage" to (e.message ?: "Unknown error")))
                    }
                } else -> result.notImplemented()
            }
        }
    }

    override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean,newConfig: Configuration) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        MethodChannel( flutterEngine!!.dartExecutor.binaryMessenger, PIP_CHANNEL ).invokeMethod( "onPipChanged" , isInPictureInPictureMode)
    }
}
