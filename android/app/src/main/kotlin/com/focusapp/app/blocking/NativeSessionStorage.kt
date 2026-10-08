package com.focusapp.app.blocking

import android.content.Context
import android.content.SharedPreferences

/**
 * Native persistence for Focus App blocking sessions.
 * Allows the foreground service to recover its target packages and absolute end timestamp
 * even if the app process or Flutter engine is killed by Android OS.
 */
object NativeSessionStorage {
    private const val PREFS_NAME = "focus_app_native_session"
    private const val KEY_IS_ACTIVE = "native_session_is_active"
    private const val KEY_START_TIME = "native_session_start_time"
    private const val KEY_END_TIME = "native_session_end_time"
    private const val KEY_PACKAGES = "native_session_packages"

    private fun getPrefs(context: Context): SharedPreferences {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    fun saveSession(
        context: Context,
        packages: Set<String>,
        endTimeEpochMs: Long,
        startTimeEpochMs: Long = System.currentTimeMillis()
    ) {
        getPrefs(context).edit().apply {
            putBoolean(KEY_IS_ACTIVE, true)
            putLong(KEY_START_TIME, startTimeEpochMs)
            putLong(KEY_END_TIME, endTimeEpochMs)
            putStringSet(KEY_PACKAGES, HashSet(packages))
            apply()
        }
    }

    fun clearSession(context: Context) {
        getPrefs(context).edit().apply {
            putBoolean(KEY_IS_ACTIVE, false)
            remove(KEY_START_TIME)
            remove(KEY_END_TIME)
            remove(KEY_PACKAGES)
            apply()
        }
    }

    fun isSessionActive(context: Context): Boolean {
        val prefs = getPrefs(context)
        val isActive = prefs.getBoolean(KEY_IS_ACTIVE, false)
        if (!isActive) return false

        // Rule: If absolute timestamp has expired, clear and return false
        val endTime = prefs.getLong(KEY_END_TIME, 0L)
        if (endTime in 1..System.currentTimeMillis()) {
            clearSession(context)
            return false
        }
        return true
    }

    fun getEndTime(context: Context): Long {
        return getPrefs(context).getLong(KEY_END_TIME, 0L)
    }

    fun getStartTime(context: Context): Long {
        return getPrefs(context).getLong(KEY_START_TIME, 0L)
    }

    fun getBlockedPackages(context: Context): Set<String> {
        return getPrefs(context).getStringSet(KEY_PACKAGES, emptySet()) ?: emptySet()
    }
}
