package com.ju150.handi_hub

import android.app.Service
import android.content.Intent
import android.os.IBinder

// Requis pour que l'app puisse être définie comme application SMS par défaut.
// Permet de répondre aux messages depuis d'autres contextes (ex: notifications appel entrant).
class RespondViaMessageService : Service() {
    override fun onBind(intent: Intent): IBinder? = null
}
