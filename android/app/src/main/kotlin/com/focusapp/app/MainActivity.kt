package com.focusapp.app

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.focusapp.app.blocking.ForegroundAppDetector
import com.focusapp.app.blocking.OverlayManager
import com.focusapp.app.permissions.PermissionHelper
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    private lateinit var foregroundAppDetector: ForegroundAppDetector
    private lateinit var overlayManager: OverlayManager

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        foregroundAppDetector = ForegroundAppDetector(this)
        overlayManager = OverlayManager(this)
    }

    override fun onResume() {
        super.onResume()
        if (!PermissionHelper.hasUsageStatsPermission(this)) {
            Log.d("FocusApp", "Day 3 Test: Usage access NOT granted. Prompting user...")
            PermissionHelper.openUsageAccessSettings(this)
            return
        }

        if (!PermissionHelper.hasOverlayPermission(this)) {
            Log.d("FocusApp", "Day 3 Test: Overlay permission NOT granted. Prompting user...")
            PermissionHelper.openOverlaySettings(this)
            return
        }

        Log.d("FocusApp", "Day 3 Test: Both permissions granted! Triggering overlay test in 5 seconds...")
        Log.d("FocusApp", "Day 3 Test: Switch to another app (e.g. Chrome, WhatsApp) to see overlay appear over it!")

        // Wait 5 seconds to give the user time to switch to another app
        Handler(Looper.getMainLooper()).postDelayed({
            val currentApp = foregroundAppDetector.getForegroundAppPackage()
            Log.d("FocusApp", "Day 3 Test: Showing overlay over foreground app: $currentApp")
            overlayManager.showOverlay(currentApp ?: "Test App")
        }, 5000)
    }
}
