# Phase 7 — Maps, summaries and Help & Safety

## Features and access

- Tourist navigation: Home, Map, Reports, Help. Existing home illustration and Report Waste flow unchanged.
- One clustered waste-map screen serves all roles. Viewport requests are debounced; filters are All, Active and Resolved. Marker sheets show categories, tourist spot, simplified status and time. Details are offered only where the server says access is allowed; existing detail authorization still applies.
- USER map: authenticated access to non-sensitive report locations across owners. No names, emails, descriptions, notes or images are returned. A tourist can open full details only for their own report.
- ADMIN map: reports across departments. DEPARTMENT map: only reports with an active assignment to that account's active department, enforced on the server. Neither a department ID nor an owner ID can be supplied to widen access.
- Rejected reports are excluded from all maps. Red = SUBMITTED/VERIFIED (also legacy pending statuses), amber = ASSIGNED/IN_PROGRESS, green = RESOLVED.
- Admin summary: real database counts, top 10 tourist spots and top 10 waste categories. Department summary remains assignment-scoped. Existing manual Verify/Assign/Start/Cleanup/Resolve actions are unchanged.

## Dependencies and API

Added flutter_map 8.3.2, flutter_map_marker_cluster 8.2.2, latlong2 0.9.1 and url_launcher 6.3.2. OSM standard tiles have visible attribution and an app-identifying User-Agent. flutter_map's default native tile cache is retained; no prefetch/offline map system is added. Internet is required; public OSM tiles have no availability guarantee. Review tile-provider capacity before substantial production traffic.

- `GET /api/v1/maps/reports?south=27&west=84&north=28&east=85&filter=ALL`
  - Bearer token required. Filter: ALL, ACTIVE, RESOLVED. Valid ordered geographic bounds required.
  - `{reports: [{id, latitude, longitude, statusGroup, touristSpot, createdAt, categories, canViewDetails}], truncated}`.
  - At most 500 newest reports per viewport; zoom-in notice when truncated. Clusters expand overlapping markers. Intended for Chitwan; antimeridian-spanning viewports are not supported.
- `GET /api/v1/authority/insights`
  - ADMIN/DEPARTMENT only. `{overview: {total, active, submitted, assigned, inProgress, resolved}, touristSpots: [{name,count}], categories: [{name,count}]}`.
  - Total includes rejected; active excludes rejected/resolved. Department total counts reports with an active assignment, including resolved reports. Department rankings are empty, preventing global information leakage.
  - Tourist-spot ranking counts non-rejected reports linked to each spot; unassociated reports are omitted. Category ranking counts individual detection records on non-rejected reports, not unique reports, objects by weight, or waste volume.

No migration, database reset, authentication redesign or assignment changes. Existing stored data is preserved.

## Help & Safety

Verified 26 September 2026 against official sources:

- Bharatpur Hospital emergency: **056-597003**, 24/7, Bharatpur, Chitwan. [Official hospital portal](https://online.bharatpurhospital.gov.np/) and [official hospital publication](https://www.bharatpurhospital.gov.np/Content/Publication/123123.pdf).
- Nepal Police: **100**; Tourist Police toll-free: **1144**. [Official Nepal Police tourist assistance page](https://nepalpolice.gov.np/tourist-police/).
- No separate ambulance number was included without verification.

Call opens a `tel:` dialer URI; it never places a call automatically. Short codes require a Nepal telephone network. Hospital Directions opens an external maps URL with the verified hospital name/address, without invented coordinates or a Google Maps API key. The installed handler may be a maps app or browser; confirm the destination before travelling.

Current location reuses the existing permission-aware location service. It is requested only on tap, displayed with accuracy, and can open an external `geo:` map action. This screen neither stores nor submits location. Denied/disabled location offers retry/settings; missing dialer/maps handlers show a useful message.

## Physical-phone manual check

1. Keep existing Docker PostgreSQL running. Restart the backend using the existing launcher, or run `./mvnw spring-boot:run` from `backend/`, so port 8081 serves the new endpoints.
2. Connect Android by USB with USB debugging enabled. For this test, run `adb reverse tcp:8081 tcp:8081`. In `mobile/`, run `flutter run -d PHONE_DEVICE_ID --dart-define=API_BASE_URL=http://127.0.0.1:8081` using the existing Flutter SDK. Obtain the ID with `flutter devices`. Alternatively retain your working LAN-IP API_BASE_URL configuration. Internet on the phone is separately needed for OSM tiles.
3. Tourist: Home → Map; pan/zoom; select Active/Resolved; tap clusters/markers. Check category/spot/time and absence of personal/private fields. Another tourist's marker must not offer full details. Reports and Home → Report Waste must still open normally.
4. Help: tap Hospital Call and cancel the dialer **without placing a test emergency call**. Check Hospital Directions. Request location; deny once, retry, then allow. Check coordinates and Open location in Maps. Check offline/retry behavior.
5. Admin: check total/active/resolved counts and rankings; open/filter map. Open an existing report and use the unchanged Verify/manual department selection/Assign workflow.
6. Department A: check assigned counts/map and existing In Progress/cleanup/Resolve workflow. Department B must not see or open A's assigned report. Tourist can still see their updated report in Reports.
7. Use Refresh after status changes. No push/live-stream updates are implemented.

## Targeted verification

- Backend compiled and started on temporary port 18081. `backend/scripts/check_phase7.py` passed HTTP checks for authentication, safe DTO fields, owner detail capability, rejected exclusion, filters/bounds, two-department isolation, department counts and admin aggregates/rankings. Temporary accounts/departments/spot/reports were removed; existing rows were not changed.
- Seven new Flutter tests in `mobile/test/phase7_test.dart` passed: DTO/status presentation, viewport/filter request and error handling, action URIs, role dashboards, tourist navigation, Help location denial/retry.
- Changed-file Dart analysis: no issues. One Android debug APK build passed.
- No historical suites, Maven test suite, iOS build, AI tests or device installation performed. Actual tiles, clustering gestures, dialer/maps launches and GPS permissions still need the physical-phone checks above.
- Repeat backend checks only on a development database: provide standard `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER`, `PGPASSWORD`, optional `PSQL` executable path and `PHASE7_BASE_URL`, then run `python3 backend/scripts/check_phase7.py`. No credentials are embedded in the script.

## Files

Created:
- `backend/src/main/java/np/chitwancare/controller/LocationInsightsController.java`
- `backend/src/main/java/np/chitwancare/service/LocationInsightsService.java`
- `backend/scripts/check_phase7.py`
- `mobile/lib/features/location_intelligence/{insights_repository,map_status,waste_map_screen,analytics_panel}.dart`
- `mobile/lib/features/help/help_screen.dart`
- `mobile/lib/features/home/screens/tourist_shell.dart`
- `mobile/test/phase7_test.dart`
- `docs/PHASE-7.md`

Modified:
- `backend/src/main/java/np/chitwancare/config/SecurityConfig.java` (authenticated map route only)
- `mobile/lib/app/app.dart` (tourist home shell only)
- `mobile/lib/features/authority/authority_screen.dart` (aggregated counts/rankings/map entry)
- `mobile/pubspec.yaml`, `mobile/pubspec.lock`
