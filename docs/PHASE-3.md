# Phase 3 — real mobile report submission

Chitwan Care remains a Flutter mobile app focused on tourism in Bharatpur and Chitwan. AI detection is still explicitly mocked. The final report submission now uses real HTTP, Spring Boot, PostgreSQL and image storage. No authentication, dashboards, department assignment, notifications or real model integration was added.

## Start and use

From the repository root:

```sh
docker compose up -d
cd backend
./mvnw spring-boot:run
```

Alternatively start the existing PostgreSQL container in Docker Desktop, then choose **Chitwan Backend → Run** in Android Studio. Stop and restart an already-running backend to load Phase 3 code. Do not delete the Docker volume.

In another terminal, from the repository root:

```sh
cd mobile
flutter pub get
flutter run -d YOUR_ANDROID_EMULATOR_ID
```

Android Studio: open the `mobile` folder, select **main.dart**, choose your emulator and Run. Because a native GPS dependency was added, stop and rerun the app; hot reload alone is insufficient. Keep the backend running.

Use your installed Flutter SDK if `flutter` is not on PATH. Existing `scripts/flutterw` also supports `FLUTTER_SDK`.

## Configuration and device networking

All mobile HTTP clients use `lib/core/config/app_config.dart`.

| Setting | Default | Purpose |
|---|---|---|
| Dart define API_BASE_URL | http://10.0.2.2:8081 | Android emulator reaches the Mac backend |
| Dart define ANALYSIS_MODE | mock | Local simulated AI remains default |
| Backend UPLOAD_DIR | ./uploads | Image folder relative to backend working directory |
| Backend SERVER_ADDRESS | 127.0.0.1 | Local-only server binding |
| Backend SERVER_PORT | 8081 | API port |

Database configuration is unchanged. Use existing DB_URL, DB_USERNAME and DB_PASSWORD environment variables when needed; do not put real credentials in source. Spring Boot does not automatically read root `.env`; set backend variables in the shell or Android Studio run configuration.

Android debug already permits HTTP. Release networking has not been weakened; use HTTPS for a future deployed backend.

For a USB-connected physical Android phone, use this option without exposing the backend to the LAN:

```sh
adb -s YOUR_PHONE_ID reverse tcp:8081 tcp:8081
flutter run -d YOUR_PHONE_ID --dart-define=API_BASE_URL=http://127.0.0.1:8081
```

Repeat adb reverse after reconnecting when necessary. Alternatively, on a trusted development network, start the backend with `SERVER_ADDRESS=0.0.0.0` and use `--dart-define=API_BASE_URL=http://YOUR_MAC_LAN_IP:8081`. The current unauthenticated report/image API would then be accessible on that network. Do not use 10.0.2.2 on a physical phone.

