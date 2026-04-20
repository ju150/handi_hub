package com.ju150.handi_hub

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

// Requis pour que l'app puisse être définie comme application SMS par défaut.
// Les MMS ne sont pas supportés dans cette V1.
class MmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        // MMS non géré en V1
    }
}
