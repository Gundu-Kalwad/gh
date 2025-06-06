package com.srk.aichat.viewmodel

import android.app.Application
import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.util.Log
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.srk.aichat.AIChatApplication
import com.srk.aichat.data.MessageRepository
import com.srk.aichat.data.MessageUsage
import com.srk.aichat.data.MessageUsageRepository
import com.srk.aichat.repository.WikipediaRepository
import kotlinx.coroutines.CoroutineExceptionHandler
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeout
import kotlinx.coroutines.withTimeoutOrNull
import java.util.concurrent.atomic.AtomicBoolean
import java.util.UUID
import java.util.concurrent.CancellationException
import java.util.concurrent.TimeoutException

class ChatViewModel(application: Application) : AndroidViewModel(application) {
    private val TAG = "ChatViewModel"
    private val wikiRepository = WikipediaRepository()
    private val messageRepository: MessageRepository
    private val messageUsageRepository = MessageUsageRepository()
    
    private val _messages = MutableStateFlow<List<ChatMessage>>(emptyList())
    val messages: StateFlow<List<ChatMessage>> = _messages.asStateFlow()
    
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()
    
    private val _suggestions = MutableStateFlow<List<String>>(emptyList())
    val suggestions: StateFlow<List<String>> = _suggestions.asStateFlow()
    
    private val _remainingMessages = MutableStateFlow(MessageUsage.DAILY_MESSAGE_LIMIT)
    val remainingMessages: StateFlow<Int> = _remainingMessages.asStateFlow()
    
    private val _limitReached = MutableStateFlow(false)
    val limitReached: StateFlow<Boolean> = _limitReached.asStateFlow()
    
    // Flag to prevent duplicate search messages
    private val _searchInProgress = MutableStateFlow(false)
    val searchInProgress: StateFlow<Boolean> = _searchInProgress.asStateFlow()
    
    // Flag to track if initial message has been added
    private var initialMessageAdded = false
    
    // Exception handler for coroutines
    private val exceptionHandler = CoroutineExceptionHandler { _, exception ->
        Log.e(TAG, "Coroutine exception", exception)
        _isLoading.value = false
        _searchInProgress.value = false
    }
    
    init {
        Log.d(TAG, "Initializing ChatViewModel")
        // Get the repository from the application
        messageRepository = (application as AIChatApplication).messageRepository
        
        // Check message usage limit
        viewModelScope.launch(exceptionHandler) {
            updateMessageUsage()
        }
        
        // Load saved messages
        viewModelScope.launch(exceptionHandler) {
            try {
                messageRepository.allMessages
                    .catch { e -> 
                        Log.e(TAG, "Error collecting messages", e)
                        emit(emptyList())
                    }
                    .collectLatest { savedMessages ->
                        try {
                            if (savedMessages.isEmpty() && !initialMessageAdded) {
                                // If no saved messages and welcome message not added yet, add the welcome message
                                addWelcomeMessage()
                                initialMessageAdded = true
                            } else {
                                // Update the messages state flow with saved messages
                                _messages.value = savedMessages
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "Error processing saved messages", e)
                            if (!initialMessageAdded) {
                                addWelcomeMessage()
                                initialMessageAdded = true
                            }
                        }
                    }
            } catch (e: Exception) {
                Log.e(TAG, "Fatal error in message collection", e)
                // At least show a welcome message if everything fails
                if (_messages.value.isEmpty()) {
                    _messages.value = listOf(
                        ChatMessage(
                            sender = MessageSender.BOT,
                            content = "Hello! I'm your AI Assistant.\nDeveloped by: SRK Apps"
                        )
                    )
                }
            }
        }
    }
    
    private suspend fun updateMessageUsage() {
        try {
            val remaining = messageUsageRepository.getRemainingMessages()
            _remainingMessages.value = remaining
            _limitReached.value = remaining <= 0
        } catch (e: Exception) {
            Log.e(TAG, "Error updating message usage", e)
        }
    }
    
