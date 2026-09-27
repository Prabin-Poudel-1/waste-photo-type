import 'dart:typed_data';

import '../../auth/auth_controller.dart';
import '../../authority/authority_actions.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/shared.dart';
import '../repositories/my_reports_repository.dart';

String reportDate(DateTime date) {
  final d = date.toLocal();
  return '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

String reportStatus(String status) => status.replaceAll('_', ' ');

class MyReportsScreen extends ConsumerStatefulWidget {
  final bool authority;
  const MyReportsScreen({super.key, this.authority = false});
  @override
  ConsumerState<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends ConsumerState<MyReportsScreen> {
  late Future<MyReportsPage> future;
  int page = 0;
  @override
  void initState() {
    super.initState();
    future = ref
        .read(myReportsRepositoryProvider)
        .mine(page, authority: widget.authority);
  }

  void reload([int? next]) {
    final nextPage = next ?? page;
    final request = ref
        .read(myReportsRepositoryProvider)
        .mine(nextPage, authority: widget.authority);
    setState(() {
      page = nextPage;
      future = request;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.authority ? 'Authority Reports' : 'My Reports'),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: () => reload(),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: SafeArea(
      child: PageShell(
        child: FutureBuilder<MyReportsPage>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _Retry(
                message: snapshot.error.toString(),
                retry: () => reload(),
              );
            }
            final result = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (result.reports.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      widget.authority ? 'No reports in the queue.' : 'No reports yet. Submit your first waste report to follow its progress here.',
                    ),
                  ),
                for (final report in result.reports)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.receipt_long_outlined),
                      title: Text(
                        '#${report.id} · ${report.touristSpot ?? 'Unregistered location'}',
                      ),
                      subtitle: Text(
                        '${reportDate(report.createdAt)}\n${reportStatus(report.status)} · ${report.severity}',
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ReportDetailScreen(id: report.id),
                          ),
                        );
                        if (mounted) reload();
                      },
                    ),
                  ),
                if (result.totalPages > 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: page > 0 ? () => reload(page - 1) : null,
                        child: const Text('Previous'),
                      ),
                      Text('${page + 1} / ${result.totalPages}'),
                      TextButton(
                        onPressed: page + 1 < result.totalPages
                            ? () => reload(page + 1)
                            : null,
                        child: const Text('Next'),
                      ),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

class ReportDetailScreen extends ConsumerStatefulWidget {
  final int id;
  const ReportDetailScreen({super.key, required this.id});
  @override
  ConsumerState<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends ConsumerState<ReportDetailScreen> {
  late Future<TrackedReport> future;
  @override
  void initState() {
    super.initState();
    future = ref.read(myReportsRepositoryProvider).detail(widget.id);
  }

  void reload() {
    final request = ref.read(myReportsRepositoryProvider).detail(widget.id);
    setState(() {
      future = request;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Report #${widget.id}'),
      actions: [
        IconButton(
          tooltip: 'Refresh status',
          onPressed: reload,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: SafeArea(
      child: PageShell(
        child: FutureBuilder<TrackedReport>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _Retry(message: snapshot.error.toString(), retry: reload);
            }
            final r = snapshot.data!;
            final photos = r.images.where(
              (i) =>
                  i['imageType'] == 'ORIGINAL' ||
                  i['imageType'] == 'AFTER_CLEANUP',
            );
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  r.touristSpot ?? 'No registered tourist spot',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(label: Text(reportStatus(r.status))),
                ),
                for (final image in photos) ...[
                  const SizedBox(height: 16),
                  Text(
                    image['imageType'] == 'ORIGINAL'
                        ? 'Original photo'
                        : 'After cleanup',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  PrivateReportPhoto(
                    key: ValueKey(image['id']),
                    reportId: r.id,
                    imageId: image['id'] as int,
                  ),
                ],
                const SizedBox(height: 20),
                Text('Submitted: ${reportDate(r.createdAt)}'),
                Text('Severity: ${r.severity}'),
                Text(
                  'GPS: ${r.latitude.toStringAsFixed(6)}, ${r.longitude.toStringAsFixed(6)}',
                ),
                const SizedBox(height: 16),
                Text(
                  r.description?.isNotEmpty == true
                      ? r.description!
                      : 'No description provided.',
                ),
                const SizedBox(height: 22),
                Text(
                  'Waste detections',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                for (final d in r.detections)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      '${d['label']} · ${((d['confidence'] as num) * 100).round()}% · ${d['categoryName']}',
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  'Status timeline',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (r.history.isEmpty)
                  const Text('No status updates available.'),
                for (final h in r.history)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      h['status'] == 'REJECTED'
                          ? Icons.cancel_outlined
                          : Icons.check_circle_outline,
                    ),
                    title: Text(reportStatus(h['status'] as String)),
                    subtitle: Text(
                      '${reportDate(DateTime.parse(h['createdAt'] as String))}${h['note'] == null ? '' : '\n${h['note']}'}',
                    ),
                  ),
                const SizedBox(height: 12),
                if (ref.watch(authProvider).isAuthority)
                  AuthorityActions(
                    key: ValueKey('${r.id}-${r.status}'),
                    id: r.id,
                    status: r.status,
                    onSaved: reload,
                  ),
                const Text(
                  'Only recorded status updates are shown. Use Refresh to check for new updates.',
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

class PrivateReportPhoto extends ConsumerStatefulWidget {
  final int reportId, imageId;
  const PrivateReportPhoto({
    super.key,
    required this.reportId,
    required this.imageId,
  });
  @override
  ConsumerState<PrivateReportPhoto> createState() => _PrivateReportPhotoState();
}

class _PrivateReportPhotoState extends ConsumerState<PrivateReportPhoto> {
  late Future<Uint8List> future;
  @override
  void initState() {
    super.initState();
    future = load();
  }

  Future<Uint8List> load() => ref
      .read(myReportsRepositoryProvider)
      .image(widget.reportId, widget.imageId);
  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List>(
    future: future,
    builder: (context, s) {
      if (s.connectionState != ConnectionState.done) {
        return const SizedBox(
          height: 180,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (s.hasError) {
        return TextButton.icon(
          onPressed: () {
            final request = load();
            setState(() {
              future = request;
            });
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Photo unavailable · Retry'),
        );
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.memory(
          s.data!,
          height: 220,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
              const Text('Photo could not be displayed.'),
        ),
      );
    },
  );
}

class _Retry extends StatelessWidget {
  final String message;
  final VoidCallback retry;
  const _Retry({required this.message, required this.retry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: retry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}
