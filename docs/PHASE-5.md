# Phase 5 — authority workflow

Superseded role/assignment instructions: see [targeted fixes](PHASE-5-FIX.md).

Restart the backend and stop/run the existing Flutter app. No new packages or database
migrations are required. ADMIN and DEPARTMENT use the same app and shared report queue;
USER keeps the existing tourist flow. Department-specific routing is not implemented.

## Test account

Register a separate account in the mobile app with an email/password you choose. With
Docker PostgreSQL running, from the project root run:

```sh
sh backend/scripts/set-test-role.sh authority@example.com ADMIN
```

Replace the email with the account you registered. Use DEPARTMENT instead of ADMIN for
a department account. This updates only that existing account; public registration
still always creates USER. Log out and back in to obtain a new JWT with the role.
No default authority password is created. This script is for local development only.

## Endpoints

- GET /api/v1/authority/reports?page=0&size=20
- PATCH /api/v1/authority/reports/{id}/status — JSON status, optional note (1000 chars)
- POST /api/v1/authority/reports/{id}/resolve — multipart metadata JSON with optional
  note, plus image (JPEG/PNG, max 10 MB).
- Existing report detail/image endpoints now also permit DEPARTMENT access.

Only ADMIN/DEPARTMENT may manage reports. Active account role is checked in the service
in addition to JWT route authorization. A database row lock serializes updates.
SUBMITTED → VERIFIED → ASSIGNED → IN_PROGRESS → RESOLVED; REJECTED is allowed before
resolution. Legacy AI_ANALYZED/PENDING_VERIFICATION reports can be verified/rejected.
Resolved/rejected reports are terminal in this phase. ASSIGNED records workflow status,
not a specific department assignment. Resolution requires one cleanup photo and saves
image metadata, status and history in one transaction, removing the file on rollback.
All notes are public to the reporting tourist; history records the acting account.

## Manual check

Tourist submits a report → authority logs in → View Reports → open that report →
mark Verified, Assigned, In Progress → select/take cleanup photo → add note → Resolve.
Tourist logs in → My Reports → open/refresh same report → see resolution note/history
and After cleanup photo. Refresh after uncertain network failures before retrying.

No full old suites, Maven build or Android build were run. Device UI testing is manual.
No counts, filters, thumbnails or Phase 6 features were added. The existing detail
screen shows the original/cleanup images. No notifications or department routing.

## Changed files

- `backend/src/main/java/np/chitwancare/config/SecurityConfig.java`
- `backend/src/main/java/np/chitwancare/repository/WasteReportRepository.java`
- `backend/src/main/java/np/chitwancare/service/ReportAccessService.java`
- `mobile/lib/app/app.dart`
- `mobile/lib/features/auth/auth_controller.dart`
- `mobile/lib/features/reports/repositories/my_reports_repository.dart`
- `mobile/lib/features/reports/screens/my_reports_screen.dart`
- `backend/scripts/set-test-role.sh`
- `backend/src/main/java/np/chitwancare/controller/AuthorityController.java`
- `backend/src/main/java/np/chitwancare/service/AuthorityReportService.java`
- `docs/PHASE-5.md`
- `mobile/lib/features/authority/authority_actions.dart`
- `mobile/lib/features/authority/authority_repository.dart`
- `mobile/lib/features/authority/authority_screen.dart`

Targeted HTTP checks passed: both authority roles can list reports; USER cannot list,
change status or resolve; transitions create history; cleanup image persists/retrieves;
tourist sees RESOLVED and note; terminal updates are rejected. Temporary records and
image were removed. Changed Dart files analyze without issues. Existing data preserved.
