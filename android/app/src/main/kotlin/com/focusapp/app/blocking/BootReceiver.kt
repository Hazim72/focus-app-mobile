package com.focusapp.app.blocking

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/**
 * BootReceiver restarts the BlockingService after device reboot if a session is still active.
 */
class BootReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "FocusAppBootReceiver"
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) return

        val action = intent.action
        Log.d(TAG, "Received broadcast action: $action")

        val validActions = listOf(
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_LOCKED_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            "android.intent.action.QUICKBOOT_POWERON",
            "com.htc.intent.action.QUICKBOOT_POWERON"
        )

        if (action in validActions) {
            if (NativeSessionStorage.isSessionActive(context)) {
                val blockedApps = NativeSessionStorage.getBlockedPackages(context)
                val endTimeEpochMs = NativeSessionStorage.getEndTime(context)

                Log.d(TAG, "Active session detected after reboot. Resuming BlockingService for $blockedApps until $endTimeEpochMs")

                val serviceIntent = Intent(context, BlockingService::class.java).apply {
                    this.action = BlockingService.ACTION_START
                    putStringArrayListExtra(BlockingService.EXTRA_PACKAGES, ArrayList(blockedApps))
                    putExtra(BlockingService.EXTRA_END_TIME, endTimeEpochMs)
                }

                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        context.startForegroundService(serviceIntent)
                    } else {
                        context.startService(serviceIntent)
                    }
                    Log.d(TAG, "Successfully requested BlockingService start after reboot")
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to start BlockingService on boot", e)
                }
            } else {
                Log.d(TAG, "No active session found in native storage on boot. Doing nothing.")
            }
        }
    }
}
