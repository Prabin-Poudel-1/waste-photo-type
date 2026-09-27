import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/config/app_config.dart';
import '../../../core/widgets/shared.dart';
import '../controllers/analysis_controller.dart';

class AnalyzingScreen extends ConsumerWidget {
  const AnalyzingScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analysisProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo analysis'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: PageShell(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const StepHeader(1),
              const SizedBox(height: 30),
              if (state.photo != null)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    PhotoPreview(state.photo!, height: 240),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: canvas.withValues(alpha: .95),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const CircularProgressIndicator(),
                    ),
                  ],
                ),
              const SizedBox(height: 30),
              Semantics(
                liveRegion: true,
                child: Text(
                  'Preparing your\ndetection results…',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                AppConfig.analysisMode == 'device'
                    ? 'Analyzing your photo on this device. Nothing is being uploaded.'
                    : AppConfig.analysisMode == 'api'
                    ? 'Sending your photo to the local analysis service.'
                    : 'Preparing simulated results. This mode does not identify your photo.',
              ),
              const SizedBox(height: 24),
              const Notice(
                AppConfig.analysisMode == 'device'
                    ? 'On-device waste detection · Please wait.'
                    : 'Development analysis · Please wait.',
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: ref.read(analysisProvider.notifier).backToPhoto,
                child: const Text('Back to photo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
