import 'package:flutter/material.dart';

/// Per-set stat breakdown table for a single game.
///
/// Shows key volleyball stats (K, E, TA, Hit%, SA, SE, D, Blocks) as rows
/// with one column per set, making it easy to spot how performance varied.
class PerSetStats extends StatelessWidget {
  final List<Map<String, dynamic>> setStats;
  final List<String> setLabels;

  const PerSetStats({
    super.key,
    required this.setStats,
    required this.setLabels,
  });

  static const _statRows = <({String key, String label})>[
    (key: 'kills', label: 'K'),
    (key: 'attackErrors', label: 'E'),
    (key: 'totalAttempts', label: 'TA'),
    (key: 'hittingPercentage', label: 'Hit%'),
    (key: 'serviceAces', label: 'SA'),
    (key: 'serviceErrors', label: 'SE'),
    (key: 'digs', label: 'D'),
    (key: 'blocks', label: 'Blocks'),
  ];

  @override
  Widget build(BuildContext context) {
    if (setStats.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final headerStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 12,
      color: colorScheme.onSurface,
    );
    final cellStyle = TextStyle(
      fontSize: 12,
      color: colorScheme.onSurface,
    );
    final labelStyle = TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 12,
      color: colorScheme.onSurface.withAlpha(200),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stats by Set',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                headingRowHeight: 36,
                dataRowMinHeight: 32,
                dataRowMaxHeight: 36,
                headingRowColor: WidgetStateProperty.all(
                  colorScheme.surfaceContainerHighest,
                ),
                columns: [
                  DataColumn(label: Text('Stat', style: headerStyle)),
                  ...setLabels.map(
                    (l) => DataColumn(
                      label: Text(l, style: headerStyle),
                      numeric: true,
                    ),
                  ),
                ],
                rows: _statRows.map((stat) {
                  return DataRow(
                    cells: [
                      DataCell(Text(stat.label, style: labelStyle)),
                      ...List.generate(setStats.length, (i) {
                        final value = setStats[i][stat.key];
                        return DataCell(
                          Text(_formatValue(stat.key, value), style: cellStyle),
                        );
                      }),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatValue(String key, dynamic value) {
    if (value == null) return '—';
    if (key == 'hittingPercentage' && value is double) {
      if (value == 0.0) return '.000';
      return '.${(value * 1000).round().toString().padLeft(3, '0')}';
    }
    return '$value';
  }
}
