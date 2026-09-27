import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/app_failure.dart';
import '../../analysis/models/detection_result.dart';

abstract interface class PhotoService {
  Future<WastePhoto?> pick(ImageSource source);
  Future<WastePhoto?> recover();
}

class DevicePhotoService implements PhotoService {
  final ImagePicker picker;
  DevicePhotoService(this.picker);
  Future<WastePhoto> read(XFile file) async {
    if (await file.length() > AppConfig.maxImageBytes) {
      throw const AppFailure('Choose a photo under 10 MB.');
    }
    return WastePhoto(
      bytes: await file.readAsBytes(),
      name: file.name,
      selectedAt: DateTime.now(),
    );
  }

  @override
  Future<WastePhoto?> pick(ImageSource source) async {
    try {
      final file = await picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      return file == null ? null : await read(file);
    } on PlatformException catch (e) {
      if (e.code.toLowerCase().contains('denied') ||
          e.code.toLowerCase().contains('restricted')) {
        throw const AppFailure(
          'Photo access was denied. Enable access in your device settings, or choose another photo source.',
          permissionDenied: true,
        );
      }
      throw const AppFailure(
        'The camera or photo picker could not open. Try the gallery, or check device permissions.',
      );
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const AppFailure('We could not load that photo. Please try again.');
    }
  }

  @override
  Future<WastePhoto?> recover() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      final response = await picker.retrieveLostData();
      if (response.exception != null) {
        throw const AppFailure(
          'Your last photo could not be recovered. Please select it again.',
        );
      }
      if (response.files?.isNotEmpty == true) {
        return await read(response.files!.first);
      }
      return null;
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const AppFailure('Please select your photo again to continue.');
    }
  }
}
