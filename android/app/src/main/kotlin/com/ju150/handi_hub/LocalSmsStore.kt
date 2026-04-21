package com.ju150.handi_hub

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

object LocalSmsStore {

    private const val PREFS_NAME = "handi_hub_sms_store"
    private const val KEY_MESSAGES = "messages"
    private const val MAX_MESSAGES = 500

    fun insert(context: Context, address: String, body: String, dateSent: Long) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val arr = load(prefs)

        for (i in 0 until arr.length()) {
            val obj = arr.getJSONObject(i)
            if (obj.optLong("dateSent") == dateSent && obj.optString("body") == body) return
        }

        val msg = JSONObject().apply {
            put("address", address)
            put("body", body)
            put("date", System.currentTimeMillis())
            put("dateSent", dateSent)
        }

        val next = JSONArray()
        next.put(msg)
        for (i in 0 until minOf(arr.length(), MAX_MESSAGES - 1)) next.put(arr.getJSONObject(i))

        prefs.edit().putString(KEY_MESSAGES, next.toString()).apply()
    }

    fun getForAddress(context: Context, coreDigits: String): List<Map<String, Any?>> {
        val arr = load(context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE))
        val result = mutableListOf<Map<String, Any?>>()
        for (i in 0 until arr.length()) {
            val obj = arr.getJSONObject(i)
            val addr = obj.optString("address").replace(Regex("[^0-9]"), "").trimStart('0')
            if (coreDigits.isNotEmpty() && addr.contains(coreDigits)) {
                result.add(mapOf(
                    "id"       to "local_$i",
                    "threadId" to "",
                    "address"  to obj.optString("address"),
                    "body"     to obj.optString("body"),
                    "date"     to obj.optLong("date"),
                    "type"     to 1,
                ))
            }
        }
        return result
    }

    private fun load(prefs: android.content.SharedPreferences): JSONArray = try {
        JSONArray(prefs.getString(KEY_MESSAGES, "[]") ?: "[]")
    } catch (e: Exception) {
        JSONArray()
    }
}
