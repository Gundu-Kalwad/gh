import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:pro_coding_studio/logic/github_auth_logic/github_login_token.dart';

/// Provider for SSH key generation status
final sshKeyGenerationStatusProvider = StateProvider<SSHKeyStatus>((ref) => SSHKeyStatus.none);

/// Provider for SSH public key
final sshPublicKeyProvider = StateProvider<String?>((ref) => null);

/// Provider for whether SSH is configured
final sshConfiguredProvider = StateProvider<bool>((ref) => false);

/// Status of SSH key generation
enum SSHKeyStatus {
  none,
  generating,
  generated,
  uploading,
  uploaded,
  error,
}

/// Class for handling GitHub SSH operations
class GitHubSSHOperations {
  static const MethodChannel _channel = MethodChannel('com.pmk.pro_coding_studio/github_ssh');
  static const _secureStorage = FlutterSecureStorage();
  
  /// Generate SSH key pair
  static Future<Map<String, String>?> generateSSHKeyPair(String email) async {
    try {
      final result = await _channel.invokeMethod('generateSSHKeyPair', {
        'email': email,
      });
      
      if (result != null) {
        final Map<String, dynamic> keyPair = Map<String, dynamic>.from(result);
        
        // Store private key securely
        await _secureStorage.write(
          key: 'github_ssh_private_key', 
          value: keyPair['privateKey'] as String
        );
        
        // Store public key securely
        await _secureStorage.write(
          key: 'github_ssh_public_key', 
          value: keyPair['publicKey'] as String
        );
        
        await _secureStorage.write(
          key: 'github_ssh_configured', 
          value: 'true'
        );
        
        return {
          'publicKey': keyPair['publicKey'] as String,
          'privateKey': keyPair['privateKey'] as String,
        };
      }
      return null;
    } on PlatformException catch (e) {
      debugPrint('Error generating SSH key pair: ${e.message}');
      return null;
    }
  }
  
  /// Upload SSH public key to GitHub
  static Future<bool> uploadSSHKeyToGitHub(WidgetRef ref, String title, String publicKey) async {
    try {
      final token = ref.read(githubTokenProvider);
      if (token == null) {
        debugPrint('GitHub token is null, cannot upload SSH key');
        return false;
      }
      
      final response = await http.post(
        Uri.parse('https://api.github.com/user/keys'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/vnd.github+json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': title,
          'key': publicKey,
        }),
      );
      
      if (response.statusCode == 201) {
        debugPrint('SSH key uploaded successfully');
        await _secureStorage.write(key: 'github_ssh_uploaded', value: 'true');
        return true;
      } else {
        debugPrint('Failed to upload SSH key: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error uploading SSH key: $e');
      return false;
    }
  }
  
  /// Check if SSH key is configured
  static Future<bool> isSSHConfigured() async {
    try {
      final configured = await _secureStorage.read(key: 'github_ssh_configured');
      return configured == 'true';
    } catch (e) {
      debugPrint('Error checking SSH configuration: $e');
      return false;
    }
  }
  
  /// Get SSH public key
  static Future<String?> getSSHPublicKey() async {
    try {
      return await _secureStorage.read(key: 'github_ssh_public_key');
    } catch (e) {
      debugPrint('Error getting SSH public key: $e');
      return null;
    }
  }
  
  /// Get SSH private key
  static Future<String?> getSSHPrivateKey() async {
    try {
      return await _secureStorage.read(key: 'github_ssh_private_key');
    } catch (e) {
      debugPrint('Error getting SSH private key: $e');
      return null;
    }
  }
  
  /// Initialize SSH configuration
  static Future<void> initializeSSHConfiguration(WidgetRef ref) async {
    try {
      final configured = await isSSHConfigured();
      ref.read(sshConfiguredProvider.notifier).state = configured;
      
      if (configured) {
        final publicKey = await getSSHPublicKey();
        ref.read(sshPublicKeyProvider.notifier).state = publicKey;
        ref.read(sshKeyGenerationStatusProvider.notifier).state = SSHKeyStatus.generated;
      }
    } catch (e) {
      debugPrint('Error initializing SSH configuration: $e');
    }
  }
  
  /// Generate and upload SSH key
  static Future<bool> generateAndUploadSSHKey(WidgetRef ref, String email) async {
    try {
      // Create a local variable to track if the ref is still valid
      bool isRefValid = true;
      
      // Create a function to safely update state
      void safeUpdateState(StateProvider<dynamic> provider, dynamic value) {
        try {
          if (isRefValid) {
            ref.read(provider.notifier).state = value;
          }
        } catch (e) {
          // If we can't update the state, the widget was likely disposed
          isRefValid = false;
          debugPrint('Ref is no longer valid: $e');
        }
      }
      
      // Update status to generating
      safeUpdateState(sshKeyGenerationStatusProvider, SSHKeyStatus.generating);
      if (!isRefValid) return false;
      
      // Generate SSH key pair
      final keyPair = await generateSSHKeyPair(email);
      if (keyPair == null) {
        safeUpdateState(sshKeyGenerationStatusProvider, SSHKeyStatus.error);
        return false;
      }
      if (!isRefValid) return false;
      
      // Update status to generated
      safeUpdateState(sshKeyGenerationStatusProvider, SSHKeyStatus.generated);
      safeUpdateState(sshPublicKeyProvider, keyPair['publicKey']);
      if (!isRefValid) return false;
      
      // Create a title for the SSH key using device name and date
      final deviceName = 'Pro Coding Studio Mobile';
      final title = '$deviceName - ${DateTime.now().toIso8601String().split('T')[0]}';
      
      // Update status to uploading
      safeUpdateState(sshKeyGenerationStatusProvider, SSHKeyStatus.uploading);
      if (!isRefValid) return false;
      
      // Get token before potentially losing ref
      final token = ref.read(githubTokenProvider);
      if (token == null) {
        safeUpdateState(sshKeyGenerationStatusProvider, SSHKeyStatus.error);
        return false;
      }
      
      // Upload SSH key to GitHub (without using ref directly)
      final uploaded = await _uploadSSHKeyToGitHubSafe(token, title, keyPair['publicKey']!);
      if (!uploaded) {
        safeUpdateState(sshKeyGenerationStatusProvider, SSHKeyStatus.error);
        return false;
      }
      if (!isRefValid) return false;
      
      // Update status to uploaded
      safeUpdateState(sshKeyGenerationStatusProvider, SSHKeyStatus.uploaded);
      safeUpdateState(sshConfiguredProvider, true);
      
      // Store that the key was uploaded
      await _secureStorage.write(key: 'github_ssh_uploaded', value: 'true');
      
      return true;
    } catch (e) {
      debugPrint('Error generating and uploading SSH key: $e');
      try {
        ref.read(sshKeyGenerationStatusProvider.notifier).state = SSHKeyStatus.error;
      } catch (stateError) {
        // Widget was likely disposed, ignore
      }
      return false;
    }
  }
  
  /// Upload SSH key to GitHub without using ref (safe version)
  static Future<bool> _uploadSSHKeyToGitHubSafe(String token, String title, String publicKey) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.github.com/user/keys'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/vnd.github+json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': title,
          'key': publicKey,
        }),
      );
      
      if (response.statusCode == 201) {
        debugPrint('SSH key uploaded successfully');
        return true;
      } else {
        debugPrint('Failed to upload SSH key: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error uploading SSH key: $e');
      return false;
    }
  }
}
