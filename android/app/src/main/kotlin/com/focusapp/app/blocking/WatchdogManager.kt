package com.focusapp.app.blocking

import android.content.Context
import android.util.Log
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

/**
 * Manages WorkManager watchdog scheduling to protect Focus App from aggressive background killers.
 */
object WatchdogManager {
    private const val TAG = "WatchdogManager"
    private const val UNIQUE_PERIODIC_WORK = "focus_app_periodic_watchdog"
    private const val UNIQUE_ONE_TIME_WORK = "focus_app_onetime_watchdog"

    fun startWatchdog(context: Context) {
        try {
            val workManager = WorkManager.getInstance(context)

            // Periodic watchdog runs every 15 minutes (Android WorkManager minimum interval)
            val periodicRequest = PeriodicWorkRequestBuilder<FocusWatchdogWorker>(
                15, TimeUnit.MINUTES
            ).build()

            workManager.enqueueUniquePeriodicWork(
                UNIQUE_PERIODIC_WORK,
                ExistingPeriodicWorkPolicy.UPDATE,
                periodicRequest
            )
            Log.d(TAG, "Periodic watchdog enqueued successfully.")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to enqueue periodic watchdog", e)
        }
    }

    fun scheduleImmediateCheck(context: Context, delaySeconds: Long = 1) {
        try {
            val workManager = WorkManager.getInstance(context)

            val oneTimeRequest = OneTimeWorkRequestBuilder<FocusWatchdogWorker>()
                .setInitialDelay(delaySeconds, TimeUnit.SECONDS)
                .build()

            workManager.enqueueUniqueWork(
                UNIQUE_ONE_TIME_WORK,
                ExistingWorkPolicy.REPLACE,
                oneTimeRequest
            )
            Log.d(TAG, "Immediate watchdog check enqueued with ${delaySeconds}s delay.")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to enqueue immediate watchdog check", e)
        }
    }

    fun stopWatchdog(context: Context) {
        try {
            val workManager = WorkManager.getInstance(context)
            workManager.cancelUniqueWork(UNIQUE_PERIODIC_WORK)
            workManager.cancelUniqueWork(UNIQUE_ONE_TIME_WORK)
            Log.d(TAG, "Watchdog cancelled.")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to cancel watchdog", e)
        }
    }
}
