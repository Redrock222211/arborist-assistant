import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Subscription management service using RevenueCat
/// 
/// Monthly subscription: $50 AUD/month
/// Provides unlimited access to all app features
/// 
/// Whitelisted users get free access (admins, testers, etc.)
class SubscriptionService {
  static const String _subscriptionStatusKey = 'subscription_active';
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Hardcoded admin emails (your team, testers, etc.)
  static const List<String> _freeAccessEmails = [
    'hello@arboristsbynature.com.au',  // Your main email
    'admin@arboristsbynature.com.au',   // Admin account
    'test@arboristsbynature.com.au',    // Testing account
    'sun@moon.com',                      // Quick test: sun@moon.com / sunmoon ☀️🌙
    // Add more emails here as needed
  ];
  
  /// Initialize RevenueCat
  /// 
  /// You'll need to:
  /// 1. Sign up at https://www.revenuecat.com (FREE)
  /// 2. Create your app in RevenueCat dashboard
  /// 3. Get API keys for iOS and Android
  /// 4. Replace 'YOUR_REVENUECAT_API_KEY' below
  static Future<void> initialize() async {
    try {
      // RevenueCat API key (test store - will work for testing and production)
      const apiKey = 'test_oTigozkjqRghmKYtjukaUTMqLsC';
      
      await Purchases.configure(
        PurchasesConfiguration(apiKey),
      );
      
      print('✅ RevenueCat initialized');
      
      // Check subscription status on startup
      await checkSubscriptionStatus();
    } catch (e) {
      print('❌ RevenueCat initialization failed: $e');
      // App will work in offline mode without subscriptions
    }
  }
  
  /// Check if user is whitelisted (free access)
  static Future<bool> isWhitelisted() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      final email = user.email?.toLowerCase();
      if (email == null) return false;
      
      // Check hardcoded list first
      if (_freeAccessEmails.contains(email)) {
        print('✅ User $email is whitelisted (hardcoded)');
        return true;
      }
      
      // Check Firebase whitelist (dynamic - can update without app update)
      try {
        final doc = await _firestore
            .collection('whitelist')
            .doc(email)
            .get();
        
        if (doc.exists) {
          final data = doc.data();
          final isActive = data?['active'] == true;
          if (isActive) {
            print('✅ User $email is whitelisted (Firebase)');
          }
          return isActive;
        }
      } catch (e) {
        print('Error checking Firebase whitelist: $e');
      }
      
      return false;
    } catch (e) {
      print('Error checking whitelist: $e');
      return false;
    }
  }
  
  /// Check if user has active subscription
  static Future<bool> hasActiveSubscription() async {
    // FIRST: Check if user is whitelisted (free access)
    final whitelisted = await isWhitelisted();
    if (whitelisted) {
      print('✅ Free access granted (whitelisted)');
      return true;
    }
    
    // THEN: Check RevenueCat subscription
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      
      // Check if user has any active entitlement
      final hasAccess = customerInfo.entitlements.active['pro']?.isActive ?? false;
      
      // Cache the status locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_subscriptionStatusKey, hasAccess);
      
      if (hasAccess) {
        print('✅ Active subscription found');
      } else {
        print('❌ No active subscription');
      }
      
      return hasAccess;
    } catch (e) {
      print('Error checking subscription: $e');
      
      // Fall back to cached status if RevenueCat is unavailable
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_subscriptionStatusKey) ?? false;
    }
  }
  
  /// Check subscription status and cache it
  static Future<void> checkSubscriptionStatus() async {
    await hasActiveSubscription();
  }
  
  /// Purchase subscription
  static Future<bool> purchaseSubscription() async {
    try {
      // Get available offerings
      final offerings = await Purchases.getOfferings();
      
      if (offerings.current == null) {
        print('No offerings available');
        return false;
      }
      
      // Purchase the monthly subscription
      final package = offerings.current!.monthly;
      
      if (package == null) {
        print('Monthly package not available');
        return false;
      }
      
      final purchaseResult = await Purchases.purchasePackage(package);
      
      // Check if purchase was successful
      final hasAccess = purchaseResult.customerInfo.entitlements.active['pro']?.isActive ?? false;
      
      if (hasAccess) {
        print('✅ Subscription successful!');
        await checkSubscriptionStatus();
        return true;
      }
      
      return false;
    } catch (e) {
      print('Purchase error: $e');
      return false;
    }
  }
  
  /// Restore purchases (for users who already paid)
  static Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      final hasAccess = customerInfo.entitlements.active['pro']?.isActive ?? false;
      
      await checkSubscriptionStatus();
      
      return hasAccess;
    } catch (e) {
      print('Restore error: $e');
      return false;
    }
  }
  
  /// Get subscription details
  static Future<Map<String, dynamic>?> getSubscriptionDetails() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final entitlement = customerInfo.entitlements.active['pro'];
      
      if (entitlement == null || !entitlement.isActive) {
        return null;
      }
      
      return {
        'isActive': entitlement.isActive,
        'willRenew': entitlement.willRenew,
        'periodType': entitlement.periodType,
        'expirationDate': entitlement.expirationDate,
        'productIdentifier': entitlement.productIdentifier,
      };
    } catch (e) {
      print('Error getting subscription details: $e');
      return null;
    }
  }
  
  /// Cancel subscription (redirects to store)
  /// Note: This needs to be handled by opening store URLs manually
  static Future<void> manageSubscription() async {
    try {
      // User needs to manage subscriptions through App Store or Play Store
      // iOS: Settings → Apple ID → Subscriptions
      // Android: Play Store → Account → Payments & subscriptions
      print('To manage subscription, go to your App Store or Play Store settings');
    } catch (e) {
      print('Error managing subscription: $e');
    }
  }
}
