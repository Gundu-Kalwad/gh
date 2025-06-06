package com.srk.aichat.ui.components

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.ExperimentalFoundationApi
import com.srk.aichat.viewmodel.ChatMessage
import com.srk.aichat.viewmodel.MessageSender
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun ChatMessageItem(message: ChatMessage, modifier: Modifier = Modifier) {
    val isUser = message.sender == MessageSender.USER
    val alignment = if (isUser) Alignment.End else Alignment.Start
    val backgroundColor = if (isUser) 
        MaterialTheme.colorScheme.primary 
    else 
        MaterialTheme.colorScheme.surfaceVariant
    val textColor = if (isUser) 
        MaterialTheme.colorScheme.onPrimary 
    else 
        MaterialTheme.colorScheme.onSurfaceVariant
    
    val context = LocalContext.current
    
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(8.dp),
        horizontalAlignment = alignment
    ) {
        Card(
            shape = RoundedCornerShape(
                topStart = 12.dp,
                topEnd = 12.dp,
                bottomStart = if (isUser) 12.dp else 0.dp,
                bottomEnd = if (isUser) 0.dp else 12.dp
            ),
            colors = CardDefaults.cardColors(
                containerColor = backgroundColor
            ),
            modifier = Modifier.padding(horizontal = 8.dp)
        ) {
            Text(
                text = message.content,
                color = textColor,
                modifier = Modifier
                    .padding(12.dp)
                    .combinedClickable(
                        onClick = {},
                        onLongClick = {
                            copyToClipboard(context, message.content)
                        }
                    ),
                style = MaterialTheme.typography.bodyLarge
            )
        }
        
        Spacer(modifier = Modifier.height(2.dp))
        
        // Message timestamp
        val formatter = SimpleDateFormat("h:mm a", Locale.getDefault())
        val timeString = formatter.format(Date(message.timestamp))
        
        Text(
            text = timeString,
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f),
            modifier = Modifier.padding(horizontal = 8.dp)
        )
    }
}

private fun copyToClipboard(context: Context, text: String) {
    val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
    val clip = ClipData.newPlainText("Message", text)
    clipboard.setPrimaryClip(clip)
    Toast.makeText(context, "Copied to clipboard", Toast.LENGTH_SHORT).show()
}

@Composable
fun LoadingIndicator(modifier: Modifier = Modifier) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Card(
            shape = RoundedCornerShape(12.dp),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.surfaceVariant
            ),
            modifier = Modifier.padding(8.dp)
        ) {
            Row(
                modifier = Modifier.padding(12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                CircularProgressIndicator(
                    modifier = Modifier.width(16.dp).height(16.dp),
                    color = MaterialTheme.colorScheme.primary,
                    strokeWidth = 2.dp
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "Looking up information...",
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    style = MaterialTheme.typography.bodyMedium
                )
            }
        }
    }
}

@Composable
fun SuggestionItem(suggestion: String, onClick: () -> Unit, modifier: Modifier = Modifier) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp)
            .background(
                color = MaterialTheme.colorScheme.surfaceVariant,
                shape = RoundedCornerShape(8.dp)
            )
            .padding(12.dp)
    ) {
        Text(
            text = suggestion,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            style = MaterialTheme.typography.bodyMedium,
            modifier = Modifier.fillMaxWidth(),
            textAlign = TextAlign.Start
        )
    }
} 