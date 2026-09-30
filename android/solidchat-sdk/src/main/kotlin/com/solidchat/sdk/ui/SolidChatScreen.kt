package com.solidchat.sdk.ui

import android.graphics.BitmapFactory
import android.util.LruCache
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Checkbox
import androidx.compose.material3.CheckboxDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.solidchat.sdk.Attachment
import com.solidchat.sdk.ChatMessage
import com.solidchat.sdk.PreChatInput
import com.solidchat.sdk.SolidChatClient
import com.solidchat.sdk.SolidChatSessionContext
import com.solidchat.sdk.SolidChatState
import com.solidchat.sdk.TicketInput
import java.io.File
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request

data class SelectedImage(val file: File, val mimeType: String, val caption: String = "")

// Vendored copy (see VENDORED.md). Colours are explicit so the screen reads the same no matter
// which MaterialTheme the host app wraps it in.
private val ScreenBg = Color(0xFF09090B)
private val BarBg = Color(0xFF18181B)
private val FieldBg = Color(0xFF111114)
private val Border = Color(0xFF3F3F46)
private val TextPrimary = Color(0xFFFAFAFA)
private val TextMuted = Color(0xFFA1A1AA)
private val TextFaint = Color(0xFF71717A)
private val BubbleOther = Color(0xFF27272A)
private val ErrorRed = Color(0xFFF87171)

/** Runs an SDK call; failures are reported through the screen instead of crashing the app. */
private typealias SafeRun = (suspend () -> Unit) -> Unit

@Composable
fun SolidChatScreen(
    client: SolidChatClient,
    modifier: Modifier = Modifier,
    sessionContext: SolidChatSessionContext = SolidChatSessionContext(),
    onRequestImage: (suspend () -> SelectedImage?)? = null,
    onClose: (() -> Unit)? = null,
) {
    val state by client.state.collectAsStateWithLifecycle()
    val scope = rememberCoroutineScope()
    var ratingVisible by remember { mutableStateOf(false) }
    var localError by remember { mutableStateOf<String?>(null) }

    // Client calls re-throw after publishing the error (rate limit, offline, validation). An
    // unhandled throw here would crash the host app and cancel this scope for good.
    val run: SafeRun = remember(scope) {
        { block ->
            scope.launch {
                try {
                    block()
                } catch (e: CancellationException) {
                    throw e
                } catch (e: Exception) {
                    localError = e.message?.takeIf { it.isNotBlank() } ?: "Terjadi kesalahan. Coba lagi."
                }
            }
        }
    }

    LaunchedEffect(client) { client.initialize(sessionContext) }
    LaunchedEffect(state.ended, state.site?.settings?.ratingFormEnabled) {
        if (state.ended && state.site?.settings?.ratingFormEnabled == true) ratingVisible = true
    }

    val banner = localError ?: state.error?.takeIf { state.site != null }?.message
    LaunchedEffect(banner) {
        if (banner != null) {
            delay(6_000)
            localError = null
            client.clearError()
        }
    }

    val accent = remember(state.site?.widgetColor) { parseColor(state.site?.widgetColor) }
    Column(modifier.fillMaxSize().background(ScreenBg)) {
        Header(
            state, accent, onClose,
            onEnd = { run { client.closeConversation() } },
            onNew = { run { client.startNewConversation() } },
        )
        Box(Modifier.weight(1f).fillMaxWidth()) {
            when {
                state.loading -> CenterMessage { CircularProgressIndicator(color = accent) }
                state.error != null && state.site == null ->
                    CenterMessage { Text(state.error?.message.orEmpty(), color = ErrorRed) }
                state.site?.settings?.widgetEnabled == false ->
                    CenterMessage { Text(state.site?.offlineMessage.orEmpty(), color = TextMuted) }
                state.conversation == null -> CenterMessage { Text("Menyiapkan percakapan...", color = TextMuted) }
                state.offline -> TicketForm(
                    state, accent,
                    onSubmit = { input -> run { client.submitTicket(input) } },
                    onReset = client::clearTicketNotice,
                )
                !state.leadSubmitted -> PreChatForm(accent) { input -> run { client.submitPreChat(input) } }
                else -> ChatContent(state, accent, client, run, onRequestImage)
            }
            if (banner != null) ErrorBanner(banner, Modifier.align(Alignment.TopCenter))
        }
    }

    if (ratingVisible) {
        RatingDialog(accent, onDismiss = { ratingVisible = false }) { score, comment ->
            run {
                client.submitFeedback(score, comment)
                ratingVisible = false
            }
        }
    }
}

