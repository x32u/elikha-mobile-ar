# e-Likha mobile parity map

This app intentionally combines native Flutter workflows with authenticated hosted web workflows. That keeps a single implementation of the camera-heavy AR engine and the security-sensitive administrator tools while still providing fast native dashboards.

The hosted web app is not bundled into the Flutter binary. Deploy the current
`elikha_web` build first, then set `ELIKHA_WEB_URL` to that HTTPS deployment
when running or building mobile. A build that uses an older production URL
will still show the older web UI even when the Flutter source is current. For
example:

```bash
flutter run -d <device-id> \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-publishable-anon-key \
  --dart-define=ELIKHA_WEB_URL=https://your-current-web-deployment.example
```

Never put access or refresh tokens in `ELIKHA_WEB_URL` or any route query
parameter. The native bridge transfers the authenticated session through
same-origin browser storage.

| Web capability | Mobile implementation |
| --- | --- |
| Student activities, class identity, submissions, scores, artwork | Native Flutter |
| Attached rubric before starting | Native Flutter via `get_student_activity_assessment` |
| Teacher-confirmed rubric result, notes, next steps, approved color suggestion | Native Flutter via the sanitized assessment RPC |
| Camera preparation and permission guide | Native prompt plus hosted preflight |
| AR gestures, paint, puzzles, undo/redo, duplicate, snap, object/model lock | Authenticated hosted AR |
| Optional voice instructions and action announcements | Authenticated hosted AR/Sandbox |
| Easy color, Medium puzzle, Advanced color + puzzle practice | Authenticated hosted Sandbox |
| Class enrollment, disable/restore | Native Flutter; classes are never permanently deleted |
| Class create/edit, flexible grade levels, colors, and class images | Native Flutter; private class images use authenticated Cloudflare R2 storage |
| Teacher student directory and learner progress details | Native Flutter, including private R2 profile pictures |
| Full activity create/edit, custom color picker, model selection, and rubric attachment | Native Flutter backed by atomic RPCs |
| Teacher activity overview | Native Flutter bottom sheet shared by the activity list and class detail flow |
| Teacher rubric/AI review confirmation | Native Flutter via `finalize_submission_review(...)` |
| Durable in-app notifications/read state | Native Flutter using `notifications` |
| Notification preferences, AR guidance, media quality, and email settings | Native Flutter |
| Profile picture upload/remove | Native Flutter for signed-in users; PNG/JPG/WebP up to 20 MB in private Cloudflare R2 storage |
| Teacher reports and evidence-based student insights | Native Flutter |
| Teacher 3D model-library browsing, upload/edit/removal, and Poly Pizza search/import | Native Flutter with authenticated R2 operations and bundled offline fallback |
| Teacher rubric-library create/copy/delete and activity attachment | Native Flutter using the protected rubric contracts |
| Admin and super-admin workspaces | Authenticated hosted role workspaces |
| Six-digit recovery-code password reset | Native Flutter with Supabase Auth |

## Audited differences from the web app

- The camera-heavy AR activity and Sandbox remain hosted intentionally; all
  surrounding learner and teacher navigation is native.
- Admin and super-admin still open their authenticated web workspaces. Their
  account management, audit trail, storage administration, and platform-wide
  analytics have not been duplicated in Flutter.
- The native teacher reports show the core metrics and student insights but do
  not yet provide the web report's CSV/Excel export or period/class filters.
- The native teacher student directory does not yet provide the web directory's
  grade export or grade/section/sort filter row.
- Notification lists and read state are native; an individual notification may
  still open its authenticated web destination when no equivalent native route
  is registered.
- Activity thumbnails remain in the existing activity-thumbnail storage flow;
  only profile pictures and class images were moved to private R2 media routes.

## Required backend contracts

The mobile client expects the same deployed Supabase contracts as the web app:

- `create_activity_with_assignments(...)`
- `update_activity_with_rubric(...)`
- `get_activity_rubric_options(p_teacher_id)`
- `get_activity_rubric_management_state(p_activity_id)`
- `get_student_activity_assessment(p_activity_id)`
- `refresh_my_activity_reminders()`
- `get_teacher_gesture_alerts(p_teacher_id)`
- `activity_lock_alerts` with assignment-bound student insert and teacher-owner read policies
- strict RLS for classes, assignments, submissions, rubrics, notifications, and parent links

Teacher finalization is native, while scores, rubric observations, criterion evidence, and approved AI suggestions are still written atomically through `finalize_submission_review(...)`. The native app does not directly update protected submission review fields.

Profile and class image bytes are not read from Supabase Storage. Supabase stores
only the deterministic `r2-media/...` reference while the signed-in mobile app
loads the private bytes from the R2 Worker with its current Supabase access token.

Before release, apply `20260814011500_harden_behavior_alert_access.sql`. It closes anonymous gesture-alert access and creates/secures the lock-alert table used by the hosted AR workspace.

After deploying the web build, open the configured `ELIKHA_WEB_URL` in a
browser and confirm it contains the current Sandbox voice guide, six-digit
password recovery, rubric assessment, model-lock, and `.blend` upload flows
before producing the mobile APK/IPA. This prevents a stale hosted bundle from
being mistaken for a Flutter regression.

## Release checks

Run before shipping:

```bash
dart format --output=none --set-exit-if-changed \
  lib/main.dart lib/mobile_database_app.dart lib/ar_launcher*.dart \
  lib/hosted_web_security.dart lib/roles/*/main.dart test
flutter analyze
flutter test
flutter build apk --release --dart-define-from-file=config/dev.json
flutter build ios --release --no-codesign --dart-define-from-file=config/dev.json
```

Then smoke-test on physical Android and iOS devices:

1. Sign in as each supported role.
2. Complete the six-digit recovery-code flow using a controlled email account.
3. Open Sandbox at each difficulty and toggle Voice Guide.
4. Open an assigned AR activity, grant camera permission, submit, and reopen read-only.
5. Confirm a teacher rubric review and verify the learner sees only the final teacher-approved result.
6. Disable and restore a class; confirm its data remains and students no longer see active work while disabled.
7. Open teacher reports, rubrics, and the 3D model library; verify rubric create/copy/attach/delete protection, custom model add/edit/remove, and that `.blend` is labeled as a source file.
