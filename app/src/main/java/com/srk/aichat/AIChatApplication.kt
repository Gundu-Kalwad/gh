package com.srk.aichat

import android.app.Application
import android.util.Log
import com.google.firebase.FirebaseApp
import com.google.firebase.messaging.FirebaseMessaging
import com.srk.aichat.data.ChatDatabase
import com.srk.aichat.data.MessageRepository

class AIChatApplication : Application() {
    companion object {
        private const val TAG = "AIChatApplication"
    }
    
    // Lazy initialization with proper error handling and backup restoration
    val database by lazy { 
        try {
            Log.d(TAG, "Initializing database")
            ChatDatabase.getDatabase(this)
        } catch (e: Exception) {
            Log.e(TAG, "Error initializing database, attempting to restore from backup", e)
            
            // Try to restore from backup
            val restored = ChatDatabase.restoreFromBackup(this)
            if (restored) {
                try {
                    // Try to initialize the database again after restoration
                    ChatDatabase.getDatabase(this)
                } catch (e2: Exception) {
                    Log.e(TAG, "Failed to initialize database even after restoration", e2)
                    null
                }
            } else {
                Log.e(TAG, "No backup available or restoration failed", e)
                null
            }
        }
    }
    
    val messageRepository by lazy { 
        try {
            database?.messageDao()?.let { MessageRepository(it) } ?: createFallbackRepository()
        } catch (e: Exception) {
            Log.e(TAG, "Error initializing repository", e)
            createFallbackRepository()
        }
    }
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Application initialized")
        
        // Initialize Firebase
        try {
            FirebaseApp.initializeApp(this)
            Log.d(TAG, "Firebase initialized successfully")
            
            // Initialize Firebase Messaging
            FirebaseMessaging.getInstance().isAutoInitEnabled = true
            
            // Get token for debugging
            FirebaseMessaging.getInstance().token.addOnCompleteListener { task ->
                if (task.isSuccessful) {
                    val token = task.result
                    Log.d(TAG, "FCM Token: $token")
                } else {
                    Log.e(TAG, "Failed to get FCM token", task.exception)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error initializing Firebase", e)
        }
        
        // Initialize database connection early to ensure it works
        Thread {
            try {
                val db = database
                Log.d(TAG, "Database initialized successfully: ${db != null}")
            } catch (e: Exception) {
                Log.e(TAG, "Error in early database initialization", e)
            }
        }.start()
    }
    
    private fun createFallbackRepository(): MessageRepository {
        // Create a fallback in-memory repository that doesn't crash the app
        Log.w(TAG, "Using fallback repository")
        return MessageRepository.createInMemoryRepository()
    }
} 