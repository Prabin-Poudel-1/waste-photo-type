import 'package:chitwan_care/features/auth/auth_controller.dart';
import 'package:chitwan_care/features/authority/authority_actions.dart';
import 'package:chitwan_care/features/authority/authority_screen.dart';
import 'package:chitwan_care/features/reports/repositories/my_reports_repository.dart';
import 'package:chitwan_care/features/reports/screens/my_reports_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

TrackedReport report(
    int id,
    String status,
    ) {
  return TrackedReport({
    'id': id,
    'status': status,
    'severity': 'MEDIUM',
    'latitude': 27.7,
    'longitude': 84.4,
    'createdAt':
    '2026-09-23T10:00:00Z',
    'detections': [],
    'statusHistory': [],
    'images': [],
  });
}

class FakeAuth extends AuthController {
  final String role;

  FakeAuth(this.role);

  @override
  AuthState build() {
    return AuthState(
      role: role,
      name: 'Test authority',
      userId: 1,
      token: 'test',
    );
  }
}

class FakeReports
    extends MyReportsRepository {
  int detailCalls = 0;

  FakeReports() : super(Dio());

  @override
  Future<MyReportsPage> mine(
      int page, {
        bool authority = false,
      }) async {
    return MyReportsPage(
      page == 0
          ? [
        report(1, 'SUBMITTED'),
        report(2, 'IN_PROGRESS'),
      ]
          : [
        report(3, 'RESOLVED'),
        report(4, 'RESOLVED'),
      ],
      2,
    );
  }

  @override
  Future<TrackedReport> detail(
      int id,
      ) async {
    detailCalls++;
    return report(id, 'ASSIGNED');
  }
}

Widget app(
    String role,
    Widget screen,
    FakeReports repository,
    ) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith(
            () => FakeAuth(role),
      ),
      myReportsRepositoryProvider
          .overrideWithValue(repository),
    ],
    child: MaterialApp(home: screen),
  );
}

void main() {
  for (final role in [
    'ADMIN',
    'DEPARTMENT',
  ]) {
    testWidgets(
      '$role dashboard counts all fetched pages',
          (tester) async {
        await tester.pumpWidget(
          app(
            role,
            const AuthorityHomeScreen(),
            FakeReports(),
          ),
        );

        await tester.pumpAndSettle();

        expect(
          find.text(
            role == 'ADMIN'
                ? 'Admin Dashboard'
                : 'Department Dashboard',
          ),
          findsOneWidget,
        );

        expect(
          find.text(
            role == 'ADMIN'
                ? 'Total Reports'
                : 'Assigned Reports',
          ),
          findsOneWidget,
        );

        expect(
          find.text('4'),
          findsOneWidget,
        );

        expect(
          find.text('2'),
          findsOneWidget,
        );

        expect(
          find.text('In Progress'),
          findsOneWidget,
        );

        expect(
          find.text('Resolved'),
          findsOneWidget,
        );

        expect(
          tester.takeException(),
          isNull,
        );
      },
    );
  }

  testWidgets(
    'status-save callback and refresh return no Future from setState',
        (tester) async {
      final repository = FakeReports();

      await tester.pumpWidget(
        app(
          'DEPARTMENT',
          const ReportDetailScreen(id: 1),
          repository,
        ),
      );

      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byType(AuthorityActions),
        300,
        scrollable:
        find.byType(Scrollable).first,
      );

      final actions =
      tester.widget<AuthorityActions>(
        find.byType(AuthorityActions),
      );

      actions.onSaved();

      await tester.pumpAndSettle();

      await tester.tap(
        find.byTooltip('Refresh status'),
      );

      await tester.pumpAndSettle();

      expect(repository.detailCalls, 3);

      expect(
        tester.takeException(),
        isNull,
      );
    },
  );
}// Placeholder: paste the contents of mobile/test/phase5_targeted_fix_test.dart from your app here.
