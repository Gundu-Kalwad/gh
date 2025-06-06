package com.srk.aichat.notification

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.RingtoneManager
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import com.srk.aichat.MainActivity
import com.srk.aichat.R

class AIChatMessagingService : FirebaseMessagingService() {
    companion object {
        private const val TAG = "AI:Ask AnythingMessagingService"
        const val CHANNEL_ID = "AI:Ask Anything_notifications"
        const val CHANNEL_NAME = "AI:Ask Anything Notifications"
        const val CHANNEL_DESCRIPTION = "Notifications from AI:Ask Anything app"
    }

    override fun onNewToken(token: String) {
        Log.d(TAG, "Refreshed FCM token: $token")
        
        // Send the token to your server if needed
        // This is important for targeting specific devices
        sendRegistrationToServer(token)
    }
    
    private fun sendRegistrationToServer(token: String) {
        // TODO: Implement server registration
        // This would typically send the token to your backend
        // where you'd associate it with the current user
        Log.d(TAG, "Sending token to server: $token")
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        Log.d(TAG, "From: ${remoteMessage.from}")
        
        // Check if message contains a notification payload
        remoteMessage.notification?.let {
            Log.d(TAG, "Notification Title: ${it.title}")
            Log.d(TAG, "Notification Body: ${it.body}")
            
            // Display the notification
            it.title?.let { title ->
                it.body?.let { body ->
                    sendNotification(title, body, remoteMessage.data)
                }
            }
        }
        
        // Check if message contains data payload
        if (remoteMessage.data.isNotEmpty()) {
            Log.d(TAG, "Message data payload: ${remoteMessage.data}")
            
            // Handle data message
            // You can process data even when app is in background
            val title = remoteMessage.data["title"] ?: "New Message"
            val body = remoteMessage.data["body"] ?: "You have a new message"
            sendNotification(title, body, remoteMessage.data)
        }
    }
    
    private fun sendNotification(title: String, messageBody: String, data: Map<String, String>) {
        // Create an intent to open the app when notification is tapped
        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            // Pass any data from the notification to the app if needed
            data.forEach { (key, value) ->
                putExtra(key, value)
            }
        }
        
        // Create a pending intent
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        
        // Set up notification appearance
        val defaultSoundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
        val notificationBuilder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(messageBody)
            .setAutoCancel(true)
            .setSound(defaultSoundUri)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
        
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        // Create the notification channel for Android O and above
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = CHANNEL_DESCRIPTION
                enableLights(true)
                enableVibration(true)
            }
            notificationManager.createNotificationChannel(channel)
        }
        
        // Show the notification
        notificationManager.notify(0, notificationBuilder.build())
    }
} 