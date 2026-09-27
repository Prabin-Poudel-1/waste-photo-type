import 'package:chitwan_care/features/auth/auth_controller.dart';
import 'package:chitwan_care/features/authority/authority_screen.dart';
import 'package:chitwan_care/features/help/help_screen.dart';
import 'package:chitwan_care/features/home/screens/tourist_shell.dart';
import 'package:chitwan_care/features/location_intelligence/insights_repository.dart';
import 'package:chitwan_care/features/location_intelligence/map_status.dart';
import 'package:chitwan_care/features/reports/controllers/report_controller.dart';
import 'package:chitwan_care/features/reports/models/report_models.dart';
import 'package:chitwan_care/features/reports/services/location_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class TestAuth extends AuthController {
  final String role;

  TestAuth(this.role);

  @override
  AuthState build() {
    return AuthState(
      role: role,
      userId: 1,
      name: 'Test',
    );
  }
}

class TestInsights extends InsightsRepository {
  TestInsights() : super(Dio());

  @override
  Future<Insights> summary() async {
    return Insights({
      'overview': {
        'total': 12,
        'active': 8,
        'inProgress': 3,
        'resolved': 4,
      },
      'touristSpots': [
        {
          'name': 'Test riverbank',
          'count': 7,
        },
      ],
      'categories': [
        {
          'name': 'Plastic',
          'count': 9,
        },
      ],
    });
  }
}

class TestLocation implements LocationService {
  bool denied = true;

  @override
  Future<IncidentLocation> locate() async {
    if (denied) {
      throw const LocationFailure(
        'Denied',
        LocationRecovery.appSettings,
      );
    }

    return const IncidentLocation(
      27.69957,
      84.42201,
      8,
    );
  }

  @override
  Future<bool> openSettings(
      LocationRecovery recovery,
      ) async {
    return true;
  }
}

void main() {
  test(
    'map DTO parses safe data and server detail capability',
        () {
      final page = MapReports({
        'truncated': true,
        'reports': [
          {
            'id': 8,
            'latitude': 27.6,
            'longitude': 84.4,
            'statusGroup': 'HANDLING',
            'touristSpot': null,
            'createdAt':
            '2026-09-26T00:00:00Z',
            'categories': [
              'Plastic',
              'Glass',
            ],
            'canViewDetails': false,
          },
        ],
      });

      expect(page.truncated, isTrue);

      expect(
        page.reports.single.categories,
        [
          'Plastic',
          'Glass',
        ],
      );

      expect(
        page.reports.single.canViewDetails,
        isFalse,
      );

      expect(
        mapStatusLabel(
          page.reports.single.statusGroup,
        ),
        'Being handled',
      );

      expect(
        mapStatusLabel('ATTENTION'),
        'Needs attention',
      );

      expect(
        mapStatusColor('ATTENTION'),
        isNot(
          mapStatusColor('RESOLVED'),
        ),
      );
    },
  );

  test(
    'map sends viewport/filter and handles API failure',
        () async {
      final dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            expect(
              request.path,
              '/api/v1/maps/reports',
            );

            expect(
              request.queryParameters,
              {
                'south': 27.0,
                'west': 84.0,
                'north': 28.0,
                'east': 85.0,
                'filter': 'ACTIVE',
              },
            );

            handler.resolve(
              Response(
                requestOptions: request,
                data: {
                  'reports': [],
                  'truncated': false,
                },
              ),
            );
          },
        ),
      );

      expect(
        (await InsightsRepository(
          dio,
        ).map(
          27,
          84,
          28,
          85,
          'ACTIVE',
        ))
            .reports,
        isEmpty,
      );

      dio.interceptors.clear();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            handler.reject(
              DioException(
                requestOptions: request,
              ),
            );
          },
        ),
      );

      await expectLater(
        InsightsRepository(dio).summary(),
        throwsA(
          predicate(
                (error) => error
                .toString()
                .contains(
              'Check your connection',
            ),
          ),
        ),
      );
    },
  );

  test(
    'call opens a tel URI and directions use named verified destination',
        () {
      expect(
        dialUri(
          hospitalPhone,
        ).toString(),
        'tel:+97756597003',
      );

      expect(
        dialUri('100').scheme,
        'tel',
      );

      expect(
        hospitalDirections()
            .queryParameters['destination'],
        contains('Bharatpur Hospital'),
      );
    },
  );

  for (final role in [
    'ADMIN',
    'DEPARTMENT',
  ]) {
    testWidgets(
      '$role dashboard shows scoped summary and correct map action',
          (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith(
                    () => TestAuth(role),
              ),
              insightsRepositoryProvider
                  .overrideWithValue(
                TestInsights(),
              ),
            ],
            child: const MaterialApp(
              home: AuthorityHomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(
          find.text('12'),
          findsOneWidget,
        );

        expect(
          find.text(
            role == 'ADMIN'
                ? 'View Waste Map'
                : 'View Assigned Map',
          ),
          findsOneWidget,
        );

        expect(
          find.text(
            'Top reporting areas',
          ),
          role == 'ADMIN'
              ? findsOneWidget
              : findsNothing,
        );

        expect(
          tester.takeException(),
          isNull,
        );
      },
    );
  }

  testWidgets(
    'tourist navigation retains home and separate Help destination',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
                  () => TestAuth('USER'),
            ),
          ],
          child: const MaterialApp(
            home: TouristShell(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byType(
          NavigationDestination,
        ),
        findsNWidgets(4),
      );

      await tester.tap(
        find.text('Help').last,
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Help & Safety'),
        findsOneWidget,
      );

      expect(
        find.text(
          'Bharatpur Hospital',
        ),
        findsOneWidget,
      );

      expect(
        tester.takeException(),
        isNull,
      );
    },
  );

  testWidgets(
    'help handles denied location and retry without report submission',
        (tester) async {
      final location = TestLocation();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            locationServiceProvider
                .overrideWithValue(
              location,
            ),
          ],
          child: const MaterialApp(
            home: HelpScreen(),
          ),
        ),
      );

      await tester.scrollUntilVisible(
        find.text(
          'Get current location',
        ),
        250,
      );

      await tester.tap(
        find.text(
          'Get current location',
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          'Location unavailable.',
        ),
        findsOneWidget,
      );

      expect(
        find.text('Open settings'),
        findsOneWidget,
      );

      location.denied = false;

      await tester.ensureVisible(
        find.text(
          'Get current location',
        ),
      );

      await tester.tap(
        find.text(
          'Get current location',
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          '27.699570, 84.422010',
        ),
        findsOneWidget,
      );

      expect(
        find.text(
          'Open location in Maps',
        ),
        findsOneWidget,
      );

      expect(
        tester.takeException(),
        isNull,
      );
    },
  );
}// Placeholder: paste the contents of mobile/test/phase7_test.dart from your app here.
