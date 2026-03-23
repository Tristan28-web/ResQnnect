package com.yummyjoy.resqnnect

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.telephony.SmsManager
import android.util.Log

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.yummyjoy.resqnnect/sos"
    private val SMS_CHANNEL = "com.yummyjoy.resqnnect/sms"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "sendSMS") {
                val phoneNumber = call.argument<String>("phoneNumber")
                val message = call.argument<String>("message")
                
                if (phoneNumber != null && message != null) {
                    try {
                        val smsManager = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
                            this.getSystemService(SmsManager::class.java)
                        } else {
                            SmsManager.getDefault()
                        }
                        
                        // Split message if it's too long
                        val parts = smsManager.divideMessage(message)
                        smsManager.sendMultipartTextMessage(phoneNumber, null, parts, null, null)
                        
                        // Show OS-level confirmation
                        android.widget.Toast.makeText(this, "SOS Message Dispatched to Inner Circle", android.widget.Toast.LENGTH_SHORT).show()
                        
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e("SMS", "Failed to send SMS: ${e.message}")
                        android.widget.Toast.makeText(this, "SMS Gateway Failed: ${e.message}", android.widget.Toast.LENGTH_LONG).show()
                        result.error("SMS_FAILED", e.message, null)
                    }
                } else {
                    result.error("INVALID_ARGUMENTS", "Phone number or message is null", null)
                }
            } else {
                result.notImplemented()
            }
        }

        // Check initial intent (if app was started by SOS gesture)
        processSOSIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        processSOSIntent(intent)
    }

    private fun processSOSIntent(intent: Intent) {
        if (intent.getBooleanExtra("triggerSOS", false)) {
            methodChannel?.invokeMethod("triggerSOS", null)
        }
    }
}
