import 'package:flutter/material.dart';

import 'insights_repository.dart';

class AnalyticsPanel extends StatelessWidget {
  final Insights data;
  const AnalyticsPanel(this.data, {super.key});
  Widget ranking(
    BuildContext context,
    String title,
    List<Ranking> items,
    String empty,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 24),
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      if (items.isEmpty) Text(empty),
      for (var i = 0; i < items.length; i++)
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Text('${i + 1}'),
          title: Text(items[i].name),
          trailing: Text(
            '${items[i].count}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
    ],
  );
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ranking(
        context,
        'Top reporting areas',
        data.spots,
        'No reports linked to tourist spots yet.',
      ),
      const Text(
        'Report counts by tourist spot; rejected reports excluded.',
        style: TextStyle(fontSize: 12),
      ),
      ranking(
        context,
        'Common waste',
        data.categories,
        'No waste detections recorded yet.',
      ),
      const Text(
        'Recorded detections by category, not measured waste volume.',
        style: TextStyle(fontSize: 12),
      ),
    ],
  );
}
