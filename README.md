# 🌳 Arborist Assistant

**Professional tree management and assessment application for arborists, tree consultants, and environmental professionals.**

[![Version](https://img.shields.io/badge/version-1.0.0-green.svg)](https://github.com/yourusername/arborist_assistant)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20Android%20%7C%20Web-blue.svg)](https://flutter.dev)

## 📱 Overview

Arborist Assistant is a comprehensive mobile and web application designed to streamline tree assessment, site management, and regulatory compliance for tree professionals in Victoria, Australia.

### ✨ Key Features

#### 🗺️ **Site Management**
- GPS-based site creation and location tracking
- Interactive maps with tree plotting
- Site-specific planning data integration
- Voice notes and photo documentation
- Custom site drawings and annotations

#### 🌲 **Comprehensive Tree Assessment**
- **20-group assessment system** with 190+ fields:
  - Basic tree data (species, DBH, height)
  - Health and structure assessment
  - VTA (Visual Tree Assessment)
  - QTRA (Quantified Tree Risk Assessment)
  - ISA risk assessment protocols
  - Protection zones (SRZ/NRZ calculations)
  - Tree valuation and ecological value
  - Management recommendations

#### 📋 **Victorian Planning Integration**
- **Real-time VICMAP Planning API** integration
- **76 Local Government Area (LGA) tree laws** verified database
- **54 planning overlay requirements** for tree protection
- Automatic permit requirement lookups
- Council-specific regulations and fees
- Processing timeframes and contact information

#### 📄 **Professional Reporting**
- **PDF exports** - Client-ready professional reports
- **Word exports** - Editable documentation
- **CSV exports** - Data analysis in Excel/Google Sheets
- Customizable export groups (20 assessment categories)
- ISA-compliant report formatting

#### 🔄 **Cloud Sync & Offline Support**
- **Firebase backend** - Secure cloud storage
- **Offline-first architecture** - Works without internet
- **Hive local database** - Lightning-fast access
- **Multi-device sync** - Access data anywhere
- Automatic background synchronization

#### 🤖 **AI-Powered Insights**
- Gemini AI integration for planning summaries
- Intelligent permit requirement explanations
- Context-aware regulatory guidance

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.8.1 or higher
- Dart SDK ^3.8.1
- Firebase project (for authentication and cloud sync)
- Gemini API key (for AI features)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/arborist_assistant.git
   cd arborist_assistant
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   - Add your iOS and Android apps to the Firebase project
   - Download and place configuration files:
     - `google-services.json` → `android/app/`
     - `GoogleService-Info.plist` → `ios/Runner/`
   - Run: `flutter pub run flutter_app_name:init`

4. **Add API Keys**
   - Create `lib/config/api_keys.dart`:
     ```dart
     class ApiKeys {
       static const String geminiApiKey = 'YOUR_GEMINI_API_KEY';
     }
     ```

5. **Generate app icons**
   ```bash
   flutter pub run flutter_launcher_icons
   ```

6. **Run the app**
   ```bash
   flutter run
   ```

---

## 🏗️ Architecture

```
lib/
├── models/          # Data models (Site, TreeEntry, User, etc.)
├── services/        # Business logic (32 services)
│   ├── auth_service.dart
│   ├── site_storage_service.dart
│   ├── tree_storage_service.dart
│   ├── vicplan_service.dart
│   ├── regulatory_data_service.dart
│   └── planning_ai_service.dart
├── pages/           # UI screens
├── widgets/         # Reusable components
└── data/            # Static data (overlays, tree laws)
```

### Tech Stack

- **Framework**: Flutter 3.8.1
- **State Management**: StatefulWidget + setState
- **Local Database**: Hive (offline-first)
- **Cloud Backend**: Firebase (Auth, Firestore, Storage)
- **Maps**: flutter_map + OpenStreetMap
- **PDF Generation**: pdf + printing packages
- **AI**: Google Generative AI (Gemini)

---

## 📊 Data Sources

- **VICMAP Planning API**: Victorian Government spatial data
- **LGA Tree Laws**: Manually verified council regulations (76 councils)
- **Planning Overlays**: Environmental and heritage overlay requirements (54 overlays)
- **Real-time geocoding**: Address to coordinates conversion

---

## 🛡️ Privacy & Security

- **End-to-end encryption** for cloud-synced data
- **User authentication** via Firebase Auth
- **Data isolation** - Each user's data is private
- **Offline capability** - Data stored locally encrypted
- **GDPR compliant** - User data deletion supported

See our [Privacy Policy](PRIVACY_POLICY.md) for details.

---

## 📖 Documentation

- [User Guide](docs/USER_GUIDE.md)
- [API Documentation](docs/API.md)
- [Firebase Setup](docs/FIREBASE_SETUP.md)
- [Contributing Guide](CONTRIBUTING.md)

---

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- Victorian Government for VICMAP Planning data
- Local councils for regulatory information
- Flutter and Firebase teams
- ISA and QTRA for assessment protocols

---

## 📧 Support

- **Email**: support@arboristassistant.com
- **Website**: https://arboristassistant.com
- **Issues**: [GitHub Issues](https://github.com/yourusername/arborist_assistant/issues)

---

## 🗺️ Roadmap

- [ ] iOS App Store launch
- [ ] Google Play Store launch
- [ ] Advanced analytics dashboard
- [ ] Team collaboration features
- [ ] Interstate planning data (NSW, QLD)
- [ ] Dark mode
- [ ] Offline map tiles

---

**Made with ❤️ for arborists by arborists**
