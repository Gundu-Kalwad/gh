package com.srk.aichat.ui.components

import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.graphics.drawscope.translate
import kotlinx.coroutines.delay
import kotlin.math.cos
import kotlin.math.sin
import kotlin.random.Random

data class RainDrop(
    val x: Float,
    var y: Float,
    val speed: Float,
    val length: Float,
    val width: Float,
    val color: Color,
    val angle: Float
)

@Composable
fun RGBRainBackground(
    modifier: Modifier = Modifier,
    numDrops: Int = 100,
    content: @Composable () -> Unit
) {
    // Create a list of raindrops
    val drops = remember {
        List(numDrops) {
            createRandomRainDrop()
        }
    }
    
    // Color animation for background gradient
    val infiniteTransition = rememberInfiniteTransition(label = "colorTransition")
    val hue1 by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(10000, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ), label = "hue1"
    )
    
    val hue2 by infiniteTransition.animateFloat(
        initialValue = 0.3f,
        targetValue = 1.3f,
        animationSpec = infiniteRepeatable(
            animation = tween(8000, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ), label = "hue2"
    )
    
    val hue3 by infiniteTransition.animateFloat(
        initialValue = 0.6f,
        targetValue = 1.6f,
        animationSpec = infiniteRepeatable(
            animation = tween(12000, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ), label = "hue3"
    )
    
    // Animation for rain movement
    var animationTrigger by remember { mutableStateOf(0f) }
    val animatedTrigger by animateFloatAsState(
        targetValue = animationTrigger,
        animationSpec = tween(durationMillis = 16), 
        label = "rainMovement"
    )
    
    // Update raindrops position
    LaunchedEffect(animatedTrigger) {
        delay(16) // ~60 fps
        drops.forEach { drop ->
            drop.y += drop.speed
            if (drop.y > 2000) {
                drop.y = -drop.length
            }
        }
        animationTrigger = animationTrigger + 0.01f
    }
    
    // Get gradient colors from the hue values
    val colors = listOf(
        Color.hsv(hue1 * 360 % 360, 0.7f, 0.8f),
        Color.hsv(hue2 * 360 % 360, 0.7f, 0.7f),
        Color.hsv(hue3 * 360 % 360, 0.7f, 0.6f)
    )
    
    Box(
        modifier = modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    colors = colors.map { it.copy(alpha = 0.5f) }
                )
            )
    ) {
        // Draw the raindrops
        Canvas(modifier = Modifier.fillMaxSize()) {
            drops.forEach { drop ->
                translate(left = drop.x, top = drop.y) {
                    rotate(drop.angle) {
                        drawLine(
                            color = drop.color,
                            start = Offset(0f, 0f),
                            end = Offset(0f, drop.length),
                            strokeWidth = drop.width
                        )
                    }
                }
            }
        }
        
        // Draw the content on top of the animation
        content()
    }
}

private fun createRandomRainDrop(): RainDrop {
    val random = Random.Default
    // Generate a random "cool" color in blue-purple-pink range
    val hue = random.nextFloat() * 180f + 180f // 180-360 degrees in HSV (blue to pink spectrum)
    val saturation = 0.6f + random.nextFloat() * 0.4f // 0.6-1.0 saturation
    val brightness = 0.7f + random.nextFloat() * 0.3f // 0.7-1.0 brightness
    
    return RainDrop(
        x = random.nextFloat() * 2000,
        y = random.nextFloat() * 2000 - 1000, // Start some above screen
        speed = 5f + random.nextFloat() * 15f,
        length = 20f + random.nextFloat() * 80f,
        width = 1f + random.nextFloat() * 3f,
        color = Color.hsv(hue, saturation, brightness).copy(alpha = 0.7f),
        angle = 15f + random.nextFloat() * 10f // Slight angle for more natural look
    )
} 