@Composable
private fun Header(
    state: SolidChatState,
    accent: Color,
    onClose: (() -> Unit)?,
    onEnd: () -> Unit,
    onNew: () -> Unit,
) {
    val status = when {
        state.agentHandling -> "Terhubung dengan agent"
        state.connected -> "Online"
        else -> "Menghubungkan..."
    }
    val dot = if (state.connected) accent else TextFaint
    Row(
        Modifier.fillMaxWidth().background(BarBg).padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Column(Modifier.weight(1f)) {
            Text(state.site?.name ?: "SolidChat", color = TextPrimary, style = MaterialTheme.typography.titleMedium)
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                Box(Modifier.size(7.dp).background(dot, CircleShape))
                Text(status, color = TextMuted, style = MaterialTheme.typography.labelSmall)
            }
        }
        if (state.ended) {
            TextButton(onClick = onNew) { Text("Pesan Baru", color = accent) }
        } else if (state.conversation != null) {
            TextButton(onClick = onEnd) { Text("Akhiri", color = TextMuted) }
        }
        if (onClose != null) TextButton(onClick = onClose) { Text("Tutup", color = TextMuted) }
    }
}

@Composable
private fun ChatContent(
    state: SolidChatState,
    accent: Color,
    client: SolidChatClient,
    run: SafeRun,
    onRequestImage: (suspend () -> SelectedImage?)?,
) {
    val listState = rememberLazyListState()
    var text by remember { mutableStateOf("") }
    var preview by remember { mutableStateOf<ImageBitmap?>(null) }
    LaunchedEffect(state.messages.size) {
        if (state.messages.isNotEmpty()) listState.animateScrollToItem(state.messages.lastIndex)
    }
    val settings = state.site?.settings
    val canAskAgent = !state.ended && !state.agentHandling && !state.agentRequested &&
        settings?.showAgentButton != false
    val canSendPhoto = state.agentHandling && settings?.allowAttachments == true && onRequestImage != null

    Column(Modifier.fillMaxSize()) {
        LazyColumn(
            Modifier.weight(1f).fillMaxWidth().padding(horizontal = 12.dp),
            state = listState,
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            item { Spacer(Modifier.height(8.dp)) }
            items(state.messages, key = { it.id }) { MessageBubble(it, accent, client) { preview = it } }
            if (state.agentTyping || state.aiTyping) {
                item {
                    Notice(
                        if (state.agentTyping) "${state.agentTypingName ?: "Agent"} sedang mengetik..."
                        else "${state.site?.aiName ?: "AI"} sedang mengetik...",
                    )
                }
            }
            item { Spacer(Modifier.height(4.dp)) }
        }

        preview?.let { ImagePreview(it) { preview = null } }

        if (state.ended) {
            Notice("Percakapan ini sudah diakhiri. Pilih Pesan Baru untuk memulai kembali.")
            return@Column
        }

        when {
            state.agentHandling -> StatusPill(
                if (canSendPhoto) "Agent terhubung. Kamu bisa kirim foto." else "Agent terhubung.",
                accent,
                spinner = false,
            )
            state.agentRequested -> StatusPill("Menghubungkan ke agent...", accent, spinner = true)
            canAskAgent -> OutlinedButton(
                onClick = { run { client.requestAgent() } },
                modifier = Modifier.align(Alignment.CenterHorizontally).padding(top = 6.dp),
                border = BorderStroke(1.dp, accent),
                colors = ButtonDefaults.outlinedButtonColors(contentColor = accent),
            ) { Text(settings?.agentButtonLabel ?: "Hubungi Agent") }
        }

        Row(
            Modifier.fillMaxWidth().background(BarBg).padding(8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            if (canSendPhoto) {
                TextButton(onClick = {
                    run { onRequestImage?.invoke()?.let { client.uploadImage(it.file, it.mimeType, it.caption) } }
                }) { Text("Foto", color = accent) }
            }
            OutlinedTextField(
                value = text,
                onValueChange = { text = it.take(4000); client.notifyTyping(it.isNotBlank()) },
                modifier = Modifier.weight(1f),
                placeholder = { Text("Tulis pesan...") },
                maxLines = 4,
                enabled = state.connected,
                shape = RoundedCornerShape(14.dp),
                colors = fieldColors(accent),
            )
            Button(
                onClick = {
                    val outgoing = text
                    text = ""
                    client.notifyTyping(false)
                    run { client.sendMessage(outgoing) }
                },
                enabled = text.isNotBlank() && state.connected,
                colors = accentButton(accent),
                modifier = Modifier.padding(start = 8.dp),
            ) { Text("Kirim") }
        }
    }
}

@Composable
private fun MessageBubble(message: ChatMessage, accent: Color, client: SolidChatClient, onPreview: (ImageBitmap) -> Unit) {
    val visitor = message.senderType == "VISITOR"
    val shape = RoundedCornerShape(
        topStart = 16.dp, topEnd = 16.dp,
        bottomStart = if (visitor) 16.dp else 4.dp,
        bottomEnd = if (visitor) 4.dp else 16.dp,
    )
    val images = if (message.messageType == "IMAGE") message.attachments else emptyList()
    Row(Modifier.fillMaxWidth(), horizontalArrangement = if (visitor) Arrangement.End else Arrangement.Start) {
        Column(
            Modifier.widthIn(max = 310.dp)
                .background(if (visitor) accent else BubbleOther, shape)
                .padding(horizontal = 12.dp, vertical = 9.dp),
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            if (!visitor) {
                Text(
                    message.senderName ?: if (message.senderType == "AI") "AI" else "Agent",
                    color = accent,
                    style = MaterialTheme.typography.labelSmall,
                )
            }
            images.forEach { AttachmentImage(client, it, onPreview) }
            val text = message.content.ifBlank { if (message.messageType == "IMAGE" && images.isEmpty()) "Gambar" else "" }
            if (text.isNotEmpty()) Text(text, color = if (visitor) Color.Black else TextPrimary)
        }
    }
}

/** Decoded images by attachment id, capped at ~24 MB so long chats do not bloat memory. */
private val imageCache = object : LruCache<String, ImageBitmap>(24 * 1024) {
    override fun sizeOf(key: String, value: ImageBitmap) = value.width * value.height * 4 / 1024
}
private val imageHttp = OkHttpClient()
private const val MAX_IMAGE_EDGE = 1024

/** Attachments are private: ask the API for a short-lived signed URL, then download and decode it. */
private suspend fun loadAttachment(client: SolidChatClient, attachment: Attachment): ImageBitmap =
    imageCache.get(attachment.id) ?: withContext(Dispatchers.IO) {
        val url = client.getAttachmentUrl(attachment.id)
        val bytes = imageHttp.newCall(Request.Builder().url(url).build()).execute().use { response ->
            check(response.isSuccessful) { "HTTP ${response.code}" }
            checkNotNull(response.body) { "Empty body" }.bytes()
        }
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
        var sample = 1
        while (maxOf(bounds.outWidth, bounds.outHeight) / (sample * 2) >= MAX_IMAGE_EDGE) sample *= 2
        val decoded = BitmapFactory.decodeByteArray(bytes, 0, bytes.size, BitmapFactory.Options().apply { inSampleSize = sample })
        checkNotNull(decoded) { "Unsupported image" }.asImageBitmap().also { imageCache.put(attachment.id, it) }
    }

@Composable
private fun AttachmentImage(client: SolidChatClient, attachment: Attachment, onPreview: (ImageBitmap) -> Unit) {
    var bitmap by remember(attachment.id) { mutableStateOf(imageCache.get(attachment.id)) }
    var failed by remember(attachment.id) { mutableStateOf(false) }
    var attempt by remember(attachment.id) { mutableIntStateOf(0) }
    LaunchedEffect(attachment.id, attempt) {
        if (bitmap != null) return@LaunchedEffect
        failed = false
        try {
            bitmap = loadAttachment(client, attachment)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            failed = true
        }
    }
    val current = bitmap
    val frame = Modifier.widthIn(max = 240.dp).clip(RoundedCornerShape(10.dp))
    when {
        current != null -> Image(
            bitmap = current,
            contentDescription = attachment.fileName,
            contentScale = ContentScale.Fit,
            modifier = frame.aspectRatio(current.width.toFloat() / current.height).clickable { onPreview(current) },
        )
        failed -> Text(
            "Gambar tidak dapat dimuat. Ketuk untuk coba lagi.",
            color = TextMuted,
            style = MaterialTheme.typography.bodySmall,
            modifier = frame.clickable { attempt++ }.padding(vertical = 4.dp),
        )
        else -> Box(frame.size(width = 160.dp, height = 110.dp).background(FieldBg), contentAlignment = Alignment.Center) {
            CircularProgressIndicator(Modifier.size(22.dp), color = TextMuted, strokeWidth = 2.dp)
        }
    }
}

@Composable
private fun ImagePreview(image: ImageBitmap, onDismiss: () -> Unit) {
    Dialog(onDismissRequest = onDismiss, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        Box(Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.92f)).clickable(onClick = onDismiss), contentAlignment = Alignment.Center) {
            Image(bitmap = image, contentDescription = null, contentScale = ContentScale.Fit, modifier = Modifier.fillMaxSize().padding(12.dp))
        }
    }
}

