# Phase 7.1 — Admin Management

## Functionality

Admin Dashboard → Management → Departments / Tourist Spots. Both lists include active and inactive records, with Add, Edit, loading, retry, validation and save-progress states. Save confirms deactivation; activation requires only Save. No delete operation exists.

Department fields: name (required, maximum 150), description (maximum 1000), active. Existing contact fields are preserved. Tourist spot fields: name (required, maximum 150), description (2000), address (500), selected coordinates, positive integer matching radius and active. Trimmed, case-insensitive duplicate names are rejected, including inactive records. This application check is intended to prevent accidental duplicates; it is not a new concurrent case-insensitive database constraint.

The picker uses the existing flutter_map/OpenStreetMap stack, cache and attribution, without changing the Waste Map. Pan/zoom and tap to place or move the marker, then Confirm location. New spots cannot be saved without a selection. Coordinates are displayed secondarily and rounded to the existing six-decimal schema. Radius is an application matching value, not an official boundary. Tiles need internet; failures offer Retry. No new dependencies.

## Endpoints and security

Added under `/api/v1/admin/management`:

| Method | Path | Purpose |
|---|---|---|
| GET | `/departments` | All departments, including inactive |
| POST | `/departments` | Create department |
| PUT | `/departments/{id}` | Edit fields and active state |
| GET | `/tourist-spots` | All destinations, including inactive |
| POST | `/tourist-spots` | Create destination |
| PUT | `/tourist-spots/{id}` | Edit fields and active state |

All require ADMIN at the security filter and a current active Admin account in the service. DTOs accept only editable fields; IDs and relationships cannot be reassigned through request bodies. POST returns 201; PUT returns 200; validation 400; duplicate 409; missing ID 404. Existing exception handling is reused.

Existing `GET /api/v1/departments` and `GET /api/v1/tourist-spots` remain unchanged and return only active records for new assignments/reports. Existing assignment and report validation remain authoritative. No authentication or workflow redesign.

Deactivation never deletes or renumbers records, user links, assignments or report associations. Admin and report owners can still read historical reports. **Existing access rule preserved:** linked department accounts lose operational access when their department is inactive; reactivation restores eligibility. The deactivation dialog explains this. Complete active work before deactivating an authority when necessary.

No database migration, reset or change to old migrations. No automatic assignment or account creation is added.

## Files

Created:
- `backend/src/main/java/np/chitwancare/controller/AdminManagementController.java`
- `backend/src/main/java/np/chitwancare/service/AdminManagementService.java` (validated input/output DTO records included)
- `backend/scripts/check_phase71.py`
- `mobile/lib/features/management/management_repository.dart`
- `mobile/lib/features/management/management_screen.dart`
- `mobile/lib/features/management/location_picker.dart`
- `mobile/test/phase71_test.dart`
- `docs/PHASE-7.1.md`

Modified:
- `backend/src/main/java/np/chitwancare/config/SecurityConfig.java` — Admin-only new route rule
- `backend/src/main/java/np/chitwancare/repository/DepartmentRepository.java` — duplicate-name lookup
- `backend/src/main/java/np/chitwancare/repository/TouristSpotRepository.java` — duplicate-name lookup
- `mobile/lib/features/authority/authority_screen.dart` — Admin-only Management button

## Targeted verification

Backend compiled/started on temporary port 18081 with tests skipped. HTTP checks passed for Admin list/create/edit/deactivate/reactivate, unauthenticated denial, USER/DEPARTMENT denial, required fields/coordinates/radius, case-insensitive duplicates, active catalog filtering, preserved IDs/contact details/user links/assignment links and readable historical tourist-spot references. Only test-created fixtures were removed afterward. Existing data was preserved.

Six targeted Flutter tests passed for repository requests, non-Admin visibility, required name/save progress, missing map selection and deactivation cancellation. Relevant Dart analysis passed. No historical suites, full Maven build or Android build were run. No native dependency changed. Physical map gestures and the full workflow are left for phone verification.

To repeat backend checks on a development database, supply standard PGHOST/PGPORT/PGDATABASE/PGUSER/PGPASSWORD, optional PSQL executable and PHASE7_BASE_URL (default temporary backend port 18081), then run `python3 backend/scripts/check_phase71.py`. The script creates disposable fixtures; no credentials are stored in it.

## Physical-phone check

1. Keep Docker PostgreSQL running; restart the existing backend launcher (or run `./mvnw spring-boot:run` from `backend`). Hot-restart Flutter in Android Studio using the same working physical-phone API URL. No new environment variables/packages are needed.
2. Admin → Management → Departments: confirm existing records. Add a uniquely named temporary department, save, reopen an assignment selector and check it appears. Edit its description, deactivate, confirm the dialog and reopen the selector: it must be absent. Verify old report history/user links still exist. Reactivate if needed.
3. Admin → Management → Tourist Spots: Add, enter name, Select Location on Map, pan/zoom/tap, Confirm, set radius, Save. Confirm it appears when opening a fresh tourist report form. Edit/deactivate and reopen that form: it must be absent. Old reports retain the same spot association.
4. Tourist and Department logins: Management must be absent. Backend authorization was separately verified against direct requests.
5. Regression manually: normal tourist report → Admin Verify → manually select an active department → Assign → Department In Progress → cleanup evidence → Resolve.

Limitations: small catalogs load as a single list; simultaneous edits use last-save-wins; no department-account provisioning. Inactive department access follows the existing rule above. Nothing beyond Phase 7.1 implemented.
