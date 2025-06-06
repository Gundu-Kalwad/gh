package com.srk.aichat.auth

import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseUser
import com.google.firebase.auth.UserProfileChangeRequest
import com.srk.aichat.notification.NotificationManager
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import java.util.concurrent.atomic.AtomicBoolean

class AuthViewModel : ViewModel() {
    private val TAG = "AuthViewModel"
    private val auth = FirebaseAuth.getInstance()

    private val _currentUser = MutableStateFlow<FirebaseUser?>(auth.currentUser)
    val currentUser: StateFlow<FirebaseUser?> = _currentUser

    private val _authState = MutableStateFlow<AuthState>(AuthState.Initial)
    val authState: StateFlow<AuthState> = _authState

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading

    private val authInProgress = AtomicBoolean(false)

    init {
        // Set up auth state listener
        auth.addAuthStateListener { firebaseAuth ->
            _currentUser.value = firebaseAuth.currentUser
            firebaseAuth.currentUser?.let {
                // Register FCM token when user logs in
                registerNotificationToken()
            }
        }
    }
    
    /**
     * Register the device token for push notifications
     */
    private fun registerNotificationToken() {
        viewModelScope.launch {
            try {
                NotificationManager.registerDeviceToken()
                // Subscribe to general notifications
                NotificationManager.subscribeToTopic("announcements")
            } catch (e: Exception) {
                Log.e(TAG, "Error registering for notifications", e)
            }
        }
    }

    fun signUp(name: String, email: String, password: String) {
        if (name.isBlank() || email.isBlank() || password.isBlank() || authInProgress.get()) return

        _isLoading.value = true
        authInProgress.set(true)
        _authState.value = AuthState.Initial

        viewModelScope.launch {
            try {
                // Create the user with email and password
                val result = auth.createUserWithEmailAndPassword(email, password).await()
                
                // Update the user profile with the name
                val profileUpdates = UserProfileChangeRequest.Builder()
                    .setDisplayName(name)
                    .build()
                
                result.user?.updateProfile(profileUpdates)?.await()
                
                // Register for notifications after signup
                registerNotificationToken()
                
                _authState.value = AuthState.SignUpSuccess
                Log.d(TAG, "Sign up successful for user: $name")
            } catch (e: Exception) {
                Log.e(TAG, "Sign up failed", e)
                _authState.value = AuthState.Error(e.message ?: "Unknown error occurred")
            } finally {
                _isLoading.value = false
                authInProgress.set(false)
            }
        }
    }

    fun signIn(email: String, password: String) {
        if (email.isBlank() || password.isBlank() || authInProgress.get()) return

        _isLoading.value = true
        authInProgress.set(true)
        _authState.value = AuthState.Initial

        viewModelScope.launch {
            try {
                auth.signInWithEmailAndPassword(email, password).await()
                
                // Register for notifications after signin
                registerNotificationToken()
                
                _authState.value = AuthState.SignInSuccess
                Log.d(TAG, "Sign in successful")
            } catch (e: Exception) {
                Log.e(TAG, "Sign in failed", e)
                _authState.value = AuthState.Error(e.message ?: "Unknown error occurred")
            } finally {
                _isLoading.value = false
                authInProgress.set(false)
            }
        }
    }

    fun resetPassword(email: String) {
        if (email.isBlank() || authInProgress.get()) return

        _isLoading.value = true
        authInProgress.set(true)
        _authState.value = AuthState.Initial

        viewModelScope.launch {
            try {
                auth.sendPasswordResetEmail(email).await()
                _authState.value = AuthState.PasswordResetEmailSent
                Log.d(TAG, "Password reset email sent to $email")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to send password reset email", e)
                _authState.value = AuthState.Error(e.message ?: "Unknown error occurred")
            } finally {
                _isLoading.value = false
                authInProgress.set(false)
            }
        }
    }

    fun signOut() {
        // Unsubscribe from topics when signing out
        viewModelScope.launch {
            try {
                NotificationManager.unsubscribeFromTopic("announcements")
            } catch (e: Exception) {
                Log.e(TAG, "Error unsubscribing from notifications", e)
            } finally {
                // Sign out after unsubscribing
                auth.signOut()
                _authState.value = AuthState.SignOutSuccess
            }
        }
    }

    fun resetAuthState() {
        _authState.value = AuthState.Initial
    }
}

sealed class AuthState {
    object Initial : AuthState()
    object SignUpSuccess : AuthState()
    object SignInSuccess : AuthState()
    object SignOutSuccess : AuthState()
    object PasswordResetEmailSent : AuthState()
    data class Error(val message: String) : AuthState()
} 