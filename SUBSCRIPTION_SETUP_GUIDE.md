# 💰 Subscription Setup Guide

## Monthly Subscription: $50 AUD/month

This guide walks you through setting up subscriptions for your app using RevenueCat.

---

## 🎯 Overview

Your app now has a **$50/month subscription** that gives users access to:
- ✅ Unlimited sites
- ✅ All 20 assessment groups
- ✅ PDF, Word, CSV exports
- ✅ Cloud backup & sync
- ✅ 76 LGA tree laws
- ✅ Permit requirement lookup
- ✅ Priority support

---

## 📋 Setup Steps

### Step 1: Sign Up for RevenueCat (FREE)

1. Go to: **https://www.revenuecat.com**
2. Click **"Get Started Free"**
3. Create account (use `hello@arboristsbynature.com.au`)
4. **Free up to $2,500/month revenue!**

---

### Step 2: Create Your App in RevenueCat

1. Log into RevenueCat dashboard
2. Click **"+ New App"**
3. Enter app name: **"Arborist Assistant"**
4. Select platforms: **iOS** and **Android**

---

### Step 3: Get Apple App Store Connect Info

**For iOS subscriptions:**

1. Log into **App Store Connect**: https://appstoreconnect.apple.com
2. Go to **My Apps** → Click your app
3. Go to **Features** → **Subscriptions**
4. Click **"+"** to create subscription group
5. Name: **"Arborist Assistant Pro"**
6. Click **"+"** to add subscription
7. Fill in:
   - **Product ID**: `com.arboristsbynature.monthly`
   - **Subscription Duration**: 1 Month
   - **Price**: $50 AUD/month
8. Add description: **"Professional tree management unlimited access"**
9. Click **Save**
10. Copy the **Product ID** and **Shared Secret** from App Store Connect

---

### Step 4: Configure iOS in RevenueCat

1. In RevenueCat dashboard, go to your app
2. Click **iOS** tab
3. Enter:
   - **Bundle ID**: `com.example.arboristAssistant` (or your actual bundle ID)
   - **App Store Connect Shared Secret**: (paste from Step 3)
4. Click **Save**

---

### Step 5: Setup Google Play Console

**For Android subscriptions:**

1. Log into **Google Play Console**: https://play.google.com/console
2. Select your app
3. Go to **Monetize** → **Products** → **Subscriptions**
4. Click **Create subscription**
5. Fill in:
   - **Product ID**: `monthly_subscription`
   - **Name**: Arborist Assistant Pro
   - **Description**: Professional tree management unlimited access
   - **Billing period**: Monthly
   - **Price**: $50 AUD
6. Click **Save** and **Activate**
7. Copy the **Product ID**

---

### Step 6: Configure Android in RevenueCat

1. In RevenueCat dashboard, go to your app
2. Click **Android** tab
3. Enter:
   - **Package name**: `com.example.arborist_assistant`
4. Follow RevenueCat's guide to link Google Play Console
5. Click **Save**

---

### Step 7: Create Offering in RevenueCat

1. In RevenueCat dashboard, go to **Offerings**
2. Click **"+ New Offering"**
3. Name: **"Default"**
4. Add a package:
   - Package identifier: **"monthly"**
   - iOS Product ID: `com.arboristsbynature.monthly`
   - Android Product ID: `monthly_subscription`
5. Click **Save**

---

### Step 8: Create Entitlement

1. In RevenueCat, go to **Entitlements**
2. Click **"+ New Entitlement"**
3. Enter identifier: **"pro"**
4. Click **Save**
5. Link this entitlement to your "monthly" package

---

### Step 9: Get RevenueCat API Keys

1. In RevenueCat dashboard, go to **API Keys**
2. You'll see:
   - **Apple App Store** key
   - **Google Play Store** key
3. **For iOS apps**, copy the **Apple App Store** key
4. **For Android apps**, copy the **Google Play Store** key

---

### Step 10: Add API Key to Your App