@Composable
private fun PreChatForm(accent: Color, onSubmit: (PreChatInput) -> Unit) {
    var name by remember { mutableStateOf("") }
    var email by remember { mutableStateOf("") }
    var phone by remember { mutableStateOf("") }
    var message by remember { mutableStateOf("") }
    var consent by remember { mutableStateOf(false) }
    val valid = name.isNotBlank() && EMAIL.matches(email.trim()) &&
        phone.count(Char::isDigit) >= 8 && message.isNotBlank() && consent
    FormColumn("Sebelum memulai, boleh kami tahu sedikit tentang Anda?") {
        Field(name, { name = it.take(120) }, "Nama Anda", accent)
        Field(email, { email = it.take(160) }, "Email", accent, KeyboardType.Email)
        Field(phone, { phone = it.take(30) }, "No. Telepon / WhatsApp", accent, KeyboardType.Phone)
        Field(message, { message = it.take(2000) }, "Pesan pertama", accent, lines = 3)
        Row(verticalAlignment = Alignment.CenterVertically) {
            Checkbox(
                checked = consent,
                onCheckedChange = { consent = it },
                colors = CheckboxDefaults.colors(
                    checkedColor = accent,
                    checkmarkColor = Color.Black,
                    uncheckedColor = TextMuted,
                ),
            )
            Text(
                "Saya menyetujui penggunaan data sesuai kebijakan privasi.",
                color = TextMuted,
                style = MaterialTheme.typography.bodySmall,
            )
        }
        Button(
            onClick = { onSubmit(PreChatInput(name.trim(), email.trim(), phone.trim(), message.trim(), consent)) },
            enabled = valid,
            modifier = Modifier.fillMaxWidth(),
            colors = accentButton(accent),
        ) { Text("Mulai Percakapan") }
    }
}

