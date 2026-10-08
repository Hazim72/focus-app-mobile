package com.focusapp.app.blocking

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import com.focusapp.app.R

class BlockingService : Service() {

    companion object {
        private const val TAG = "FocusAppService"
        const val CHANNEL_ID = "focus_service_channel"
        const val NOTIFICATION_ID = 1001
        const val ACTION_START = "com.focusapp.app.action.START"
        const val ACTION_STOP = "com.focusapp.app.action.STOP"
        const val EXTRA_PACKAGES = "extra_packages"
        const val EXTRA_END_TIME = "extra_end_time"

        var isRunning: Boolean = false
            private set
    }

    private lateinit var foregroundAppDetector: ForegroundAppDetector
    private lateinit var overlayManager: OverlayManager
    private lateinit var powerManager: PowerManager

    private val handler = Handler(Looper.getMainLooper())
    private var isScreenInteractive = true

    private var blockedApps: Set<String> = setOf(
        "com.instagram.android",
        "com.whatsapp",
        "com.android.chrome"
    )
    private var sessionEndTimeEpochMs: Long = 0L

    private val pollingRunnable = object : Runnable {
        override fun run() {
            if (isScreenInteractive) {
                checkForegroundApp()
            }
            // Poll every 1 second
            handler.postDelayed(this, 1000)
        }
    }

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                Intent.ACTION_SCREEN_ON -> {
                    Log.d(TAG, "Screen turned ON - resuming checks")
                    isScreenInteractive = true
                    checkForegroundApp()
                }
                Intent.ACTION_SCREEN_OFF -> {
                    Log.d(TAG, "Screen turned OFF - pausing polling to save battery")
                    isScreenInteractive = false
                }
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "BlockingService created")
        foregroundAppDetector = ForegroundAppDetector(this)
        overlayManager = OverlayManager(this)
        powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        isScreenInteractive = powerManager.isInteractive

        createNotificationChannel()

        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_SCREEN_OFF)
        }
        registerReceiver(screenReceiver, filter)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            Log.d(TAG, "Stopping service via ACTION_STOP")
            WatchdogManager.stopWatchdog(this)
            NativeSessionStorage.clearSession(this)
            overlayManager.hideOverlay()
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return START_NOT_STICKY
        }

        if (intent != null) {
            val passedPackages = intent.getStringArrayListExtra(EXTRA_PACKAGES)
            if (!passedPackages.isNullOrEmpty()) {
                blockedApps = passedPackages.toSet()
            }

            val passedEndTime = intent.getLongExtra(EXTRA_END_TIME, 0L)
            if (passedEndTime > 0L) {
                sessionEndTimeEpochMs = passedEndTime
            }

            // Save to native storage so the service can recover if Android kills the process
            NativeSessionStorage.saveSession(this, blockedApps, sessionEndTimeEpochMs)
            Log.d(TAG, "Started foreground service: blocking $blockedApps until timestamp $sessionEndTimeEpochMs (saved to native storage)")
        } else {
            // Android OS restarted the service (intent is null after process kill recovery)
            Log.d(TAG, "BlockingService restarted by OS (START_STICKY recovery). Checking native storage...")
            if (NativeSessionStorage.isSessionActive(this)) {
                blockedApps = NativeSessionStorage.getBlockedPackages(this)
                sessionEndTimeEpochMs = NativeSessionStorage.getEndTime(this)
                Log.d(TAG, "Successfully recovered session from native storage: blocking $blockedApps until timestamp $sessionEndTimeEpochMs")
            } else {
                Log.d(TAG, "No active session in native storage or session expired. Stopping service.")
                WatchdogManager.stopWatchdog(this)
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
                return START_NOT_STICKY
            }
        }

        val notification = buildForegroundNotification()
        startForeground(NOTIFICATION_ID, notification)
        isRunning = true

        // Ensure watchdog is monitoring this active session
        WatchdogManager.startWatchdog(this)

        handler.removeCallbacks(pollingRunnable)
        handler.post(pollingRunnable)

        return START_STICKY
    }

    private fun checkForegroundApp() {
        // If absolute session end time was specified and reached, stop the session
        if (sessionEndTimeEpochMs > 0 && System.currentTimeMillis() >= sessionEndTimeEpochMs) {
            Log.d(TAG, "Session expired (reached $sessionEndTimeEpochMs). Stopping blocking service.")
            WatchdogManager.stopWatchdog(this)
            NativeSessionStorage.clearSession(this)
            overlayManager.hideOverlay()
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return
        }

        val currentApp = foregroundAppDetector.getForegroundAppPackage() ?: return

        if (blockedApps.contains(currentApp)) {
            Log.d(TAG, "BLOCKED app detected in foreground: $currentApp")
            overlayManager.showOverlay(currentApp)
        } else {
            // User left the blocked app, hide the overlay (unless they're in our app)
            if (overlayManager.isShowing && currentApp != packageName) {
                overlayManager.hideOverlay()
            }
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Focus Service",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Shows ongoing focus blocking status"
                setShowBadge(true)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }

    private fun buildForegroundNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Focus App is Active")
            .setContentText("Distractions are blocked in the background.")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .build()
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        Log.d(TAG, "onTaskRemoved called (app swiped away from recents)")
        if (NativeSessionStorage.isSessionActive(this)) {
            Log.d(TAG, "Session is active. Scheduling immediate watchdog check to guarantee service survival.")
            WatchdogManager.scheduleImmediateCheck(this, 1)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "BlockingService destroyed")
        handler.removeCallbacks(pollingRunnable)
        try {
            unregisterReceiver(screenReceiver)
        } catch (e: Exception) {
            e.printStackTrace()
        }
        overlayManager.hideOverlay()
        isRunning = false

        // If killed unexpectedly while session is still supposed to be active, trigger watchdog
        if (NativeSessionStorage.isSessionActive(this)) {
            Log.w(TAG, "BlockingService destroyed while session was active! Scheduling immediate watchdog recovery.")
            WatchdogManager.scheduleImmediateCheck(this, 1)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
