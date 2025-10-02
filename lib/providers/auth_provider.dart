import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;
  bool _isInitialized = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    _setLoading(true);
    try {
      await _authService.initializeAuth();
      _user = FirebaseAuth.instance.currentUser;
      
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        _user = user;
        notifyListeners();
      });
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing auth: $e');
    }
    _setLoading(false);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final success = await _authService.login(email, password);
      if (success) {
        _user = FirebaseAuth.instance.currentUser;
      }
      return success;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(String email, String password, String name) async {
    _setLoading(true);
    try {
      final success = await _authService.register(email, password, name);
      if (success) {
        _user = FirebaseAuth.instance.currentUser;
      }
      return success;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.logout();
      _user = null;
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> getUserToken() async {
    return await _authService.getUserToken();
  }

  String? getUserDisplayName() {
    return _user?.displayName;
  }

  String? getUserEmail() {
    return _user?.email;
  }
}