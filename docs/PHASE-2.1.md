# Phase 2.1 — TouristSpot amendment

## Delivered

Tourist destinations are now database-managed entities. Reports may reference one active destination, while their latitude/longitude continue to describe the exact waste incident. Existing JSON requests without `touristSpotId` and existing rows remain compatible.

`tourist_spots` has an identity BIGINT id, required nonblank VARCHAR(150) name, optional VARCHAR(2000) description, NUMERIC(9,6) latitude/longitude, positive INTEGER radius_meters, optional VARCHAR(500) address, active flag and created/updated TIMESTAMPTZ timestamps. PostgreSQL and entity validation enforce coordinate ranges and positive radius.

`waste_reports.tourist_spot_id` is nullable, with a foreign key to tourist_spots. The relationship is many reports to one spot, with no cascading deletion. Indexes support active/name lookup and reports by tourist spot/status. Existing detection/category joins already support future per-spot analytics; no analytics implementation was added.

## Files

Created:
- `backend/src/main/resources/db/migration/V3__add_tourist_spots.sql`
- `backend/src/main/java/np/chitwancare/entity/TouristSpot.java`
- `backend/src/main/java/np/chitwancare/repository/TouristSpotRepository.java`
- `backend/src/main/java/np/chitwancare/service/TouristSpotService.java`
- `backend/src/main/java/np/chitwancare/controller/TouristSpotController.java`
- `backend/src/main/java/np/chitwancare/dto/TouristSpotResponse.java`
- `backend/src/main/java/np/chitwancare/dto/TouristSpotSummary.java`
- `backend/src/test/java/np/chitwancare/TouristSpotIT.java`
- `backend/src/test/java/np/chitwancare/TouristSpotMigrationIT.java`
- This completion document.

Modified:
- `WasteReport.java`: optional destination relation.
- `CreateWasteReportRequest.java`: optional positive touristSpotId.
- `WasteReportResponse.java`: nested touristSpot summary.
- `WasteReportMapper.java`: map id/name without serializing entities.
- `WasteReportService.java`: resolve active destination before persisting.
- `ReportingIT.java`: expect the third applied migration.
- `backend/README.md`: link to amendment and API details.

V1 and V2 are unchanged. Flutter, dependencies, Docker Compose, Department, history and image types are unchanged.

## API

- `GET /api/v1/tourist-spots`: active spots sorted by name then ID; initially `[]`.
- `GET /api/v1/tourist-spots/{id}`: destination DTO with coordinates, radius, description and address. Missing/inactive returns 404; nonpositive ID returns 400.
- `POST /api/v1/reports`: accepts optional `touristSpotId`. Missing/null preserves prior behavior. Unknown/inactive returns 404; nonpositive returns 400, without creating a report.
- Both report GET responses and POST response include `touristSpot: {"id": 1, "name": "Confirmed destination"}`, or null when unassociated. A spot becoming inactive does not erase association or hide its name on historical reports.

The supplied ID is an explicit selection. Coordinates are not automatically matched, checked against a destination radius or changed to its center in this phase. TouristSpotService is the boundary for adding a reviewed nearest/containing-location policy in Phase 3. No PostGIS, maps, geospatial matching or admin write APIs were added.

## Seeds, tracking, evidence and notifications

No production spots are seeded because no authoritative coordinates/radii have been supplied. Tests create clearly labelled synthetic fixtures at (0,0) only in the test database. Confirmed destination data can be added in a future data migration or admin/import workflow. Do not treat test fixtures as official sites.

The existing `statusHistory` array remains ordered by timestamp and ID, exposing `status`, `createdAt` (timestamp), and optional `note`. It already supports a tourist timeline. No duplicate status system or status-change API was introduced. Future internal notes must not be placed in this public timeline field.

ReportImage still supports ORIGINAL, AFTER_CLEANUP and EVIDENCE, with multiple images per report and separate storage keys. No uploads are implemented. Future status-change services can update currentStatus/history transactionally and publish an after-commit event (or later durable outbox) for ASSIGNED/IN_PROGRESS/RESOLVED. No notification infrastructure/provider is needed for this amendment and none was added.

## Verification and applying the migration

2026-09-23: Maven `-Ppostgres-it clean verify` passed **29 backend tests**: 5 unit and 24 integration. Nine new tests cover spot persistence, active listing/detail, association and nested response, invalid/inactive IDs, backwards compatibility, historical association after deactivation, database constraints and migration preservation. The migration test applies V1/V2 to an isolated schema, inserts a report with two detections and history, applies V3, compares the original records/timestamps, checks the null association, and verifies a second migration run is a no-op.

Tests use isolated PostgreSQL 18.4 on port 15439. The user's Docker volume/database was neither deleted nor modified by these tests. V3 has not been applied to that Docker database by this task; application restart will apply it. No production locations were invented.

All 14 existing Flutter tests passed and the Android ARM64 debug APK built successfully. No Flutter files changed. The backend Maven package built successfully, with no failed or skipped tests. `git diff --check` passed. Physical-device/iOS testing was not repeated for this backend-only amendment. The isolated PostgreSQL server was stopped after verification, retaining its test database. No commits or pushes were made by this task.

To apply to your existing Docker PostgreSQL:

```sh
cd /Users/prabinpoudel/Desktop/chitwan-care
docker compose up -d
cd backend
./mvnw spring-boot:run
```

Stop the old backend process first if port 8081 is occupied. Flyway applies V3 on startup and Hibernate validates the updated schema. Keep the existing volume; no reset or `down -v` is needed. Use your existing DB environment variables if customized. Your existing reports keep all data and have a null tourist spot until deliberately associated in a future workflow.

Check `http://127.0.0.1:8081/api/v1/tourist-spots` (empty is expected until verified destinations are added). No Flutter setup changes are needed.

Phase 2.1 prepares the architecture for Phase 3; Phase 3 has not started. GPS matching behavior, real destination data, app integration, authentication, uploads, workflows, notifications and dashboards remain later work.
