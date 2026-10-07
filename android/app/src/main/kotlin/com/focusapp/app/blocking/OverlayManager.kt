package com.focusapp.app.blocking

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

class OverlayManager(private val context: Context) {

    private val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as? WindowManager
    private val mainHandler = Handler(Looper.getMainLooper())
    private var overlayView: View? = null
    var isShowing: Boolean = false
        private set

    /**
     * Shows a full-screen blocked overlay over whatever app is currently open.
     */
    fun showOverlay(appName: String = "This app") {
        mainHandler.post {
            if (isShowing || windowManager == null) return@post

            val layoutParams = WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                        WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                        WindowManager.LayoutParams.FLAG_FULLSCREEN,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.CENTER
            }

            val rootLayout = LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                gravity = Gravity.CENTER
                setBackgroundColor(Color.parseColor("#0F172A")) // Modern dark slate
                setPadding(64, 64, 64, 64)
            }

            // Icon / Emoji
            val iconView = TextView(context).apply {
                text = "🛑"
                textSize = 64f
                gravity = Gravity.CENTER
            }
            rootLayout.addView(iconView)

            // Header Title
            val titleView = TextView(context).apply {
                text = "Focus App"
                textSize = 28f
                setTextColor(Color.WHITE)
                typeface = Typeface.DEFAULT_BOLD
                gravity = Gravity.CENTER
                setPadding(0, 32, 0, 16)
            }
            rootLayout.addView(titleView)

            // Blocked Message
            val messageView = TextView(context).apply {
                text = "$appName is blocked during your focus session."
                textSize = 18f
                setTextColor(Color.parseColor("#94A3B8")) // slate-400
                gravity = Gravity.CENTER
                setPadding(0, 0, 0, 48)
            }
            rootLayout.addView(messageView)

            // Return Home Button
            val homeButton = Button(context).apply {
                text = "Go to Home Screen"
                setBackgroundColor(Color.parseColor("#6366F1")) // Indigo
                setTextColor(Color.WHITE)
                textSize = 16f
                setPadding(48, 24, 48, 24)
                setOnClickListener {
                    hideOverlay()
                    val homeIntent = Intent(Intent.ACTION_MAIN).apply {
                        addCategory(Intent.CATEGORY_HOME)
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                    context.startActivity(homeIntent)
                }
            }
            rootLayout.addView(homeButton)

            try {
                windowManager.addView(rootLayout, layoutParams)
                overlayView = rootLayout
                isShowing = true
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    /**
     * Hides and removes the full-screen blocked overlay.
     */
    fun hideOverlay() {
        mainHandler.post {
            if (!isShowing || overlayView == null || windowManager == null) return@post

            try {
                windowManager.removeView(overlayView)
            } catch (e: Exception) {
                e.printStackTrace()
            } finally {
                overlayView = null
                isShowing = false
            }
        }
    }
}
