package com.focusapp.app.blocking

import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.work.Worker
import androidx.work.WorkerParameters

/**
 * WorkManager worker that acts as a watchdog to verify that BlockingService is alive
 * when an active session is in progress, resurrecting it if an aggressive OS killed it.
 */
class FocusWatchdogWorker(
    private val context: Context,
    workerParams: WorkerParameters
) : Worker(context, workerParams) {

    companion object {
        private const val TAG = "FocusWatchdogWorker"
    }

    override fun doWork(): Result {
        Log.d(TAG, "Watchdog running health check...")

        if (!NativeSessionStorage.isSessionActive(context)) {
            Log.d(TAG, "No active session in storage. Stopping watchdog.")
            WatchdogManager.stopWatchdog(context)
            return Result.success()
        }

        if (!BlockingService.isRunning) {
            Log.w(TAG, "Watchdog detected BlockingService was killed! Reviving service now...")
            val blockedApps = NativeSessionStorage.getBlockedPackages(context)
            val endTimeEpochMs = NativeSessionStorage.getEndTime(context)

            val serviceIntent = Intent(context, BlockingService::class.java).apply {
                action = BlockingService.ACTION_START
                putStringArrayListExtra(BlockingService.EXTRA_PACKAGES, ArrayList(blockedApps))
                putExtra(BlockingService.EXTRA_END_TIME, endTimeEpochMs)
            }

            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
                Log.d(TAG, "Watchdog successfully revived BlockingService")
            } catch (e: Exception) {
                Log.e(TAG, "Watchdog failed to restart BlockingService", e)
            }
        } else {
            Log.d(TAG, "Watchdog check passed: BlockingService is running normally.")
        }

        return Result.success()
    }
}
