import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../auth/auth_controller.dart';

class MapReport {
  final int id;
  final double latitude;
  final double longitude;
  final String statusGroup;
  final String? touristSpot;
  final DateTime date;
  final List<String> categories;
  final bool canViewDetails;

  MapReport(Map<String, dynamic> json)
      : id = json['id'] as int,
        latitude =
        (json['latitude'] as num).toDouble(),
        longitude =
        (json['longitude'] as num).toDouble(),
        statusGroup =
        json['statusGroup'] as String,
        touristSpot =
        json['touristSpot'] as String?,
        date = DateTime.parse(
          json['createdAt'] as String,
        ),
        categories = List<String>.from(
          json['categories'] as List,
        ),
        canViewDetails =
            json['canViewDetails'] == true;
}

class MapReports {
  final List<MapReport> reports;
  final bool truncated;

  MapReports(Map<String, dynamic> json)
      : reports = (json['reports'] as List)
      .map(
        (entry) => MapReport(
      Map<String, dynamic>.from(
        entry as Map,
      ),
    ),
  )
      .toList(),
        truncated = json['truncated'] == true;
}

class Ranking {
  final String name;
  final int count;

  Ranking(Map<String, dynamic> json)
      : name = json['name'] as String,
        count =
        (json['count'] as num).toInt();
}

class Insights {
  final Map<String, int> overview;
  final List<Ranking> spots;
  final List<Ranking> categories;

  Insights(Map<String, dynamic> json)
      : overview = Map<String, dynamic>.from(
    json['overview'] as Map,
  ).map(
        (key, value) => MapEntry(
      key,
      (value as num).toInt(),
    ),
  ),
        spots = (json['touristSpots'] as List)
            .map(
              (entry) => Ranking(
            Map<String, dynamic>.from(
              entry as Map,
            ),
          ),
        )
            .toList(),
        categories =
        (json['categories'] as List)
            .map(
              (entry) => Ranking(
            Map<String, dynamic>.from(
              entry as Map,
            ),
          ),
        )
            .toList();
}

final insightsRepositoryProvider = Provider(
      (ref) => InsightsRepository(
    ref.watch(authenticatedDioProvider),
  ),
);

class InsightsRepository {
  final Dio dio;

  InsightsRepository(this.dio);

  Future<Map<String, dynamic>> _get(
      String path, [
        Map<String, dynamic>? parameters,
      ]) async {
    try {
      return Map<String, dynamic>.from(
        (await dio.get(
          path,
          queryParameters: parameters,
        ))
            .data as Map,
      );
    } on DioException catch (error) {
      throw AppFailure(
        error.response?.statusCode == 403
            ? 'This account needs permission and an active department to view assigned data.'
            : 'Could not load data. Check your connection and retry.',
      );
    } catch (_) {
      throw const AppFailure(
        'The server response could not be read. Please retry.',
      );
    }
  }

  Future<MapReports> map(
      double south,
      double west,
      double north,
      double east,
      String filter,
      ) async {
    return MapReports(
      await _get(
        '/api/v1/maps/reports',
        {
          'south': south,
          'west': west,
          'north': north,
          'east': east,
          'filter': filter,
        },
      ),
    );
  }

  Future<Insights> summary() async {
    return Insights(
      await _get(
        '/api/v1/authority/insights',
      ),
    );
  }
}// Placeholder: paste the contents of mobile/lib/features/location_intelligence/insights_repository.dart from your app here.
