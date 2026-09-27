import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../auth/auth_controller.dart';

class MapReport {
  final int id;
  final double latitude, longitude;
  final String statusGroup;
  final String? touristSpot;
  final DateTime date;
  final List<String> categories;
  final bool canViewDetails;
  MapReport(Map<String, dynamic> j)
    : id = j['id'] as int,
      latitude = (j['latitude'] as num).toDouble(),
      longitude = (j['longitude'] as num).toDouble(),
      statusGroup = j['statusGroup'] as String,
      touristSpot = j['touristSpot'] as String?,
      date = DateTime.parse(j['createdAt'] as String),
      categories = List<String>.from(j['categories'] as List),
      canViewDetails = j['canViewDetails'] == true;
}

class MapReports {
  final List<MapReport> reports;
  final bool truncated;
  MapReports(Map<String, dynamic> j)
    : reports = (j['reports'] as List)
          .map((e) => MapReport(Map<String, dynamic>.from(e as Map)))
          .toList(),
      truncated = j['truncated'] == true;
}

class Ranking {
  final String name;
  final int count;
  Ranking(Map<String, dynamic> j)
    : name = j['name'] as String,
      count = (j['count'] as num).toInt();
}

class Insights {
  final Map<String, int> overview;
  final List<Ranking> spots, categories;
  Insights(Map<String, dynamic> j)
    : overview = Map<String, dynamic>.from(j['overview'] as Map)
          .map((k, v) => MapEntry(k, (v as num).toInt())),
      spots = (j['touristSpots'] as List)
          .map((e) => Ranking(Map<String, dynamic>.from(e as Map)))
          .toList(),
      categories = (j['categories'] as List)
          .map((e) => Ranking(Map<String, dynamic>.from(e as Map)))
          .toList();
}

final insightsRepositoryProvider = Provider(
  (ref) => InsightsRepository(ref.watch(authenticatedDioProvider)),
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
        (await dio.get(path, queryParameters: parameters)).data as Map,
      );
    } on DioException catch (e) {
      throw AppFailure(
        e.response?.statusCode == 403
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
  ) async => MapReports(
    await _get('/api/v1/maps/reports', {
      'south': south,
      'west': west,
      'north': north,
      'east': east,
      'filter': filter,
    }),
  );
  Future<Insights> summary() async =>
      Insights(await _get('/api/v1/authority/insights'));
}
