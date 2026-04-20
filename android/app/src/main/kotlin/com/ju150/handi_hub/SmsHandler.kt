package com.ju150.handi_hub

import android.Manifest
import android.app.Activity
import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.provider.ContactsContract
import android.provider.Telephony
import android.telephony.SmsManager
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class SmsHandler(
    private val context: Context,
    private val activity: Activity,
) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL_NAME = "handi_hub/sms"
        const val PERMISSION_REQUEST_CODE = 1001
        private const val TAG = "SmsHandler"
    }

    private val smsPermissions = arrayOf(
        Manifest.permission.READ_SMS,
        Manifest.permission.SEND_SMS,
        Manifest.permission.RECEIVE_SMS,
        Manifest.permission.READ_CONTACTS,
    )

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isDefaultSmsApp"      -> result.success(isDefaultSmsApp())
            "requestDefaultSmsApp" -> requestDefaultSmsApp(result)
            "hasPermissions"       -> result.success(hasPermissions())
            "requestPermissions"   -> { requestPermissions(); result.success(null) }
            "getConversations" -> {
                if (!hasPermissions()) return result.error("NO_PERMISSION", "Permission SMS refusée", null)
                getConversations(result)
            }
            "getMessages" -> {
                if (!hasPermissions()) return result.error("NO_PERMISSION", "Permission SMS refusée", null)
                val threadId = call.argument<String>("threadId")
                    ?: return result.error("INVALID_ARG", "threadId manquant", null)
                getMessages(threadId, result)
            }
            "sendSms" -> {
                val address = call.argument<String>("address")
                    ?: return result.error("INVALID_ARG", "address manquant", null)
                val body = call.argument<String>("body")
                    ?: return result.error("INVALID_ARG", "body manquant", null)
                val threadId = call.argument<String>("threadId")
                sendSms(address, body, threadId, result)
            }
            "getContacts" -> getContacts(result)
            "deleteThread" -> {
                val threadId = call.argument<String>("threadId")
                    ?: return result.error("INVALID_ARG", "threadId manquant", null)
                deleteThread(threadId, result)
            }
            else -> result.notImplemented()
        }
    }

    private fun isDefaultSmsApp(): Boolean =
        Telephony.Sms.getDefaultSmsPackage(context) == context.packageName

    private fun requestDefaultSmsApp(result: MethodChannel.Result) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val roleManager = activity.getSystemService(android.app.role.RoleManager::class.java)
                if (roleManager != null
                    && roleManager.isRoleAvailable(android.app.role.RoleManager.ROLE_SMS)
                    && !roleManager.isRoleHeld(android.app.role.RoleManager.ROLE_SMS)
                ) {
                    val intent = roleManager.createRequestRoleIntent(android.app.role.RoleManager.ROLE_SMS)
                    activity.startActivityForResult(intent, 1002)
                }
            } else {
                @Suppress("DEPRECATION")
                val intent = android.content.Intent(Telephony.Sms.Intents.ACTION_CHANGE_DEFAULT)
                    .putExtra(Telephony.Sms.Intents.EXTRA_PACKAGE_NAME, context.packageName)
                activity.startActivity(intent)
            }
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "requestDefaultSmsApp: ${e.message}")
            result.error("ERROR", e.message, null)
        }
    }

    private fun hasPermissions(): Boolean =
        smsPermissions.all {
            ContextCompat.checkSelfPermission(context, it) == PackageManager.PERMISSION_GRANTED
        }

    private fun requestPermissions() {
        ActivityCompat.requestPermissions(activity, smsPermissions, PERMISSION_REQUEST_CODE)
    }

    // ── Conversations ─────────────────────────────────────────────────────────
    // Requête sur content://sms, dédupliquée par THREAD_ID, triée par DATE DESC.
    // On prend le premier message de chaque thread = le plus récent = le snippet.
    private fun getConversations(result: MethodChannel.Result) {
        try {
            val conversations = mutableListOf<Map<String, Any?>>()
            val cursor = context.contentResolver.query(
                Telephony.Sms.CONTENT_URI,
                arrayOf(
                    Telephony.Sms.THREAD_ID,
                    Telephony.Sms.ADDRESS,
                    Telephony.Sms.BODY,
                    Telephony.Sms.DATE,
                    Telephony.Sms.READ,
                    Telephony.Sms.TYPE,
                ),
                null, null,
                "${Telephony.Sms.DATE} DESC",
            ) ?: return result.success(conversations)

            val seen = mutableSetOf<String>()
            cursor.use {
                while (it.moveToNext()) {
                    val threadId = it.getString(
                        it.getColumnIndexOrThrow(Telephony.Sms.THREAD_ID)
                    ) ?: continue
                    if (!seen.add(threadId)) continue

                    conversations.add(mapOf(
                        "threadId" to threadId,
                        "address"  to (it.getString(it.getColumnIndexOrThrow(Telephony.Sms.ADDRESS)) ?: ""),
                        "snippet"  to (it.getString(it.getColumnIndexOrThrow(Telephony.Sms.BODY)) ?: ""),
                        "date"     to it.getLong(it.getColumnIndexOrThrow(Telephony.Sms.DATE)),
                        "isRead"   to (it.getInt(it.getColumnIndexOrThrow(Telephony.Sms.READ)) == 1),
                    ))
                }
            }
            result.success(conversations)
        } catch (e: Exception) {
            Log.e(TAG, "getConversations: ${e.message}")
            result.error("SMS_ERROR", e.message, null)
        }
    }

    // ── Messages d'un thread ──────────────────────────────────────────────────
    // Tous les messages (type inbox=1 ET sent=2) triés par DATE ASC.
    // Aucune déduplication : on veut TOUT l'historique.
    private fun getMessages(threadId: String, result: MethodChannel.Result) {
        try {
            val messages = mutableListOf<Map<String, Any?>>()
            val cursor = context.contentResolver.query(
                Telephony.Sms.CONTENT_URI,
                arrayOf(
                    Telephony.Sms._ID,
                    Telephony.Sms.THREAD_ID,
                    Telephony.Sms.ADDRESS,
                    Telephony.Sms.BODY,
                    Telephony.Sms.DATE,
                    Telephony.Sms.TYPE,
                ),
                // Filtre strict : uniquement ce thread, pas de draft ni de failed
                "${Telephony.Sms.THREAD_ID} = ? AND ${Telephony.Sms.TYPE} IN (1, 2)",
                arrayOf(threadId),
                "${Telephony.Sms.DATE} ASC",
            ) ?: return result.success(messages)

            cursor.use {
                while (it.moveToNext()) {
                    messages.add(mapOf(
                        "id"       to it.getString(it.getColumnIndexOrThrow(Telephony.Sms._ID)),
                        "threadId" to it.getString(it.getColumnIndexOrThrow(Telephony.Sms.THREAD_ID)),
                        "address"  to (it.getString(it.getColumnIndexOrThrow(Telephony.Sms.ADDRESS)) ?: ""),
                        "body"     to (it.getString(it.getColumnIndexOrThrow(Telephony.Sms.BODY)) ?: ""),
                        "date"     to it.getLong(it.getColumnIndexOrThrow(Telephony.Sms.DATE)),
                        "type"     to it.getInt(it.getColumnIndexOrThrow(Telephony.Sms.TYPE)),
                    ))
                }
            }
            result.success(messages)
        } catch (e: Exception) {
            Log.e(TAG, "getMessages: ${e.message}")
            result.error("SMS_ERROR", e.message, null)
        }
    }

    // ── Contacts ──────────────────────────────────────────────────────────────
    private fun getContacts(result: MethodChannel.Result) {
        try {
            val contacts = mutableListOf<Map<String, Any?>>()
            val cursor = context.contentResolver.query(
                ContactsContract.Contacts.CONTENT_URI,
                arrayOf(
                    ContactsContract.Contacts._ID,
                    ContactsContract.Contacts.DISPLAY_NAME_PRIMARY,
                ),
                "${ContactsContract.Contacts.HAS_PHONE_NUMBER} = 1",
                null,
                "${ContactsContract.Contacts.DISPLAY_NAME_PRIMARY} ASC",
            ) ?: return result.success(contacts)

            cursor.use {
                while (it.moveToNext()) {
                    val id = it.getString(it.getColumnIndexOrThrow(ContactsContract.Contacts._ID))
                    val name = it.getString(it.getColumnIndexOrThrow(ContactsContract.Contacts.DISPLAY_NAME_PRIMARY))
                        ?: continue
                    val phones = mutableListOf<String>()
                    context.contentResolver.query(
                        ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
                        arrayOf(ContactsContract.CommonDataKinds.Phone.NUMBER),
                        "${ContactsContract.CommonDataKinds.Phone.CONTACT_ID} = ?",
                        arrayOf(id),
                        null,
                    )?.use { pc ->
                        while (pc.moveToNext()) {
                            val n = pc.getString(pc.getColumnIndexOrThrow(ContactsContract.CommonDataKinds.Phone.NUMBER))
                            if (!n.isNullOrEmpty()) phones.add(n)
                        }
                    }
                    if (phones.isNotEmpty()) {
                        contacts.add(mapOf(
                            "id"    to id,
                            "name"  to name,
                            "phones" to phones,
                            "photo" to loadContactPhoto(id),
                        ))
                    }
                }
            }
            result.success(contacts)
        } catch (e: Exception) {
            Log.e(TAG, "getContacts: ${e.message}")
            result.error("CONTACTS_ERROR", e.message, null)
        }
    }

    private fun loadContactPhoto(contactId: String): ByteArray? {
        return try {
            val uri = ContentUris.withAppendedId(
                ContactsContract.Contacts.CONTENT_URI, contactId.toLong()
            )
            ContactsContract.Contacts.openContactPhotoInputStream(
                context.contentResolver, uri, false
            )?.use { it.readBytes() }
        } catch (e: Exception) {
            null
        }
    }

    // ── Suppression d'un thread ───────────────────────────────────────────────
    private fun deleteThread(threadId: String, result: MethodChannel.Result) {
        try {
            val deleted = context.contentResolver.delete(
                Telephony.Sms.CONTENT_URI,
                "${Telephony.Sms.THREAD_ID} = ?",
                arrayOf(threadId),
            )
            result.success(deleted > 0)
        } catch (e: Exception) {
            Log.e(TAG, "deleteThread: ${e.message}")
            result.error("DELETE_ERROR", e.message, null)
        }
    }

    // ── Envoi SMS ─────────────────────────────────────────────────────────────
    // 1. Envoie le SMS via SmsManager.
    // 2. Insère le message dans la base locale (indispensable : SmsManager n'insère PAS
    //    automatiquement les messages envoyés dans la base Android).
    private fun sendSms(address: String, body: String, threadId: String?, result: MethodChannel.Result) {
        try {
            val smsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                context.getSystemService(SmsManager::class.java)
            } else {
                @Suppress("DEPRECATION")
                SmsManager.getDefault()
            }
            smsManager?.sendTextMessage(address, null, body, null, null)
                ?: return result.error("SMS_ERROR", "SmsManager non disponible", null)

            val resolvedThreadId = insertSentMessage(address, body, threadId)
            result.success(resolvedThreadId ?: threadId ?: "")
        } catch (e: Exception) {
            Log.e(TAG, "sendSms: ${e.message}")
            result.error("SEND_ERROR", e.message, null)
        }
    }

    // Insère le message envoyé et retourne le threadId résolu depuis la DB.
    private fun insertSentMessage(address: String, body: String, threadId: String?): String? {
        return try {
            val values = ContentValues().apply {
                put(Telephony.Sms.ADDRESS, address)
                put(Telephony.Sms.BODY, body)
                put(Telephony.Sms.DATE, System.currentTimeMillis())
                put(Telephony.Sms.DATE_SENT, System.currentTimeMillis())
                put(Telephony.Sms.TYPE, Telephony.Sms.MESSAGE_TYPE_SENT)
                put(Telephony.Sms.READ, 1)
                put(Telephony.Sms.STATUS, Telephony.Sms.STATUS_NONE)
                if (!threadId.isNullOrEmpty()) {
                    threadId.toLongOrNull()?.let { put(Telephony.Sms.THREAD_ID, it) }
                }
            }
            val uri = context.contentResolver.insert(Telephony.Sms.CONTENT_URI, values)
            if (uri != null) {
                context.contentResolver.query(
                    uri, arrayOf(Telephony.Sms.THREAD_ID), null, null, null
                )?.use { c ->
                    if (c.moveToFirst()) c.getString(c.getColumnIndexOrThrow(Telephony.Sms.THREAD_ID))
                    else null
                }
            } else null
        } catch (e: Exception) {
            Log.w(TAG, "insertSentMessage: ${e.message}")
            null
        }
    }
}
