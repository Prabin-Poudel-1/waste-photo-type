import '../../../core/errors/app_failure.dart';
import '../models/detection_result.dart';
import 'waste_detection_service.dart';

class MockWasteDetectionService implements WasteDetectionService {
  final Duration delay;
  const MockWasteDetectionService({
    this.delay = const Duration(milliseconds: 1800),
  });
  @override
  Future<DetectionResult> analyze(
    WastePhoto photo,
    MockScenario scenario,
  ) async {
    await Future<void>.delayed(delay);
    if (scenario == MockScenario.error) {
      throw const AppFailure(
        'Simulated analysis outage. Your photo is still here. Choose another demo scenario and try again.',
      );
    }
    final detections = switch (scenario) {
      MockScenario.multiple => const [
        WasteDetection(
          categoryCode: 'plastic',
          label: 'Plastic',
          confidence: .94,
        ),
        WasteDetection(
          categoryCode: 'organic',
          label: 'Organic',
          confidence: .82,
        ),
        WasteDetection(
          categoryCode: 'paper',
          label: 'Paper / cardboard',
          confidence: .71,
        ),
      ],
      MockScenario.low => const [
        WasteDetection(
          categoryCode: 'mixed',
          label: 'Mixed waste',
          confidence: .43,
        ),
      ],
      _ => <WasteDetection>[],
    };
    return DetectionResult(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      isMock: true,
      modelVersion: 'mock-v1',
      detections: detections,
    );
  }
}
