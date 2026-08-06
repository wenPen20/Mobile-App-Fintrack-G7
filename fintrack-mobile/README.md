# FinTrack Mobile

Flutter client for FinTrack. It covers onboarding and financial profile, the dashboard, transactions, budgets, and the AI financial assistant. All data comes from the FastAPI backend in [`fintrack-api`](../fintrack-api), so **the backend must be running before this app will get past the login screen**.

> **Setting up for the first time? Read the [root README](../README.md).** It covers prerequisites, the database, and the backend. This page covers Flutter client details only.

## Quick start

```bash
cd fintrack-mobile
flutter pub get
flutter run -d chrome     # or -d windows, or just `flutter run` for an emulator
```

Built and tested against Flutter 3.41.9 stable with Dart 3.11.5. `pubspec.yaml` requires Dart `^3.11.5`, so older Flutter versions will not resolve.

## Point the app at the backend first

The API base URL is hardcoded in **two** files, and both have to agree:

- [lib/core/services/api_service.dart:338](lib/core/services/api_service.dart#L338)
- [lib/features/auth/providers/auth_provider.dart:37](lib/features/auth/providers/auth_provider.dart#L37)

Both currently read `http://localhost:8000`. The correct value depends on the run target, because `localhost` resolves to the device the app is running on.

| Run target | Base URL |
|---|---|
| Chrome, Windows desktop, iOS simulator | `http://localhost:8000` |
| Android emulator | `http://10.0.2.2:8000` |
| Physical phone on the same Wi-Fi | `http://<computer-LAN-IP>:8000`, with the backend started using `--host 0.0.0.0` |

Editing only one of the two files produces the confusing symptom where login succeeds but no data loads, or the reverse.

## Architecture

- **State management:** Riverpod. `apiServiceProvider` watches `authProvider`, so the API client is rebuilt with a fresh token whenever auth state changes.
- **Routing:** go_router, with a redirect guard that holds unauthenticated users on the auth screens and routes users who have not finished onboarding into that flow.
- **Networking:** the `http` package, wrapped in `ApiService` and `AuthApiService`. The JWT is attached as `Authorization: Bearer <token>` on every authenticated call.
- **Persistence:** the backend is the source of truth for all financial data. `shared_preferences` is used only for local UI preferences, such as the user's category display order. The auth token is held in memory, so a full restart requires logging in again.

```
lib/
├── main.dart               Entry point, DevicePreview wrapper, ProviderScope
├── app.dart                MaterialApp.router and theme
├── core/
│   ├── constants/          app_colors, app_text_styles, category_visuals
│   ├── models/
│   ├── router/             go_router config and auth guard
│   ├── services/           api_service.dart, auth_api_service.dart
│   └── widgets/
├── features/               One folder per module, each holding
│   ├── ai_assistant/         screens / providers / models / widgets
│   ├── auth/
│   ├── budget/
│   ├── dashboard/
│   ├── onboarding/
│   ├── profile/
│   └── transactions/
└── shared/navigation/
```

`lib/core/constants/category_visuals.dart` is the translation layer between the data the backend stores (icon names such as `utensils`, hex strings such as `#D85A30`) and Flutter's `IconData` and `Color`. A category whose icon name is not in that map renders a generic fallback rather than crashing.

## Device preview

`main.dart` wraps the app in `DevicePreview` for all non-release builds, so on web and desktop the UI renders inside a phone frame. That is deliberate. It disappears in release builds.

## Tests

```bash
flutter test        # widget tests
flutter analyze     # lints from analysis_options.yaml
```

## Release builds

`android/app/src/main/AndroidManifest.xml` does not declare the INTERNET permission. Debug builds work because Flutter injects it through the debug manifest, but a release APK will have no network access until this is added to the main manifest:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```
