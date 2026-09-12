# DocAppoint Frontend

Flutter mobile app for a doctor appointment booking and management system. The app supports patient and doctor workflows, secure authentication, appointment booking, and profile-based management.

## Overview

This project is the frontend for the DocAppoint platform. It connects to a Java/Spring backend API and provides:

- Patient registration and login
- Doctor registration and login
- Appointment slot browsing and booking
- Doctor schedule management
- Appointment status tracking
- Secure token-based authentication using Flutter Secure Storage
- Role-based UI flow for patients and doctors

## Tech Stack

- Flutter
- Dart
- Riverpod for state management
- HTTP client for API calls
- Shared Preferences for local app data
- Flutter Secure Storage for auth tokens

## Project Structure

```text
lib/
  config/
    app_config.dart
  models/
  providers/
  screens/
    common/
    doctor/
    patient/
  services/
    api_service.dart
    auth_service.dart
  theme/
  widgets/
  main.dart
assets/
  icons/
android/
ios/
linux/
macos/
windows/
web/
test/
```

## Backend Configuration

The app is configured to use a default backend URL in `lib/config/app_config.dart`.

By default, it points to the Railway deployment:

```dart
https://docappointjava-production.up.railway.app
```

You can override this at build/run time with:

```bash
flutter run --dart-define=API_BASE_URL=https://your-backend-url
```

or by changing the value in `AppConfig.baseUrl` if needed for local development.

## Prerequisites

Before running this project, make sure you have:

- Flutter SDK installed
- Android Studio or VS Code with Flutter extensions
- An emulator or physical device connected
- A running backend API

Check your Flutter environment:

```bash
flutter --version
flutter doctor
```

## Setup

1. Clone the repository.
2. Change into the project folder.
3. Install dependencies:

```bash
flutter pub get
```

## Run the App

For Android or emulator:

```bash
flutter run
```

To point to a specific backend URL:

```bash
flutter run --dart-define=API_BASE_URL=https://docappointjava-production.up.railway.app
```

## Build

Android APK:

```bash
flutter build apk
```

Android App Bundle:

```bash
flutter build appbundle
```

## Testing

Run tests with:

```bash
flutter test
```

## Notes

- Authentication tokens are stored securely using `flutter_secure_storage`.
- API requests are centralized in `lib/services`.
- The app uses role-aware navigation to send patients and doctors to different screens after login.

## Related Backend

This frontend expects a matching backend service exposing endpoints for:

- login
- register
- register/doctor
- auth/refresh
- appointments
- doctor slots
- profile-related APIs
