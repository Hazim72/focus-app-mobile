package com.focusapp.app.blocking

import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.os.Build

class ForegroundAppDetector(private val context: Context) {

    private val usageStatsManager =
        context.getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager

    /**
     * Returns the package name of the app currently visible in the foreground.
     * Returns null if usage stats permission is missing or no foreground event was found.
     */
    fun getForegroundAppPackage(): String? {
        if (usageStatsManager == null) return null

        val endTime = System.currentTimeMillis()
        // Query events from the last 15 seconds
        val beginTime = endTime - (1000 * 15)

        val usageEvents = usageStatsManager.queryEvents(beginTime, endTime)
        val event = UsageEvents.Event()
        var currentForegroundPackage: String? = null

        while (usageEvents.hasNextEvent()) {
            usageEvents.getNextEvent(event)
            val isForeground = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                event.eventType == UsageEvents.Event.ACTIVITY_RESUMED
            } else {
                event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND
            }

            if (isForeground) {
                currentForegroundPackage = event.packageName
            }
        }

        // If no recent transition event occurred in the 15-second window, fallback to queryUsageStats
        if (currentForegroundPackage == null) {
            val stats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                endTime - (1000 * 60 * 5),
                endTime
            )
            currentForegroundPackage = stats?.maxByOrNull { it.lastTimeUsed }?.packageName
        }

        return currentForegroundPackage
    }
}
