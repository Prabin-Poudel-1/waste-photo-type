import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../auth/auth_controller.dart';
import '../reports/screens/my_reports_screen.dart';
import 'insights_repository.dart';
import 'map_status.dart';

class WasteMapScreen extends ConsumerStatefulWidget {
  const WasteMapScreen({super.key});
  @override
  ConsumerState<WasteMapScreen> createState() => _WasteMapScreenState();
}

class _WasteMapScreenState extends ConsumerState<WasteMapScreen> {
  final controller = MapController();
  Timer? timer;
  int generation = 0;
  int tileEpoch = 0;
  bool ready = false, loading = true, tileError = false;
  String filter = 'ALL';
  String? error;
  MapReports? data;
  @override
  void dispose() {
    timer?.cancel();
    generation++;
    controller.dispose();
    super.dispose();
  }

  void schedule() {
    timer?.cancel();
    timer = Timer(const Duration(milliseconds: 450), load);
  }

  Future<void> load() async {
    if (!ready || !mounted) return;
    final current = ++generation;
    final bounds = controller.camera.visibleBounds;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await ref
          .read(insightsRepositoryProvider)
          .map(
            bounds.south.clamp(-90, 90),
            bounds.west.clamp(-180, 180),
            bounds.north.clamp(-90, 90),
            bounds.east.clamp(-180, 180),
            filter,
          );
      if (mounted && current == generation) {
        setState(() {
          data = result;
        });
      }
    } catch (e) {
      if (mounted && current == generation) {
        setState(() {
          error = e.toString();
          data = null;
        });
      }
    } finally {
      if (mounted && current == generation) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  void details(MapReport report) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              report.touristSpot ?? 'Reported location',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Chip(
              avatar: Icon(
                Icons.circle,
                size: 12,
                color: mapStatusColor(report.statusGroup),
              ),
              label: Text(mapStatusLabel(report.statusGroup)),
            ),
            Text(
              report.categories.isEmpty
                  ? 'Category not recorded'
                  : report.categories.join(' · '),
            ),
            const SizedBox(height: 8),
            Text(reportDate(report.date)),
            if (report.canViewDetails) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  Navigator.pop(sheet);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ReportDetailScreen(id: report.id),
                    ),
                  );
                },
                child: const Text('View Details'),
              ),
            ],
          ],
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final department = ref.watch(authProvider).role == 'DEPARTMENT';
    return Scaffold(
      appBar: AppBar(
        title: Text(department ? 'Assigned Waste Map' : 'Waste Map'),
        actions: [
          IconButton(
            tooltip: 'Refresh reports',
            onPressed: loading ? null : load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                for (final entry in {
                  'ALL': 'All',
                  'ACTIVE': 'Active',
                  'RESOLVED': 'Resolved',
                }.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(entry.value),
                      selected: filter == entry.key,
                      onSelected: (_) {
                        setState(() {
                          filter = entry.key;
                        });
                        load();
                      },
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Wrap(
              spacing: 14,
              runSpacing: 4,
              children: [
                for (final group in ['ATTENTION', 'HANDLING', 'RESOLVED'])
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 9, color: mapStatusColor(group)),
                      const SizedBox(width: 4),
                      Text(
                        mapStatusLabel(group),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: controller,
                  options: MapOptions(
                    initialCenter: const LatLng(27.63, 84.40),
                    initialZoom: 10,
                    minZoom: 3,
                    maxZoom: 19,
                    onMapReady: () {
                      ready = true;
                      load();
                    },
                    onPositionChanged: (_, gesture) {
                      schedule();
                    },
                  ),
                  children: [
                    TileLayer(
                      key: ValueKey(tileEpoch),
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'np.chitwancare.chitwan_care',
                      maxNativeZoom: 19,
                      errorTileCallback: (_, _, _) {
                        if (!tileError && mounted) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() {
                                tileError = true;
                              });
                            }
                          });
                        }
                      },
                    ),
                    MarkerClusterLayerWidget(
                      options: MarkerClusterLayerOptions(
                        maxClusterRadius: 48,
                        size: const Size(40, 40),
                        markers: [
                          for (final report in data?.reports ?? <MapReport>[])
                            Marker(
                              point: LatLng(report.latitude, report.longitude),
                              width: 42,
                              height: 42,
                              child: Semantics(
                                label:
                                    '${mapStatusLabel(report.statusGroup)} report',
                                button: true,
                                child: IconButton(
                                  onPressed: () => details(report),
                                  icon: Icon(
                                    Icons.location_on,
                                    color: mapStatusColor(report.statusGroup),
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),
                        ],
                        builder: (context, markers) => Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${markers.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution(
                          'OpenStreetMap contributors',
                          onTap: () => launchUrl(
                            Uri.parse(
                              'https://www.openstreetmap.org/copyright',
                            ),
                            mode: LaunchMode.externalApplication,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (error != null ||
                    (!loading && data?.reports.isEmpty == true) ||
                    data?.truncated == true ||
                    tileError)
                  Positioned(
                    top: 12,
                    left: 16,
                    right: 16,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              error ??
                                  (tileError
                                      ? 'Map tiles unavailable. Check your internet connection.'
                                      : data?.truncated == true
                                      ? 'Showing 500 reports. Zoom in to see this area more clearly.'
                                      : 'No reports to show in this area.'),
                            ),
                            if (error != null || tileError)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    tileError = false;
                                    tileEpoch++;
                                  });
                                  load();
                                  controller.move(
                                    controller.camera.center,
                                    controller.camera.zoom,
                                  );
                                },
                                child: const Text('Retry'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
