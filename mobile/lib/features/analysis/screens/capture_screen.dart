import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/shared.dart';
import '../controllers/analysis_controller.dart';

class CaptureScreen extends ConsumerWidget {
  const CaptureScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analysisProvider);
    final controller = ref.read(analysisProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to home',
          icon: const Icon(Icons.arrow_back),
          onPressed: state.picking ? null : controller.home,
        ),
        title: const Text(
          'Report waste',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: PageShell(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            children: [
              const StepHeader(0),
              const SizedBox(height: 26),
              Text(
                state.photo == null
                    ? 'Start with a photo.'
                    : 'A clearer picture.\nA better response.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              const Text(
                'Photograph waste at a visitor site, riverside or trail. Stay at a safe distance; do not touch hazardous material.',
              ),
              const SizedBox(height: 22),
              if (state.photo != null)
                PhotoPreview(state.photo!)
              else
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9EEDF),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFD0DBBF)),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.center_focus_strong_outlined,
                        size: 66,
                        color: forest,
                      ),
                      SizedBox(height: 18),
                      Text(
                        'Show the scene, not just the waste',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: forest,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Good light · Clear view · Safe distance',
                        style: TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: state.picking
                    ? null
                    : () => controller.pick(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(
                  state.photo == null ? 'Take a photo' : 'Retake photo',
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: state.picking
                    ? null
                    : () => controller.pick(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Choose from gallery'),
              ),
              if (state.picking)
                const Padding(
                  padding: EdgeInsets.all(18),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Semantics(
                    liveRegion: true,
                    child: Column(
                      children: [
                        Notice(state.error!.message, warning: true),
                        if (state.error!.permissionDenied)
                          TextButton(
                            onPressed: () async {
                              final opened = await openAppSettings();
                              if (!opened && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Open your device settings and enable camera or photo access for Chitwan Care.',
                                    ),
                                  ),
                                );
                              }
                            },
                            child: const Text('Open device settings'),
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              const Notice(
                'Analysis runs on this Android device. Your photo is uploaded only when you submit a report.',
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: state.photo == null || state.picking
                    ? null
                    : controller.analyze,
                icon: const Icon(Icons.auto_awesome_outlined),
                label: const Text('Analyze photo'),
              ),
              const SizedBox(height: 12),
              const Text(
                'JPEG or PNG · Up to 10 MB\nCamera and photo access are requested only when needed.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
