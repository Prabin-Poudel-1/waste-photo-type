// Placeholder: paste the contents of mobile/lib/features/reports/screens/report_success_screen.dart from your app here.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/shared.dart';
import '../../analysis/controllers/analysis_controller.dart';
import '../models/report_models.dart';

class ReportSuccessScreen
    extends ConsumerWidget {
  final SubmittedReport report;

  const ReportSuccessScreen({
    super.key,
    required this.report,
  });

  @override
  Widget build(
      BuildContext context,
      WidgetRef ref,
      ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Report submitted',
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: PageShell(
          child: ListView(
            padding: const EdgeInsets.all(28),
            children: [
              const SizedBox(height: 32),
              const Icon(
                Icons.check_circle_outline,
                size: 76,
                color: forest,
              ),
              const SizedBox(height: 24),
              Text(
                'Thank you for helping\nkeep Chitwan clean.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium,
              ),
              const SizedBox(height: 28),
              Card(
                child: Padding(
                  padding:
                  const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Report #${report.id}',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Chip(
                        label: Text(
                          report.status,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        report.touristSpotName ??
                            'No registered tourist spot associated',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Submitted: ${report.createdAt.toLocal()}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Your report and photo have been saved in the central system for review. Keep your report ID for reference.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: ref
                    .read(
                  analysisProvider.notifier,
                )
                    .home,
                child: const Text(
                  'Back to Home',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}