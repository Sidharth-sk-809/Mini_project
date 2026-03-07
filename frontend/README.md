# Neamet - Flutter Mobile Application

Flutter mobile app for the Neamet grocery delivery platform.  
Connects to the live backend at **https://mini-project-8sdo.onrender.com**.

## Prerequisites

- Flutter SDK 3.0.0+
- Dart SDK 3.0.0+
- Android SDK (Android builds) / Xcode (iOS builds)

## Getting Started

```bash
cd frontend
flutter pub get
flutter run
```

The app targets the production Render backend by default (`lib/services/api_client.dart`).  
Change the base URL there to `http://localhost:8000` to use a local backend.

## Features

- **Home** — browse shops and product catalog, search products
- **Favourites** — heart button on each product card; list persisted with shared_preferences
- **Orders** — full order history with status badges; tap any order to track it
- **Account** — profile, login / signup via custom JWT auth

Delivery person view: available orders with 2-second polling, accept and advance status.

## Running the App

```bash
# Hot reload (development)
flutter run

# Specific device
flutter run -d <device_id>

# Release mode
flutter run --release
```

## Project Structure

```
lib/
  ├── constants/        # App-wide constants
  ├── models/           # Dart data models
  ├── screens/          # UI screens (home, login, order tracking…)
  ├── services/         # api_client.dart, order_service.dart, favorites_service.dart
  ├── widgets/          # Reusable widgets (product_card, etc.)
  └── main.dart
```

## Build

```bash
# Release APK (~57 MB)
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

# Debug APK
flutter build apk --debug

# iOS
flutter build ios --release

# Web
flutter build web --release
```

## Key Dependencies

| Package | Purpose |
|---|---|
| http | REST API calls |
| shared_preferences | Persisted favourites |
| google_fonts | Custom typography |
| firebase_core | Firebase SDK init |

See `pubspec.yaml` for the full list.

## Troubleshooting

```bash
flutter doctor          # check environment
flutter clean           # clear build cache
flutter pub get         # reinstall packages
flutter pub upgrade     # upgrade packages
```

## License

Part of the Neamet grocery delivery application.