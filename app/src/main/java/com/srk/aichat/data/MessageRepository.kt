package com.srk.aichat.data

import android.util.Log
import com.srk.aichat.viewmodel.ChatMessage
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.map

open class MessageRepository(private val messageDao: MessageDao) {
    private val TAG = "MessageRepository"
    
    open val allMessages: Flow<List<ChatMessage>> = messageDao.getAllMessages()
        .catch { e -> 
            Log.e(TAG, "Error fetching messages", e)
            emit(emptyList())
        }
        .map { entities ->
            try {
                entities.map { MessageEntity.toChatMessage(it) }
            } catch (e: Exception) {
                Log.e(TAG, "Error mapping entities", e)
                emptyList()
            }
        }
    
    open suspend fun insertMessage(message: ChatMessage) {
        try {
            messageDao.insertMessage(MessageEntity.fromChatMessage(message))
        } catch (e: Exception) {
            Log.e(TAG, "Error inserting message", e)
        }
    }
    
    open suspend fun insertMessages(messages: List<ChatMessage>) {
        try {
            val entities = messages.map { MessageEntity.fromChatMessage(it) }
            messageDao.insertMessages(entities)
        } catch (e: Exception) {
            Log.e(TAG, "Error inserting messages", e)
        }
    }
    
    open suspend fun clearAllMessages() {
        try {
            messageDao.deleteAllMessages()
        } catch (e: Exception) {
            Log.e(TAG, "Error clearing messages", e)
        }
    }
    
    companion object {
        fun createInMemoryRepository(): MessageRepository {
            return InMemoryMessageRepository()
        }
    }
}

/**
 * In-memory implementation of MessageRepository that doesn't use the database.
 * Used as a fallback when the database is not available to prevent crashes.
 */
class InMemoryMessageRepository : MessageRepository(NoOpMessageDao()) {
    private val TAG = "InMemoryRepository"
    private val messages = MutableStateFlow<List<MessageEntity>>(emptyList())
    
    override val allMessages: Flow<List<ChatMessage>> = messages.map { entities ->
        entities.map { MessageEntity.toChatMessage(it) }
    }
    
    override suspend fun insertMessage(message: ChatMessage) {
        Log.d(TAG, "Inserting message in memory: ${message.content}")
        val entity = MessageEntity.fromChatMessage(message)
        val currentList = messages.value.toMutableList()
        currentList.add(entity)
        messages.value = currentList
    }
    
    override suspend fun insertMessages(messages: List<ChatMessage>) {
        Log.d(TAG, "Inserting ${messages.size} messages in memory")
        val entities = messages.map { MessageEntity.fromChatMessage(it) }
        val currentList = this.messages.value.toMutableList()
        currentList.addAll(entities)
        this.messages.value = currentList
    }
    
    override suspend fun clearAllMessages() {
        Log.d(TAG, "Clearing all in-memory messages")
        messages.value = emptyList()
    }
}

/**
 * No-op implementation of MessageDao used for the in-memory repository.
 */
class NoOpMessageDao : MessageDao {
    private val messages = MutableStateFlow<List<MessageEntity>>(emptyList())
    
    override fun getAllMessages(): Flow<List<MessageEntity>> = messages
    
    override suspend fun insertMessage(message: MessageEntity) {
        // No-op
    }
    
    override suspend fun insertMessages(messages: List<MessageEntity>) {
        // No-op
    }
    
    override suspend fun deleteAllMessages() {
        // No-op
    }
} 