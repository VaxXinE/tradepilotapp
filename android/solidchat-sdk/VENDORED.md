# SolidChat Android SDK (vendored)

Source: `bizdevsg/live-chat`, path `sdks/android/solidchat-sdk`, tag `v0.16.4`
(commit `3353e49`, same as branch `dev` at the time of vendoring).

Vendored because the published 0.16.4 screen crashes the host app: every SDK call in
`SolidChatScreen` runs in a bare `scope.launch`, and `SolidChatClient` re-throws failures
(`getOrThrow()`), so a rate limit ("Permintaan agent terlalu sering") or a network error kills
the process. Drop this module and go back to
`implementation("com.solidchat:solidchat-android-sdk:<version>")` once upstream fixes it.

## Local changes vs upstream

- `ui/SolidChatScreen.kt`: rewritten. All SDK calls are wrapped so failures show an error
  banner instead of crashing; "Hubungi Agent" is shown as soon as a conversation exists (not
  only after an AI reply); agent status pill; explicit dark colours for inputs, checkbox and
  disabled buttons so text stays readable regardless of the host `MaterialTheme`.
- `ui/SolidChatScreen.kt`: image messages render the attachment (signed URL via
  `getAttachmentUrl`, OkHttp + BitmapFactory, in-memory cache, tap for full-screen preview)
  instead of the placeholder text "Gambar".
- `SolidChatClient.kt`: added `clearError()`.
- Removed: unit tests, Maven publishing config (built as a normal project module).
