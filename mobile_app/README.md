# Mobile App

Flutter client for DayFi/Turbo.

## Run Locally

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:3001
```

If `API_BASE_URL` is omitted, the app uses the default production API URL.

## Requirements

- Flutter stable (3.x)
- iOS and/or Android toolchain configured
- Backend API running locally or reachable remotely

## Push Notifications

Configure Firebase for each platform:

- Android: add `google-services.json` to `android/app/`
- iOS: add `GoogleService-Info.plist` to `ios/Runner/`

## Biometric Auth

- iOS: ensure Face ID usage description exists in `ios/Runner/Info.plist`
- Android: ensure biometric permission is declared in `AndroidManifest.xml`
