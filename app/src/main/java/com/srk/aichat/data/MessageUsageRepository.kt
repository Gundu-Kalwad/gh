package com.srk.aichat.data

import android.util.Log
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.SetOptions
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withTimeoutOrNull

class MessageUsageRepository {
    private val TAG = "MessageUsageRepository"
    private val firestore = FirebaseFirestore.getInstance()
    private val auth = FirebaseAuth.getInstance()
    
    // Cache the current message usage to avoid excessive Firestore reads
    private val _currentMessageUsage = MutableStateFlow<MessageUsage?>(null)
    val currentMessageUsage: Flow<MessageUsage?> = _currentMessageUsage
    
    private val usageCollection = firestore.collection("message_usage")
    
    suspend fun getCurrentUsage(): MessageUsage? {
        // If we already have usage data cached, return it immediately
        _currentMessageUsage.value?.let { 
            if (it.date == MessageUsage.getTodayDateString()) {
                return it
            }
        }
        
        val userId = auth.currentUser?.uid ?: return createDefaultUsage()
        val today = MessageUsage.getTodayDateString()
        
        try {
            // Try to get today's usage record with timeout
            val document = withTimeoutOrNull(5000) {
                usageCollection
                    .whereEqualTo("userId", userId)
                    .whereEqualTo("date", today)
                    .get()
                    .await()
            } ?: return handleFirestoreTimeout(userId, today)
            
            val usage = if (document.isEmpty) {
                // No usage record for today, create a new one
                MessageUsage(userId = userId, date = today)
            } else {
                // Convert Firestore document to MessageUsage
                val usageDoc = document.documents[0].toObject(MessageUsage::class.java)
                usageDoc ?: MessageUsage(userId = userId, date = today)
            }
            
            _currentMessageUsage.value = usage
            return usage
        } catch (e: Exception) {
            Log.e(TAG, "Error getting message usage", e)
            return handleFirestoreError(userId, today)
        }
    }
    
    private fun createDefaultUsage(): MessageUsage {
        // Create a default usage with a generous limit when user is not authenticated
        val defaultUsage = MessageUsage(
            userId = "anonymous",
            date = MessageUsage.getTodayDateString(),
            messageCount = 0
        )
        _currentMessageUsage.value = defaultUsage
        return defaultUsage
    }
    
    private fun handleFirestoreTimeout(userId: String, today: String): MessageUsage {
        Log.w(TAG, "Firestore timeout, using cached or default usage")
        
        // Use cached value or create new one
        val cachedOrDefault = _currentMessageUsage.value?.let {
            if (it.date == today && it.userId == userId) it else MessageUsage(userId = userId, date = today)
        } ?: MessageUsage(userId = userId, date = today)
        
        _currentMessageUsage.value = cachedOrDefault
        return cachedOrDefault
    }
    
    private fun handleFirestoreError(userId: String, today: String): MessageUsage {
        Log.w(TAG, "Firestore error, using cached or default usage")
        
        // Use cached value or create new one
        val cachedOrDefault = _currentMessageUsage.value?.let {
            if (it.date == today && it.userId == userId) it else MessageUsage(userId = userId, date = today)
        } ?: MessageUsage(userId = userId, date = today)
        
        _currentMessageUsage.value = cachedOrDefault
        return cachedOrDefault
    }
    
    suspend fun incrementMessageCount(): Result<MessageUsage> {
        val userId = auth.currentUser?.uid ?: return Result.failure(Exception("User not logged in"))
        val today = MessageUsage.getTodayDateString()
        
        try {
            // Get current usage - with improved error handling
            var usage = getCurrentUsage() ?: MessageUsage(userId = userId, date = today)
            
            // Check if user has reached limit
            if (MessageUsage.hasReachedLimit(usage.messageCount)) {
                return Result.failure(Exception("Daily message limit reached"))
            }
            
            // Increment message count
            usage = usage.copy(
                messageCount = usage.messageCount + 1,
                lastUpdated = System.currentTimeMillis()
            )
            
            // Update local cache immediately (optimistic update)
            _currentMessageUsage.value = usage
            
            // Try to save to Firestore with timeout
            try {
                withTimeoutOrNull(5000) {
                    usageCollection.document("$userId-$today")
                        .set(usage, SetOptions.merge())
                        .await()
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error saving to Firestore, but continuing with local cache", e)
                // We continue with the local cache even if Firestore fails
            }
            
            return Result.success(usage)
        } catch (e: Exception) {
            Log.e(TAG, "Error incrementing message count", e)
            return Result.failure(e)
        }
    }
    
    suspend fun getRemainingMessages(): Int {
        val usage = getCurrentUsage()
        return if (usage != null) {
            MessageUsage.getRemainingMessages(usage.messageCount)
        } else {
            MessageUsage.DAILY_MESSAGE_LIMIT
        }
    }
    
    suspend fun hasReachedDailyLimit(): Boolean {
        val usage = getCurrentUsage()
        return usage?.let { MessageUsage.hasReachedLimit(it.messageCount) } ?: false
    }
} 