package com.example.smart_card_scanner_app

import android.app.PendingIntent
import android.content.Intent
import android.nfc.NfcAdapter
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.smartCardScannerApp/nfc"
    private var nfcAdapter: NfcAdapter? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        nfcAdapter = NfcAdapter.getDefaultAdapter(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "enableForegroundDispatch" -> {
                        // Η εφαρμογή "καταπίνει" όλα τα NFC intents
                        // και δεν τα αφήνει να ανοίξουν νέα Activity
                        val nfcIntent = Intent(this, javaClass).apply {
                            addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
                        }
                        val pendingIntent = PendingIntent.getActivity(
                            this, 0, nfcIntent,
                            PendingIntent.FLAG_MUTABLE
                        )
                        nfcAdapter?.enableForegroundDispatch(
                            this, pendingIntent, null, null
                        )
                        result.success(null)
                    }
                    "disableForegroundDispatch" -> {
                        nfcAdapter?.disableForegroundDispatch(this)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // ✅ Απαραίτητο: όταν έρχεται νέο NFC intent ενώ η εφαρμογή τρέχει,
    // το "καταπίνουμε" εδώ και δεν κάνει τίποτα
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Απλά το αγνοούμε — το NFC manager της Flutter το χειρίζεται ήδη
    }
}