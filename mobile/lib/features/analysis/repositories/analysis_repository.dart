import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/app_failure.dart';
import '../models/detection_result.dart';
import '../services/waste_detection_service.dart';

class AnalysisRepository {
  final WasteDetectionService service;
  const AnalysisRepository(this.service);
  Future<void> validate(WastePhoto photo) async {
    final b = photo.bytes;
    if (b.isEmpty || b.length > AppConfig.maxImageBytes) {
      throw const AppFailure('Choose a photo under 10 MB.');
    }
    final jpeg = b.length > 3 && b[0] == 255 && b[1] == 216 && b[2] == 255;
    final png =
        b.length > 8 && b[0] == 137 && b[1] == 80 && b[2] == 78 && b[3] == 71;
    if (!jpeg && !png) {
      throw const AppFailure(
        'Choose a JPEG or PNG photo. Export HEIC photos as JPEG if your device does not convert them.',
      );
    }
    try {
      if (kIsWeb) {
        // Flutter's web ImageDescriptor does not expose encoded dimensions.
        final codec = await ui.instantiateImageCodec(b);
        try {
          final frame = await codec.getNextFrame();
          final pixels = frame.image.width * frame.image.height;
          frame.image.dispose();
          if (pixels > 24000000) {
            throw const AppFailure(
              'Choose a photo smaller than 24 megapixels.',
            );
          }
        } finally {
          codec.dispose();
        }
        return;
      }
      final buffer = await ui.ImmutableBuffer.fromUint8List(b);
      try {
        final descriptor = await ui.ImageDescriptor.encoded(buffer);
        try {
          if (descriptor.width * descriptor.height > 24000000) {
            throw const AppFailure(
              'Choose a photo smaller than 24 megapixels.',
            );
          }
          final codec = await descriptor.instantiateCodec(targetWidth: 256);
          try {
            final frame = await codec.getNextFrame();
            frame.image.dispose();
          } finally {
            codec.dispose();
          }
        } finally {
          descriptor.dispose();
        }
      } finally {
        buffer.dispose();
      }
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const AppFailure(
        'This image could not be read. Please choose another photo.',
      );
    }
  }

  Future<DetectionResult> analyze(
    WastePhoto photo,
    MockScenario scenario,
  ) async {
    await validate(photo);
    return service.analyze(photo, scenario);
  }
}
