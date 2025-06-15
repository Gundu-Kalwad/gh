package com.pmk.pro_coding_studio

import android.util.Log
import com.jcraft.jsch.JSch
import com.jcraft.jsch.KeyPair
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.security.SecureRandom

/**
 * Handler for GitHub SSH operations
 */
class GitHubSSHHandler(private val activity: MainActivity) {
    companion object {
        private const val TAG = "GitHubSSHHandler"
    }

    /**
     * Handle method calls from Flutter
     */
    fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "generateSSHKeyPair" -> {
                val email = call.argument<String>("email") ?: ""
                generateSSHKeyPair(email, result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    /**
     * Generate SSH key pair
     */
    private fun generateSSHKeyPair(email: String, result: MethodChannel.Result) {
        Thread {
            try {
                val jsch = JSch()
                val keyPair = KeyPair.genKeyPair(jsch, KeyPair.RSA, 4096)

                // Set up output streams for public and private keys
                val publicKeyStream = ByteArrayOutputStream()
                val privateKeyStream = ByteArrayOutputStream()

                // Export keys
                keyPair.writePublicKey(publicKeyStream, "$email")
                keyPair.writePrivateKey(privateKeyStream)

                // Convert to strings
                val publicKey = publicKeyStream.toString()
                val privateKey = privateKeyStream.toString()

                // Clean up
                keyPair.dispose()
                publicKeyStream.close()
                privateKeyStream.close()

                // Return result to Flutter
                activity.runOnUiThread {
                    result.success(mapOf(
                        "publicKey" to publicKey,
                        "privateKey" to privateKey
                    ))
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error generating SSH key pair", e)
                activity.runOnUiThread {
                    result.error("SSH_ERROR", "Error generating SSH key pair: ${e.message}", null)
                }
            }
        }.start()
    }

    /**
     * Save SSH key to file
     */
    private fun saveKeyToFile(key: String, filePath: String): Boolean {
        return try {
            val file = File(filePath)
            file.parentFile?.mkdirs()
            
            FileOutputStream(file).use { fos ->
                fos.write(key.toByteArray())
            }
            
            // Set permissions (600 - owner read/write only)
            file.setReadable(false, false)
            file.setReadable(true, true)
            file.setWritable(false, false)
            file.setWritable(true, true)
            file.setExecutable(false, false)
            
            true
        } catch (e: Exception) {
            Log.e(TAG, "Error saving key to file", e)
            false
        }
    }
}
