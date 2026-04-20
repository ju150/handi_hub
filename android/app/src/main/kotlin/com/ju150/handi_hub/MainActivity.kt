package com.ju150.handi_hub

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private lateinit var smsHandler: SmsHandler

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        smsHandler = SmsHandler(this, this)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SmsHandler.CHANNEL_NAME,
        ).setMethodCallHandler(smsHandler)

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SmsEventBridge.CHANNEL_NAME,
        ).setStreamHandler(SmsEventBridge)
    }
}
