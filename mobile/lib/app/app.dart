// Placeholder: paste the contents of mobile/lib/app/app.dart from your app here.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme.dart';
import '../features/authority/authority_screen.dart';
import '../features/analysis/controllers/analysis_controller.dart';
import '../features/home/screens/tourist_shell.dart';
import '../features/analysis/screens/capture_screen.dart';
import '../features/analysis/screens/analyzing_screen.dart';
import '../features/analysis/screens/result_screen.dart';
import '../features/reports/screens/report_draft_screen.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/auth_screen.dart';

class CareApp extends ConsumerStatefulWidget {
  const CareApp({super.key});

  @override
  ConsumerState<CareApp> createState() => _CareAppState();
}

class _CareAppState extends ConsumerState<CareApp> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(analysisProvider.notifier).recover();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    ref.listen(authProvider.select((s) => s.userId), (previous, next) {
      if (previous != null && previous != next) {
        ref.read(analysisProvider.notifier).home();
      }
    });

    final step = ref.watch(analysisProvider.select((s) => s.step));
    final controller = ref.read(analysisProvider.notifier);

    return MaterialApp(
      key: ValueKey(auth.userId),
      title: 'Chitwan Care',
      debugShowCheckedModeBanner: false,
      theme: careTheme(),
      home: auth.restoring
          ? const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      )
          : auth.token == null
          ? const AuthScreen()
          : auth.isAuthority
          ? const AuthorityHomeScreen()
          : PopScope(
        canPop: step == FlowStep.home,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;

          switch (step) {
            case FlowStep.capture:
              controller.home();

            case FlowStep.analyzing:
            case FlowStep.result:
              controller.backToPhoto();

            case FlowStep.draft:
            // The form owns navigation so system back cannot
            // lose an in-flight submission.
              break;

            case FlowStep.home:
              break;
          }
        },
        child: switch (step) {
          FlowStep.home => const TouristShell(),
          FlowStep.capture => const CaptureScreen(),
          FlowStep.analyzing => const AnalyzingScreen(),
          FlowStep.result => const ResultScreen(),
          FlowStep.draft => const ReportDraftScreen(),
        },
      ),
    );
  }
}