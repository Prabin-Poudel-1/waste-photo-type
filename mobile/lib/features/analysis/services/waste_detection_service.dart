import '../models/detection_result.dart';

abstract interface class WasteDetectionService {
  Future<DetectionResult> analyze(WastePhoto photo, MockScenario scenario);
}
