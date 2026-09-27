import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../reports/controllers/report_controller.dart';
import '../reports/models/report_models.dart';
import '../reports/services/location_service.dart';

// Verified 2026-09-26 against hospital and Nepal Police official websites.
const hospitalPhone = '+97756597003';

Uri hospitalDirections() {
  return Uri.https(
    'www.google.com',
    '/maps/dir/',
    {
      'api': '1',
      'destination':
      'Bharatpur Hospital, Bharatpur, Chitwan, Nepal',
    },
  );
}

Uri dialUri(String number) {
  return Uri(
    scheme: 'tel',
    path: number,
  );
}

class HelpScreen extends ConsumerStatefulWidget {
  const HelpScreen({super.key});

  @override
  ConsumerState<HelpScreen> createState() {
    return _HelpScreenState();
  }
}

class _HelpScreenState
    extends ConsumerState<HelpScreen> {
  IncidentLocation? location;
  LocationFailure? failure;
  bool loading = false;

  Future<void> open(Uri uri) async {
    try {
      if (await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      )) {
        return;
      }
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No compatible app could open this action. Use the displayed number or location manually.',
          ),
        ),
      );
    }
  }

  Future<void> locate() async {
    setState(() {
      loading = true;
      failure = null;
    });

    try {
      final value = await ref
          .read(locationServiceProvider)
          .locate();

      if (mounted) {
        setState(() {
          location = value;
        });
      }
    } on LocationFailure catch (error) {
      if (mounted) {
        setState(() {
          failure = error;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Widget contact(
      String name,
      String number,
      String description,
      ) {
    return Card(
      child: ListTile(
        contentPadding:
        const EdgeInsets.all(16),
        title: Text(name),
        subtitle: Text(
          '$description\n$number',
        ),
        isThreeLine: true,
        trailing: IconButton(
          tooltip: 'Call $name',
          icon: const Icon(
            Icons.call_outlined,
          ),
          onPressed: () =>
              open(dialUri(number)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Safety'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Assistance in Bharatpur & Chitwan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Calls open your dialer. You choose whether to place the call. Short codes require a Nepal phone network.',
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding:
              const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bharatpur Hospital',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Emergency / medical assistance · 24/7\n'
                        'Bharatpur, Chitwan, Nepal\n'
                        '056-597003',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child:
                        OutlinedButton.icon(
                          onPressed: () => open(
                            dialUri(
                              hospitalPhone,
                            ),
                          ),
                          icon: const Icon(
                            Icons.call_outlined,
                            size: 18,
                          ),
                          label:
                          const Text('Call'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child:
                        OutlinedButton.icon(
                          onPressed: () => open(
                            hospitalDirections(),
                          ),
                          icon: const Icon(
                            Icons
                                .directions_outlined,
                            size: 18,
                          ),
                          label: const Text(
                            'Directions',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          contact(
            'Nepal Police',
            '100',
            'Police assistance',
          ),
          contact(
            'Tourist Police',
            '1144',
            'Tourist assistance hotline',
          ),
          const SizedBox(height: 20),
          Text(
            'Your current location',
            style: Theme.of(context)
                .textTheme
                .titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Request location when you need it. No location is submitted or stored by this screen.',
          ),
          if (location != null) ...[
            const SizedBox(height: 8),
            SelectableText(
              '${location!.latitude.toStringAsFixed(6)}, '
                  '${location!.longitude.toStringAsFixed(6)}\n'
                  'Accuracy approximately '
                  '${location!.accuracyMeters.round()} m',
            ),
            TextButton.icon(
              onPressed: () => open(
                Uri.parse(
                  'geo:${location!.latitude},'
                      '${location!.longitude}'
                      '?q=${location!.latitude},'
                      '${location!.longitude}',
                ),
              ),
              icon: const Icon(
                Icons.open_in_new,
                size: 18,
              ),
              label: const Text(
                'Open location in Maps',
              ),
            ),
          ],
          if (failure != null) ...[
            Text(
              'Location unavailable. '
                  '${failure!.recovery == LocationRecovery.retry ? 'Check permission and retry.' : 'Enable location access in settings.'}',
            ),
            if (failure!.recovery !=
                LocationRecovery.retry)
              TextButton(
                onPressed: () async {
                  final opened = await ref
                      .read(
                    locationServiceProvider,
                  )
                      .openSettings(
                    failure!.recovery,
                  );

                  if (!opened &&
                      context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Open location permissions in device settings.',
                        ),
                      ),
                    );
                  }
                },
                child: const Text(
                  'Open settings',
                ),
              ),
          ],
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: loading ? null : locate,
            child: Text(
              loading
                  ? 'Getting location…'
                  : location == null
                  ? 'Get current location'
                  : 'Refresh location',
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Contacts: official Bharatpur Hospital and Nepal Police websites. Checked 26 September 2026. Confirm the hospital destination in your maps app.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}// Placeholder: paste the contents of mobile/lib/features/help/help_screen.dart from your app here.
