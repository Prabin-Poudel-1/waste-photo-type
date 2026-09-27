import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chitwan_care/core/errors/app_failure.dart';
import 'package:chitwan_care/features/analysis/models/detection_result.dart';
import 'package:chitwan_care/features/reports/controllers/report_controller.dart';
import 'package:chitwan_care/features/reports/models/report_models.dart';
import 'package:chitwan_care/features/reports/repositories/report_repository.dart';
import 'package:chitwan_care/features/reports/services/location_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'http_service_test.dart'
    show StubAdapter;
import 'report_fakes.dart';

void main() {
  final photo = WastePhoto(
    bytes: File(
      'test/fixtures/synthetic-scene.png',
    ).readAsBytesSync(),
    name: 'scene.png',
    selectedAt: DateTime(2026),
  );

  const detections = [
    WasteDetection(
      categoryCode: 'plastic',
      label: 'Plastic',
      confidence: .94,
    ),
  ];

  test(
    'Category mapping uses catalog IDs, normalized labels and Other fallback',
        () {
      const catalog = [
        WasteCategory(
          82,
          'paper',
          'Paper/Cardboard',
        ),
        WasteCategory(
          91,
          'other',
          'Other',
        ),
      ];

      expect(
        mapCategory(
          const WasteDetection(
            categoryCode: 'unknown',
            label:
            ' PAPER / cardboard ',
            confidence: .5,
          ),
          catalog,
        ).id,
        82,
      );

      expect(
        mapCategory(
          detections.first,
          catalog,
        ).id,
        91,
      );

      expect(
            () => mapCategory(
          detections.first,
          [],
        ),
        throwsA(isA<AppFailure>()),
      );
    },
  );

  test(
    'Metadata preserves labels and rounds exact GPS to database precision',
        () {
      final metadata = reportMetadata(
        location:
        const IncidentLocation(
          27.12345678,
          84.23456789,
          5,
        ),
        detections: detections,
        categories: const [
          WasteCategory(
            42,
            'plastic',
            'Plastic',
          ),
        ],
        description: ' waste ',
        severity: 'HIGH',
        touristSpotId: 77,
      );

      expect(
        metadata['latitude'],
        27.123457,
      );

      expect(
        metadata['longitude'],
        84.234568,
      );

      expect(
        metadata['touristSpotId'],
        77,
      );

      expect(
        (metadata['detections'] as List)
            .single,
        {
          'categoryId': 42,
          'label': 'Plastic',
          'confidence': .94,
        },
      );

      expect(
        metadata['description'],
        'waste',
      );
    },
  );

  test(
    'Tourist spot and success response deserialize',
        () {
      final spot =
      TouristSpot.fromJson({
        'id': 77,
        'name': 'Test',
        'latitude': 0,
        'longitude': 0,
        'radiusMeters': 100,
      });

      expect(
        spot.radiusMeters,
        100,
      );

      final report =
      SubmittedReport.fromJson({
        'id': 22,
        'status': 'SUBMITTED',
        'createdAt':
        '2026-09-23T00:00:00Z',
        'touristSpot': {
          'id': 77,
          'name': 'Test',
        },
        'images': [],
      });

      expect(report.id, 22);

      expect(
        report.touristSpotName,
        'Test',
      );

      expect(
            () =>
            SubmittedReport.fromJson({
              'id': 0,
              'status': '',
            }),
        throwsFormatException,
      );
    },
  );

  test(
    'Multipart contains JSON metadata and original photo bytes',
        () async {
      final data =
      HttpReportRepository.multipart(
        {
          'severity': 'LOW',
        },
        photo,
      );

      expect(
        data.files.map(
              (entry) => entry.key,
        ),
        [
          'metadata',
          'image',
        ],
      );

      final metadata =
          data.files.first.value;

      expect(
        metadata.contentType!.mimeType,
        'application/json',
      );

      expect(
        jsonDecode(
          utf8.decode(
            await metadata
                .finalize()
                .expand(
                  (chunk) => chunk,
            )
                .toList(),
          ),
        ),
        {
          'severity': 'LOW',
        },
      );

      expect(
        await data.files.last.value
            .finalize()
            .expand(
              (chunk) => chunk,
        )
            .toList(),
        photo.bytes,
      );
    },
  );

  test(
    'GPS failure blocks submit; retry and unmatched location allow nullable destination',
        () async {
      final location =
      FakeLocationService()
        ..failure =
        const LocationFailure(
          'Denied',
          LocationRecovery.appSettings,
        );

      final controller =
      ReportController(
        FakeReportRepository(),
        location,
      );

      addTearDown(controller.dispose);

      await controller.loadCatalog();
      await controller.locate();

      expect(
        controller.canSubmit,
        false,
      );

      expect(
        controller
            .locationError!
            .recovery,
        LocationRecovery.appSettings,
      );

      location.failure = null;

      await controller.locate();

      expect(
        controller.canSubmit,
        true,
      );

      expect(
        controller.selectedSpot,
        isNull,
      );

      controller.selectSpot(77);

      expect(
        controller.selectedSpot!.id,
        77,
      );

      expect(
        controller.location!.latitude,
        .0001234,
      );
    },
  );

  test(
    'Submit guard prevents repeated taps and retains returned report ID',
        () async {
      final repository =
      FakeReportRepository()
        ..pending =
        Completer<
            SubmittedReport>();

      final controller =
      ReportController(
        repository,
        FakeLocationService(),
      );

      addTearDown(controller.dispose);

      await controller.loadCatalog();
      await controller.locate();

      final first = controller.submit(
        photo,
        detections,
        'test',
        'MEDIUM',
      );

      await controller.submit(
        photo,
        detections,
        'test',
        'MEDIUM',
      );

      expect(repository.calls, 1);

      expect(
        controller.submitting,
        true,
      );

      repository.pending!.complete(
        SubmittedReport(
          42,
          'SUBMITTED',
          DateTime.utc(2026),
          null,
          [],
        ),
      );

      await first;

      expect(
        controller.submitted!.id,
        42,
      );

      expect(
        controller.canSubmit,
        false,
      );
    },
  );

  test(
    'Submission failure retains prepared form state and allows retry',
        () async {
      final repository =
      FakeReportRepository()
        ..fail = true;

      final controller =
      ReportController(
        repository,
        FakeLocationService(),
      );

      addTearDown(controller.dispose);

      await controller.loadCatalog();
      await controller.locate();

      await controller.submit(
        photo,
        detections,
        'test',
        'LOW',
      );

      expect(
        controller.submitError,
        isNotNull,
      );

      expect(
        controller.location,
        isNotNull,
      );

      expect(
        controller.canSubmit,
        true,
      );

      repository.fail = false;

      await controller.submit(
        photo,
        detections,
        'test',
        'LOW',
      );

      expect(
        controller.submitted!.id,
        1042,
      );
    },
  );

  for (final status in [
    400,
    404,
    413,
    500,
    503,
  ]) {
    test(
      'Report HTTP $status is shown without internal server details',
          () async {
        final dio = Dio()
          ..httpClientAdapter =
          StubAdapter(
            status,
            {
              'message':
              'secret SQL trace',
            },
          );

        addTearDown(dio.close);

        final repository =
        HttpReportRepository(dio);

        try {
          await repository.submit(
            {},
            photo,
                (_, _) {},
          );

          fail('Expected error');
        } on AppFailure catch (error) {
          expect(
            error.message,
            isNot(
              contains(
                'secret SQL',
              ),
            ),
          );
        }
      },
    );
  }

  test(
    'Malformed success is not presented as a submitted report',
        () async {
      final dio = Dio()
        ..httpClientAdapter =
        StubAdapter(
          201,
          {
            'wrong': true,
          },
        );

      addTearDown(dio.close);

      expect(
            () => HttpReportRepository(
          dio,
        ).submit(
          {},
          photo,
              (_, _) {},
        ),
        throwsA(isA<AppFailure>()),
      );
    },
  );

  test(
    'HTTP submission parses actual created report',
        () async {
      final dio = Dio()
        ..httpClientAdapter =
        StubAdapter(
          201,
          {
            'id': 9,
            'status': 'SUBMITTED',
            'createdAt':
            '2026-09-23T00:00:00Z',
            'touristSpot': null,
            'images': [],
          },
        );

      addTearDown(dio.close);

      expect(
        (await HttpReportRepository(
          dio,
        ).submit(
          {},
          photo,
              (_, _) {},
        ))
            .id,
        9,
      );
    },
  );
}// Placeholder: paste the contents of mobile/test/report_test.dart from your app here.
