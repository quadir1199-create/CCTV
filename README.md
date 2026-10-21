# CameraCare

Flutter Android/iOS customer app for CCTV after-sales complaints. Inspired by the service workflow of CP Plus Intelli Serve; uses original branding and UI.

## Implemented

- Firebase email/password signup and login, password reset, Google account sign-in, and Sign in with Apple. Signup asks for full name, email, password, and confirmation; no phone OTP is required.
- Submit product model, serial number, issue description and installation address.
- Watch customer-owned complaints and their current progress in real time.
- Status progression: submitted → assigned → in progress → resolved.
- Dedicated Home, filtered Requests, Help/FAQ, and Account tabs.
- Social account profiles use provider name/email, including Apple private relay addresses. Missing details are requested after authentication.
- Loading, empty, failure and retry states; form validation; duplicate submission prevention.
- Demo backend with sample data (memory only, resets on restart).
- Firestore rules restrict reads to owners and prevent client-side status or ownership changes.

## Run with Firebase

From this directory:

```sh
flutter pub get
flutter run
```

Firebase is the default backend. This app is connected to Firebase project `studio-6884643544-d4d8a`; FlutterFire configuration is in `lib/firebase_options.dart`, `android/app/google-services.json`, and `ios/Runner/GoogleService-Info.plist`. The standard Firestore database is in Doha (`me-central1`), and `firestore.rules` has been deployed. Android and iOS app registrations currently use `com.example.cctv_service` and `com.example.cctvService`; update these identifiers and rerun `flutterfire configure` before release if you choose different ones.

To run the local demo instead:

```sh
flutter run --dart-define=DEMO_MODE=true
```

In demo mode, create an account with any valid email and an 8-character-or-longer password. Demo accounts last only for the current session. Google and Apple buttons use clearly identified synthetic demo accounts in this mode; they do not open real account pickers.

## Authentication provider setup

Email/password is enabled in this Firebase project. Live Firebase email signup, password login, profile saving without a phone claim, and owner isolation have been checked with a temporary account, which was removed afterward. Email/password login does not use SMS or require SMS billing.

Google's native sign-in flow is implemented with `google_sign_in`. Google is not yet configured in this project's Firebase provider settings, and the downloaded SDK configuration currently has no Google OAuth client IDs. Complete these steps before testing Google:

1. Firebase Console > Authentication > Sign-in method > Google: enable it, select the support email, and save. This generates the required OAuth clients.
2. Download updated `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist` from Project settings. Run `flutterfire configure --project=studio-6884643544-d4d8a` to refresh `lib/firebase_options.dart`, including `iosClientId`.
3. For iOS, add the new plist's `REVERSED_CLIENT_ID` under `CFBundleURLTypes` > `CFBundleURLSchemes` in `ios/Runner/Info.plist`. Do not invent a client ID or scheme. Both Android debug signing fingerprints are already registered; add release/Play signing fingerprints before release.
4. Rebuild the app fully after replacing native configuration.

Apple's Firebase provider is enabled for iOS bundle `com.example.cctvService`. `Runner/Runner.entitlements` and all Runner build configurations include Sign in with Apple. Register the bundle with your Apple Developer team, enable Sign in with Apple for that App ID, and regenerate the provisioning profile before testing on iOS. For Android, configure an Apple Service ID and OAuth code flow (Team ID, Key ID, and private key) in Firebase's Apple provider. The return URL is `https://studio-6884643544-d4d8a.firebaseapp.com/__/auth/handler`. Keep the Apple private key in Firebase's provider settings, never in the app or source repository. Full social account sign-in cannot be verified until these external provider configurations are complete.

Existing customer profiles and complaint ownership continue to use Firebase UID. Existing phone-only users are not automatically merged with new email or social accounts; migrate/link those accounts deliberately if needed. Phone authentication is no longer exposed in the app, but existing backend Phone provider settings were retained to avoid locking out old identities during migration.

To register another Firebase project, follow https://firebase.google.com/docs/flutter/setup, run `flutterfire configure`, then deploy rules with `firebase deploy --only firestore:rules --project YOUR_PROJECT_ID`.

Minimum platform targets: Android uses the installed Flutter SDK default (API 24 here), iOS 15. Firebase setup and device builds must be verified with your project and signing configuration.

## Architecture

```text
lib/
  core/providers.dart                       composition and Riverpod state
  features/auth/
    domain/auth_repository.dart              user entity and repository contract
    data/firebase_auth_repository.dart       Firebase adapter
    presentation/sign_in_screen.dart         email/social sign-in, signup and profile setup
    domain/customer_profile.dart             customer profile contract
    data/firebase_customer_profile_repository.dart  Firestore profile adapter
  features/complaints/
    domain/complaint.dart                     entities, contract and submit use case
    data/firebase_complaint_repository.dart   Firestore mapping
    data/demo_complaint_repository.dart       local demo adapter
    presentation/service_app.dart            customer screens
```

Domain imports no Flutter, Riverpod or Firebase. Presentation consumes providers and domain objects. Data owns SDK calls and document mapping. Riverpod uses ProviderScope, StreamProvider and AsyncNotifierProvider without code generation. `SubmitComplaint` owns business validation. Form validation also provides immediate user feedback.

To migrate to your server, implement `AuthRepository` and `ComplaintRepository` in new API adapters, then change the bindings in `core/providers.dart`. Keep domain contracts and screens unchanged. The server must validate payloads, enforce per-user access, and own status transitions. Stream adapters can use polling, WebSockets or server-sent events. Adopt a stable timestamp and status contract; do not expose Firebase document types to domain code.

## Service operations

Customer clients cannot change status. A trusted backend using Firebase Admin SDK must authenticate and authorize staff before updating complaints. This starter contains no technician/admin application or backend status endpoint. The UI progress view derives from current status; it is not a timestamped event history. Add an append-only status event collection when implementing staff operations.

## Build and verification

```sh
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --simulator
```

Static analysis, authentication regression tests, and the Android Firebase debug build are verified. Social provider sign-in requires the configuration above; iOS builds also require a current CocoaPods installation and signing configuration.

## Next product milestones

Photo attachments with Firebase Storage and ownership/size/type rules; email verification; staff assignment and audited status transitions; push notifications; warranty/RMA details; search and pagination; localization; account deletion and retention workflow. Release work also requires final branding, signing, privacy disclosures, Firebase App Check, monitoring and CI. This is a working customer starter, not a published production service.

## Local build results

The iOS simulator build is currently blocked by installed CocoaPods 1.11.2; FirebaseAuth requires at least 1.12.0 and Flutter recommends 1.16.2+. Updating pod specifications confirmed the version requirement. Upgrade CocoaPods to at least 1.12.0 (Flutter recommends 1.16.2), then run `pod install --repo-update` in `ios` and retry the simulator build.

Android debug APK built successfully and the demo app was launched on the Pixel XL API 33 emulator. APK: `build/app/outputs/flutter-apk/app-debug.apk`.

Android native configuration uses Kotlin Gradle plugin 2.3.10 to match Firebase Auth Kotlin metadata and the modern `compilerOptions` DSL for JVM target 11.
