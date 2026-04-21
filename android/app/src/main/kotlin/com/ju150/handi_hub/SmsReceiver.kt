package com.ju150.handi_hub

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import android.telephony.SmsMessage

class SmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Telephony.Sms.Intents.SMS_DELIVER_ACTION) return
        val pdus = intent.extras?.get("pdus") as? Array<*> ?: return
        val format = intent.getStringExtra("format")
        pdus.forEach { pdu ->
            val msg = SmsMessage.createFromPdu(pdu as ByteArray, format) ?: return@forEach
            LocalSmsStore.insert(
                context,
                msg.originatingAddress ?: "",
                msg.messageBody ?: "",
                msg.timestampMillis,
            )
        }
        SmsEventBridge.notifySmsReceived()
    }
}
