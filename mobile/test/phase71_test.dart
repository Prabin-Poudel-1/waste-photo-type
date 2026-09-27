import 'dart:async';

import 'package:chitwan_care/features/auth/auth_controller.dart';
import 'package:chitwan_care/features/management/management_repository.dart';
import 'package:chitwan_care/features/management/management_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class TestAuth extends AuthController {
  final String role;

  TestAuth(this.role);

  @override
  AuthState build() {
    return AuthState(role: role);
  }
}

class FakeManagement
    extends ManagementRepository {
  int calls = 0;
  Map<String, dynamic>? saved;
  Completer<void>? pending;

  FakeManagement() : super(Dio());

  @override
  Future<void> save(
      bool spots,
      int? id,
      Map<String, dynamic> data,
      ) async {
    calls++;
    saved = data;

    if (pending != null) {
      await pending!.future;
    }
  }
}

Widget host(
    Widget child,
    FakeManagement repository, {
      String role = 'ADMIN',
    }) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith(
            () => TestAuth(role),
      ),
      managementRepositoryProvider
          .overrideWithValue(repository),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  test(
    'repository uses admin endpoints and preserves inactive records',
        () async {
      final dio = Dio();
      final requests =
      <RequestOptions>[];

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            requests.add(request);

            handler.resolve(
              Response(
                requestOptions: request,
                data:
                request.method == 'GET'
                    ? [
                  {
                    'id': 7,
                    'name':
                    'Old department',
                    'description':
                    null,
                    'active': false,
                  },
                ]
                    : {},
              ),
            );
          },
        ),
      );

      final repository =
      ManagementRepository(dio);

      expect(
        (await repository.list(false))
            .single
            .active,
        isFalse,
      );

      await repository.save(
        false,
        null,
        {
          'name': 'New',
          'active': true,
        },
      );

      await repository.save(
        true,
        4,
        {
          'name': 'Spot',
          'active': false,
          'latitude': 27.123456,
          'longitude': 84.123456,
          'radiusMeters': 700,
        },
      );

      expect(
        requests.map(
              (request) => request.method,
        ),
        [
          'GET',
          'POST',
          'PUT',
        ],
      );

      expect(
        requests.last.path,
        '/api/v1/admin/management/tourist-spots/4',
      );

      expect(
        requests
            .last
            .data['radiusMeters'],
        700,
      );
    },
  );

  for (final role in [
    'USER',
    'DEPARTMENT',
  ]) {
    testWidgets(
      '$role has no management operations',
          (tester) async {
        await tester.pumpWidget(
          host(
            const ManagementScreen(),
            FakeManagement(),
            role: role,
          ),
        );

        expect(
          find.text(
            'Admin access required.',
          ),
          findsOneWidget,
        );

        expect(
          find.text('Departments'),
          findsNothing,
        );
      },
    );
  }

  testWidgets(
    'required name and save progress prevent duplicate submits',
        (tester) async {
      final repository =
      FakeManagement()
        ..pending = Completer<void>();

      await tester.pumpWidget(
        host(
          const ManagementForm(
            spots: false,
          ),
          repository,
        ),
      );

      await tester.tap(
        find.text('Save'),
      );

      await tester.pump();

      expect(
        find.text('Enter a name.'),
        findsOneWidget,
      );

      expect(repository.calls, 0);

      await tester.enterText(
        find.byType(TextFormField).first,
        '  New department  ',
      );

      await tester.tap(
        find.text('Save'),
      );

      await tester.pump();

      expect(repository.calls, 1);

      expect(
        repository.saved!['name'],
        'New department',
      );

      expect(
        find.text('Saving…'),
        findsOneWidget,
      );

      expect(
        tester
            .widget<FilledButton>(
          find.byType(FilledButton),
        )
            .onPressed,
        isNull,
      );

      await tester.pumpWidget(
        const SizedBox(),
      );

      repository.pending!.complete();

      await tester.pump();

      expect(
        tester.takeException(),
        isNull,
      );
    },
  );

  testWidgets(
    'new spot cannot save without a selected map location',
        (tester) async {
      tester.view.physicalSize =
      const Size(1000, 1800);

      tester.view.devicePixelRatio = 1;

      addTearDown(
        tester.view.resetPhysicalSize,
      );

      addTearDown(
        tester.view.resetDevicePixelRatio,
      );

      final repository =
      FakeManagement();

      await tester.pumpWidget(
        host(
          const ManagementForm(
            spots: true,
          ),
          repository,
        ),
      );

      await tester.enterText(
        find.byType(TextFormField).first,
        'New spot',
      );

      await tester.tap(
        find.text('Save'),
      );

      await tester.pumpAndSettle();

      expect(
        find.text(
          'Select the tourist spot on the map.',
        ),
        findsOneWidget,
      );

      expect(repository.calls, 0);
    },
  );

  testWidgets(
    'deactivation requires confirmation and cancellation preserves record',
        (tester) async {
      final repository =
      FakeManagement();

      final record = ManagedRecord({
        'id': 9,
        'name': 'Existing',
        'description': '',
        'active': true,
      });

      await tester.pumpWidget(
        host(
          ManagementForm(
            spots: false,
            record: record,
          ),
          repository,
        ),
      );

      await tester.tap(
        find.byType(SwitchListTile),
      );

      await tester.pump();

      await tester.tap(
        find.text('Save'),
      );

      await tester.pumpAndSettle();

      expect(
        find.text(
          'Deactivate this record?',
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.text('Cancel'),
      );

      await tester.pumpAndSettle();

      expect(repository.calls, 0);

      expect(
        find.text('Save'),
        findsOneWidget,
      );
    },
  );
}