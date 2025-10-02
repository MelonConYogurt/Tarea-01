import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const String _tokenKey = 'user_token';
  static const String _userIdKey = 'user_id';
  static const String _emailKey = 'user_email';

  Future<void> initializeAuth() async {
    try {
      final savedToken = await _storage.read(key: _tokenKey);
      final savedUserId = await _storage.read(key: _userIdKey);
      
      if (savedToken != null && savedUserId != null) {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null || currentUser.uid != savedUserId) {
          await _clearStoredCredentials();
        }
      }
    } catch (e) {
      debugPrint('Error initializing auth: $e');
      await _clearStoredCredentials();
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _storeUserCredentials(credential.user!);
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      debugPrint('Login error: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Unexpected login error: $e');
      return false;
    }
  }

  Future<bool> register(String email, String password, String name) async {
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await credential.user!.updateDisplayName(name);
        await credential.user!.reload();
        
        await _storeUserCredentials(credential.user!);
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      debugPrint('Registration error: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Unexpected registration error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      await _clearStoredCredentials();
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  Future<String?> getUserToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        return await user.getIdToken();
      }
      return await _storage.read(key: _tokenKey);
    } catch (e) {
      debugPrint('Error getting user token: $e');
      return null;
    }
  }

  Future<bool> isTokenValid() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      
      final token = await user.getIdToken(true);
      return token != null && token.isNotEmpty;
    } catch (e) {
      debugPrint('Error validating token: $e');
      return false;
    }
  }

  Future<void> _storeUserCredentials(User user) async {
    try {
      final token = await user.getIdToken();
      
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _userIdKey, value: user.uid);
      await _storage.write(key: _emailKey, value: user.email ?? '');
    } catch (e) {
      debugPrint('Error storing credentials: $e');
    }
  }

  Future<void> _clearStoredCredentials() async {
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _userIdKey);
      await _storage.delete(key: _emailKey);
    } catch (e) {
      debugPrint('Error clearing credentials: $e');
    }
  }

  Future<void> refreshToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final newToken = await user.getIdToken(true);
        await _storage.write(key: _tokenKey, value: newToken);
      }
    } catch (e) {
      debugPrint('Error refreshing token: $e');
    }
  }
}