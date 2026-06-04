import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:verithrive_dev/utils/logger.dart';
import '../services/storage_service.dart';
import '../utils/jwt_decoder.dart';

/// Service for handling social authentication (Google and Apple)
class SocialAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  static const _appleUserEmailKey = 'apple_user_email';
  static const _appleUserNameKey = 'apple_user_name';
  static const _appleUserIdKey = 'apple_user_id';

  /// Sign in with Google
  /// Returns a map with user information or null if sign-in failed
  Future<Map<String, String?>?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final String code = googleAuth.serverAuthCode?.isNotEmpty == true
          ? googleAuth.serverAuthCode!
          : (googleAuth.idToken?.isNotEmpty == true
              ? googleAuth.idToken!
              : (googleAuth.accessToken ?? ''));

      logInfo('Google sign-in success: '
          'id=${googleUser.id}, '
          'email=${googleUser.email}, '
          'displayName=${googleUser.displayName}, '
          'photoUrl=${googleUser.photoUrl}, '
          'idToken=${googleAuth.idToken?.substring(0, 15)}, '
          'accessToken=${googleAuth.accessToken?.substring(0, 15)}, '
          'code=${code.substring(0, code.length > 15 ? 15 : code.length)}, '
          'provider=google');

      return {
        'id': googleUser.id,
        'email': googleUser.email,
        'displayName': googleUser.displayName ?? '',
        'photoUrl': googleUser.photoUrl ?? '',
        'idToken': googleAuth.idToken ?? '',
        'accessToken': googleAuth.accessToken ?? '',
        'code': googleUser.id,
        'provider': 'google',
      };
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      rethrow;
    }
  }

  /// Sign in with Apple
  /// Returns a map with user information or null if sign-in failed
  /// Works on both iOS and Android (Android uses web-based authentication)
  Future<Map<String, String?>?> signInWithApple() async {
    try {
      // Check if Apple Sign In is available
      final isAvailable = await SignInWithApple.isAvailable();

      if (!isAvailable) {
        throw Exception('Apple Sign In is not available on this device');
      }

      // On Android, webAuthenticationOptions is required
      // You need to configure these values in your Apple Developer account:
      // - clientId: Your Apple Service ID (e.g., "com.yourcompany.yourapp.service")
      // - redirectUri: The redirect URI you configured in Apple Developer (e.g., "https://yourdomain.com/callback")
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        // Required for Android - configure these in Apple Developer Console
        webAuthenticationOptions: Platform.isAndroid
            ? WebAuthenticationOptions(
                clientId:
                    'com.app.verithrive.professional.service', // Replace with your Apple Service ID
                redirectUri: Uri.parse(
                  'https://yourdomain.com/callback', // Replace with your configured redirect URI
                ),
              )
            : null,
      );

      // Build display name from given and family name
      String displayName = '';
      if (credential.givenName != null && credential.familyName != null) {
        displayName = '${credential.givenName} ${credential.familyName}';
      } else if (credential.givenName != null) {
        displayName = credential.givenName!;
      } else if (credential.familyName != null) {
        displayName = credential.familyName!;
      }

      // Extract email from credential or decode from ID token
      String email = credential.email ?? '';

      // If email is not provided in credential (common on subsequent logins),
      // try to extract it from the ID token
      if (email.isEmpty && credential.identityToken != null) {
        final decodedEmail = JwtDecoder.getEmail(credential.identityToken!);
        if (decodedEmail != null && decodedEmail.isNotEmpty) {
          email = decodedEmail;
          debugPrint('Extracted email from Apple ID token: $email');
        }
      }

      // If still no email, try to get from stored data
      if (email.isEmpty) {
        final storage = Get.isRegistered<StorageService>()
            ? Get.find<StorageService>()
            : null;
        if (storage != null) {
          final storedEmail = storage.readString('apple_user_email');
          if (storedEmail != null && storedEmail.isNotEmpty) {
            email = storedEmail;
            debugPrint('Using stored Apple email: $email');
          }
        }
      }

      // Persist Apple user data whenever available (name is only sent on first auth)
      final storage = Get.isRegistered<StorageService>()
          ? Get.find<StorageService>()
          : null;
      if (storage != null) {
        if (email.isNotEmpty) {
          await storage.writeString(_appleUserEmailKey, email);
        }
        if (displayName.isNotEmpty) {
          await storage.writeString(_appleUserNameKey, displayName);
        }
        final userId = credential.userIdentifier;
        if (userId != null && userId.isNotEmpty) {
          await storage.writeString(_appleUserIdKey, userId);
        }
        if (email.isNotEmpty || displayName.isNotEmpty) {
          debugPrint('Stored Apple user data for future use');
        }
      }

      // Use stored display name if not provided in credential (subsequent sign-ins)
      if (displayName.isEmpty && storage != null) {
        final storedName = storage.readString(_appleUserNameKey);
        if (storedName != null && storedName.isNotEmpty) {
          displayName = storedName;
          debugPrint('Using stored Apple display name: $displayName');
        }
      }

      // Apple only sends name on first auth; generate a stable 6-letter fallback if missing
      if (displayName.isEmpty) {
        displayName = _generateAppleFallbackDisplayName();
        debugPrint('Generated Apple fallback display name: $displayName');
        if (storage != null) {
          await storage.writeString(_appleUserNameKey, displayName);
        }
      }

      return {
        'id': credential.userIdentifier ?? '',
        'email': email,
        'displayName': displayName,
        'idToken': credential.identityToken ?? '',
        'authorizationCode': credential.authorizationCode,
        'code': credential.authorizationCode,
        'provider': 'apple',
      };
    } catch (e) {
      debugPrint('Apple Sign-In Error: $e');
      rethrow;
    }
  }

  /// Sign out from Google
  Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Google Sign-Out Error: $e');
    }
  }

  /// Sign out from Apple stored credentials.
  Future<void> signOutApple() async {
    try {
      final storage = Get.isRegistered<StorageService>()
          ? Get.find<StorageService>()
          : null;
      if (storage == null) return;

      await storage.writeString(_appleUserEmailKey, '');
      await storage.writeString(_appleUserNameKey, '');
      await storage.writeString(_appleUserIdKey, '');
    } catch (e) {
      debugPrint('Apple Sign-Out Error: $e');
    }
  }

  /// Sign out from all supported social providers.
  Future<void> signOutSocialProviders() async {
    await Future.wait([
      signOutGoogle(),
      signOutApple(),
    ]);
  }

  /// Persist display name from a social sign-in (e.g. Apple first authorization).
  Future<void> persistSocialDisplayName(String displayName) async {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return;

    final storage = Get.isRegistered<StorageService>()
        ? Get.find<StorageService>()
        : null;
    if (storage == null) return;

    await storage.writeString(_appleUserNameKey, trimmed);
  }

  /// Best available full name: API response, credential, then stored Apple name.
  String resolveSocialFullName({
    String? apiFullName,
    String? credentialDisplayName,
  }) {
    final api = apiFullName?.trim() ?? '';
    if (api.isNotEmpty) return api;

    final credential = credentialDisplayName?.trim() ?? '';
    if (credential.isNotEmpty) return credential;

    final storage = Get.isRegistered<StorageService>()
        ? Get.find<StorageService>()
        : null;
    if (storage != null) {
      final stored = storage.readString(_appleUserNameKey)?.trim() ?? '';
      if (stored.isNotEmpty) return stored;
    }

    return '';
  }

  static const _appleFallbackNameChars = 'abcdefghijklmnopqrstuvwxyz';

  /// Six-letter alphabetic placeholder when Apple does not provide a name.
  static String _generateAppleFallbackDisplayName() {
    final random = Random();
    return List.generate(
      6,
      (_) => _appleFallbackNameChars[random.nextInt(_appleFallbackNameChars.length)],
    ).join();
  }

  /// Check if Apple Sign In is available
  Future<bool> isAppleSignInAvailable() async {
    try {
      return await SignInWithApple.isAvailable();
    } catch (e) {
      debugPrint('Apple Sign-In Availability Check Error: $e');
      return false;
    }
  }
}
