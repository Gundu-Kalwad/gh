package com.srk.aichat.data

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.srk.aichat.viewmodel.ChatMessage
import com.srk.aichat.viewmodel.MessageSender

@Entity(tableName = "messages")
data class MessageEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val content: String,
    val sender: String,
    val timestamp: Long
) {
    companion object {
        fun fromChatMessage(chatMessage: ChatMessage): MessageEntity {
            return MessageEntity(
                content = chatMessage.content,
                sender = chatMessage.sender.name,
                timestamp = chatMessage.timestamp
            )
        }
        
        fun toChatMessage(entity: MessageEntity): ChatMessage {
            return ChatMessage(
                content = entity.content,
                sender = MessageSender.valueOf(entity.sender),
                timestamp = entity.timestamp
            )
        }
    }
} 