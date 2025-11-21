import 'package:hive_flutter/hive_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/user.dart' as app_user;
import 'firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class AuthService {
  static const String boxName = 'users';
  static const String currentUserKey = 'current_user';
  static const String sessionKey = 'session_token';
  
  static late Box<app_user.User> _userBox;
  static late Box _sessionBox;
  
  static app_user.User? _currentUser;
  static app_user.User? _firebaseUser;
  
  /// Initialize the authentication service
  static Future<void> init() async {
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(app_user.UserAdapter());
    }
    _userBox = await Hive.openBox<app_user.User>(boxName);
    _sessionBox = await Hive.openBox('auth_session');
    
    // Load current user from session
    final userId = _sessionBox.get(currentUserKey);
    if (userId != null) {
      _currentUser = _userBox.get(userId);
    }
    
    // Create default admin user if no users exist
    if (_userBox.isEmpty) {
      await _createDefaultAdmin();
    }
    
    // TEMPORARY: Set default user for development (bypass login)
    if (_currentUser == null) {
      final defaultUser = _userBox.values.first;
      if (defaultUser != null) {
        _currentUser = defaultUser;
        await _sessionBox.put(currentUserKey, defaultUser.id);
        print('DEBUG: Set default user: ${defaultUser.email}');
      }
    }
    
    // Listen to Firebase auth state changes
    firebase_auth.FirebaseAuth.instance.authStateChanges().listen((firebase_auth.User? firebaseUser) {
      if (firebaseUser != null) {
        _handleFirebaseUserSignIn(firebaseUser);
      } else {
        _handleFirebaseUserSignOut();
      }
    });
  }
  
  /// Handle Firebase user sign in
  static Future<void> _handleFirebaseUserSignIn(firebase_auth.User firebaseUser) async {
    try {
      // Check if user exists in local database
      app_user.User? localUser;
      try {
        localUser = _userBox.values.firstWhere(
          (user) => user.email.toLowerCase() == firebaseUser.email?.toLowerCase(),
        );
      } catch (e) {
        // User not found, will create new one
        localUser = null;
      }
      
      if (localUser == null) {
        // Create new local user from Firebase user
        // Use displayName if available, otherwise extract name from email
        String userName = firebaseUser.displayName ?? '';
        if (userName.isEmpty && firebaseUser.email != null) {
          // Extract username from email (part before @)
          userName = firebaseUser.email!.split('@').first;
          // Capitalize first letter
          if (userName.isNotEmpty) {
            userName = userName[0].toUpperCase() + userName.substring(1);
          }
        }
        if (userName.isEmpty) {
          userName = 'Arborist';
        }
        
        localUser = app_user.User(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          name: userName,
          role: 'arborist',
          createdAt: DateTime.now(),
          permissions: _getDefaultPermissions('arborist'),
        );
        
        await _userBox.put(localUser.id, localUser);
        
        // Save to Firestore
        try {
          await FirebaseService.saveUserData(localUser);
        } catch (e) {
          print('Failed to save user to Firestore: $e');
        }
      }
      
      _firebaseUser = localUser;
      _currentUser = localUser;
      await _sessionBox.put(currentUserKey, localUser.id);
      
      // Update last login
      final updatedUser = localUser.copyWith(lastLoginAt: DateTime.now());
      await _userBox.put(localUser.id, updatedUser);
      _currentUser = updatedUser;
      
    } catch (e) {
      print('Error handling Firebase user sign in: $e');
    }
  }
  
  /// Handle Firebase user sign out
  static void _handleFirebaseUserSignOut() {
    _firebaseUser = null;
    _currentUser = null;
    _sessionBox.delete(currentUserKey);
  }
  
  /// Create default admin user
  static Future<void> _createDefaultAdmin() async {
    final adminUser = app_user.User(
      id: 'admin',
      email: 'admin@arborist.com',
      name: 'Administrator',
      role: 'admin',
      createdAt: DateTime.now(),
      permissions: [
        'edit_sites',
        'delete_sites',
        'edit_trees',
        'delete_trees',
        'export_data',
        'manage_users',
      ],
    );
    
    await _userBox.put(adminUser.id, adminUser);
  }
  
  /// Get current user
  static app_user.User? getCurrentUser() => _currentUser;
  
  /// Check if user is logged in
  static bool isLoggedIn() => _currentUser != null;
  
  /// Check if user is signed in with Firebase
  static bool isFirebaseUser() => _firebaseUser != null;
  
  /// Login with email and password (Firebase priority, local fallback)
  static Future<bool> login(String email, String password) async {
    print('AuthService.login called with email: $email'); // Debug log
    print('FirebaseService.isOnline: ${FirebaseService.isOnline}'); // Debug log
    print('Current users in box: ${_userBox.values.length}'); // Debug log
    
    try {
      // Always try Firebase authentication first (since we now have real credentials)
      try {
        print('Attempting Firebase authentication...'); // Debug log
        await FirebaseService.signInWithEmailAndPassword(email, password);
        print('Firebase authentication successful'); // Debug log
        return true; // Firebase auth will trigger auth state change
      } catch (e) {
        print('Firebase login failed: $e');
        
        // If Firebase fails, check if it's because user doesn't exist
        if (e.toString().contains('user-not-found')) {
          // Try to create the user in Firebase first
          try {
            print('User not found in Firebase, attempting to create...'); // Debug log
            await FirebaseService.createUserWithEmailAndPassword(email, password);
            print('User created in Firebase successfully'); // Debug log
            return true; // Firebase auth will trigger auth state change
          } catch (createError) {
            print('Failed to create user in Firebase: $createError');
            // Fall back to local auth
          }
        }
        
        // Fall back to local auth if Firebase completely fails
        print('Falling back to local authentication...'); // Debug log
      }
      
      // Fall back to local authentication
      final user = _userBox.values.firstWhere(
        (user) => user.email.toLowerCase() == email.toLowerCase(),
        orElse: () => throw Exception('User not found'),
      );
      
      print('Found user: ${user.name} (${user.email})'); // Debug log
      
      // Check if user is active
      if (!user.isActive) {
        throw Exception('Account is deactivated');
      }
      
      // For demo purposes, accept any password for existing users
      // In production, you'd hash and verify the password
      if (password.isNotEmpty) {
        print('Password validation passed, updating user...'); // Debug log
        
        // Update last login
        final updatedUser = user.copyWith(lastLoginAt: DateTime.now());
        await _userBox.put(user.id, updatedUser);
        
        // Set current user
        _currentUser = updatedUser;
        await _sessionBox.put(currentUserKey, user.id);
        
        print('Login successful, current user set: ${_currentUser?.name}'); // Debug log
        return true;
      } else {
        throw Exception('Password cannot be empty');
      }
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }
  
  /// Register new user (Firebase priority)
  static Future<bool> register(String email, String password, String name, {String role = 'arborist'}) async {
    print('AuthService.register called with email: $email, name: $name'); // Debug log
    
    try {
      // Check if user already exists locally
      final existingUser = _userBox.values.any(
        (user) => user.email.toLowerCase() == email.toLowerCase(),
      );
      
      if (existingUser) {
        throw Exception('User already exists');
      }
      
      // Always try Firebase registration first (since we now have real credentials)
      try {
        print('Attempting Firebase registration...'); // Debug log
        final credential = await FirebaseService.createUserWithEmailAndPassword(email, password);
        print('Firebase registration successful, UID: ${credential.user?.uid}'); // Debug log
        
        // Create new user with Firebase UID
        final newUser = app_user.User(
          id: credential.user?.uid ?? DateTime.now().millisecondsSinceEpoch.toString(),
          email: email,
          name: name,
          role: role,
          createdAt: DateTime.now(),
          permissions: _getDefaultPermissions(role),
        );
        
        // Save to local storage
        await _userBox.put(newUser.id, newUser);
        print('User saved to local storage'); // Debug log
        
        // Save to Firestore
        try {
          await FirebaseService.saveUserData(newUser);
          print('User saved to Firestore'); // Debug log
        } catch (e) {
          print('Failed to save user to Firestore: $e');
        }
        
        return true;
      } catch (e) {
        print('Firebase registration failed: $e');
        
        // Fall back to local registration only if Firebase completely fails
        if (e.toString().contains('email-already-in-use')) {
          throw Exception('An account with this email already exists');
        }
        
        print('Falling back to local registration...'); // Debug log
        
        // Create local user
        final newUser = app_user.User(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          email: email,
          name: name,
          role: role,
          createdAt: DateTime.now(),
          permissions: _getDefaultPermissions(role),
        );
        
        await _userBox.put(newUser.id, newUser);
        print('User saved to local storage only'); // Debug log
        return true;
      }
    } catch (e) {
      print('Registration error: $e');
      return false;
    }
  }
  
  /// Get default permissions for role
  static List<String> _getDefaultPermissions(String role) {
    switch (role) {
      case 'admin':
        return [
          'edit_sites',
          'delete_sites',
          'edit_trees',
          'delete_trees',
          'export_data',
          'manage_users',
        ];
      case 'arborist':
        return [
          'edit_sites',
          'edit_trees',
          'export_data',
        ];
      case 'viewer':
        return [
          'export_data',
        ];
      default:
        return [];
    }
  }
  
  /// Logout current user
  static Future<void> logout() async {
    // Sign out from Firebase if user was signed in with Firebase
    if (_firebaseUser != null) {
      try {
        await FirebaseService.signOut();
      } catch (e) {
        print('Firebase sign out failed: $e');
      }
    }
    
    _currentUser = null;
    _firebaseUser = null;
    await _sessionBox.delete(currentUserKey);
  }
  
  /// Get all users (admin only)
  static List<app_user.User> getAllUsers() {
    if (_currentUser?.role != 'admin') {
      return [];
    }
    return _userBox.values.toList();
  }
  
  /// Update user
  static Future<bool> updateUser(app_user.User user) async {
    if (_currentUser?.role != 'admin' && _currentUser?.id != user.id) {
      return false;
    }
    
    await _userBox.put(user.id, user);
    
    // Update current user if it's the same user
    if (_currentUser?.id == user.id) {
      _currentUser = user;
    }
    
    // Save to Firestore if online
    if (FirebaseService.isOnline) {
      try {
        await FirebaseService.saveUserData(user);
      } catch (e) {
        print('Failed to save user to Firestore: $e');
      }
    }
    
    return true;
  }
  
  /// Delete user
  static Future<bool> deleteUser(String userId) async {
    if (_currentUser?.role != 'admin') {
      return false;
    }
    
    await _userBox.delete(userId);
    return true;
  }
  
  /// Check if user is authenticated
  static bool isAuthenticated() {
    return _currentUser != null;
  }
  
  /// Close the service
  static Future<void> close() async {
    await _userBox.close();
    await _sessionBox.close();
  }
}
