import 'dart:io';
import 'dart:typed_data';

import 'package:chitwan_care/features/analysis/controllers/analysis_controller.dart';
import 'package:chitwan_care/features/analysis/models/detection_result.dart';
import 'package:chitwan_care/features/analysis/screens/detection_preview.dart';
import 'package:chitwan_care/features/analysis/services/on_device_waste_detection_service.dart';
import 'package:chitwan_care/features/analysis/services/yolo_processing.dart';
import 'package:chitwan_care/features/capture/services/photo_service.dart';
import 'package:chitwan_care/features/reports/models/report_models.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

Uint8List output() {
  return Uint8List(
    outputChannels * 8400 * 4,
  );
}

void candidate(
    Uint8List bytes,
    int index,
    int cls,
    double confidence, {
      double cx = .5,
      double cy = .5,
      double w = .2,
      double h = .2,
    }) {
  final data = ByteData.sublistView(bytes);

  for (final entry in [
    cx,
    cy,
    w,
    h,
  ].asMap().entries) {
    data.setFloat32(
      (entry.key * 8400 + index) * 4,
      entry.value,
      Endian.little,
    );
  }

  data.setFloat32(
    ((cls + 4) * 8400 + index) * 4,
    confidence,
    Endian.little,
  );
}

Uint8List photo() {
  final image = img.Image(
    width: 100,
    height: 50,
  );

  img.fill(
    image,
    color: img.ColorRgb8(
      255,
      0,
      0,
    ),
  );

  return Uint8List.fromList(
    img.encodePng(image),
  );
}

class Photos implements PhotoService {
  ImageSource? last;

  @override
  Future<WastePhoto?> pick(
      ImageSource source,
      ) async {
    last = source;

    return WastePhoto(
      bytes: photo(),
      name: 'photo.png',
      selectedAt: DateTime.now(),
    );
  }

  @override
  Future<WastePhoto?> recover() async {
    return null;
  }
}

