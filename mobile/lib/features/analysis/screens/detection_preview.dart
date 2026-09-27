// Placeholder: paste the contents of mobile/lib/features/analysis/screens/detection_preview.dart from your app here.
import 'package:flutter/material.dart';

import '../models/detection_result.dart';

Rect containImageRect(
    Size original,
    Size display,
    ) {
  final fitted = applyBoxFit(
    BoxFit.contain,
    original,
    display,
  );

  return Alignment.center.inscribe(
    fitted.destination,
    Offset.zero & display,
  );
}

Rect displayBox(
    DetectionBox box,
    Size original,
    Size display,
    ) {
  final image = containImageRect(original, display);

  return Rect.fromLTRB(
    image.left +
        box.left * image.width / original.width,
    image.top +
        box.top * image.height / original.height,
    image.left +
        box.right * image.width / original.width,
    image.top +
        box.bottom * image.height / original.height,
  );
}

class DetectionPreview extends StatelessWidget {
  final DetectionResult result;

  const DetectionPreview(
      this.result, {
        super.key,
      });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: 280,
        width: double.infinity,
        child: CustomPaint(
          foregroundPainter: DetectionBoxPainter(result),
          child: Image.memory(
            result.previewBytes!,
            fit: BoxFit.contain,
            semanticLabel:
            'Waste photo with ${result.detections.length} detected objects',
          ),
        ),
      ),
    );
  }
}

class DetectionBoxPainter extends CustomPainter {
  final DetectionResult result;

  DetectionBoxPainter(this.result);

  @override
  void paint(Canvas canvas, Size size) {
    final original = Size(
      result.imageWidth!.toDouble(),
      result.imageHeight!.toDouble(),
    );

    final paint = Paint()
      ..color = Colors.orangeAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final detection in result.detections) {
      if (detection.box == null) {
        continue;
      }

      final box = displayBox(
        detection.box!,
        original,
        size,
      );

      canvas.drawRect(box, paint);

      final text = TextPainter(
        text: TextSpan(
          text:
          '${detection.label} ${(detection.confidence * 100).round()}%',
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white,
            backgroundColor: Colors.black87,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width);

      text.paint(
        canvas,
        Offset(
          box.left.clamp(
            0,
            (size.width - text.width).clamp(
              0,
              size.width,
            ),
          ),
          (box.top - text.height).clamp(
            0,
            (size.height - text.height).clamp(
              0,
              size.height,
            ),
          ),
        ),
      );
    }
  }

  @override
  bool shouldRepaint(
      covariant DetectionBoxPainter oldDelegate,
      ) {
    return oldDelegate.result != result;
  }
}