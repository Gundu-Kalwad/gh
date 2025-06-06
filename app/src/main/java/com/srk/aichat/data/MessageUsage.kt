package com.srk.aichat.data

import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

data class MessageUsage(
    val userId: String = "",
    val date: String = getTodayDateString(),
    val messageCount: Int = 0,
    val lastUpdated: Long = System.currentTimeMillis()
) {
    companion object {
        const val DAILY_MESSAGE_LIMIT = 20
        
        fun getTodayDateString(): String {
            val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
            return dateFormat.format(Date())
        }
        
        fun getRemainingMessages(messageCount: Int): Int {
            return maxOf(0, DAILY_MESSAGE_LIMIT - messageCount)
        }
        
        fun hasReachedLimit(messageCount: Int): Boolean {
            return messageCount >= DAILY_MESSAGE_LIMIT
        }
    }
} 