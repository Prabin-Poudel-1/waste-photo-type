import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../features/analysis/models/detection_result.dart';

class PageShell extends StatelessWidget {
  final Widget child;

  const PageShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: child,
    ),
  );
}

class Eyebrow extends StatelessWidget {
  final String text;

  const Eyebrow(
      this.text, {
        super.key,
      });

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.8,
      color: muted,
    ),
  );
}

class Notice extends StatelessWidget {
  final String text;
  final bool warning;

  const Notice(
      this.text, {
        super.key,
        this.warning = false,
      });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: warning
          ? const Color(0xFFFFEEDC)
          : const Color(0xFFE9F0DE),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          warning
              ? Icons.info_outline
              : Icons.science_outlined,
          size: 19,
          color: forest,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: forest,
            ),
          ),
        ),
      ],
    ),
  );
}

class PhotoPreview extends StatelessWidget {
  final WastePhoto photo;
  final double height;

  const PhotoPreview(
      this.photo, {
        super.key,
        this.height = 250,
      });

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(22),
    child: Image.memory(
      photo.bytes,
      width: double.infinity,
      height: height,
      fit: BoxFit.cover,
      semanticLabel: 'Your selected waste incident photo',
      errorBuilder: (_, error, stack) => const SizedBox(
        height: 160,
        child: Center(
          child: Text(
            'Photo preview unavailable. Please select another image.',
          ),
        ),
      ),
    ),
  );
}

class StepHeader extends StatelessWidget {
  final int current;

  const StepHeader(
      this.current, {
        super.key,
      });

  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(
      3,
          (i) => Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 3,
                decoration: BoxDecoration(
                  color: i <= current ? forest : line,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 9),
              Text(
                [
                  '01  PHOTO',
                  '02  ANALYSIS',
                  '03  REVIEW',
                ][i],
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: .7,
                  fontWeight: FontWeight.bold,
                  color: i <= current ? forest : muted,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}// Placeholder: paste the contents of mobile/lib/core/widgets/shared.dart from your app here.
