package com.antigravity.finance.finance_app

import android.Manifest
import android.content.pm.PackageManager
import android.net.Uri
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    private val SMS_CHANNEL = "com.spendvault.app/sms_reader"
    private val SMS_PERMISSION_REQUEST_CODE = 9912
    private var pendingSmsPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasSmsPermission" -> {
                    val granted = ContextCompat.checkSelfPermission(
                        this,
                        Manifest.permission.READ_SMS
                    ) == PackageManager.PERMISSION_GRANTED
                    result.success(granted)
                }
                "requestSmsPermission" -> {
                    val granted = ContextCompat.checkSelfPermission(
                        this,
                        Manifest.permission.READ_SMS
                    ) == PackageManager.PERMISSION_GRANTED
                    if (granted) {
                        result.success(true)
                    } else {
                        pendingSmsPermissionResult = result
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(Manifest.permission.READ_SMS, Manifest.permission.RECEIVE_SMS),
                            SMS_PERMISSION_REQUEST_CODE
                        )
                    }
                }
                "readSmsInbox" -> {
                    val limit = call.argument<Int>("limit") ?: 200
                    try {
                        val messages = readSmsMessages(limit)
                        result.success(messages)
                    } catch (e: Exception) {
                        result.error("READ_FAILED", e.localizedMessage, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == SMS_PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingSmsPermissionResult?.success(granted)
            pendingSmsPermissionResult = null
        }
    }

    private fun readSmsMessages(limit: Int): List<Map<String, Any>> {
        val messages = mutableListOf<Map<String, Any>>()
        val uri = Uri.parse("content://sms/inbox")
        val projection = arrayOf("_id", "address", "body", "date")

        val cursor = contentResolver.query(
            uri,
            projection,
            null,
            null,
            "date DESC LIMIT $limit"
        )

        cursor?.use {
            val idIndex = it.getColumnIndex("_id")
            val addressIndex = it.getColumnIndex("address")
            val bodyIndex = it.getColumnIndex("body")
            val dateIndex = it.getColumnIndex("date")

            while (it.moveToNext()) {
                val id = if (idIndex != -1) it.getString(idIndex) else ""
                val address = if (addressIndex != -1) it.getString(addressIndex) ?: "" else ""
                val body = if (bodyIndex != -1) it.getString(bodyIndex) ?: "" else ""
                val date = if (dateIndex != -1) it.getLong(dateIndex) else 0L

                if (body.isNotBlank()) {
                    val map = HashMap<String, Any>()
                    map["id"] = id
                    map["sender"] = address
                    map["body"] = body
                    map["date"] = date
                    messages.add(map)
                }
            }
        }

        return messages
    }
}

