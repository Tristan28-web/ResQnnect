package com.yummyjoy.resqnnect

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.view.KeyEvent
import android.view.accessibility.AccessibilityEvent
import android.os.Handler
import android.os.Looper

class ResQnnectAccessibilityService : AccessibilityService() {

    private var volumeUpClickCount = 0
    private var lastVolumeUpClickTime: Long = 0
    private val handler = Handler(Looper.getMainLooper())
    private var isLongPressingDown = false
    private var longPressDownStartTime: Long = 0

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {}

    override fun onInterrupt() {}

    override fun onKeyEvent(event: KeyEvent?): Boolean {
        if (event == null) return false
        
        // Read preference from Flutter's SharedPreferences
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val selectedGesture = prefs.getString("flutter.sos_gesture", "none")

        val keyCode = event.keyCode
        val action = event.action

        // 1. TRIPLE VOLUME UP CLICK
        if (selectedGesture == "triple_volume_up" && keyCode == KeyEvent.KEYCODE_VOLUME_UP && action == KeyEvent.ACTION_DOWN) {
            val currentTime = System.currentTimeMillis()
            if (currentTime - lastVolumeUpClickTime < 500) {
                volumeUpClickCount++
            } else {
                volumeUpClickCount = 1
            }
            lastVolumeUpClickTime = currentTime

            if (volumeUpClickCount >= 3) {
                triggerSOS()
                volumeUpClickCount = 0
            }
            return true // Consume to prevent volume change during panic
        }

        // 2. LONG PRESS VOLUME DOWN (3s)
        if (selectedGesture == "long_press_volume_down" && keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) {
            if (action == KeyEvent.ACTION_DOWN && !isLongPressingDown) {
                isLongPressingDown = true
                longPressDownStartTime = System.currentTimeMillis()
                
                handler.postDelayed({
                    if (isLongPressingDown) {
                        triggerSOS()
                        isLongPressingDown = false
                    }
                }, 3000)
            } else if (action == KeyEvent.ACTION_UP) {
                isLongPressingDown = false
            }
            return true // Consume
        }

        return super.onKeyEvent(event)
    }

    private fun triggerSOS() {
        val intent = Intent(this, MainActivity::class.java)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
        intent.putExtra("triggerSOS", true)
        startActivity(intent)
    }
}
