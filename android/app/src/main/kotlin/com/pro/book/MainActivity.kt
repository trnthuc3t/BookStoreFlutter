package com.pro.book

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.pro.book.ZaloPayMethodCallHandler

class MainActivity: FlutterActivity() {
    private val zaloPayHandler = ZaloPayMethodCallHandler()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        zaloPayHandler.attachToEngine(flutterEngine, this)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        super.cleanUpFlutterEngine(flutterEngine)
        zaloPayHandler.detachFromEngine()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        zaloPayHandler.handleNewIntent(intent)
    }
}

