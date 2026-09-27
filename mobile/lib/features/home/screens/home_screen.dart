import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../location_intelligence/analytics_panel.dart';
import '../location_intelligence/insights_repository.dart';
import '../location_intelligence/waste_map_screen.dart';
import '../management/management_screen.dart';
import '../reports/screens/my_reports_screen.dart';

class AuthorityHomeScreen
    extends ConsumerStatefulWidget {
  const AuthorityHomeScreen({super.key});

  @override
  ConsumerState<AuthorityHomeScreen>
  createState() {
    return _AuthorityHomeScreenState();
  }
}

class _AuthorityHomeScreenState
    extends ConsumerState<AuthorityHomeScreen> {
  Map<String, int>? counts;
  Insights? insights;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result = await ref
          .read(insightsRepositoryProvider)
          .summary();

      if (mounted) {
        setState(() {
          insights = result;
          counts = result.overview;
        });
      }
    } catch (caught) {
      if (mounted) {
        setState(() {
          error = caught.toString();
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

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final admin = auth.role == 'ADMIN';

    final cards = admin
        ? {
      'Total Reports': 'total',
      'Active': 'active',
      'In Progress': 'inProgress',
      'Resolved': 'resolved',
    }
        : {
      'Assigned Reports': 'total',
      'In Progress': 'inProgress',
      'Resolved': 'resolved',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(
          admin
              ? 'Admin Dashboard'
              : 'Department Dashboard',
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh counts',
            onPressed: loading ? null : refresh,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Log out',
            onPressed: () => ref
                .read(authProvider.notifier)
                .logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints:
          const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Welcome, '
                    '${auth.name ?? 'Authority'}',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                admin
                    ? 'Review and assign waste reports from tourist destinations.'
                    : 'Manage reports assigned to your department.',
              ),
              const SizedBox(height: 20),
              if (loading)
                const LinearProgressIndicator(),
              if (error != null) ...[
                Text(error!),
                TextButton(
                  onPressed: refresh,
                  child: const Text('Retry'),
                ),
              ],
              if (!loading &&
                  error == null &&
                  counts != null)
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final card
                    in cards.entries)
                      SizedBox(
                        width: 160,
                        child: Card(
                          child: Padding(
                            padding:
                            const EdgeInsets
                                .all(20),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                              children: [
                                Text(
                                  '${counts![card.value] ?? 0}',
                                  style: Theme.of(
                                    context,
                                  )
                                      .textTheme
                                      .headlineMedium,
                                ),
                                Text(card.key),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(
                  Icons.map_outlined,
                ),
                label: Text(
                  admin
                      ? 'View Waste Map'
                      : 'View Assigned Map',
                ),
                onPressed: () =>
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                        const WasteMapScreen(),
                      ),
                    ),
              ),
              if (admin)
                OutlinedButton.icon(
                  icon: const Icon(
                    Icons.settings_outlined,
                  ),
                  label: const Text(
                    'Management',
                  ),
                  onPressed: () =>
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                          const ManagementScreen(),
                        ),
                      ),
                ),
              if (admin &&
                  !loading &&
                  error == null &&
                  insights != null)
                AnalyticsPanel(insights!),
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: const Icon(
                  Icons.receipt_long,
                ),
                label: Text(
                  admin
                      ? 'View Reports'
                      : 'View Assigned Reports',
                ),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                      const MyReportsScreen(
                        authority: true,
                      ),
                    ),
                  );

                  if (mounted) {
                    await refresh();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}// Placeholder: paste the contents of mobile/lib/features/home/screens/home_screen.dart from your app here.
