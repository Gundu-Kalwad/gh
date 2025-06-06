package com.srk.aichat.ui.screens

import android.content.Intent
import android.net.Uri
import android.util.Log
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.ExitToApp
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.Send
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Divider
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.srk.aichat.auth.AuthViewModel
import com.srk.aichat.data.UserProfile
import com.srk.aichat.ui.components.ChatMessageItem
import com.srk.aichat.ui.components.LoadingIndicator
import com.srk.aichat.ui.components.SuggestionItem
import com.srk.aichat.viewmodel.ChatViewModel
import kotlinx.coroutines.launch

private const val TAG = "ChatScreen"

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChatScreen(
    onSignOut: (() -> Unit)? = null,
    authViewModel: AuthViewModel = viewModel(),
    notificationPermissionGranted: Boolean = true,
    onRequestNotificationPermission: () -> Unit = {}
) {
    val context = LocalContext.current
    val snackbarHostState = remember { SnackbarHostState() }
    val coroutineScope = rememberCoroutineScope()
    
    // Get current user from Auth ViewModel
    val currentUser by authViewModel.currentUser.collectAsState()
    val userProfile = currentUser?.let { UserProfile.fromFirebaseUser(it) }
    
    // Create ViewModel with error handling using a callback
    val viewModelErrorState = remember { mutableStateOf(false) }
    var showDeleteConfirmation by remember { mutableStateOf(false) }
    var showSignOutConfirmation by remember { mutableStateOf(false) }
    var showMenu by remember { mutableStateOf(false) }
    var showPermissionDialog by remember { mutableStateOf(!notificationPermissionGranted) }
    
    // Get the ViewModel directly - can't use try/catch around composable functions
    val viewModel: ChatViewModel = viewModel(
        factory = ChatViewModel.provideFactory(context.applicationContext as android.app.Application)
    )
    
    // Get message limit info
    val remainingMessages by viewModel.remainingMessages.collectAsState()
    val limitReached by viewModel.limitReached.collectAsState()
    
    // Use LaunchedEffect to catch any initialization errors
    LaunchedEffect(key1 = Unit) {
        try {
            // Just accessing a property from ViewModel to check if it's initialized correctly
            val initialMessages = viewModel.messages.value
            Log.d(TAG, "ViewModel initialized successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Error initializing or accessing ViewModel", e)
            viewModelErrorState.value = true
            snackbarHostState.showSnackbar("Error initializing chat. Please restart the app.")
        }
    }
    
    // Show error state if needed
    if (viewModelErrorState.value) {
        ErrorScreen()
        return
    }
    
    val messages by viewModel.messages.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    val suggestions by viewModel.suggestions.collectAsState()
    var userInput by remember { mutableStateOf("") }
    
    val listState = rememberLazyListState()
    
    // Scroll to bottom when new message arrives
    LaunchedEffect(messages.size) {
        if (messages.isNotEmpty()) {
            try {
                listState.animateScrollToItem(messages.size - 1)
            } catch (e: Exception) {
                Log.e(TAG, "Error scrolling", e)
            }
        }
    }
    
    // Permission Dialog - Show when notification permission is not granted
    if (showPermissionDialog) {
        AlertDialog(
            onDismissRequest = { /* Do nothing, user must respond */ },
            title = { Text("Enable Notifications") },
            text = { 
                Text("This app requires notifications to be enabled in order to use the chat. " +
                     "Please grant notification permission to continue.")
            },
            confirmButton = {
                Button(onClick = {
                    onRequestNotificationPermission()
                    showPermissionDialog = false
                }) {
                    Text("Grant Permission")
                }
            },
            dismissButton = {
                TextButton(onClick = {
                    // Handle user rejection
                    showPermissionDialog = false
                    // Navigate back or handle rejection
                    onSignOut?.invoke()
                }) {
                    Text("Exit Chat")
                }
            }
        )
    }
    
    // Delete confirmation dialog
    if (showDeleteConfirmation) {
        AlertDialog(
            onDismissRequest = { showDeleteConfirmation = false },
            title = { Text("Clear Chat History?") },
            text = { Text("This will permanently delete all chat messages. This action cannot be undone.") },
            confirmButton = {
                Button(
                    onClick = {
                        try {
                            viewModel.clearAllMessages()
                            showDeleteConfirmation = false
                            coroutineScope.launch {
                                snackbarHostState.showSnackbar("Chat history cleared")
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "Error clearing messages", e)
                            coroutineScope.launch {
                                snackbarHostState.showSnackbar("Failed to clear messages")
                            }
                        }
                    }
                ) {
                    Text("Clear")
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteConfirmation = false }) {
                    Text("Cancel")
                }
            }
        )
    }
    
    // Sign out confirmation dialog
    if (showSignOutConfirmation) {
        AlertDialog(
            onDismissRequest = { showSignOutConfirmation = false },
            title = { Text("Sign Out?") },
            text = { Text("Are you sure you want to sign out?") },
            confirmButton = {
                Button(
                    onClick = {
                        showSignOutConfirmation = false
                        onSignOut?.invoke()
                    }
                ) {
                    Text("Sign Out")
                }
            },
            dismissButton = {
                TextButton(onClick = { showSignOutConfirmation = false }) {
                    Text("Cancel")
                }
            }
        )
    }
    
    // Function to open email app
    fun openEmailApp() {
        val intent = Intent(Intent.ACTION_SENDTO).apply {
            data = Uri.parse("mailto:srk.apps88@gmail.com")
            putExtra(Intent.EXTRA_SUBJECT, "Feedback for AI:Ask Anything App")
        }
        
        try {
            context.startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Error opening email app", e)
            coroutineScope.launch {
                snackbarHostState.showSnackbar("No email app found")
            }
        }
    }
    
    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            TopAppBar(
                title = { 
                    Column {
                        Text("AI:Ask Anything")
                        userProfile?.let {
                            Text(
                                text = "Signed in as: ${it.name}",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.8f)
                            )
                        }
                        
                        // Removing message count from here - will show in menu instead
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer,
                    titleContentColor = MaterialTheme.colorScheme.onPrimaryContainer
                ),
                actions = {
                    // Menu button with dropdown
                    Box {
                        IconButton(onClick = { showMenu = true }) {
                            Icon(
                                imageVector = Icons.Default.MoreVert,
                                contentDescription = "Menu"
                            )
                        }
                        
                        DropdownMenu(
                            expanded = showMenu,
                            onDismissRequest = { showMenu = false }
                        ) {
                            // Message Limit Info - Non-clickable item
                            DropdownMenuItem(
                                text = { 
                                    Text(
                                        text = "Messages remaining today: $remainingMessages/${com.srk.aichat.data.MessageUsage.DAILY_MESSAGE_LIMIT}",
                                        color = if (limitReached)
                                            MaterialTheme.colorScheme.error
                                        else
                                            MaterialTheme.colorScheme.onSurface
                                    )
                                },
                                onClick = { /* Do nothing - info only */ },
                                enabled = false,
                                leadingIcon = {
                                    Icon(
                                        imageVector = Icons.Default.Info,
                                        contentDescription = "Message Limit Info",
                                        tint = if (limitReached)
                                            MaterialTheme.colorScheme.error
                                        else
                                            MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                            )
                            
                            Divider(modifier = Modifier.padding(vertical = 4.dp))
                            
                            // Contact Us Option
                            DropdownMenuItem(
                                text = { Text("Contact Us") },
                                leadingIcon = { 
                                    Icon(
                                        imageVector = Icons.Default.Email,
                                        contentDescription = "Contact Us"
                                    )
                                },
                                onClick = { 
                                    showMenu = false
                                    openEmailApp()
                                }
                            )
                            
                            // Clear Chat Option
                            DropdownMenuItem(
                                text = { Text("Clear Chat") },
                                leadingIcon = { 
                                    Icon(
                                        imageVector = Icons.Default.Delete,
                                        contentDescription = "Clear Chat"
                                    )
                                },
                                onClick = { 
                                    showMenu = false
                                    showDeleteConfirmation = true
                                }
                            )
                            
                            // Logout Option (only if onSignOut is provided)
                            if (onSignOut != null) {
                                DropdownMenuItem(
                                    text = { Text("Sign Out") },
                                    leadingIcon = { 
                                        Icon(
                                            imageVector = Icons.Default.ExitToApp,
                                            contentDescription = "Sign Out"
                                        )
                                    },
                                    onClick = { 
                                        showMenu = false
                                        showSignOutConfirmation = true
                                    }
                                )
                            }
                        }
                    }
                }
            )
        },
        modifier = Modifier.fillMaxSize()
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            if (!notificationPermissionGranted) {
                // Show permission overlay when permission is not granted
                NotificationPermissionRequired(
                    onRequestPermission = {
                        onRequestNotificationPermission()
                        showPermissionDialog = true
                    }
                )
            } else {
                // Two layers using Box composable
                
                // Background layer with watermark (rendered first)
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "AI:Ask Anything",
                        style = MaterialTheme.typography.displayMedium,
                        color = MaterialTheme.colorScheme.primary.copy(alpha = 0.07f),
                        fontWeight = FontWeight.Bold,
                        textAlign = TextAlign.Center
                    )
                }
                
                // Foreground layer with content (rendered on top)
                Box(
                    modifier = Modifier.fillMaxSize()
                ) {
                    Column(
                        modifier = Modifier.fillMaxSize()
                    ) {
                        // Chat messages
                        LazyColumn(
                            state = listState,
                            modifier = Modifier.weight(1f),
                            contentPadding = PaddingValues(16.dp)
                        ) {
                            items(messages) { message ->
                                ChatMessageItem(message = message)
                            }
                            
                            if (isLoading) {
                                item {
                                    LoadingIndicator()
                                }
                            }
                        }
                        
                        // Suggestions
                        if (suggestions.isNotEmpty()) {
                            LazyColumn(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(200.dp)
                            ) {
                                items(suggestions) { suggestion ->
                                    SuggestionItem(
                                        suggestion = suggestion,
                                        onClick = {
                                            userInput = suggestion
                                            try {
                                                viewModel.sendMessage(suggestion)
                                            } catch (e: Exception) {
                                                Log.e(TAG, "Error sending suggestion", e)
                                            }
                                        },
                                        modifier = Modifier.clickable {
                                            userInput = suggestion
                                            try {
                                                viewModel.sendMessage(suggestion)
                                            } catch (e: Exception) {
                                                Log.e(TAG, "Error sending suggestion", e)
                                            }
                                        }
                                    )
                                }
                            }
                        }
                        
                        // Input area
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .imePadding()
                                .padding(16.dp)
                        ) {
                            OutlinedTextField(
                                value = userInput,
                                onValueChange = { 
                                    userInput = it
                                    try {
                                        viewModel.getSuggestions(it)
                                    } catch (e: Exception) {
                                        Log.e(TAG, "Error getting suggestions", e)
                                    }
                                },
                                modifier = Modifier.fillMaxWidth(),
                                placeholder = { Text("Ask Anything...") },
                                shape = RoundedCornerShape(24.dp),
                                trailingIcon = {
                                    IconButton(
                                        onClick = {
                                            if (userInput.isNotBlank()) {
                                                try {
                                                    viewModel.sendMessage(userInput)
                                                    userInput = ""
                                                } catch (e: Exception) {
                                                    Log.e(TAG, "Error sending message", e)
                                                    coroutineScope.launch {
                                                        snackbarHostState.showSnackbar("Failed to send message")
                                                    }
                                                }
                                            }
                                        }
                                    ) {
                                        Icon(
                                            imageVector = Icons.Default.Send,
                                            contentDescription = "Send"
                                        )
                                    }
                                }
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun ErrorScreen() {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = "Something went wrong. Please restart the app.",
            color = MaterialTheme.colorScheme.error,
            style = MaterialTheme.typography.titleMedium
        )
    }
}

@Preview(showBackground = true, showSystemUi = true, name = "Chat Screen Preview")
@Composable
fun ChatScreenPreview() {
    // Use a simplified preview that doesn't depend on the actual ViewModel
    PreviewChatScreen()
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun PreviewChatScreen() {
    val snackbarHostState = remember { SnackbarHostState() }
    var userInput by remember { mutableStateOf("") }
    
    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            TopAppBar(
                title = { Text("AI:Ask Anything") },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer,
                    titleContentColor = MaterialTheme.colorScheme.onPrimaryContainer
                ),
                actions = {
                    IconButton(onClick = { }) {
                        Icon(
                            imageVector = Icons.Default.Delete,
                            contentDescription = "Clear Chat History"
                        )
                    }
                }
            )
        },
        modifier = Modifier.fillMaxSize()
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            Column(
                modifier = Modifier.fillMaxSize()
            ) {
                // Sample chat messages
                LazyColumn(
                    modifier = Modifier.weight(1f),
                    contentPadding = PaddingValues(16.dp)
                ) {
                    // Preview sample item
                    item {
                        Text("This is a preview of the chat screen", 
                             style = MaterialTheme.typography.bodyLarge,
                             modifier = Modifier.padding(8.dp))
                    }
                }
                
                // Input area
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .imePadding()
                        .padding(16.dp)
                ) {
                    OutlinedTextField(
                        value = userInput,
                        onValueChange = { userInput = it },
                        modifier = Modifier.fillMaxWidth(),
                        placeholder = { Text("Ask Anything...") },
                        shape = RoundedCornerShape(24.dp),
                        trailingIcon = {
                            IconButton(onClick = { }) {
                                Icon(
                                    imageVector = Icons.Default.Send,
                                    contentDescription = "Send"
                                )
                            }
                        }
                    )
                }
            }
        }
    }
}

@Preview(showBackground = true, name = "Error Screen Preview")
@Composable
fun ErrorScreenPreview() {
    MaterialTheme {
        ErrorScreen()
    }
}

@Composable
fun NotificationPermissionRequired(
    onRequestPermission: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            imageVector = Icons.Default.Notifications,
            contentDescription = "Notifications",
            modifier = Modifier.size(80.dp),
            tint = MaterialTheme.colorScheme.primary
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        Text(
            text = "Notifications Required",
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold
        )
        
        Spacer(modifier = Modifier.height(8.dp))
        
        Text(
            text = "This app requires notification permission to function properly. " +
                  "Please enable notifications to continue using the chat.",
            textAlign = TextAlign.Center,
            style = MaterialTheme.typography.bodyMedium
        )
        
        Spacer(modifier = Modifier.height(24.dp))
        
        Button(
            onClick = onRequestPermission,
            modifier = Modifier.fillMaxWidth(0.7f)
        ) {
            Text("Enable Notifications")
        }
    }
} 