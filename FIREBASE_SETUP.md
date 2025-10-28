# Firebase Setup Guide for Arborist Assistant

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Enter project name: `arborist-assistant` (or your preferred name)
4. Enable Google Analytics (optional)
5. Click "Create project"

## Step 2: Enable Authentication

1. In Firebase Console, go to "Authentication" → "Sign-in method"
2. Enable "Email/Password" authentication
3. Click "Save"

## Step 3: Create Firestore Database

1. Go to "Firestore Database" → "Create database"
2. Choose "Start in test mode" (for development)
3. Select a location close to your users
4. Click "Done"

## Step 4: Enable Storage

1. Go to "Storage" → "Get started"
2. Choose "Start in test mode" (for development)
3. Select a location close to your users
4. Click "Done"

## Step 5: Get Configuration

1. Go to Project Settings (gear icon)
2. Scroll down to "Your apps"
3. Click "Add app" → "Web"
4. Enter app nickname: `arborist-assistant-web`
5. Copy the configuration object

## Step 6: Update Configuration Files

### Update `lib/firebase_options.dart`:
```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'YOUR_ACTUAL_API_KEY',
  appId: 'YOUR_ACTUAL_APP_ID',
  messagingSenderId: 'YOUR_ACTUAL_SENDER_ID',
  projectId: 'YOUR_ACTUAL_PROJECT_ID',
  authDomain: 'YOUR_ACTUAL_PROJECT_ID.firebaseapp.com',
  storageBucket: 'YOUR_ACTUAL_PROJECT_ID.appspot.com',
  measurementId: 'YOUR_ACTUAL_MEASUREMENT_ID',
);
```

### Update `web/firebase-config.js`:
```javascript
const firebaseConfig = {
  apiKey: "YOUR_ACTUAL_API_KEY",
  authDomain: "YOUR_ACTUAL_PROJECT_ID.firebaseapp.com",
  projectId: "YOUR_ACTUAL_PROJECT_ID",
  storageBucket: "YOUR_ACTUAL_PROJECT_ID.appspot.com",
  messagingSenderId: "YOUR_ACTUAL_SENDER_ID",
  appId: "YOUR_ACTUAL_APP_ID",
  measurementId: "YOUR_ACTUAL_MEASUREMENT_ID"
};
```

## Step 7: Security Rules (Optional)

### Firestore Rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /sites/{siteId} {
      allow read, write: if request.auth != null;
    }
    match /trees/{treeId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### Storage Rules:
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Step 8: Test the App

1. Run `flutter pub get`
2. Run `flutter run -d chrome`
3. The app should now connect to Firebase!

## Features Enabled

✅ **User Authentication** - Email/password login
✅ **Data Sync** - Sites and trees sync to Firestore
✅ **File Storage** - Images and voice notes stored in Firebase Storage
✅ **Offline Support** - Data stored locally, syncs when online
✅ **Real-time Updates** - Changes sync across devices

## Next Steps

1. **Customize Authentication** - Add password reset, user registration
2. **Data Validation** - Add Firestore security rules
3. **User Management** - Add user roles and permissions
4. **Backup & Restore** - Implement data backup strategies
5. **Analytics** - Track app usage and performance

## Troubleshooting

- **"Firebase not initialized"** - Check your configuration values
- **"Permission denied"** - Check Firestore security rules
- **"Storage access denied"** - Check Storage security rules
- **"Authentication failed"** - Verify email/password authentication is enabled