iOS simulator uses `--dart-define=API_BASE_URL=http://127.0.0.1:8081`. A when-in-use location purpose string is included. iOS build, signing, camera and permissions were not verified in Phase 3. No background location is requested. See the [geolocator platform configuration](https://pub.dev/packages/geolocator) before iOS distribution.

## Form and location

Continue to Report opens the existing flow's real report form. The form retains the image and mock categories/confidences. It loads categories and active tourist spots, and provides **Get current location**.

GPS uses geolocator with high requested accuracy and a 25-second location timeout. Permission denial, permanent denial, services off, timeout and acquisition errors are distinct actionable states. Settings and Retry are available; no fallback coordinates are invented. The user must capture a valid location and review the report before submission. The form displays coordinates and estimated accuracy. Capture GPS while at the incident, including when choosing a gallery photo.

The backend matches active tourist spots using Haversine distance in metres. Only spots whose configured radius contains the point qualify. The closest qualifying spot wins; equal distances use the smaller ID. A 204 response means no match. No-match reports may have null touristSpotId. Manual selection of an active spot changes only the association, never exact incident GPS. On matching failure, retry or explicitly choose a destination/no destination; failure is not silently treated as a successful match.

No official tourist destinations or coordinates were invented. If the active catalog is empty, no-match is expected. An administrator/developer must later register verified locations. Tests use clearly synthetic coordinates in a separate test database.

Waste categories are fetched from the backend. Stable category codes or normalized names (case, whitespace and punctuation ignored) map detections to database IDs. Unknown labels fall back to the active Other category; original label and confidence are preserved. If neither a match nor Other exists, submission fails clearly. IDs are never hard-coded in the app.

For the existing no-waste mock scenario, the user can explicitly select a manual-review category. Its label is prefixed `Manual review:` and confidence is 0; this does not claim the model detected waste.

## REST APIs

| Endpoint | Behavior |
|---|---|
| GET /api/v1/waste-categories | Existing active category catalog |
| GET /api/v1/tourist-spots | Existing active destination catalog |
| GET /api/v1/tourist-spots/nearest?latitude=…&longitude=… | New radius-contained match; 200 DTO or 204 no match; invalid GPS → 400 |
| POST /api/v1/reports, application/json | Preserved Phase 2 creation |
| POST /api/v1/reports, multipart/form-data | New image + metadata creation; returns 201 |
| GET /api/v1/reports/{id} | Existing details, now also includes images |
| GET /api/v1/reports/{reportId}/images/{imageId} | New image download, checks report/image relationship |

Multipart parts:

- `metadata`: application/json with description, latitude, longitude, severity, optional touristSpotId and detections.
- `image`: actual binary JPEG/PNG.
- Each detection uses `categoryId`, `label`, `confidence`, matching the existing DTO.

After fetching category IDs, write a local metadata.json using those IDs, then:

```sh
curl -i http://127.0.0.1:8081/api/v1/reports \
  -F 'metadata=@metadata.json;type=application/json' \
  -F 'image=@scene.jpg;type=image/jpeg'
```

Both report creation methods reuse the same report-building logic. Multipart adds an ORIGINAL ReportImage and writes the file. The result retains status SUBMITTED, detections, touristSpot summary, timestamp and statusHistory; image summaries include ID, type, sanitized filename, MIME type, timestamp and a retrieval URL. Local paths/storage keys are not returned.

## Storage and consistency

Development images default to `backend/uploads/` when started in the backend folder, including the Android Studio configuration. Override UPLOAD_DIR as needed. The folder is created on first successful upload; `uploads/` is ignored by Git.

Server validation rejects empty files, files above 10 MiB, unsupported MIME types, mislabeled or undecodable images and images above 40 megapixels. The existing mobile selection validator is stricter at 24 megapixels. Only JPEG/PNG are accepted; HEIC and WebP must be converted before selection. UUID filenames are generated server-side. Client names are sanitized metadata only. Reads/deletes accept only the opaque generated key format, reject symlinks and do not accept client paths. Retrieval verifies the image belongs to the report and returns its content type plus nosniff.

Database changes are one transaction. Partial filesystem write failures clean up their target. A transaction completion callback deletes the stored file if the database transaction rolls back, including commit failures. Storage errors return failure, not a fake success. As with ordinary local storage, process/power loss between file write and transaction completion can leave an orphan file; no distributed transaction or background reconciliation engine was added.

Repeated taps are blocked during upload and after success. Network failure leaves the photo/form available for retry. If the server commits but the response is lost, a retry can create another report: the UI warns about uncertain outcomes. Cross-request idempotency/offline synchronization remains future work.

The report is stored centrally only. No department is silently assigned, and the success screen makes no claim that a department has acted.

## Verification

Backend complete suite and Maven build:

```sh
cd backend
DB_URL=jdbc:postgresql://127.0.0.1:YOUR_TEST_PORT/chitwan_care_test \
DB_USERNAME=YOUR_TEST_USER DB_PASSWORD=YOUR_TEST_PASSWORD \
./mvnw -Ppostgres-it verify
```

Use a dedicated test database. The suite writes synthetic reports. Multipart tests use a temporary upload directory and remove their own files. Existing JSON, migration and restart-persistence tests remain.

```sh
cd mobile
flutter test
flutter analyze
flutter build apk --debug
```

An additional real HTTP smoke test uses the same Dart repository as the UI:

```sh
cd mobile
dart run tool/verify_report_api.dart http://127.0.0.1:18081
```

This writes a synthetic report. Run only against an isolated test backend with a clearly labelled development tourist spot at latitude 0, longitude 0, radius 100 m. It checks two detections, exact GPS, destination association, initial history and byte-identical original-image retrieval.

Verified on 2026-09-23: 39 backend tests (8 unit + 31 integration), 33 Flutter tests, Maven build and Android debug build all passed; Flutter analyze reported no issues. The live Dart → Spring Boot → PostgreSQL → file-storage test produced report #17 in the isolated test database and passed. Database inspection confirmed two detections, one ORIGINAL image, one initial history entry and the exact submitted GPS/spot. It used synthetic coordinates/photo, not live device GPS.

## Manual Android end-to-end check

1. Start Docker PostgreSQL and restart the Phase 3 backend. Verify health is UP.
2. Stop and rerun the Flutter app in an Android emulator.
3. Emulator **Extended Controls (⋮) → Location → Single points**: set a simulated location. For destination matching, use a verified registered spot's coordinates. Do not seed fabricated official places.
4. Tap Report Waste → camera/gallery → select an actual JPEG/PNG → Analyze photo.
5. Review the mock results → Continue to Report.
6. Tap Get current location. Allow location while using the app. Confirm the captured coordinates.
7. Check matching destination, manually correct if necessary, or keep no destination if none matches.
8. Add description, choose severity and tick the review confirmation.
9. Tap Submit report once. Confirm Report submitted, returned report ID and SUBMITTED.
10. GET /api/v1/reports/{id}. Check detections, exact coordinates, touristSpot, SUBMITTED history and one ORIGINAL image.
11. Open the returned images[0].url against your backend. It must return the uploaded image.
12. Inspect the report_images row and corresponding generated file under UPLOAD_DIR.
13. Test location denial/services-off and retry. Stop the backend and test submission failure; the image/form must remain available.

Optional database verification, substituting your returned ID:

```sql
SELECT id, latitude, longitude, tourist_spot_id, severity, current_status
FROM waste_reports WHERE id = YOUR_REPORT_ID;
SELECT * FROM waste_detections WHERE report_id = YOUR_REPORT_ID;
SELECT * FROM report_status_history WHERE report_id = YOUR_REPORT_ID;
SELECT id, image_type, original_filename, content_type, storage_key
FROM report_images WHERE report_id = YOUR_REPORT_ID;
```

This full manual camera/gallery + device GPS run has not been performed by the agent. Automated widget tests replace the device picker/GPS and server with fakes; backend integration and real Dart HTTP tests independently exercise real persistence and upload.

## Files and scope

New backend: LocalImageStorage, ReportImageService, ReportImageResponse, MultipartReportIT and StorageAndMatchingTest.

Modified backend: ReportController, WasteReportService, WasteReport, WasteReportResponse, WasteReportMapper, ImageStorage, TouristSpotController, TouristSpotService, TouristSpotIT and application.properties.

New mobile: report_models.dart, report_repository.dart, location_service.dart, report_controller.dart, report_success_screen.dart; report_fakes.dart, report_test.dart, location_service_test.dart; tool/verify_report_api.dart.

Modified mobile: report_draft_screen.dart, app.dart (back-navigation guard), home_screen.dart/result_screen.dart (accurate phase text), pubspec.yaml/pubspec.lock, Android main manifest, iOS Info.plist, widget_test.dart. Direct dependency added: geolocator 14.0.3; Dio and Riverpod were reused.

Other changes: root/backend/mobile README, this document, .env.example and .gitignore.

No Phase 3 schema migration was required: the existing report_images table already has the metadata fields. V1/V2/V3 are unchanged by Phase 3. Docker PostgreSQL volumes/data were not deleted, recreated, or used for these tests.

Phase 4 has not started. Authentication/ownership, My Reports, assignment and cleanup workflows, real AI, notifications and dashboards remain out of scope.
