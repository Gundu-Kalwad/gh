package com.srk.aichat.data

import com.google.firebase.auth.FirebaseUser

data class UserProfile(
    val uid: String,
    val name: String,
    val email: String,
    val photoUrl: String? = null
) {
    companion object {
        fun fromFirebaseUser(user: FirebaseUser): UserProfile {
            return UserProfile(
                uid = user.uid,
                name = user.displayName ?: "User",
                email = user.email ?: "",
                photoUrl = user.photoUrl?.toString()
            )
        }
    }
} 