@Composable
private fun TicketForm(state: SolidChatState, accent: Color, onSubmit: (TicketInput) -> Unit, onReset: () -> Unit) {
    if (state.ticketNumber != null) {
        CenterMessage {
            Text("Tiket Anda berhasil dikirim", color = TextPrimary)
            Text(state.ticketNumber.orEmpty(), color = accent)
            Text("Tim kami akan menghubungi Anda secepatnya.", color = TextMuted)
            Button(onClick = onReset, colors = accentButton(accent)) { Text("Kirim tiket lagi") }
        }
        return
    }
    var name by remember { mutableStateOf("") }
    var email by remember { mutableStateOf("") }
    var phone by remember { mutableStateOf("") }
    var subject by remember { mutableStateOf("") }
    var description by remember { mutableStateOf("") }
    val valid = name.isNotBlank() && EMAIL.matches(email.trim()) && phone.count(Char::isDigit) >= 8 &&
        subject.isNotBlank() && description.trim().length >= 5
    FormColumn(
        state.site?.offlineMessage
            ?.ifBlank { "Tim kami sedang offline. Tinggalkan pesan dan kami akan menghubungi Anda." }
            .orEmpty(),
    ) {
        Field(name, { name = it.take(120) }, "Nama Anda", accent)
        Field(email, { email = it }, "Email", accent, KeyboardType.Email)
        Field(phone, { phone = it.take(30) }, "No. Telepon / WhatsApp", accent, KeyboardType.Phone)
        Field(subject, { subject = it.take(200) }, "Subjek", accent)
        Field(description, { description = it }, "Ceritakan kebutuhan Anda", accent, lines = 4)
        Button(
            onClick = { onSubmit(TicketInput(name.trim(), email.trim(), phone.trim(), subject.trim(), description.trim())) },
            enabled = valid,
            modifier = Modifier.fillMaxWidth(),
            colors = accentButton(accent),
        ) { Text("Kirim Tiket") }
    }
}

