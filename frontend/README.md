# Neamet - Flutter Mobile Application

A modern Flutter-based mobile application for the Neamet grocery delivery platform. Features Material 3 design, Firebase authentication, and real-time updates.

## 📋 Prerequisites

- Flutter SDK 3.0.0 or higher
- Dart SDK 3.0.0 or higher  
- Android SDK (for Android development)
- Xcode (for iOS development)
- Firebase project setup

## 🚀 Getting Started

### Installation

1. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

2. **Configure Firebase (if needed):**
   - Place your `google-services.json` in `android/app/`
   - Place your `GoogleService-Info.plist` in `ios/Runner/`

### Running the App

```bash
# Run with Flutter development server (hot reload enabled)
flutter run

# Run on specific device
flutter run -d <device_id>

# Run on Android emulator
flutter run -d emulator-<number>

# Run on iOS simulator
flutter run -d iPhone

# Run on web
flutter run -d chrome

# Build and run release version
flutter run --release
```

## 📁 Project Structure

```
lib/
  ├── constants/       # App constants and configuration
  ├── models/          # Data models
  ├── screens/         # App screens/pages
  ├── services/        # API and external services
  ├── widgets/         # Reusable widgets
  └── main.dart        # App entry point
```

## 🔧 Build Commands

```bash
# Build for different platforms
flutter build web        # Web
flutter build apk        # Android APK
flutter build appbundle  # Android App Bundle
flutter build ios        # iOS

# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

## 📦 Dependencies

Key packages used in this project:
- **google_fonts** - Custom fonts
- **firebase_core** - Firebase initialization
- **firebase_auth** - Authentication
- **cloud_firestore** - Database
- **http** - HTTP requests
- **shared_preferences** - Local storage

See `pubspec.yaml` for complete list.

## 🔐 Environment Configuration

Configuration values are typically stored in constants files. Ensure API endpoints and Firebase configurations are properly set.

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run all tests
flutter test test/
```

## 🌐 API Integration

The app communicates with the FastAPI backend located in `../backend/`. Ensure the backend is running before testing API features.

Base API URL: Configure in your services based on environment (dev/prod).

## 🚢 Deployment

### Android
```bash
# Generate signing key
keytool -genkey -v -keystore release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Build release APK
flutter build apk --release
```

### iOS
```bash
# Build iOS app
flutter build ios --release

# For App Store submission, use Xcode
open ios/Runner.xcworkspace
```

### Web
```bash
# Build web for production
flutter build web --release

# Output will be in build/web/
```

## 📚 Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Flutter Cookbook](https://docs.flutter.dev/cookbook)
- [Material 3 Guidelines](https://m3.material.io/)
- [Firebase Documentation](https://firebase.google.com/docs)

## 🐛 Troubleshooting

### Flutter Doctor
```bash
flutter doctor
```

### Clear Cache
```bash
flutter clean
rm -rf pubspec.lock
flutter pub get
```

### Dependency Issues
```bash
flutter pub upgrade
```

## 📝 Contributing

Follow the Flutter style guide and ensure code is properly formatted:

```bash
flutter format lib/
flutter analyze
```

## 📄 License

Part of the Neamet grocery delivery application.