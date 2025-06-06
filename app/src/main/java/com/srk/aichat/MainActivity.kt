package com.srk.aichat

import android.Manifest
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.lifecycle.ViewModelProvider
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.srk.aichat.auth.AuthViewModel
import com.srk.aichat.ui.screens.ChatScreen
import com.srk.aichat.ui.screens.LoginScreen
import com.srk.aichat.ui.screens.SignUpScreen
import com.srk.aichat.ui.theme.AIAskAnythingTheme

class MainActivity : ComponentActivity() {
    private lateinit var authViewModel: AuthViewModel
    
    // Store permission state at the activity level
    var notificationPermissionGranted by mutableStateOf(false)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Initialize AuthViewModel
        authViewModel = ViewModelProvider(this)[AuthViewModel::class.java]
        
        // Check notification permission for API 33+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            notificationPermissionGranted = checkSelfPermission(
                Manifest.permission.POST_NOTIFICATIONS
            ) == android.content.pm.PackageManager.PERMISSION_GRANTED
        } else {
            notificationPermissionGranted = true
        }
        
        setContent {
            AppContent()
        }
    }
    
    @Composable
    fun AppContent() {
        AIAskAnythingTheme {
            Surface(
                modifier = Modifier.fillMaxSize(),
                color = MaterialTheme.colorScheme.background
            ) {
                val navController = rememberNavController()
                val currentUser by authViewModel.currentUser.collectAsState()
                
                // Permission launcher
                val permissionLauncher = rememberLauncherForActivityResult(
                    contract = ActivityResultContracts.RequestPermission(),
                    onResult = { isGranted ->
                        notificationPermissionGranted = isGranted
                    }
                )
                
                NavHost(
                    navController = navController,
                    startDestination = if (currentUser != null) "chat" else "login"
                ) {
                    composable("login") {
                        LoginScreen(
                            onNavigateToSignUp = { navController.navigate("signup") },
                            onLoginSuccess = { navController.navigate("chat") {
                                popUpTo("login") { inclusive = true }
                            }},
                            authViewModel = authViewModel
                        )
                    }
                    
                    composable("signup") {
                        SignUpScreen(
                            onNavigateToLogin = { navController.popBackStack() },
                            onSignUpSuccess = { navController.navigate("chat") {
                                popUpTo("signup") { inclusive = true }
                            }},
                            authViewModel = authViewModel
                        )
                    }
                    
                    composable("chat") {
                        // Request notification permission if not granted yet (API 33+)
                        LaunchedEffect(Unit) {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && !notificationPermissionGranted) {
                                permissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                            }
                        }
                        
                        ChatScreen(
                            onSignOut = {
                                authViewModel.signOut()
                                navController.navigate("login") {
                                    popUpTo("chat") { inclusive = true }
                                }
                            },
                            authViewModel = authViewModel,
                            notificationPermissionGranted = notificationPermissionGranted,
                            onRequestNotificationPermission = {
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                    permissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                                }
                            }
                        )
                    }
                }
            }
        }
    }
}