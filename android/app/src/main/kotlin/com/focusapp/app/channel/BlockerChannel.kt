package com.focusapp.app.channel

import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import com.focusapp.app.blocking.BlockingService
import com.focusapp.app.permissions.PermissionHelper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import kotlin.concurrent.thread

class BlockerChannel(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL_NAME = "com.focusapp.app/blocker"

        fun register(context: Context, messenger: BinaryMessenger): BlockerChannel {
            val channel = MethodChannel(messenger, CHANNEL_NAME)
            val handler = BlockerChannel(context)
            channel.setMethodCallHandler(handler)
            return handler
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startSession" -> {
                val packages = call.argument<List<String>>("packages") ?: emptyList()
                val endTimeEpochMs = call.argument<Long>("endTimeEpochMs") ?: 0L

                val intent = Intent(context, BlockingService::class.java).apply {
                    action = BlockingService.ACTION_START
                    putStringArrayListExtra(BlockingService.EXTRA_PACKAGES, ArrayList(packages))
                    putExtra(BlockingService.EXTRA_END_TIME, endTimeEpochMs)
                }

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }

                result.success(true)
            }

            "stopSession" -> {
                val intent = Intent(context, BlockingService::class.java).apply {
                    action = BlockingService.ACTION_STOP
                }
                context.startService(intent)
                result.success(true)
            }

            "isSessionActive" -> {
                result.success(BlockingService.isRunning)
            }

            "getPermissionsStatus" -> {
                val status = mapOf(
                    "usageAccess" to PermissionHelper.hasUsageStatsPermission(context),
                    "overlay" to PermissionHelper.hasOverlayPermission(context),
                    "notification" to PermissionHelper.hasNotificationPermission(context),
                    "batteryOptimization" to PermissionHelper.isBatteryOptimizationIgnored(context)
                )
                result.success(status)
            }

            "requestUsageAccess" -> {
                PermissionHelper.openUsageAccessSettings(context)
                result.success(true)
            }

            "requestOverlay" -> {
                PermissionHelper.openOverlaySettings(context)
                result.success(true)
            }

            "requestNotification" -> {
                PermissionHelper.openNotificationSettings(context)
                result.success(true)
            }

            "requestBatteryOptimization" -> {
                PermissionHelper.requestIgnoreBatteryOptimization(context)
                result.success(true)
            }

            "hasPermissions" -> {
                val hasUsage = PermissionHelper.hasUsageStatsPermission(context)
                val hasOverlay = PermissionHelper.hasOverlayPermission(context)
                result.success(hasUsage && hasOverlay)
            }

            "requestPermissions" -> {
                if (!PermissionHelper.hasUsageStatsPermission(context)) {
                    PermissionHelper.openUsageAccessSettings(context)
                } else if (!PermissionHelper.hasOverlayPermission(context)) {
                    PermissionHelper.openOverlaySettings(context)
                }
                result.success(true)
            }

            "getInstalledApps" -> {
                thread {
                    try {
                        val pm = context.packageManager
                        val mainIntent = Intent(Intent.ACTION_MAIN, null).apply {
                            addCategory(Intent.CATEGORY_LAUNCHER)
                        }
                        val resolveInfos = pm.queryIntentActivities(mainIntent, 0)
                        val seenPackages = HashSet<String>()
                        val appList = ArrayList<Map<String, Any?>>()

                        for (info in resolveInfos) {
                            val packageName = info.activityInfo.packageName ?: continue
                            if (packageName == context.packageName) continue
                            if (seenPackages.contains(packageName)) continue
                            seenPackages.add(packageName)

                            val appName = try {
                                info.loadLabel(pm).toString()
                            } catch (e: Exception) {
                                packageName
                            }

                            val iconBytes = try {
                                val drawable = info.loadIcon(pm)
                                drawableToByteArray(drawable)
                            } catch (e: Exception) {
                                null
                            }

                            val isSystemApp = try {
                                val appInfo = pm.getApplicationInfo(packageName, 0)
                                (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                            } catch (e: Exception) {
                                false
                            }

                            appList.add(
                                mapOf(
                                    "name" to appName,
                                    "packageName" to packageName,
                                    "icon" to iconBytes,
                                    "isSystemApp" to isSystemApp
                                )
                            )
                        }

                        appList.sortBy { (it["name"] as? String)?.lowercase() ?: "" }

                        Handler(Looper.getMainLooper()).post {
                            result.success(appList)
                        }
                    } catch (e: Exception) {
                        Handler(Looper.getMainLooper()).post {
                            result.error("APP_LIST_ERROR", e.message, null)
                        }
                    }
                }
            }

            else -> result.notImplemented()
        }
    }

    private fun drawableToByteArray(drawable: Drawable): ByteArray? {
        return try {
            val width = if (drawable.intrinsicWidth in 1..96) drawable.intrinsicWidth else 96
            val height = if (drawable.intrinsicHeight in 1..96) drawable.intrinsicHeight else 96
            val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            drawable.setBounds(0, 0, canvas.width, canvas.height)
            drawable.draw(canvas)
            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 85, stream)
            val bytes = stream.toByteArray()
            bitmap.recycle()
            bytes
        } catch (t: Throwable) {
            null
        }
    }
}
