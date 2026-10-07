package com.focusapp.app

import android.os.Bundle
import android.util.Log
import com.focusapp.app.blocking.ForegroundAppDetector
import com.focusapp.app.permissions.PermissionHelper
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    private lateinit var foregroundAppDetector: ForegroundAppDetector

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        foregroundAppDetector = ForegroundAppDetector(this)
    }

    override fun onResume() {
        super.onResume()
        if (PermissionHelper.hasUsageStatsPermission(this)) {
            val currentApp = foregroundAppDetector.getForegroundAppPackage()
            Log.d("FocusApp", "Day 2 Test: Usage access granted. Current foreground app: $currentApp")
        } else {
            Log.d("FocusApp", "Day 2 Test: Usage access NOT granted. Prompting user to enable settings...")
            PermissionHelper.openUsageAccessSettings(this)
        }
    }
}
