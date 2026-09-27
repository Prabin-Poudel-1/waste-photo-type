import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../models/detection_result.dart';

// Model output order: glass, metal, paper, plastic, trash.
// Display/store trash as miscellaneous; backend fallback category is other.
const wasteClasses = [
  'glass',
  'metal',
  'paper',
  'plastic',
  'miscellaneous',
];

const categoryCodes = [
  'glass',
  'metal',
  'paper',
  'plastic',
  'other',
];

final outputChannels = 4 + wasteClasses.length;

class Letterbox {
  final int width;
  final int height;
  final int resizedWidth;
  final int resizedHeight;
  final int padX;
  final int padY;
  final double scale;

  Letterbox(this.width, this.height)
      : scale = math.min(640 / width, 640 / height),
        resizedWidth =
        (width * math.min(640 / width, 640 / height))
            .round()
            .clamp(1, 640),
        resizedHeight =
        (height * math.min(640 / width, 640 / height))
            .round()
            .clamp(1, 640),
        padX =
        ((640 -
            (width * math.min(640 / width, 640 / height))
                .round()
                .clamp(1, 640)) /
            2)
            .floor(),
        padY =
        ((640 -
            (height * math.min(640 / width, 640 / height))
                .round()
                .clamp(1, 640)) /
            2)
            .floor();

  DetectionBox restore(
      double cx,
      double cy,
      double w,
      double h,
      ) {
    final sx = resizedWidth / width;
    final sy = resizedHeight / height;

    return DetectionBox(
      ((cx - w / 2) * 640 - padX)
          .clamp(0, resizedWidth)
          .toDouble() /
          sx,
      ((cy - h / 2) * 640 - padY)
          .clamp(0, resizedHeight)
          .toDouble() /
          sy,
      ((cx + w / 2) * 640 - padX)
          .clamp(0, resizedWidth)
          .toDouble() /
          sx,
      ((cy + h / 2) * 640 - padY)
          .clamp(0, resizedHeight)
          .toDouble() /
          sy,
    );
  }
}

class PreparedPhoto {
  final Uint8List input;
  final Uint8List preview;
  final Letterbox letterbox;

  PreparedPhoto(
      this.input,
      this.preview,
      this.letterbox,
      );
}

PreparedPhoto preparePhoto(Uint8List bytes) {
  if (bytes.length < 8 || bytes.length > 10 * 1024 * 1024) {
    throw const FormatException('Invalid image size');
  }

  img.Image? decoded;

  try {
    decoded = img.decodeImage(bytes);
  } catch (_) {
    throw const FormatException('Invalid image');
  }

  if (decoded == null || decoded.width * decoded.height > 24000000) {
    throw const FormatException('Unsupported image');
  }

  final upright = img.bakeOrientation(decoded);
  final geometry = Letterbox(upright.width, upright.height);

  final resized = img.copyResize(
    upright,
    width: geometry.resizedWidth,
    height: geometry.resizedHeight,
    interpolation: img.Interpolation.linear,
  );

  final floats = Float32List(3 * 640 * 640);
  floats.fillRange(0, floats.length, 114 / 255);

  for (var y = 0; y < resized.height; y++) {
    for (var x = 0; x < resized.width; x++) {
      final pixel = resized.getPixel(x, y);
      final index =
          (y + geometry.padY) * 640 + x + geometry.padX;
      final alpha = pixel.aNormalized;

      floats[index] =
          pixel.rNormalized * alpha + (1 - alpha) * 114 / 255;

      floats[640 * 640 + index] =
          pixel.gNormalized * alpha + (1 - alpha) * 114 / 255;

      floats[2 * 640 * 640 + index] =
          pixel.bNormalized * alpha + (1 - alpha) * 114 / 255;
    }
  }

  return PreparedPhoto(
    floats.buffer.asUint8List(),
    Uint8List.fromList(
      img.encodeJpg(upright, quality: 90),
    ),
    geometry,
  );
}

double boxIou(DetectionBox a, DetectionBox b) {
  final intersection =
      math.max(
        0.0,
        math.min(a.right, b.right) -
            math.max(a.left, b.left),
      ) *
          math.max(
            0.0,
            math.min(a.bottom, b.bottom) -
                math.max(a.top, b.top),
          );

  final union =
      (a.right - a.left) * (a.bottom - a.top) +
          (b.right - b.left) * (b.bottom - b.top) -
          intersection;

  return union <= 0 ? 0 : intersection / union;
}

List<WasteDetection> decodeYolo(
    Uint8List bytes,
    Letterbox geometry,
    ) {
  if (bytes.length != outputChannels * 8400 * 4) {
    throw const FormatException('Unexpected model output');
  }

  final values = ByteData.sublistView(bytes);

  double value(int channel, int index) {
    return values.getFloat32(
      (channel * 8400 + index) * 4,
      Endian.little,
    );
  }

  final candidates = <WasteDetection>[];

  for (var i = 0; i < 8400; i++) {
    var classIndex = 0;
    var score = value(4, i);

    for (var c = 1; c < wasteClasses.length; c++) {
      final classScore = value(c + 4, i);

      if (classScore > score) {
        score = classScore;
        classIndex = c;
      }
    }

    if (!score.isFinite || score < 0.25 || score > 1) {
      continue;
    }

    final cx = value(0, i);
    final cy = value(1, i);
    final width = value(2, i);
    final height = value(3, i);

    if (![cx, cy, width, height].every((v) => v.isFinite) ||
        width <= 0 ||
        height <= 0) {
      continue;
    }

    final box = geometry.restore(
      cx,
      cy,
      width,
      height,
    );

    if (box.right <= box.left || box.bottom <= box.top) {
      continue;
    }

    candidates.add(
      WasteDetection(
        categoryCode: categoryCodes[classIndex],
        label: wasteClasses[classIndex],
        confidence: score,
        box: box,
      ),
    );
  }

  candidates.sort(
        (a, b) => b.confidence.compareTo(a.confidence),
  );

  final selected = <WasteDetection>[];

  for (final candidate in candidates) {
    final overlapsExisting = selected.any(
          (detection) =>
      detection.label == candidate.label &&
          boxIou(detection.box!, candidate.box!) > 0.45,
    );

    if (overlapsExisting) {
      continue;
    }

    selected.add(candidate);

    // The report endpoint accepts at most 20 detections.
    if (selected.length == 20) {
      break;
    }
  }

  return selected;
}// Placeholder: paste the contents of mobile/lib/features/analysis/services/yolo_processing.dart from your app here.