@Composable
private fun FormColumn(title: String, content: @Composable ColumnScope.() -> Unit) = Column(
    Modifier.fillMaxSize().padding(20.dp),
    verticalArrangement = Arrangement.spacedBy(12.dp),
) {
    Text(title, color = TextPrimary, style = MaterialTheme.typography.titleSmall)
    content()
}

@Composable
private fun Field(
    value: String,
    onChange: (String) -> Unit,
    label: String,
    accent: Color,
    keyboard: KeyboardType = KeyboardType.Text,
    lines: Int = 1,
) = OutlinedTextField(
    value = value,
    onValueChange = onChange,
    modifier = Modifier.fillMaxWidth(),
    label = { Text(label) },
    keyboardOptions = KeyboardOptions(keyboardType = keyboard),
    minLines = lines,
    maxLines = lines,
    shape = RoundedCornerShape(14.dp),
    colors = fieldColors(accent),
)

@Composable
private fun fieldColors(accent: Color) = OutlinedTextFieldDefaults.colors(
    focusedTextColor = TextPrimary,
    unfocusedTextColor = TextPrimary,
    disabledTextColor = TextFaint,
    focusedContainerColor = FieldBg,
    unfocusedContainerColor = FieldBg,
    disabledContainerColor = FieldBg,
    focusedBorderColor = accent,
    unfocusedBorderColor = Border,
    disabledBorderColor = Border,
    focusedLabelColor = accent,
    unfocusedLabelColor = TextMuted,
    disabledLabelColor = TextFaint,
    focusedPlaceholderColor = TextFaint,
    unfocusedPlaceholderColor = TextFaint,
    disabledPlaceholderColor = TextFaint,
    cursorColor = accent,
)

@Composable
private fun accentButton(accent: Color) = ButtonDefaults.buttonColors(
    containerColor = accent,
    contentColor = Color.Black,
    disabledContainerColor = BubbleOther,
    disabledContentColor = TextMuted,
)

@Composable
private fun ColumnScope.StatusPill(text: String, accent: Color, spinner: Boolean) {
    Row(
        Modifier.align(Alignment.CenterHorizontally)
            .padding(top = 6.dp)
            .background(BubbleOther, RoundedCornerShape(50))
            .padding(horizontal = 14.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        if (spinner) CircularProgressIndicator(Modifier.size(14.dp), color = accent, strokeWidth = 2.dp)
        Text(text, color = TextPrimary, style = MaterialTheme.typography.bodySmall)
    }
}

@Composable
private fun ErrorBanner(message: String, modifier: Modifier = Modifier) = Text(
    message,
    color = Color.White,
    style = MaterialTheme.typography.bodySmall,
    modifier = modifier
        .fillMaxWidth()
        .padding(12.dp)
        .background(Color(0xFF7F1D1D), RoundedCornerShape(12.dp))
        .padding(horizontal = 14.dp, vertical = 10.dp),
)

@Composable
private fun Notice(text: String) = Text(
    text,
    color = TextMuted,
    style = MaterialTheme.typography.bodySmall,
    modifier = Modifier.fillMaxWidth().padding(8.dp),
)

@Composable
private fun CenterMessage(content: @Composable ColumnScope.() -> Unit) = Column(
    Modifier.fillMaxSize().padding(24.dp),
    verticalArrangement = Arrangement.spacedBy(12.dp, Alignment.CenterVertically),
    horizontalAlignment = Alignment.CenterHorizontally,
    content = content,
)

@Composable
private fun RatingDialog(accent: Color, onDismiss: () -> Unit, onSubmit: (Int, String?) -> Unit) {
    var score by remember { mutableIntStateOf(5) }
    var comment by remember { mutableStateOf("") }
    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = BarBg,
        title = { Text("Nilai layanan kami", color = TextPrimary) },
        text = {
            Column {
                Row {
                    (1..5).forEach { value ->
                        TextButton(onClick = { score = value }) {
                            Text(if (value <= score) "★" else "☆", color = accent)
                        }
                    }
                }
                Field(comment, { comment = it.take(1000) }, "Komentar (opsional)", accent, lines = 3)
            }
        },
        confirmButton = {
            Button(
                onClick = { onSubmit(score, comment.trim().ifBlank { null }) },
                colors = accentButton(accent),
            ) { Text("Kirim") }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Nanti", color = TextMuted) } },
    )
}

private val EMAIL = Regex("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$")

private fun parseColor(hex: String?): Color =
    runCatching { Color(android.graphics.Color.parseColor(hex ?: "#D4AF37")) }
        .getOrDefault(Color(0xFFD4AF37))
