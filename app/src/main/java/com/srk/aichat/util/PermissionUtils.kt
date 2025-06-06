package com.srk.aichat.util

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.ContextCompat

/**
 * Utility class for handling app permissions
 */
object PermissionUtils {
    
    /**
     * Check if notification permission is granted (For API 33+)
     */
    fun hasNotificationPermission(context: Context): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            // For devices below API 33, notifications don't require runtime permission
            true
        }
    }
    
    /**
     * Check if we can show the rationale for notification permission
     */
    fun shouldShowNotificationPermissionRationale(context: Context): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val activity = context as? androidx.activity.ComponentActivity
            activity?.shouldShowRequestPermissionRationale(Manifest.permission.POST_NOTIFICATIONS) ?: false
        } else {
            false
        }
    }
    
    /**
     * Open app settings to allow the user to enable permissions manually
     */
    fun openAppSettings(context: Context) {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.fromParts("package", context.packageName, null)
        }
        context.startActivity(intent)
    }
} 