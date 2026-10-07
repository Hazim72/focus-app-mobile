package com.focusapp.app

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.Log
import com.focusapp.app.blocking.BlockingService
import com.focusapp.app.permissions.PermissionHelper
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }

    override fun onResume() {
        super.onResume()
        if (!PermissionHelper.hasUsageStatsPermission(this)) {
            Log.d("FocusApp", "Day 4: Usage access NOT granted. Prompting user...")
            PermissionHelper.openUsageAccessSettings(this)
            return
        }

        if (!PermissionHelper.hasOverlayPermission(this)) {
            Log.d("FocusApp", "Day 4: Overlay permission NOT granted. Prompting user...")
            PermissionHelper.openOverlaySettings(this)
            return
        }

        // Both permissions granted: start background BlockingService
        startBlockingService()
    }

    private fun startBlockingService() {
        if (!BlockingService.isRunning) {
            Log.d("FocusApp", "Day 4: Starting background BlockingService...")
            val serviceIntent = Intent(this, BlockingService::class.java).apply {
                action = BlockingService.ACTION_START
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(serviceIntent)
            } else {
                startService(serviceIntent)
            }
        } else {
            Log.d("FocusApp", "Day 4: BlockingService is already running in background.")
        }
    }
}
