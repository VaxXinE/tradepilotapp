package com.tradepilot.app.livechat

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.webkit.MimeTypeMap
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.lifecycle.lifecycleScope
import com.solidchat.sdk.SolidChatClient
import com.solidchat.sdk.SolidChatConfig
import com.solidchat.sdk.ui.SelectedImage
import com.solidchat.sdk.ui.SolidChatScreen
import java.io.File
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.coroutines.Dispatchers

/** Hosts the native SolidChat Compose screen; Flutter only launches it. */
class ChatActivity : ComponentActivity() {
    private lateinit var chatClient: SolidChatClient
    private var pendingImage: CompletableDeferred<Uri?>? = null

    private val photoPicker =
        registerForActivityResult(ActivityResultContracts.PickVisualMedia()) { uri ->
            pendingImage?.complete(uri)
            pendingImage = null
        }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val language = intent.getStringExtra(EXTRA_LANGUAGE) ?: "id"
        chatClient = SolidChatClient(applicationContext, SolidChatConfig(language = language))
        identifyWhenReady()

        setContent {
            ChatTheme {
                Box(
                    Modifier
                        .fillMaxSize()
                        .background(Color(0xFF09090B))
                        .safeDrawingPadding(),
                ) {
                    SolidChatScreen(
                        client = chatClient,
                        onRequestImage = ::pickImage,
                        onClose = ::finish,
                    )
                }
            }
        }
    }

    override fun onDestroy() {
        pendingImage?.complete(null)
        chatClient.close()
        super.onDestroy()
    }

    /** Identity can only be attached once the SDK has a visitor session. */
    private fun identifyWhenReady() {
        val token = LiveChatBridge.identityToken ?: return
        lifecycleScope.launch {
            chatClient.state.first { it.site != null }
            runCatching { chatClient.identify(token) }
        }
    }

    private suspend fun pickImage(): SelectedImage? {
        val deferred = CompletableDeferred<Uri?>().also { pendingImage = it }
        photoPicker.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly))
        val uri = deferred.await() ?: return null
        val mimeType = contentResolver.getType(uri) ?: "image/jpeg"
        return withContext(Dispatchers.IO) {
            val extension = MimeTypeMap.getSingleton().getExtensionFromMimeType(mimeType) ?: "jpg"
            val target = File(cacheDir, "livechat_upload_${System.currentTimeMillis()}.$extension")
            contentResolver.openInputStream(uri)?.use { input ->
                target.outputStream().use { input.copyTo(it) }
            } ?: return@withContext null
            SelectedImage(target, mimeType)
        }
    }

    companion object {
        private const val EXTRA_LANGUAGE = "language"

        fun launch(context: Context, language: String) {
            context.startActivity(
                Intent(context, ChatActivity::class.java).putExtra(EXTRA_LANGUAGE, language),
            )
        }
    }
}
