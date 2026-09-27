import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chitwan_care/app/app.dart';
import 'package:chitwan_care/core/errors/app_failure.dart';
import 'package:chitwan_care/features/analysis/controllers/analysis_controller.dart';
import 'package:chitwan_care/features/analysis/models/detection_result.dart';
import 'package:chitwan_care/features/analysis/repositories/analysis_repository.dart';
import 'package:chitwan_care/features/analysis/services/mock_waste_detection_service.dart';
import 'package:chitwan_care/features/capture/services/photo_service.dart';
import 'package:chitwan_care/features/reports/controllers/report_controller.dart';

import 'report_fakes.dart';

class FakePhotos implements PhotoService {
  final WastePhoto photo;
  AppFailure? failure;
  bool cancel = false;
  FakePhotos(this.photo);
  @override
  Future<WastePhoto?> pick(ImageSource source) async {
    if (failure != null) throw failure!;
    return cancel ? null : photo;
  }

  @override
  Future<WastePhoto?> recover() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late WastePhoto photo;
  setUpAll(() async {
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawRect(
      const Rect.fromLTWH(0, 0, 24, 24),
      Paint()..color = Colors.green,
    );
    final image = await recorder.endRecording().toImage(24, 24);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    photo = WastePhoto(
      bytes: data!.buffer.asUint8List(),
      name: 'scene.png',
      selectedAt: DateTime(2026),
    );
  });
  test(
    'Mock fixtures expose multiple, empty, low confidence and failure',
    () async {
      const mock = MockWasteDetectionService(delay: Duration.zero);
      expect(
        (await mock.analyze(photo, MockScenario.multiple)).detections.length,
        3,
      );
      expect(
        (await mock.analyze(photo, MockScenario.none)).wasteDetected,
        false,
      );
      expect(
        (await mock.analyze(
          photo,
          MockScenario.low,
        )).detections.single.needsReview,
        true,
      );
      expect(
        () => mock.analyze(photo, MockScenario.error),
        throwsA(isA<AppFailure>()),
      );
    },
  );
  test(
    'Repository rejects invalid and oversized images before inference',
    () async {
      const repo = AnalysisRepository(
        MockWasteDetectionService(delay: Duration.zero),
      );
      await repo.validate(photo);
      for (final bytes in [
        Uint8List(0),
        Uint8List.fromList([1, 2, 3]),
        Uint8List(10 * 1024 * 1024 + 1),
      ]) {
        expect(
          () => repo.validate(
            WastePhoto(
              bytes: bytes,
              name: 'bad.jpg',
              selectedAt: DateTime.now(),
            ),
          ),
          throwsA(isA<AppFailure>()),
        );
      }
    },
  );
  test('Unknown category labels remain extensible and invalid scores fail', () {
    expect(
      WasteDetection.fromJson({
        'categoryCode': 'new',
        'label': 'Future category',
        'confidence': .5,
      }).label,
      'Future category',
    );
    expect(
      () => WasteDetection.fromJson({
        'categoryCode': 'new',
        'label': 'Bad',
        'confidence': 1.5,
      }),
      throwsFormatException,
    );
  });
  test(
    'Cancellation preserves previous photo and denied permission is actionable',
    () async {
      final picker = FakePhotos(photo);
      final container = ProviderContainer(
        overrides: [photoServiceProvider.overrideWithValue(picker)],
      );
      addTearDown(container.dispose);
      final controller = container.read(analysisProvider.notifier);
      controller.start();
      await controller.pick(ImageSource.gallery);
      picker.cancel = true;
      await controller.pick(ImageSource.camera);
      expect(container.read(analysisProvider).photo, photo);
      picker.failure = const AppFailure(
        'Permission denied',
        permissionDenied: true,
      );
      await controller.pick(ImageSource.camera);
      expect(container.read(analysisProvider).error!.permissionDenied, true);
      expect(container.read(analysisProvider).photo, photo);
    },
  );
  test('Leaving analysis ignores a late result', () async {
    final container = ProviderContainer(
      overrides: [
        photoServiceProvider.overrideWithValue(FakePhotos(photo)),
        detectionServiceProvider.overrideWithValue(
          const MockWasteDetectionService(delay: Duration(milliseconds: 10)),
        ),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(analysisProvider.notifier);
    controller.start();
    await controller.pick(ImageSource.gallery);
    final pending = controller.analyze();
    controller.backToPhoto();
    await pending;
    expect(container.read(analysisProvider).step, FlowStep.capture);
    expect(container.read(analysisProvider).result, isNull);
  });
  testWidgets('Complete gallery flow reaches real report form and submission', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          photoServiceProvider.overrideWithValue(FakePhotos(photo)),
          reportRepositoryProvider.overrideWithValue(FakeReportRepository()),
          locationServiceProvider.overrideWithValue(FakeLocationService()),
          detectionServiceProvider.overrideWithValue(
            const MockWasteDetectionService(delay: Duration.zero),
          ),
        ],
        child: const CareApp(),
      ),
    );
    await tester.scrollUntilVisible(find.text('Report Waste'), 180);
    await tester.tap(find.text('Report Waste'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Choose from gallery'), 180);
    await tester.runAsync(() async {
      await tester.tap(find.text('Choose from gallery'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Analyze photo'), 180);
    await tester.runAsync(() async {
      await tester.tap(find.text('Analyze photo'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
    expect(find.text('Detection results'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Plastic'), 160);
    expect(find.text('Plastic'), findsOneWidget);
    expect(find.text('94%'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Continue to Report'), 180);
    await tester.tap(find.text('Continue to Report'));
    await tester.pumpAndSettle();
    expect(find.text('Prepare report'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Get current location'), 180);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Get current location'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get current location'));
    await tester.pumpAndSettle();
    expect(find.text('Location captured'), findsOneWidget);
    final reportScroll = find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.byType(CheckboxListTile),
      180,
      scrollable: reportScroll,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Submit report'),
      160,
      scrollable: reportScroll,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();
    expect(find.text('Report submitted'), findsOneWidget);
    expect(find.text('Report #1042'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Small screen renders home without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [photoServiceProvider.overrideWithValue(FakePhotos(photo))],
        child: const CareApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
