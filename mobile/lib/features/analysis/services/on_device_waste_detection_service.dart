import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../core/errors/app_failure.dart';
import '../models/detection_result.dart';
import 'waste_detection_service.dart';
import 'yolo_processing.dart';

class OnDeviceWasteDetectionService implements WasteDetectionService {
  static const channel = MethodChannel('np.chitwancare/waste_inference');
  bool _busy = false;
  @override
  Future<DetectionResult> analyze(
    WastePhoto photo,
    MockScenario scenario,
  ) async {
    if (_busy) {
      throw const AppFailure('Analysis already running.');
    }
    _busy = true;
    try {
      final prepared = await compute(preparePhoto, photo.bytes);
      final output = await channel.invokeMethod<Uint8List>(
        'infer',
        prepared.input,
      );
      if (output == null) {
        throw const FormatException('No model output');
      }
      final detections = await compute(_decode, (output, prepared.letterbox));
      return DetectionResult(
        id: 'device-${DateTime.now().microsecondsSinceEpoch}',
        isMock: false,
        modelVersion: 'mira-exp019-a87e1887-litert2.1.5',
        detections: detections,
        imageWidth: prepared.letterbox.width,
        imageHeight: prepared.letterbox.height,
        previewBytes: prepared.preview,
      );
    } on MissingPluginException {
      throw const AppFailure(
        'On-device AI requires the Android app. Fully restart after installing this update.',
      );
    } on FormatException {
      throw const AppFailure(
        'The photo or model output could not be read. Try another JPEG or PNG photo.',
      );
    } catch (_) {
      throw const AppFailure(
        'On-device analysis could not finish. Please retry or choose another photo.',
      );
    } finally {
      _busy = false;
    }
  }

  static List<WasteDetection> _decode((Uint8List, Letterbox) data) =>
      decodeYolo(data.$1, data.$2);
}
