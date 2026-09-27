import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/shared.dart';
import '../controllers/analysis_controller.dart';
import '../models/detection_result.dart';
import 'detection_preview.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analysisProvider);
    final result = state.result!;
    final controller = ref.read(analysisProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to photo',
          onPressed: controller.backToPhoto,
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text(
          'Detection results',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: PageShell(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            children: [
              const StepHeader(2),
              const SizedBox(height: 24),
              Eyebrow(
                result.isMock ? 'DEMONSTRATION RESULT' : 'ANALYSIS COMPLETE',
              ),
              const SizedBox(height: 12),
              Text(
                result.wasteDetected
                    ? 'Here’s what\nthe analysis suggests.'
                    : 'No waste detected.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                result.wasteDetected
                    ? 'Review these suggestions before preparing your report. AI confidence is not a guarantee.'
                    : 'This does not prove the area is clean. Try a closer, clearer photo, or choose another image.',
              ),
              const SizedBox(height: 20),
              if (result.previewBytes != null)
                DetectionPreview(result)
              else
                PhotoPreview(state.photo!, height: 180),
              const SizedBox(height: 18),
              if (result.isMock)
                const Notice(
                  'These are simulated results from development mode, not findings from your photo.',
                ),
              const SizedBox(height: 22),
              if (result.wasteDetected) ...[
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Suggested categories',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: forest,
                        ),
                      ),
                    ),
                    Text(
                      '${result.detections.length} found',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...result.detections.map((d) => DetectionCard(d)),
              ] else
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.search_off_outlined, size: 42, color: forest),
                      SizedBox(height: 12),
                      Text(
                        'No waste detected in this photo',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: forest,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Try a closer, clearer photo or choose another image.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: result.wasteDetected
                    ? controller.continueToReport
                    : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Continue to Report'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: controller.backToPhoto,
                child: const Text('Try another photo'),
              ),
              const SizedBox(height: 14),
              const Text(
                'Next: add location and submit a real report to the central system.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DetectionCard extends StatelessWidget {
  final WasteDetection detection;
  const DetectionCard(this.detection, {super.key});
  @override
  Widget build(BuildContext context) {
    final percent = (detection.confidence * 100).round();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF3E6),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.category_outlined,
                  color: forest,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  detection.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: forest,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: forest,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Semantics(
            label: '${detection.label}: $percent percent confidence',
            child: LinearProgressIndicator(
              value: detection.confidence,
              minHeight: 5,
              borderRadius: BorderRadius.circular(4),
              backgroundColor: line,
              color: detection.needsReview ? const Color(0xFFC18442) : forest,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            detection.needsReview
                ? 'Low confidence · manual review recommended'
                : 'Model confidence · review before reporting',
            style: TextStyle(
              fontSize: 10,
              color: detection.needsReview ? const Color(0xFF976025) : muted,
            ),
          ),
        ],
      ),
    );
  }
}