    private suspend fun addWelcomeMessage() {
        try {
            val welcomeMessage = ChatMessage(
                sender = MessageSender.BOT,
                content = "Hello! I'm your AI Assistant.\nDeveloped by: SRK Apps"
            )
            messageRepository.insertMessage(welcomeMessage)
            // Don't replace existing messages
            _messages.value = if (_messages.value.isEmpty()) {
                listOf(welcomeMessage)
            } else {
                _messages.value + welcomeMessage
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error adding welcome message", e)
        }
    }
    
    private fun addSystemMessage(content: String) {
        val systemMessage = ChatMessage(
            sender = MessageSender.BOT,
            content = content,
            timestamp = System.currentTimeMillis()
        )
        _messages.value = _messages.value + systemMessage
        
        // Also save to repository if possible
        viewModelScope.launch {
            try {
                messageRepository.insertMessage(systemMessage)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to save system message", e)
            }
        }
    }
    
    fun sendMessage(query: String) {
        if (query.isBlank()) return
        
        // Check if daily limit is reached
        if (_limitReached.value) {
            addSystemMessage("Sorry, you've reached your daily message limit. Try again tomorrow!")
            return
        }
        
        // Create and add the user message immediately for better UX
        val userMessage = ChatMessage(
            sender = MessageSender.USER,
            content = query,
            timestamp = System.currentTimeMillis()
        )
        
        _messages.value = _messages.value + userMessage
        
        // Add user message to repository
        viewModelScope.launch {
            try {
                messageRepository.insertMessage(userMessage)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to save user message", e)
            }
        }
        
        // Show loading indicator
        _isLoading.value = true
        _searchInProgress.value = true
        
        viewModelScope.launch {
            var responseContent = ""
            
            try {
                // First, try to get response from Wikipedia with a timeout
                val wikipediaRepo = WikipediaRepository()
                responseContent = withTimeoutOrNull(15000) {
                    wikipediaRepo.getInformationAbout(query)
                } ?: "I'm having trouble connecting to my knowledge sources right now. Please check your internet connection and try again."
                
                // Increment message count only after successful response
                val usageLimitExceeded = try {
                    messageUsageRepository.incrementMessageCount()
                    updateMessageUsage() // Refresh UI with updated count
                    false
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to update message usage", e)
                    false // Continue anyway even if usage tracking fails
                }
                
                // If limit was exceeded during this operation
                if (_limitReached.value) {
                    addSystemMessage("You've reached your daily message limit. This will be your last response for today.")
                }
                
            } catch (e: CancellationException) {
                // Don't catch cancellation exceptions
                throw e
            } catch (e: Exception) {
                Log.e(TAG, "Exception getting response", e)
                
                // Generate helpful fallback response instead of showing error
                responseContent = when {
                    !isNetworkAvailable() -> 
                        "I'm having trouble connecting to my knowledge sources. Please check your internet connection and try again."
                    e is TimeoutException || e.cause is TimeoutException -> 
                        "It's taking longer than expected to find information. This might be due to network issues or high demand."
                    query.length > 200 -> 
                        "That's a very detailed question. Could you try asking something more specific or break it into smaller questions?"
                    else -> 
                        "I encountered an issue while searching for information about \"$query\". Could you try rephrasing your question?"
                }
            } finally {
                // Create response message
                if (responseContent.isNotBlank()) {
                    val responseMessage = ChatMessage(
                        sender = MessageSender.BOT,
                        content = responseContent,
                        timestamp = System.currentTimeMillis()
                    )
                    
                    // Add to UI
                    _messages.value = _messages.value + responseMessage
                    
                    // Save to repository
                    try {
                        messageRepository.insertMessage(responseMessage)
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to save response message", e)
                    }
                }
                
                // Hide loading states
                _isLoading.value = false
                _searchInProgress.value = false
            }
        }
    }
    
    private fun isNetworkAvailable(): Boolean {
        val connectivityManager = getApplication<Application>().getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val network = connectivityManager.activeNetwork ?: return false
        val capabilities = connectivityManager.getNetworkCapabilities(network) ?: return false
        return capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
    }
    
    fun getSuggestions(query: String) {
        if (query.length < 3 || _searchInProgress.value) {
            _suggestions.value = emptyList()
            return
        }
        
        viewModelScope.launch(exceptionHandler) {
            try {
                val suggestions = withTimeout(5000) {
                    wikiRepository.getSuggestions(query)
                }
                _suggestions.value = suggestions
            } catch (e: Exception) {
                Log.e(TAG, "Error getting suggestions", e)
                _suggestions.value = emptyList()
            }
        }
    }
    
    fun clearAllMessages() {
        viewModelScope.launch(exceptionHandler) {
            try {
                // Only clear messages when explicitly requested
                _messages.value = emptyList()
                
                // Then clear the repository
                messageRepository.clearAllMessages()
                
                // Add the welcome message back
                addWelcomeMessage()
            } catch (e: Exception) {
                Log.e(TAG, "Error clearing messages", e)
                // At least try to show the welcome message
                addWelcomeMessage()
            }
        }
    }
    
    companion object {
        fun provideFactory(application: Application): ViewModelProvider.Factory {
            return object : ViewModelProvider.Factory {
                @Suppress("UNCHECKED_CAST")
                override fun <T : androidx.lifecycle.ViewModel> create(modelClass: Class<T>): T {
                    if (modelClass.isAssignableFrom(ChatViewModel::class.java)) {
                        return try {
                            ChatViewModel(application) as T
                        } catch (e: Exception) {
                            Log.e("ChatViewModel", "Error creating ViewModel", e)
                            throw e
                        }
                    }
                    throw IllegalArgumentException("Unknown ViewModel class")
                }
            }
        }
    }
}

data class ChatMessage(
    val sender: MessageSender,
    val content: String,
    val timestamp: Long = System.currentTimeMillis()
)

enum class MessageSender {
    USER, BOT
} 