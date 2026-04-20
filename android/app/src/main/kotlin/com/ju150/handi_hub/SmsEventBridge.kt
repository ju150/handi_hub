package com.ju150.handi_hub

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

// Pont singleton entre le BroadcastReceiver (natif) et le stream Flutter (EventChannel).
// Le BroadcastReceiver peut tourner sur n'importe quel thread → on force le main thread.
object SmsEventBridge : EventChannel.StreamHandler {

    const val CHANNEL_NAME = "handi_hub/sms_events"

    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    fun notifySmsReceived() {
        mainHandler.post {
            eventSink?.success("sms_received")
        }
    }
}