1. Open: `lib/services/subscription_service.dart`
2. Find line: `const apiKey = 'YOUR_REVENUECAT_API_KEY';`
3. Replace with your actual key:
   ```dart
   // iOS
   const apiKey = 'appl_xxxxxxxxxxxxxxxxx';
   
   // OR for cross-platform, use platform-specific keys:
   import 'dart:io';
   final apiKey = Platform.isIOS 
       ? 'appl_xxxxxxxxxxxxxxxxx'  // iOS key
       : 'goog_xxxxxxxxxxxxxxxxx';  // Android key
   ```

---

## 🧪 Step 11: Test Subscriptions

### iOS Testing (Sandbox):

1. In App Store Connect, create a **Sandbox Tester**:
   - Go to **Users and Access** → **Sandbox Testers**
   - Click **"+"**
   - Create test Apple ID
2. On your iPhone:
   - Settings → App Store → Sandbox Account
   - Sign in with test account
3. Run your app
4. Try subscribing (won't charge real money!)

### Android Testing:

1. In Play Console, add yourself as a **License Tester**
2. Go to **Testing** → **License testing**
3. Add your Gmail address
4. Run app and test subscription

---

## 💰 Revenue Flow

### How You Get Paid:

1. **User subscribes** → $50/month charged
2. **Apple/Google takes 30%** (first year) = $15
3. **You receive 70%** = **$35/month per user**
4. **After 1 year, commission drops to 15%** = **$42.50/month per user**

### RevenueCat Fees:

- **FREE** for first $2,500/month revenue
- **1% fee** on revenue above $2,500/month

### Example Revenue:

- **10 users**: 10 × $35 = **$350/month** (RevenueCat FREE)
- **100 users**: 100 × $35 = **$3,500/month** (RevenueCat: $10/month)
- **500 users**: 500 × $35 = **$17,500/month** (RevenueCat: $150/month)

---

## 🔒 Where Subscription Checks Are Used

The subscription is checked before these premium features:

1. **Creating more than 3 sites** (free limit)
2. **Exporting to PDF/Word/CSV**
3. **Using all 20 assessment groups** (free users get basic 5)
4. **Cloud sync** (free users local only)

To add more restrictions, use:

```dart
import '../services/subscription_service.dart';
import '../pages/paywall_page.dart';

// Check subscription before premium feature
final hasSubscription = await SubscriptionService.hasActiveSubscription();

if (!hasSubscription) {
  // Show paywall
  final subscribed = await Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const PaywallPage()),
  );
  
  if (subscribed != true) {
    return; // User didn't subscribe
  }
}

// Allow premium feature
doSomethingPremium();
```

---

## 📱 Managing Subscriptions

Users can manage (cancel/change) their subscription through:

**iOS:**
- Settings → Apple ID → Subscriptions

**Android:**
- Play Store → Account → Payments & subscriptions → Subscriptions

Or in your app, call:
```dart
await SubscriptionService.manageSubscription();
```

---

## ✅ Checklist Before Launch

- [ ] RevenueCat account created
- [ ] App created in RevenueCat
- [ ] iOS subscription created in App Store Connect ($50/month)
- [ ] Android subscription created in Play Console ($50/month)
- [ ] Offering created in RevenueCat
- [ ] Entitlement "pro" created
- [ ] API key added to app code
- [ ] Tested with sandbox account (iOS)
- [ ] Tested with license tester (Android)
- [ ] Privacy policy mentions subscriptions
- [ ] App store listings mention subscription price

---

## 🆘 Troubleshooting

### "No offerings available"
- Check RevenueCat dashboard: Offerings → Default → Make sure it's set as "current"
- Verify products are linked correctly

### "Purchase failed"
- iOS: Make sure signed into Sandbox account in Settings
- Android: Make sure you're a license tester
- Check RevenueCat dashboard for errors

### "Restore didn't work"
- Make sure using same Apple ID / Google account as original purchase
- Check RevenueCat dashboard → Customers to see if purchase recorded

---

## 📧 Support

**RevenueCat Support:** https://www.revenuecat.com/support
**Documentation:** https://docs.revenuecat.com

---

**You're all set! Users can now subscribe for $50/month!** 🎉
