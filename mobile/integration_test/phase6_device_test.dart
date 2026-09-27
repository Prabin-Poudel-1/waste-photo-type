import 'dart:typed_data';

import 'package:chitwan_care/features/analysis/models/detection_result.dart';
import 'package:chitwan_care/features/analysis/services/on_device_waste_detection_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding
      .ensureInitialized();

  testWidgets(
    'bundled model executes and is reusable through Android bridge',
        (tester) async {
      final image = img.Image(
        width: 320,
        height: 180,
      );

      img.fill(
        image,
        color: img.ColorRgb8(
          128,
          128,
          128,
        ),
      );

      final photo = WastePhoto(
        bytes: Uint8List.fromList(
          img.encodePng(image),
        ),
        name: 'synthetic.png',
        selectedAt: DateTime.now(),
      );

      final service =
      OnDeviceWasteDetectionService();

      for (var run = 0; run < 2; run++) {
        final result =
        await service.analyze(
          photo,
          MockScenario.multiple,
        );

        expect(result.isMock, isFalse);
        expect(result.imageWidth, 320);
        expect(result.imageHeight, 180);

        expect(
          result.modelVersion,
          contains('litert2.1.5'),
        );

        for (final detection
        in result.detections) {
          expect(
            detection.confidence,
            inInclusiveRange(.25, 1),
          );

          expect(
            detection.box!.left,
            inInclusiveRange(0, 320),
          );

          expect(
            detection.box!.bottom,
             inInclusiveRange(0, 180),
          );
        }
      }
    },
  );
}// Placeholder: paste the contents of mobile/integration_test/phase6_device_test.dart from your app here.
