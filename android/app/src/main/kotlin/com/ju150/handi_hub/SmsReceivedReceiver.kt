package com.ju150.handi_hub

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony

// Reçoit SMS_RECEIVED — se déclenche pour TOUTES les apps avec RECEIVE_SMS,
// même si l'app n'est pas l'app SMS par défaut.
// Permet de détecter les SMS entrants quelle que soit la configuration.
class SmsReceivedReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            SmsEventBridge.notifySmsReceived()
        }
    }
}
