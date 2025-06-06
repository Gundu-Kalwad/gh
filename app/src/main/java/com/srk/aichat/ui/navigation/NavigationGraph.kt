package com.srk.aichat.ui.navigation

import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import com.srk.aichat.auth.AuthViewModel
import com.srk.aichat.ui.screens.ChatScreen
import com.srk.aichat.ui.screens.LoginScreen
import com.srk.aichat.ui.screens.SignUpScreen

@Composable
fun NavigationGraph(
    navController: NavHostController,
    modifier: Modifier = Modifier,
    authViewModel: AuthViewModel = viewModel()
) {
    val currentUser by authViewModel.currentUser.collectAsState()

    NavHost(
        navController = navController,
        startDestination = if (currentUser != null) Routes.Chat.route else Routes.Login.route,
        modifier = modifier
    ) {
        composable(Routes.Login.route) {
            LoginScreen(
                onNavigateToSignUp = { navController.navigate(Routes.SignUp.route) },
                onLoginSuccess = { navController.navigate(Routes.Chat.route) {
                    popUpTo(Routes.Login.route) { inclusive = true }
                }},
                authViewModel = authViewModel
            )
        }

        composable(Routes.SignUp.route) {
            SignUpScreen(
                onNavigateToLogin = { navController.navigate(Routes.Login.route) {
                    popUpTo(Routes.SignUp.route) { inclusive = true }
                }},
                onSignUpSuccess = { navController.navigate(Routes.Chat.route) {
                    popUpTo(Routes.SignUp.route) { inclusive = true }
                }},
                authViewModel = authViewModel
            )
        }

        composable(Routes.Chat.route) {
            ChatScreen(
                onSignOut = {
                    authViewModel.signOut()
                    navController.navigate(Routes.Login.route) {
                        popUpTo(Routes.Chat.route) { inclusive = true }
                    }
                }
            )
        }
    }
}

sealed class Routes(val route: String) {
    object Login : Routes("login")
    object SignUp : Routes("signup")
    object Chat : Routes("chat")
} 