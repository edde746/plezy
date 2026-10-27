@file:Suppress("EnumEntryName")

package com.bbflight.background_downloader

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat

enum class PermissionType {
    notifications, androidSharedStorage, iosAddToPhotoLibrary, iosChangePhotoLibrary
}

@Suppress("unused")
enum class PermissionStatus {
    undetermined, denied, granted, partial, requestError
}

class PermissionsService {
    companion object {
        private const val baseRequestCode = 373900

        /**
         * Requests [PermissionStatus] for permission of [permissionType]
         *
         * Requests [PermissionStatus.granted] for unknown permissions
         */
        fun getPermissionStatus(
            context: Context,
            permissionType: PermissionType
        ): PermissionStatus {
            when (permissionType) {
                PermissionType.notifications -> {
                    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        // On Android 33+, check/ask for permission
                        val auth = ActivityCompat.checkSelfPermission(
                            context, Manifest.permission.POST_NOTIFICATIONS
                        )
                        if (auth == PackageManager.PERMISSION_GRANTED)
                            PermissionStatus.granted
                        else
                            PermissionStatus.denied
                    } else {
                        PermissionStatus.granted
                    }
                }

                PermissionType.androidSharedStorage -> {
                    return if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q
                    ) {
                        // On Android before 29, check/ask for permission
                        val auth = ActivityCompat.checkSelfPermission(
                            context, Manifest.permission.WRITE_EXTERNAL_STORAGE
                        )
                        if (auth == PackageManager.PERMISSION_GRANTED)
                            PermissionStatus.granted
                        else
                            PermissionStatus.denied
                    } else {
                        PermissionStatus.granted
                    }
                }

                else -> {
                    return PermissionStatus.granted
                }
            }
        }

        /**
         * Requests permission for [permissionType] adn returns a Boolean
         * If true a request has been made that the flutter side should wait for
         * If false, no request has been made -> check permission status separately
         *
         * Does not wait for result. Once result is received via the
         * [onRequestPermissionsResult], a message is sent back to the
         * Flutter side with the permission result
         */
        fun requestPermission(plugin: BDPlugin, permissionType: PermissionType): Boolean {
            val requestCode = baseRequestCode + permissionType.ordinal
            when (permissionType) {
                PermissionType.notifications -> {
                    // On Android 33+, check/ask for permission
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        if (plugin.activity == null) {
                            return false
                        }
                        ActivityCompat.requestPermissions(
                            plugin.activity!!, arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                            requestCode
                        )
                        return true
                    } else {
                        return false
                    }
                }

                PermissionType.androidSharedStorage -> {
                    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                        // On Android before 29, check/ask for permission
                        if (plugin.activity == null) {
                            return false
                        }
                        ActivityCompat.requestPermissions(
                            plugin.activity!!,
                            arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE),
                            requestCode
                        )
                        // completer will be completed via [onRequestPermissionsResult]
                        return true

                    } else {
                        return false
                    }
                }

                else -> {
                    return false
                }
            }
        }

        /**
         * Returns true if Android shouldShowRequestPermissionRationale returns true for this
         * [permissionType]. Returns false for unrecognized [permissionType]
         */
        fun shouldShowRequestPermissionRationale(
            plugin: BDPlugin,
            permissionType: PermissionType
        ): Boolean {
            val activity = plugin.activity
            return if (activity != null) {
                when (permissionType) {
                    PermissionType.notifications -> {
                        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            ActivityCompat.shouldShowRequestPermissionRationale(
                                activity,
                                Manifest.permission.POST_NOTIFICATIONS
                            )
                        } else {
                            false
                        }
                    }

                    PermissionType.androidSharedStorage -> {
                        return ActivityCompat.shouldShowRequestPermissionRationale(
                            activity,
                            Manifest.permission.WRITE_EXTERNAL_STORAGE
                        )
                    }

                    else -> return false
                }
            } else {
                false
            }
        }

        /// Processes the onRequestPermissionsResult received by the Activity
        fun onRequestPermissionsResult(
            plugin: BDPlugin,
            requestCode: Int, grantResults: IntArray
        ): Boolean {
            val granted =
                (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED)
            return when (requestCode) {
                baseRequestCode + PermissionType.notifications.ordinal,
                baseRequestCode + PermissionType.androidSharedStorage.ordinal -> {
                    sendPermissionResult(plugin, granted)
                    true
                }

                else -> {
                    false
                }
            }
        }

        /**
         * Send the [granted] result via the background channel to Flutter
         *
         * Only one request can be 'in flight' at any time
         */
        private fun sendPermissionResult(
            plugin: BDPlugin,
            granted: Boolean
        ) {
            // send with dummy task ("")
            val bgChannel = BDPlugin.backgroundChannel(plugin)
            bgChannel?.invokeMethod(
                "permissionRequestResult",
                listOf(
                    "",
                    if (granted) PermissionStatus.granted.ordinal else PermissionStatus.denied.ordinal
                )
            )

        }
    }
}
