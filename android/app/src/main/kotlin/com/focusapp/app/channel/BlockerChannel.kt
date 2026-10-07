package com.focusapp.app.channel

import android.content.Context
import android.content.Intent
import android.os.Build
import com.focusapp.app.blocking.BlockingService
import com.focusapp.app.permissions.PermissionHelper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

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

            else -> result.notImplemented()
        }
    }
}
