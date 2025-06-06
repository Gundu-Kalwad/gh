package com.srk.aichat.notification

import android.util.Log
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.messaging.FirebaseMessaging
import kotlinx.coroutines.tasks.await

/**
 * Utility class to manage notification settings and token registration
 */
class NotificationManager {
    companion object {
        private const val TAG = "NotificationManager"
        private const val TOKEN_COLLECTION = "user_tokens"

        /**
         * Register the current device token with the current user in Firestore
         */
        suspend fun registerDeviceToken() {
            try {
                val userId = FirebaseAuth.getInstance().currentUser?.uid ?: return
                
                // Get the FCM token
                val token = FirebaseMessaging.getInstance().token.await()
                
                // Store it in Firestore under the user's document
                val tokenData = hashMapOf(
                    "userId" to userId,
                    "token" to token,
                    "createdAt" to System.currentTimeMillis(),
                    "platform" to "android"
                )
                
                // Save to Firestore
                FirebaseFirestore.getInstance()
                    .collection(TOKEN_COLLECTION)
                    .document(userId)
                    .set(tokenData)
                    .await()
                
                Log.d(TAG, "FCM token registered for user: $userId")
            } catch (e: Exception) {
                Log.e(TAG, "Error registering FCM token", e)
            }
        }
        
        /**
         * Subscribe to a topic for group notifications
         */
        suspend fun subscribeToTopic(topic: String): Boolean {
            return try {
                FirebaseMessaging.getInstance().subscribeToTopic(topic).await()
                Log.d(TAG, "Subscribed to topic: $topic")
                true
            } catch (e: Exception) {
                Log.e(TAG, "Error subscribing to topic: $topic", e)
                false
            }
        }
        
        /**
         * Unsubscribe from a topic
         */
        suspend fun unsubscribeFromTopic(topic: String): Boolean {
            return try {
                FirebaseMessaging.getInstance().unsubscribeFromTopic(topic).await()
                Log.d(TAG, "Unsubscribed from topic: $topic")
                true
            } catch (e: Exception) {
                Log.e(TAG, "Error unsubscribing from topic: $topic", e)
                false
            }
        }
    }
} 