package com.tradepilot.app.livechat

import android.content.Context
import com.solidchat.sdk.SolidChatClient
import com.solidchat.sdk.SolidChatConfig
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/** Flutter <-> SolidChat SDK bridge (`id.tradepilot.app/live_chat`). */
object LiveChatBridge {
    private const val CHANNEL = "id.tradepilot.app/live_chat"

    /** Backend-issued identity JWT waiting for the next chat session. */
    @Volatile
    var identityToken: String? = null
        private set

    fun register(context: Context, messenger: BinaryMessenger) {
        val appContext = context.applicationContext
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "open" -> {
                    val language = call.argument<String>("language") ?: "id"
                    ChatActivity.launch(context, language)
                    result.success(null)
                }
                "identify" -> {
                    identityToken = call.argument<String>("token")?.takeIf { it.isNotBlank() }
                    result.success(null)
                }
                "reset" -> {
                    identityToken = null
                    // Clears the persisted visitor/conversation for the default site.
                    SolidChatClient(appContext, SolidChatConfig()).apply {
                        reset()
                        close()
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
