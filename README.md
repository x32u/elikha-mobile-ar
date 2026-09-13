# e-Likha Mobile

e-Likha Mobile is the Flutter companion app for the e-Likha learning platform. It gives every platform role a secure mobile workspace while reusing the hosted web application for AR and administration tools.

## What the app provides

- **Students** can review assigned activities, attached rubrics, teacher-confirmed criterion results, scores, approved color suggestions, artwork, and durable notifications.
- **Students** can open Easy (color), Medium (puzzle), and Advanced (color + puzzle) practice modes with the same optional voice guide as the website.
- **Teachers** can manage active and disabled classes, enrollments, activities, rubric attachments, reviews, gesture alerts, reports, rubrics, and the shared 3D model library, including attributed Poly Pizza imports.
- **Parents** can follow linked students, progress, reviewed work, durable notifications, and notification settings.
- **Admins and super admins** can open their complete role-protected web workspaces from the mobile shell.
- **AR activities** open the hosted e-Likha experience in an authenticated in-app WebView on Android and iOS, or in the browser on other platforms.
- **Password recovery** uses a direct six-digit email code and no longer requires administrator approval.
- **Role-based access** uses Supabase Authentication and database profiles to route each user to the correct workspace.
- **Private profile and class images** are uploaded to Cloudflare R2 (PNG, JPG, or WebP up to 20 MB); Supabase stores only their `r2-media/...` references.

## Web parity architecture

Native Flutter screens cover everyday dashboards, activity building, teacher review, reporting, settings, flexible rubric management, and searchable 3D model-library management. AR rendering and gestures, voice guidance, Sandbox sessions, and administrator tools still open the trusted hosted origin inside the app. Blender files can be managed natively but remain source files until converted to `.glb` for AR.

The web app is loaded at runtime; it is not copied into the mobile binary.
Deploy the current `/Users/haru/Documents/Main/elikha_web` build before
testing mobile parity, then set `ELIKHA_WEB_URL` to that deployment. If this
still points at an older production bundle, hosted screens such as Sandbox,
rubrics, recovery, and model management will look outdated even though the
Flutter source is updated.

The mobile-to-web bridge:

- accepts only the exact HTTPS origin configured by `ELIKHA_WEB_URL`;
- rejects credentials in URLs and blocks navigation to other origins;
- transfers the current Supabase session through same-origin browser storage, never through query parameters;
- synchronizes refreshed credentials back to the native client before closing;
- grants only camera access on AR pages and denies microphone/other WebView permission requests;
- stops camera media, speech synthesis, and the temporary browser session during teardown.

## Tech stack

- Flutter and Dart
- Supabase Authentication and Postgres data APIs
- `webview_flutter` for mobile AR activities
- `permission_handler` for camera access
- `shared_preferences` for local session preferences

## Project structure

```text
lib/
├── main.dart                 # App startup, authentication, and role routing
├── mobile_database_app.dart  # Live student, teacher, and parent workspaces
├── ar_launcher*.dart         # Secure platform-specific hosted launch behavior
├── hosted_web_security.dart  # Origin, session, and download-bridge validation
└── roles/                    # Role UI components and earlier screen modules

assets/images/                # e-Likha brand assets
android/                      # Android platform project
ios/                          # iOS platform project
web/                          # Flutter web bootstrap
```

## Getting started

### Prerequisites

- Flutter SDK compatible with Dart `^3.11.5`
- Android Studio or Xcode for mobile builds
- A Supabase project with the e-Likha schema and Row Level Security policies
- The corresponding e-Likha web migrations and Edge Functions deployed
- A hosted Supabase recovery email template that displays `{{ .Token }}` as a six-digit code

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Configure Supabase

The repository does not contain backend credentials. Copy the example file and add your local publishable values:

```bash
cp config/example.json config/dev.json
```

Edit `config/dev.json`:

```json
{
  "SUPABASE_URL": "https://your-project.supabase.co",
  "SUPABASE_ANON_KEY": "your-publishable-anon-key",
  "ELIKHA_WEB_URL": "https://elikhaweb.vercel.app"
}
```

`ELIKHA_WEB_URL` may point to a reviewed HTTPS preview deployment while the
current web changes are being verified. Production builds should use the
current e-Likha production deployment.

For a reviewed preview, pass the URL explicitly:

```bash
flutter run -d <device-id> \
  --dart-define=ELIKHA_WEB_URL=https://your-current-web-deployment.example \
  --dart-define-from-file=config/dev.json
```

`config/dev.json` is ignored by Git. Never place a Supabase service-role key or another server-side secret in this mobile application.

### 3. Run the app

```bash
flutter run --dart-define-from-file=config/dev.json
```

Choose a device explicitly when needed:

```bash
flutter devices
flutter run -d <device-id> --dart-define-from-file=config/dev.json
```

For Chrome development, use one of the fixed origins allowed by the R2 Worker so
model and private-image requests are not blocked by browser CORS:

```bash
flutter run -d chrome --web-port 3000 --dart-define-from-file=config/dev.json
```

Port `56057` is also allowed for the mobile browser preview used by this project.

## Quality checks

```bash
dart format --output=none --set-exit-if-changed \
  lib/main.dart lib/mobile_database_app.dart lib/ar_launcher*.dart \
  lib/hosted_web_security.dart lib/roles/*/main.dart test
flutter analyze
flutter test
```

## Building

Pass the same local configuration file to release builds:

```bash
flutter build apk --release --dart-define-from-file=config/dev.json
flutter build ios --release --dart-define-from-file=config/dev.json
```

Android release signing is still configured with the Flutter development default. Configure a private signing key outside the repository before publishing to an app store.

## Permissions and privacy

- Camera access is requested only when a user opens an AR activity.
- Authentication tokens are managed by the Supabase Flutter client. The authenticated WebView bridge never places them in links, logs, or route parameters.
- Database access must be protected by Supabase Row Level Security; a publishable client key is not a substitute for authorization rules.
- Do not commit local configuration, signing keys, generated browser profiles, exported user data, or staff/student photographs.

## Security note

If a key has ever been committed, shared, or bundled unintentionally, remove it from the code and rotate it in the provider dashboard. Deleting the current file alone does not remove a credential from Git history.

## Related application

By default, the mobile AR flow opens the hosted e-Likha web experience at [elikhaweb.vercel.app](https://elikhaweb.vercel.app). A reviewed preview can be selected at build time with `ELIKHA_WEB_URL`.

See [MOBILE_PARITY.md](MOBILE_PARITY.md) for the current native/hosted feature map and required backend contracts.

## License

No open-source license has been added. All rights are reserved by the project owner.
