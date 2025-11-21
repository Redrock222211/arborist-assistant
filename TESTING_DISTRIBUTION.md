# Arborist Assistant - Testing Distribution Guide

## Quick Test Builds

### Android Testing (Direct APK)

#### Option 1: Universal APK (All Devices)
```bash
# Build universal APK for testing
flutter build apk --release

# Location: build/app/outputs/flutter-apk/app-release.apk
# Size: ~50MB (larger but works on all devices)
```

#### Option 2: Split APKs (Smaller Size)
```bash
# Build split APKs by architecture
flutter build apk --release --split-per-abi

# Locations:
# ARM 32-bit: build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
# ARM 64-bit: build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
# x86 64-bit: build/app/outputs/flutter-apk/app-x86_64-release.apk
```

### iOS Testing (TestFlight)

```bash
# Build for iOS
flutter build ios --release

# Open in Xcode
open ios/Runner.xcworkspace

# In Xcode:
# 1. Select "Any iOS Device" as target
# 2. Product → Archive
# 3. Distribute App → App Store Connect → Upload
# 4. Use TestFlight for distribution
```

## Distribution Methods

### 1. Firebase App Distribution (Recommended)
- **Pros:** Easy setup, automatic updates, crash reporting
- **Supports:** Android APK, iOS (with setup)
- **Testers:** Up to 500 testers

Setup:
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize App Distribution
cd ~/arborist_assistant_test_build
firebase init appdistribution

# Upload Android APK
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
  --app 1:512062345870:android:3555f403e8d596f177afdf \
  --groups testers \
  --release-notes "Test build v1.0.0"
```

### 2. Direct APK Distribution (Android Only)
- **Pros:** Simple, no setup required
- **Method:** Email, Google Drive, Dropbox, etc.
- **Installation:** Enable "Install from Unknown Sources"

Steps for testers:
1. Download APK to Android device
2. Go to Settings → Security → Enable "Unknown Sources"
3. Open APK file to install
4. May need to allow Chrome/Files to install apps

### 3. TestFlight (iOS Only)
- **Pros:** Official Apple testing platform
- **Testers:** Up to 10,000 external testers
- **Duration:** 90 days per build

Setup:
1. Upload build to App Store Connect
2. Add tester emails in TestFlight
3. Testers receive email invitation
4. Install via TestFlight app

### 4. Google Play Console Internal Testing (Android)
- **Pros:** Play Store infrastructure, automatic updates
- **Testers:** Up to 100 internal testers

Setup:
```bash
# Build App Bundle
flutter build appbundle --release

# Upload to Play Console:
# 1. Create app in Google Play Console
# 2. Go to Testing → Internal testing
# 3. Create release and upload AAB
# 4. Add tester emails
```

## Quick Testing Links

### For Android Testers
Send this to testers with the APK:

```
How to Install Arborist Assistant (Android):

1. Download the APK file
2. Open Settings → Security
3. Enable "Install from Unknown Sources"
4. Open the downloaded APK
5. Tap "Install"
6. Open the app!

Note: You may see a security warning - this is normal for test apps.
```

### For iOS Testers
Send this after adding to TestFlight:

```
How to Install Arborist Assistant (iOS):

1. Download TestFlight from App Store
2. Check your email for TestFlight invitation
3. Tap "View in TestFlight"
4. Tap "Install"
5. Open the app!

TestFlight Link: [Will be provided after upload]
```

## Current Build Info

- **Package Name:** com.arboristsbynature.assistant
- **Version:** 1.0.0
- **Min Android:** 5.0 (API 21)
- **Min iOS:** 13.0

## Test Checklist

Before distributing:
- [ ] Test core features work
- [ ] Check Firebase connection
- [ ] Verify report generation
- [ ] Test on different screen sizes
- [ ] Check permissions (location, storage, camera)

## Support

For issues during testing:
- Android: Check if "Unknown Sources" is enabled
- iOS: Ensure TestFlight is installed
- Both: Try uninstalling and reinstalling
