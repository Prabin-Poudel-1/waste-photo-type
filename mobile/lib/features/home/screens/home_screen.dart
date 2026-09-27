import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/shared.dart';
import '../../analysis/controllers/analysis_controller.dart';
import '../../auth/auth_controller.dart';
import '../../reports/screens/my_reports_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: Text('Hello, ${ref.watch(authProvider).name ?? 'traveller'}'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const MyReportsScreen()),
          ),
          child: const Text('My Reports'),
        ),
        IconButton(
          tooltip: 'Log out',
          icon: const Icon(Icons.logout),
          onPressed: () => ref.read(authProvider.notifier).logout(),
        ),
      ],
    ),
    body: SafeArea(
      child: PageShell(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: forest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.eco_outlined, color: leaf),
                ),
                const SizedBox(width: 11),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'chitwan care',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: forest,
                          letterSpacing: -.5,
                        ),
                      ),
                      Text(
                        'SMALL ACTS. BETTER JOURNEYS.',
                        style: TextStyle(
                          fontSize: 8,
                          letterSpacing: 1.2,
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.landscape_outlined, color: forest),
              ],
            ),
            const SizedBox(height: 32),
            const Row(
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: forest),
                SizedBox(width: 5),
                Eyebrow('BHARATPUR · CHITWAN'),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Leave a place\nbetter than\nyou found it.',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 14),
            const Text(
              'Help care for the rivers, trails and cultural places that make every visit special.',
            ),
            const SizedBox(height: 24),
            Container(
              height: 184,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFFDBE7CF),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: CustomPaint(painter: LandscapePainter()),
                  ),
                  Positioned(
                    left: 18,
                    top: 17,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .8),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        'OUR PLACES. OUR RESPONSIBILITY.',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: forest,
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 20,
                    bottom: 18,
                    child: Text(
                      'A cleaner welcome.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: () => ref.read(analysisProvider.notifier).start(),
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Report Waste'),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                'Take a photo. Make a difference.',
                style: TextStyle(fontSize: 12, color: muted),
              ),
            ),
            const SizedBox(height: 29),
            const Text(
              'A simple act of care',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: forest,
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _Step(
                    Icons.camera_alt_outlined,
                    'Capture',
                    'Spot waste on your visit',
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _Step(
                    Icons.auto_awesome_outlined,
                    'Review',
                    'Check suggested categories',
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _Step(
                    Icons.fact_check_outlined,
                    'Prepare',
                    'Preview your report draft',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Notice(
              'On-device waste detection · Your photo and GPS are uploaded only when you submit a report.',
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'For visitors. For communities. For Chitwan.',
                style: TextStyle(fontSize: 11, color: muted),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Step extends StatelessWidget {
  final IconData icon;
  final String title, caption;
  const _Step(this.icon, this.title, this.caption);
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: forest, size: 23),
      const SizedBox(height: 9),
      Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: forest,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        caption,
        style: const TextStyle(fontSize: 11, height: 1.5, color: muted),
      ),
    ],
  );
}

class LandscapePainter extends CustomPainter {
  const LandscapePainter();
  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawCircle(
      Offset(s.width * .8, 45),
      26,
      Paint()..color = const Color(0xFFF4D99A),
    );
    final back = Path()
      ..moveTo(0, s.height * .65)
      ..quadraticBezierTo(s.width * .24, 25, s.width * .53, 95)
      ..quadraticBezierTo(s.width * .77, 30, s.width, 70)
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
    canvas.drawPath(back, Paint()..color = const Color(0xFF91AE83));
    final river = Path()
      ..moveTo(s.width * .52, 90)
      ..quadraticBezierTo(s.width * .27, 130, s.width * .77, s.height)
      ..lineTo(s.width * .45, s.height)
      ..quadraticBezierTo(s.width * .05, 130, s.width * .52, 90);
    canvas.drawPath(river, Paint()..color = const Color(0xFFA6CCBB));
    final front = Path()
      ..moveTo(0, 115)
      ..quadraticBezierTo(s.width * .18, 105, s.width * .42, s.height)
      ..lineTo(0, s.height)
      ..close();
    canvas.drawPath(front, Paint()..color = forest);
    for (final x in [s.width * .08, s.width * .16, s.width * .91]) {
      canvas.drawLine(
        Offset(x, 120),
        Offset(x, 74),
        Paint()
          ..color = forest
          ..strokeWidth = 3,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, 73), width: 28, height: 49),
        Paint()..color = const Color(0xFF3C6C50),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
