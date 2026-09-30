package com.tradepilot.app

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import androidx.core.content.FileProvider
import com.tradepilot.app.livechat.LiveChatBridge
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        LiveChatBridge.register(this, flutterEngine.dartExecutor.binaryMessenger)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "id.tradepilot.app/clipboard",
        ).setMethodCallHandler { call, result ->
            val bytes = call.arguments as? ByteArray
            if (call.method != "copyImage" || bytes == null) {
                result.notImplemented()
                return@setMethodCallHandler
            }
            runCatching {
                val directory = File(cacheDir, "shared_reasoning").apply { mkdirs() }
                val image = File(directory, "tradepilot_reasoning.png").apply {
                    writeBytes(bytes)
                }
                val uri = FileProvider.getUriForFile(
                    this,
                    "$packageName.fileprovider",
                    image,
                )
                val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                clipboard.setPrimaryClip(
                    ClipData.newUri(contentResolver, "TradePilot analysis reasoning", uri),
                )
            }.onSuccess { result.success(null) }
                .onFailure { result.error("copy_failed", it.message, null) }
        }
    }
}
