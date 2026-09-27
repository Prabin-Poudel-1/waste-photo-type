// Placeholder: paste the contents of mobile/lib/features/analysis/controllers/analysis_controller.dart from your app here.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/errors/app_failure.dart';
import '../../capture/services/photo_service.dart';
import '../models/detection_result.dart';
import '../repositories/analysis_repository.dart';
import '../services/on_device_waste_detection_service.dart';
import '../services/waste_detection_service.dart';

final photoServiceProvider = Provider<PhotoService>(
      (ref) => DevicePhotoService(ImagePicker()),
);

final detectionServiceProvider = Provider<WasteDetectionService>(
      (ref) => OnDeviceWasteDetectionService(),
);

final repositoryProvider = Provider(
      (ref) => AnalysisRepository(
    ref.watch(detectionServiceProvider),
  ),
);

enum FlowStep {
  home,
  capture,
  analyzing,
  result,
  draft,
}

class AnalysisState {
  final FlowStep step;
  final WastePhoto? photo;
  final DetectionResult? result;
  final MockScenario scenario;
  final AppFailure? error;
  final bool picking;

  const AnalysisState({
    this.step = FlowStep.home,
    this.photo,
    this.result,
    this.scenario = MockScenario.multiple,
    this.error,
    this.picking = false,
  });
}

final analysisProvider =
NotifierProvider<AnalysisController, AnalysisState>(
  AnalysisController.new,
);

class AnalysisController extends Notifier<AnalysisState> {
  int _generation = 0;
  bool _disposed = false;

  @override
  AnalysisState build() {
    ref.onDispose(() {
      _disposed = true;
      _generation++;
    });

    return const AnalysisState();
  }

  void start() {
    state = AnalysisState(
      step: FlowStep.capture,
      photo: state.photo,
      scenario: state.scenario,
    );
  }

  void home() {
    _generation++;
    state = const AnalysisState();
  }

  void changeScenario(MockScenario scenario) {
    state = AnalysisState(
      step: FlowStep.capture,
      photo: state.photo,
      scenario: scenario,
    );
  }

  void backToPhoto() {
    _generation++;

    state = AnalysisState(
      step: FlowStep.capture,
      photo: state.photo,
      scenario: state.scenario,
    );
  }

  void showResult() {
    if (state.result == null) {
      return;
    }

    state = AnalysisState(
      step: FlowStep.result,
      photo: state.photo,
      result: state.result,
      scenario: state.scenario,
    );
  }

  void continueToReport() {
    if (state.result == null) {
      return;
    }

    state = AnalysisState(
      step: FlowStep.draft,
      photo: state.photo,
      result: state.result,
      scenario: state.scenario,
    );
  }

  Future<void> recover() async {
    final generation = _generation;

    try {
      final photo = await ref.read(photoServiceProvider).recover();

      if (_disposed ||
          generation != _generation ||
          photo == null) {
        return;
      }

      await ref.read(repositoryProvider).validate(photo);

      if (!_disposed && generation == _generation) {
        state = AnalysisState(
          step: FlowStep.capture,
          photo: photo,
        );
      }
    } on AppFailure catch (error) {
      if (!_disposed && generation == _generation) {
        state = AnalysisState(
          step: FlowStep.capture,
          error: error,
        );
      }
    }
  }

  Future<void> pick(ImageSource source) async {
    if (state.picking || state.step == FlowStep.analyzing) {
      return;
    }

    final generation = ++_generation;
    final previous = state;

    state = AnalysisState(
      step: FlowStep.capture,
      photo: previous.photo,
      scenario: previous.scenario,
      picking: true,
    );

    try {
      final photo = await ref
          .read(photoServiceProvider)
          .pick(source);

      if (_disposed || generation != _generation) {
        return;
      }

      if (photo != null) {
        await ref.read(repositoryProvider).validate(photo);
      }

      if (!_disposed && generation == _generation) {
        state = AnalysisState(
          step: FlowStep.capture,
          photo: photo ?? previous.photo,
          scenario: previous.scenario,
        );
      }
    } catch (error) {
      if (!_disposed && generation == _generation) {
        state = AnalysisState(
          step: FlowStep.capture,
          photo: previous.photo,
          scenario: previous.scenario,
          error: error is AppFailure
              ? error
              : const AppFailure(
            'Could not load the photo. Please try again.',
          ),
        );
      }
    }
  }

  Future<void> analyze() async {
    if (state.photo == null ||
        state.picking ||
        state.step == FlowStep.analyzing) {
      return;
    }

    final photo = state.photo!;
    final scenario = state.scenario;
    final generation = ++_generation;

    state = AnalysisState(
      step: FlowStep.analyzing,
      photo: photo,
      scenario: scenario,
    );

    try {
      final result = await ref
          .read(repositoryProvider)
          .analyze(photo, scenario);

      if (!_disposed && generation == _generation) {
        state = AnalysisState(
          step: FlowStep.result,
          photo: photo,
          result: result,
          scenario: scenario,
        );
      }
    } catch (error) {
      if (!_disposed && generation == _generation) {
        state = AnalysisState(
          step: FlowStep.capture,
          photo: photo,
          scenario: scenario,
          error: error is AppFailure
              ? error
              : const AppFailure(
            'Analysis could not finish. Please try again.',
          ),
        );
      }
    }
  }
}