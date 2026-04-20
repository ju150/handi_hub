package com.ju150.handi_hub

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony

// Reçoit les SMS entrants quand l'app est l'app SMS par défaut.
// Notifie Flutter via SmsEventBridge pour rafraîchir l'UI.
class SmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Telephony.Sms.Intents.SMS_DELIVER_ACTION) {
            SmsEventBridge.notifySmsReceived()
        }
    }
}
