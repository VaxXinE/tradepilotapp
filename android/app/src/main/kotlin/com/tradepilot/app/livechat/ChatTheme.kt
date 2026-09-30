package com.tradepilot.app.livechat

import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Shapes
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp

// The SDK screen paints its own dark background but its inputs, checkbox and dialogs read
// MaterialTheme, so the default light scheme gives dark text on a dark surface. This mirrors
// the Flutter dark palette (lib/core/theme/app_colors.dart).
private val ChatColors = darkColorScheme(
    primary = Color(0xFFFAB505),
    onPrimary = Color(0xFF0D0D0D),
    background = Color(0xFF09090B),
    onBackground = Color(0xFFFAFAFA),
    surface = Color(0xFF18181B),
    onSurface = Color(0xFFFAFAFA),
    surfaceVariant = Color(0xFF27272A),
    onSurfaceVariant = Color(0xFFA6A6A6),
    surfaceContainerHigh = Color(0xFF1F1F23),
    outline = Color(0xFF4A4D55),
    outlineVariant = Color(0xFF34373E),
    error = Color(0xFFF87171),
)

private val ChatShapes = Shapes(
    extraSmall = RoundedCornerShape(12.dp),
    small = RoundedCornerShape(12.dp),
    medium = RoundedCornerShape(16.dp),
)

@Composable
fun ChatTheme(content: @Composable () -> Unit) {
    MaterialTheme(colorScheme = ChatColors, shapes = ChatShapes, content = content)
}
