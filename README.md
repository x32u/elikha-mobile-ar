# e-Likha Mobile

e-Likha Mobile is the Flutter companion app for the e-Likha learning platform. It gives students, teachers, and parents a role-specific view of classroom activity while connecting supported projects to the hosted AR experience.

## What the app provides

- **Students** can review assigned activities, submissions, scores, artwork, and notifications.
- **Teachers** can manage classes, activities, reviews, enrollments, and gesture alerts.
- **Parents** can follow linked students, progress, projects, and account settings.
- **AR activities** open the hosted e-Likha experience in an in-app WebView on Android and iOS, or in the browser on other platforms.
- **Role-based access** uses Supabase Authentication and database profiles to route each user to the correct workspace.

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
├── ar_launcher*.dart         # Platform-specific AR launch behavior
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
  "SUPABASE_ANON_KEY": "your-publishable-anon-key"
}
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

## Quality checks

```bash
dart format --output=none --set-exit-if-changed lib test
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
- Authentication tokens are managed by the Supabase Flutter client.
- Database access must be protected by Supabase Row Level Security; a publishable client key is not a substitute for authorization rules.
- Do not commit local configuration, signing keys, generated browser profiles, exported user data, or staff/student photographs.

## Security note

If a key has ever been committed, shared, or bundled unintentionally, remove it from the code and rotate it in the provider dashboard. Deleting the current file alone does not remove a credential from Git history.

## Related application

The mobile AR flow opens the hosted e-Likha web experience at [elikhaweb.vercel.app](https://elikhaweb.vercel.app).

## License

No open-source license has been added. All rights are reserved by the project owner.
