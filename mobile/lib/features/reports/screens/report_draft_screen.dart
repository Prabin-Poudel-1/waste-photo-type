// Placeholder: paste the contents of mobile/lib/features/reports/screens/report_draft_screen.dart from your app here.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/shared.dart';
import '../../analysis/controllers/analysis_controller.dart';
import '../../analysis/models/detection_result.dart';
import '../controllers/report_controller.dart';
import '../models/report_models.dart';
import '../services/location_service.dart';
import 'report_success_screen.dart';

class ReportDraftScreen
    extends ConsumerStatefulWidget {
  const ReportDraftScreen({super.key});

  @override
  ConsumerState<ReportDraftScreen> createState() =>
      _ReportDraftScreenState();
}

class _ReportDraftScreenState
    extends ConsumerState<ReportDraftScreen> {
  late final ReportController controller;

  final description = TextEditingController();
  final form = GlobalKey<FormState>();

  String severity = 'MEDIUM';
  bool confirmed = false;
  WasteCategory? manualCategory;

  @override
  void initState() {
    super.initState();

    controller = ReportController(
      ref.read(reportRepositoryProvider),
      ref.read(locationServiceProvider),
    );

    WidgetsBinding.instance.addPostFrameCallback(
          (_) {
        if (mounted) {
          controller.loadCatalog();
        }
      },
    );
  }

  @override
  void dispose() {
    controller.dispose();
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analysis = ref.watch(analysisProvider);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final report = controller;

        if (report.submitted != null) {
          return ReportSuccessScreen(
            report: report.submitted!,
          );
        }

        final detections =
            analysis.result!.detections;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Prepare report'),
            leading: IconButton(
              tooltip: 'Back to results',
              icon: const Icon(
                Icons.arrow_back,
              ),
              onPressed: report.submitting
                  ? null
                  : () => ref
                  .read(
                analysisProvider.notifier,
              )
                  .showResult(),
            ),
          ),
          body: SafeArea(
            child: PageShell(
              child: Form(
                key: form,
                child: ListView(
                  padding:
                  const EdgeInsets.all(24),
                  children: [
                    const Eyebrow(
                      'CARE FOR BHARATPUR · CHITWAN',
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Turn a moment of care\ninto action.',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium,
                    ),
                    const SizedBox(height: 20),
                    PhotoPreview(
                      analysis.photo!,
                      height: 210,
                    ),
                    const SizedBox(height: 16),
                    const Notice(
                      'Analysis runs on this Android device. Submitting sends the photo, location and report details to the development backend. Review the suggestions first.',
                    ),
                    _section(
                      'Waste identified',
                      Icons.category_outlined,
                      [
                        for (final detection
                        in detections)
                          Padding(
                            padding:
                            const EdgeInsets
                                .symmetric(
                              vertical: 5,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    detection.label,
                                  ),
                                ),
                                Text(
                                  '${(detection.confidence * 100).round()}%',
                                  style:
                                  const TextStyle(
                                    fontWeight:
                                    FontWeight
                                        .bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (detections.any(
                              (detection) =>
                          detection.needsReview,
                        ))
                          const Text(
                            'Low confidence: review the scene carefully before submitting.',
                          ),
                        if (detections.isEmpty) ...[
                          const Text(
                            'No waste detected. If you still see waste, choose a category for manual review. This is recorded with zero model confidence.',
                          ),
                          if (report.catalogReady)
                            DropdownButtonFormField<
                                int>(
                              isExpanded: true,
                              decoration:
                              const InputDecoration(
                                labelText:
                                'Manual review category',
                              ),
                              items: report
                                  .categories
                                  .map(
                                    (category) =>
                                    DropdownMenuItem(
                                      value:
                                      category.id,
                                      child: Text(
                                        category.name,
                                      ),
                                    ),
                              )
                                  .toList(),
                              onChanged:
                              report.submitting
                                  ? null
                                  : (id) =>
                                  setState(
                                        () {
                                      manualCategory = report
                                          .categories
                                          .firstWhere(
                                            (
                                            category,
                                            ) =>
                                        category
                                            .id ==
                                            id,
                                      );
                                    },
                                  ),
                              validator: (_) =>
                              manualCategory ==
                                  null
                                  ? 'Select a category for manual review.'
                                  : null,
                            ),
                        ],
                      ],
                    ),
                    if (report.loading)
                      const LinearProgressIndicator(),
                    if (report.catalogError !=
                        null) ...[
                      Notice(
                        report.catalogError!,
                        warning: true,
                      ),
                      TextButton(
                        onPressed:
                        report.loadCatalog,
                        child: const Text(
                          'Retry loading options',
                        ),
                      ),
                    ],
                    _section(
                      'Incident location',
                      Icons.my_location_outlined,
                      [
                        const Text(
                          'Capture location while you are at the waste incident. Selecting a destination does not change these coordinates.',
                        ),
                        const SizedBox(height: 10),
                        if (report.locating)
                          const LinearProgressIndicator(),
                        if (report.locating)
                          const Text(
                            'Getting location…',
                          ),
                        if (report.location !=
                            null) ...[
                          const Text(
                            'Location captured',
                            style: TextStyle(
                              color: forest,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${report.location!.latitude.toStringAsFixed(6)}, ${report.location!.longitude.toStringAsFixed(6)}',
                          ),
                          if (report
                              .location!
                              .accuracyMeters
                              .isFinite)
                            Text(
                              'Estimated accuracy: ${report.location!.accuracyMeters.round()} m',
                            ),
                        ],
                        if (report.locationError !=
                            null)
                          Notice(
                            report
                                .locationError!
                                .message,
                            warning: true,
                          ),
                        if (report.locationError !=
                            null &&
                            report
                                .locationError!
                                .recovery !=
                                LocationRecovery
                                    .retry)
                          TextButton(
                            onPressed: () async {
                              try {
                                final opened =
                                await report
                                    .locations
                                    .openSettings(
                                  report
                                      .locationError!
                                      .recovery,
                                );

                                if (context
                                    .mounted) {
                                  ScaffoldMessenger
                                      .of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        opened
                                            ? 'Return here and tap Retry location after changing settings.'
                                            : 'Open your device settings to enable location.',
                                      ),
                                    ),
                                  );
                                }
                              } catch (_) {
                                if (context
                                    .mounted) {
                                  ScaffoldMessenger
                                      .of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Open your device settings to enable location.',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text(
                              'Open settings',
                            ),
                          ),
                        OutlinedButton.icon(
                          onPressed:
                          report.locating ||
                              report
                                  .matching ||
                              report
                                  .submitting
                              ? null
                              : report.locate,
                          icon: const Icon(
                            Icons.gps_fixed,
                          ),
                          label: Text(
                            report.location ==
                                null &&
                                report
                                    .locationError ==
                                    null
                                ? 'Get current location'
                                : 'Retry location',
                          ),
                        ),
                      ],
                    ),
                    _section(
                      'Tourist destination',
                      Icons.place_outlined,
                      [
                        if (report.matching)
                          const LinearProgressIndicator(),
                        Text(
                          report.matching
                              ? 'Finding a registered tourist spot…'
                              : report.matchReady
                              ? report
                              .selectedSpot
                              ?.name ??
                              (report
                                  .manualSpot
                                  ? 'No tourist spot selected.'
                                  : 'No registered tourist spot detected near this location.')
                              : 'Capture GPS to check nearby registered tourist spots.',
                        ),
                        if (report.matchError !=
                            null) ...[
                          Notice(
                            report.matchError!,
                            warning: true,
                          ),
                          TextButton(
                            onPressed: report.match,
                            child: const Text(
                              'Retry tourist-spot matching',
                            ),
                          ),
                        ],
                        if (report.catalogReady &&
                            report.location !=
                                null &&
                            !report.matching) ...[
                          const SizedBox(
                            height: 12,
                          ),
                          DropdownButtonFormField<
                              int>(
                            key: ValueKey(
                              report.selectedSpot
                                  ?.id ??
                                  0,
                            ),
                            initialValue: report
                                .selectedSpot
                                ?.id ??
                                0,
                            isExpanded: true,
                            decoration:
                            const InputDecoration(
                              labelText:
                              'Confirm or change destination',
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: 0,
                                child: Text(
                                  'No registered tourist spot',
                                ),
                              ),
                              ...report.spots.map(
                                    (spot) =>
                                    DropdownMenuItem(
                                      value: spot.id,
                                      child: Text(
                                        spot.name,
                                      ),
                                    ),
                              ),
                            ],
                            onChanged:
                            report.submitting
                                ? null
                                : (id) =>
                                report.selectSpot(
                                  id == 0
                                      ? null
                                      : id,
                                ),
                          ),
                          if (!report.matchReady)
                            TextButton(
                              onPressed: () =>
                                  report.selectSpot(
                                    null,
                                  ),
                              child: const Text(
                                'Continue without a tourist spot',
                              ),
                            ),
                          const SizedBox(height: 8),
                          const Text(
                            'Manual selection changes the destination association only. GPS stays unchanged.',
                            style: TextStyle(
                              fontSize: 12,
                              color: muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                    _section(
                      'Report details',
                      Icons.edit_note,
                      [
                        TextFormField(
                          controller: description,
                          enabled:
                          !report.submitting,
                          maxLength: 2000,
                          maxLines: 3,
                          decoration:
                          const InputDecoration(
                            labelText:
                            'Description (optional)',
                            hintText:
                            'What should the reviewing team know?',
                          ),
                          validator: (value) =>
                          (value?.length ??
                              0) >
                              2000
                              ? 'Use at most 2,000 characters.'
                              : null,
                        ),
                        const SizedBox(
                          height: 14,
                        ),
                        DropdownButtonFormField<
                            String>(
                          initialValue: severity,
                          isExpanded: true,
                          decoration:
                          const InputDecoration(
                            labelText: 'Severity',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'LOW',
                              child: Text(
                                'Low · small amount',
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'MEDIUM',
                              child: Text(
                                'Medium · needs attention',
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'HIGH',
                              child: Text(
                                'High · significant waste',
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'CRITICAL',
                              child: Text(
                                'Critical · urgent review',
                              ),
                            ),
                          ],
                          onChanged:
                          report.submitting
                              ? null
                              : (value) =>
                              setState(
                                    () => severity =
                                value!,
                              ),
                        ),
                        Material(
                          color:
                          Colors.transparent,
                          child:
                          CheckboxListTile(
                            contentPadding:
                            EdgeInsets.zero,
                            value: confirmed,
                            title: const Text(
                              'I reviewed the photo and suggestions and want to submit this report.',
                            ),
                            onChanged:
                            report.submitting
                                ? null
                                : (value) =>
                                setState(
                                      () =>
                                  confirmed =
                                      value ??
                                          false,
                                ),
                          ),
                        ),
                      ],
                    ),
                    if (report.submitError !=
                        null)
                      Notice(
                        report.submitError!,
                        warning: true,
                      ),
                    if (report.submitting) ...[
                      LinearProgressIndicator(
                        value: report.progress,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Uploading report… Please keep this screen open.',
                        textAlign:
                        TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed:
                      !report.canSubmit ||
                          !confirmed
                          ? null
                          : () {
                        if (!form
                            .currentState!
                            .validate()) {
                          return;
                        }

                        final entries =
                        detections
                            .isNotEmpty
                            ? detections
                            : [
                          WasteDetection(
                            categoryCode:
                            manualCategory!
                                .code,
                            label:
                            'Manual review: ${manualCategory!.name}',
                            confidence:
                            0,
                          ),
                        ];

                        report.submit(
                          analysis.photo!,
                          entries,
                          description.text,
                          severity,
                        );
                      },
                      icon: const Icon(
                        Icons
                            .cloud_upload_outlined,
                      ),
                      label: Text(
                        report.submitting
                            ? 'Submitting…'
                            : 'Submit report',
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'The central system stores your report for review. No department assignment is made yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _section(
      String title,
      IconData icon,
      List<Widget> children,
      ) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: line),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: forest,
                size: 21,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: forest,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}