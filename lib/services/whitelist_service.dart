import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Whitelist service for free/admin accounts
/// 
/// Allows specific users to bypass subscription requirements
class WhitelistService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Hardcoded admin emails (your team, testers, etc.)
  static const List<String> _adminEmails = [
    'hello@arboristsbynature.com.au',  // Your main email
    'admin@arboristsbynature.com.au',   // Admin account
    'test@arboristsbynature.com.au',    // Testing account
    // Add more emails as needed
  ];
  
  /// Check if current user is whitelisted (free access)
  static Future<bool> isWhitelisted() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      final email = user.email?.toLowerCase();
      if (email == null) return false;
      
      // Check hardcoded admin list
      if (_adminEmails.contains(email)) {
        return true;
      }
      
      // Check Firebase whitelist (dynamic list you can update without app update)
      try {
        final doc = await _firestore
            .collection('whitelist')
            .doc(email)
            .get();
        
        if (doc.exists) {
          final data = doc.data();
          return data?['active'] == true;
        }
      } catch (e) {
        print('Error checking Firebase whitelist: $e');
        // Continue to return false if Firebase check fails
      }
      
      return false;
    } catch (e) {
      print('Error checking whitelist: $e');
      return false;
    }
  }
  
  /// Check if user has access (either whitelisted OR subscribed)
  static Future<bool> hasAccess() async {
    // First check whitelist (free access)
    final isWhitelisted = await WhitelistService.isWhitelisted();
    if (isWhitelisted) {
      print('✅ User is whitelisted - free access granted');
      return true;
    }
    
    // Then check subscription
    final hasSubscription = await SubscriptionService.hasActiveSubscription();
    if (hasSubscription) {
      print('✅ User has active subscription');
      return true;
    }
    
    print('❌ User needs to subscribe');
    return false;
  }
  
  /// Add email to whitelist (call this from admin panel or Firebase console)
  static Future<void> addToWhitelist(String email, {String? reason}) async {
    try {
      await _firestore.collection('whitelist').doc(email.toLowerCase()).set({
        'email': email.toLowerCase(),
        'active': true,
        'reason': reason ?? 'Manual add',
        'addedAt': FieldValue.serverTimestamp(),
        'addedBy': _auth.currentUser?.email ?? 'system',
      });
      print('✅ Added $email to whitelist');
    } catch (e) {
      print('❌ Error adding to whitelist: $e');
      rethrow;
    }
  }
  
  /// Remove email from whitelist
  static Future<void> removeFromWhitelist(String email) async {
    try {
      await _firestore.collection('whitelist').doc(email.toLowerCase()).delete();
      print('✅ Removed $email from whitelist');
    } catch (e) {
      print('❌ Error removing from whitelist: $e');
      rethrow;
    }
  }
  
  /// Get all whitelisted users (admin function)
  static Future<List<Map<String, dynamic>>> getWhitelistedUsers() async {
    try {
      final snapshot = await _firestore
          .collection('whitelist')
          .where('active', isEqualTo: true)
          .get();
      
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error getting whitelist: $e');
      return [];
    }
  }
}

// Add this import to subscription_service.dart
import 'whitelist_service.dart';