void main() {
  TestWidgetsFlutterBinding
      .ensureInitialized();

  test(
    'bundled model equals supplied model byte for byte',
        () {
      expect(
        File(
          'android/app/src/main/assets/chitwan_care_waste_model.tflite',
        ).readAsBytesSync(),
        File(
          '/Users/prabinpoudel/Downloads/chitwan_care_waste_model.tflite',
        ).readAsBytesSync(),
      );
    },
  );

  test(
    'RGB float NCHW and letterbox padding preserve aspect ratio',
        () {
      final prepared =
      preparePhoto(photo());

      final data =
      ByteData.sublistView(
        prepared.input,
      );

      expect(
        prepared.letterbox.padY,
        160,
      );

      expect(
        prepared.letterbox.padX,
        0,
      );

      expect(
        data.getFloat32(
          0,
          Endian.little,
        ),
        closeTo(114 / 255, 1e-6),
      );

      expect(
        data.getFloat32(
          160 * 640 * 4,
          Endian.little,
        ),
        1,
      );

      expect(
        data.getFloat32(
          (640 * 640 + 160 * 640) * 4,
          Endian.little,
        ),
        0,
      );

      expect(
        img.decodeJpg(
          prepared.preview,
        )!
            .width,
        100,
      );
    },
  );

  test(
    'EXIF orientation is baked before geometry and preview',
        () {
      final image = img.Image(
        width: 80,
        height: 40,
      );

      image.exif.imageIfd.orientation = 6;

      final prepared = preparePhoto(
        Uint8List.fromList(
          img.encodeJpg(image),
        ),
      );

      expect(
        prepared.letterbox.width,
        40,
      );

      expect(
        prepared.letterbox.height,
        80,
      );
    },
  );

  test(
    'threshold, highest class and class-aware NMS',
        () {
      final bytes = output();

      candidate(bytes, 0, 3, .9);
      candidate(bytes, 1, 3, .8);
      candidate(bytes, 2, 0, .85);
      candidate(bytes, 3, 0, .24);

      final detections = decodeYolo(
        bytes,
        Letterbox(640, 640),
      );

      expect(
        detections.map(
              (detection) => detection.label,
        ),
        [
          'plastic',
          'glass',
        ],
      );

      expect(
        decodeYolo(
          output(),
          Letterbox(640, 640),
        ),
        isEmpty,
      );

      candidate(
        bytes,
        4,
        4,
        .25,
        cx: .1,
        cy: .1,
        w: .05,
        h: .05,
      );

      expect(
        decodeYolo(
          bytes,
          Letterbox(640, 640),
        ).length,
        3,
      );
    },
  );

  test(
    'letterbox inverse returns original coordinates and clamps padding',
        () {
      final letterbox =
      Letterbox(1000, 500);

      final box = letterbox.restore(
        .5,
        .5,
        .5,
        .25,
      );

      expect(box.left, 250);
      expect(box.top, 125);
      expect(box.right, 750);
      expect(box.bottom, 375);

      final clamped =
      letterbox.restore(
        .5,
        .5,
        2,
        2,
      );

      expect(clamped.left, 0);
      expect(clamped.bottom, 500);

      final portrait =
      Letterbox(333, 777);

      final whole = portrait.restore(
        .5,
        .5,
        1,
        1,
      );

      expect(
        whole.right,
        closeTo(333, 1e-6),
      );

      expect(
        whole.bottom,
        closeTo(777, 1e-6),
      );
    },
  );

  test(
    'contain rendering includes vertical and horizontal offsets',
        () {
      expect(
        displayBox(
          const DetectionBox(
            0,
            0,
            1000,
            500,
          ),
          const Size(1000, 500),
          const Size(300, 300),
        ),
        const Rect.fromLTWH(
          0,
          75,
          300,
          150,
        ),
      );

      expect(
        displayBox(
          const DetectionBox(
            0,
            0,
            500,
            1000,
          ),
          const Size(500, 1000),
          const Size(300, 300),
        ),
        const Rect.fromLTWH(
          75,
          0,
          150,
          300,
        ),
      );
    },
  );

  test(
    'real detections preserve category and metadata compatibility',
        () {
      expect(
        wasteClasses,
        [
          'glass',
          'metal',
          'paper',
          'plastic',
          'miscellaneous',
        ],
      );

      expect(outputChannels, 9);
      expect(categoryCodes[4], 'other');

      final bytes = output();

      for (var cls = 0;
      cls < wasteClasses.length;
      cls++) {
        candidate(
          bytes,
          cls,
          cls,
          .9,
          cx:
          (cls + .5) /
              wasteClasses.length,
          w: .08,
        );
      }

      final detections = decodeYolo(
        bytes,
        Letterbox(640, 640),
      );

      final categories = [
        const WasteCategory(
          1,
          'paper',
          'Paper/Cardboard',
        ),
        const WasteCategory(
          2,
          'other',
          'Other',
        ),
        const WasteCategory(
          3,
          'plastic',
          'Plastic',
        ),
      ];

      expect(
        mapCategory(
          detections.firstWhere(
                (detection) =>
            detection.label ==
                'paper',
          ),
          categories,
        ).code,
        'paper',
      );

      expect(
        mapCategory(
          detections.firstWhere(
                (detection) =>
            detection.label ==
                'miscellaneous',
          ),
          categories,
        ).code,
        'other',
      );

      expect(
        detections.length,
        wasteClasses.length,
      );

      expect(
        detections.every(
              (detection) =>
          detection.box != null,
        ),
        isTrue,
      );
    },
  );

  test(
    'invalid image and wrong output are rejected',
        () {
      expect(
            () =>
            preparePhoto(Uint8List(0)),
        throwsFormatException,
      );

      expect(
            () => decodeYolo(
          Uint8List(4),
          Letterbox(100, 100),
        ),
        throwsFormatException,
      );
    },
  );

  for (final source
  in ImageSource.values) {
    test(
      '${source.name} uses production real detector and existing draft',
          () async {
        final bytes = output();

        candidate(
          bytes,
          0,
          3,
          .9,
        );

        var calls = 0;

        TestDefaultBinaryMessengerBinding
            .instance
            .defaultBinaryMessenger
            .setMockMethodCallHandler(
          OnDeviceWasteDetectionService
              .channel,
              (call) async {
            calls++;

            expect(
              call.method,
              'infer',
            );

            expect(
              (call.arguments as Uint8List)
                  .length,
              3 * 640 * 640 * 4,
            );

            return bytes;
          },
        );

        final picker = Photos();

        final container =
        ProviderContainer(
          overrides: [
            photoServiceProvider
                .overrideWithValue(
              picker,
            ),
          ],
        );

        try {
          expect(
            container.read(
              detectionServiceProvider,
            ),
            isA<
                OnDeviceWasteDetectionService>(),
          );

          final controller =
          container.read(
            analysisProvider.notifier,
          );

          await controller.pick(source);

          await Future.wait([
            controller.analyze(),
            controller.analyze(),
          ]);

          expect(calls, 1);
          expect(picker.last, source);

          final result =
          container
              .read(analysisProvider)
              .result!;

          expect(result.isMock, isFalse);

          expect(
            result
                .detections
                .single
                .label,
            'plastic',
          );

          controller.continueToReport();

          expect(
            container
                .read(analysisProvider)
                .step,
            FlowStep.draft,
          );

          expect(
            container
                .read(analysisProvider)
                .photo!
                .bytes,
            photo(),
          );
        } finally {
          container.dispose();

          TestDefaultBinaryMessengerBinding
              .instance
              .defaultBinaryMessenger
              .setMockMethodCallHandler(
            OnDeviceWasteDetectionService
                .channel,
            null,
          );
        }
      },
    );
  }
}// Placeholder: paste the contents of mobile/test/phase6/detector_test.dart from your app here.
