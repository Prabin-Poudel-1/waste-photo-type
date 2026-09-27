# Phase 5 targeted fixes

Restart the backend and stop/run the mobile app. V6 adds only a nullable department
membership to existing accounts; it preserves existing data. It has already applied
successfully on this machine. No old migrations were changed.

ADMIN: view all, verify, choose an active department and assign, reject, monitor.
DEPARTMENT: view only active assignments to its department, start work, resolve with
cleanup photo/note. Admin cleanup and department verification/assignment are denied
server-side. Detail and image retrieval enforce the same department restriction.
Assignment uses ReportAssignment and creates an ASSIGNED history entry. No automatic
routing/reassignment was added. Resolved assignments remain visible for monitoring.

Dashboards count all pages of the role-scoped report list. Department Assigned Reports
means all reports assigned to that department, including completed ones. Refresh
updates counts; returning from the report list refreshes automatically.

## Link a department test account

Register the account normally. Find active department IDs:

```sh
curl http://127.0.0.1:8081/api/v1/departments
```

From the project root (replace email and 123 with the real department ID):

```sh
sh backend/scripts/set-test-role.sh staff@example.com DEPARTMENT 123
```

ADMIN setup is unchanged:

```sh
sh backend/scripts/set-test-role.sh admin@example.com ADMIN
```

Log out and in again. An unlinked DEPARTMENT account cannot access department reports.
If no departments exist, create clearly labeled development data using Docker:

```sh
docker compose exec postgres sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"'
```

Then run this SQL and use the returned ID (run only once):

```sql
INSERT INTO departments(name,description,active,created_at,updated_at)
VALUES ('Development Cleanup Team','Local test department only',true,now(),now())
RETURNING id;
```

## Manual check

Tourist submits → admin verifies → selects department → assigns → linked department
logs in → sees assigned report → In Progress → uploads cleanup photo → resolves.
Tourist opens the same report to see history, note and cleanup photo. Another department
must not see/access it. Check both dashboard counts and logout.

Legacy reports already marked ASSIGNED without a ReportAssignment are not automatically
allocated to a department. No historical assignments or account memberships are guessed.

## Files changed for this fix

- backend/src/main/java/np/chitwancare/entity/AppUser.java
- backend/src/main/java/np/chitwancare/repository/ReportAssignmentRepository.java
- backend/src/main/java/np/chitwancare/repository/WasteReportRepository.java
- backend/src/main/java/np/chitwancare/service/ReportAccessService.java
- backend/src/main/java/np/chitwancare/service/AuthorityReportService.java
- backend/src/main/java/np/chitwancare/controller/AuthorityController.java
- backend/src/main/resources/db/migration/V6__link_department_accounts.sql
- backend/scripts/set-test-role.sh
- mobile/lib/features/authority/authority_screen.dart
- mobile/lib/features/authority/authority_actions.dart
- mobile/lib/features/authority/authority_repository.dart
- mobile/lib/features/reports/screens/my_reports_screen.dart
- mobile/test/phase5_targeted_fix_test.dart
- docs/PHASE-5-FIX.md
- docs/PHASE-5.md

Targeted HTTP checks passed for role restrictions, assignment, scoped list/detail/image
access, resolution and history. Temporary verification records/images were removed.
No full old suites, Maven build or Android build were run.

All three new targeted Flutter widget tests passed: admin dashboard counts, department
dashboard counts, and post-status-save/detail refresh without the setState Future error.
Changed Dart files analyze cleanly.
