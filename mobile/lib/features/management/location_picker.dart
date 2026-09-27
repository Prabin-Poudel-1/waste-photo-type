import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

// Same flutter_map/OSM stack as the Waste Map; no report data or GPS changes.
class LocationPicker extends StatefulWidget {
  final LatLng? initial;

  const LocationPicker({
    super.key,
    this.initial,
  });

  @override
  State<LocationPicker> createState() {
    return _LocationPickerState();
  }
}

class _LocationPickerState
    extends State<LocationPicker> {
  LatLng? selected;
  bool failed = false;
  int tileEpoch = 0;

  @override
  void initState() {
    super.initState();
    selected = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select location',
        ),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Pan or zoom, then tap the map to place the destination marker. Tap again to move it.',
            ),
          ),
          if (failed)
            ListTile(
              title: const Text(
                'Map tiles unavailable. Check your connection.',
              ),
              trailing: TextButton(
                onPressed: () {
                  setState(() {
                    failed = false;
                    tileEpoch++;
                  });
                },
                child: const Text('Retry'),
              ),
            ),
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: selected ??
                    const LatLng(
                      27.63,
                      84.40,
                    ),
                initialZoom:
                selected == null ? 10 : 15,
                minZoom: 3,
                maxZoom: 19,
                onTap: (_, point) {
                  setState(() {
                    selected = LatLng(
                      point.latitude.clamp(
                        -90,
                        90,
                      ),
                      ((point.longitude + 180) %
                          360) -
                          180,
                    );
                  });
                },
              ),
              children: [
                TileLayer(
                  key: ValueKey(tileEpoch),
                  urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName:
                  'np.chitwancare.chitwan_care',
                  maxNativeZoom: 19,
                  errorTileCallback:
                      (_, _, _) {
                    if (!failed && mounted) {
                      WidgetsBinding.instance
                          .addPostFrameCallback(
                            (_) {
                          if (mounted) {
                            setState(() {
                              failed = true;
                            });
                          }
                        },
                      );
                    }
                  },
                ),
                MarkerLayer(
                  markers: [
                    if (selected != null)
                      Marker(
                        point: selected!,
                        width: 44,
                        height: 44,
                        child: const Icon(
                          Icons.location_on,
                          size: 40,
                          color:
                          Color(0xFF173F35),
                        ),
                      ),
                  ],
                ),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      'OpenStreetMap contributors',
                      onTap: () => launchUrl(
                        Uri.parse(
                          'https://www.openstreetmap.org/copyright',
                        ),
                        mode: LaunchMode
                            .externalApplication,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding:
              const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    selected == null
                        ? 'No location selected'
                        : '${selected!.latitude.toStringAsFixed(6)}, '
                        '${selected!.longitude.toStringAsFixed(6)}',
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: selected == null
                          ? null
                          : () =>
                          Navigator.pop(
                            context,
                            selected,
                          ),
                      child: const Text(
                        'Confirm location',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}// Placeholder: paste the contents of mobile/lib/features/management/location_picker.dart from your app here.
