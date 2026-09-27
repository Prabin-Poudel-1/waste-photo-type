# Phase 4: tourist accounts and report tracking

Implemented email/password registration and login, BCrypt hashing, seven-day JWTs,
secure mobile session persistence, logout, owned-report listing/details and existing
status-history display. Original and any existing AFTER_CLEANUP photos are supported.
No department workflow or Phase 5 functionality was added.

## Run

The local JWT secret is already configured on this machine. For another checkout:

```sh
sh backend/scripts/init-auth.sh
cd backend
./mvnw spring-boot:run
```

Start the existing Docker PostgreSQL service first using the existing setup. Restart
an older running backend to load Phase 4. Start Maven from `backend` so its ignored
`auth-local.properties` is loaded. Alternatively configure `JWT_SECRET` in the backend
run environment: a base64-encoded random secret of at least 32 bytes. Keep it stable
across restarts; changing it invalidates sessions. Never commit the secret file.

From `mobile`, run `flutter pub get`, then fully restart the Android app using Run.
The new secure-storage native plugin needs a fresh run, not just hot reload.
Android emulator API URL remains http://10.0.2.2:8081; override with
`--dart-define=API_BASE_URL=http://YOUR_MAC_LAN_IP:8081` for a physical phone.

## APIs

- POST /api/v1/auth/register: name, email, password
- POST /api/v1/auth/login: email, password
- GET /api/v1/reports/mine?page=0&size=20
- Existing report creation, detail and image routes now require a bearer JWT.
- Tourist access to details/images requires report ownership. The global report list
  requires ADMIN. Old reports with no reporter remain in the database.

## Manual check

Register → submit a report → My Reports → open details/timeline → restart app
(session remains) → logout → log in. A second account must not see the first account's
reports. Existing after-cleanup images display when available; uploads are not added.

## Targeted verification

Backend startup and V5 migration succeeded. There are ten active seeded spots,
including the eight added in V5. Targeted HTTP checks passed for registration, login,
invalid credentials/tokens, unauthenticated access, report ownership, My Reports,
initial history, and denial of another tourist's report. Temporary verification
accounts/report were removed; existing data was preserved.

No full backend tests/build, Flutter tests, or Android build were run for Phase 4.
Flutter device testing remains manual. JWTs expire after seven days; no refresh-token,
password-reset, email verification, or server-side token revocation is implemented.

## Files created/modified

- Modified: `.gitignore`
- Modified: `backend/pom.xml`
- Modified: `backend/src/main/java/np/chitwancare/config/WebConfig.java`
- Modified: `backend/src/main/java/np/chitwancare/controller/ReportController.java`
- Modified: `backend/src/main/java/np/chitwancare/repository/AppUserRepository.java`
- Modified: `backend/src/main/java/np/chitwancare/repository/WasteReportRepository.java`
- Modified: `backend/src/main/java/np/chitwancare/service/ReportImageService.java`
- Modified: `backend/src/main/java/np/chitwancare/service/WasteReportService.java`
- Modified: `backend/src/main/resources/application.properties`
- Modified: `mobile/android/app/src/main/AndroidManifest.xml`
- Modified: `mobile/ios/Runner.xcodeproj/project.pbxproj`
- Modified: `mobile/lib/app/app.dart`
- Modified: `mobile/lib/features/home/screens/home_screen.dart`
- Modified: `mobile/lib/features/reports/controllers/report_controller.dart`
- Modified: `mobile/pubspec.lock`
- Modified: `mobile/pubspec.yaml`
- Created: `backend/scripts/init-auth.sh`
- Created: `backend/src/main/java/np/chitwancare/config/SecurityConfig.java`
- Created: `backend/src/main/java/np/chitwancare/controller/AuthController.java`
- Created: `backend/src/main/java/np/chitwancare/dto/AuthDtos.java`
- Created: `backend/src/main/java/np/chitwancare/service/AuthService.java`
- Created: `backend/src/main/java/np/chitwancare/service/ReportAccessService.java`
- Created: `backend/src/main/resources/db/migration/V5__seed_remaining_tourist_spots.sql`
- Created: `docs/PHASE-4.md`
- Created: `mobile/ios/Runner/Runner.entitlements`
- Created: `mobile/lib/features/auth/auth_controller.dart`
- Created: `mobile/lib/features/auth/auth_screen.dart`
- Created: `mobile/lib/features/reports/repositories/my_reports_repository.dart`
- Created: `mobile/lib/features/reports/screens/my_reports_screen.dart`
