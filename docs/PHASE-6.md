# Phase 6 — Android on-device waste detection

Runtime: Google LiteRT 2.1.5 CompiledModel, CPU, two threads. A small Android method
channel exposes inference only; no cloud inference or Flutter YOLO wrapper is used.
Dart image 4.10.1 handles decoding/EXIF orientation/letterboxing in a compute isolate.
Flutter SDK integration_test is a development-only dependency for the native smoke test.

Exact resource: mobile/android/app/src/main/assets/best_int8.tflite
SHA256: 024d0b6a67e2437b53ee58cbcb000d0d3288df48ded2ce0e91ac7a386b970090
The supplied model is unchanged. It exposes FLOAT32 [1,3,640,640] input and FLOAT32
[1,11,8400] output. Quantization is internal; no boundary INT8 conversion is applied.
Native initialization checks shapes/types, loads once and reuses buffers. A single
worker serializes native calls; resources close on engine cleanup. Both service and
existing analysis controller prevent duplicate calls. Failures never fall back to mock.

Images are baked upright, letterboxed with value 114 padding, normalized to RGB 0–1,
and packed NCHW. Scale, resized dimensions and integer X/Y padding are retained.
Decode uses normalized center-x/center-y/width/height plus seven class scores. It selects
the best class per candidate, requires confidence >=0.25, then class-aware NMS at IoU
0.45. Boxes are restored to upright original-resolution pixel coordinates and clipped.
Integer resize rounding is accounted for through actual X/Y resize ratios.

The strongest 20 post-NMS objects are kept to respect the existing report API limit.
Class mapping is centralized in yolo_processing.dart: cardboard and paper map to the
existing paper code, miscellaneous to Other; organic/glass/metal/plastic retain their
codes. Labels and confidence remain unchanged in the existing WasteDetection objects.
No backend/category/schema or report workflow modifications are needed.

Result preview uses the same upright image used for inference. BoxFit.contain and
center alignment are shared by its painter's scaling/offset calculation. An empty
result offers another photo; Continue to Report is disabled until waste is detected.
The original selected photo bytes still feed existing report submission. No uploaded
image is substituted with the inference preview.

Normal detectionServiceProvider now always uses OnDeviceWasteDetectionService.
Mock fixtures/interfaces remain for historical tests, but demo controls are removed
and neither mock nor HTTP inference is selected in production, regardless of old
ANALYSIS_MODE defines. Existing report networking still uses API_BASE_URL normally.

## Manual test

1. Stop the app and run mobile/lib/main.dart on Android from Android Studio (full Run;
   hot reload cannot register a new native bridge). Keep the existing backend/Docker
   running for login and report submission.
2. Log in as a tourist → Report Waste → Camera → photograph waste → Analyze.
3. Check real class/confidence and boxes. Repeat with Gallery, including a portrait
   photo and rotated photo. Multiple objects should show multiple boxes.
4. Try a clear non-waste image; no predictions above threshold must show No waste
   detected. This does not promise that every non-waste photo yields zero detections.
5. Continue to Report → existing GPS/spot/description/severity → submit → My Reports.
6. To check offline inference: after login and choosing a photo, disconnect network
   and analyze. Login/submission still require the backend; inference does not.

No real-image accuracy claim is made. Android CPU only; iOS/web inference is not
implemented and reports a supported-platform error instead of fake results. GPU,
model retraining, conversion, and additional project phases were not attempted.

## Files created/changed

- mobile/android/app/build.gradle.kts
- mobile/android/app/src/main/kotlin/np/chitwancare/chitwan_care/MainActivity.kt
- mobile/android/app/src/main/kotlin/np/chitwancare/chitwan_care/WasteInferenceBridge.kt
- mobile/android/app/src/main/assets/best_int8.tflite
- mobile/pubspec.yaml and mobile/pubspec.lock
- mobile/lib/features/analysis/controllers/analysis_controller.dart
- mobile/lib/features/analysis/models/detection_result.dart
- mobile/lib/features/analysis/services/on_device_waste_detection_service.dart
- mobile/lib/features/analysis/services/yolo_processing.dart
- mobile/lib/features/analysis/screens/detection_preview.dart
- mobile/lib/features/analysis/screens/result_screen.dart
- mobile/lib/features/analysis/screens/capture_screen.dart
- mobile/lib/features/analysis/screens/analyzing_screen.dart
- mobile/lib/features/home/screens/home_screen.dart (analysis notice only)
- mobile/test/phase6/detector_test.dart
- mobile/integration_test/phase6_device_test.dart
- docs/PHASE-6.md

## Targeted verification

Ten Phase 6 tests passed: exact bundled bytes, RGB/NCHW/padding, EXIF orientation,
threshold/highest class/NMS/empty result, inverse letterbox/clipping, contain display
scaling, category mapping, malformed inputs, camera/gallery routing and duplicate-tap
prevention with the existing draft. Channel inference is mocked only in these unit tests.
Changed Dart source/tests analyze cleanly. No old backend or Flutter suites were run.

One Android debug build completed successfully (67.1 s). The Phase 6 integration test
passed on emulator-5554: the actual bundled model initialized and performed two
successive inferences through WasteInferenceBridge, exercising reuse, preprocessing,
decoding and result construction without a mock channel. One integration test passed.
The APK installed by this check runs the test entrypoint; select lib/main.dart and
use normal Android Studio Run for the interactive app. No second Android build was run.
